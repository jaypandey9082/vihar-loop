import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vihar_loop/data/listing_repository.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/features/listing_details/listing_details_screen.dart';
import 'package:vihar_loop/features/listing_details/listing_details_view_model.dart';

import '../../support/listing_fixture.dart';

void main() {
  testWidgets('sample listing toggles saved and contacted persistent markers',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final repository = _InteractiveRepository(
      buildTestListing(
        origin: ListingOrigin.sample,
        isSaved: false,
        isContacted: false,
      ),
    );
    final updates = <Listing>[];

    try {
      await _pumpDetails(tester, repository, updates.add);
      await _showAction(tester, 'Save listing');

      final saveNode =
          tester.getSemantics(find.bySemanticsLabel('Save listing'));
      expect(saveNode.flagsCollection.isToggled, Tristate.isFalse);

      await tester.tap(find.text('Save listing'));
      await tester.pumpAndSettle();
      expect(find.text('Remove from saved'), findsOneWidget);
      expect(find.text('Saved on this device.'), findsOneWidget);
      expect(updates.single.isSaved, isTrue);

      await tester.tap(find.text('Remove from saved'));
      await tester.pumpAndSettle();
      expect(find.text('Save listing'), findsOneWidget);
      expect(updates.last.isSaved, isFalse);

      await _showAction(tester, 'Mark as contacted');
      await tester.tap(find.text('Mark as contacted'));
      await tester.pumpAndSettle();
      expect(find.text('Remove contacted mark'), findsOneWidget);
      expect(find.text('Marked as contacted.'), findsOneWidget);
      expect(updates.last.isContacted, isTrue);

      await tester.tap(find.text('Remove contacted mark'));
      await tester.pumpAndSettle();
      expect(find.text('Mark as contacted'), findsOneWidget);
      expect(updates.last.isContacted, isFalse);
      expect(repository.savedValues, [true, false]);
      expect(repository.contactedValues, [true, false]);
      expect(find.text('Close listing'), findsNothing);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('failed mutation keeps old state and shows friendly copy',
      (tester) async {
    final repository = _InteractiveRepository(
      buildTestListing(origin: ListingOrigin.sample, isSaved: false),
    )..savedFailure = StateError('secret technical detail');
    final updates = <Listing>[];

    await _pumpDetails(tester, repository, updates.add);
    await _showAction(tester, 'Save listing');
    await tester.tap(find.text('Save listing'));
    await tester.pumpAndSettle();

    expect(
        find.text(ListingDetailsViewModel.savedFailureMessage), findsOneWidget);
    expect(find.text('secret technical detail'), findsNothing);
    expect(find.text('Save listing'), findsOneWidget);
    expect(updates, isEmpty);
  });

  testWidgets('pending mutation disables controls and blocks back navigation',
      (tester) async {
    final repository = _InteractiveRepository(
      buildTestListing(origin: ListingOrigin.sample, isSaved: false),
    );
    final pending = Completer<Listing>();
    repository.savedResult = pending.future;

    await _pumpDetails(tester, repository, (_) {});
    await _showAction(tester, 'Save listing');
    await tester.tap(find.text('Save listing'));
    await tester.pump();

    expect(find.text('Saving…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final contacted = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Mark as contacted'),
    );
    expect(contacted.onPressed, isNull);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Listing details'), findsOneWidget);
    expect(find.text('Finishing this update…'), findsOneWidget);

    pending.complete(repository.current.copyWith(isSaved: true));
    await tester.pumpAndSettle();
    expect(find.text('Remove from saved'), findsOneWidget);
  });

  testWidgets('local listing close confirms, persists, and reopens',
      (tester) async {
    final repository = _InteractiveRepository(
      buildTestListing(
        origin: ListingOrigin.local,
        status: ListingStatus.open,
        isSaved: false,
      ),
    );
    final updates = <Listing>[];

    await _pumpDetails(tester, repository, updates.add);
    expect(find.text('Your post'), findsOneWidget);
    await _showAction(tester, 'Close listing');

    await tester.tap(find.text('Close listing'));
    await tester.pumpAndSettle();
    expect(find.text('Close this listing?'), findsOneWidget);
    expect(
      find.text('It will stay on this device and can be reopened later.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Keep open'));
    await tester.pumpAndSettle();
    expect(repository.statusValues, isEmpty);

    await tester.tap(find.text('Close listing'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, 'Close listing').last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Reopen listing'), findsOneWidget);
    expect(find.text('Listing closed.'), findsOneWidget);
    expect(updates.last.status, ListingStatus.closed);

    await tester.tap(find.text('Reopen listing'));
    await tester.pumpAndSettle();
    expect(find.text('Close listing'), findsOneWidget);
    expect(find.text('Listing reopened.'), findsOneWidget);
    expect(updates.last.status, ListingStatus.open);
    expect(repository.statusValues, [
      ListingStatus.closed,
      ListingStatus.open,
    ]);
  });

  testWidgets('details remain usable at 200 percent text scale',
      (tester) async {
    final repository = _InteractiveRepository(
      buildTestListing(origin: ListingOrigin.local, isSaved: false),
    );

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
        home: ListingDetailsScreen(
          listing: repository.current,
          repository: repository,
          onListingChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _showAction(tester, 'Close listing');

    expect(find.text('Close listing'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpDetails(
  WidgetTester tester,
  _InteractiveRepository repository,
  ValueChanged<Listing> onChanged,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ListingDetailsScreen(
        listing: repository.current,
        repository: repository,
        onListingChanged: onChanged,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _showAction(WidgetTester tester, String label) async {
  await tester.scrollUntilVisible(
    find.text(label),
    300,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
}

class _InteractiveRepository implements ListingRepository {
  _InteractiveRepository(this.current);

  Listing current;
  Object? savedFailure;
  Future<Listing>? savedResult;
  final List<bool> savedValues = [];
  final List<bool> contactedValues = [];
  final List<ListingStatus> statusValues = [];

  @override
  Future<List<Listing>> fetchListings() async => [current];

  @override
  Future<Listing> setSaved({
    required String listingId,
    required bool isSaved,
  }) async {
    savedValues.add(isSaved);
    if (savedFailure case final failure?) {
      throw failure;
    }
    if (savedResult case final result?) {
      final listing = await result;
      current = listing;
      return listing;
    }
    return current = current.copyWith(isSaved: isSaved);
  }

  @override
  Future<Listing> setContacted({
    required String listingId,
    required bool isContacted,
  }) async {
    contactedValues.add(isContacted);
    return current = current.copyWith(isContacted: isContacted);
  }

  @override
  Future<Listing> setStatus({
    required String listingId,
    required ListingStatus status,
  }) async {
    statusValues.add(status);
    return current = current.copyWith(status: status);
  }
}
