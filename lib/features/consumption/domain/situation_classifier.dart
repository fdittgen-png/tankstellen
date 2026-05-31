// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:collection';

/// Driving situation classifier (#768).
///
/// Pure-logic state machine over a rolling 10-second window of
/// [Obd2Service] PIDs (speed, RPM, throttle %, engine load %, fuel
/// rate). Emits one of 8 [DrivingSituation] values on every
/// [onSample] call so the consumption banner can tint itself for
/// the user's current mode.
///
/// Two categories of situation:
///
/// * Steady-state modes — the user is cruising, idling, stop-and-go,
///   etc. — survive as long as the detection condition holds.
/// * Transient events — `hardAccel` and `fuelCutCoast` — fire while
///   the condition is true but always yield back to the underlying
///   steady-state once they pass.
///
/// Transitions between steady-state modes are debounced so a brief
/// WOT overtake doesn't strobe the UI: a new mode must hold for
/// [transitionDebounce] (default 3 s) before it's emitted. Transient
/// events bypass the debounce because their whole purpose is
/// immediate feedback.
enum DrivingSituation {
  idle,
  stopAndGo,
  urbanCruise,
  highwayCruise,
  deceleration,
  climbingOrLoaded,
  hardAccel,
  fuelCutCoast,

  // --- #2515 (epic #2512) new persistent calibration buckets ------
  // Consumption-layer mirror of the vehicle-layer `Situation` additions
  // (cold-start / sustained-load / partial-throttle decel). Persistence
  // is keyed by `.name`, so appending mid-enum would be ordinal-safe; we
  // append at the end regardless. All three are PERSISTENT (a stable
  // learned mean), not transient.
  /// Engine below operating temperature — open-loop warm-up enrichment.
  coldStartWarmup,

  /// High load held steady on a flat road (towing / fully loaded),
  /// distinct from a hill climb.
  sustainedLoadOrTowing,

  /// Gentle engine-braking / coast where injectors still fire — between
  /// [deceleration] and [fuelCutCoast].
  partialThrottleDecel,
}

/// One point of driving data the classifier ingests. Values come from
/// `Obd2Service` live PIDs; [speedKmh] and [rpm] are mandatory, the
/// rest are nullable because not every adapter / car answers every
/// PID.
class DrivingSample {
  final DateTime timestamp;
  final double speedKmh;
  final double rpm;
  final double? throttlePercent;
  final double? engineLoadPercent;
  final double? fuelRateLPerHour;

  /// Engine coolant temperature in °C (PID 0x05), #2515. Null when the
  /// car doesn't surface it. Used by [SituationClassifier] to detect a
  /// cold-start warm-up so the rule-mode path gets the new buckets too.
  final double? coolantTempC;

  /// Road grade as a percentage when a confident GPS-altitude estimate
  /// exists, else 0 (#2515). Lets the rule path separate a flat
  /// sustained load (towing) from a hill climb.
  final double gradePct;

  const DrivingSample({
    required this.timestamp,
    required this.speedKmh,
    required this.rpm,
    this.throttlePercent,
    this.engineLoadPercent,
    this.fuelRateLPerHour,
    this.coolantTempC,
    this.gradePct = 0,
  });
}

/// Stateful classifier — feed one sample per poll tick, read the
/// current situation via [current].
///
/// Keeps a rolling window of samples spanning [window] (default 10 s)
/// and derives aggregate features (averages + variances) over it.
class SituationClassifier {
  final Duration window;
  final Duration transitionDebounce;

  final Queue<DrivingSample> _samples = Queue();
  DrivingSituation _current = DrivingSituation.idle;
  DrivingSituation? _pending;
  DateTime? _pendingSince;

  SituationClassifier({
    this.window = const Duration(seconds: 10),
    this.transitionDebounce = const Duration(seconds: 3),
  });

  DrivingSituation get current => _current;

  /// Number of samples currently in the rolling window. Useful for
  /// cold-start handling — the first tick can't classify much.
  int get sampleCount => _samples.length;

