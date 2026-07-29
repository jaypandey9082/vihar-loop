import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vihar_loop/app/app_theme.dart';
import 'package:vihar_loop/app/vihar_loop_app.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/features/create_listing/create_listing_screen.dart';
import 'package:vihar_loop/features/feed/feed_screen.dart';
import 'package:vihar_loop/features/listing_details/listing_details_screen.dart';
import 'package:vihar_loop/features/privacy_data/privacy_data_screen.dart';
import 'package:vihar_loop/local_ai/rule_based_listing_assistant.dart';

import '../support/accessibility_test_repository.dart';

final _now = DateTime(2026, 7, 30, 12);

void main() {
  group('official accessibility guidelines', () {
    testWidgets(
        'ready feed passes targets, labels, and contrast in both themes',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        for (final mode in [ThemeMode.light, ThemeMode.dark]) {
          await _setSurface(tester, const Size(411, 1000));
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: mode,
              home: FeedScreen(
                localAiService: const RuleBasedListingAssistant(),
                repository: AccessibilityTestRepository(
                  listings: [
                    accessibilityListing(
                      origin: ListingOrigin.local,
                      isSaved: true,
                      isContacted: true,
                    ),
                  ],
                ),
                clock: () => _now,
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.text('USB-C laptop charger for two hours'),
            250,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          await _expectGuidelines(tester, contrast: true);
        }
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('filtered empty, genuine empty, and error states pass',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _setSurface(tester, const Size(411, 1000));
        final filtered = AccessibilityTestRepository(
          listings: [accessibilityListing()],
        );
        await tester.pumpWidget(
          ViharLoopApp(
              localAiService: const RuleBasedListingAssistant(),
              listingRepository: filtered,
              clock: () => _now),
        );
        await tester.pumpAndSettle();
        tester.semantics.tap(find.semantics.byLabel('Offers'));
        await tester.pumpAndSettle();
        await _expectGuidelines(tester, contrast: true);

        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          ViharLoopApp(
            localAiService: const RuleBasedListingAssistant(),
            listingRepository: AccessibilityTestRepository(),
            clock: () => _now,
          ),
        );
        await tester.pumpAndSettle();
        await _expectGuidelines(tester, contrast: true);

        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          ViharLoopApp(
            localAiService: const RuleBasedListingAssistant(),
            listingRepository: AccessibilityTestRepository(
              fetchFailure: StateError('hidden'),
            ),
            clock: () => _now,
          ),
        );
        await tester.pumpAndSettle();
        await _expectGuidelines(tester, contrast: true);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('create initial and validation states pass all guidelines',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _setSurface(tester, const Size(800, 1600));
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: CreateListingScreen(
              localAiService: const RuleBasedListingAssistant(),
              repository: AccessibilityTestRepository(),
              clock: () => _now,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await _expectGuidelines(tester, contrast: true);

        tester.semantics.tap(find.semantics.byLabel('Post need'));
        await tester.pumpAndSettle();
        await _expectGuidelines(tester, contrast: true);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('details actions and close dialog pass all guidelines',
        (tester) async {
      final semantics = tester.ensureSemantics();
      final listing = accessibilityListing(origin: ListingOrigin.local);
      try {
        await _setSurface(tester, const Size(800, 1400));
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: ListingDetailsScreen(
              listing: listing,
              repository: AccessibilityTestRepository(listings: [listing]),
              onListingChanged: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        await _expectGuidelines(tester, contrast: true);

        tester.semantics.tap(find.semantics.byLabel('Close listing'));
        await tester.pumpAndSettle();
        await _expectGuidelines(tester, contrast: true);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('pending create remains labelled and disabled', (tester) async {
      final semantics = tester.ensureSemantics();
      final createPending = Completer<Listing>();
      final createRepository = AccessibilityTestRepository()
        ..createCompleter = createPending;

      try {
        await _setSurface(tester, const Size(800, 1600));
        await tester.pumpWidget(
          MaterialApp(
            home: CreateListingScreen(
              localAiService: const RuleBasedListingAssistant(),
              repository: createRepository,
              clock: () => _now,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await _fillValidForm(tester);
        tester.semantics.tap(find.semantics.byLabel('Post need'));
        await tester.pump();
        await _expectGuidelines(tester);
        expect(
          find.semantics.byLabel('Posting listing').evaluate(),
          hasLength(1),
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('pending details remains labelled and disabled',
        (tester) async {
      final semantics = tester.ensureSemantics();
      final listing = accessibilityListing(origin: ListingOrigin.local);
      final mutationPending = Completer<Listing>();
      final detailsRepository = AccessibilityTestRepository(
        listings: [listing],
      )..mutationCompleter = mutationPending;

      try {
        await _setSurface(tester, const Size(800, 1400));
        await tester.pumpWidget(
          MaterialApp(
            home: ListingDetailsScreen(
              listing: listing,
              repository: detailsRepository,
              onListingChanged: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Save listing'),
          250,
          scrollable: find.byType(Scrollable).last,
        );
        tester.semantics.tap(find.semantics.byLabel('Save listing'));
        await tester.pump();
        await _expectGuidelines(tester);
        expect(find.semantics.byLabel('Saving…').evaluate(), hasLength(1));

        mutationPending.complete(listing.copyWith(isSaved: true));
        await tester.pumpAndSettle();
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('Privacy & data and its dialog pass in both themes',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        for (final mode in [ThemeMode.light, ThemeMode.dark]) {
          await _setSurface(tester, const Size(411, 1000));
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: mode,
              home: PrivacyDataScreen(
                repository: AccessibilityTestRepository(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.byKey(const Key('reset-local-data-button')),
            250,
            scrollable: find.byType(Scrollable).last,
          );
          await _expectGuidelines(tester, contrast: true);

          tester.semantics.tap(
            find.semantics.byLabel('Reset local data').last,
          );
          await tester.pumpAndSettle();
          await _expectGuidelines(tester, contrast: true);
          tester.semantics.tap(find.semantics.byLabel('Keep data'));
          await tester.pumpAndSettle();
        }
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('pending local reset stays labelled and disabled',
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
        await tester.pump();

        await _expectGuidelines(tester);
        expect(
          tester
              .getSemantics(find.byKey(const Key('reset-local-data-button')))
              .label,
          'Resetting local data',
        );

        pending.complete(const []);
        await tester.pumpAndSettle();
      } finally {
        semantics.dispose();
      }
    });
  });

  group('large text and constrained layouts', () {
    testWidgets('feed is scrollable at 320 by 568 and 200 percent',
        (tester) async {
      await _setSurface(tester, const Size(320, 568));
      await tester.pumpWidget(
        _scaledApp(
          FeedScreen(
            localAiService: const RuleBasedListingAssistant(),
            repository: AccessibilityTestRepository(
              listings: [
                accessibilityListing(
                  title:
                      'A long but complete neighbourhood listing title that remains reachable',
                  origin: ListingOrigin.local,
                  isSaved: true,
                  isContacted: true,
                ),
              ],
            ),
            clock: () => _now,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final scrollable = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
      await tester.pumpAndSettle();

      expect(find.textContaining('long but complete'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('create errors remain reachable in portrait and landscape',
        (tester) async {
      for (final size in [const Size(320, 568), const Size(568, 320)]) {
        await _setSurface(tester, size);
        await tester.pumpWidget(
          _scaledApp(
            CreateListingScreen(
              localAiService: const RuleBasedListingAssistant(),
              repository: AccessibilityTestRepository(),
              clock: () => _now,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final initialScrollable = tester.state<ScrollableState>(
          find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        initialScrollable.position
            .jumpTo(initialScrollable.position.maxScrollExtent);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Post need'));
        await tester.pumpAndSettle();
        final scrollable = tester.state<ScrollableState>(
          find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
        await tester.pumpAndSettle();

        expect(
          find.text('Choose when this need or offer ends.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('details and dialog remain reachable at 200 percent',
        (tester) async {
      final listing = accessibilityListing(
        title:
            'A long listing title with enough context for large text verification',
        description:
            'A longer description that remains readable without hiding the required actions.',
        origin: ListingOrigin.local,
      );
      await _setSurface(tester, const Size(568, 320));
      await tester.pumpWidget(
        _scaledApp(
          ListingDetailsScreen(
            listing: listing,
            repository: AccessibilityTestRepository(listings: [listing]),
            onListingChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Close listing'));
      await tester.pumpAndSettle();

      expect(find.text('Keep open'), findsOneWidget);
      expect(find.text('Close listing'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Privacy & data is safe at 200 percent in both orientations',
        (tester) async {
      for (final size in [const Size(320, 568), const Size(568, 320)]) {
        await _setSurface(tester, size);
        await tester.pumpWidget(
          _scaledApp(
            PrivacyDataScreen(
              repository: AccessibilityTestRepository(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final scrollable = tester.state<ScrollableState>(
          find
              .descendant(
                of: find.byType(SingleChildScrollView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('reset-local-data-button')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        await tester.tap(find.byKey(const Key('reset-local-data-button')));
        await tester.pumpAndSettle();
        expect(find.text('Keep data'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
    });
  });
}

Future<void> _expectGuidelines(
  WidgetTester tester, {
  bool contrast = false,
}) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  if (contrast) {
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }
}

Future<void> _setSurface(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

Widget _scaledApp(Widget home) {
  return MaterialApp(
    theme: AppTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(2),
      ),
      child: child!,
    ),
    home: home,
  );
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
  await _selectDropdown<ListingCategory>(
    tester,
    'Music, hobbies & sports',
  );
  await _selectDropdown<ApproximateArea>(tester, 'Somaiya side');
  await _selectDropdown<ContactPreference>(
    tester,
    'Meet at a public place',
  );
  await tester.scrollUntilVisible(
    find.text('Choose date and time'),
    250,
    scrollable: find.byType(Scrollable).last,
  );
  tester.semantics.tap(find.semantics.byLabel('Needed by'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text('Post need'),
    250,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
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
  await tester.scrollUntilVisible(
    find.text(label),
    250,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(find.byType(DropdownButtonFormField<T>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}
