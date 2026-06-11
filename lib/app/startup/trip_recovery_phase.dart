// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/feedback/auto_record_badge_provider.dart';
import '../../core/logging/app_log.dart';
import '../../core/logging/error_logger.dart';
import '../../core/storage/hive_boxes.dart';
import '../../features/obd2/data/active_trip_recovery_service.dart';
import '../../features/obd2/data/active_trip_repository.dart';
import '../../features/obd2/data/paused_trip_recovery_service.dart';
import '../../features/obd2/data/paused_trip_repository.dart';
import '../../features/consumption/data/trip_history_repository.dart';
import '../../features/consumption/providers/trip_recording_provider.dart';
import '../../core/navigation/app_routes.dart';
import '../router.dart';

/// Trip crash-recovery passes — extracted from `AppInitializer._launch`
/// by the #3139 phase decomposition.
///
/// ## Ordering contract (#3139)
///
/// `AppInitializer._launch` schedules both passes post-first-frame,
/// AFTER `errorLogger.bind(container)` + the global handler install (so
/// every recovery fault reaches the trace pipeline), and in this fixed
/// order:
///
/// 1. [recoverPausedTrips] (#1004 phase 4-WAL) — finalise paused trips
///    that survived an app kill mid-grace-window into the trip-history
///    rolling log. Sequenced BEFORE the active recovery AND before the
///    auto-record orchestrator start so the user lands on a history list
///    with the recovered trip already populated.
/// 2. [recoverActiveTrip] (#1303) — rehydrate an in-progress trip
///    snapshot that survived a process death. Sequenced AFTER the
///    paused-trip recovery so a stale paused row from the same drive
///    lands in history before the active recovery re-enters the
///    recording UI.
///
/// Failures are caught + logged per pass; recovery must never block or
/// crash the launch.
class TripRecoveryPhase {
  TripRecoveryPhase._();

