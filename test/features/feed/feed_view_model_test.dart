import 'package:flutter_test/flutter_test.dart';
import 'package:vihar_loop/data/listing_repository.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/domain/listing_draft.dart';
import 'package:vihar_loop/features/feed/feed_view_model.dart';

void main() {
  test('starts in the initial state', () {
    final viewModel = FeedViewModel(
      repository: _FakeListingRepository.responses([
        const <Listing>[],
      ]),
    );
    addTearDown(viewModel.dispose);

    expect(viewModel.status, FeedStatus.initial);
    expect(viewModel.listings, isEmpty);
    expect(viewModel.message, isNull);
  });

  test('loads and sorts open listings by urgency before closed listings',
      () async {
    final now = DateTime(2026, 7, 28, 12);
    final later = _listing(
      id: 'later',
      activeUntil: now.add(const Duration(hours: 4)),
    );
    final urgent = _listing(
      id: 'urgent',
      activeUntil: now.add(const Duration(hours: 1)),
    );
    final closed = _listing(
      id: 'closed',
      activeUntil: now.subtract(const Duration(hours: 1)),
      status: ListingStatus.closed,
    );
    final viewModel = FeedViewModel(
      repository: _FakeListingRepository.responses([
        [later, closed, urgent],
      ]),
    );
    addTearDown(viewModel.dispose);

    await viewModel.loadListings();

    expect(viewModel.status, FeedStatus.ready);
    expect(
      viewModel.listings.map((listing) => listing.id),
      ['urgent', 'later', 'closed'],
    );
    expect(
      () => viewModel.listings.add(urgent),
      throwsUnsupportedError,
    );
  });

  test('produces an empty state', () async {
    final viewModel = FeedViewModel(
      repository: _FakeListingRepository.responses([
        const <Listing>[],
      ]),
    );
    addTearDown(viewModel.dispose);

    await viewModel.loadListings();

    expect(viewModel.status, FeedStatus.empty);
  });

  test('produces a friendly failed state without technical details', () async {
    final viewModel = FeedViewModel(
      repository: _FakeListingRepository.responses([
        StateError('database internals'),
      ]),
    );
    addTearDown(viewModel.dispose);

    await viewModel.loadListings();

    expect(viewModel.status, FeedStatus.failed);
    expect(viewModel.message, FeedViewModel.failureMessage);
    expect(viewModel.message, isNot(contains('database internals')));
  });

  test('retry calls the repository again and can recover', () async {
    final repository = _FakeListingRepository.responses([
      StateError('first load fails'),
      [_listing(id: 'recovered')],
    ]);
    final viewModel = FeedViewModel(repository: repository);
    addTearDown(viewModel.dispose);

    await viewModel.loadListings();
    await viewModel.retry();

    expect(repository.callCount, 2);
    expect(viewModel.status, FeedStatus.ready);
    expect(viewModel.listings.single.id, 'recovered');
  });

  test('applies saved and contacted updates without changing other listings',
      () async {
    final first = _listing(id: 'first');
    final other = _listing(id: 'other');
    final repository = _FakeListingRepository.responses([
      [first, other],
    ]);
    final viewModel = FeedViewModel(repository: repository);
    addTearDown(viewModel.dispose);
    await viewModel.loadListings();

    expect(viewModel.applyListingUpdate(first.copyWith(isSaved: true)), isTrue);
    expect(
      viewModel.applyListingUpdate(
        first.copyWith(isSaved: true, isContacted: true),
      ),
      isTrue,
    );

    final updated =
        viewModel.listings.singleWhere((listing) => listing.id == first.id);
    final unchanged =
        viewModel.listings.singleWhere((listing) => listing.id == other.id);
    expect(updated.isSaved, isTrue);
    expect(updated.isContacted, isTrue);
    expect(identical(unchanged, other), isTrue);
    expect(viewModel.status, FeedStatus.ready);
    expect(() => viewModel.listings.add(first), throwsUnsupportedError);
    expect(repository.mutationCalls, 0);
  });

  test('closing and reopening reapply the existing feed ordering', () async {
    final now = DateTime(2026, 7, 30, 12);
    final urgent = _listing(
      id: 'urgent',
      activeUntil: now.add(const Duration(hours: 1)),
      origin: ListingOrigin.local,
    );
    final later = _listing(
      id: 'later',
      activeUntil: now.add(const Duration(hours: 4)),
    );
    final viewModel = FeedViewModel(
      repository: _FakeListingRepository.responses([
        [later, urgent],
      ]),
    );
    addTearDown(viewModel.dispose);
    await viewModel.loadListings();

    expect(
        viewModel.listings.map((listing) => listing.id), ['urgent', 'later']);

    viewModel.applyListingUpdate(
      urgent.copyWith(status: ListingStatus.closed),
    );
    expect(
        viewModel.listings.map((listing) => listing.id), ['later', 'urgent']);

    viewModel.applyListingUpdate(urgent.copyWith(status: ListingStatus.open));
    expect(
        viewModel.listings.map((listing) => listing.id), ['urgent', 'later']);
  });

  test('unknown and identical updates do not change or notify', () async {
    final listing = _listing(id: 'known');
    final viewModel = FeedViewModel(
      repository: _FakeListingRepository.responses([
        [listing],
      ]),
    );
    addTearDown(viewModel.dispose);
    await viewModel.loadListings();
    var notifications = 0;
    viewModel.addListener(() => notifications++);

    expect(
      viewModel.applyListingUpdate(_listing(id: 'unknown')),
      isFalse,
    );
    expect(viewModel.applyListingUpdate(listing.copyWith()), isFalse);

    expect(viewModel.listings, hasLength(1));
    expect(viewModel.listings.single.id, 'known');
    expect(notifications, 0);
  });

  test('kind and time filters combine without changing source or fetching',
      () async {
    final now = DateTime(2026, 7, 30, 12);
    final needSoon = _listing(
      id: 'need-soon',
      activeUntil: now.add(const Duration(hours: 2)),
    );
    final offerToday = _listing(
      id: 'offer-today',
      kind: ListingKind.offer,
      activeUntil: DateTime(2026, 7, 30, 20),
    );
    final needTomorrow = _listing(
      id: 'need-tomorrow',
      activeUntil: DateTime(2026, 7, 31, 10),
    );
    final closed = _listing(
      id: 'closed',
      activeUntil: now.add(const Duration(hours: 1)),
      status: ListingStatus.closed,
    );
    final past = _listing(
      id: 'past',
      activeUntil: now.subtract(const Duration(hours: 1)),
    );
    final repository = _FakeListingRepository.responses([
      [needTomorrow, closed, offerToday, past, needSoon],
    ]);
    final viewModel = FeedViewModel(
      repository: repository,
      clock: () => now,
    );
    addTearDown(viewModel.dispose);
    await viewModel.loadListings();
    final sourceIds = viewModel.listings.map((listing) => listing.id).toList();

    viewModel.setKindFilter(FeedKindFilter.needs);
    expect(
      viewModel.visibleListings.map((listing) => listing.id),
      containsAll(['need-soon', 'need-tomorrow', 'closed', 'past']),
    );
    viewModel.setTimeFilter(FeedTimeFilter.today);
    expect(
      viewModel.visibleListings.map((listing) => listing.id),
      ['need-soon'],
    );
    viewModel.setKindFilter(FeedKindFilter.offers);
    expect(
      viewModel.visibleListings.map((listing) => listing.id),
      ['offer-today'],
    );
    viewModel.setTimeFilter(FeedTimeFilter.endingSoon);
    expect(viewModel.visibleListings, isEmpty);
    expect(viewModel.status, FeedStatus.ready);
    expect(viewModel.totalCount, 5);
    expect(viewModel.visibleCount, 0);
    expect(viewModel.hasActiveFilters, isTrue);
    expect(viewModel.listings.map((listing) => listing.id), sourceIds);
    expect(repository.callCount, 1);
    expect(
      () => viewModel.visibleListings.add(needSoon),
      throwsUnsupportedError,
    );

    viewModel.clearFilters();
    expect(viewModel.kindFilter, FeedKindFilter.all);
    expect(viewModel.timeFilter, FeedTimeFilter.all);
    expect(viewModel.visibleCount, 5);
  });

  test('reselecting filters is quiet and Ending soon includes its boundary',
      () async {
    final now = DateTime(2026, 7, 30, 12);
    final boundary = _listing(
      id: 'boundary',
      kind: ListingKind.offer,
      activeUntil: now.add(const Duration(hours: 3)),
    );
    final viewModel = FeedViewModel(
      repository: _FakeListingRepository.responses([
        [boundary],
      ]),
      clock: () => now,
    );
    addTearDown(viewModel.dispose);
    await viewModel.loadListings();
    var notifications = 0;
    viewModel.addListener(() => notifications++);

    viewModel.setKindFilter(FeedKindFilter.all);
    viewModel.setTimeFilter(FeedTimeFilter.all);
    expect(notifications, 0);
    viewModel.setTimeFilter(FeedTimeFilter.endingSoon);
    expect(notifications, 1);
    expect(viewModel.visibleListings.single.id, 'boundary');
  });

  test('addCreatedListing validates origin, resets filters, and sorts',
      () async {
    final now = DateTime(2026, 7, 30, 12);
    final repository = _FakeListingRepository.responses([
      const <Listing>[],
    ]);
    final viewModel = FeedViewModel(
      repository: repository,
      clock: () => now,
    );
    addTearDown(viewModel.dispose);
    await viewModel.loadListings();
    viewModel.setKindFilter(FeedKindFilter.offers);
    viewModel.setTimeFilter(FeedTimeFilter.today);
    final created = _listing(
      id: 'created',
      origin: ListingOrigin.local,
      activeUntil: now.add(const Duration(hours: 1)),
    );

    expect(viewModel.addCreatedListing(created), isTrue);
    expect(viewModel.status, FeedStatus.ready);
    expect(viewModel.listings.single, same(created));
    expect(viewModel.kindFilter, FeedKindFilter.all);
    expect(viewModel.timeFilter, FeedTimeFilter.all);
    expect(viewModel.addCreatedListing(created), isFalse);
    expect(
      viewModel.addCreatedListing(_listing(id: 'sample')),
      isFalse,
    );
    expect(viewModel.listings, hasLength(1));
    expect(repository.mutationCalls, 0);
  });

  test('details updates recalculate an active Today filter', () async {
    final now = DateTime(2026, 7, 30, 12);
    final local = _listing(
      id: 'local',
      origin: ListingOrigin.local,
      activeUntil: now.add(const Duration(hours: 2)),
    );
    final viewModel = FeedViewModel(
      repository: _FakeListingRepository.responses([
        [local],
      ]),
      clock: () => now,
    );
    addTearDown(viewModel.dispose);
    await viewModel.loadListings();
    viewModel.setTimeFilter(FeedTimeFilter.today);

    expect(viewModel.visibleListings, hasLength(1));
    viewModel.applyListingUpdate(local.copyWith(status: ListingStatus.closed));
    expect(viewModel.visibleListings, isEmpty);
    viewModel.applyListingUpdate(local.copyWith(status: ListingStatus.open));
    expect(viewModel.visibleListings, hasLength(1));
    viewModel.applyListingUpdate(local.copyWith(isSaved: true));
    expect(viewModel.visibleListings, hasLength(1));
    viewModel.applyListingUpdate(local.copyWith(isContacted: true));
    expect(viewModel.visibleListings, hasLength(1));
  });
}

