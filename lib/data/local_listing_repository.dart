import 'dart:async';
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
  Future<void> _mutationTail = Future<void>.value();

  @override
  Future<List<Listing>> fetchListings() async {
    await _ensureInitialized();
    return UnmodifiableListView(await _store.readAll());
  }

  @override
  Future<Listing> setSaved({
    required String listingId,
    required bool isSaved,
  }) {
    return _enqueueMutation(() async {
      await _ensureInitialized();
      return _mutate(listingId, (current) {
        if (current.isSaved == isSaved) {
          return current;
        }
        return current.copyWith(isSaved: isSaved);
      });
    });
  }

  @override
  Future<Listing> setContacted({
    required String listingId,
    required bool isContacted,
  }) {
    return _enqueueMutation(() async {
      await _ensureInitialized();
      return _mutate(listingId, (current) {
        if (current.isContacted == isContacted) {
          return current;
        }
        return current.copyWith(isContacted: isContacted);
      });
    });
  }

  @override
  Future<Listing> setStatus({
    required String listingId,
    required ListingStatus status,
  }) {
    return _enqueueMutation(() async {
      await _ensureInitialized();
      return _mutate(listingId, (current) {
        if (current.origin != ListingOrigin.local) {
          throw const ListingStatusChangeNotAllowedException();
        }
        if (current.status == status) {
          return current;
        }
        return current.copyWith(status: status);
      });
    });
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

  Future<Listing> _mutate(
    String listingId,
    Listing Function(Listing current) change,
  ) async {
    final current = await _store.readById(listingId);
    if (current == null) {
      throw const ListingNotFoundException();
    }

    final updated = change(current);
    if (identical(updated, current)) {
      return current;
    }

    await _store.update(updated);
    return updated;
  }

  Future<T> _enqueueMutation<T>(Future<T> Function() operation) {
    final result = Completer<T>();

    // Each mutation reads after the previous write so rapid actions cannot
    // overwrite fields using stale snapshots.
    _mutationTail = _mutationTail.then((_) async {
      try {
        result.complete(await operation());
      } on Object catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });

    return result.future;
  }
}
