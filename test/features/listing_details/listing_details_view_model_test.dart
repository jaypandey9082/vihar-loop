import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vihar_loop/data/listing_repository.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/domain/listing_draft.dart';
import 'package:vihar_loop/features/listing_details/listing_details_view_model.dart';

import '../../support/listing_fixture.dart';

void main() {
  group('ListingDetailsViewModel', () {
    test('exposes initial state and ownership capability', () {
      final sample = buildTestListing(origin: ListingOrigin.sample);
      final local = buildTestListing(origin: ListingOrigin.local);
      final sampleViewModel = ListingDetailsViewModel(
        repository: _DetailsRepository(sample),
        initialListing: sample,
      );
      final localViewModel = ListingDetailsViewModel(
        repository: _DetailsRepository(local),
        initialListing: local,
      );
      addTearDown(sampleViewModel.dispose);
      addTearDown(localViewModel.dispose);

      expect(identical(sampleViewModel.listing, sample), isTrue);
      expect(sampleViewModel.pendingAction, isNull);
      expect(sampleViewModel.isActionRunning, isFalse);
      expect(sampleViewModel.failureMessage, isNull);
      expect(sampleViewModel.canChangeStatus, isFalse);
      expect(localViewModel.canChangeStatus, isTrue);
    });

    test('successful saved and contacted actions use the stable ID', () async {
      final listing = buildTestListing(
        isSaved: false,
        isContacted: false,
      );
      final repository = _DetailsRepository(listing);
      final viewModel = ListingDetailsViewModel(
        repository: repository,
        initialListing: listing,
      );
      addTearDown(viewModel.dispose);

      expect(await viewModel.setSaved(true), isTrue);
      expect(viewModel.listing.isSaved, isTrue);
      expect(repository.lastListingId, listing.id);
      expect(repository.lastSavedValue, isTrue);

      expect(await viewModel.setContacted(true), isTrue);
      expect(viewModel.listing.isSaved, isTrue);
      expect(viewModel.listing.isContacted, isTrue);
      expect(repository.lastListingId, listing.id);
      expect(repository.lastContactedValue, isTrue);
      expect(viewModel.pendingAction, isNull);
    });

    test('local listing closes and reopens while sample status is refused',
        () async {
      final local = buildTestListing(origin: ListingOrigin.local);
      final localRepository = _DetailsRepository(local);
      final localViewModel = ListingDetailsViewModel(
        repository: localRepository,
        initialListing: local,
      );
      addTearDown(localViewModel.dispose);

      expect(await localViewModel.setStatus(ListingStatus.closed), isTrue);
      expect(localViewModel.listing.status, ListingStatus.closed);
      expect(localRepository.lastStatusValue, ListingStatus.closed);
      expect(await localViewModel.setStatus(ListingStatus.open), isTrue);
      expect(localViewModel.listing.status, ListingStatus.open);

      final sample = buildTestListing(origin: ListingOrigin.sample);
      final sampleRepository = _DetailsRepository(sample);
      final sampleViewModel = ListingDetailsViewModel(
        repository: sampleRepository,
        initialListing: sample,
      );
      addTearDown(sampleViewModel.dispose);

      expect(await sampleViewModel.setStatus(ListingStatus.closed), isFalse);
      expect(sampleRepository.statusCalls, 0);
      expect(sampleViewModel.listing.status, ListingStatus.open);
    });

    test('exposes one pending action and refuses a second action', () async {
      final listing = buildTestListing(isSaved: false);
      final pending = Completer<Listing>();
      final repository = _DetailsRepository(listing)
        ..savedResult = pending.future;
      final viewModel = ListingDetailsViewModel(
        repository: repository,
        initialListing: listing,
      );
      addTearDown(viewModel.dispose);

      final first = viewModel.setSaved(true);
      expect(viewModel.pendingAction, ListingDetailsAction.saved);
      expect(viewModel.isActionRunning, isTrue);

      expect(await viewModel.setContacted(true), isFalse);
      expect(repository.contactedCalls, 0);

      pending.complete(listing.copyWith(isSaved: true));
      expect(await first, isTrue);
      expect(viewModel.listing.isSaved, isTrue);
      expect(viewModel.pendingAction, isNull);
      expect(viewModel.isActionRunning, isFalse);
    });

    test('save failure preserves listing and exposes friendly copy', () async {
      final listing = buildTestListing(isSaved: false);
      final repository = _DetailsRepository(listing)
        ..savedError = StateError('Hive box internals');
      final viewModel = ListingDetailsViewModel(
        repository: repository,
        initialListing: listing,
      );
      addTearDown(viewModel.dispose);

      expect(await viewModel.setSaved(true), isFalse);

      expect(identical(viewModel.listing, listing), isTrue);
      expect(
        viewModel.failureMessage,
        ListingDetailsViewModel.savedFailureMessage,
      );
      expect(viewModel.failureMessage, isNot(contains('Hive')));
      expect(viewModel.pendingAction, isNull);
    });

    test('contacted and status failures use action-specific friendly copy',
        () async {
      final listing = buildTestListing(
        origin: ListingOrigin.local,
        isContacted: false,
      );
      final repository = _DetailsRepository(listing)
        ..contactedError = Exception('technical contact failure')
        ..statusError = Exception('technical status failure');
      final viewModel = ListingDetailsViewModel(
        repository: repository,
        initialListing: listing,
      );
      addTearDown(viewModel.dispose);

      expect(await viewModel.setContacted(true), isFalse);
      expect(
        viewModel.failureMessage,
        ListingDetailsViewModel.contactedFailureMessage,
      );
      expect(viewModel.listing.isContacted, isFalse);
      expect(viewModel.pendingAction, isNull);

      expect(await viewModel.setStatus(ListingStatus.closed), isFalse);
      expect(
        viewModel.failureMessage,
        ListingDetailsViewModel.statusFailureMessage,
      );
      expect(viewModel.listing.status, ListingStatus.open);
      expect(viewModel.pendingAction, isNull);
    });

    test('a successful retry clears an old failure message', () async {
      final listing = buildTestListing(isSaved: false);
      final repository = _DetailsRepository(listing)
        ..savedError = Exception('first failure');
      final viewModel = ListingDetailsViewModel(
        repository: repository,
        initialListing: listing,
      );
      addTearDown(viewModel.dispose);

      expect(await viewModel.setSaved(true), isFalse);
      repository.savedError = null;

      expect(await viewModel.setSaved(true), isTrue);
      expect(viewModel.failureMessage, isNull);
      expect(viewModel.listing.isSaved, isTrue);
    });
  });
}

