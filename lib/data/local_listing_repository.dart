import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:vihar_loop/core/clock.dart';
import 'package:vihar_loop/data/listing_repository.dart';
import 'package:vihar_loop/data/local/listing_local_store.dart';
import 'package:vihar_loop/data/seed_listings.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/domain/listing_draft.dart';
import 'package:vihar_loop/domain/listing_draft_validator.dart';
import 'package:vihar_loop/domain/neighborhood.dart';

typedef ListingIdGenerator = String Function(DateTime now);

class LocalListingRepository implements ListingRepository {
  LocalListingRepository({
    required ListingLocalStore store,
    Clock? clock,
    ListingDraftValidator validator = const ListingDraftValidator(),
    ListingIdGenerator? idGenerator,
  })  : _store = store,
        _clock = clock ?? DateTime.now,
        _validator = validator,
        _idGenerator = idGenerator ?? _generateListingId;

  final ListingLocalStore _store;
  final Clock _clock;
  final ListingDraftValidator _validator;
  final ListingIdGenerator _idGenerator;

  Future<void>? _initialization;
  Future<void> _mutationTail = Future<void>.value();

  @override
  Future<List<Listing>> fetchListings() async {
    await _ensureInitialized();
    return UnmodifiableListView(await _store.readAll());
  }

  @override
  Future<Listing> createListing(ListingDraft draft) {
    return _enqueueMutation(() async {
      await _ensureInitialized();
      final now = _clock();
      final normalized = draft.normalized();
      _validator.validateOrThrow(normalized, now);

      final listing = Listing(
        id: _idGenerator(now),
        neighborhoodId: Neighborhood.vidyavihar.id,
        kind: normalized.kind,
        title: normalized.title,
        description: normalized.description,
        category: normalized.category,
        approximateArea: normalized.approximateArea,
        contactPreference: normalized.contactPreference,
        createdAt: now,
        activeUntil: normalized.activeUntil,
        status: ListingStatus.open,
        isSaved: false,
        isContacted: false,
        origin: ListingOrigin.local,
      );
      await _store.insert(listing);
      return listing;
    });
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

  static String _generateListingId(DateTime now) {
    final random = Random.secure();
    final suffix = List.generate(
      2,
      (_) => random.nextInt(0x100000000).toRadixString(16).padLeft(8, '0'),
    ).join();
    return 'local-${now.toUtc().microsecondsSinceEpoch}-$suffix';
  }
}
