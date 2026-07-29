import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vihar_loop/data/listing_repository.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/domain/listing_draft.dart';
import 'package:vihar_loop/features/create_listing/create_listing_view_model.dart';
import 'package:vihar_loop/local_ai/listing_suggestion.dart';

import '../../support/listing_fixture.dart';
import '../../support/test_local_ai_service.dart';

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
      localAiService: TestLocalAiService(),
    );
    addTearDown(viewModel.dispose);

    expect(viewModel.isSubmitting, isFalse);
    expect(viewModel.isSuggesting, isFalse);
    expect(viewModel.isBusy, isFalse);
    expect(viewModel.pendingAction, isNull);
    expect(viewModel.suggestion, isNull);
    expect(viewModel.suggestionFailureMessage, isNull);
    expect(viewModel.failureMessage, isNull);
  });

  test('returns persisted listing and sends the exact draft', () async {
    final persisted = buildTestListing(origin: ListingOrigin.local);
    final repository = _CreateRepository()..nextResult = persisted;
    final viewModel = CreateListingViewModel(
      repository: repository,
      localAiService: TestLocalAiService(),
    );
    addTearDown(viewModel.dispose);

    expect(await viewModel.create(draft), same(persisted));
    expect(repository.drafts.single, same(draft));
    expect(viewModel.isSubmitting, isFalse);
    expect(viewModel.failureMessage, isNull);
  });

  test('exposes pending state and refuses a second submission', () async {
    final pending = Completer<Listing>();
    final repository = _CreateRepository()..pending = pending;
    final viewModel = CreateListingViewModel(
      repository: repository,
      localAiService: TestLocalAiService(),
    );
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
    final viewModel = CreateListingViewModel(
      repository: repository,
      localAiService: TestLocalAiService(),
    );
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
      localAiService: TestLocalAiService(),
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

  test('suggests with exact input, exposes pending, and never persists',
      () async {
    final suggestion = const ListingSuggestion(
      kind: ListingKind.offer,
      title: 'Statistics notes',
      category: ListingCategory.booksAndStudy,
      source: ListingSuggestionSource.deterministicFallback,
    );
    final pending = Completer<ListingSuggestion>();
    final service = TestLocalAiService(result: suggestion, pending: pending);
    final repository = _CreateRepository();
    final viewModel = CreateListingViewModel(
      repository: repository,
      localAiService: service,
    );
    addTearDown(viewModel.dispose);

    final future = viewModel.suggestListing(
      description: 'Offering my statistics notes until tomorrow.',
      preferredKind: ListingKind.need,
    );
    expect(viewModel.pendingAction, CreateListingPendingAction.suggesting);
    expect(viewModel.isSuggesting, isTrue);
    expect(viewModel.isSubmitting, isFalse);
    expect(service.requests.single.description,
        'Offering my statistics notes until tomorrow.');
    expect(service.requests.single.preferredKind, ListingKind.need);
    expect(
        await viewModel.suggestListing(
          description: 'A second valid description.',
          preferredKind: ListingKind.offer,
        ),
        isNull);
    expect(service.requests, hasLength(1));

    pending.complete(suggestion);
    expect(await future, same(suggestion));
    expect(viewModel.suggestion, same(suggestion));
    expect(viewModel.pendingAction, isNull);
    expect(repository.drafts, isEmpty);
  });

  test('suggestion failure is friendly and retry succeeds', () async {
    final service = TestLocalAiService(
      failure: StateError('model implementation detail'),
    );
    final viewModel = CreateListingViewModel(
      repository: _CreateRepository(),
      localAiService: service,
    );
    addTearDown(viewModel.dispose);

    expect(
        await viewModel.suggestListing(
          description: 'A long enough useful description.',
          preferredKind: ListingKind.need,
        ),
        isNull);
    expect(viewModel.suggestion, isNull);
    expect(
      viewModel.suggestionFailureMessage,
      CreateListingViewModel.suggestionFailureCopy,
    );
    expect(
      viewModel.suggestionFailureMessage,
      isNot(contains('model implementation detail')),
    );
    expect(viewModel.pendingAction, isNull);

    service.failure = null;
    expect(
        await viewModel.suggestListing(
          description: 'A long enough useful description.',
          preferredKind: ListingKind.need,
        ),
        same(service.result));
    expect(viewModel.suggestionFailureMessage, isNull);
  });

  test('create and suggest mutually exclude each other', () async {
    final suggestionPending = Completer<ListingSuggestion>();
    final service = TestLocalAiService(pending: suggestionPending);
    final repository = _CreateRepository();
    final viewModel = CreateListingViewModel(
      repository: repository,
      localAiService: service,
    );
    addTearDown(viewModel.dispose);

    final suggestionFuture = viewModel.suggestListing(
      description: 'Need a useful rehearsal accessory today.',
      preferredKind: ListingKind.need,
    );
    expect(await viewModel.create(draft), isNull);
    expect(repository.drafts, isEmpty);
    suggestionPending.complete(service.result);
    await suggestionFuture;

    final createPending = Completer<Listing>();
    repository.pending = createPending;
    final createFuture = viewModel.create(draft);
    expect(
        await viewModel.suggestListing(
          description: 'Need a useful rehearsal accessory today.',
          preferredKind: ListingKind.need,
        ),
        isNull);
    expect(service.requests, hasLength(1));
    createPending.complete(buildTestListing(origin: ListingOrigin.local));
    await createFuture;
  });

  test('dismiss clears preview without service or repository calls', () async {
    final service = TestLocalAiService();
    final repository = _CreateRepository();
    final viewModel = CreateListingViewModel(
      repository: repository,
      localAiService: service,
    );
    addTearDown(viewModel.dispose);
    var notifications = 0;
    viewModel.addListener(() => notifications++);

    viewModel.dismissSuggestion();
    expect(notifications, 0);
    await viewModel.suggestListing(
      description: 'Need a useful rehearsal accessory today.',
      preferredKind: ListingKind.need,
    );
    final afterSuggestion = notifications;
    viewModel.dismissSuggestion();
    expect(viewModel.suggestion, isNull);
    expect(notifications, afterSuggestion + 1);
    expect(service.requests, hasLength(1));
    expect(repository.drafts, isEmpty);
  });

  test('does not notify after disposal while suggest is pending', () async {
    final pending = Completer<ListingSuggestion>();
    final service = TestLocalAiService(pending: pending);
    final viewModel = CreateListingViewModel(
      repository: _CreateRepository(),
      localAiService: service,
    );
    var notifications = 0;
    viewModel.addListener(() => notifications++);

    final result = viewModel.suggestListing(
      description: 'Need a useful rehearsal accessory today.',
      preferredKind: ListingKind.need,
    );
    expect(notifications, 1);
    viewModel.dispose();
    pending.complete(service.result);

    expect(await result, isNull);
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
  Future<List<Listing>> resetLocalData() {
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
