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

  testWidgets('tapping a card opens complete details and local markers',
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
      ViharLoopApp(listingRepository: repository),
    );
    await tester.pumpAndSettle();

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

      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Contacted'), findsOneWidget);
      expect(find.text('Your post'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          RegExp(r'Open\. Saved\. Contacted\. Your post\. Open details'),
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
  List<Listing> _current = const [];

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