  /// Feed a new sample. Returns the situation the UI should show
  /// right now — either the current steady-state mode, or a
  /// transient event (`hardAccel` / `fuelCutCoast`) when one applies.
  DrivingSituation onSample(DrivingSample sample) {
    _samples.addLast(sample);
    while (_samples.isNotEmpty &&
        sample.timestamp.difference(_samples.first.timestamp) > window) {
      _samples.removeFirst();
    }

    // Transients override the steady-state — they apply only at the
    // current tick, no debounce, and revert as soon as the condition
    // drops.
    final transient = _detectTransient(sample);
    if (transient != null) return transient;

    final candidate = _detectSteadyState(sample);
    if (candidate == _current) {
      // Same mode — cancel any pending transition.
      _pending = null;
      _pendingSince = null;
      return _current;
    }
    if (candidate == _pending) {
      // Still pending — check if the debounce has elapsed.
      if (sample.timestamp
              .difference(_pendingSince!)
              .inMilliseconds >=
          transitionDebounce.inMilliseconds) {
        _current = candidate;
        _pending = null;
        _pendingSince = null;
      }
      return _current;
    }
    // New candidate — start the debounce clock.
    _pending = candidate;
    _pendingSince = sample.timestamp;
    return _current;
  }

  /// Detect transient events that should render over the current
  /// steady-state. Checked before the steady-state classifier on
  /// every tick so a user hammering the pedal gets the "Hard accel"
  /// badge within one sample.
  DrivingSituation? _detectTransient(DrivingSample s) {
    // Fuel-cut coast: engine running but injectors off — most modern
    // cars do this on deceleration. Detected when fuelRate is
    // effectively zero while moving at >20 km/h.
    final fuelRate = s.fuelRateLPerHour;
    if (fuelRate != null && fuelRate < 0.1 && s.speedKmh > 20) {
      return DrivingSituation.fuelCutCoast;
    }

    // Hard acceleration: need ≥2 s of sustained rising speed with
    // throttle >50%. Use the last ~2 s of samples to compute accel.
    final accel = _recentAccelMps2(windowSeconds: 2);
    final throttle = s.throttlePercent;
    if (accel != null &&
        accel > 1.5 &&
        throttle != null &&
        throttle > 50) {
      return DrivingSituation.hardAccel;
    }

    return null;
  }

  /// Classify the underlying steady-state mode from the rolling
  /// window averages.
  DrivingSituation _detectSteadyState(DrivingSample s) {
    final avgSpeed = _avg((e) => e.speedKmh);
    final avgRpm = _avg((e) => e.rpm);
    final throttleVar = _variance((e) => e.throttlePercent);
    final accelVar = _variance((e) => e.speedKmh);
    final engineLoad = s.engineLoadPercent;
    final avgThrottle = _avg((e) => e.throttlePercent);
    final speedRange = _range((e) => e.speedKmh);

    // Cold-start / warm-up (#2515): the engine is below operating
    // temperature, running open-loop rich. Highest-priority steady
    // state — a warm-up sample must not be classified as anything else,
    // mirroring the fuzzy path's cold-start override. Coolant below
    // 70 °C (PID 0x05) is the gate; cars that never report it fall
    // through to the legacy logic.
    final coolant = s.coolantTempC;
    if (coolant != null && coolant < 70) {
      return DrivingSituation.coldStartWarmup;
    }

    // Idle: basically stationary with the engine running. Short
    // window of ≥5 s so a momentary stop at a light doesn't count.
    if (avgSpeed <= 2 &&
        avgRpm > 0 &&
        avgThrottle < 5 &&
        _spanSeconds() >= 5) {
      return DrivingSituation.idle;
    }

    // Stop-and-go: low avg speed with multiple zero-crossings — the
    // user is in dense traffic with frequent starts and stops.
    if (avgSpeed < 20 && _zeroSpeedCrossings() >= 2) {
      return DrivingSituation.stopAndGo;
    }

    // Deceleration: mostly letting off the throttle with speed
    // dropping. Distinct from fuel-cut coast because fuel may still
    // be injected — just not much.
    final accel = _recentAccelMps2(windowSeconds: 3);
    if (accel != null && accel < -1 && avgThrottle < 10) {
      return DrivingSituation.deceleration;
    }

    // Partial-throttle decel (#2515): a gentler lift-off than the
    // `< -1 m/s²` deceleration above — the injectors still fire. Sits in
    // the band `[-1, -0.1)` between full deceleration and a steady
    // cruise. Disjoint accel band so it can't double-count with
    // deceleration.
    if (accel != null && accel >= -1 && accel < -0.1 && avgThrottle < 10) {
      return DrivingSituation.partialThrottleDecel;
    }

    // Climbing or heavily loaded: engine working hard (high load)
    // while speed is roughly constant. #2515 — only when a grade is
    // actually present; on the flat the same high-load signature is a
    // sustained tow (handled next), not a climb. Stands in for the pure
    // climb-detection we'd do with GPS altitude.
    if (engineLoad != null &&
        engineLoad > 70 &&
        speedRange < 2 &&
        avgSpeed > 20 &&
        s.gradePct >= 2) {
      return DrivingSituation.climbingOrLoaded;
    }

    // Sustained load / towing (#2515): the same high-load, steady-speed
    // signature as a climb but on a FLAT road (grade < 2 %) — a fully
    // loaded car or a trailer holding the engine at high load without a
    // hill.
    if (engineLoad != null &&
        engineLoad > 70 &&
        speedRange < 2 &&
        avgSpeed > 20 &&
        s.gradePct < 2) {
      return DrivingSituation.sustainedLoadOrTowing;
    }

    // Highway cruise: high, stable speed.
    if (avgSpeed >= 80 && (throttleVar ?? 0) < 100) {
      return DrivingSituation.highwayCruise;
    }

    // Urban cruise: moderate speed, smooth throttle.
    if (avgSpeed >= 20 && avgSpeed < 60 && (accelVar ?? 0) < 1) {
      return DrivingSituation.urbanCruise;
    }

    // Nothing fits — hold the current mode. Prevents rapid flipping
    // in transition zones.
    return _current;
  }

