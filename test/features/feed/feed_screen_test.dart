import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vihar_loop/app/vihar_loop_app.dart';
import 'package:vihar_loop/data/listing_repository.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/features/feed/feed_screen.dart';
import 'package:vihar_loop/features/feed/feed_view_model.dart';

void main() {
  testWidgets('shows a genuine loading state while the repository is pending',
      (tester) async {
    final pending = Completer<List<Listing>>();
    await tester.pumpWidget(
      ViharLoopApp(
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
    expect(find.text('Offer'), findsOneWidget);
    expect(find.text('Closed'), findsOneWidget);
  });

  testWidgets('tapping a card opens complete read-only details',
      (tester) async {
    await tester.pumpWidget(
      ViharLoopApp(
        listingRepository: _SequenceRepository([
          [_testListing()],
        ]),
      ),
    );
    await tester.pumpAndSettle();

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
    expect(find.text('Save'), findsNothing);
    expect(find.text('Contact'), findsNothing);
  });

  testWidgets('empty state is readable', (tester) async {
    await tester.pumpWidget(
      ViharLoopApp(
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
      ViharLoopApp(listingRepository: repository),
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
          listingRepository: _SequenceRepository([
            [_testListing()],
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(
          RegExp(
            r'Need\. USB-C laptop charger for two hours\. Electronics\. '
            r'Somaiya side\. Needed by .+\. Open\. Open details',
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
}

class _SequenceRepository implements ListingRepository {
  _SequenceRepository(this._responses);

  final List<Object> _responses;
  int callCount = 0;

  @override
  Future<List<Listing>> fetchListings() async {
    final response = _responses[callCount++];
    if (response is List<Listing>) {
      return response;
    }
    throw response;
  }
}

class _PendingRepository implements ListingRepository {
  _PendingRepository(this.result);

  final Future<List<Listing>> result;

  @override
  Future<List<Listing>> fetchListings() => result;
}

Listing _testListing({
  String id = 'test-charger',
  String title = 'USB-C laptop charger for two hours',
  ListingKind kind = ListingKind.need,
  ListingStatus status = ListingStatus.open,
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
    isSaved: false,
    isContacted: false,
    origin: ListingOrigin.sample,
  );
}
