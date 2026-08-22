// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/moderation/content_moderation_providers.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/trips/data/trip_shares_sync.dart';
import 'package:tankstellen/features/trips/data/trip_history_entry.dart';
import 'package:tankstellen/features/trips/domain/trip_recorder.dart';
import 'package:tankstellen/features/trips/presentation/widgets/shared_trips_section.dart';
import 'package:tankstellen/features/trips/providers/shared_trips_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #3726 — widget coverage of the in-app REPORT + BLOCK flow on the
/// "Shared with me" section (the Play UGC-policy prerequisite):
///
///  * long-press → moderation sheet → Report → confirm dialog → the
///    injectable submitter receives (trip_share, tripId), the row hides
///    and the confirmation snackbar shows;
///  * a failed submit keeps the row visible and says so;
///  * Block author hides EVERY trip that author shared, persists the id
///    into the device-local block list, and leaves other authors alone.
void main() {
  late AppLocalizations en;

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  TripHistoryEntry entry(String id) => TripHistoryEntry(
        id: id,
        vehicleId: null,
        summary: TripSummary(
          startedAt: DateTime(2026, 5, 10, 10),
          endedAt: DateTime(2026, 5, 10, 10, 30),
          distanceKm: 12.5,
          maxRpm: 3000,
          highRpmSeconds: 5,
          idleSeconds: 30,
          harshBrakes: 0,
          harshAccelerations: 0,
        ),
      );

  // Two trips shared by alice, one by bob.
  final fetch = SharedTripsFetch(
    entries: [entry('t1'), entry('t2'), entry('t3')],
    ownerByTripId: const {'t1': 'alice', 't2': 'bob', 't3': 'alice'},
  );

  Future<_Harness> pumpSection(
    WidgetTester tester, {
    bool submitSucceeds = true,
  }) async {
    final harness = _Harness(submitSucceeds: submitSucceeds);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsStorageProvider.overrideWithValue(harness.settings),
          sharedTripsProvider.overrideWith(() => _FakeSharedTrips(fetch)),
          contentReportSubmitProvider.overrideWithValue(harness.submit),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(child: SharedTripsSection()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return harness;
  }

  Future<void> openSheetFor(WidgetTester tester, String tripId) async {
    await tester.longPress(find.byKey(ValueKey('trajet-$tripId')));
    await tester.pumpAndSettle();
  }

  testWidgets('report flow: confirm → submit(trip_share, id) → row hidden '
      '+ snackbar', (tester) async {
    final harness = await pumpSection(tester);
    expect(find.byKey(const ValueKey('trajet-t1')), findsOneWidget);

    await openSheetFor(tester, 't1');
    await tester.tap(find.byKey(const Key('shared_trip_report_action')));
    await tester.pumpAndSettle();
    // Confirmation dialog — nothing submitted yet.
    expect(find.text(en.contentModerationReportDialogTitle), findsOneWidget);
    expect(harness.reported, isEmpty);

    await tester.tap(find.byKey(const Key('shared_trip_report_confirm')));
    await tester.pumpAndSettle();

    expect(harness.reported, [('trip_share', 't1')]);
    expect(find.byKey(const ValueKey('trajet-t1')), findsNothing,
        reason: 'a reported item hides immediately');
    expect(find.byKey(const ValueKey('trajet-t2')), findsOneWidget);
    expect(find.text(en.contentModerationReportedSnack), findsOneWidget);
    // The hidden id persisted — a restart keeps it hidden.
    expect(
        harness.settings.values[StorageKeys.reportedContentTargetIds], ['t1']);
  });

  testWidgets('cancelling the report dialog submits nothing', (tester) async {
    final harness = await pumpSection(tester);
    await openSheetFor(tester, 't1');
    await tester.tap(find.byKey(const Key('shared_trip_report_action')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.cancel));
    await tester.pumpAndSettle();
    expect(harness.reported, isEmpty);
    expect(find.byKey(const ValueKey('trajet-t1')), findsOneWidget);
  });

  testWidgets('failed submit keeps the row and shows the failure snackbar',
      (tester) async {
    final harness = await pumpSection(tester, submitSucceeds: false);
    await openSheetFor(tester, 't1');
    await tester.tap(find.byKey(const Key('shared_trip_report_action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shared_trip_report_confirm')));
    await tester.pumpAndSettle();

    expect(harness.reported, [('trip_share', 't1')]);
    expect(find.byKey(const ValueKey('trajet-t1')), findsOneWidget,
        reason: 'an unsent report must not silently hide the content');
    expect(
        find.text(en.contentModerationReportFailedSnack), findsOneWidget);
  });

  testWidgets('block flow: EVERY trip by the blocked author disappears and '
      'the block list persists', (tester) async {
    final harness = await pumpSection(tester);
    expect(find.byKey(const ValueKey('trajet-t3')), findsOneWidget);

    await openSheetFor(tester, 't1');
    await tester.tap(find.byKey(const Key('shared_trip_block_action')));
    await tester.pumpAndSettle();
    expect(find.text(en.contentModerationBlockDialogTitle), findsOneWidget);

    await tester.tap(find.byKey(const Key('shared_trip_block_confirm')));
    await tester.pumpAndSettle();

    // alice's two trips vanish; bob's stays.
    expect(find.byKey(const ValueKey('trajet-t1')), findsNothing);
    expect(find.byKey(const ValueKey('trajet-t3')), findsNothing);
    expect(find.byKey(const ValueKey('trajet-t2')), findsOneWidget);
    expect(find.text(en.contentModerationBlockedSnack), findsOneWidget);
    expect(harness.settings.values[StorageKeys.blockedContentAuthorIds],
        ['alice']);
  });
}

/// Recording fakes shared by the tests.
class _Harness {
  final _MemorySettings settings = _MemorySettings();
  final List<(String, String)> reported = [];
  final bool submitSucceeds;

  _Harness({required this.submitSucceeds});

  Future<bool> submit({
    required String targetKind,
    required String targetId,
  }) async {
    reported.add((targetKind, targetId));
    return submitSucceeds;
  }
}

/// Serves the canned fetch without touching sync gates or the network.
class _FakeSharedTrips extends SharedTrips {
  final SharedTripsFetch fetch;
  _FakeSharedTrips(this.fetch);

  @override
  Future<SharedTripsFetch> build() async => fetch;
}

/// In-memory [SettingsStorage] backing the REAL moderation providers, so
/// the tests exercise the persistence contract, not a stub of it.
class _MemorySettings implements SettingsStorage {
  final Map<String, dynamic> values = {};

  @override
  dynamic getSetting(String key) => values[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    values[key] = value;
  }

  @override
  bool get isSetupComplete => true;

  @override
  bool get isSetupSkipped => false;

  @override
  Future<void> skipSetup() async {}

  @override
  Future<void> resetSetupSkip() async {}
}
