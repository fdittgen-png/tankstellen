// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'accel_event_gate.dart';
import 'harsh_event.dart';

/// Detects harsh-braking / harsh-acceleration events from a stream of
/// speed samples, decoupled from the sample-feed cadence (#1922) and
/// de-noised against jittery / dead-reckoning speed signals (#2653).
///
/// Extracted from [TripRecorder]: the recorder is fed a `TripSample`
/// every 250 ms, but the OBD speed PID (0x0D, integer km/h) refreshes
/// only ~1 Hz — so `speedKmh` arrives as a *staircase* of repeated
/// values. Differentiating that staircase over the 250 ms emit
/// interval divided a ~1 s speed delta by 0.25 s and inflated every
/// acceleration ~4x: a real device backup showed 428 "harsh brakes"
/// on a single 157 km motorway drive.
///
/// The first fix (#1922) re-samples speed at ~1 Hz before taking the
/// derivative: the threshold is evaluated only between samples at
/// least [_evalIntervalSec] apart, so Δt is always a real ~1 s window.
///
/// #2653 adds four de-noising gates on top, because the resample alone
/// still over-detected on the **virtual** (dead-reckoning) distance
/// source — a real 77-trip backup measured a median of 4.78 and a peak
/// of 43.4 phantom events/km on virtual trips, versus 1.06/km on
/// GPS-sourced trips (43.4/km is physically impossible → it is noise
/// counted as events). The gates:
///   1. **Sustained-window** — the derivative must be measured over a
///      window of at least [minSustainedSec] (≈1 s, matching
///      `gps_driving_features.dart`). A single sub-1 s spike (the
///      phasing artefact a coarse staircase produces against the
///      ~0.9 s resample) can no longer fire.
///   2. **Accuracy gate** — a fix whose reported horizontal accuracy
///      exceeds [maxHAccuracyM] (~10 m) is dropped *and* breaks the
///      anchor, so the derivative is never taken across a bad fix
///      ("a bad fix is worse than no fix"). Possible since #2648/#2650
///      persist `hAccuracyM`.
///   3. **Min-speed floor** — intervals whose mean speed is below
///      [minSpeedKmh] (~5 km/h) are not scored; dead-reckoning noise at
///      a near-standstill manufactures phantom events.
///   4. **Source-aware suppression** — when [onSample] is told the
///      sample came from a suppressed source (the `virtual`
///      dead-reckoning odometer, and GPS-only trips that also default
///      to `virtual`), harsh scoring is skipped entirely. A
///      1 km/h-quantised dead-reckoning speed signal is unfit for
///      differentiation; suppressing it is honest, where counting its
///      phasing artefacts is not.
///
/// An optional 3-sample moving-average pre-smoothing on speed (the same
/// low-pass already proven in `gps_live_fuel_estimator.dart`) further
/// damps quantisation jitter before the derivative; off by default so
/// the canonical OBD path is unchanged.
///
/// Since #2029 the detector also records a [HarshEvent] per crossing
/// — the integer counters stay as cheap getters for legacy consumers,
/// while [events] gives post-trip coaching the timestamped detail it
/// needs to surface "harsh brake at 14:23, 0.45 g while doing 80 km/h".
class HarshEventDetector {
  HarshEventDetector({
    this.brakeThresholdMps2 = kHardBrakeThresholdMps2,
    this.accelThresholdMps2 = kHardAccelThresholdMps2,
    this.minSustainedSec = kAccelEventMinSustainedSec,
    this.minSpeedKmh = kAccelEventMinSpeedKmh,
    this.maxHAccuracyM = kAccelEventAccuracyGateM,
    this.refractorySec = kAccelEventRefractorySec,
    this.smoothSpeed = false,
    this.onEvent,
  });

  /// Optional live callback invoked the instant a (de-noised) event is
  /// detected (#2663). Post-#2653 the detector fires only on REAL,
  /// sustained, accuracy-/speed-/source-gated events — exactly the
  /// signal the driving-coach voice listener should speak. Off by
  /// default so the post-trip [events] path is unchanged; the recorder
  /// threads it in only when a live consumer is attached.
  void Function(HarshEvent event)? onEvent;

  /// Deceleration magnitude (m/s², positive number) at or above which
  /// an interval counts as a harsh brake.
  final double brakeThresholdMps2;

  /// Acceleration (m/s²) at or above which an interval counts as a
  /// harsh acceleration.
  final double accelThresholdMps2;

  /// Minimum window length (seconds) the derivative must span before a
  /// crossing is counted (#2653). A single sub-[minSustainedSec]
  /// interval — the phasing artefact a coarse speed staircase produces
  /// against the [_evalIntervalSec] resample — is rejected, matching the
  /// "sustained ≥ 1 s" convention in `gps_driving_features.dart`.
  final double minSustainedSec;

