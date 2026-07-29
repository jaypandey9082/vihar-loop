import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vihar_loop/app/vihar_loop_app.dart';
import 'package:vihar_loop/data/listing_repository.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/domain/listing_draft.dart';
import 'package:vihar_loop/features/feed/feed_screen.dart';
import 'package:vihar_loop/features/feed/feed_view_model.dart';
import 'package:vihar_loop/local_ai/rule_based_listing_assistant.dart';

import '../../support/test_local_ai_service.dart';

void main() {
  testWidgets('app injects one service through feed into create only',
      (tester) async {
    final service = TestLocalAiService();
    final repository = _SequenceRepository([
      [_testListing()],
    ]);
    await tester.pumpWidget(
      ViharLoopApp(
        localAiService: service,
        listingRepository: repository,
      ),
    );
    await tester.pumpAndSettle();
    expect(service.requests, isEmpty);

    await _showFeedListing(tester, 'USB-C laptop charger for two hours');
    await tester.tap(find.text('USB-C laptop charger for two hours'));
    await tester.pumpAndSettle();
    expect(service.requests, isEmpty);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Post a need or offer'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).last,
      'Need a guitar capo for rehearsal near Somaiya today.',
    );
    await tester.scrollUntilVisible(
      find.text('Suggest type, title & category'),
      250,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suggest type, title & category'));
    await tester.pumpAndSettle();

    expect(service.requests, hasLength(1));
    expect(
      service.requests.single.description,
      'Need a guitar capo for rehearsal near Somaiya today.',
    );
  });

  testWidgets('shows a genuine loading state while the repository is pending',
      (tester) async {
    final pending = Completer<List<Listing>>();
    await tester.pumpWidget(
      ViharLoopApp(
        localAiService: const RuleBasedListingAssistant(),
        listingRepository: _PendingRepository(pending.future),
      ),
    );
    await tester.pump();

    expect(find.text('Loading nearby listings…'), findsOneWidget);

    pending.complete([_testListing()]);
    await tester.pumpAndSettle();
    expect(find.text('USB-C laptop charger for two hours'), findsOneWidget);
  });

  testWidgets('shows product, neighborhood, and listing cards', (tester) async {
    await tester.pumpWidget(
      ViharLoopApp(
        localAiService: const RuleBasedListingAssistant(),
        listingRepository: _SequenceRepository([
          [
            _testListing(),
            _testListing(
              id: 'closed-offer',
              title: 'Scientific calculator available',
              kind: ListingKind.offer,
              status: ListingStatus.closed,
            ),
          ],
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ViharLoop'), findsOneWidget);
    expect(find.text('Vidyavihar, Mumbai'), findsOneWidget);
    expect(find.text('Nearby needs and offers'), findsOneWidget);
    expect(find.text('USB-C laptop charger for two hours'), findsOneWidget);
    expect(find.text('Need'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    await _showFeedListing(tester, 'Scientific calculator available');
    expect(find.text('Offer'), findsOneWidget);
    expect(find.text('Closed'), findsOneWidget);
  });

  testWidgets('tapping a card opens complete details and local markers',
      (tester) async {
    await tester.pumpWidget(
      ViharLoopApp(
        localAiService: const RuleBasedListingAssistant(),
        listingRepository: _SequenceRepository([
          [_testListing()],
        ]),
      ),
    );
    await tester.pumpAndSettle();

    await _showFeedListing(tester, 'USB-C laptop charger for two hours');
    await tester.tap(find.text('USB-C laptop charger for two hours'));
    await tester.pumpAndSettle();

    expect(find.text('Listing details'), findsOneWidget);
    expect(
      find.text('A charger would help finish an assignment.'),
      findsOneWidget,
    );
    expect(find.text('Contact preference'), findsOneWidget);
    expect(find.text('Meet at a public place'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Your activity'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Your activity'), findsOneWidget);
    expect(find.text('Save listing'), findsOneWidget);
    expect(find.text('Mark as contacted'), findsOneWidget);
    expect(find.text('Close listing'), findsNothing);
  });

  testWidgets('saved and contacted changes return to the feed card',
      (tester) async {
    final repository = _SequenceRepository([
      [_testListing()],
    ]);
    await tester.pumpWidget(
      ViharLoopApp(
          localAiService: const RuleBasedListingAssistant(),
          listingRepository: repository),
    );
    await tester.pumpAndSettle();

    await _showFeedListing(tester, 'USB-C laptop charger for two hours');
    await tester.tap(find.text('USB-C laptop charger for two hours'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Save listing'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Save listing'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Mark as contacted'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Mark as contacted'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Contacted'), findsOneWidget);
  });

  testWidgets('card conditionally exposes all persistent markers',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        ViharLoopApp(
          localAiService: const RuleBasedListingAssistant(),
          listingRepository: _SequenceRepository([
            [
              _testListing(
                origin: ListingOrigin.local,
                isSaved: true,
                isContacted: true,
              ),
            ],
          ]),
        ),
      );
      await tester.pumpAndSettle();

      await _showFeedListing(tester, 'USB-C laptop charger for two hours');
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Contacted'), findsOneWidget);
      expect(find.text('Your post'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          RegExp(
            r'Open\. Ending soon\. Saved\. Contacted\. Your post$',
          ),
        ),
        findsOneWidget,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('empty state is readable', (tester) async {
    await tester.pumpWidget(
      ViharLoopApp(
        localAiService: const RuleBasedListingAssistant(),
        listingRepository: _SequenceRepository([
          const <Listing>[],
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No listings yet'), findsOneWidget);
    expect(
      find.text('Be the first to post a need or offer in Vidyavihar.'),
      findsOneWidget,
    );
  });

  testWidgets('error state has a working Retry button', (tester) async {
    final repository = _SequenceRepository([
      StateError('not shown'),
      [_testListing()],
    ]);
    await tester.pumpWidget(
      ViharLoopApp(
          localAiService: const RuleBasedListingAssistant(),
          listingRepository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text(FeedViewModel.failureMessage), findsOneWidget);
    expect(find.text('not shown'), findsNothing);

    await tester.tap(find.text('Retry loading listings'));
    await tester.pumpAndSettle();

    expect(repository.callCount, 2);
    expect(find.text('USB-C laptop charger for two hours'), findsOneWidget);
  });

  testWidgets('listing card exposes one meaningful tappable semantic summary',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        ViharLoopApp(
          localAiService: const RuleBasedListingAssistant(),
          listingRepository: _SequenceRepository([
            [_testListing()],
          ]),
        ),
      );
      await tester.pumpAndSettle();

      await _showFeedListing(tester, 'USB-C laptop charger for two hours');
      expect(
        find.bySemanticsLabel(
          RegExp(
            r'Need\. USB-C laptop charger for two hours\. Electronics\. '
            r'Somaiya side\. Needed by .+\. Open\. Ending soon',
          ),
        ),
        findsOneWidget,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('feed renders at 200 percent text scale without exceptions',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
            ),
            child: child!,
          );
        },
        home: FeedScreen(
          localAiService: const RuleBasedListingAssistant(),
          repository: _SequenceRepository([
            [_testListing()],
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nearby needs and offers'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('create returns a local listing and exposes owner controls',
      (tester) async {
    final now = DateTime(2026, 7, 30, 12);
    final repository = _SequenceRepository([
      [_testListing()],
    ]);
    await tester.pumpWidget(
      ViharLoopApp(
        localAiService: const RuleBasedListingAssistant(),
        listingRepository: repository,
        clock: () => now,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Post a need or offer'));
    await tester.pumpAndSettle();
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
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Choose date and time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Post need'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Post need'));
    await tester.pumpAndSettle();

    expect(find.text('Listing posted on this device.'), findsOneWidget);
    await _showFeedListing(tester, 'Foldable music stand for rehearsal');
    expect(find.text('Your post'), findsOneWidget);
    expect(
      repository.current
          .where((listing) => listing.id == 'local-widget-created'),
      hasLength(1),
    );

    await tester.tap(find.text('Foldable music stand for rehearsal'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Close listing'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Close listing'), findsOneWidget);
  });

  testWidgets('filtered cards navigate by Listing rather than source index',
      (tester) async {
    final repository = _SequenceRepository([
      [
        _testListing(id: 'first-need', title: 'First complete-list need'),
        _testListing(
          id: 'filtered-offer',
          title: 'Filtered offer card',
          kind: ListingKind.offer,
        ),
        _testListing(id: 'third-need', title: 'Third complete-list need'),
      ],
    ]);
    await tester.pumpWidget(
      ViharLoopApp(
          localAiService: const RuleBasedListingAssistant(),
          listingRepository: repository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Offers'));
    await tester.pumpAndSettle();
    await _showFeedListing(tester, 'Filtered offer card');
    expect(find.text('First complete-list need'), findsNothing);
    await tester.tap(find.text('Filtered offer card'));
    await tester.pumpAndSettle();

    expect(find.text('Listing details'), findsOneWidget);
    expect(find.text('Filtered offer card'), findsOneWidget);
    expect(find.text('First complete-list need'), findsNothing);
  });

  testWidgets('ready feed opens Privacy & data and cancel keeps feed unchanged',
      (tester) async {
    final original = _testListing(title: 'Listing that stays after cancel');
    final repository = _SequenceRepository([
      [original],
    ]);
    await tester.pumpWidget(ViharLoopApp(
        localAiService: const RuleBasedListingAssistant(),
        listingRepository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Privacy & data'), findsOneWidget);
    await tester.tap(find.text('Privacy & data'));
    await tester.pumpAndSettle();
    expect(find.text('What stays on this device'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text(original.title), findsOneWidget);
    expect(repository.resetCalls, 0);
  });

  testWidgets(
      'ready reset replaces records, clears filters, and reports success',
      (tester) async {
    final oldLocal = _testListing(
      id: 'old-local',
      title: 'Old local canary',
      origin: ListingOrigin.local,
      isSaved: true,
      isContacted: true,
      status: ListingStatus.closed,
    );
    final resetSamples = _resetSamples();
    final repository = _SequenceRepository(
      [
        [oldLocal],
      ],
      resetResult: resetSamples,
    );
    await tester.pumpWidget(ViharLoopApp(
        localAiService: const RuleBasedListingAssistant(),
        listingRepository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Offers'));
    await tester.pump();

    await _openAndConfirmPrivacyReset(tester);

    expect(repository.resetCalls, 1);
    expect(find.text('Old local canary'), findsNothing);
    expect(find.text('Reset sample 0'), findsOneWidget);
    expect(find.text('Showing 9 listings'), findsOneWidget);
    expect(find.text('Local data reset. Sample listings restored.'),
        findsOneWidget);
    final allChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'All'),
    );
    expect(allChip.selected, isTrue);
  });

  testWidgets('empty and failed feeds expose reset recovery to Ready',
      (tester) async {
    for (final response in <Object>[const <Listing>[], Exception('corrupt')]) {
      final repository = _SequenceRepository(
        [response],
        resetResult: _resetSamples(),
      );
      await tester.pumpWidget(ViharLoopApp(
          localAiService: const RuleBasedListingAssistant(),
          listingRepository: repository));
      await tester.pumpAndSettle();

      expect(find.text('Privacy & data'), findsOneWidget);
      if (response is Exception) {
        expect(find.text('Retry loading listings'), findsOneWidget);
      } else {
        expect(find.text('Post a need or offer'), findsOneWidget);
      }

      await _openAndConfirmPrivacyReset(tester);

      expect(repository.resetCalls, 1);
      expect(find.text('Showing 9 listings'), findsOneWidget);
      expect(find.text('Reset sample 0'), findsOneWidget);
      expect(find.text('Unable to load listings'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });
}

Future<void> _selectDropdown<T>(
  WidgetTester tester,
  String option,
) async {
  await tester.scrollUntilVisible(
    find.byType(DropdownButtonFormField<T>),
    300,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.ensureVisible(find.byType(DropdownButtonFormField<T>));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(DropdownButtonFormField<T>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

Future<void> _showFeedListing(WidgetTester tester, String title) async {
  await tester.scrollUntilVisible(
    find.text(title),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> _openAndConfirmPrivacyReset(WidgetTester tester) async {
  await tester.tap(find.text('Privacy & data'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.byKey(const Key('reset-local-data-button')),
    300,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(find.byKey(const Key('reset-local-data-button')));
  await tester.pumpAndSettle();
  final confirm = find.descendant(
    of: find.byType(AlertDialog),
    matching: find.widgetWithText(FilledButton, 'Reset local data'),
  );
  await tester.tap(confirm);
  await tester.pumpAndSettle();
}

class _SequenceRepository implements ListingRepository {
  _SequenceRepository(
    this._responses, {
    this.resetResult,
  });

  final List<Object> _responses;
  final List<Listing>? resetResult;
  int callCount = 0;
  int resetCalls = 0;
  List<Listing> _current = const [];
  List<Listing> get current => List.unmodifiable(_current);

  @override
  Future<List<Listing>> fetchListings() async {
    final response = _responses[callCount++];
    if (response is List<Listing>) {
      _current = response;
      return _current;
    }
    throw response;
  }

  @override
  Future<Listing> createListing(ListingDraft draft) async {
    final created = Listing(
      id: 'local-widget-created',
      neighborhoodId: 'vidyavihar',
      kind: draft.kind,
      title: draft.title.trim(),
      description: draft.description.trim(),
      category: draft.category,
      approximateArea: draft.approximateArea,
      contactPreference: draft.contactPreference,
      createdAt: draft.activeUntil.subtract(const Duration(hours: 2)),
      activeUntil: draft.activeUntil,
      status: ListingStatus.open,
      isSaved: false,
      isContacted: false,
      origin: ListingOrigin.local,
    );
    _current = [..._current, created];
    return created;
  }

  @override
  Future<List<Listing>> resetLocalData() async {
    resetCalls++;
    _current = resetResult ?? _current;
    return current;
  }

  @override
  Future<Listing> setSaved({
    required String listingId,
    required bool isSaved,
  }) {
    return _update(
      listingId,
      (listing) => listing.copyWith(isSaved: isSaved),
    );
  }

  @override
  Future<Listing> setContacted({
    required String listingId,
    required bool isContacted,
  }) {
    return _update(
      listingId,
      (listing) => listing.copyWith(isContacted: isContacted),
    );
  }

  @override
  Future<Listing> setStatus({
    required String listingId,
    required ListingStatus status,
  }) {
    return _update(listingId, (listing) {
      if (listing.origin != ListingOrigin.local) {
        throw const ListingStatusChangeNotAllowedException();
      }
      return listing.copyWith(status: status);
    });
  }

  Future<Listing> _update(
    String id,
    Listing Function(Listing listing) change,
  ) async {
    final index = _current.indexWhere((listing) => listing.id == id);
    if (index == -1) {
      throw const ListingNotFoundException();
    }
    final updated = change(_current[index]);
    final next = _current.toList();
    next[index] = updated;
    _current = next;
    return updated;
  }
}

class _PendingRepository implements ListingRepository {
  _PendingRepository(this.result);

  final Future<List<Listing>> result;

  @override
  Future<List<Listing>> fetchListings() => result;

  @override
  Future<List<Listing>> resetLocalData() {
    throw UnimplementedError();
  }

  @override
  Future<Listing> createListing(ListingDraft draft) {
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

Listing _testListing({
  String id = 'test-charger',
  String title = 'USB-C laptop charger for two hours',
  ListingKind kind = ListingKind.need,
  ListingStatus status = ListingStatus.open,
  ListingOrigin origin = ListingOrigin.sample,
  bool isSaved = false,
  bool isContacted = false,
}) {
  final now = DateTime.now();
  return Listing(
    id: id,
    neighborhoodId: 'vidyavihar',
    kind: kind,
    title: title,
    description: 'A charger would help finish an assignment.',
    category: ListingCategory.electronics,
    approximateArea: ApproximateArea.somaiyaSide,
    contactPreference: ContactPreference.publicPlace,
    createdAt: now,
    activeUntil: now.add(const Duration(hours: 2)),
    status: status,
    isSaved: isSaved,
    isContacted: isContacted,
    origin: origin,
  );
}

List<Listing> _resetSamples() {
  return List.generate(
    9,
    (index) => _testListing(
      id: 'reset-sample-$index',
      title: 'Reset sample $index',
      kind: index.isEven ? ListingKind.need : ListingKind.offer,
      origin: ListingOrigin.sample,
    ),
  );
}
