import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vihar_loop/app/vihar_loop_app.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/features/create_listing/create_listing_screen.dart';
import 'package:vihar_loop/features/listing_details/listing_details_screen.dart';
import 'package:vihar_loop/local_ai/rule_based_listing_assistant.dart';
import 'package:vihar_loop/features/privacy_data/privacy_data_screen.dart';

import '../support/accessibility_test_repository.dart';

final _now = DateTime(2026, 7, 30, 12);

void main() {
  group('accessibility traversal', () {
    testWidgets('feed ready follows context, filters, count, then cards',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _setSurface(tester, const Size(411, 1200));
        await tester.pumpWidget(
          ViharLoopApp(
            localAiService: const RuleBasedListingAssistant(),
            listingRepository: AccessibilityTestRepository(
              listings: [accessibilityListing()],
            ),
            clock: () => _now,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          _traversalLabels(tester),
          containsAllInOrder([
            contains('Nearby needs and offers'),
            contains('Post a need or offer'),
            contains('Privacy & data'),
            contains('Type'),
            contains('All'),
            contains('Needs'),
            contains('Offers'),
            contains('Time'),
            contains('Any time'),
            contains('Today'),
            contains('Ending soon'),
            contains('Showing 1 listing'),
            contains('USB-C laptop charger for two hours'),
          ]),
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('filtered empty keeps recovery after filter context',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _setSurface(tester, const Size(411, 1200));
        await tester.pumpWidget(
          ViharLoopApp(
            localAiService: const RuleBasedListingAssistant(),
            listingRepository: AccessibilityTestRepository(
              listings: [accessibilityListing()],
            ),
            clock: () => _now,
          ),
        );
        await tester.pumpAndSettle();
        tester.semantics.tap(find.semantics.byLabel('Offers'));
        await tester.pumpAndSettle();

        expect(
          _traversalLabels(tester),
          containsAllInOrder([
            contains('Type'),
            contains('Offers'),
            contains('Time'),
            contains('Showing 0 of 1 listing'),
            contains('Clear filters'),
            contains('No listings match these filters'),
            contains('Try another type or time'),
            contains('Clear filters'),
          ]),
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('create reads guidance, controls, and post in natural order',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _setSurface(tester, const Size(800, 1800));
        await tester.pumpWidget(
          MaterialApp(
            home: CreateListingScreen(
              localAiService: const RuleBasedListingAssistant(),
              repository: AccessibilityTestRepository(),
              clock: () => _now,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.semantics.byLabel('I need something').evaluate(),
          hasLength(1),
        );
        expect(
          find.semantics.byLabel('I’m offering something').evaluate(),
          hasLength(1),
        );
        expect(
          _traversalLabels(tester),
          containsAllInOrder([
            contains('Post a need or offer'),
            contains('Share one small, time-sensitive'),
            contains('Choose a broad area'),
            contains('What are you posting'),
            contains('Title'),
            contains('Description'),
            contains('Draft Assist'),
            contains('Suggest type, title & category'),
            contains('Category'),
            contains('Approximate area'),
            contains('Contact preference'),
            contains('Needed by'),
            contains('Post need'),
          ]),
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('details and close dialog retain a useful order',
        (tester) async {
      final semantics = tester.ensureSemantics();
      final listing = accessibilityListing(origin: ListingOrigin.local);
      final repository = AccessibilityTestRepository(listings: [listing]);

      try {
        await _setSurface(tester, const Size(800, 1400));
        await tester.pumpWidget(
          MaterialApp(
            home: ListingDetailsScreen(
              listing: listing,
              repository: repository,
              onListingChanged: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          _traversalLabels(tester),
          containsAllInOrder([
            contains('Listing details'),
            contains('Need. Open. Your post'),
            contains(listing.title),
            contains(listing.description),
            contains('Category, Electronics'),
            contains('Approximate area, Somaiya side'),
            contains('Contact preference, Meet at a public place'),
            contains('Status, Open'),
            contains('Your activity'),
            contains('Save listing'),
            contains('Mark as contacted'),
            contains('Close listing'),
          ]),
        );

        tester.semantics.tap(find.semantics.byLabel('Close listing'));
        await tester.pumpAndSettle();
        expect(
          _traversalLabels(tester),
          containsAllInOrder([
            contains('Close this listing?'),
            contains('It will stay on this device'),
            contains('Keep open'),
            contains('Close listing'),
          ]),
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('Privacy & data and reset dialog retain a useful order',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _setSurface(tester, const Size(411, 1200));
        await tester.pumpWidget(
          MaterialApp(
            home: PrivacyDataScreen(
              repository: AccessibilityTestRepository(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          _traversalLabels(tester),
          containsAllInOrder([
            contains('Privacy & data'),
            contains('ViharLoop works locally'),
            contains('What stays on this device'),
            contains('What ViharLoop does not collect'),
            contains('How local protection works'),
            contains('Reset local data'),
            contains('This cannot be undone'),
            contains('Reset local data'),
          ]),
        );

        await tester.scrollUntilVisible(
          find.byKey(const Key('reset-local-data-button')),
          250,
          scrollable: find.byType(Scrollable).last,
        );
        tester.semantics.tap(
          find.semantics.byLabel('Reset local data').last,
        );
        await tester.pumpAndSettle();
        expect(
          _traversalLabels(tester),
          containsAllInOrder([
            contains('Reset local data?'),
            contains('This removes every listing and activity'),
            contains('Keep data'),
            contains('Reset local data'),
          ]),
        );
      } finally {
        semantics.dispose();
      }
    });
  });

  group('keyboard and alternative input', () {
    testWidgets('Tab reaches filters and Space changes the selected value',
        (tester) async {
      await _setSurface(tester, const Size(411, 1000));
      await tester.pumpWidget(
        ViharLoopApp(
          localAiService: const RuleBasedListingAssistant(),
          listingRepository: AccessibilityTestRepository(
            listings: [
              accessibilityListing(),
              accessibilityListing(
                id: 'offer',
                title: 'Offer reached from keyboard',
                kind: ListingKind.offer,
              ),
            ],
          ),
          clock: () => _now,
        ),
      );
      await tester.pumpAndSettle();

      for (var index = 0; index < 5; index += 1) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      expect(FocusManager.instance.primaryFocus, isNotNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(find.text('Showing 1 of 2 listings'), findsOneWidget);
      expect(find.text('Offer reached from keyboard'), findsOneWidget);
    });

    testWidgets('keyboard opens dropdown, deadline, and submits the form',
        (tester) async {
      final repository = AccessibilityTestRepository();
      await _setSurface(tester, const Size(800, 1000));
      await tester.pumpWidget(
        MaterialApp(
          home: CreateListingScreen(
            localAiService: const RuleBasedListingAssistant(),
            repository: repository,
            clock: () => _now,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'Keyboard-accessible music stand',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'A stand would help with a neighbourhood rehearsal tonight.',
      );
      await _showText(tester, 'Category');
      final category = tester.widget<DropdownButton<ListingCategory>>(
        find.byType(DropdownButton<ListingCategory>),
      );
      category.focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.text('Music, hobbies & sports'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      await _selectDropdown<ListingCategory>(
        tester,
        'Music, hobbies & sports',
      );
      await _selectDropdown<ApproximateArea>(tester, 'Somaiya side');
      await _selectDropdown<ContactPreference>(
        tester,
        'Meet at a public place',
      );

      await _showText(tester, 'Choose date and time');
      final deadline = tester.widget<InkWell>(
        find.byKey(const Key('deadline-control')),
      );
      deadline.focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await _showText(tester, 'Post need');
      final post = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Post need'),
      );
      post.focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(repository.createCount, 1);
    });

    testWidgets('keyboard toggles Save and operates the close dialog',
        (tester) async {
      final listing = accessibilityListing(origin: ListingOrigin.local);
      final repository = AccessibilityTestRepository(listings: [listing]);
      await _setSurface(tester, const Size(800, 1000));
      await tester.pumpWidget(
        MaterialApp(
          home: ListingDetailsScreen(
            listing: listing,
            repository: repository,
            onListingChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _showText(tester, 'Save listing');
      await _tabTo(tester, find.text('Save listing'));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Remove from saved'), findsOneWidget);

      await _showText(tester, 'Close listing');
      await _tabTo(tester, find.text('Close listing'));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Close this listing?'), findsOneWidget);

      await _tabTo(tester, find.text('Keep open'));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Close this listing?'), findsNothing);
      expect(repository.mutationCount, 1);
    });
  });
}

List<String> _traversalLabels(WidgetTester tester) {
  return tester.semantics
      .simulatedAccessibilityTraversal()
      .map((node) => node.label)
      .where((label) => label.isNotEmpty)
      .toList();
}

Future<void> _setSurface(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

Future<void> _showText(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text),
    250,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
}

Future<void> _tabTo(WidgetTester tester, Finder target) async {
  final targetElement = tester.element(target);
  for (var index = 0; index < 30; index += 1) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final focusContext = FocusManager.instance.primaryFocus?.context;
    if (focusContext != null &&
        _hasAncestor(targetElement, focusContext as Element)) {
      return;
    }
  }
  fail('Tab did not reach ${target.toString(describeSelf: true)}.');
}

bool _hasAncestor(Element target, Element possibleAncestor) {
  if (target == possibleAncestor) {
    return true;
  }
  var found = false;
  target.visitAncestorElements((ancestor) {
    if (ancestor == possibleAncestor) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
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
  await _showText(tester, label);
  await tester.tap(find.byType(DropdownButtonFormField<T>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}
