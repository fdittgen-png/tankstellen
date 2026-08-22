// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'app_initializer.dart';

/// Deferred-task scheduling for [AppInitializer], extracted as a `part`
/// file (sanctioned #3761 decomposition — move-only, behaviour
/// preserved). Holds the launch-sync sequence body and the grouped
/// post-first-frame registrations whose call slots (and relative order)
/// `run()` / `_launch` pin.
///
/// ## Cold-start phases (moved narrative — the ordering lives in `run()`)
///
/// 1. **bootstrap** — Flutter binding, edge-to-edge, debug-print
///    silencing. Synchronous and must succeed for the rest to make sense.
/// 2. **storage** — Hive boxes, secure-storage API key, trace storage,
///    profile migration, cache eviction. A failure here means the device
///    can't write local data; we surface it but still attempt to keep
///    going so the user isn't stuck on a black screen. The secure-storage
///    API-key read and `TraceStorage.init()` run in parallel (#795).
/// 3. **services** — notifications, background tasks, home widget;
///    independent of each other → parallelised with `Future.wait`.
/// 4. **optional (deferred)** — community config + TankSync, plus
///    one-shot migrations (vehicle reference-catalog backfill #950, the
///    feature-flag legacy-toggle promoter #1373). All scheduled for a
///    post-first-frame microtask so the app paints before Supabase is
///    touched (#795) and before any Hive walks run. Failures are logged
///    but never block startup. #1794/#1768 belong here too: cache
///    eviction (#2264, yield counted by #3610), the #2317 price-history
///    30-day retention trim (the foreground record path never trims —
///    without the cold-start hook a heavy user accumulates ~175k dead
///    rows/year; reads already filter to 30 days, so this caps storage
///    growth, not a correctness bug) and the profile migrations.
/// 5. **runApp** — wires global error handlers and hands control to the
///    framework; Sentry initialises post-first-frame when configured.
///
/// ## Phase objects (#3139)
///
/// The bulky deferred work is decomposed into ordered phase objects under
/// `lib/app/startup/` — [LaunchSyncPhase] (launch-time server→local
/// merges), [TripRecoveryPhase] (paused-then-active trip crash recovery),
/// [ProviderWarmupPhase] (one-shot migrations + keep-alive provider
/// kick-offs) and [TelemetryReplayPhase] (background-isolate error-spool
/// drain). [AppInitializer] stays the single ordering authority: every
/// phase documents its slot, and the pre-Zone / post-bind /
/// post-first-frame placement lives only in this library.

// ---------------------------------------------------------------------------
// Deferred launch sync (TankSync + pulls)
// ---------------------------------------------------------------------------

/// Body of the `run()` launch-sync deferral (#795 phase 1). The caller
/// keeps `CommunityConfig.load()` + the [initTankSync] tear-off
/// (`AppInitializer._maybeInitTankSync`) at the pinned call site.
Future<void> _runDeferredLaunchSync(
  ProviderContainer container,
  HiveStorage storage, {
  required Future<void> Function(HiveStorage storage) initTankSync,
}) async {
  // #3445 — span the otherwise-invisible launch-sync phase when the
  // Feature.startupTrace devtool is on (null = zero overhead).
  final trace = LaunchSyncPhase.armTrace(container);
  // #3447 — install the pull matrix + app-resume trigger BEFORE the
  // init so a "sync now" tap can never observe an empty registry.
  LaunchSyncPhase.registerPulls(container, storage);
  LaunchSyncPhase.wireResumeSync(container);
  await LaunchSyncTrace.spanned(
      trace, 'tanksync_init', () => initTankSync(storage));
  // #3449 relink surface + #3450 background init-retry ladder.
  LaunchSyncPhase.handleInitOutcome(container, storage);
  // #3126 — one run id threads the launch merges into the trace.
  if (TankSyncClient.client != null) SyncRunTrace.begin('launch');
  // #3447/#3450 — every synced table pulls in parallel; each entry is
  // consent-gated + time-boxed and no-ops when sync is off (see
  // LaunchSyncPhase / LaunchSyncPulls).
  await LaunchSyncPhase.runLaunchPulls(container, trace: trace);
  trace?.finish();
}

