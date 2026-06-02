// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import '../../../core/utils/num_extensions.dart';
import '../../consumption/data/driving_score_calculator.dart';
import '../../consumption/data/trip_history_repository.dart';
import '../../consumption/domain/trip_recorder.dart';

/// Pure helpers that derive achievement-grade metrics from a single
/// trip (#1041 phase 5).
///
/// The achievement engine stays pure: the provider runs these helpers
/// once per trip and passes the results in via lookup maps. Keeping
/// the helpers here (rather than inside the engine) so the engine
/// signature does not pull `TripSample` into rule code that only
/// needs simple ints/doubles.
///
/// Concretely:
///   * [drivingScore] — 0-100 composite for a single trip. Since #2460
///     this is a thin wrapper over the ONE canonical
///     `computeDrivingScoreFromSummary` (the divergent per-summary
///     formula that used to live here is gone). The achievement engine
///     thresholds the same number the trip-detail card shows, so the
///     two surfaces can never disagree again.
///   * [coldStartExcessLiters] — best-effort estimate of the fuel a
///     trip burned above its own steady-state baseline during the first
///     few minutes. Used to evaluate the `coldStartAware` badge on a
///     per-month aggregate.
///   * [speedStdDev] — std-dev of non-idle speed samples, used by the
///     `highwayMaster` rule.
class TripMetrics {
  TripMetrics._();

  /// Speed (km/h) below which a sample is treated as idle / stopped
  /// for std-dev calculations. Same threshold the analyzer uses for
  /// the idle column, so the two metrics agree on what "moving" means.
  static const double _movingSpeedThresholdKmh = 5.0;

  /// First-minutes window treated as "cold start" for the excess
  /// estimate. 5 minutes is a common warm-up window for petrol cars
  /// to reach operating temperature; diesels run a bit longer but
  /// cold-start excess for them is also smaller, so a single window
  /// is good enough for an achievement signal.
  static const Duration _coldStartWindow = Duration(minutes: 5);

  /// Compute a 0-100 driving score for a single trip from its summary
  /// (#2460). Delegates to the ONE canonical summary-only calculator so
  /// the achievement engine and the trip-detail card never diverge.
  /// Higher is better; legacy trips without per-sample data score off
  /// the summary fields. Trips < 1 minute, or with no duration, score
  /// 100 (insufficient signal) — the canonical calc enforces that.
  static int drivingScore(TripSummary summary) =>
      computeDrivingScoreFromSummary(summary).score;

  /// Estimate the litres burned above this trip's own steady-state
  /// baseline during the first [_coldStartWindow]. Returns 0 when the
  /// trip is too short, has no fuel-rate samples, or the cold-start
  /// segment is missing (e.g. immediate-stop trip).
  ///
  /// The baseline is the mean L/h of the trip *outside* the cold-
  /// start window — using the trip's own steady-state avoids the
  /// ambiguity of choosing between `cold_start_baselines.dart`'s
  /// per-situation table and the per-vehicle learned baseline. Trips
  /// that entirely lack a steady-state segment (e.g. <6 min of
  /// recording) return 0 because the achievement requires a real
  /// month-aggregate signal, not a one-trip extrapolation.
  static double coldStartExcessLiters(List<TripSample> samples) {
    if (samples.length < 2) return 0;

    // Sort defensively — persistence order is not guaranteed.
    final sorted = [...samples]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final tripStart = sorted.first.timestamp;
    final coldEnd = tripStart.add(_coldStartWindow);
    final tripEnd = sorted.last.timestamp;
    if (!coldEnd.isBefore(tripEnd)) {
      // Whole trip falls inside the cold-start window — not enough
      // signal to derive a baseline.
      return 0;
    }

    // Per-interval fuel accumulation (litres) for cold + steady
    // segments. We attribute each interval to whichever segment its
    // start sample falls into.
    double coldLiters = 0;
    double coldSeconds = 0;
    double steadyLiters = 0;
    double steadySeconds = 0;

    for (var i = 1; i < sorted.length; i++) {
      final prev = sorted[i - 1];
      final cur = sorted[i];
      final dt =
          cur.timestamp.difference(prev.timestamp).inMicroseconds /
              Duration.microsecondsPerSecond;
      if (dt <= 0) continue;
      final fuelRate = prev.fuelRateLPerHour;
      if (fuelRate == null || fuelRate <= 0) continue;
      final liters = fuelRate * dt / 3600.0;
      if (prev.timestamp.isBefore(coldEnd)) {
        coldLiters += liters;
        coldSeconds += dt;
      } else {
        steadyLiters += liters;
        steadySeconds += dt;
      }
    }

    if (coldSeconds <= 0 || steadySeconds <= 0) return 0;

    final coldRate = coldLiters / coldSeconds; // L/s
    final steadyRate = steadyLiters / steadySeconds; // L/s
    if (coldRate <= steadyRate) return 0;

    final excessRate = coldRate - steadyRate;
    return excessRate * coldSeconds;
  }

  /// Std-dev (km/h) of non-idle speed samples. Returns
  /// `double.infinity` when there are fewer than two moving samples
  /// — callers treat that as "fail any tightness threshold".
  static double speedStdDev(List<TripSample> samples) {
    final moving = <double>[];
    for (final s in samples) {
      if (s.speedKmh >= _movingSpeedThresholdKmh) moving.add(s.speedKmh);
    }
    if (moving.length < 2) return double.infinity;
    final mean = moving.average;
    var sumSq = 0.0;
    for (final v in moving) {
      final d = v - mean;
      sumSq += d * d;
    }
    final variance = sumSq / moving.length; // population variance
    return math.sqrt(variance);
  }

  /// Convenience for callers that already have the wrapped trip
  /// entry — returns the score keyed by [TripHistoryEntry.id] so the
  /// engine's lookup maps line up with the iteration the provider
  /// performs.
  static MapEntry<String, int> scoreEntry(TripHistoryEntry entry) {
    return MapEntry(entry.id, drivingScore(entry.summary));
  }

  /// Signed percentage by which a trip's average consumption [tripAvg]
  /// (L/100 km) differs from the driver's synced efficient [baseline]
  /// (L/100 km) — `((tripAvg − baseline) / baseline) × 100` (#2696 C10).
  ///
  /// Positive = the trip burned MORE than the baseline (worse); negative =
  /// the trip beat the baseline (better). Returns null when no comparison
  /// is meaningful: a missing trip average, or a non-positive baseline
  /// (`baseline <= 0` — e.g. the driver has no learned baseline yet, so the
  /// caller shows nothing rather than a divide-by-zero or a fake 0 %).
  static double? consumptionDelta({
    required double? tripAvg,
    required double? baseline,
  }) {
    if (tripAvg == null || baseline == null || baseline <= 0) return null;
    return (tripAvg - baseline) / baseline * 100.0;
  }
}
