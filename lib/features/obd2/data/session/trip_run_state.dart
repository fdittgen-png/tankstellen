// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The states a recording can actually be IN (#4162, epic #4155).
///
/// [TripRunState] carries five booleans, which describes **32
/// combinations**. Eight are reachable — see
/// `trip_run_state_reachability_test`, which walks every real transition
/// (with its caller's guard) from `idle` — and every one of them maps to
/// one of these six.
///
/// This enum is DERIVED from the flags rather than replacing them: #4034
/// already made the transitions atomic, and a storage change here would
/// be a behaviour change in the app's highest-risk subsystem.
///
/// The precedence of [tripRunPhaseOf] is the one the recording UI has
/// always shown (`TripRecordingController.currentState`), and it is not
/// arbitrary:
///
/// * [finished] first — an auto-finalised drop leaves `stopped` true with
///   `started` false;
/// * the two pauses BEFORE [degradedGpsOnly] — a user pause taken while
///   degraded is reachable, and the emit loop does not sample during it,
///   so calling it "recording" would be the lie. Until #4162 this enum
///   ranked degraded above the pauses and disagreed with the UI on
///   exactly that reachable state.
enum TripRunPhase {
  /// Never begun. The only state with nothing set.
  idle,

  /// Begun and sampling.
  running,

  /// The user paused. Resumable by the user.
  pausedByUser,

  /// The link dropped AND GPS is gone too. Resumable by the link
  /// returning, or finalised by the grace timer.
  pausedByDrop,

  /// #2565 — the link died and recording continues on GPS alone. An
  /// ACTIVE state, not a pause.
  degradedGpsOnly,

  /// Ended. `stopped` is true and `started` is false.
  finished,
}

/// The phase five flags describe — total over all 32 combinations, so a
/// reader can never be handed a combination it cannot name (#4162).
TripRunPhase tripRunPhaseOf({
  required bool started,
  required bool stopped,
  required bool paused,
  required bool pausedDueToDrop,
  required bool degradedGpsOnly,
}) {
  if (stopped) return TripRunPhase.finished;
  if (!started) return TripRunPhase.idle;
  if (pausedDueToDrop) return TripRunPhase.pausedByDrop;
  if (paused) return TripRunPhase.pausedByUser;
  if (degradedGpsOnly) return TripRunPhase.degradedGpsOnly;
  return TripRunPhase.running;
}

/// The five flags that say what a recording is doing, owned by
/// [TripRecordingController] instead of shared across its `part` files
/// (#4034, epic #4032).
///
/// `_started`, `_stopped`, `_paused`, `_pausedDueToDrop` and
/// `_degradedGpsOnly` used to be bare booleans in the controller's
/// private scope, written from the lifecycle part AND from the drop-host
/// adapter the [DroppedSessionManager] drives. Nothing tied them
/// together, so a transition that forgot one of them left the state
/// machine describing a situation that could not happen — which is the
/// shape of the recurring OBD2 defects (the PARK/REUSE state trap #3574,
/// the ready-with-corpse deadlock #3775).
///
/// They live here now, and every compound transition — begin, end,
/// resume-from-drop — sets its whole group in one method, so a caller
/// cannot perform half of one.
class TripRunState {
  bool _started = false;
  bool _stopped = false;
  bool _paused = false;
  bool _pausedDueToDrop = false;
  bool _degradedGpsOnly = false;

  bool get started => _started;
  bool get stopped => _stopped;
  bool get paused => _paused;
  bool get pausedDueToDrop => _pausedDueToDrop;

  /// #2565 — recording continues on GPS alone after the link died. An
  /// ACTIVE state, not a pause: it is checked after the true-pause
  /// states, and it becomes [pausedDueToDrop] when GPS also dies.
  bool get degradedGpsOnly => _degradedGpsOnly;

  /// True while samples should be flowing: running, or degraded onto GPS
  /// (#4162 — read off [phase], so a user pause taken while degraded is
  /// not "recording"; nothing in production reads this getter).
  bool get isRecording =>
      phase == TripRunPhase.running || phase == TripRunPhase.degradedGpsOnly;

  /// True for both the user pause and the drop pause.
  bool get isPaused => _paused || _pausedDueToDrop;

  /// Which of the six named states this is (#4162) — see [tripRunPhaseOf]
  /// for the precedence and why.
  TripRunPhase get phase => tripRunPhaseOf(
        started: _started,
        stopped: _stopped,
        paused: _paused,
        pausedDueToDrop: _pausedDueToDrop,
        degradedGpsOnly: _degradedGpsOnly,
      );

  /// The trip has begun. `stopped` is cleared in the same step so a
  /// restart can never be seen as "stopped and started at once".
  void begin() {
    _started = true;
    _stopped = false;
  }

  /// The trip has ended. Clears the drop pause and the #2565 degrade in
  /// the same step, so a stop while degraded finalises cleanly (the
  /// drop-window GPS samples persist in the mixed trip).
  ///
  /// An auto-finalised drop leaves both `stopped` true and `started`
  /// false, which is why a state read must check `stopped` FIRST.
  void end() {
    _started = false;
    _stopped = true;
    _pausedDueToDrop = false;
    _degradedGpsOnly = false;
    // #4068 — a user pause must not outlive the trip: `isPaused` reads
    // this flag, and a paused trip that grace-finalised reported
    // "stopped AND paused" to the tile and the notification.
    _paused = false;
  }

  /// #4344 — awaits [step], one of the start's reads, and answers whether
  /// the trip is still alive after it. A stop that landed meanwhile ended
  /// it synchronously, so the start must create nothing more: no poll loop,
  /// no emit timer. A stopped trip never begins again, which makes the
  /// answer final for a start that was already under way.
  Future<bool> alive(Future<Object?> step) async {
    await step;
    return !_stopped;
  }

  /// The user paused. No-op unless the trip is running and not already
  /// paused either way — returns whether the pause actually happened.
  bool pauseByUser() {
    if (!_started) return false;
    if (_paused || _pausedDueToDrop) return false;
    _paused = true;
    return true;
  }

  /// Clear the drop pause (the link came back, or the user resumed).
  void clearDropPause() => _pausedDueToDrop = false;

  /// Clear the user pause.
  void clearUserPause() => _paused = false;

  // Driven by the [DroppedSessionManager] through the controller's
  // drop-host adapter, whose setter-shaped contract predates this class.
  // They are methods rather than setters so the field they write stays
  // private and every writer is greppable.
  void setPausedDueToDrop(bool value) => _pausedDueToDrop = value;
  void setDegradedGpsOnly(bool value) => _degradedGpsOnly = value;
}
