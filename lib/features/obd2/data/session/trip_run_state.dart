// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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

  /// True while samples should be flowing: started and not truly paused,
  /// or degraded onto GPS.
  bool get isRecording =>
      (_started && !_paused && !_pausedDueToDrop) || _degradedGpsOnly;

  /// True for both the user pause and the drop pause.
  bool get isPaused => _paused || _pausedDueToDrop;

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
  void setStopped(bool value) => _stopped = value;
  void setStarted(bool value) => _started = value;
}
