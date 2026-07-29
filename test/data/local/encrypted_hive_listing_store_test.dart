import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:vihar_loop/data/local/encrypted_hive_listing_store.dart';
import 'package:vihar_loop/data/local/listing_record_codec.dart';
import 'package:vihar_loop/data/local/local_storage_exception.dart';
import 'package:vihar_loop/data/local_listing_repository.dart';
import 'package:vihar_loop/data/seed_listings.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/domain/listing_draft.dart';
import 'package:vihar_loop/security/encryption_key_store.dart';

import '../../support/listing_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory directory;
  late String boxName;
  late List<int> encryptionKey;
  EncryptedHiveListingStore? store;

  setUp(() async {
    await Hive.close();
    directory = await Directory.systemTemp.createTemp('vihar_loop_hive_test_');
    boxName = 'listings_${DateTime.now().microsecondsSinceEpoch}';
    encryptionKey = List<int>.generate(32, (index) => index + 1);
  });

  tearDown(() async {
    await store?.close();
    await Hive.close();
    if (directory.existsSync()) {
      try {
        await directory.delete(recursive: true);
      } on PathNotFoundException {
        // Hive can finish deleting its temporary files between the existence
        // check and this teardown cleanup.
      }
    }
  });

  EncryptedHiveListingStore createStore({
    List<int>? key,
    String? name,
  }) {
    return EncryptedHiveListingStore(
      keyStore: _FixedKeyStore(key ?? encryptionKey),
      boxName: name ?? boxName,
      initializeHive: (hive) async => hive.init(directory.path),
    );
  }

  Future<Box<dynamic>> openDynamicBox() async {
    Hive.init(directory.path);
    return Hive.openBox<dynamic>(
      boxName,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
  }

  group('EncryptedHiveListingStore', () {
    test('seeds, encrypts, and round-trips all nine listings', () async {
      final listings = buildSeedListings(DateTime(2026, 7, 29, 12));
      store = createStore();

      await store!.seedIfRequired(listings);
      final restored = await store!.readAll();

      expect(restored, hasLength(9));
      for (final original in listings) {
        final actual =
            restored.singleWhere((listing) => listing.id == original.id);
        expectSameListing(actual, original);
      }
      expect(() => restored.add(restored.first), throwsUnsupportedError);
    });

    test('keeps seed version one authoritative even when records are empty',
        () async {
      store = createStore();
      await store!.seedIfRequired([buildTestListing()]);
      final box = Hive.box<String>(boxName);
      await box.delete('listing:test-listing');

      await store!.seedIfRequired([
        buildTestListing(id: 'replacement-that-must-not-be-seeded'),
      ]);

      expect(await store!.readAll(), isEmpty);
      expect(box.get(EncryptedHiveListingStore.seedVersionKey), '1');
    });

    test('replays stable record writes after an interrupted seed', () async {
      const codec = ListingRecordCodec();
      final listings = buildSeedListings(DateTime(2026, 7, 29, 12));
      store = createStore();

      await store!.seedIfRequired(const []);
      final box = Hive.box<String>(boxName);
      await box.clear();
      await box.put(
        'listing:${listings.first.id}',
        codec.encode(listings.first),
      );

      await store!.seedIfRequired(listings);

      expect(await store!.readAll(), hasLength(9));
      expect(box.get(EncryptedHiveListingStore.seedVersionKey), '1');
    });

    test('does not write listing titles or descriptions as plaintext',
        () async {
      final listing = buildTestListing();
      store = createStore();
      await store!.seedIfRequired([listing]);
      await Hive.box<String>(boxName).flush();

      final bytes = <int>[];
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          bytes.addAll(await entity.readAsBytes());
        }
      }
      final rawText = utf8.decode(bytes, allowMalformed: true);

      expect(rawText, isNot(contains(listing.title)));
      expect(rawText, isNot(contains(listing.description)));
    });

    test('readById decodes a stable key and returns null for non-listings',
        () async {
      final listing = buildTestListing();
      store = createStore();
      await store!.seedIfRequired([listing]);

      final restored = await store!.readById(listing.id);

      expectSameListing(restored!, listing);
      expect(await store!.readById('missing'), isNull);
      expect(
        await store!.readById(EncryptedHiveListingStore.seedVersionKey),
        isNull,
      );
    });

    test('readById rejects mismatched, malformed, and unsupported records',
        () async {
      const codec = ListingRecordCodec();
      store = createStore();
      await store!.seedIfRequired([buildTestListing()]);
      final box = Hive.box<String>(boxName);

      await box.put(
        'listing:test-listing',
        codec.encode(buildTestListing(id: 'different-id')),
      );
      await expectLater(
        store!.readById('test-listing'),
        throwsA(isA<LocalStorageException>()),
      );

      await box.put('listing:test-listing', '{not-json');
      await expectLater(
        store!.readById('test-listing'),
        throwsA(isA<LocalStorageException>()),
      );

      final unsupported = jsonDecode(
        codec.encode(buildTestListing()),
      ) as Map<String, dynamic>;
      unsupported['schemaVersion'] = 2;
      await box.put('listing:test-listing', jsonEncode(unsupported));
      await expectLater(
        store!.readById('test-listing'),
        throwsA(isA<LocalStorageException>()),
      );
    });

    test('update replaces one complete record and preserves metadata',
        () async {
      final original = buildTestListing(
        isSaved: false,
        isContacted: false,
      );
      store = createStore();
      await store!.seedIfRequired([original]);
      final box = Hive.box<String>(boxName);
      final keysBefore = box.keys.toSet();

      final updated = original.copyWith(
        isSaved: true,
        isContacted: true,
        status: ListingStatus.closed,
      );
      await store!.update(updated);
      final restored = await store!.readById(original.id);

      expectSameListing(restored!, updated);
      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.createdAt, original.createdAt);
      expect(restored.activeUntil, original.activeUntil);
      expect(box.keys.toSet(), keysBefore);
      expect(box.get(EncryptedHiveListingStore.seedVersionKey), '1');
    });

    test('update never inserts a missing or overwrites a corrupt record',
        () async {
      final listing = buildTestListing();
      store = createStore();
      await store!.seedIfRequired([listing]);
      final box = Hive.box<String>(boxName);

      final missing = buildTestListing(id: 'missing');
      await expectLater(
        store!.update(missing),
        throwsA(isA<LocalStorageException>()),
      );
      expect(box.containsKey('listing:missing'), isFalse);

      await box.put('listing:test-listing', '{corrupt');
      await expectLater(
        store!.update(listing.copyWith(isSaved: false)),
        throwsA(isA<LocalStorageException>()),
      );
      expect(box.get('listing:test-listing'), '{corrupt');
    });

    test('insert adds one complete local record without changing seeds',
        () async {
      final seeds = buildSeedListings(DateTime(2026, 7, 29, 12));
      final local = buildTestListing(
        id: 'local-created',
        origin: ListingOrigin.local,
        status: ListingStatus.open,
        isSaved: false,
        isContacted: false,
      );
      store = createStore();
      await store!.seedIfRequired(seeds);
      final originalSeed = await store!.readById(seeds.first.id);

      await store!.insert(local);

      final restored = await store!.readById(local.id);
      expectSameListing(restored!, local);
      expect(await store!.readAll(), hasLength(10));
      expectSameListing(
          (await store!.readById(seeds.first.id))!, originalSeed!);
      expect(
        Hive.box<String>(boxName).get(
          EncryptedHiveListingStore.seedVersionKey,
        ),
        '1',
      );

      await expectLater(
        store!.insert(local.copyWith(isSaved: true)),
        throwsA(isA<LocalStorageException>()),
      );
      expectSameListing((await store!.readById(local.id))!, local);
    });

    test('insert does not create metadata and remains encrypted after reopen',
        () async {
      final local = buildTestListing(
        id: 'local-without-seed',
        origin: ListingOrigin.local,
      );
      store = createStore();

      await store!.insert(local);
      final box = Hive.box<String>(boxName);
      expect(
        box.containsKey(EncryptedHiveListingStore.seedVersionKey),
        isFalse,
      );
      await box.flush();

      final bytes = <int>[];
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          bytes.addAll(await entity.readAsBytes());
        }
      }
      final rawText = utf8.decode(bytes, allowMalformed: true);
      expect(rawText, isNot(contains(local.title)));
      expect(rawText, isNot(contains(local.description)));

      await store!.close();
      store = createStore();
      expectSameListing((await store!.readById(local.id))!, local);
    });

    test('wrong encryption key cannot read an existing box', () async {
      store = createStore();
      await store!.seedIfRequired([buildTestListing()]);
      await store!.close();

      store = createStore(key: List<int>.filled(32, 99));

      await expectLater(
        store!.readAll(),
        throwsA(isA<LocalStorageException>()),
      );
    });

    test('reopen preserves nine records and clock-A timestamps', () async {
      final clockA = DateTime(2026, 7, 29, 8);
      final clockB = DateTime(2026, 8, 20, 20);
      store = createStore();
      final firstRepository = LocalListingRepository(
        store: store!,
        clock: () => clockA,
      );
      final first = await firstRepository.fetchListings();
      final original = first.singleWhere(
        (listing) => listing.id == 'sample-guitar-capo',
      );
      final originalCreatedAt = original.createdAt;
      final originalActiveUntil = original.activeUntil;
      await store!.close();

      store = createStore();
      final secondRepository = LocalListingRepository(
        store: store!,
        clock: () => clockB,
      );
      final restored = await secondRepository.fetchListings();
      final sameListing = restored.singleWhere(
        (listing) => listing.id == 'sample-guitar-capo',
      );

      expect(restored, hasLength(9));
      expect(sameListing.createdAt, originalCreatedAt);
      expect(sameListing.activeUntil, originalActiveUntil);
      expect(sameListing.activeUntil, clockA.add(const Duration(hours: 3)));
    });

    test('repository mutations survive encrypted reopen without duplicates',
        () async {
      final sample = buildTestListing(
        id: 'sample',
        origin: ListingOrigin.sample,
        isSaved: false,
        isContacted: false,
      );
      final local = buildTestListing(
        id: 'local',
        origin: ListingOrigin.local,
        isSaved: false,
        isContacted: true,
      );
      store = createStore();
      final firstRepository = LocalListingRepository(
        store: store!,
        clock: () => DateTime(2026, 7, 30, 8),
      );
      await store!.seedIfRequired([sample, local]);

      await firstRepository.setSaved(listingId: sample.id, isSaved: true);
      await firstRepository.setContacted(
        listingId: sample.id,
        isContacted: true,
      );
      await firstRepository.setStatus(
        listingId: local.id,
        status: ListingStatus.closed,
      );
      await store!.close();

      store = createStore();
      final secondRepository = LocalListingRepository(
        store: store!,
        clock: () => DateTime(2027, 1, 1),
      );
      final restored = await secondRepository.fetchListings();
      final restoredSample =
          restored.singleWhere((listing) => listing.id == sample.id);
      final restoredLocal =
          restored.singleWhere((listing) => listing.id == local.id);

      expect(restored, hasLength(2));
      expect(restored.map((listing) => listing.id).toSet(), hasLength(2));
      expect(restoredSample.isSaved, isTrue);
      expect(restoredSample.isContacted, isTrue);
      expect(restoredSample.title, sample.title);
      expect(restoredSample.createdAt, sample.createdAt);
      expect(restoredSample.activeUntil, sample.activeUntil);
      expect(restoredLocal.status, ListingStatus.closed);
      expect(restoredLocal.isContacted, isTrue);

      await secondRepository.setStatus(
        listingId: local.id,
        status: ListingStatus.open,
      );
      expect(
        (await secondRepository.fetchListings())
            .singleWhere((listing) => listing.id == local.id)
            .status,
        ListingStatus.open,
      );
    });

    test('created listing closes and reopens across encrypted restarts',
        () async {
      final now = DateTime(2026, 7, 30, 12);
      final deadline = now.add(const Duration(hours: 2));
      final draft = ListingDraft(
        kind: ListingKind.need,
        title: '  Foldable music stand for rehearsal  ',
        description: '  A foldable stand would help our rehearsal tonight.  ',
        category: ListingCategory.musicHobbiesAndSports,
        approximateArea: ApproximateArea.somaiyaSide,
        contactPreference: ContactPreference.publicPlace,
        activeUntil: deadline,
      );
      store = createStore();
      final firstRepository = LocalListingRepository(
        store: store!,
        clock: () => now,
        idGenerator: (_) => 'local-end-to-end',
      );

      final created = await firstRepository.createListing(draft);
      expect(created.origin, ListingOrigin.local);
      expect(created.status, ListingStatus.open);
      await firstRepository.setStatus(
        listingId: created.id,
        status: ListingStatus.closed,
      );
      await store!.close();

      store = createStore();
      final secondRepository = LocalListingRepository(
        store: store!,
        clock: () => now.add(const Duration(days: 1)),
      );
      final firstReopen = await secondRepository.fetchListings();
      final closed =
          firstReopen.singleWhere((listing) => listing.id == created.id);
      expect(firstReopen, hasLength(10));
      expect(
        firstReopen.where((listing) => listing.origin == ListingOrigin.sample),
        hasLength(9),
      );
      expect(closed.title, 'Foldable music stand for rehearsal');
      expect(
        closed.description,
        'A foldable stand would help our rehearsal tonight.',
      );
      expect(closed.createdAt, now);
      expect(closed.activeUntil, deadline);
      expect(closed.origin, ListingOrigin.local);
      expect(closed.status, ListingStatus.closed);

      await secondRepository.setStatus(
        listingId: created.id,
        status: ListingStatus.open,
      );
      await store!.close();

      store = createStore();
      final thirdRepository = LocalListingRepository(
        store: store!,
        clock: () => now.add(const Duration(days: 2)),
      );
      final finalListings = await thirdRepository.fetchListings();
      final reopened =
          finalListings.singleWhere((listing) => listing.id == created.id);
      expect(reopened.status, ListingStatus.open);
      expect(finalListings.map((listing) => listing.id).toSet(), hasLength(10));
      final box = Hive.box<String>(boxName);
      expect(box.get(EncryptedHiveListingStore.seedVersionKey), '1');
      final record = jsonDecode(
        box.get('listing:${created.id}')!,
      ) as Map<String, dynamic>;
      expect(record['schemaVersion'], ListingRecordCodec.schemaVersion);
    });

    test('corrupt JSON and unknown schema fail the whole read', () async {
      store = createStore();
      await store!.seedIfRequired([
        buildTestListing(id: 'valid'),
        buildTestListing(id: 'corrupt'),
      ]);
      final box = Hive.box<String>(boxName);
      await box.put('listing:corrupt', '{not-json');

      await expectLater(
        store!.readAll(),
        throwsA(isA<LocalStorageException>()),
      );

      final unknownSchema = jsonDecode(
        const ListingRecordCodec().encode(buildTestListing(id: 'corrupt')),
      ) as Map<String, dynamic>;
      unknownSchema['schemaVersion'] = 99;
      await box.put('listing:corrupt', jsonEncode(unknownSchema));

      await expectLater(
        store!.readAll(),
        throwsA(isA<LocalStorageException>()),
      );
    });

    test('rejects storage-key mismatch and duplicate logical identifiers',
        () async {
      const codec = ListingRecordCodec();
      store = createStore();
      await store!.seedIfRequired([buildTestListing(id: 'one')]);
      final box = Hive.box<String>(boxName);
      await box.put('listing:wrong', codec.encode(buildTestListing(id: 'two')));

      await expectLater(
        store!.readAll(),
        throwsA(isA<LocalStorageException>()),
      );

      await box.delete('listing:wrong');
      await box.put(
          'listing:second', codec.encode(buildTestListing(id: 'one')));
      await expectLater(
        store!.readAll(),
        throwsA(isA<LocalStorageException>()),
      );
    });

    test('rejects unknown records and unsupported seed versions', () async {
      store = createStore();
      await store!.seedIfRequired([buildTestListing()]);
      final box = Hive.box<String>(boxName);
      await box.put('meta:future_setting', 'value');

      await expectLater(
        store!.readAll(),
        throwsA(isA<LocalStorageException>()),
      );

      await box.delete('meta:future_setting');
      await box.put(EncryptedHiveListingStore.seedVersionKey, '2');
      await expectLater(
        store!.seedIfRequired([buildTestListing()]),
        throwsA(isA<LocalStorageException>()),
      );
    });

    test('rejects a persisted record with the wrong value type', () async {
      final dynamicBox = await openDynamicBox();
      await dynamicBox.put('listing:test-listing', 42);
      await dynamicBox.put(EncryptedHiveListingStore.seedVersionKey, '1');
      await dynamicBox.close();

      store = createStore();

      await expectLater(
        store!.readAll(),
        throwsA(isA<LocalStorageException>()),
      );
    });

    test('clears a failed box-open future so a later attempt can retry',
        () async {
      var keyReads = 0;
      store = EncryptedHiveListingStore(
        keyStore: _RetryingKeyStore(onRead: () => keyReads++),
        boxName: boxName,
        initializeHive: (hive) async => hive.init(directory.path),
      );

      await expectLater(
        store!.readAll(),
        throwsA(isA<LocalStorageException>()),
      );
      expect(await store!.readAll(), isEmpty);
      expect(keyReads, 2);
    });
  });
}

class _FixedKeyStore implements EncryptionKeyStore {
  const _FixedKeyStore(this.key);

  final List<int> key;

  @override
  Future<List<int>> readOrCreateKey() async => key;
}

class _RetryingKeyStore implements EncryptionKeyStore {
  _RetryingKeyStore({required this.onRead});

  final void Function() onRead;
  var _calls = 0;

  @override
  Future<List<int>> readOrCreateKey() async {
    _calls++;
    onRead();
    if (_calls == 1) {
      throw Exception('temporary keychain failure');
    }
    return List<int>.filled(32, 7);
  }
}
