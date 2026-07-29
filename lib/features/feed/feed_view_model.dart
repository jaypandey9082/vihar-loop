import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:vihar_loop/core/clock.dart';
import 'package:vihar_loop/data/listing_repository.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/domain/listing_timing.dart';

enum FeedStatus { initial, loading, ready, empty, failed }

enum FeedKindFilter { all, needs, offers }

enum FeedTimeFilter { all, today, endingSoon }

class FeedViewModel extends ChangeNotifier {
  FeedViewModel({
    required ListingRepository repository,
    Clock? clock,
  })  : _repository = repository,
        _clock = clock ?? DateTime.now;

  static const failureMessage =
      'We couldn’t load the local listings. Try again.';

  final ListingRepository _repository;
  final Clock _clock;
  List<Listing> _listings = const [];
  FeedStatus _status = FeedStatus.initial;
  String? _message;
  FeedKindFilter _kindFilter = FeedKindFilter.all;
  FeedTimeFilter _timeFilter = FeedTimeFilter.all;

  FeedStatus get status => _status;
  UnmodifiableListView<Listing> get listings => UnmodifiableListView(_listings);
  UnmodifiableListView<Listing> get visibleListings {
    final now = _clock();
    return UnmodifiableListView(
      _listings.where((listing) {
        final kindMatches = switch (_kindFilter) {
          FeedKindFilter.all => true,
          FeedKindFilter.needs => listing.kind == ListingKind.need,
          FeedKindFilter.offers => listing.kind == ListingKind.offer,
        };
        final timeMatches = switch (_timeFilter) {
          FeedTimeFilter.all => true,
          FeedTimeFilter.today => listingIsToday(listing, now),
          FeedTimeFilter.endingSoon => listingIsEndingSoon(listing, now),
        };
        return kindMatches && timeMatches;
      }),
    );
  }

  String? get message => _message;
  FeedKindFilter get kindFilter => _kindFilter;
  FeedTimeFilter get timeFilter => _timeFilter;
  int get totalCount => _listings.length;
  int get visibleCount => visibleListings.length;
  bool get hasActiveFilters =>
      _kindFilter != FeedKindFilter.all || _timeFilter != FeedTimeFilter.all;

  ListingTimeBadge timeBadgeFor(Listing listing) {
    return listingTimeBadge(listing, _clock());
  }

  Future<void> loadListings() async {
    _setState(status: FeedStatus.loading, listings: const [], message: null);

    try {
      final loadedListings = await _repository.fetchListings();
      final sortedListings = loadedListings.toList()..sort(_compareListings);

      _setState(
        status: sortedListings.isEmpty ? FeedStatus.empty : FeedStatus.ready,
        listings: sortedListings,
        message: null,
      );
    } on Object {
      _setState(
        status: FeedStatus.failed,
        listings: const [],
        message: failureMessage,
      );
    }
  }

  Future<void> retry() => loadListings();

  void setKindFilter(FeedKindFilter value) {
    if (_kindFilter == value) {
      return;
    }
    _kindFilter = value;
    notifyListeners();
  }

  void setTimeFilter(FeedTimeFilter value) {
    if (_timeFilter == value) {
      return;
    }
    _timeFilter = value;
    notifyListeners();
  }

  void clearFilters() {
    if (!hasActiveFilters) {
      return;
    }
    _kindFilter = FeedKindFilter.all;
    _timeFilter = FeedTimeFilter.all;
    notifyListeners();
  }

  bool addCreatedListing(Listing listing) {
    if (listing.origin != ListingOrigin.local ||
        _listings.any((current) => current.id == listing.id)) {
      return false;
    }
    final updated = [..._listings, listing]..sort(_compareListings);
    _kindFilter = FeedKindFilter.all;
    _timeFilter = FeedTimeFilter.all;
    _setState(
      status: FeedStatus.ready,
      listings: updated,
      message: null,
    );
    return true;
  }

  bool applyListingUpdate(Listing listing) {
    if (_status != FeedStatus.ready) {
      return false;
    }

    final index = _listings.indexWhere((current) => current.id == listing.id);
    if (index == -1 || _sameListing(_listings[index], listing)) {
      return false;
    }

    final updated = _listings.toList();
    updated[index] = listing;
    updated.sort(_compareListings);
    _setState(status: FeedStatus.ready, listings: updated, message: null);
    return true;
  }

  bool applyLocalDataReset(List<Listing> listings) {
    final identifiers = <String>{};
    if (listings.any((listing) => !identifiers.add(listing.id))) {
      return false;
    }

    final replacement = listings.toList()..sort(_compareListings);
    _kindFilter = FeedKindFilter.all;
    _timeFilter = FeedTimeFilter.all;
    _setState(
      status: replacement.isEmpty ? FeedStatus.empty : FeedStatus.ready,
      listings: replacement,
      message: null,
    );
    return true;
  }

  // Open listings appear first, ordered by deadline, so urgent posts remain
  // discoverable. Closed posts follow in reverse creation order.
  static int _compareListings(Listing left, Listing right) {
    if (left.status != right.status) {
      return left.status == ListingStatus.open ? -1 : 1;
    }

    if (left.status == ListingStatus.open) {
      final deadlineOrder = left.activeUntil.compareTo(right.activeUntil);
      if (deadlineOrder != 0) {
        return deadlineOrder;
      }
    }

    return right.createdAt.compareTo(left.createdAt);
  }

  static bool _sameListing(Listing left, Listing right) {
    return left.id == right.id &&
        left.neighborhoodId == right.neighborhoodId &&
        left.kind == right.kind &&
        left.title == right.title &&
        left.description == right.description &&
        left.category == right.category &&
        left.approximateArea == right.approximateArea &&
        left.contactPreference == right.contactPreference &&
        left.createdAt == right.createdAt &&
        left.activeUntil == right.activeUntil &&
        left.status == right.status &&
        left.isSaved == right.isSaved &&
        left.isContacted == right.isContacted &&
        left.origin == right.origin;
  }

  void _setState({
    required FeedStatus status,
    required List<Listing> listings,
    required String? message,
  }) {
    final changed = _status != status ||
        _message != message ||
        !listEquals(_listings, listings);
    if (!changed) {
      return;
    }

    _status = status;
    _listings = List.unmodifiable(listings);
    _message = message;
    notifyListeners();
  }
}
