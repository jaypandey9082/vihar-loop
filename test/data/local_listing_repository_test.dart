import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vihar_loop/data/listing_repository.dart';
import 'package:vihar_loop/data/local/listing_local_store.dart';
import 'package:vihar_loop/data/local_listing_repository.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/domain/listing_draft.dart';
import 'package:vihar_loop/domain/listing_draft_validator.dart';
import 'package:vihar_loop/domain/neighborhood.dart';

import '../support/listing_fixture.dart';

void main() {
  final fixedNow = DateTime(2026, 7, 30, 12);

  group('LocalListingRepository initialization and reads', () {
    test('seeds nine Vidyavihar listings once and returns them unmodifiable',
        () async {
      final store = _MemoryListingStore();
      final repository = LocalListingRepository(
        store: store,
        clock: () => fixedNow,
      );

      final first = await repository.fetchListings();
      final second = await repository.fetchListings();

      expect(store.seedCalls, 1);
      expect(first, hasLength(9));
      expect(second, hasLength(9));
      expect(first.map((listing) => listing.id).toSet(), hasLength(9));
      expect(
        first.every(
          (listing) =>
              listing.neighborhoodId == Neighborhood.vidyavihar.id &&
              listing.origin == ListingOrigin.sample,
        ),
        isTrue,
      );
      expect(() => first.add(first.first), throwsUnsupportedError);
    });

    test('shares one initialization across concurrent first reads', () async {
      final gate = Completer<void>();
      final store = _MemoryListingStore(seedGate: gate);
      final repository = LocalListingRepository(
        store: store,
        clock: () => fixedNow,
      );

      final first = repository.fetchListings();
      final second = repository.fetchListings();
      await Future<void>.delayed(Duration.zero);

      expect(store.seedCalls, 1);
      gate.complete();
      expect(await first, hasLength(9));
      expect(await second, hasLength(9));
      expect(store.seedCalls, 1);
    });

    test('clears a failed initialization so retry genuinely seeds again',
        () async {
      final store = _MemoryListingStore(failFirstSeed: true);
      final repository = LocalListingRepository(
        store: store,
        clock: () => fixedNow,
      );

      await expectLater(repository.fetchListings(), throwsException);
      expect(await repository.fetchListings(), hasLength(9));
      expect(store.seedCalls, 2);
    });

    test('does not reseed after initialization when a later read fails',
        () async {
      final store = _MemoryListingStore();
      final repository = LocalListingRepository(
        store: store,
        clock: () => fixedNow,
      );

      expect(await repository.fetchListings(), hasLength(9));
      store.failReads = true;
      await expectLater(repository.fetchListings(), throwsException);

      expect(store.seedCalls, 1);
    });

    test('keeps store order so display sorting remains in FeedViewModel',
        () async {
      final store = _MemoryListingStore(reverseAfterSeed: true);
      final repository = LocalListingRepository(
        store: store,
        clock: () => fixedNow,
      );

      final listings = await repository.fetchListings();

      expect(listings.first.id, 'sample-music-stand');
      expect(listings.last.id, 'sample-guitar-capo');
    });
  });

  group('LocalListingRepository mutations', () {
    test('setSaved persists true and false while preserving other fields',
        () async {
      final original = buildTestListing(
        isSaved: false,
        isContacted: true,
      );
      final store = _MemoryListingStore(initialListings: [original]);
      final repository = LocalListingRepository(store: store);

      final saved = await repository.setSaved(
        listingId: original.id,
        isSaved: true,
      );
      final unsaved = await repository.setSaved(
        listingId: original.id,
        isSaved: false,
      );

      expect(saved.isSaved, isTrue);
      expect(saved.isContacted, original.isContacted);
      expect(saved.status, original.status);
      expect(saved.title, original.title);
      expect(saved.createdAt, original.createdAt);
      expect(unsaved.isSaved, isFalse);
      expect(store.updateCalls, 2);
      expect(identical(unsaved, store.record(original.id)), isTrue);

      final sameValue = await repository.setSaved(
        listingId: original.id,
        isSaved: false,
      );
      expect(identical(sameValue, store.record(original.id)), isTrue);
      expect(store.updateCalls, 2);
    });

    test('setContacted persists true and false without changing saved state',
        () async {
      final original = buildTestListing(
        isSaved: true,
        isContacted: false,
      );
      final store = _MemoryListingStore(initialListings: [original]);
      final repository = LocalListingRepository(store: store);

      final contacted = await repository.setContacted(
        listingId: original.id,
        isContacted: true,
      );
      final removed = await repository.setContacted(
        listingId: original.id,
        isContacted: false,
      );

      expect(contacted.isContacted, isTrue);
      expect(contacted.isSaved, isTrue);
      expect(removed.isContacted, isFalse);
      expect(removed.isSaved, isTrue);
      expect(store.updateCalls, 2);

      await repository.setContacted(
        listingId: original.id,
        isContacted: false,
      );
      expect(store.updateCalls, 2);
    });

    test('local listing can close and reopen without losing markers', () async {
      final original = buildTestListing(
        origin: ListingOrigin.local,
        isSaved: true,
        isContacted: true,
      );
      final store = _MemoryListingStore(initialListings: [original]);
      final repository = LocalListingRepository(store: store);

      final closed = await repository.setStatus(
        listingId: original.id,
        status: ListingStatus.closed,
      );
      final reopened = await repository.setStatus(
        listingId: original.id,
        status: ListingStatus.open,
      );

      expect(closed.status, ListingStatus.closed);
      expect(closed.isSaved, isTrue);
      expect(closed.isContacted, isTrue);
      expect(reopened.status, ListingStatus.open);
      expect(reopened.isSaved, isTrue);
      expect(reopened.isContacted, isTrue);
      expect(store.updateCalls, 2);

      await repository.setStatus(
        listingId: original.id,
        status: ListingStatus.open,
      );
      expect(store.updateCalls, 2);
    });

    test('sample status mutation is rejected without a write', () async {
      final sample = buildTestListing(origin: ListingOrigin.sample);
      final store = _MemoryListingStore(initialListings: [sample]);
      final repository = LocalListingRepository(store: store);

      await expectLater(
        repository.setStatus(
          listingId: sample.id,
          status: ListingStatus.closed,
        ),
        throwsA(isA<ListingStatusChangeNotAllowedException>()),
      );

      expect(store.updateCalls, 0);
      expect(store.record(sample.id)!.status, ListingStatus.open);
    });

    test('missing ID throws and never creates a record', () async {
      final store = _MemoryListingStore(
        initialListings: [buildTestListing()],
      );
      final repository = LocalListingRepository(store: store);

      await expectLater(
        repository.setSaved(listingId: 'missing', isSaved: true),
        throwsA(isA<ListingNotFoundException>()),
      );

      expect(store.updateCalls, 0);
      expect(store.record('missing'), isNull);
    });

    test('mutation initializes first and failed initialization can retry',
        () async {
      final store = _MemoryListingStore(failFirstSeed: true);
      final repository = LocalListingRepository(
        store: store,
        clock: () => fixedNow,
      );

      await expectLater(
        repository.setSaved(
          listingId: 'sample-guitar-capo',
          isSaved: true,
        ),
        throwsException,
      );
      final saved = await repository.setSaved(
        listingId: 'sample-guitar-capo',
        isSaved: true,
      );

      expect(saved.isSaved, isTrue);
      expect(store.seedCalls, 2);
      expect(store.updateCalls, 1);
    });

    test('failed write propagates and does not poison a later mutation',
        () async {
      final original = buildTestListing(
        isSaved: false,
        isContacted: false,
      );
      final store = _MemoryListingStore(
        initialListings: [original],
        failingUpdates: 1,
      );
      final repository = LocalListingRepository(store: store);

      await expectLater(
        repository.setSaved(listingId: original.id, isSaved: true),
        throwsException,
      );
      expect(store.record(original.id)!.isSaved, isFalse);

      final contacted = await repository.setContacted(
        listingId: original.id,
        isContacted: true,
      );

      expect(contacted.isSaved, isFalse);
      expect(contacted.isContacted, isTrue);
      expect(store.updateCalls, 2);
    });

    test('rapid mutations are ordered and each reads the latest record',
        () async {
      final original = buildTestListing(
        isSaved: false,
        isContacted: false,
      );
      final updateStarted = Completer<void>();
      final allowFirstUpdate = Completer<void>();
      final store = _MemoryListingStore(
        initialListings: [original],
        firstUpdateStarted: updateStarted,
        firstUpdateGate: allowFirstUpdate,
      );
      final repository = LocalListingRepository(store: store);

      final save = repository.setSaved(
        listingId: original.id,
        isSaved: true,
      );
      final contact = repository.setContacted(
        listingId: original.id,
        isContacted: true,
      );

      await updateStarted.future;
      expect(store.readByIdCalls, 1);
      allowFirstUpdate.complete();

      await Future.wait([save, contact]);
      final persisted = store.record(original.id)!;
      expect(persisted.isSaved, isTrue);
      expect(persisted.isContacted, isTrue);
      expect(store.readByIdCalls, 2);
      expect(store.updateCalls, 2);
      expect(store.updates.last.isSaved, isTrue);
      expect(store.updates.last.isContacted, isTrue);
    });
  });

  group('LocalListingRepository create', () {
    ListingDraft validDraft({
      String title = '  Music stand needed  ',
      String description = '  A foldable stand would help rehearsal.  ',
    }) {
      return ListingDraft(
        kind: ListingKind.need,
        title: title,
        description: description,
        category: ListingCategory.musicHobbiesAndSports,
        approximateArea: ApproximateArea.somaiyaSide,
        contactPreference: ContactPreference.publicPlace,
        activeUntil: fixedNow.add(const Duration(hours: 2)),
      );
    }

    test('initializes then constructs every protected field and inserts',
        () async {
      final store = _MemoryListingStore();
      var clockCalls = 0;
      DateTime? idTime;
      final repository = LocalListingRepository(
        store: store,
        clock: () {
          clockCalls++;
          return fixedNow;
        },
        idGenerator: (now) {
          idTime = now;
          return 'local-fixed-id';
        },
      );
      await repository.fetchListings();
      clockCalls = 0;

      final created = await repository.createListing(validDraft());

      expect(clockCalls, 1);
      expect(idTime, fixedNow);
      expect(store.insertCalls, 1);
      expect(identical(store.inserts.single, created), isTrue);
      expect(created.id, 'local-fixed-id');
      expect(created.neighborhoodId, Neighborhood.vidyavihar.id);
      expect(created.title, 'Music stand needed');
      expect(created.description, 'A foldable stand would help rehearsal.');
      expect(created.kind, ListingKind.need);
      expect(created.category, ListingCategory.musicHobbiesAndSports);
      expect(created.approximateArea, ApproximateArea.somaiyaSide);
      expect(created.contactPreference, ContactPreference.publicPlace);
      expect(created.createdAt, fixedNow);
      expect(created.activeUntil, fixedNow.add(const Duration(hours: 2)));
      expect(created.origin, ListingOrigin.local);
      expect(created.status, ListingStatus.open);
      expect(created.isSaved, isFalse);
      expect(created.isContacted, isFalse);
    });

    test('invalid draft throws safely and performs no insert', () async {
      final store = _MemoryListingStore();
      final repository = LocalListingRepository(
        store: store,
        clock: () => fixedNow,
        idGenerator: (_) => 'unused',
      );

      await expectLater(
        repository.createListing(validDraft(title: 'bad')),
        throwsA(isA<InvalidListingDraftException>()),
      );

      expect(store.insertCalls, 0);
    });

    test('duplicate insert propagates and returns no listing', () async {
      final store = _MemoryListingStore(
        initialListings: [buildTestListing(id: 'local-fixed-id')],
      );
      final repository = LocalListingRepository(
        store: store,
        clock: () => fixedNow,
        idGenerator: (_) => 'local-fixed-id',
      );

      await expectLater(
        repository.createListing(validDraft()),
        throwsException,
      );
      expect(store.insertCalls, 1);
      expect(
          store.record('local-fixed-id')!.title, isNot('Music stand needed'));
    });

    test('failed create does not poison later Save or Create', () async {
      final existing = buildTestListing(isSaved: false);
      final store = _MemoryListingStore(
        initialListings: [existing],
        failingInserts: 1,
      );
      var id = 0;
      final repository = LocalListingRepository(
        store: store,
        clock: () => fixedNow,
        idGenerator: (_) => 'local-${id++}',
      );

      await expectLater(
          repository.createListing(validDraft()), throwsException);
      final saved = await repository.setSaved(
        listingId: existing.id,
        isSaved: true,
      );
      final created = await repository.createListing(validDraft());

      expect(saved.isSaved, isTrue);
      expect(created.id, 'local-1');
      expect(store.insertCalls, 2);
    });

    test('concurrent creates are serialized', () async {
      final started = Completer<void>();
      final gate = Completer<void>();
      final store = _MemoryListingStore(
        firstInsertStarted: started,
        firstInsertGate: gate,
      );
      var id = 0;
      final repository = LocalListingRepository(
        store: store,
        clock: () => fixedNow,
        idGenerator: (_) => 'local-${id++}',
      );

      final first = repository.createListing(validDraft());
      final second = repository.createListing(validDraft());
      await started.future;
      expect(store.insertCalls, 1);
      gate.complete();

      final created = await Future.wait([first, second]);
      expect(created.map((listing) => listing.id), ['local-0', 'local-1']);
      expect(store.insertCalls, 2);
    });
  });
}

