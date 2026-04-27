import 'dart:math' as math;

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
///   * [tripDrivingScore] — 0-100 composite from the [TripSummary]
///     fields (idle ratio, high-RPM ratio, harsh events). Mirrors the
///     "driving score" envisaged in #1041 Card A; shipped here so the
///     achievement rules have something concrete to threshold even
///     before Card A's UI lands.
///   * [tripColdStartExcessLiters] — best-effort estimate of the
///     fuel a trip burned above its own steady-state baseline during
///     the first few minutes. Used to evaluate the
///     `coldStartAware` badge on a per-month aggregate.
///   * [tripSpeedStdDev] — std-dev of non-idle speed samples,
///     used by the `highwayMaster` rule.
class TripMetrics {
  TripMetrics._();

  /// Floor / ceiling for the score so a single insane reading doesn't
  /// blow it up beyond what a user can interpret.
  static const int _scoreMin = 0;
  static const int _scoreMax = 100;

  /// Idle-ratio penalty cap (points). 30% of the score budget.
  static const double _idlePenaltyCap = 30.0;

  /// High-RPM-ratio penalty cap (points). 25% of the score budget.
  static const double _highRpmPenaltyCap = 25.0;

  /// Per-event harsh-driving penalty (points). Brakes and accels
  /// each. Capped at 25 points combined so one rough trip can still
  /// score in the mid-30s rather than 0.
  static const double _harshEventPenalty = 5.0;
  static const double _harshPenaltyCap = 25.0;

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

  /// Compute a 0-100 driving score for a single trip from its
  /// summary fields. Higher is better. The formula intentionally
  /// uses only [TripSummary] (no per-sample scan) so it is cheap
  /// even on long trips and works for legacy trips that do not have
  /// per-sample data.
  ///
  /// Trips shorter than 1 minute return 100 — there is not enough
  /// data to penalise driver behaviour. Trips with no duration
  /// (missing `startedAt`/`endedAt`) also return 100.
  static int drivingScore(TripSummary summary) {
    final start = summary.startedAt;
    final end = summary.endedAt;
    final durationSeconds = (start != null && end != null)
        ? end.difference(start).inSeconds.toDouble()
        : 0.0;
    if (durationSeconds <= 60) return _scoreMax;

    final idleRatio = (summary.idleSeconds / durationSeconds).clamp(0.0, 1.0);
    final highRpmRatio =
        (summary.highRpmSeconds / durationSeconds).clamp(0.0, 1.0);

    final idlePenalty = idleRatio * _idlePenaltyCap;
    final rpmPenalty = highRpmRatio * _highRpmPenaltyCap;

    final harshEvents = summary.harshBrakes + summary.harshAccelerations;
    final harshPenalty = math.min(
      harshEvents * _harshEventPenalty,
      _harshPenaltyCap,
    );

    final raw = _scoreMax - idlePenalty - rpmPenalty - harshPenalty;
    return raw.clamp(_scoreMin.toDouble(), _scoreMax.toDouble()).round();
  }

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
    final mean = moving.reduce((a, b) => a + b) / moving.length;
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
}
