import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vihar_loop/data/local/listing_local_store.dart';
import 'package:vihar_loop/data/local_listing_repository.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/domain/neighborhood.dart';

void main() {
  final fixedNow = DateTime(2026, 7, 29, 12);

  group('LocalListingRepository', () {
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
}

class _MemoryListingStore implements ListingLocalStore {
  _MemoryListingStore({
    this.seedGate,
    this.failFirstSeed = false,
    this.reverseAfterSeed = false,
  });

  final Completer<void>? seedGate;
  final bool failFirstSeed;
  final bool reverseAfterSeed;

  int seedCalls = 0;
  bool failReads = false;
  List<Listing> _listings = const [];

  @override
  Future<void> seedIfRequired(List<Listing> listings) async {
    seedCalls++;
    if (failFirstSeed && seedCalls == 1) {
      throw Exception('first seed failed');
    }
    if (seedGate case final gate?) {
      await gate.future;
    }
    _listings = List<Listing>.unmodifiable(
      reverseAfterSeed ? listings.reversed : listings,
    );
  }

  @override
  Future<List<Listing>> readAll() async {
    if (failReads) {
      throw Exception('read failed');
    }
    return _listings;
  }
}