class _MemoryListingStore implements ListingLocalStore {
  _MemoryListingStore({
    List<Listing>? initialListings,
    this.seedGate,
    this.failFirstSeed = false,
    this.reverseAfterSeed = false,
    this.firstUpdateStarted,
    this.firstUpdateGate,
    this.firstInsertStarted,
    this.firstInsertGate,
    int failingUpdates = 0,
    int failingInserts = 0,
  })  : _seeded = initialListings != null,
        _failingUpdates = failingUpdates,
        _failingInserts = failingInserts,
        _records = {
          for (final listing in initialListings ?? const <Listing>[])
            listing.id: listing,
        };

  final Completer<void>? seedGate;
  final bool failFirstSeed;
  final bool reverseAfterSeed;
  final Completer<void>? firstUpdateStarted;
  final Completer<void>? firstUpdateGate;
  final Completer<void>? firstInsertStarted;
  final Completer<void>? firstInsertGate;
  final Map<String, Listing> _records;

  bool _seeded;
  int _failingUpdates;
  int _failingInserts;
  int seedCalls = 0;
  int readByIdCalls = 0;
  int updateCalls = 0;
  int insertCalls = 0;
  bool failReads = false;
  final List<Listing> updates = [];
  final List<Listing> inserts = [];

  Listing? record(String id) => _records[id];