  double _avg(num? Function(DrivingSample) f) {
    if (_samples.isEmpty) return 0;
    var total = 0.0;
    var count = 0;
    for (final s in _samples) {
      final v = f(s);
      if (v == null) continue;
      total += v.toDouble();
      count++;
    }
    return count == 0 ? 0 : total / count;
  }

  double? _variance(num? Function(DrivingSample) f) {
    if (_samples.length < 2) return null;
    var mean = 0.0;
    var count = 0;
    for (final s in _samples) {
      final v = f(s);
      if (v == null) continue;
      mean += v.toDouble();
      count++;
    }
    if (count < 2) return null;
    mean /= count;
    var sumSq = 0.0;
    for (final s in _samples) {
      final v = f(s);
      if (v == null) continue;
      final d = v.toDouble() - mean;
      sumSq += d * d;
    }
    return sumSq / (count - 1);
  }

  double _range(num Function(DrivingSample) f) {
    if (_samples.isEmpty) return 0;
    var minV = double.infinity;
    var maxV = -double.infinity;
    for (final s in _samples) {
      final v = f(s).toDouble();
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }
    return maxV - minV;
  }

  int _zeroSpeedCrossings() {
    // Count transitions from moving (>5 km/h) to stopped (≤1 km/h).
    var crossings = 0;
    var wasMoving = false;
    for (final s in _samples) {
      if (s.speedKmh > 5) {
        wasMoving = true;
      } else if (s.speedKmh <= 1 && wasMoving) {
        crossings++;
        wasMoving = false;
      }
    }
    return crossings;
  }

  int _spanSeconds() {
    if (_samples.length < 2) return 0;
    return _samples.last.timestamp
        .difference(_samples.first.timestamp)
        .inSeconds;
  }

  /// Compute acceleration in m/s² across the trailing
  /// [windowSeconds] of samples. Returns null if we don't have at
  /// least two samples spanning that window.
  double? _recentAccelMps2({required int windowSeconds}) {
    if (_samples.length < 2) return null;
    final now = _samples.last;
    DrivingSample? start;
    for (final s in _samples) {
      if (now.timestamp.difference(s.timestamp).inSeconds <= windowSeconds) {
        start = s;
        break;
      }
    }
    start ??= _samples.first;
    final dt = now.timestamp.difference(start.timestamp).inMilliseconds / 1000.0;
    if (dt <= 0) return null;
    final dv = (now.speedKmh - start.speedKmh) / 3.6; // km/h → m/s
    return dv / dt;
  }
}