class _FakeListingRepository implements ListingRepository {
  _FakeListingRepository.responses(this._responses);

  final List<Object> _responses;
  int callCount = 0;
  int mutationCalls = 0;

  @override
  Future<List<Listing>> fetchListings() async {
    final response = _responses[callCount++];
    if (response is List<Listing>) {
      return response;
    }
    throw response;
  }

  @override
  Future<Listing> createListing(ListingDraft draft) {
    mutationCalls++;
    throw UnimplementedError();
  }

  @override
  Future<Listing> setSaved({
    required String listingId,
    required bool isSaved,
  }) async {
    mutationCalls++;
    throw UnimplementedError();
  }

  @override
  Future<Listing> setContacted({
    required String listingId,
    required bool isContacted,
  }) async {
    mutationCalls++;
    throw UnimplementedError();
  }

  @override
  Future<Listing> setStatus({
    required String listingId,
    required ListingStatus status,
  }) async {
    mutationCalls++;
    throw UnimplementedError();
  }
}

Listing _listing({
  required String id,
  DateTime? activeUntil,
  ListingStatus status = ListingStatus.open,
  ListingOrigin origin = ListingOrigin.sample,
  ListingKind kind = ListingKind.need,
}) {
  final createdAt = DateTime(2026, 7, 28, 12);
  return Listing(
    id: id,
    neighborhoodId: 'vidyavihar',
    kind: kind,
    title: 'Test listing',
    description: 'A useful test description.',
    category: ListingCategory.other,
    approximateArea: ApproximateArea.otherVidyavihar,
    contactPreference: ContactPreference.communityGroup,
    createdAt: createdAt,
    activeUntil: activeUntil ?? createdAt.add(const Duration(hours: 2)),
    status: status,
    isSaved: false,
    isContacted: false,
    origin: origin,
  );
}