  /// #1004 phase 4-WAL — finalise paused trips that survived an app
  /// kill mid-grace-window into the trip-history rolling log.
  ///
  /// Resolves the paused-trips + history Hive boxes (no-op when either
  /// is closed — widget tests, fresh installs), wires the badge bump
  /// from [autoRecordBadgeServiceProvider] only for entries flagged as
  /// auto-record, and calls [PausedTripRecoveryService.recoverStale]
  /// with the default 5-minute threshold.
  static Future<void> recoverPausedTrips(ProviderContainer container) async {
    try {
      await _runPausedTripRecovery(container);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.background, e, st,
          context: {'where': 'pausedTripRecovery'}));
    }
  }

  /// #1303 — recover an in-progress trip whose process was killed
  /// before it could finalise. Walks the active-trip Hive box, hands a
  /// non-stale snapshot back to the `TripRecording` provider, bumps the
  /// unseen-trip badge for auto-record sessions, and navigates to
  /// `/trip-recording`.
  static Future<void> recoverActiveTrip(ProviderContainer container) async {
    try {
      await _runActiveTripRecovery(container);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.background, e, st,
          context: {'where': 'activeTripRecovery'}));
    }
  }

  /// #1303 — recover an in-progress trip snapshot that survived a
  /// process death. Walks the active-trip Hive box; if a fresh
  /// snapshot is on disk (within the 24 h staleness window) the
  /// `TripRecording` provider is rehydrated into a
  /// `pausedDueToDrop`-shaped state with the captured samples
  /// preserved, the launcher-icon badge is bumped (auto-record
  /// trips only), and the user is navigated to `/trip-recording`.
  ///
  /// Stale snapshots are dropped quietly — the user gave up; we
  /// don't surface a stale recovery prompt that would confuse them
  /// on a fresh launch.
  ///
  /// No-ops cleanly when the active-trip box isn't open.
  static Future<void> _runActiveTripRecovery(
    ProviderContainer container,
  ) async {
    // #1794 — the active-trip + trip-history boxes are deferred; wait
    // for the post-first-frame opens before reading them.
    await HiveBoxes.initDeferred();
    if (!Hive.isBoxOpen(HiveBoxes.obd2ActiveTrip)) return;
    final activeRepo = ActiveTripRepository(
      box: Hive.box<String>(HiveBoxes.obd2ActiveTrip),
    );
    TripHistoryRepository? historyRepo;
    if (Hive.isBoxOpen(HiveBoxes.obd2TripHistory)) {
      historyRepo = TripHistoryRepository(
        box: Hive.box<String>(HiveBoxes.obd2TripHistory),
      );
    }
    final service = ActiveTripRecoveryService(
      activeRepo: activeRepo,
      historyRepo: historyRepo,
      onAutomaticRecovered: () async {
        try {
          final badge =
              await container.read(autoRecordBadgeServiceProvider.future);
          await badge.increment();
        } catch (e, st) {
          unawaited(errorLogger.log(ErrorLayer.background, e, st,
              context: {'where': 'activeTripRecovery badge bump'}));
        }
      },
    );
    final outcome = await service.recover();
    switch (outcome) {
      case ActiveTripRecoveryOutcome.none:
      case ActiveTripRecoveryOutcome.failed:
      case ActiveTripRecoveryOutcome.discarded:
        return;
      case ActiveTripRecoveryOutcome.recovered:
        final snapshot = service.recoveredSnapshot;
        if (snapshot == null) return;
        try {
          final notifier = container.read(tripRecordingProvider.notifier);
          final applied = notifier.restoreFromSnapshot(snapshot);
          if (!applied) return;
          // Bump the unseen-trip badge for auto-record sessions —
          // the user should see "your auto-trip didn't fully save"
          // in the launcher even if they don't tap the recording
          // banner. Mirrors the paused-trip recovery semantics.
          if (snapshot.automatic) {
            try {
              final badge = await container
                  .read(autoRecordBadgeServiceProvider.future);
              await badge.increment();
            } catch (e, st) {
              unawaited(errorLogger.log(ErrorLayer.background, e, st, context: {
                'where': 'activeTripRecovery recovered badge bump'
              }));
            }
          }
          // Auto-navigate to /trip-recording on the next frame so
          // the user lands directly on the live recording UI. We
          // re-enter post-frame because the GoRouter redirect chain
          // (consent → setup → landing) has to settle before we
          // can push a new route — a synchronous push from inside
          // the recovery callback would race against the redirect
          // logic and lose.
          SchedulerBinding.instance.addPostFrameCallback((_) {
            try {
              final goRouter = container.read(routerProvider);
              goRouter.go(RoutePaths.tripRecording);
            } catch (e, st) {
              unawaited(errorLogger.log(ErrorLayer.background, e, st, context: {
                'where': 'activeTripRecovery go(/trip-recording)'
              }));
            }
          });
        } catch (e, st) {
          unawaited(errorLogger.log(ErrorLayer.background, e, st, context: {
            'where': 'activeTripRecovery restoreFromSnapshot'
          }));
        }
    }
  }

  /// #1004 phase 4-WAL — finalise paused trips that survived an app
  /// kill mid-grace-window into the trip-history rolling log.
  ///
  /// The recovered count is logged at info level; production builds
  /// carry it into the leveled log facade.
  static Future<void> _runPausedTripRecovery(
    ProviderContainer container,
  ) async {
    // #1794 — the paused-trip + trip-history boxes are deferred; wait
    // for the post-first-frame opens before reading them.
    await HiveBoxes.initDeferred();
    if (!Hive.isBoxOpen(HiveBoxes.obd2PausedTrips)) return;
    if (!Hive.isBoxOpen(HiveBoxes.obd2TripHistory)) return;
    final pausedRepo = PausedTripRepository(
      box: Hive.box<String>(HiveBoxes.obd2PausedTrips),
    );
    final historyRepo = TripHistoryRepository(
      box: Hive.box<String>(HiveBoxes.obd2TripHistory),
    );
    final service = PausedTripRecoveryService(
      pausedRepo: pausedRepo,
      historyRepo: historyRepo,
      onAutomaticRecovered: () async {
        try {
          final badge =
              await container.read(autoRecordBadgeServiceProvider.future);
          await badge.increment();
        } catch (e, st) {
          unawaited(errorLogger.log(ErrorLayer.background, e, st,
              context: {'where': 'pausedTripRecovery badge bump'}));
        }
      },
    );
    final recovered = await service.recoverStale();
    if (recovered > 0) {
      log.info(
          'AppInitializer: recovered $recovered paused trip(s) into history');
    }
  }
}
