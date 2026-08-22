// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Pure climb + stop-and-go-restart detection over a trip's [TripSample]
/// stream, extracted from `driving_insights_analyzer.dart` so the analyzer
/// stays under its 400-line guard (#2693 C6 climb; #2694 C8 restart).
///
/// The climb detector folds the samples ONCE, recomputing road grade inline
/// with the IDENTICAL [RoadGradeCalculator] configuration the live GPS
/// folder uses (`gps_live_estimate_folder.dart`: 150 m window / 0.2
/// smoothing / minSamplesInWindow 5) and the SAME `speedMps · dt` distance
/// integral, so the post-trip figure lines up with what the live estimator
/// saw. The restart detector counts speed zero-crossings (stop→accelerate)
/// distinguished from a rolling start that never fully stopped.
///
/// The counterfactual model is documented in
/// `docs/guides/driving-insights.md`. Numbers are intentionally rough —
/// the goal is coaching, not telematics-grade accounting.
library;

import 'road_grade_calculator.dart';
import 'trip_recorder.dart';

/// Grade fraction above which a confident sample counts as a real climb.
/// 0.02 (2 %) clears GPS-altitude noise on flat ground.
const double _climbGradeThreshold = 0.02;

/// Counterfactual fuel rate on a climb expressed as a fraction of the
/// measured rate. 0.7 ≈ "the same distance on the flat would have burned
/// ~70 % of what the climb did" — the extra 30 % is the climbing cost.
const double _climbCounterfactualRatio = 0.7;

/// Fallback climb fuel rate (L/h) when no measured rate is on the samples
/// (GPS-only / no fuel PID) — a moderately high load figure.
const double _climbFallbackLPerHour = 9.0;

/// Speed (km/h) below which the car is considered stopped for restart
/// detection — absorbs GPS / wheel-speed jitter around a standstill.
const double _stopSpeedKmh = 1.5;

/// Speed (km/h) a restart must reach after a stop to count as a genuine
/// stop→accelerate restart (distinguishes it from a brief roll / creep).
const double _restartSpeedKmh = 12.0;

/// Estimated extra litres burned per stop-and-go restart — accelerating a
/// stopped car from rest is the costliest part of stop-and-go traffic.
const double _wastedLitersPerRestart = 0.04;

/// Outcome of [detectClimbCost]: the litres of fuel attributable to
/// climbing, the seconds spent on a confident climb, and the peak confident
/// grade as a percentage (for the insight subtitle / metadata).
class ClimbCostResult {
  const ClimbCostResult({
    required this.climbingLiters,
    required this.climbSeconds,
    required this.peakGradePercent,
  });

  final double climbingLiters;
  final double climbSeconds;
  final double peakGradePercent;

  static const ClimbCostResult none =
      ClimbCostResult(climbingLiters: 0, climbSeconds: 0, peakGradePercent: 0);
}

/// Outcome of [detectRestartCost]: the number of stop→accelerate restarts
/// and the litres attributable to them.
class RestartCostResult {
  const RestartCostResult({
    required this.restartCount,
    required this.restartLiters,
  });

  final int restartCount;
  final double restartLiters;

  static const RestartCostResult none =
      RestartCostResult(restartCount: 0, restartLiters: 0);
}

/// Recompute confident road grade over [sortedSamples] (must be sorted by
/// timestamp) and attribute the extra fuel burned while climbing. Pure.
ClimbCostResult detectClimbCost(List<TripSample> sortedSamples) {
  if (sortedSamples.length < 2) return ClimbCostResult.none;

  final gradeCalc = RoadGradeCalculator();
  var cumulativeDistanceM = 0.0;
  var climbingLiters = 0.0;
  var climbSeconds = 0.0;
  var peakGradePercent = 0.0;

  for (var i = 1; i < sortedSamples.length; i++) {
    final prev = sortedSamples[i - 1];
    final cur = sortedSamples[i];
    final dt = cur.timestamp.difference(prev.timestamp).inMicroseconds /
        Duration.microsecondsPerSecond;
    if (dt <= 0) continue;

    // Fold the START sample into the same calculator the live folder uses.
    final speedMps = prev.speedKmh / 3.6;
    cumulativeDistanceM += speedMps * dt;
    gradeCalc.addSample(
      cumulativeDistanceKm: cumulativeDistanceM / 1000.0,
      altitudeM: prev.altitudeM,
    );
    final grade = gradeCalc.current;
    if (!grade.confident || grade.gradeFraction <= _climbGradeThreshold) {
      continue;
    }

    climbSeconds += dt;
    final gradePct = grade.gradeFraction * 100.0;
    if (gradePct > peakGradePercent) peakGradePercent = gradePct;

    // Extra fuel over a flat-road counterfactual during the climb.
    final measuredRate = prev.fuelRateLPerHour;
    final rate = (measuredRate != null && measuredRate > 0)
        ? measuredRate
        : _climbFallbackLPerHour;
    climbingLiters += rate * (1 - _climbCounterfactualRatio) * dt / 3600.0;
  }

  return ClimbCostResult(
    climbingLiters: climbingLiters,
    climbSeconds: climbSeconds,
    peakGradePercent: peakGradePercent,
  );
}

/// Count stop→accelerate restarts (speed zero-crossings that recover past
/// [_restartSpeedKmh], distinguished from a rolling start that never fully
/// stopped) over [sortedSamples] and attribute the extra fuel. Pure.
RestartCostResult detectRestartCost(List<TripSample> sortedSamples) {
  if (sortedSamples.length < 2) return RestartCostResult.none;

  var restartCount = 0;
  // The car must come to a stop (below _stopSpeedKmh) and then climb back
  // above _restartSpeedKmh to count one restart. `wasStopped` latches the
  // stop so a single restart is counted once, not per accelerating sample.
  var wasStopped = sortedSamples.first.speedKmh <= _stopSpeedKmh;

  for (final s in sortedSamples.skip(1)) {
    if (s.speedKmh <= _stopSpeedKmh) {
      wasStopped = true;
    } else if (wasStopped && s.speedKmh >= _restartSpeedKmh) {
      restartCount++;
      wasStopped = false;
    }
  }

  return RestartCostResult(
    restartCount: restartCount,
    restartLiters: restartCount * _wastedLitersPerRestart,
  );
}
