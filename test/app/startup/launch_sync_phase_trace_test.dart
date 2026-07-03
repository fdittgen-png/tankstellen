// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/startup/launch_sync_phase.dart';
import 'package:tankstellen/core/perf/launch_sync_trace.dart';
import 'package:tankstellen/core/perf/startup_timer.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/core/sync/sync_events.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';

import '../../fakes/fake_hive_storage.dart';
import '../../helpers/silence_error_logger.dart';

/// #3445 — the launch-sync phase records per-entity spans onto the
/// startup trace when armed, and records NOTHING when the flag is off or
/// sync is disabled (the zero-overhead acceptance criterion).
///
/// The fake-synced launch path: [LaunchSyncPhase.clientReadyOverride]
/// stands in for an initialised TankSync client; the unauthenticated real
/// sync transports then make every pull a safe local no-op (no network),
/// which is exactly enough to drive the span wiring.
void main() {
  silenceErrorLoggerSpool();

  late FakeHiveStorage fakeStorage;

  setUp(() {
    fakeStorage = FakeHiveStorage();
    StartupTimer.instance.reset();
    StartupTimer.instance.start();
  });
  tearDown(() {
    LaunchSyncPhase.clientReadyOverride = null;
    StartupTimer.instance.reset();
  });

  ProviderContainer createContainer({required bool syncEnabled}) {
    final c = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(fakeStorage),
      syncStateProvider.overrideWith(() => _FakeSyncState(SyncConfig(
            enabled: syncEnabled,
            supabaseUrl: 'https://test.supabase.co',
            supabaseAnonKey: 'key',
            userId: 'user-123',
            mode: SyncMode.community,
          ))),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('LaunchSyncPhase entity spans (#3445)', () {
    test('armed + fake-synced launch → one span per entity + phase-done',
        () async {
      LaunchSyncPhase.clientReadyOverride = () => true;
      final container = createContainer(syncEnabled: true);
      final trace = LaunchSyncTrace.maybeArm(enabled: true)!;

      await LaunchSyncPhase.runEntitySyncMerge(container, fakeStorage,
          trace: trace);
      trace.finish();

      final spans = StartupTimer.instance.spans;
      final names = spans.map((s) => s.name).toList();
      // Anonymous session → the trip-data gate keeps vehicles/fill-ups
      // out; ratings + alerts always ride the master consent.
      expect(names,
          [SyncTables.stationRatings, SyncTables.alerts, 'sync_phase_done']);
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

      await LaunchSyncPhase.runEntitySyncMerge(container, fakeStorage,
          trace: LaunchSyncTrace.maybeArm(enabled: false));

      expect(StartupTimer.instance.spans, isEmpty);
    });

    test('sync disabled → returns before any span begins', () async {
      LaunchSyncPhase.clientReadyOverride = () => true;
      final container = createContainer(syncEnabled: false);
      final trace = LaunchSyncTrace.maybeArm(enabled: true)!;

      await LaunchSyncPhase.runEntitySyncMerge(container, fakeStorage,
          trace: trace);

      expect(StartupTimer.instance.spans, isEmpty,
          reason: 'zero overhead when sync is disabled');
    });

    test('TankSync client not ready → returns before any span begins',
        () async {
      LaunchSyncPhase.clientReadyOverride = () => false;
      final container = createContainer(syncEnabled: true);
      final trace = LaunchSyncTrace.maybeArm(enabled: true)!;

      await LaunchSyncPhase.runEntitySyncMerge(container, fakeStorage,
          trace: trace);

      expect(StartupTimer.instance.spans, isEmpty);
    });
  });
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