// ---------------------------------------------------------------------------
// Grouped post-first-frame registrations (order preserved)
// ---------------------------------------------------------------------------

/// The four post-frame registrations `run()` schedules after the
/// legacy-toggle kick-off, in the exact original order: #3580 crash
/// forensics, then the #1858 / #1925 / #2465 provider warm-ups.
void _schedulePostFrameWarmups(ProviderContainer container) {
  // #3580 — crash forensics: restore the previous run's persisted
  // breadcrumbs, start mirroring this run's ring to disk, then drain
  // the native crash journal + ApplicationExitInfo so every abnormal
  // process death (native crash / ANR / OOM kill — the "recording
  // crashed with no traces" class) lands in the on-device error log
  // with the context of what the app was doing when it died.
  AppInitializer._deferPostFirstFrame(() async {
    try {
      final supportDir = await getApplicationSupportDirectory();
      await BreadcrumbPersistence.init(supportDir.path);
      await CrashForensicsHarvester.harvestAndLog();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.background, e, st,
          context: const {'where': 'crash forensics startup (#3580)'}));
    }
  });

  // #1858 — warm the keep-alive η_v recompute listener so it watches
  // vehicle-profile edits before the user can reach the Edit-vehicle
  // screen (see ProviderWarmupPhase).
  AppInitializer._deferPostFirstFrame(
      () => ProviderWarmupPhase.warmTripVeRecomputeListener(container));

  // #1925 — arm the OBD2 debug-session recorder from the persisted
  // opt-in flag (see ProviderWarmupPhase).
  AppInitializer._deferPostFirstFrame(
      () => ProviderWarmupPhase.armObd2DebugSessionLogging(container));

  // #2465 — arm the OBD2 comm-health diagnostics collector from
  // Feature.debugMode (see ProviderWarmupPhase).
  AppInitializer._deferPostFirstFrame(
      () => ProviderWarmupPhase.armObd2CommDiagnosticsGate(container));
}

/// The `_launch`-time schedule block, in the exact original order:
/// heartbeat, paused-trip recovery, active-trip recovery, auto-record
/// orchestrator, aggregator hook, isolate-spool drain.
void _scheduleLaunchDeferredPhases(ProviderContainer container) {
  // #609 — kick the 2-minute nearest-widget heartbeat so the home-screen
  // widget stays fresh while the app is running (see ProviderWarmupPhase).
  ProviderWarmupPhase.startNearestWidgetHeartbeat(container);

  // #1004 phase 4-WAL — finalise paused trips that survived an app
  // kill mid-grace-window. Sequenced BEFORE the active recovery AND
  // the orchestrator start below so the user lands on a history list
  // with the recovered trip already populated (see TripRecoveryPhase).
  AppInitializer._deferPostFirstFrame(
      () => TripRecoveryPhase.recoverPausedTrips(container));

  // #1303 — recover an in-progress trip whose process was killed
  // before it could finalise. Sequenced AFTER the paused-trip recovery
  // so a stale paused row from the same drive lands in history before
  // the active recovery re-enters the recording UI
  // (see TripRecoveryPhase).
  AppInitializer._deferPostFirstFrame(
      () => TripRecoveryPhase.recoverActiveTrip(container));

  // #1004 phase 2b-2 — start the auto-record orchestrator, with the
  // #3167 iOS Core Bluetooth state-restoration opt-in sequenced first
  // inside the same deferred block (see ProviderWarmupPhase).
  AppInitializer._deferPostFirstFrame(
      () => ProviderWarmupPhase.startAutoRecordOrchestrator(container));

  // #1193 phase 2 — wire the vehicle aggregator's `runForVehicle` hook
  // onto `TripHistoryRepository.onSavedHook` (see ProviderWarmupPhase).
  AppInitializer._deferPostFirstFrame(
      () => ProviderWarmupPhase.wireVehicleAggregatorHook(container));

  // #1105 — drain the background-isolate error spool through the
  // foreground TraceRecorder (see TelemetryReplayPhase).
  AppInitializer._deferPostFirstFrame(
      () => TelemetryReplayPhase.drainIsolateErrorSpool(container));
}
