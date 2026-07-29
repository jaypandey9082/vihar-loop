import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vihar_loop/data/listing_repository.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/domain/listing_draft.dart';
import 'package:vihar_loop/features/privacy_data/privacy_data_view_model.dart';

import '../../support/listing_fixture.dart';

void main() {
  test('starts idle without a failure message', () {
    final viewModel = PrivacyDataViewModel(
      repository: _ResetRepository(),
    );
    addTearDown(viewModel.dispose);

    expect(viewModel.isResetting, isFalse);
    expect(viewModel.failureMessage, isNull);
  });

  test('successful reset exposes pending and returns exact persisted list',
      () async {
    final persisted = [buildTestListing(origin: ListingOrigin.sample)];
    final pending = Completer<List<Listing>>();
    final repository = _ResetRepository(pending: pending);
    final viewModel = PrivacyDataViewModel(repository: repository);
    addTearDown(viewModel.dispose);
    var notifications = 0;
    viewModel.addListener(() => notifications++);

    final result = viewModel.resetLocalData();

    expect(viewModel.isResetting, isTrue);
    expect(notifications, 1);
    expect(repository.resetCalls, 1);
    expect(await viewModel.resetLocalData(), isNull);
    expect(repository.resetCalls, 1);

    pending.complete(persisted);
    expect(await result, same(persisted));
    expect(viewModel.isResetting, isFalse);
    expect(viewModel.failureMessage, isNull);
    expect(notifications, 2);
  });

  test('failure is friendly, clears pending, and retry can succeed', () async {
    final repository = _ResetRepository(failure: Exception('box path secret'));
    final viewModel = PrivacyDataViewModel(repository: repository);
    addTearDown(viewModel.dispose);

    expect(await viewModel.resetLocalData(), isNull);
    expect(viewModel.isResetting, isFalse);
    expect(
      viewModel.failureMessage,
      PrivacyDataViewModel.resetFailureMessage,
    );
    expect(viewModel.failureMessage, isNot(contains('box path secret')));

    repository.failure = null;
    repository.result = [buildTestListing(origin: ListingOrigin.sample)];
    expect(await viewModel.resetLocalData(), same(repository.result));
    expect(viewModel.failureMessage, isNull);
    expect(repository.resetCalls, 2);
  });

  test('does not notify after disposal while reset is pending', () async {
    final pending = Completer<List<Listing>>();
    final viewModel = PrivacyDataViewModel(
      repository: _ResetRepository(pending: pending),
    );
    var notifications = 0;
    viewModel.addListener(() => notifications++);

    final result = viewModel.resetLocalData();
    expect(notifications, 1);
    viewModel.dispose();
    pending.complete([buildTestListing(origin: ListingOrigin.sample)]);

    expect(await result, isNotNull);
    expect(notifications, 1);
  });
}

class _ResetRepository implements ListingRepository {
  _ResetRepository({
    this.failure,
    this.pending,
  });

  List<Listing>? result;
  Object? failure;
  Completer<List<Listing>>? pending;
  int resetCalls = 0;

  @override
  Future<List<Listing>> resetLocalData() async {
    resetCalls++;
    if (failure case final error?) {
      throw error;
    }
    if (pending case final completer?) {
      return completer.future;
    }
    return result ?? const [];
  }

  @override
  Future<Listing> createListing(ListingDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<List<Listing>> fetchListings() {
    throw UnimplementedError();
  }

  @override
  Future<Listing> setContacted({
    required String listingId,
    required bool isContacted,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Listing> setSaved({
    required String listingId,
    required bool isSaved,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Listing> setStatus({
    required String listingId,
    required ListingStatus status,
  }) {
    throw UnimplementedError();
  }
}