  /// Minimum mean interval speed (km/h) below which an interval is not
  /// scored (#2653). Dead-reckoning noise at a near-standstill produces
  /// phantom events; genuine harsh manoeuvres happen above a walking
  /// pace.
  final double minSpeedKmh;

  /// Reported horizontal GPS accuracy (metres) above which a sample is
  /// dropped *and* the anchor reset, so the derivative is never taken
  /// across a bad fix (#2653). A non-finite or null accuracy is treated
  /// as "unknown, accept" so OBD-speed-only samples (no GPS) still flow.
  final double maxHAccuracyM;

  /// Refractory window (seconds) the derivative must stay continuously
  /// below the threshold before another same-type event can fire (#2846).
  /// Debounces one physical manoeuvre's staircase jitter into ONE event;
  /// shared default with `countAccelEvents` so every path agrees.
  final double refractorySec;

  /// When true, speed is passed through a 3-sample moving average before
  /// differentiation (#2653), damping 1 km/h quantisation jitter. Off by
  /// default — the canonical OBD path keeps its raw-speed behaviour.
  final bool smoothSpeed;

  /// Minimum spacing (seconds) between two evaluated samples — this is
  /// what re-samples the speed signal at ~1 Hz. 0.9 rather than 1.0 so
  /// a nominally-1 Hz feed with minor jitter still evaluates every
  /// sample instead of skipping to a 2 s window.
  static const double _evalIntervalSec = 0.9;

  /// Window length for the optional speed moving average.
  static const int _smoothWindow = 3;

  final List<HarshEvent> _events = [];
  final List<double> _speedWindow = [];

  // The last sample an evaluation was anchored on. Advances only when
  // an evaluation actually fires, so a burst of sub-second samples
  // cannot drag the anchor forward and starve the detector.
  double? _anchorSpeedKmh;
  DateTime? _anchorAt;

  // Episode latches (#2667). An "event" is one sustained threshold-crossing
  // episode, not one per evaluated ~1 s interval — a multi-second hard
  // brake is ONE brake. We count on the transition INTO an episode and
  // re-arm only once the signal has stayed below the threshold for a
  // continuous [minSustainedSec]·-independent refractory window
  // ([refractorySec], #2846): the staircase a coarse ~1 Hz speed PID
  // produces dips below the threshold for a single hold interval inside one
  // manoeuvre, and the old "re-arm after one sub-threshold interval" latch
  // counted each pulse as a new event (the ~100× over-count). This is the
  // count semantics shared with `countAccelEvents`, so the detector agrees
  // with the score / insights / GPS features.
  bool _inAccelEpisode = false;
  bool _inBrakeEpisode = false;
  double _accelBelowSec = 0;
  double _brakeBelowSec = 0;

  /// Number of harsh-braking events counted so far.
  int get brakes => _events
      .where((e) => e.type == HarshEventType.brake)
      .length;

  /// Number of harsh-acceleration events counted so far.
  int get accelerations => _events
      .where((e) => e.type == HarshEventType.acceleration)
      .length;

  /// Per-event detail captured since the detector was last reset
  /// (#2029). Surfaces the timestamped magnitude + speed needed for
  /// post-trip coaching messages. Caller copies defensively if it
  /// intends to mutate.
  List<HarshEvent> get events => List.unmodifiable(_events);

