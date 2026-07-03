// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/startup/launch_sync_phase.dart';
import 'package:tankstellen/core/perf/launch_sync_trace.dart';
import 'package:tankstellen/core/perf/startup_timer.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/core/sync/sync_events.dart';
import 'package:tankstellen/core/sync/fill_ups_sync.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';
import 'package:tankstellen/core/sync/sync_pull_coordinator.dart';
import 'package:tankstellen/core/sync/vehicles_sync.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../fakes/fake_hive_storage.dart';
import '../../helpers/silence_error_logger.dart';

/// #3445/#3447 — the launch-sync phase records per-pull spans onto the
/// startup trace when armed, and records NOTHING when the flag is off or
/// sync is disabled (the zero-overhead acceptance criterion).
///
/// The fake-synced launch path: [LaunchSyncPhase.clientReadyOverride]
/// stands in for an initialised TankSync client; the unauthenticated real
/// sync transports then make every pull a safe local no-op (no network),
/// which is exactly enough to drive the span wiring.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  silenceErrorLoggerSpool();

  late FakeHiveStorage fakeStorage;

  setUp(() {
    fakeStorage = FakeHiveStorage();
    SyncPullCoordinator.instance.resetForTest();
    StartupTimer.instance.reset();
    StartupTimer.instance.start();
  });
  tearDown(() {
    LaunchSyncPhase.clientReadyOverride = null;
    SyncPullCoordinator.instance.resetForTest();
    StartupTimer.instance.reset();
  });

  ProviderContainer createContainer({
    required bool syncEnabled,
    bool tripConsents = false,
    List<Override> extraOverrides = const [],
  }) {
    if (tripConsents) {
      fakeStorage
        ..putSetting(StorageKeys.consentCloudSync, true)
        ..putSetting(StorageKeys.consentSyncTrips, true);
    }
    final c = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(fakeStorage),
      syncStateProvider.overrideWith(() => _FakeSyncState(SyncConfig(
            enabled: syncEnabled,
            supabaseUrl: 'https://test.supabase.co',
            supabaseAnonKey: 'key',
            userId: 'user-123',
            mode: SyncMode.community,
          ))),
      ...extraOverrides,
    ]);
    addTearDown(c.dispose);
    return c;
  }

  Future<void> registerAndRun(ProviderContainer container,
      {LaunchSyncTrace? trace}) async {
    LaunchSyncPhase.registerPulls(container, fakeStorage);
    await LaunchSyncPhase.runLaunchPulls(container, trace: trace);
  }

  group('LaunchSyncPhase pull spans (#3445/#3447)', () {
    test('armed + fake-synced launch → one span per registered pull + '
        'phase-done', () async {
      LaunchSyncPhase.clientReadyOverride = () => true;
      final container = createContainer(syncEnabled: true);
      final trace = LaunchSyncTrace.maybeArm(enabled: true)!;

      await registerAndRun(container, trace: trace);
      trace.finish();

      final spans = StartupTimer.instance.spans;
      final names = spans.map((s) => s.name).toSet();
      // #3447 — the full matrix spans (gated-off pulls span too, with
      // pulled: 0), plus the phase-done closer.
      expect(
          names,
          containsAll({
            SyncTables.tripSummaries,
            '${SyncTables.favorites}+${SyncTables.ignoredStations}',
            SyncTables.stationRatings,
            SyncTables.alerts,
            SyncTables.itineraries,
            SyncTables.vehicles,
            SyncTables.fillUps,
            SyncTables.obd2Baselines,
            'sync_phase_done',
          }));
      for (final s in spans) {
        expect(s.endMs, greaterThanOrEqualTo(s.startMs));
      }
      final ratings =
          spans.firstWhere((s) => s.name == SyncTables.stationRatings);
      expect(ratings.attributes['table'], SyncTables.stationRatings);
      expect(ratings.attributes['pulled'], 0,
          reason: 'the unauthenticated fetch pulled nothing');
    });

    test('trace disarmed (flag off) → pulls run, zero spans recorded',
        () async {
      LaunchSyncPhase.clientReadyOverride = () => true;
      final container = createContainer(syncEnabled: true);

      await registerAndRun(container,
          trace: LaunchSyncTrace.maybeArm(enabled: false));

      expect(StartupTimer.instance.spans, isEmpty);
    });

    test('sync disabled → returns before any span begins', () async {
      LaunchSyncPhase.clientReadyOverride = () => true;
      final container = createContainer(syncEnabled: false);
      final trace = LaunchSyncTrace.maybeArm(enabled: true)!;

      await registerAndRun(container, trace: trace);

      expect(StartupTimer.instance.spans, isEmpty,
          reason: 'zero overhead when sync is disabled');
    });

    test('TankSync client not ready → returns before any span begins',
        () async {
      LaunchSyncPhase.clientReadyOverride = () => false;
      final container = createContainer(syncEnabled: true);
      final trace = LaunchSyncTrace.maybeArm(enabled: true)!;

      await registerAndRun(container, trace: trace);

      expect(StartupTimer.instance.spans, isEmpty);
    });

    test(
        '#3448 — ANONYMOUS account + cloudSync + syncTrips consents: the '
        'vehicles/fill-ups pulls execute (previously email-gated off) and '
        'the fill-ups call-site emit fires', () async {
      LaunchSyncPhase.clientReadyOverride = () => true;
      final fakeFillUps = _FakeFillUpList(pulled: 3);
      final fakeVehicles = _FakeVehicleList(pulled: 2);
      // NOTE: the fake sync state carries NO email — an anonymous session.
      final container = createContainer(
        syncEnabled: true,
        tripConsents: true,
        extraOverrides: [
          fillUpListProvider.overrideWith(() => fakeFillUps),
          vehicleProfileListProvider.overrideWith(() => fakeVehicles),
        ],
      );
      final events = <SyncTableChanged>[];
      final sub = SyncEvents.instance
          .forTable(SyncTables.fillUps)
          .listen(events.add);
      addTearDown(sub.cancel);

      await registerAndRun(container);
      // Broadcast-stream delivery is async — drain the microtask queue.
      await Future<void>.delayed(Duration.zero);

      expect(fakeVehicles.pullCalls, 1,
          reason: 'vehicles must pull for a consented anonymous account '
              '(#3448 dropped the email requirement)');
      expect(fakeFillUps.pullCalls, 1,
          reason: 'fill-ups must pull for a consented anonymous account');
      expect(events.map((e) => e.changedCount), contains(3),
          reason: 'the fill-ups persist site is length-frozen (#3138), so '
              'the pull thunk must emit at the call site (#3446)');
    });

    test('#3448 — consents OFF keeps the trip-data pulls gated', () async {
      LaunchSyncPhase.clientReadyOverride = () => true;
      final fakeFillUps = _FakeFillUpList(pulled: 3);
      final fakeVehicles = _FakeVehicleList(pulled: 2);
      final container = createContainer(
        syncEnabled: true,
        extraOverrides: [
          fillUpListProvider.overrideWith(() => fakeFillUps),
          vehicleProfileListProvider.overrideWith(() => fakeVehicles),
        ],
      );

      await registerAndRun(container);

      expect(fakeVehicles.pullCalls, 0);
      expect(fakeFillUps.pullCalls, 0);
    });
  });
}

/// Records `pullFromServer` invocations without touching Supabase.
class _FakeFillUpList extends FillUpList {
  _FakeFillUpList({required this.pulled});
  final int pulled;
  int pullCalls = 0;

  @override
  List<FillUp> build() => [];

  @override
  Future<int> pullFromServer(
      {FillUpsMergeFn mergeFn = FillUpsSync.merge}) async {
    pullCalls++;
    return pulled;
  }
}

/// Records `pullFromServer` invocations without touching Supabase.
class _FakeVehicleList extends VehicleProfileList {
  _FakeVehicleList({required this.pulled});
  final int pulled;
  int pullCalls = 0;

  @override
  List<VehicleProfile> build() => [];

  @override
  Future<int> pullFromServer(
      {VehiclesMergeFn mergeFn = VehiclesSync.merge}) async {
    pullCalls++;
    return pulled;
  }
}

/// Fixed-config [SyncState] without Supabase — the inherited
/// `syncAndPersistRatings` seam is exactly what the phase under test
/// drives (mirrors `sync_pull_persist_test.dart`).
class _FakeSyncState extends SyncState {
  final SyncConfig _config;
  _FakeSyncState(this._config);

  @override
  SyncConfig build() => _config;
}
