// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:hive/hive.dart';

import '../../../../core/logging/error_logger.dart';
import '../../../../core/storage/hive_boxes.dart';
import '../trip_history_repository.dart';
import 'dropped_session_host.dart';
import 'paused_trip_repository.dart';

/// #2565 — resolves the paused-trips + trip-history Hive repositories the
/// [DroppedSessionManager] persists into, extracted into a tiny
/// collaborator so the manager stays under the 400-line file-length cap.
///
/// Production passes no overrides and both repos are resolved lazily from
/// the open Hive box on use (a closed box → null, which the manager
/// treats as "skip persistence"). Unit tests inject in-memory repos so
/// the persistence branches are exercised without Hive.
class DroppedSessionRepoResolver {
  DroppedSessionRepoResolver({
    PausedTripRepository? pausedOverride,
    TripHistoryRepository? historyOverride,
  })  : _pausedOverride = pausedOverride,
        _historyOverride = historyOverride;

  final PausedTripRepository? _pausedOverride;
  final TripHistoryRepository? _historyOverride;

  PausedTripRepository? resolvePaused() {
    final override = _pausedOverride;
    if (override != null) return override;
    if (!Hive.isBoxOpen(HiveBoxes.obd2PausedTrips)) return null;
    try {
      return PausedTripRepository(
          box: Hive.box<String>(HiveBoxes.obd2PausedTrips));
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: const {'where': 'DroppedSessionManager paused repo'}));
      return null;
    }
  }

  TripHistoryRepository? resolveHistory() {
    final override = _historyOverride;
    if (override != null) return override;
    if (!Hive.isBoxOpen(TripHistoryRepository.boxName)) return null;
    try {
      return TripHistoryRepository(
        box: Hive.box<String>(TripHistoryRepository.boxName),
      );
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: const {'where': 'DroppedSessionManager history repo'}));
      return null;
    }
  }

  /// Persist the in-progress trip snapshot to the paused-trips box on drop
  /// (#797 phase 1). Fire-and-forget; Hive errors are logged by the repo
  /// and must not throw back into the scheduler callback.
  void savePausedSnapshot(DroppedSessionHost host, {required DateTime at}) {
    final repo = resolvePaused();
    final id = host.sessionId;
    if (repo == null || id == null) return;
    repo.save(PausedTripEntry(
      id: id,
      vehicleId: host.vehicleId,
      vin: host.vin,
      summary: host.buildInProgressSummary(),
      odometerStartKm: host.odometerStartKm,
      odometerLatestKm: host.odometerLatestKm,
      pausedAt: at,
      // #1004 phase 4-WAL — flag persists so the launch-time recovery
      // service knows whether to bump the launcher-icon badge if the app
      // is killed before the grace timer fires.
      automatic: host.automatic,
    ));
  }

  /// Delete this session's paused-trips row — best-effort, no-op when
  /// the session has no id.
  void deletePausedRow(String? sessionId) {
    if (sessionId == null) return;
    resolvePaused()?.delete(sessionId);
  }

  /// Grace-window finalisation persistence (#797): write the partial into
  /// trip-history (with the still-live buffer + GPS diagnostics + the
  /// automatic flag, #2291) and delete the paused row. The lifecycle flag
  /// flips + emit stay on the manager.
  Future<void> finaliseToHistory(DroppedSessionHost host) async {
    final id = host.sessionId;
    final historyRepo = resolveHistory();
    if (historyRepo != null && id != null) {
      try {
        await historyRepo.save(TripHistoryEntry(
          id: id,
          vehicleId: host.vehicleId,
          summary: host.buildFinalSummary(),
          samples: host.capturedSamples,
          gpsSampleDiagnostics: host.capturedGpsSampleDiagnostics,
          automatic: host.automatic,
        ));
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.storage, e, st,
            context: const {'where': 'DroppedSessionManager grace finalise'}));
      }
    }
    deletePausedRow(id);
  }
}
