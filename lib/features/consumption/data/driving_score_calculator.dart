// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The ONE canonical driving-style score calculator (#2460).
///
/// Turns a stream of [TripSample]s into a single 0..100 [DrivingScore]
/// composite — `100 − Σ(weighted penalties) + Σ(eco credits)`, floored
/// at 0, capped at 100, classified into a [DrivingStyleClass]. Replaces
/// the two divergent 0..100 implementations that used to exist (this
/// file's old throttle-blind version and `trip_metrics.drivingScore`).
///
/// ## Metric families & caps (sum of penalty caps = 100; eco credit can
/// push back up toward 100)
///
///   * AGGRESSIVENESS — hard-accel events (-3/event, cap -15),
///     hard-brake events (-3/event, cap -15), full-throttle time-share
///     (pedal `pp` else throttle `th` ≥ 90 %, cap -10), pedal-velocity
///     (max d(pedal)/dt over moving samples, cap -5).
///   * OVER-REV / SHIFT — high-RPM time-share (> 3000 RPM, cap -20),
///     lugging seconds below the optimal gear (RPM ceiling 2200, cap
///     -10, from `secondsBelowOptimalGear`), hard-shift spikes (cap -5).
///   * IDLE — idle time-share (speed ≤ 0.5 & rpm > 0, cap -25),
///     rev-while-stationary blips (cap -5).
///   * SMOOTHNESS — a CONTINUOUS term from speed std-dev + pedal/throttle
///     variance (cap -10), replacing the old binary gate.
///   * SPEED-EFFICIENCY — high-speed time-share (> 110 km/h, cap -10),
///     λ-enrichment share (λ < 1, cap -5).
///   * ECO-CREDIT (positive) — fuel-cut coast time-share (fuelRate < 0.1
///     & speed > 20, +10 max). Detected before #2460 but never credited.
///
/// ## Full-throttle penalty — NOW FIRES (#2460)
///
/// The old code hard-coded `const fullThrottleSeconds = 0` (a dead
/// no-op) and a stale docstring claiming the schema lacked throttle.
/// Both are gone: pedal (PID 0x49-0x4B) and throttle (PID 0x11) are
/// persisted on every [TripSample] since #1261 / #2459, so the penalty
/// is computed from real data. Cars exposing neither contribute 0 — the
/// honest "no signal" result, not a hard-coded zero.
///
/// The function is pure and synchronous — safe to call from a UI thread
/// (a 60-min trip at 1 Hz is 3 600 samples; the passes are O(n)).
library;

import 'dart:math' as math;

import '../domain/driving_score.dart';
import '../domain/trip_recorder.dart';

// #2460 — the per-interval accumulator + the inline Welford helper live in
// a part file so this orchestrator stays under the 400-line guard. They
// stay library-private (`_`-prefixed); the part shares this file's scope.
part 'driving_score_accumulators.dart';

// ---- Canonical thresholds (shared by analyzer + lessons + score) ----

/// RPM above which a sample counts as "high RPM".
const double kHighRpmThreshold = 3000;

/// Acceleration (m/s²) at/above which an interval is a hard-accel event.
const double kHardAccelThresholdMps2 = 3.0;

/// Deceleration (m/s², positive) at/below whose negation an interval is
/// a hard-brake event. Canonical 3.5 (#2460).
const double kHardBrakeThresholdMps2 = 3.5;

/// Pedal / throttle percent at/above which a sample counts as "full
/// throttle".
const double kFullThrottlePercent = 90.0;

/// RPM ceiling used by the lugging heuristic (one gear too low).
const double kLuggingRpmCeiling = 2200;

/// Speed (km/h) at/above which a sample is in the high-speed band.
const double kHighSpeedThresholdKmh = 110.0;

/// Speed (km/h) at/below which the car is "stationary" for idle.
const double _idleSpeedToleranceKmh = 0.5;

/// Speed (km/h) above which the fuel-cut coast credit applies.
const double _coastMinSpeedKmh = 20.0;

/// Fuel rate (L/h) below which the engine is treated as fuel-cut.
const double _coastFuelRateLPerHour = 0.1;

// ---- Penalty caps -----------------------------------------------------

const double _idlingCap = 25.0;
const double _hardAccelCap = 15.0;
const double _hardBrakeCap = 15.0;
const double _highRpmCap = 20.0;
const double _fullThrottleCap = 10.0;
const double _pedalVelocityCap = 5.0;
const double _luggingCap = 10.0;
const double _hardShiftCap = 5.0;
const double _revWhileStationaryCap = 5.0;
const double _smoothnessCap = 10.0;
const double _speedEfficiencyCap = 10.0;
const double _lambdaEnrichmentCap = 5.0;
const double _ecoCreditCap = 10.0;

/// Per-event score deductions.
const double _hardAccelPerEvent = 3.0;
const double _hardBrakePerEvent = 3.0;

/// Pedal-velocity (%/s) at which the pedal-velocity penalty saturates.
const double _pedalVelocitySaturation = 200.0;

