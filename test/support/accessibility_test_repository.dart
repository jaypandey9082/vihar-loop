import 'dart:async';

import 'package:vihar_loop/data/listing_repository.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/domain/listing_draft.dart';

class AccessibilityTestRepository implements ListingRepository {
  AccessibilityTestRepository({
    List<Listing> listings = const [],
    this.fetchFailure,
  }) : _listings = [...listings];

  List<Listing> _listings;
  Object? fetchFailure;
  Object? createFailure;
  Object? mutationFailure;
  Completer<Listing>? createCompleter;
  Completer<Listing>? mutationCompleter;
  int fetchCount = 0;
  int createCount = 0;
  int mutationCount = 0;

  List<Listing> get listings => List.unmodifiable(_listings);

  @override
  Future<List<Listing>> fetchListings() async {
    fetchCount += 1;
    if (fetchFailure case final failure?) {
      throw failure;
    }
    return listings;
  }

  @override
  Future<Listing> createListing(ListingDraft draft) async {
    createCount += 1;
    if (createFailure case final failure?) {
      throw failure;
    }
    if (createCompleter case final pending?) {
      final listing = await pending.future;
      _listings = [..._listings, listing];
      return listing;
    }
    final listing = listingFromDraft(draft);
    _listings = [..._listings, listing];
    return listing;
  }

  @override
  Future<Listing> setSaved({
    required String listingId,
    required bool isSaved,
  }) {
    return _mutate(
      listingId,
      (listing) => listing.copyWith(isSaved: isSaved),
    );
  }

  @override
  Future<Listing> setContacted({
    required String listingId,
    required bool isContacted,
  }) {
    return _mutate(
      listingId,
      (listing) => listing.copyWith(isContacted: isContacted),
    );
  }

  @override
  Future<Listing> setStatus({
    required String listingId,
    required ListingStatus status,
  }) {
    return _mutate(listingId, (listing) => listing.copyWith(status: status));
  }

  Future<Listing> _mutate(
    String id,
    Listing Function(Listing listing) change,
  ) async {
    mutationCount += 1;
    if (mutationFailure case final failure?) {
      throw failure;
    }
    if (mutationCompleter case final pending?) {
      final listing = await pending.future;
      _replace(listing);
      return listing;
    }
    final current = _listings.singleWhere((listing) => listing.id == id);
    final updated = change(current);
    _replace(updated);
    return updated;
  }

  void _replace(Listing listing) {
    final index = _listings.indexWhere((value) => value.id == listing.id);
    final next = [..._listings];
    next[index] = listing;
    _listings = next;
  }
}

Listing accessibilityListing({
  String id = 'accessibility-listing',
  String title = 'USB-C laptop charger for two hours',
  String description = 'A charger would help finish an assignment.',
  ListingKind kind = ListingKind.need,
  ListingStatus status = ListingStatus.open,
  ListingOrigin origin = ListingOrigin.sample,
  bool isSaved = false,
  bool isContacted = false,
  DateTime? createdAt,
  DateTime? activeUntil,
}) {
  final now = DateTime(2026, 7, 30, 12);
  return Listing(
    id: id,
    neighborhoodId: 'vidyavihar',
    kind: kind,
    title: title,
    description: description,
    category: ListingCategory.electronics,
    approximateArea: ApproximateArea.somaiyaSide,
    contactPreference: ContactPreference.publicPlace,
    createdAt: createdAt ?? now,
    activeUntil: activeUntil ?? now.add(const Duration(hours: 2)),
    status: status,
    isSaved: isSaved,
    isContacted: isContacted,
    origin: origin,
  );
}

Listing listingFromDraft(ListingDraft draft) {
  final now = DateTime(2026, 7, 30, 12);
  return Listing(
    id: 'created-accessibility-listing',
    neighborhoodId: 'vidyavihar',
    kind: draft.kind,
    title: draft.title.trim(),
    description: draft.description.trim(),
    category: draft.category,
    approximateArea: draft.approximateArea,
    contactPreference: draft.contactPreference,
    createdAt: now,
    activeUntil: draft.activeUntil,
    status: ListingStatus.open,
    isSaved: false,
    isContacted: false,
    origin: ListingOrigin.local,
  );
}