  @override
  Future<void> seedIfRequired(List<Listing> listings) async {
    seedCalls++;
    if (failFirstSeed && seedCalls == 1) {
      throw Exception('first seed failed');
    }
    if (seedGate case final gate?) {
      await gate.future;
    }
    if (_seeded) {
      return;
    }

    final seededListings = reverseAfterSeed ? listings.reversed : listings;
    _records.addEntries(
      seededListings.map((listing) => MapEntry(listing.id, listing)),
    );
    _seeded = true;
  }

  @override
  Future<List<Listing>> readAll() async {
    if (failReads) {
      throw Exception('read failed');
    }
    return List<Listing>.unmodifiable(_records.values);
  }

  @override
  Future<Listing?> readById(String id) async {
    readByIdCalls++;
    return _records[id];
  }

  @override
  Future<void> insert(Listing listing) async {
    insertCalls++;
    if (_failingInserts > 0) {
      _failingInserts--;
      throw Exception('insert failed');
    }
    if (insertCalls == 1) {
      firstInsertStarted?.complete();
      if (firstInsertGate case final gate?) {
        await gate.future;
      }
    }
    if (_records.containsKey(listing.id)) {
      throw Exception('duplicate record');
    }
    _records[listing.id] = listing;
    inserts.add(listing);
  }

  @override
  Future<void> update(Listing listing) async {
    updateCalls++;
    if (_failingUpdates > 0) {
      _failingUpdates--;
      throw Exception('write failed');
    }
    if (updateCalls == 1) {
      firstUpdateStarted?.complete();
      if (firstUpdateGate case final gate?) {
        await gate.future;
      }
    }
    if (!_records.containsKey(listing.id)) {
      throw Exception('missing record');
    }
    _records[listing.id] = listing;
    updates.add(listing);
  }
}