/// RPM jump (within one interval) that counts as one hard-shift spike,
/// when followed by a drop. -1.25 points per spike, capped.
const double _hardShiftRpmSpike = 1200.0;
const double _hardShiftPerSpike = 1.25;

/// Per rev-while-stationary blip (pedal/throttle > 25 % or rpm spike >
/// 1500 while speed ≤ 0.5). -1.25 points each, capped.
const double _revWhileStationaryPedal = 25.0;
const double _revWhileStationaryRpm = 1500.0;
const double _revWhileStationaryPerBlip = 1.25;

/// Speed std-dev (km/h) at which the smoothness penalty saturates on its
/// own, and pedal/throttle variance (%²) at which it saturates.
const double _smoothnessSpeedStdDevSaturation = 25.0;
const double _smoothnessPedalVarSaturation = 900.0;

/// Compute the canonical driving-style score from a trip's [samples]
/// (#2460). Empty / single-sample trips return [DrivingScore.perfect] —
/// there is no Δt to integrate.
///
/// [secondsBelowOptimalGear] is the lugging metric computed at trip-end
/// by `gear_inference.dart` and stored on [TripSummary]; pass it through
/// so the over-rev family includes lugging. Null (no inference / EV /
/// too few samples) contributes 0.
DrivingScore computeDrivingScore(
  List<TripSample> samples, {
  double? secondsBelowOptimalGear,
}) {
  if (samples.length < 2) return DrivingScore.perfect;

  final sorted = [...samples]
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  final totalDt = _seconds(sorted.first.timestamp, sorted.last.timestamp);
  if (totalDt <= 0) return DrivingScore.perfect;

  final acc = _Accumulators();
  for (var i = 1; i < sorted.length; i++) {
    final prev = sorted[i - 1];
    final cur = sorted[i];
    final dt = _seconds(prev.timestamp, cur.timestamp);
    if (dt <= 0) continue;
    acc.accumulate(prev: prev, cur: cur, dt: dt);
  }

  return acc.build(
    totalDt: totalDt,
    secondsBelowOptimalGear: secondsBelowOptimalGear,
  );
}

/// Cheap, summary-only score for legacy sample-less trips (#2460) — the
/// path the achievement engine and any trip persisted before per-sample
/// buffers (#1040) take. Routes the SAME idle / high-RPM / harsh-event
/// model through the canonical [DrivingScore] so the two surfaces never
/// diverge again (this replaces the deleted `trip_metrics.drivingScore`).
///
/// Trips under 1 minute, or without a start/end, return a perfect score
/// — too little signal to attribute any penalty.
DrivingScore computeDrivingScoreFromSummary(TripSummary summary) {
  final start = summary.startedAt;
  final end = summary.endedAt;
  final durationSec =
      (start != null && end != null) ? _seconds(start, end) : 0.0;
  if (durationSec <= 60) return DrivingScore.perfect;

  final idlingPenalty = _clamp(
    summary.idleSeconds / durationSec * _idlingCap,
    0,
    _idlingCap,
  );
  final highRpmPenalty = _clamp(
    summary.highRpmSeconds / durationSec * _highRpmCap,
    0,
    _highRpmCap,
  );
  final hardAccelPenalty = _clamp(
    summary.harshAccelerations * _hardAccelPerEvent,
    0,
    _hardAccelCap,
  );
  final hardBrakePenalty = _clamp(
    summary.harshBrakes * _hardBrakePerEvent,
    0,
    _hardBrakeCap,
  );
  final luggingPenalty = _luggingPenalty(
    summary.secondsBelowOptimalGear,
    durationSec,
  );

  final raw = 100.0 -
      idlingPenalty -
      highRpmPenalty -
      hardAccelPenalty -
      hardBrakePenalty -
      luggingPenalty;
  return DrivingScore(
    score: _clamp(raw, 0, 100).round(),
    idlingPenalty: idlingPenalty,
    hardAccelPenalty: hardAccelPenalty,
    hardBrakePenalty: hardBrakePenalty,
    highRpmPenalty: highRpmPenalty,
    fullThrottlePenalty: 0,
    luggingPenalty: luggingPenalty,
  );
}

/// Lugging penalty: linear in the share of the trip spent below the
/// optimal gear, capped. Null `seconds` (no inference) → 0.
double _luggingPenalty(double? seconds, double durationSec) {
  if (seconds == null || seconds <= 0 || durationSec <= 0) return 0;
  return _clamp(seconds / durationSec * _luggingCap, 0, _luggingCap);
}

/// Pedal position (driver intent, PID 0x49-0x4B) when available, else
/// throttle position (PID 0x11). The canonical "how hard is the driver
/// pushing" signal for the aggressiveness family (#2460).
double? _pedalOrThrottle(TripSample s) => s.pedalPercent ?? s.throttlePercent;

double _seconds(DateTime a, DateTime b) =>
    b.difference(a).inMicroseconds / Duration.microsecondsPerSecond;

double _clamp(double value, double low, double high) {
  if (value < low) return low;
  if (value > high) return high;
  return value;
}