class _DetailsRepository implements ListingRepository {
  _DetailsRepository(this.current);

  Listing current;
  Future<Listing>? savedResult;
  Object? savedError;
  Object? contactedError;
  Object? statusError;

  int savedCalls = 0;
  int contactedCalls = 0;
  int statusCalls = 0;
  String? lastListingId;
  bool? lastSavedValue;
  bool? lastContactedValue;
  ListingStatus? lastStatusValue;

  @override
  Future<List<Listing>> fetchListings() async => [current];

  @override
  Future<Listing> createListing(ListingDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<List<Listing>> resetLocalData() {
    throw UnimplementedError();
  }

  @override
  Future<Listing> setSaved({
    required String listingId,
    required bool isSaved,
  }) async {
    savedCalls++;
    lastListingId = listingId;
    lastSavedValue = isSaved;
    if (savedError case final error?) {
      throw error;
    }
    if (savedResult case final result?) {
      current = await result;
      return current;
    }
    current = current.copyWith(isSaved: isSaved);
    return current;
  }

  @override
  Future<Listing> setContacted({
    required String listingId,
    required bool isContacted,
  }) async {
    contactedCalls++;
    lastListingId = listingId;
    lastContactedValue = isContacted;
    if (contactedError case final error?) {
      throw error;
    }
    current = current.copyWith(isContacted: isContacted);
    return current;
  }

  @override
  Future<Listing> setStatus({
    required String listingId,
    required ListingStatus status,
  }) async {
    statusCalls++;
    lastListingId = listingId;
    lastStatusValue = status;
    if (statusError case final error?) {
      throw error;
    }
    current = current.copyWith(status: status);
    return current;
  }
}
