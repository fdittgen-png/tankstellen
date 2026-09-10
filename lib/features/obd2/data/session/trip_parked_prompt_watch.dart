// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// What the parked watch decided this tick.
enum ParkedPromptDecision {
  /// Nothing to do — still moving, still inside the parked grace, the
  /// prompt is already up, or the driver has answered "Keep".
  none,

  /// #3862 — an auto-record trip ends itself: it started on its own, it
  /// ends on its own, once, and only when nothing is left to record.
  finalise,

  /// #3862 — a manually started trip asks: the UI raises the Stop / Keep
  /// pill and the driver answers.
  prompt,
}

/// #3862 — the parked-prompt bookkeeping of [TripRecordingController],
/// as a collaborator that owns its five fields (#4034, epic #4032).
///
/// When the engine is off and the car has stopped moving, a recording
/// that keeps running is recording nothing. After
/// [TripRecordingController.parkedPromptAfter] the watch either
/// finalises the trip (auto-record: it started itself, it ends itself)
/// or raises the Stop / Keep prompt (manual: the driver decides).
///
/// The five flags used to be written from three of the controller's
/// `part` files, which could each invalidate an invariant the others
/// relied on. They are private here, and every transition goes through
/// one of the methods below.
class TripParkedPromptWatch {
  /// Below this GPS speed the car counts as stationary for the prompt.
  static const double stationaryKmh = 3.0;

  DateTime? _engineOffSince;
  DateTime? _stationarySince;
  bool _promptDue = false;
  bool _dismissed = false;
  bool _finaliseInFlight = false;

  /// True when the recording has been parked past the prompt delay and
  /// the driver has not yet answered. Surfaced to the UI as the Stop /
  /// Keep pill.
  bool get promptDue => _promptDue;

  /// #3858 — a recording that starts with the engine off enters the
  /// engine-off wait immediately, anchored at the trip's start time.
  void armEngineOffSince(DateTime? at) => _engineOffSince = at;

  /// The engine-off wait is over (the engine is running again, or the
  /// drop had another cause). Clears the parked clocks and returns true
  /// when a pending prompt was withdrawn, so the caller re-emits state
  /// exactly when something the UI shows actually changed.
  bool onEngineOffWaitEnded() {
    _engineOffSince = null;
    _stationarySince = null;
    if (!_promptDue) return false;
    _promptDue = false;
    return true;
  }

  /// #3862 — the driver answered "Keep": stay recording, and do not ask
  /// again this session.
  void dismiss() {
    _dismissed = true;
    _promptDue = false;
  }

  /// One tick of the parked watch, called only while the engine-off wait
  /// is active. [gpsSpeedKmh] is the latest GPS speed (null counts as
  /// stationary — a dead GPS must not keep a parked trip alive).
  ///
  /// Returns what the caller should do; [ParkedPromptDecision.prompt] is
  /// returned at most once per session, and
  /// [ParkedPromptDecision.finalise] at most once per recording.
  ParkedPromptDecision tick({
    required DateTime now,
    required double? gpsSpeedKmh,
    required bool automatic,
    required Duration promptAfter,
  }) {
    _engineOffSince ??= now;
    final stationary = gpsSpeedKmh == null || gpsSpeedKmh < stationaryKmh;
    if (!stationary) {
      _stationarySince = null;
      return ParkedPromptDecision.none;
    }
    _stationarySince ??= now;
    if (parkedFor(now) < promptAfter) return ParkedPromptDecision.none;
    if (automatic) {
      if (_finaliseInFlight) return ParkedPromptDecision.none;
      _finaliseInFlight = true;
      return ParkedPromptDecision.finalise;
    }
    if (_promptDue || _dismissed) return ParkedPromptDecision.none;
    _promptDue = true;
    return ParkedPromptDecision.prompt;
  }

  /// How long the car has been parked at [now] — measured from the LATER
  /// of "the engine went off" and "the car stopped moving", so neither a
  /// long idle nor a coast to a halt shortens the wait.
  Duration parkedFor(DateTime now) {
    final off = _engineOffSince;
    final still = _stationarySince;
    if (off == null) return Duration.zero;
    if (still == null) return now.difference(off);
    return now.difference(still.isAfter(off) ? still : off);
  }
}
