import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:vihar_loop/data/local/encrypted_hive_listing_store.dart';
import 'package:vihar_loop/data/local/listing_record_codec.dart';
import 'package:vihar_loop/data/local/local_storage_exception.dart';
import 'package:vihar_loop/data/local_listing_repository.dart';
import 'package:vihar_loop/data/seed_listings.dart';
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
      await directory.delete(recursive: true);
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
