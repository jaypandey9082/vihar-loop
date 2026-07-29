import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vihar_loop/data/listing_repository.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/domain/listing_draft.dart';
import 'package:vihar_loop/features/create_listing/create_listing_view_model.dart';

import '../../support/listing_fixture.dart';

void main() {
  final draft = ListingDraft(
    kind: ListingKind.need,
    title: 'Music stand needed',
    description: 'A foldable stand would help with rehearsal.',
    category: ListingCategory.musicHobbiesAndSports,
    approximateArea: ApproximateArea.somaiyaSide,
    contactPreference: ContactPreference.publicPlace,
    activeUntil: DateTime(2026, 7, 30, 14),
  );

  test('starts idle without a failure message', () {
    final viewModel = CreateListingViewModel(
      repository: _CreateRepository(),
    );
    addTearDown(viewModel.dispose);

    expect(viewModel.isSubmitting, isFalse);
    expect(viewModel.failureMessage, isNull);
  });

  test('returns persisted listing and sends the exact draft', () async {
    final persisted = buildTestListing(origin: ListingOrigin.local);
    final repository = _CreateRepository()..nextResult = persisted;
    final viewModel = CreateListingViewModel(repository: repository);
    addTearDown(viewModel.dispose);

    expect(await viewModel.create(draft), same(persisted));
    expect(repository.drafts.single, same(draft));
    expect(viewModel.isSubmitting, isFalse);
    expect(viewModel.failureMessage, isNull);
  });

  test('exposes pending state and refuses a second submission', () async {
    final pending = Completer<Listing>();
    final repository = _CreateRepository()..pending = pending;
    final viewModel = CreateListingViewModel(repository: repository);
    addTearDown(viewModel.dispose);

    final first = viewModel.create(draft);
    expect(viewModel.isSubmitting, isTrue);
    expect(await viewModel.create(draft), isNull);
    expect(repository.drafts, hasLength(1));

    final persisted = buildTestListing(origin: ListingOrigin.local);
    pending.complete(persisted);
    expect(await first, same(persisted));
    expect(viewModel.isSubmitting, isFalse);
  });

  test('failure is friendly and a later retry succeeds', () async {
    final persisted = buildTestListing(origin: ListingOrigin.local);
    final repository = _CreateRepository()
      ..failure = StateError('Hive technical detail');
    final viewModel = CreateListingViewModel(repository: repository);
    addTearDown(viewModel.dispose);

    expect(await viewModel.create(draft), isNull);
    expect(viewModel.isSubmitting, isFalse);
    expect(
      viewModel.failureMessage,
      CreateListingViewModel.createFailureMessage,
    );
    expect(viewModel.failureMessage, isNot(contains('Hive technical detail')));

    repository
      ..failure = null
      ..nextResult = persisted;
    expect(await viewModel.create(draft), same(persisted));
    expect(viewModel.failureMessage, isNull);
  });

  test('does not notify after disposal while create is pending', () async {
    final pending = Completer<Listing>();
    final viewModel = CreateListingViewModel(
      repository: _CreateRepository()..pending = pending,
    );
    var notifications = 0;
    viewModel.addListener(() => notifications++);

    final result = viewModel.create(draft);
    expect(notifications, 1);
    viewModel.dispose();
    pending.complete(buildTestListing(origin: ListingOrigin.local));

    expect(await result, isNotNull);
    expect(notifications, 1);
  });
}

class _CreateRepository implements ListingRepository {
  final drafts = <ListingDraft>[];
  Listing? nextResult;
  Object? failure;
  Completer<Listing>? pending;

  @override
  Future<Listing> createListing(ListingDraft draft) async {
    drafts.add(draft);
    if (failure case final error?) {
      throw error;
    }
    if (pending case final completer?) {
      return completer.future;
    }
    return nextResult!;
  }

  @override
  Future<List<Listing>> fetchListings() async => const [];

  @override
  Future<Listing> setSaved({
    required String listingId,
    required bool isSaved,
  }) {
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
  Future<Listing> setStatus({
    required String listingId,
    required ListingStatus status,
  }) {
    throw UnimplementedError();
  }
}
