import 'package:flutter/foundation.dart';

import '../trip_history_repository.dart';
import 'active_trip_repository.dart';

/// Outcome of [ActiveTripRecoveryService.recover].
///
/// Drives the wiring layer's response on cold start:
///  - [none]: nothing on disk, business as usual.
///  - [recovered]: a non-stale snapshot was rehydrated and
///    [ActiveTripRecoveryService.recoveredSnapshot] is non-null.
///    The wiring layer routes the user into the trip-recording
///    screen and the provider takes ownership of the snapshot.
///  - [discarded]: a stale snapshot was found and dropped from
///    the box. The user gets the unseen-trip badge bumped (if the
///    crashed session was hands-free auto-record) and a debug log,
///    but no on-screen recovery prompt.
///  - [failed]: the snapshot existed but couldn't be parsed or
///    finalised. We swallow and log so the launch path keeps going.
enum ActiveTripRecoveryOutcome { none, recovered, discarded, failed }

/// Launch-time recovery for in-progress trip snapshots that survived
/// a process death (#1303).
///
/// ## Why
///
/// `TripRecording` (Riverpod, keepAlive) holds the controller and the
/// captured-samples buffer in memory. Android happily kills a
/// backgrounded app under memory pressure; on resume the provider
/// rebuilds from scratch, the controller is null, and the user's
/// in-progress trip is gone.
///
/// `ActiveTripRepository` writes a debounced snapshot to Hive every
/// few seconds while the trip is live. This service runs at cold
/// start (after Hive boxes are open, before the first frame), reads
/// any pending snapshot, and decides what to do with it:
///
///  - **Fresh** (lastFlushedAt within [staleAfter], default 24 h):
///    the snapshot is exposed via [recoveredSnapshot] for the
///    wiring layer to hand to the `TripRecording` provider, which
///    rehydrates the controller in `pausedDueToDrop` so the user
///    can manually resume. We never auto-reconnect OBD2 here —
///    the existing reconnect-scanner owns that schedule.
///
///  - **Stale** (older than [staleAfter]): assume the user gave up.
///    Drop the snapshot. If the crashed session was an auto-record
///    one, fire [onAutomaticRecovered] so the unseen-trip badge
///    still increments (consistent with the paused-trip recovery
///    path).
///
/// ## Errors
///
/// Every step is fenced inside try/catch. A corrupt row, a Hive
/// write failure, or a thrown badge callback must NOT prevent the
/// app from launching. Failures route through [debugPrint] (matches
/// the existing repo error policy) and the outcome reports
/// [ActiveTripRecoveryOutcome.failed].
class ActiveTripRecoveryService {
  final ActiveTripRepository _activeRepo;

  /// Optional history repo. Reserved for a future iteration where a
  /// stale snapshot could be finalised into history (current rule:
  /// just discard) — kept in the constructor so we don't have to
  /// thread it through later. Today it's unused on the recovery
  /// path; we keep the surface so callers (AppInitializer) don't
  /// have to refactor when the rule changes.
  // ignore: unused_field
  final TripHistoryRepository? _historyRepo;

  final Future<void> Function()? _onAutomaticRecovered;
  final DateTime Function() _now;

  /// Stale threshold. Defaults to 24 h: long enough that a person
  /// who left the app overnight still gets their morning trip back,
  /// short enough that an abandoned snapshot from last week doesn't
  /// suddenly resurrect itself.
  final Duration staleAfter;

  ActiveTripSnapshot? _recoveredSnapshot;

  ActiveTripRecoveryService({
    required ActiveTripRepository activeRepo,
    TripHistoryRepository? historyRepo,
    Future<void> Function()? onAutomaticRecovered,
    DateTime Function()? now,
    this.staleAfter = const Duration(hours: 24),
  })  : _activeRepo = activeRepo,
        _historyRepo = historyRepo,
        _onAutomaticRecovered = onAutomaticRecovered,
        _now = now ?? DateTime.now;

  /// Snapshot that the wiring layer should rehydrate into the
  /// `TripRecording` provider. Non-null only after [recover]
  /// returns [ActiveTripRecoveryOutcome.recovered].
  ActiveTripSnapshot? get recoveredSnapshot => _recoveredSnapshot;

  /// Run the recovery walk. Idempotent — calling twice in the same
  /// process returns the cached outcome on the second call only if
  /// the underlying box still holds the same row.
  Future<ActiveTripRecoveryOutcome> recover() async {
    final ActiveTripSnapshot? snapshot;
    try {
      snapshot = _activeRepo.loadSnapshot();
    } catch (e, st) {
      debugPrint('ActiveTripRecoveryService loadSnapshot failed: $e\n$st');
      return ActiveTripRecoveryOutcome.failed;
    }
    if (snapshot == null) {
      return ActiveTripRecoveryOutcome.none;
    }

    final now = _now();
    final stale = ActiveTripRepository.isStale(
      snapshot,
      now: now,
      olderThan: staleAfter,
    );

    if (stale) {
      try {
        await _activeRepo.clearSnapshot();
      } catch (e, st) {
        debugPrint('ActiveTripRecoveryService clear stale failed: $e\n$st');
        return ActiveTripRecoveryOutcome.failed;
      }
      // Stale auto-record snapshots still bump the unseen badge —
      // mirrors the paused-trip recovery semantics so the user sees
      // "your auto-trip didn't make it" instead of silent data loss.
      final cb = _onAutomaticRecovered;
      if (snapshot.automatic && cb != null) {
        try {
          await cb();
        } catch (e, st) {
          debugPrint(
              'ActiveTripRecoveryService stale badge bump failed: $e\n$st');
        }
      }
      debugPrint(
        'ActiveTripRecoveryService: discarded stale snapshot id=${snapshot.id} '
        'lastFlushedAt=${snapshot.lastFlushedAt.toIso8601String()}',
      );
      return ActiveTripRecoveryOutcome.discarded;
    }

    _recoveredSnapshot = snapshot;
    return ActiveTripRecoveryOutcome.recovered;
  }
}
