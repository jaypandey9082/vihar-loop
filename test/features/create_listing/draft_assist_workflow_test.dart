import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vihar_loop/app/vihar_loop_app.dart';
import 'package:vihar_loop/data/listing_repository.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/domain/listing_draft.dart';
import 'package:vihar_loop/local_ai/rule_based_listing_assistant.dart';

void main() {
  testWidgets('offline fallback previews, applies, posts, and reaches feed',
      (tester) async {
    final now = DateTime(2026, 7, 30, 12);
    final repository = _WorkflowRepository(now);
    await tester.pumpWidget(
      ViharLoopApp(
        listingRepository: repository,
        localAiService: const RuleBasedListingAssistant(),
        clock: () => now,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Post a need or offer'));
    await tester.pumpAndSettle();
    const description = 'Need a guitar capo for rehearsal near Somaiya today.';
    await tester.enterText(find.byType(TextFormField).last, description);
    await _scrollTo(tester, 'Suggest type, title & category');
    await tester.tap(find.text('Suggest type, title & category'));
    await tester.pumpAndSettle();

    expect(find.text('Suggested details'), findsOneWidget);
    expect(
      find.textContaining('Type: Need', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Title: Guitar capo for rehearsal',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Category: Music, hobbies & sports',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Source: Built-in offline rules',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(repository.drafts, isEmpty);

    await _scrollTo(tester, 'Use suggestions');
    await tester.tap(find.text('Use suggestions'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(repository.drafts, isEmpty);
    expect(
      tester
          .widget<TextFormField>(
            find.byType(TextFormField, skipOffstage: false).last,
          )
          .controller
          ?.text,
      description,
    );

    await tester.enterText(
      find.byType(TextFormField, skipOffstage: false).first,
      'Guitar capo for rehearsal today',
    );
    final areaControl = find.byType(DropdownButtonFormField<ApproximateArea>);
    await _scrollTo(tester, 'Approximate area');
    await tester.tap(areaControl);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Somaiya side').last);
    await tester.pumpAndSettle();

    final contactControl =
        find.byType(DropdownButtonFormField<ContactPreference>);
    await _scrollTo(tester, 'Contact preference');
    await tester.tap(contactControl);
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
    await tester.tap(find.text('Post need'));
    await tester.pumpAndSettle();

    expect(repository.drafts, hasLength(1));
    final draft = repository.drafts.single;
    expect(draft.kind, ListingKind.need);
    expect(draft.title, 'Guitar capo for rehearsal today');
    expect(draft.category, ListingCategory.musicHobbiesAndSports);
    expect(draft.description, description);
    expect(find.text('Guitar capo for rehearsal today'), findsOneWidget);
  });
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

class _WorkflowRepository implements ListingRepository {
  _WorkflowRepository(this.now);

  final DateTime now;
  final drafts = <ListingDraft>[];

  @override
  Future<Listing> createListing(ListingDraft draft) async {
    drafts.add(draft);
    return Listing(
      id: 'draft-assist-workflow',
      neighborhoodId: 'vidyavihar',
      kind: draft.kind,
      title: draft.title,
      description: draft.description,
      category: draft.category,
      approximateArea: draft.approximateArea,
      contactPreference: draft.contactPreference,
      createdAt: now,
      activeUntil: draft.activeUntil,
      status: ListingStatus.open,
      isSaved: false,
      isContacted: false,
      origin: ListingOrigin.local,
    );
  }

  @override
  Future<List<Listing>> fetchListings() async => const [];

  @override
  Future<List<Listing>> resetLocalData() async => const [];

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
