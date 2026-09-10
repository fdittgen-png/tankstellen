// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #3602 — the staleness fence that keeps snapshot engine values off a
/// sample no fresh parse is backing.
///
/// Owned by [TripRecordingController] (#4034, epic #4032). Its three
/// fields — when the last successful high-priority parse landed, whether
/// the fence has already escalated, and when the last sample was written
/// — used to live in the controller's shared `part` scope and were
/// written from four of its parts. They are private to this class now,
/// and the controller drives them through the four methods below.
///
/// ### Why the fence exists
///
/// A link that never opened (or died without a transport error) leaves
/// the scheduler at 0 Hz. The null-parse silent-failure detector counts
/// null PARSES, not absent polls, so it is structurally blind to that:
/// on the 76.5 km field trip of #3602 it stayed quiet while 49 minutes
/// of a real drive got ghost engine data (rpm 0, resting throttle)
/// stamped onto every GPS fix — and the trip was classified "full OBD2,
/// measured fuel". The fence measures the absence directly instead.
class TripEngineDataFence {
  DateTime? _lastFreshParseAt;
  bool _escalated = false;
  DateTime? _lastSampleAt;

  /// Wall time of the last successful high-priority engine parse, or
  /// null when none has landed in this window.
  DateTime? get lastFreshParseAt => _lastFreshParseAt;

  /// Wall time of the last sample handed to the recorder.
  DateTime? get lastSampleAt => _lastSampleAt;

  /// ANY successful high-priority parse clears the window — the fence
  /// detects "the ECU is dead", not "this one PID is unsupported".
  ///
  /// #3776 — a rebind re-arms it the same way with a fresh window: the
  /// escalation latch only clears on a real parse, so a reconnect onto a
  /// link that ALSO stays silent could never fire a second drop and the
  /// trip froze unhandled. Anchoring "fresh" at the swap gives the new
  /// link the full staleness window, after which the fence fires again
  /// and the recovery cycle re-runs — bounded, convergent.
  void onFreshParse(DateTime now) {
    _lastFreshParseAt = now;
    _escalated = false;
  }

  /// Record that a sample reached the recorder at [at].
  void onSample(DateTime at) => _lastSampleAt = at;

  /// True when the engine data has gone stale: no fresh parse within
  /// [stalenessLimit] of [now], measured only once [startGrace] has
  /// elapsed since [startedAt].
  ///
  /// [suppressed] holds the fence off while the reconnect grace or
  /// protocol work is running (#3783): the quiet-window `0100` search
  /// legitimately produces no parses for up to ~17 s, and the fence
  /// firing mid-search tore down the very link the recovery was
  /// bringing up — the 2026-08-25 dial-storm spiral.
  bool isStale({
    required DateTime now,
    required DateTime? startedAt,
    required Duration startGrace,
    required Duration stalenessLimit,
    required bool suppressed,
  }) {
    final pastGrace =
        startedAt == null || now.difference(startedAt) > startGrace;
    if (!pastGrace || suppressed) return false;
    final fresh = _lastFreshParseAt;
    return fresh == null || now.difference(fresh) > stalenessLimit;
  }

  /// Claim the one escalation this fence is allowed per window. Returns
  /// true the first time it is called after the fence went stale, false
  /// on every later tick — the caller escalates ONCE through the silent-
  /// failure drop path (pause with grace → reconnect → #2565 GPS-only
  /// degrade) rather than on every tick.
  bool claimEscalation() {
    if (_escalated) return false;
    _escalated = true;
    return true;
  }
}
