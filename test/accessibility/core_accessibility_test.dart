import 'dart:async';
import 'dart:ui'
    show SemanticsAction, SemanticsValidationResult, Size, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsData;
import 'package:flutter_test/flutter_test.dart';
import 'package:vihar_loop/app/vihar_loop_app.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/domain/listing_draft.dart';
import 'package:vihar_loop/features/create_listing/create_listing_screen.dart';
import 'package:vihar_loop/features/create_listing/create_listing_view_model.dart';
import 'package:vihar_loop/features/feed/listing_card.dart';
import 'package:vihar_loop/features/listing_details/listing_details_screen.dart';
import 'package:vihar_loop/features/privacy_data/privacy_data_screen.dart';
import 'package:vihar_loop/local_ai/listing_suggestion.dart';
import 'package:vihar_loop/local_ai/local_ai_service.dart';
import 'package:vihar_loop/local_ai/rule_based_listing_assistant.dart';

import '../support/accessibility_test_repository.dart';
import '../support/test_local_ai_service.dart';

final _now = DateTime(2026, 7, 30, 12);

void main() {
  group('feed semantics', () {
    testWidgets('loading is one understandable live-region status',
        (tester) async {
      final semantics = tester.ensureSemantics();
      final pending = Completer<List<Listing>>();
      final repository = _PendingFetchRepository(pending.future);

      try {
        await tester.pumpWidget(
          ViharLoopApp(
              localAiService: const RuleBasedListingAssistant(),
              listingRepository: repository,
              clock: () => _now),
        );
        await tester.pump();

        final data = _data(tester, 'Loading nearby listings');
        expect(data.flagsCollection.isLiveRegion, isTrue);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(
          find.bySemanticsLabel('Loading nearby listings'),
          findsOneWidget,
        );

        pending.complete(const []);
        await tester.pumpAndSettle();
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('headings, filters, count, and card actions expose state',
        (tester) async {
      final semantics = tester.ensureSemantics();
      final repository = AccessibilityTestRepository(
        listings: [
          accessibilityListing(kind: ListingKind.need),
          accessibilityListing(
            id: 'offer',
            title: 'Scientific calculator available',
            kind: ListingKind.offer,
          ),
        ],
      );

      try {
        await _setSurface(tester, const Size(411, 1000));
        await tester.pumpWidget(
          ViharLoopApp(
              localAiService: const RuleBasedListingAssistant(),
              listingRepository: repository,
              clock: () => _now),
        );
        await tester.pumpAndSettle();

        _expectHeading(tester, 'Nearby needs and offers', 1);
        _expectHeading(tester, 'Type', 2);
        _expectHeading(tester, 'Time', 2);
        expect(
            _data(tester, 'All').flagsCollection.isSelected, Tristate.isTrue);
        expect(
          _data(tester, 'Offers').flagsCollection.isSelected,
          Tristate.isFalse,
        );
        expect(find.text('Showing 2 listings'), findsOneWidget);

        tester.semantics.tap(find.semantics.byLabel('Offers'));
        await tester.pumpAndSettle();
        expect(find.text('Showing 1 of 2 listings'), findsOneWidget);
        expect(_data(tester, 'Offers').flagsCollection.isSelected,
            Tristate.isTrue);
        expect(find.text('Scientific calculator available'), findsOneWidget);
        expect(
          find.text('USB-C laptop charger for two hours'),
          findsNothing,
        );

        await tester.scrollUntilVisible(
          find.byType(ListingCard),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        final card = find.semantics
            .byLabel(RegExp(r'Offer\. Scientific calculator available\.'))
            .evaluate()
            .single;
        final cardData = card.getSemanticsData();
        expect(cardData.flagsCollection.isButton, isTrue);
        expect(cardData.flagsCollection.isEnabled, Tristate.isTrue);
        expect(cardData.hasAction(SemanticsAction.tap), isTrue);

        tester.semantics.tap(
          find.semantics.byLabel(
            RegExp(r'Offer\. Scientific calculator available\.'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Listing details'), findsOneWidget);
        expect(find.text('Scientific calculator available'), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets(
        'filtered empty recovery and clear filters are semantic actions',
        (tester) async {
      final semantics = tester.ensureSemantics();
      final repository = AccessibilityTestRepository(
        listings: [accessibilityListing()],
      );

      try {
        await _setSurface(tester, const Size(411, 1000));
        await tester.pumpWidget(
          ViharLoopApp(
              localAiService: const RuleBasedListingAssistant(),
              listingRepository: repository,
              clock: () => _now),
        );
        await tester.pumpAndSettle();

        tester.semantics.tap(find.semantics.byLabel('Offers'));
        await tester.pumpAndSettle();
        _expectHeading(tester, 'No listings match these filters', 1);
        expect(find.text('Showing 0 of 1 listing'), findsOneWidget);

        tester.semantics.tap(find.semantics.byLabel('Clear filters').last);
        await tester.pumpAndSettle();
        expect(find.text('Showing 1 listing'), findsOneWidget);
        expect(find.text('USB-C laptop charger for two hours'), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('genuine empty and error recovery retain actionable controls',
        (tester) async {
      final semantics = tester.ensureSemantics();
      final emptyRepository = AccessibilityTestRepository();

      try {
        await tester.pumpWidget(
          ViharLoopApp(
            localAiService: const RuleBasedListingAssistant(),
            listingRepository: emptyRepository,
            clock: () => _now,
          ),
        );
        await tester.pumpAndSettle();
        _expectHeading(tester, 'No listings yet', 1);
        expect(
          _data(tester, 'Post a need or offer').hasAction(SemanticsAction.tap),
          isTrue,
        );

        final failed = AccessibilityTestRepository(
          fetchFailure: StateError('technical detail'),
        );
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          ViharLoopApp(
              localAiService: const RuleBasedListingAssistant(),
              listingRepository: failed,
              clock: () => _now),
        );
        await tester.pumpAndSettle();
        _expectHeading(tester, 'Unable to load listings', 1);
        expect(find.text('technical detail'), findsNothing);
        failed.fetchFailure = null;
        tester.semantics.tap(
          find.semantics.byLabel('Retry loading listings'),
        );
        await tester.pumpAndSettle();
        expect(failed.fetchCount, 2);
        _expectHeading(tester, 'No listings yet', 1);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets(
        'Privacy & data opens semantically from ready, empty, and error',
        (tester) async {
      final semantics = tester.ensureSemantics();
      final repositories = [
        AccessibilityTestRepository(listings: [accessibilityListing()]),
        AccessibilityTestRepository(),
        AccessibilityTestRepository(fetchFailure: StateError('unreadable')),
      ];
      try {
        for (final repository in repositories) {
          await tester.pumpWidget(
            ViharLoopApp(
              localAiService: const RuleBasedListingAssistant(),
              listingRepository: repository,
              clock: () => _now,
            ),
          );
          await tester.pumpAndSettle();

          final privacy = _actionData(tester, 'Privacy & data');
          expect(privacy.flagsCollection.isButton, isTrue);
          expect(privacy.hasAction(SemanticsAction.tap), isTrue);
          tester.semantics.tap(find.semantics.byLabel('Privacy & data'));
          await tester.pumpAndSettle();
          expect(find.text('What stays on this device'), findsOneWidget);

          tester.semantics.tap(find.semantics.byLabel('Back'));
          await tester.pumpAndSettle();
          await tester.pumpWidget(const SizedBox());
        }
      } finally {
        semantics.dispose();
      }
    });
  });

  group('privacy and reset semantics', () {
    testWidgets('headings, confirmation, and pending status are coherent',
        (tester) async {
      final semantics = tester.ensureSemantics();
      final pending = Completer<List<Listing>>();
      final repository = AccessibilityTestRepository()
        ..resetCompleter = pending;
      try {
        await _setSurface(tester, const Size(411, 1000));
        await tester.pumpWidget(
          MaterialApp(
            home: PrivacyDataScreen(repository: repository),
          ),
        );
        await tester.pumpAndSettle();
        _expectHeading(tester, 'What stays on this device', 2);
        _expectHeading(tester, 'What ViharLoop does not collect', 2);
        _expectHeading(tester, 'How local protection works', 2);
        _expectHeading(tester, 'Reset local data', 2);
        await tester.scrollUntilVisible(
          find.byKey(const Key('reset-local-data-button')),
          250,
          scrollable: find.byType(Scrollable).last,
        );

        final reset = _actionData(tester, 'Reset local data');
        expect(reset.flagsCollection.isButton, isTrue);
        expect(reset.hasAction(SemanticsAction.tap), isTrue);
        tester.semantics.tap(
          find.semantics.byLabel('Reset local data').last,
        );
        await tester.pumpAndSettle();
        expect(find.text('Reset local data?'), findsOneWidget);
        tester.semantics.tap(find.semantics.byLabel('Keep data'));
        await tester.pumpAndSettle();
        expect(repository.resetCount, 0);

        tester.semantics.tap(
          find.semantics.byLabel('Reset local data').last,
        );
        await tester.pumpAndSettle();
        tester.semantics.tap(
          find.semantics.byLabel('Reset local data').last,
        );
        await tester.pump();

        final resetting = tester
            .getSemantics(find.byKey(const Key('reset-local-data-button')))
            .getSemanticsData();
        expect(resetting.flagsCollection.isLiveRegion, isTrue);
        expect(resetting.flagsCollection.isButton, isTrue);
        expect(resetting.flagsCollection.isEnabled, Tristate.isFalse);
        expect(resetting.hasAction(SemanticsAction.tap), isFalse);
        expect(repository.resetCount, 1);

        await tester.binding.handlePopRoute();
        await tester.pump();
        expect(find.text('Finishing the local-data reset…'), findsOneWidget);

        pending.complete([
          accessibilityListing(id: 'reset-sample'),
        ]);
        await tester.pumpAndSettle();
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('reset failure is visible, safe, and retryable',
        (tester) async {
      final semantics = tester.ensureSemantics();
      final repository = AccessibilityTestRepository()
        ..resetFailure = StateError('hidden key detail');
      try {
        await _setSurface(tester, const Size(411, 1000));
        await tester.pumpWidget(
          MaterialApp(
            home: PrivacyDataScreen(repository: repository),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(const Key('reset-local-data-button')),
          250,
          scrollable: find.byType(Scrollable).last,
        );
        tester.semantics.tap(
          find.semantics.byLabel('Reset local data').last,
        );
        await tester.pumpAndSettle();
        tester.semantics.tap(
          find.semantics.byLabel('Reset local data').last,
        );
        await tester.pumpAndSettle();

        expect(
            find.textContaining('finish resetting local data'), findsOneWidget);
        expect(find.textContaining('hidden key detail'), findsNothing);
        expect(
          _actionData(tester, 'Reset local data').hasAction(
            SemanticsAction.tap,
          ),
          isTrue,
        );
      } finally {
        semantics.dispose();
      }
    });
  });

  group('create semantics and focus', () {
    testWidgets(
        'Draft Assist exposes pending, preview, actions, failure, and apply focus',
        (tester) async {
      final semantics = tester.ensureSemantics();
      final pending = Completer<ListingSuggestion>();
      final service = TestLocalAiService(
        result: const ListingSuggestion(
          kind: ListingKind.offer,
          title:
              'A deliberately long but safe suggested title for a useful nearby item',
          category: ListingCategory.other,
          source: ListingSuggestionSource.deterministicFallback,
        ),
        pending: pending,
      );
      try {
        await _setSurface(tester, const Size(800, 3000));
        await _pumpCreate(
          tester,
          AccessibilityTestRepository(),
          localAiService: service,
        );
        _expectHeadingContaining(tester, 'Draft Assist', 2);
        expect(
          _actionData(tester, 'Suggest type, title & category')
              .hasAction(SemanticsAction.tap),
          isTrue,
        );
        await tester.enterText(
          find.byType(TextFormField).last,
          'Offering one useful nearby item for a short while.',
        );
        tester.semantics.tap(
          find.semantics.byLabel('Suggest type, title & category'),
        );
        await tester.pump();
        final pendingData =
            _data(tester, 'Suggesting type, title, and category');
        expect(pendingData.flagsCollection.isLiveRegion, isTrue);
        expect(pendingData.flagsCollection.isEnabled, Tristate.isFalse);

        pending.complete(service.result);
        await tester.pumpAndSettle();
        _expectHeadingContaining(tester, 'Suggested details', 3);
        expect(
          find.semantics.byLabel('Source: Built-in offline rules').evaluate(),
          hasLength(1),
        );
        expect(
          _actionData(tester, 'Use suggestions').hasAction(SemanticsAction.tap),
          isTrue,
        );
        expect(
          _actionData(tester, 'Dismiss').hasAction(SemanticsAction.tap),
          isTrue,
        );
        expect(
          _data(
            tester,
            'Suggested type, title, and category are ready for review.',
          ).flagsCollection.isLiveRegion,
          isTrue,
        );

        tester.semantics.tap(find.semantics.byLabel('Use suggestions'));
        await tester.pumpAndSettle();
        final title = tester.widget<EditableText>(
          find.descendant(
            of: find
                .byType(
                  TextFormField,
                  skipOffstage: false,
                )
                .first,
            matching: find.byType(
              EditableText,
              skipOffstage: false,
            ),
          ),
        );
        expect(title.focusNode.hasFocus, isTrue);

        service
          ..pending = null
          ..failure = StateError('technical detail');
        await _showCreateText(tester, 'Description');
        await tester.enterText(
          find.byType(TextFormField).last,
          'Offering another useful nearby item for a short while.',
        );
        await _showCreateText(tester, 'Suggest type, title & category');
        tester.semantics.tap(
          find.semantics.byLabel('Suggest type, title & category'),
        );
        await tester.pumpAndSettle();
        final failure = _data(
          tester,
          CreateListingViewModel.suggestionFailureCopy,
        );
        expect(failure.flagsCollection.isLiveRegion, isTrue);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('heading and segmented control adapt without losing selection',
        (tester) async {
      final repository = AccessibilityTestRepository();

      await _setSurface(tester, const Size(800, 900));
      await _pumpCreate(tester, repository);
      _expectHeading(tester, 'What are you posting?', 2);
      expect(
        tester
            .widget<SegmentedButton<ListingKind>>(
              find.byType(SegmentedButton<ListingKind>),
            )
            .direction,
        Axis.horizontal,
      );

      await _setSurface(tester, const Size(320, 568));
      await tester.pumpWidget(const SizedBox());
      await _pumpCreate(
        tester,
        repository,
        textScaler: const TextScaler.linear(2),
      );
      await tester.scrollUntilVisible(
        find.text('What are you posting?'),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      final segmented = tester.widget<SegmentedButton<ListingKind>>(
        find.byType(SegmentedButton<ListingKind>, skipOffstage: false),
      );
      expect(segmented.direction, Axis.vertical);
      expect(segmented.selected, {ListingKind.need});
      expect(tester.takeException(), isNull);
    });

    for (final scenario in <String, Future<void> Function(WidgetTester)>{
      'Title': (_) async {},
      'Description': (tester) async {
        await tester.enterText(
          find.byType(TextFormField).first,
          'A valid accessibility title',
        );
      },
      'Category': (tester) async {
        await _fillValidText(tester);
      },
      'Approximate area': (tester) async {
        await _fillValidText(tester);
        await _selectDropdown<ListingCategory>(
          tester,
          'Music, hobbies & sports',
        );
      },
      'Contact preference': (tester) async {
        await _fillValidText(tester);
        await _selectDropdown<ListingCategory>(
          tester,
          'Music, hobbies & sports',
        );
        await _selectDropdown<ApproximateArea>(tester, 'Somaiya side');
      },
      'Deadline': (tester) async {
        await _fillValidText(tester);
        await _selectDropdown<ListingCategory>(
          tester,
          'Music, hobbies & sports',
        );
        await _selectDropdown<ApproximateArea>(tester, 'Somaiya side');
        await _selectDropdown<ContactPreference>(
          tester,
          'Meet at a public place',
        );
      },
    }.entries) {
      testWidgets('invalid ${scenario.key} receives actual focus',
          (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          await _pumpCreate(tester, AccessibilityTestRepository());
          await scenario.value(tester);
          await _showCreateText(tester, 'Post need');
          tester.semantics.tap(find.semantics.byLabel('Post need'));
          await tester.pumpAndSettle();

          expect(
            FocusManager.instance.primaryFocus?.debugLabel,
            scenario.key,
          );
          expect(find.text('Check the highlighted fields.'), findsOneWidget);
        } finally {
          semantics.dispose();
        }
      });
    }

    testWidgets('deadline is one actionable validated semantic control',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _pumpCreate(tester, AccessibilityTestRepository());
        await _showCreateText(tester, 'Post need');
        tester.semantics.tap(find.semantics.byLabel('Post need'));
        await tester.pumpAndSettle();
        await _showCreateText(tester, 'Choose date and time');

        final invalid = _data(tester, 'Needed by');
        expect(invalid.flagsCollection.isButton, isTrue);
        expect(invalid.flagsCollection.isEnabled, Tristate.isTrue);
        expect(invalid.hasAction(SemanticsAction.tap), isTrue);
        expect(
          invalid.validationResult,
          SemanticsValidationResult.invalid,
        );
        expect(invalid.value, 'Not selected');
        expect(
          invalid.hint,
          contains('Choose when this need or offer ends.'),
        );

        tester.semantics.tap(find.semantics.byLabel('Needed by'));
        await tester.pumpAndSettle();
        expect(find.byType(DatePickerDialog), findsOneWidget);
        tester.semantics.tap(find.semantics.byLabel('OK'));
        await tester.pumpAndSettle();
        expect(find.byType(TimePickerDialog), findsOneWidget);
        tester.semantics.tap(find.semantics.byLabel('OK'));
        await tester.pumpAndSettle();

        final valid = _data(tester, 'Needed by');
        expect(valid.validationResult, SemanticsValidationResult.valid);
        expect(valid.value, isNot('Not selected'));
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'Deadline');
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('posting exposes one disabled live status and failure recovers',
        (tester) async {
      final semantics = tester.ensureSemantics();
      final repository = AccessibilityTestRepository();
      final pending = Completer<Listing>();
      repository.createCompleter = pending;

      try {
        await _pumpCreate(tester, repository);
        await _fillValidForm(tester);
        tester.semantics.tap(find.semantics.byLabel('Post need'));
        await tester.pump();

        final posting = _data(tester, 'Posting listing');
        expect(posting.flagsCollection.isLiveRegion, isTrue);
        expect(posting.flagsCollection.isButton, isTrue);
        expect(posting.flagsCollection.isEnabled, Tristate.isFalse);
        expect(posting.hasAction(SemanticsAction.tap), isFalse);
        expect(repository.createCount, 1);

        pending.complete(
          listingFromDraft(
            _draftFromRepositoryState(),
          ),
        );
        await tester.pumpAndSettle();
      } finally {
        semantics.dispose();
      }
    });
  });

  group('details semantics', () {
    testWidgets(
        'headings, state summary, rows, and toggle actions are coherent',
        (tester) async {
      final semantics = tester.ensureSemantics();
      final listing = accessibilityListing(origin: ListingOrigin.local);
      final repository = AccessibilityTestRepository(listings: [listing]);

      try {
        await _pumpDetails(tester, repository, listing);
        _expectHeading(tester, listing.title, 1);
        expect(_data(tester, 'Need. Open. Your post').label, isNotEmpty);
        expect(_data(tester, 'Category, Electronics').label, isNotEmpty);
        await _showDetailsText(tester, 'Your activity');
        _expectHeading(tester, 'Your activity', 2);

        await _showDetailsText(tester, 'Save listing');
        expect(
          _data(tester, 'Save listing').flagsCollection.isToggled,
          Tristate.isFalse,
        );
        tester.semantics.tap(find.semantics.byLabel('Save listing'));
        await tester.pumpAndSettle();
        expect(find.text('Saved on this device.'), findsOneWidget);
        expect(
          _data(tester, 'Remove from saved').flagsCollection.isToggled,
          Tristate.isTrue,
        );

        await _showDetailsText(tester, 'Mark as contacted');
        tester.semantics.tap(find.semantics.byLabel('Mark as contacted'));
        await tester.pumpAndSettle();
        expect(find.text('Marked as contacted.'), findsOneWidget);
        expect(
          _data(tester, 'Remove contacted mark').flagsCollection.isToggled,
          Tristate.isTrue,
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('close confirmation and reopen execute through semantics',
        (tester) async {
      final semantics = tester.ensureSemantics();
      final listing = accessibilityListing(origin: ListingOrigin.local);
      final repository = AccessibilityTestRepository(listings: [listing]);

      try {
        await _pumpDetails(tester, repository, listing);
        await _showDetailsText(tester, 'Close listing');
        tester.semantics.tap(find.semantics.byLabel('Close listing'));
        await tester.pumpAndSettle();
        expect(find.text('Close this listing?'), findsOneWidget);
        tester.semantics.tap(find.semantics.byLabel('Keep open'));
        await tester.pumpAndSettle();
        expect(repository.mutationCount, 0);

        tester.semantics.tap(find.semantics.byLabel('Close listing'));
        await tester.pumpAndSettle();
        tester.semantics.tap(find.semantics.byLabel('Close listing'));
        await tester.pumpAndSettle();
        expect(find.text('Listing closed.'), findsOneWidget);
        expect(find.text('Reopen listing'), findsOneWidget);

        tester.semantics.tap(find.semantics.byLabel('Reopen listing'));
        await tester.pumpAndSettle();
        expect(find.text('Listing reopened.'), findsOneWidget);
        expect(repository.mutationCount, 2);
      } finally {
        semantics.dispose();
      }
    });
  });
}

SemanticsData _data(WidgetTester tester, String label) {
  return find.semantics.byLabel(label).evaluate().single.getSemanticsData();
}

void _expectHeading(WidgetTester tester, String label, int level) {
  final data = find.semantics
      .byLabel(label)
      .evaluate()
      .map((element) => element.getSemanticsData())
      .singleWhere((data) => data.flagsCollection.isHeader);
  expect(data.flagsCollection.isHeader, isTrue);
  expect(data.headingLevel, level);
}

void _expectHeadingContaining(
  WidgetTester tester,
  String label,
  int level,
) {
  final data = find.semantics
      .byLabel(RegExp(RegExp.escape(label)))
      .evaluate()
      .map((element) => element.getSemanticsData())
      .singleWhere((data) => data.flagsCollection.isHeader);
  expect(data.headingLevel, level);
}

SemanticsData _actionData(WidgetTester tester, String label) {
  return find.semantics
      .byLabel(label)
      .evaluate()
      .map((element) => element.getSemanticsData())
      .singleWhere((data) => data.hasAction(SemanticsAction.tap));
}

Future<void> _setSurface(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

Future<void> _pumpCreate(
  WidgetTester tester,
  AccessibilityTestRepository repository, {
  TextScaler textScaler = TextScaler.noScaling,
  LocalAiService localAiService = const RuleBasedListingAssistant(),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: CreateListingScreen(
        localAiService: localAiService,
        repository: repository,
        clock: () => _now,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _fillValidText(WidgetTester tester) async {
  await tester.enterText(
    find.byType(TextFormField).first,
    'Foldable music stand for rehearsal',
  );
  await tester.enterText(
    find.byType(TextFormField).last,
    'A foldable stand would help our rehearsal tonight.',
  );
}

Future<void> _fillValidForm(WidgetTester tester) async {
  await _fillValidText(tester);
  await _selectDropdown<ListingCategory>(
    tester,
    'Music, hobbies & sports',
  );
  await _selectDropdown<ApproximateArea>(tester, 'Somaiya side');
  await _selectDropdown<ContactPreference>(
    tester,
    'Meet at a public place',
  );
  await _showCreateText(tester, 'Choose date and time');
  tester.semantics.tap(find.semantics.byLabel('Needed by'));
  await tester.pumpAndSettle();
  tester.semantics.tap(find.semantics.byLabel('OK'));
  await tester.pumpAndSettle();
  tester.semantics.tap(find.semantics.byLabel('OK'));
  await tester.pumpAndSettle();
  await _showCreateText(tester, 'Post need');
}

Future<void> _selectDropdown<T>(
  WidgetTester tester,
  String option,
) async {
  final label = T == ListingCategory
      ? 'Category'
      : T == ApproximateArea
          ? 'Approximate area'
          : 'Contact preference';
  await _showCreateText(tester, label);
  await tester.tap(find.byType(DropdownButtonFormField<T>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

Future<void> _showCreateText(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text),
    250,
    scrollable: find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpDetails(
  WidgetTester tester,
  AccessibilityTestRepository repository,
  Listing listing,
) {
  return tester.pumpWidget(
    MaterialApp(
      home: ListingDetailsScreen(
        listing: listing,
        repository: repository,
        onListingChanged: (_) {},
      ),
    ),
  );
}

Future<void> _showDetailsText(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text),
    250,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
}

ListingDraft _draftFromRepositoryState() {
  return ListingDraft(
    kind: ListingKind.need,
    title: 'Foldable music stand for rehearsal',
    description: 'A foldable stand would help our rehearsal tonight.',
    category: ListingCategory.musicHobbiesAndSports,
    approximateArea: ApproximateArea.somaiyaSide,
    contactPreference: ContactPreference.publicPlace,
    activeUntil: _now.add(const Duration(hours: 2)),
  );
}

class _PendingFetchRepository extends AccessibilityTestRepository {
  _PendingFetchRepository(this.pending);

  final Future<List<Listing>> pending;

  @override
  Future<List<Listing>> fetchListings() => pending;
}
