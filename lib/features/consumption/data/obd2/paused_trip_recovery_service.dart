import 'package:flutter/foundation.dart';

import '../trip_history_repository.dart';
import 'paused_trip_repository.dart';

/// Launch-time recovery for paused-but-never-finalised trips
/// (#1004 phase 4-WAL).
///
/// ## Why
///
/// Phase 4 of the auto-record epic shipped the disconnect-save timer:
/// when the BLE adapter drops mid-trip, [TripRecordingController]
/// writes a [PausedTripEntry] to the `obd2_paused_trips` Hive box and
/// arms a 60 s in-memory timer that auto-finalises the trip into
/// history. The gap closed here: if the OS kills the app inside that
/// 60 s window — Android process pressure, user force-stop, sudden
/// reboot — the in-memory timer is gone and the paused row sits in
/// Hive forever. The user "drove a trip that never appears in the
/// history list."
///
/// This service walks the paused-trips box on every cold start. Any
/// entry whose `pausedAt` is older than [recoverStale]'s `olderThan`
/// threshold is finalised into the trip-history rolling log and
/// dropped from the paused box. The threshold defaults to 5 minutes —
/// long enough that a transient kill (Doze entering, OS reclaiming
/// memory) doesn't race a still-mounted controller, short enough that
/// the user sees yesterday's interrupted trip on next launch instead
/// of next week.
///
/// ## Why a callback for badge bumping
///
/// The recovery service depends on the consumption layer (paused-
/// trips repo, history repo) but the launcher-icon badge lives in
/// `core/feedback/`. Reaching across that boundary inside this file
/// would couple data-layer recovery to UI feedback. Instead we accept
/// an [onAutomaticRecovered] callback the wiring layer fills in with
/// `ref.read(autoRecordBadgeServiceProvider.future).then(b => b.increment)`.
/// Manual paused trips never carried badge-counter weight in the
/// first place, so the callback is gated on `entry.automatic`.
///
/// ## Errors
///
/// Each entry is processed inside its own try/catch — one corrupt
/// row or one failing repo write must not block the recovery of the
/// rest. Failures are logged via [debugPrint] (matching the existing
/// repo error policy) so a debug build still surfaces them without
/// crashing the launch path.
class PausedTripRecoveryService {
  final PausedTripRepository _pausedRepo;
  final TripHistoryRepository _historyRepo;
  final Future<void> Function()? _onAutomaticRecovered;
  final DateTime Function() _now;

  /// Construct the recovery service.
  ///
  /// [pausedRepo] reads & deletes paused-trip rows.
  /// [historyRepo] persists the finalised [TripHistoryEntry].
  /// [onAutomaticRecovered] is invoked once per recovered entry whose
  /// `automatic` flag is true. Pass null to skip the badge bump
  /// entirely (tests, manual-only deployments).
  /// [now] overrides the wall-clock for tests.
  PausedTripRecoveryService({
    required PausedTripRepository pausedRepo,
    required TripHistoryRepository historyRepo,
    Future<void> Function()? onAutomaticRecovered,
    DateTime Function()? now,
  })  : _pausedRepo = pausedRepo,
        _historyRepo = historyRepo,
        _onAutomaticRecovered = onAutomaticRecovered,
        _now = now ?? DateTime.now;

  /// Walk the paused-trips box, finalise stale entries into history,
  /// and return the count of recovered entries.
  ///
  /// An entry is "stale" when `now - entry.pausedAt > olderThan`.
  /// 5 minutes is the default — generous enough to avoid racing a
  /// just-mounted controller whose grace timer is still ticking, tight
  /// enough that the user sees the trip on next launch.
  ///
  /// Each recovery step is independently fenced; one bad row never
  /// blocks the rest. [PausedTripEntry.automatic] entries trigger
  /// [onAutomaticRecovered] (if wired) so the launcher-icon badge
  /// stays consistent with phase 5's "unseen trip" semantics.
  Future<int> recoverStale({
    Duration olderThan = const Duration(minutes: 5),
  }) async {
    final List<PausedTripEntry> entries;
    try {
      entries = _pausedRepo.loadAll();
    } catch (e, st) {
      debugPrint('PausedTripRecoveryService loadAll failed: $e\n$st');
      return 0;
    }
    if (entries.isEmpty) return 0;

    final now = _now();
    var recovered = 0;
    for (final entry in entries) {
      try {
        if (now.difference(entry.pausedAt) <= olderThan) continue;
        final historyEntry = TripHistoryEntry(
          id: entry.id,
          vehicleId: entry.vehicleId,
          summary: entry.summary,
          automatic: entry.automatic,
          // Samples are NOT persisted in PausedTripEntry today (the
          // pause-write happens on a transport-error callback and we
          // don't want to serialise the captured-samples buffer on
          // every drop). Recovered trips therefore land with an empty
          // samples list; the trip-detail charts fall back to the
          // shared "No samples recorded" caption — the honest answer
          // for a trip whose buffer never reached disk.
          samples: const [],
        );
        await _historyRepo.save(historyEntry);
        final cb = _onAutomaticRecovered;
        if (entry.automatic && cb != null) {
          await cb();
        }
        await _pausedRepo.delete(entry.id);
        recovered++;
      } catch (e, st) {
        debugPrint(
          'PausedTripRecoveryService recover ${entry.id} failed: $e\n$st',
        );
      }
    }
    return recovered;
  }
}
