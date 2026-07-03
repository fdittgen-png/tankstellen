// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #3459 — idle-reconnect FLAP latch.
///
/// Field evidence (2026-07-03 export, build 2026061861): with the car
/// parked, the idle loop reconnected every ~9 s for minutes — each connect
/// completed the ELM init from the adapter's standby power, the session
/// died seconds later (PID reads silent), and the SUCCESS reset the
/// backoff, so the episode never converged to `terminalEngineOff`. The
/// wedge detector is blind to this: it counts consecutive *failed* ladders,
/// and every one of these connects "succeeded".
///
/// The latch counts consecutive SHORT-LIVED sessions (connect→drop faster
/// than [shortSession]). [strikes] of them in a row latch `flapping`; while
/// latched the idle policy must not dial. The latch clears on:
///  * a session that survives at least [shortSession] (organic recovery —
///    the engine is genuinely on), or
///  * [clear] — an explicit user action (retry tap / interactive connect).
///
/// A flapping SUCCESS never clears the latch by itself: only session
/// LIFETIME proves the link is real.
class Obd2FlapLatch {
  Obd2FlapLatch({
    this.shortSession = const Duration(seconds: 30),
    this.strikes = 3,
  });

  /// Sessions shorter than this count as a flap strike.
  final Duration shortSession;

  /// Consecutive short sessions that latch the stand-down.
  final int strikes;

  DateTime? _connectedAt;
  int _shortCount = 0;
  bool _latched = false;

  /// Whether the idle policy must stand down (no automatic dials).
  bool get flapping => _latched;

  /// Consecutive short-session count (diagnostics / tests).
  int get shortSessionCount => _shortCount;

  /// A session opened (successful connect). Never clears the latch —
  /// flapping successes are the symptom, not the recovery.
  void noteConnected(DateTime now) {
    _connectedAt = now;
  }

  /// The session dropped. Returns true when this drop LATCHED the
  /// stand-down (so the caller can trace the transition exactly once).
  bool noteDropped(DateTime now) {
    final openedAt = _connectedAt;
    _connectedAt = null;
    if (openedAt == null) {
      // A drop without a tracked session (drop during connect, or the
      // latch was constructed mid-episode): neutral — neither a strike
      // nor a recovery.
      return false;
    }
    final lived = now.difference(openedAt);
    if (lived >= shortSession) {
      // The link held long enough to be real — organic recovery.
      _shortCount = 0;
      _latched = false;
      return false;
    }
    _shortCount++;
    if (!_latched && _shortCount >= strikes) {
      _latched = true;
      return true;
    }
    return false;
  }

  /// Explicit user action (retry tap / interactive connect) — the user
  /// asserted the link is worth dialling again.
  void clear() {
    _shortCount = 0;
    _latched = false;
    _connectedAt = null;
  }
}
