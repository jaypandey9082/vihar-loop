import 'package:flutter_test/flutter_test.dart';
import 'package:vihar_loop/data/listing_repository.dart';
import 'package:vihar_loop/domain/listing.dart';
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
}

class _FakeListingRepository implements ListingRepository {
  _FakeListingRepository.responses(this._responses);

  final List<Object> _responses;
  int callCount = 0;

  @override
  Future<List<Listing>> fetchListings() async {
    final response = _responses[callCount++];
    if (response is List<Listing>) {
      return response;
    }
    throw response;
  }
}

Listing _listing({
  required String id,
  DateTime? activeUntil,
  ListingStatus status = ListingStatus.open,
}) {
  final createdAt = DateTime(2026, 7, 28, 12);
  return Listing(
    id: id,
    neighborhoodId: 'vidyavihar',
    kind: ListingKind.need,
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
    origin: ListingOrigin.sample,
  );
}
