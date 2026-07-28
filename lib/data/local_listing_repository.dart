import 'dart:collection';

import 'package:vihar_loop/data/listing_repository.dart';
import 'package:vihar_loop/data/local/listing_local_store.dart';
import 'package:vihar_loop/data/seed_listings.dart';
import 'package:vihar_loop/domain/listing.dart';

typedef Clock = DateTime Function();

class LocalListingRepository implements ListingRepository {
  LocalListingRepository({
    required ListingLocalStore store,
    Clock? clock,
  })  : _store = store,
        _clock = clock ?? DateTime.now;

  final ListingLocalStore _store;
  final Clock _clock;

  Future<void>? _initialization;

  @override
  Future<List<Listing>> fetchListings() async {
    await _ensureInitialized();
    return UnmodifiableListView(await _store.readAll());
  }

  Future<void> _ensureInitialized() async {
    final cached = _initialization;
    if (cached != null) {
      return cached;
    }

    final pending = _store.seedIfRequired(buildSeedListings(_clock()));
    _initialization = pending;
    try {
      await pending;
    } on Object {
      if (identical(_initialization, pending)) {
        _initialization = null;
      }
      rethrow;
    }
  }
}
