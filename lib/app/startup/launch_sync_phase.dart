// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/storage_repository.dart';
import '../../core/logging/error_logger.dart';
import '../../core/perf/launch_sync_trace.dart';
import '../../core/storage/hive_storage.dart';
import '../../core/sync/app_resume_sync.dart';
import '../../core/sync/supabase_client.dart';
import '../../core/sync/sync_provider.dart';
import '../../core/sync/sync_pull_coordinator.dart';
import '../../core/sync/sync_run_trace.dart';
import '../../core/sync/tanksync_init.dart';
import '../../core/sync/tanksync_init_retry.dart';
import '../../features/consumption/providers/trip_recording_provider.dart';
import '../../features/feature_management/application/feature_flags_provider.dart';
import '../../features/feature_management/domain/feature.dart';
import 'launch_sync_pulls.dart';

/// Launch-time server→local sync — extracted from `AppInitializer` by the
/// #3139 phase decomposition, re-architected around the #3447
/// [SyncPullCoordinator]:
///
///  1. [registerPulls] installs the full pull matrix (every synced table,
///     see [LaunchSyncPulls.buildEntries]) plus the master gate
///     (client-ready ∧ `sync_enabled`) into the app-wide coordinator;
///  2. [runLaunchPulls] replays it — all tables in PARALLEL (#3450: one
///     failing or hung table never blocks the rest; wall-clock ≈ the
///     slowest pull), each spanned on the #3445 launch trace;
///  3. [handleInitOutcome] reacts to the TankSync init result: the #3449
///     relink-required state surfaces to the sync settings, a failed /
///     timed-out init arms the #3450 background retry ladder whose late
///     success replays the same pulls;
///  4. [wireResumeSync] hands the #3447 app-resume trigger its app-layer
///     callbacks (the recording-active guard reads
///     `tripRecordingProvider`, which core must not import).
///
/// ## Ordering contract (#3139)
///
/// `AppInitializer.run()` drives 1→4 inside the SAME post-first-frame
/// closure as `CommunityConfig.load()` and the TankSync init, strictly
/// after both — the pulls read `TankSyncClient.client`, and they must
/// follow the #3126 `SyncRunTrace.begin('launch')` mint so the per-table
/// sync counts thread under one run id.
///
/// Every failure is caught and routed through [errorLogger]
/// (`ErrorLayer.sync`); nothing in this phase may block or crash the
/// running app.
class LaunchSyncPhase {
  LaunchSyncPhase._();

  /// Test seam for the `TankSyncClient.client != null` readiness guard —
  /// the static client has no injection point, so the launch-span tests
  /// (#3445) force readiness here instead of standing up Supabase.
  @visibleForTesting
  static bool Function()? clientReadyOverride;

  static bool get _clientReady =>
      clientReadyOverride?.call() ?? (TankSyncClient.client != null);

  /// #3445 — arm the launch-sync span recorder from the
  /// `Feature.startupTrace` devtool flag. Lives HERE (app layer) because
  /// core/perf must not import feature_management; returns `null` (zero
  /// overhead) when the flag is off.
  static LaunchSyncTrace? armTrace(ProviderContainer container) =>
      LaunchSyncTrace.maybeArm(
        enabled: container
            .read(enabledFeaturesProvider)
            .contains(Feature.startupTrace),
      );

  /// Install the #3447 pull matrix into [SyncPullCoordinator.instance].
  /// Idempotent (re-registration replaces the list); cheap (no I/O), so it
  /// runs BEFORE the TankSync init — a "sync now" tap can never observe an
  /// empty registry.
  static void registerPulls(
    ProviderContainer container,
    StorageRepository storage,
  ) {
    SyncPullCoordinator.instance.register(
      enabled: () =>
          _clientReady && container.read(syncStateProvider).enabled,
      entries: LaunchSyncPulls.buildEntries(container, storage),
    );
  }

  /// Replay the registered pull matrix (#3450: parallel, per-table
  /// timeouts, per-table error isolation). No-ops cleanly when TankSync
  /// isn't initialised or sync is disabled — the coordinator's master gate
  /// returns before any span begins.
  static Future<void> runLaunchPulls(
    ProviderContainer container, {
    LaunchSyncTrace? trace,
  }) =>
      SyncPullCoordinator.instance.pullAll(trace: trace);

  /// React to [TankSyncInit.lastOutcome] after the (timeout-bounded) init:
  ///
  ///  * `relinkRequired` → mark the #3449 state on [syncStateProvider] so
  ///    sync settings surface the re-link guidance;
  ///  * `failed` / still-pending (the 8 s timeout abandoned the future) →
  ///    arm the #3450 retry ladder (30 s → 5 min backoff, max 5, plus the
  ///    app-resume fast path). A late success mints a fresh sync-run id
  ///    and replays the launch pulls;
  ///  * `ready` / `notConfigured` → nothing to do.
  static void handleInitOutcome(
    ProviderContainer container,
    HiveStorage storage,
  ) {
    final outcome = TankSyncInit.lastOutcome;
    if (outcome == TankSyncInitOutcome.ready ||
        outcome == TankSyncInitOutcome.notConfigured) {
      return;
    }
    if (outcome == TankSyncInitOutcome.relinkRequired) {
      _markRelinkRequired(container);
      return;
    }
    TankSyncInitRetry.instance.arm(
      attempt: () async {
        // The orphaned first init may have finished in the background —
        // a live session means there is nothing left to retry.
        if (TankSyncClient.isConnected) return TankSyncInitOutcome.ready;
        try {
          return await TankSyncInit.run(storage)
              .timeout(const Duration(seconds: 8));
        } on TimeoutException {
          return TankSyncInitOutcome.failed;
        }
      },
      onReady: () async {
        // #3126 — the late launch pulls thread under their own run id.
        SyncRunTrace.begin('launch-retry');
        await runLaunchPulls(container);
      },
      onRelinkRequired: () => _markRelinkRequired(container),
    );
  }

  /// Configure the #3447 app-resume sync trigger. The recording-active
  /// guard is `tripRecordingProvider.isActive` — the same signal the
  /// persistent recording banner uses, covering OBD2, paused,
  /// dropped-link and GPS-degraded trips alike.
  static void wireResumeSync(ProviderContainer container) {
    AppResumeSync.instance.configure(
      recordingActive: () {
        try {
          return container.read(tripRecordingProvider).isActive;
        } catch (e, st) {
          // Provider-wiring fault — assume no recording (a pull is safe;
          // silently never syncing again is not) and make it visible.
          unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: const {
            'where': 'AppResumeSync recording guard read failed'
          }));
          return false;
        }
      },
    );
  }

  static void _markRelinkRequired(ProviderContainer container) {
    try {
      container.read(syncStateProvider.notifier).markRelinkRequired();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st,
          context: const {'where': 'markRelinkRequired'}));
    }
  }
}
