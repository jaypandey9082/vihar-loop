import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vihar_loop/data/listing_repository.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/domain/listing_draft.dart';
import 'package:vihar_loop/domain/listing_draft_validator.dart';
import 'package:vihar_loop/features/create_listing/create_listing_screen.dart';
import 'package:vihar_loop/features/create_listing/create_listing_view_model.dart';

void main() {
  final now = DateTime(2026, 7, 30, 12);

  testWidgets('shows the complete form and switches Need to Offer',
      (tester) async {
    await _openForm(tester, _FormRepository(), now);

    expect(find.text('Post a need or offer'), findsOneWidget);
    expect(
      find.text(
        'Share one small, time-sensitive need or offer with people around '
        'Vidyavihar.',
      ),
      findsOneWidget,
    );
    expect(find.text('I need something'), findsOneWidget);
    expect(find.text('I’m offering something'), findsOneWidget);

    await tester.tap(find.text('I’m offering something'));
    await tester.pumpAndSettle();
    await _scrollTo(tester, 'Choose date and time');
    expect(find.text('Available until'), findsOneWidget);
    expect(find.text('Post offer'), findsOneWidget);

    await _scrollTo(tester, 'Contact preference');
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Approximate area'), findsOneWidget);
    expect(find.text('Contact preference'), findsOneWidget);
    expect(find.text('Choose date and time'), findsOneWidget);
  });

  testWidgets('empty submit shows every required error and keeps values',
      (tester) async {
    final repository = _FormRepository();
    await _openForm(tester, repository, now);

    await tester.enterText(find.byType(TextFormField).first, 'four');
    await tester.enterText(find.byType(TextFormField).last, 'too short');
    await _scrollTo(tester, 'Post need');
    await tester.tap(find.text('Post need'));
    await tester.pumpAndSettle();

    expect(find.text('Check the highlighted fields.'), findsOneWidget);
    expect(repository.drafts, isEmpty);
    await _scrollTo(tester, 'Title');
    expect(find.text('Use at least 5 characters.'), findsOneWidget);
    expect(find.text('four'), findsOneWidget);
    expect(find.text('too short'), findsOneWidget);
    await _scrollTo(tester, 'Category');
    expect(find.text('Choose a category.'), findsOneWidget);
    expect(find.text('Choose an approximate area.'), findsOneWidget);
    expect(
      find.text('Choose how people should coordinate.'),
      findsOneWidget,
    );
    expect(
      find.text('Choose when this need or offer ends.'),
      findsOneWidget,
    );
  });

  testWidgets('date and time picker displays a valid local deadline',
      (tester) async {
    await _openForm(tester, _FormRepository(), now);
    await _scrollTo(tester, 'Choose date and time');

    await tester.tap(find.text('Choose date and time'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Jul 30'), findsOneWidget);
  });

  testWidgets('visible validation rejects email, URL, and phone text',
      (tester) async {
    final repository = _FormRepository();
    await _openForm(tester, repository, now);

    await tester.enterText(
      find.byType(TextFormField).first,
      'user@example.test',
    );
    await tester.enterText(
      find.byType(TextFormField).last,
      'A normal description with enough detail.',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await _scrollTo(tester, 'Post need');
    await tester.tap(find.text('Post need'));
    await tester.pumpAndSettle();
    expect(repository.drafts, isEmpty);
    await _scrollTo(tester, 'Title');
    expect(
      find.text(ListingDraftValidator.directContactError),
      findsOneWidget,
    );

    await tester.enterText(
      find.byType(TextFormField).first,
      'See www.example.test/listing',
    );
    await tester.enterText(
      find.byType(TextFormField).last,
      'Please call +91 98765-43210 after rehearsal.',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await _scrollTo(tester, 'Post need');
    await tester.tap(find.text('Post need'));
    await tester.pumpAndSettle();
    expect(repository.drafts, isEmpty);
    await _scrollTo(tester, 'Title');
    expect(
      find.text(ListingDraftValidator.directContactError),
      findsNWidgets(2),
    );
    expect(find.text('See www.example.test/listing'), findsOneWidget);
    expect(
      find.text('Please call +91 98765-43210 after rehearsal.'),
      findsOneWidget,
    );
  });

  testWidgets('visible validation distinguishes precise-location text',
      (tester) async {
    final repository = _FormRepository();
    await _openForm(tester, repository, now);

    await tester.enterText(
      find.byType(TextFormField).first,
      'Calculator from Flat 302',
    );
    await tester.enterText(
      find.byType(TextFormField).last,
      'Collect this useful calculator from Wing B after class.',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await _scrollTo(tester, 'Post need');
    await tester.tap(find.text('Post need'));
    await tester.pumpAndSettle();

    expect(repository.drafts, isEmpty);
    await _scrollTo(tester, 'Title');
    expect(
      find.text(ListingDraftValidator.preciseLocationError),
      findsNWidgets(2),
    );
    expect(find.text('Calculator from Flat 302'), findsOneWidget);
    expect(
      find.text('Collect this useful calculator from Wing B after class.'),
      findsOneWidget,
    );
  });

  testWidgets('successful submit returns exact persisted listing',
      (tester) async {
    final repository = _FormRepository();
    Listing? returned;
    await _openForm(
      tester,
      repository,
      now,
      onReturned: (listing) => returned = listing,
    );
    await _fillValidForm(tester);

    await tester.tap(find.text('Post need'));
    await tester.pumpAndSettle();

    expect(repository.drafts, hasLength(1));
    expect(
        repository.drafts.single.title, 'Foldable music stand for rehearsal');
    expect(repository.drafts.single.kind, ListingKind.need);
    expect(returned, same(repository.lastCreated));
    expect(find.text('Open create'), findsOneWidget);
  });

  testWidgets('pending disables form, blocks back, and prevents duplicate post',
      (tester) async {
    final pending = Completer<Listing>();
    final repository = _FormRepository()..pending = pending;
    await _openForm(tester, repository, now);
    await _fillValidForm(tester);

    await tester.tap(find.text('Post need'));
    await tester.pump();
    expect(find.text('Posting…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final title =
        tester.widget<TextFormField>(find.byType(TextFormField).first);
    expect(title.enabled, isFalse);

    await tester.tap(find.text('Posting…'));
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(repository.drafts, hasLength(1));
    expect(find.text('Posting this listing…'), findsOneWidget);

    pending.complete(repository.createdFrom(repository.drafts.single));
    await tester.pumpAndSettle();
  });

  testWidgets('repository failure keeps draft and retry succeeds',
      (tester) async {
    final repository = _FormRepository()
      ..failure = StateError('raw storage failure');
    await _openForm(tester, repository, now);
    await _fillValidForm(tester);

    await tester.tap(find.text('Post need'));
    await tester.pumpAndSettle();
    expect(
      find.text(CreateListingViewModel.createFailureMessage),
      findsOneWidget,
    );
    expect(find.text('raw storage failure'), findsNothing);
    await tester.fling(
      find.byType(ListView),
      const Offset(0, 2000),
      2000,
    );
    await tester.pumpAndSettle();
    expect(find.text('Foldable music stand for rehearsal'), findsOneWidget);

    repository.failure = null;
    await tester.pump(const Duration(seconds: 5));
    await _scrollTo(tester, 'Post need');
    await tester.tap(find.text('Post need'));
    await tester.pumpAndSettle();
    expect(repository.drafts, hasLength(2));
    expect(find.text('Open create'), findsOneWidget);
  });

  testWidgets('form remains usable at 200 percent text scale', (tester) async {
    await _openForm(
      tester,
      _FormRepository(),
      now,
      textScaler: const TextScaler.linear(2),
    );
    await _scrollTo(tester, 'Post need');

    expect(find.text('Post need'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _openForm(
  WidgetTester tester,
  _FormRepository repository,
  DateTime now, {
  ValueChanged<Listing?>? onReturned,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  final listing = await Navigator.of(context).push<Listing>(
                    MaterialPageRoute(
                      builder: (_) => CreateListingScreen(
                        repository: repository,
                        clock: () => now,
                      ),
                    ),
                  );
                  onReturned?.call(listing);
                },
                child: const Text('Open create'),
              ),
            ),
          );
        },
      ),
    ),
  );
  await tester.tap(find.text('Open create'));
  await tester.pumpAndSettle();
}

Future<void> _fillValidForm(WidgetTester tester) async {
  await tester.enterText(
    find.byType(TextFormField).first,
    'Foldable music stand for rehearsal',
  );
  await tester.enterText(
    find.byType(TextFormField).last,
    'A foldable stand would help our rehearsal tonight.',
  );

  await _scrollTo(tester, 'Category');
  await tester.tap(find.byType(DropdownButtonFormField<ListingCategory>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Music, hobbies & sports').last);
  await tester.pumpAndSettle();

  await _scrollTo(tester, 'Approximate area');
  await tester.tap(find.byType(DropdownButtonFormField<ApproximateArea>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Somaiya side').last);
  await tester.pumpAndSettle();

  await _scrollTo(tester, 'Contact preference');
  await tester.tap(find.byType(DropdownButtonFormField<ContactPreference>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Meet at a public place').last);
  await tester.pumpAndSettle();

  await _scrollTo(tester, 'Choose date and time');
  await tester.tap(find.text('Choose date and time'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
  await _scrollTo(tester, 'Post need');
}

Future<void> _scrollTo(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text),
    300,
    scrollable: find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

class _FormRepository implements ListingRepository {
  final drafts = <ListingDraft>[];
  Object? failure;
  Completer<Listing>? pending;
  Listing? lastCreated;

  Listing createdFrom(ListingDraft draft) {
    return Listing(
      id: 'local-widget-created',
      neighborhoodId: 'vidyavihar',
      kind: draft.kind,
      title: draft.title.trim(),
      description: draft.description.trim(),
      category: draft.category,
      approximateArea: draft.approximateArea,
      contactPreference: draft.contactPreference,
      createdAt: DateTime(2026, 7, 30, 12),
      activeUntil: draft.activeUntil,
      status: ListingStatus.open,
      isSaved: false,
      isContacted: false,
      origin: ListingOrigin.local,
    );
  }

  @override
  Future<Listing> createListing(ListingDraft draft) async {
    drafts.add(draft);
    if (failure case final error?) {
      throw error;
    }
    if (pending case final completer?) {
      return completer.future;
    }
    return lastCreated = createdFrom(draft);
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