  /// Feed one speed sample. Safe to call at any cadence; samples
  /// closer together than [_evalIntervalSec] are folded into the next
  /// evaluated window rather than each producing a derivative.
  ///
  /// [hAccuracyM] is the sample's reported horizontal GPS accuracy (null
  /// / non-finite when unknown, e.g. an OBD-speed-only sample); a fix
  /// worse than [maxHAccuracyM] is dropped and resets the anchor.
  /// [suppress] is true when the sample's distance source is unfit for
  /// speed differentiation (the `virtual` dead-reckoning odometer) — the
  /// detector then ignores the sample entirely (#2653).
  void onSample(
    double speedKmh,
    DateTime timestamp, {
    double? hAccuracyM,
    bool suppress = false,
  }) {
    // Source-aware suppression: a dead-reckoning speed signal is unfit
    // for differentiation. Don't even seed the anchor from it.
    if (suppress) return;

    // Accuracy gate: a bad fix is worse than no fix — drop it and break
    // the anchor (and the running episode) so the derivative is never
    // taken across it.
    if (hAccuracyM != null && hAccuracyM.isFinite && hAccuracyM > maxHAccuracyM) {
      _anchorAt = null;
      _anchorSpeedKmh = null;
      _speedWindow.clear();
      _inAccelEpisode = false;
      _inBrakeEpisode = false;
      _accelBelowSec = 0;
      _brakeBelowSec = 0;
      return;
    }

    final speed = smoothSpeed ? _smooth(speedKmh) : speedKmh;

    final anchorAt = _anchorAt;
    final anchorSpeed = _anchorSpeedKmh;
    if (anchorAt == null || anchorSpeed == null) {
      _anchorAt = timestamp;
      _anchorSpeedKmh = speed;
      return;
    }
    final dt = timestamp.difference(anchorAt).inMicroseconds /
        Duration.microsecondsPerSecond;
    if (dt < _evalIntervalSec) return;

    // Sustained-window gate: only count a crossing whose derivative was
    // measured over a real ≥ minSustainedSec window. A single sub-1 s
    // spike (the staircase phasing artefact) is rejected here.
    // Min-speed floor: skip intervals at a near-standstill.
    final meanSpeedKmh = (speed + anchorSpeed) / 2.0;
    final scorable = dt >= minSustainedSec && meanSpeedKmh >= minSpeedKmh;

    // Δspeed km/h → m/s by / 3.6, then / Δt for m/s².
    final accelMps2 = ((speed - anchorSpeed) / 3.6) / dt;

    // Physical-plausibility clamp (#2895): a speed-derivative beyond what a
    // real car can produce (forward > ~0.61 g, braking > ~1.12 g) is GPS
    // speed noise, not a manoeuvre — break the anchor + running episode so it
    // never counts. Mirrors `countAccelEvents` so the recorder's
    // harshAccelerations agrees with the gate the score / insights use.
    if (accelMps2 >= kMaxPlausibleAccelMps2 ||
        accelMps2 <= -kMaxPlausibleBrakeMps2) {
      _anchorAt = null;
      _anchorSpeedKmh = null;
      _speedWindow.clear();
      _inAccelEpisode = false;
      _inBrakeEpisode = false;
      _accelBelowSec = 0;
      _brakeBelowSec = 0;
      return;
    }

    // Episode semantics (#2667 + #2846): record at most once on entry into
    // a sustained harsh stretch, and re-arm only once the derivative has
    // stayed below the threshold for a continuous [refractorySec] window —
    // so a multi-interval manoeuvre (and the staircase hold-jitter that a
    // coarse speed PID adds inside it) is ONE event, agreeing with the
    // shared gate.
    final isBrake = scorable && accelMps2 <= -brakeThresholdMps2;
    final isAccel = scorable && accelMps2 >= accelThresholdMps2;

    if (isBrake) {
      _brakeBelowSec = 0;
      if (!_inBrakeEpisode) {
        _record(HarshEvent(
          timestamp: timestamp,
          magnitudeG: (-accelMps2) / standardGravityMps2,
          speedKmh: speed,
          type: HarshEventType.brake,
        ));
        _inBrakeEpisode = true;
      }
    } else if (_inBrakeEpisode) {
      _brakeBelowSec += dt;
      if (_brakeBelowSec >= refractorySec) {
        _inBrakeEpisode = false;
        _brakeBelowSec = 0;
      }
    }

    if (isAccel) {
      _accelBelowSec = 0;
      if (!_inAccelEpisode) {
        _record(HarshEvent(
          timestamp: timestamp,
          magnitudeG: accelMps2 / standardGravityMps2,
          speedKmh: speed,
          type: HarshEventType.acceleration,
        ));
        _inAccelEpisode = true;
      }
    } else if (_inAccelEpisode) {
      _accelBelowSec += dt;
      if (_accelBelowSec >= refractorySec) {
        _inAccelEpisode = false;
        _accelBelowSec = 0;
      }
    }
    _anchorAt = timestamp;
    _anchorSpeedKmh = speed;
  }

  /// Append [event] to the post-trip list and fire the optional live
  /// [onEvent] callback (#2663) — the single record point both consumers
  /// flow through.
  void _record(HarshEvent event) {
    _events.add(event);
    onEvent?.call(event);
  }

  /// Push [raw] into the moving-average window and return the smoothed
  /// value (mean of the last up-to-[_smoothWindow] samples). Mirrors the
  /// low-pass in `gps_live_fuel_estimator.dart`.
  double _smooth(double raw) {
    _speedWindow.add(raw);
    if (_speedWindow.length > _smoothWindow) {
      _speedWindow.removeAt(0);
    }
    final sum = _speedWindow.reduce((a, b) => a + b);
    return sum / _speedWindow.length;
  }

  /// Reset the counters and anchor — used before recording a fresh
  /// trip without discarding the detector instance.
  void reset() {
    _events.clear();
    _speedWindow.clear();
    _anchorSpeedKmh = null;
    _anchorAt = null;
    _inAccelEpisode = false;
    _inBrakeEpisode = false;
    _accelBelowSec = 0;
    _brakeBelowSec = 0;
  }
}
