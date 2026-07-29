import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:vihar_loop/data/listing_repository.dart';
import 'package:vihar_loop/domain/listing.dart';

enum FeedStatus { initial, loading, ready, empty, failed }

class FeedViewModel extends ChangeNotifier {
  FeedViewModel({required ListingRepository repository})
      : _repository = repository;

  static const failureMessage =
      'We couldn’t load the local listings. Try again.';

  final ListingRepository _repository;
  List<Listing> _listings = const [];
  FeedStatus _status = FeedStatus.initial;
  String? _message;

  FeedStatus get status => _status;
  UnmodifiableListView<Listing> get listings => UnmodifiableListView(_listings);
  String? get message => _message;

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
