import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vihar_loop/data/listing_repository.dart';
import 'package:vihar_loop/domain/listing.dart';
import 'package:vihar_loop/domain/listing_draft.dart';
import 'package:vihar_loop/features/privacy_data/privacy_data_screen.dart';
import 'package:vihar_loop/features/privacy_data/privacy_data_view_model.dart';

import '../../support/listing_fixture.dart';

void main() {
  testWidgets('shows an accurate local data and protection inventory',
      (tester) async {
    final repository = _PrivacyRepository();
    await tester.pumpWidget(
      MaterialApp(home: PrivacyDataScreen(repository: repository)),
    );

    expect(find.text('Privacy & data'), findsOneWidget);
    expect(
      find.textContaining('There is no account, server, or analytics'),
      findsOneWidget,
    );
    for (final heading in [
      'What stays on this device',
      'What ViharLoop does not collect',
      'How local protection works',
      'Reset local data',
    ]) {
      await _scrollTo(tester, heading);
      expect(
        find.text(heading),
        heading == 'Reset local data' ? findsNWidgets(2) : findsOneWidget,
      );
    }
    await _scrollTo(tester, 'Reset local data');
    expect(find.textContaining('unlocked, rooted'), findsOneWidget);
    expect(find.textContaining('fictional sample listings'), findsOneWidget);
    expect(repository.fetchCalls, 0);
  });

  testWidgets('Keep data and dialog Back cancel without repository work',
      (tester) async {
    final repository = _PrivacyRepository();
    await tester.pumpWidget(
      MaterialApp(home: PrivacyDataScreen(repository: repository)),
    );
    await _showReset(tester);

    await tester.tap(find.byKey(const Key('reset-local-data-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep data'));
    await tester.pumpAndSettle();
    expect(find.text('Reset local data?'), findsNothing);
    expect(repository.resetCalls, 0);

    await tester.tap(find.byKey(const Key('reset-local-data-button')));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Reset local data?'), findsNothing);
    expect(repository.resetCalls, 0);
  });

  testWidgets('confirmed success pops with the exact persisted collection',
      (tester) async {
    final persisted = <Listing>[
      buildTestListing(id: 'sample-reset', origin: ListingOrigin.sample),
    ];
    final repository = _PrivacyRepository(result: persisted);
    List<Listing>? returned;
    await tester.pumpWidget(
      MaterialApp(
        home: _PrivacyHarness(
          repository: repository,
          onReturned: (value) => returned = value,
        ),
      ),
    );

    await tester.tap(find.text('Open privacy'));
    await tester.pumpAndSettle();
    await _showReset(tester);
    await tester.tap(find.byKey(const Key('reset-local-data-button')));
    await tester.pumpAndSettle();
    await _confirmDialog(tester);
    await tester.pumpAndSettle();

    expect(repository.resetCalls, 1);
    expect(returned, same(persisted));
    expect(find.text('Open privacy'), findsOneWidget);
  });

  testWidgets('pending reset disables action, blocks Back, and runs once',
      (tester) async {
    final pending = Completer<List<Listing>>();
    final repository = _PrivacyRepository(pending: pending);
    await tester.pumpWidget(
      MaterialApp(
        home: _PrivacyHarness(repository: repository),
      ),
    );
    await tester.tap(find.text('Open privacy'));
    await tester.pumpAndSettle();
    await _showReset(tester);
    await tester.tap(find.byKey(const Key('reset-local-data-button')));
    await tester.pumpAndSettle();
    await _confirmDialog(tester);
    await tester.pump();

    expect(find.text('Resetting…'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('reset-local-data-button')),
    );
    expect(button.onPressed, isNull);
    expect(repository.resetCalls, 1);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Privacy & data'), findsOneWidget);
    expect(find.text('Finishing the local-data reset…'), findsOneWidget);
    expect(repository.resetCalls, 1);

    pending.complete([
      buildTestListing(id: 'reset-finished', origin: ListingOrigin.sample),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Open privacy'), findsOneWidget);
  });

  testWidgets('failure stays on screen with honest copy and allows retry',
      (tester) async {
    final repository = _PrivacyRepository(
      failure: Exception('low-level box and key detail'),
    );
    await tester.pumpWidget(
      MaterialApp(home: PrivacyDataScreen(repository: repository)),
    );
    await _showReset(tester);
    await tester.tap(find.byKey(const Key('reset-local-data-button')));
    await tester.pumpAndSettle();
    await _confirmDialog(tester);
    await tester.pumpAndSettle();

    expect(
      find.text(PrivacyDataViewModel.resetFailureMessage),
      findsOneWidget,
    );
    expect(find.textContaining('low-level'), findsNothing);
    expect(find.textContaining('Nothing changed'), findsNothing);
    expect(find.byKey(const Key('reset-local-data-button')), findsOneWidget);

    repository.failure = null;
    repository.result = [
      buildTestListing(id: 'retry-sample', origin: ListingOrigin.sample),
    ];
    await tester.tap(find.byKey(const Key('reset-local-data-button')));
    await tester.pumpAndSettle();
    await _confirmDialog(tester);
    await tester.pumpAndSettle();
    expect(repository.resetCalls, 2);
  });

  testWidgets('is usable at 200 percent text and narrow width', (tester) async {
    tester.view.physicalSize = const Size(640, 1000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: MaterialApp(
          home: PrivacyDataScreen(repository: _PrivacyRepository()),
        ),
      ),
    );
    await _showReset(tester);

    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('reset-local-data-button')));
    await tester.pumpAndSettle();
    expect(find.text('Reset local data?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _showReset(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(const Key('reset-local-data-button')),
    300,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollTo(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text).first,
    300,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
}

Future<void> _confirmDialog(WidgetTester tester) async {
  final dialog = find.byType(AlertDialog);
  final confirm = find.descendant(
    of: dialog,
    matching: find.widgetWithText(FilledButton, 'Reset local data'),
  );
  await tester.tap(confirm);
}

class _PrivacyHarness extends StatelessWidget {
  const _PrivacyHarness({
    required this.repository,
    this.onReturned,
  });

  final ListingRepository repository;
  final ValueChanged<List<Listing>>? onReturned;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () async {
            final result = await Navigator.push<List<Listing>>(
              context,
              MaterialPageRoute<List<Listing>>(
                builder: (context) => PrivacyDataScreen(
                  repository: repository,
                ),
              ),
            );
            if (result != null) {
              onReturned?.call(result);
            }
          },
          child: const Text('Open privacy'),
        ),
      ),
    );
  }
}

class _PrivacyRepository implements ListingRepository {
  _PrivacyRepository({
    this.result,
    this.failure,
    this.pending,
  });

  List<Listing>? result;
  Object? failure;
  Completer<List<Listing>>? pending;
  int fetchCalls = 0;
  int resetCalls = 0;

  @override
  Future<List<Listing>> fetchListings() async {
    fetchCalls++;
    return const [];
  }

  @override
  Future<List<Listing>> resetLocalData() async {
    resetCalls++;
    if (failure case final error?) {
      throw error;
    }
    if (pending case final completer?) {
      return completer.future;
    }
    return result ?? const [];
  }

  @override
  Future<Listing> createListing(ListingDraft draft) {
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
