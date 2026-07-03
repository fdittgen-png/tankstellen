// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/startup/launch_sync_phase.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/sync/sync_events.dart';
import 'package:tankstellen/core/sync/sync_pull_coordinator.dart';

import '../../fakes/fake_hive_storage.dart';
import '../../helpers/silence_error_logger.dart';

/// #3447 — the pull-matrix contract: EVERY synced table must be covered
/// by the ONE registered pull list that launch, app-resume and the
/// "sync now" gesture all replay. Before this, each trigger kept its own
/// hand-maintained pull set and each had silently drifted out of
/// coverage (launch was missing favorites/ignored/itineraries/baselines,
/// "sync now" was missing trips/itineraries/baselines/ignored).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  silenceErrorLoggerSpool();

  setUp(SyncPullCoordinator.instance.resetForTest);
  tearDown(SyncPullCoordinator.instance.resetForTest);

  test('the registered pull matrix covers every synced table', () {
    final fakeStorage = FakeHiveStorage();
    final container = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(fakeStorage),
    ]);
    addTearDown(container.dispose);

    LaunchSyncPhase.registerPulls(container, fakeStorage);

    expect(
      SyncPullCoordinator.instance.coveredTables,
      SyncTables.all.toSet(),
      reason: 'a synced table missing here silently never pulls on '
          'launch/resume/sync-now (#3447). Register a SyncPullEntry for '
          'it in LaunchSyncPulls.buildEntries.',
    );
  });

  test('launch, app-resume AND "sync now" all replay the registry '
      '(source-level pin)', () {
    // Each trigger must funnel through SyncPullCoordinator.pullAll — a
    // hand-rolled per-entity list at any trigger is how coverage drifted
    // apart in the first place.
    const triggers = <String, String>{
      // launch (via LaunchSyncPhase.runLaunchPulls) + the #3450 late-init
      // retry onReady.
      'lib/app/startup/launch_sync_phase.dart': 'launch + init-retry',
      // app resume debounce.
      'lib/core/sync/app_resume_sync.dart': 'app resume',
      // the "sync now" gesture.
      'lib/features/sync/providers/data_transparency_provider.dart':
          'sync now',
    };
    triggers.forEach((path, what) {
      final source = File(path).readAsStringSync();
      expect(source, contains('.pullAll('),
          reason: '$what ($path) must replay the registered pull matrix '
              'via SyncPullCoordinator.pullAll (#3447)');
    });
  });

  test('SyncTables.all stays in lockstep with the per-table constants',
      () {
    // A new synced table added as a constant but not to `all` would dodge
    // the coverage assertion above.
    expect(
      SyncTables.all.toSet(),
      {
        SyncTables.favorites,
        SyncTables.ignoredStations,
        SyncTables.stationRatings,
        SyncTables.tripSummaries,
        SyncTables.itineraries,
        SyncTables.alerts,
        SyncTables.vehicles,
        SyncTables.fillUps,
        SyncTables.obd2Baselines,
      },
    );
  });
}
