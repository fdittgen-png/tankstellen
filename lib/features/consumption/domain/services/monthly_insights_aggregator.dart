/// "This month vs last month" aggregator for the Trajets tab landing
/// screen (#1041 phase 4 — Aggregates surface).
///
/// Given the persisted [TripHistoryEntry] list, group every trip into
/// the current calendar month, the previous calendar month, or
/// older-than-previous (ignored), then derive four headline metrics
/// per bucket:
///   * trip count
///   * total drive time (wall-clock from `startedAt` -> `endedAt`)
///   * total distance (sample-integrated when samples exist; else
///     `summary.distanceKm` if non-null; else 0 + dropped from the
///     consumption average)
///   * average L/100 km (fuel litres summed from `fuelRateLPerHour`
///     samples / total distance × 100). Returns null when distance
///     stays under [_minDistanceForConsumptionKm] — the noise floor
///     below which "average consumption" is misleading.
///
/// Trips with empty samples STILL count for trip-count + drive-time
/// (those metrics come from the wall-clock timestamps, which every
/// trip carries). They drop out of distance + consumption only.
///
/// The aggregator takes a `now` parameter so widget tests can pin a
/// deterministic month boundary; production callers should pass
/// `DateTime.now()`.
///
/// Reliability gate: `isComparisonReliable` is true ONLY when BOTH
/// months recorded at least [_minTripsForReliableComparison] trips.
/// Below that, the UI skips the delta arrows and only shows current
/// values — comparing against a single-trip baseline produces noise
/// the user shouldn't act on.
library;

import '../../data/trip_history_repository.dart';
import '../trip_recorder.dart';

/// Bands the aggregator considers "noise" for the consumption average.
/// Below 5 km a single coast or a long warm-up dominates the figure.
const double _minDistanceForConsumptionKm = 5.0;

/// Minimum trips per month before the deltas are surfaced. Three is the
/// smallest count where a week-over-week pattern is visible without
/// being one outlier away from a swing.
const int _minTripsForReliableComparison = 3;

/// Result of [aggregateMonthlyInsights] — value type, no side effects.
///
/// All `*Delta*` getters are derived from the raw fields; consumers
/// should never need to recompute them.
class MonthlyInsightsSummary {
  /// Number of trips whose `startedAt` lands in the current calendar
  /// month (same `(year, month)` as `now`). Trips without `startedAt`
  /// are dropped — we have no honest way to bucket them.
  final int currentMonthTripCount;
  final int previousMonthTripCount;

  /// Sum of `endedAt - startedAt` across the bucket's trips. Trips
  /// missing either timestamp contribute zero (rather than crash).
  final Duration currentMonthDriveTime;
  final Duration previousMonthDriveTime;

  /// Sample-integrated distance when samples exist; else
  /// `summary.distanceKm`; else 0. Trips that contribute 0 are dropped
  /// from the consumption average's denominator.
  final double currentMonthDistanceKm;
  final double previousMonthDistanceKm;

  /// `(litres / km) × 100`, summed over the bucket. Null when bucket
  /// distance is below [_minDistanceForConsumptionKm] (~5 km) —
  /// "average consumption" below that is dominated by warm-up burn
  /// and would mislead the comparison.
  final double? currentMonthAvgConsumptionLPer100km;
  final double? previousMonthAvgConsumptionLPer100km;

  /// True only if BOTH months recorded ≥ 3 trips. The card uses this
  /// to decide whether to render delta arrows or just current values.
  final bool isComparisonReliable;

  const MonthlyInsightsSummary({
    required this.currentMonthTripCount,
    required this.previousMonthTripCount,
    required this.currentMonthDriveTime,
    required this.previousMonthDriveTime,
    required this.currentMonthDistanceKm,
    required this.previousMonthDistanceKm,
    required this.currentMonthAvgConsumptionLPer100km,
    required this.previousMonthAvgConsumptionLPer100km,
    required this.isComparisonReliable,
  });

  /// All-zero / null summary used when the trip list is empty.
  static const MonthlyInsightsSummary empty = MonthlyInsightsSummary(
    currentMonthTripCount: 0,
    previousMonthTripCount: 0,
    currentMonthDriveTime: Duration.zero,
    previousMonthDriveTime: Duration.zero,
    currentMonthDistanceKm: 0,
    previousMonthDistanceKm: 0,
    currentMonthAvgConsumptionLPer100km: null,
    previousMonthAvgConsumptionLPer100km: null,
    isComparisonReliable: false,
  );

  /// Trip-count delta (current minus previous). Positive means the user
  /// drove more this month; the UI renders this as a neutral activity
  /// indicator (no good/bad colouring).
  int get tripCountDelta => currentMonthTripCount - previousMonthTripCount;

  /// Drive-time delta (current minus previous). Positive means more
  /// time behind the wheel — neutral activity indicator.
  Duration get driveTimeDelta => currentMonthDriveTime - previousMonthDriveTime;

  /// Distance delta (current minus previous), in km. Neutral activity
  /// indicator.
  double get distanceKmDelta =>
      currentMonthDistanceKm - previousMonthDistanceKm;

  /// Consumption delta (current minus previous), in L/100 km. Null
  /// when either month lacks a reliable consumption figure. NEGATIVE
  /// means consumption dropped (better); POSITIVE means it rose
  /// (worse). The sign convention is the opposite of [tripCountDelta]:
  /// "less" is good for fuel.
  double? get consumptionDeltaLPer100km {
    final c = currentMonthAvgConsumptionLPer100km;
    final p = previousMonthAvgConsumptionLPer100km;
    if (c == null || p == null) return null;
    return c - p;
  }

  /// True when the user burned LESS fuel per 100 km this month than
  /// last. False when consumption rose (or stayed equal). Null-safe:
  /// returns false when the delta is unknown — the UI shouldn't render
  /// a celebratory arrow on missing data.
  bool get consumptionImproved {
    final delta = consumptionDeltaLPer100km;
    if (delta == null) return false;
    return delta < 0;
  }
}

/// Fold a list of finalised trips into the current/previous month
/// breakdown. `now` controls which calendar month is "current" — pass
/// `DateTime.now()` in production; tests pin a fixed value so month
/// boundaries are deterministic.
///
/// Implementation walks the list once per metric so the cost stays
/// O(n × samples) — for the rolling 100-trip cap × ~2 000 samples each
/// this is well under a frame on the UI thread.
MonthlyInsightsSummary aggregateMonthlyInsights(
  List<TripHistoryEntry> trips,
  DateTime now,
) {
  if (trips.isEmpty) return MonthlyInsightsSummary.empty;

  final currentBucket = _MonthBucket();
  final previousBucket = _MonthBucket();

  final (prevYear, prevMonth) = _previousMonthOf(now.year, now.month);

  for (final entry in trips) {
    final startedAt = entry.summary.startedAt;
    if (startedAt == null) continue; // can't bucket without a start.

    final isCurrent =
        startedAt.year == now.year && startedAt.month == now.month;
    final isPrevious =
        startedAt.year == prevYear && startedAt.month == prevMonth;
    if (!isCurrent && !isPrevious) continue;

    final bucket = isCurrent ? currentBucket : previousBucket;
    bucket.tripCount++;

    // Drive time: wall-clock between startedAt and endedAt. Trips
    // whose endedAt is missing contribute zero — better than crashing
    // on a partial summary.
    final endedAt = entry.summary.endedAt;
    if (endedAt != null) {
      final delta = endedAt.difference(startedAt);
      if (delta > Duration.zero) {
        bucket.driveTime += delta;
      }
    }

    // Distance + consumption: prefer sample-integrated maths. Falls
    // back to summary.distanceKm if samples are empty — important for
    // legacy trips written before #1040 persisted samples.
    final samples = entry.samples;
    if (samples.isNotEmpty) {
      final (distanceKm, fuelLitres, hadFuelRate) =
          _integrateSamples(samples);
      bucket.distanceKm += distanceKm;
      if (hadFuelRate && distanceKm > 0) {
        bucket.fuelLitres += fuelLitres;
        bucket.consumptionDistanceKm += distanceKm;
      }
    } else {
      // No samples — use the persisted summary as-is. We cannot
      // compute a consumption average without per-tick fuel-rate
      // samples, so this trip drops out of the consumption denominator
      // even when summary.avgLPer100Km is set (mixing pre-aggregated
      // averages with per-sample sums would skew the result).
      bucket.distanceKm += entry.summary.distanceKm;
    }
  }

  final currentAvg = _avgConsumption(currentBucket);
  final previousAvg = _avgConsumption(previousBucket);

  final reliable = currentBucket.tripCount >= _minTripsForReliableComparison &&
      previousBucket.tripCount >= _minTripsForReliableComparison;

  return MonthlyInsightsSummary(
    currentMonthTripCount: currentBucket.tripCount,
    previousMonthTripCount: previousBucket.tripCount,
    currentMonthDriveTime: currentBucket.driveTime,
    previousMonthDriveTime: previousBucket.driveTime,
    currentMonthDistanceKm: currentBucket.distanceKm,
    previousMonthDistanceKm: previousBucket.distanceKm,
    currentMonthAvgConsumptionLPer100km: currentAvg,
    previousMonthAvgConsumptionLPer100km: previousAvg,
    isComparisonReliable: reliable,
  );
}

/// Walk the per-tick samples and return `(distanceKm, fuelLitres,
/// hadFuelRate)`. Mirrors `TripRecorder.onSample` so the per-trip
/// figures the user already sees on the trip detail screen line up
/// with the monthly aggregate (no parallel-implementation drift).
(double, double, bool) _integrateSamples(List<TripSample> samples) {
  if (samples.length < 2) return (0, 0, false);
  final sorted = [...samples]
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  double distanceKm = 0;
  double fuelLitres = 0;
  bool hadFuelRate = false;

  for (var i = 1; i < sorted.length; i++) {
    final prev = sorted[i - 1];
    final cur = sorted[i];
    final dt = cur.timestamp.difference(prev.timestamp).inMicroseconds /
        Duration.microsecondsPerSecond;
    if (dt <= 0) continue;

    final avgSpeedKmh = (prev.speedKmh + cur.speedKmh) / 2.0;
    distanceKm += avgSpeedKmh * dt / 3600.0;

    if (prev.fuelRateLPerHour != null && cur.fuelRateLPerHour != null) {
      final avgRate = (prev.fuelRateLPerHour! + cur.fuelRateLPerHour!) / 2.0;
      fuelLitres += avgRate * dt / 3600.0;
      hadFuelRate = true;
    }
  }

  return (distanceKm, fuelLitres, hadFuelRate);
}

/// Average L/100 km for a bucket. Null when the bucket's qualifying
/// distance is below the noise floor — averaging a litre over <5 km is
/// dominated by warm-up burn and would mislead the comparison.
double? _avgConsumption(_MonthBucket bucket) {
  if (bucket.consumptionDistanceKm < _minDistanceForConsumptionKm) return null;
  if (bucket.fuelLitres <= 0) return null;
  return bucket.fuelLitres / bucket.consumptionDistanceKm * 100.0;
}

/// `(year, month)` of the calendar month immediately before `(year,
/// month)`. Wraps January back to December of the prior year.
(int, int) _previousMonthOf(int year, int month) {
  if (month == 1) return (year - 1, 12);
  return (year, month - 1);
}

/// Mutable accumulator used by [aggregateMonthlyInsights]. Kept private
/// — the public surface is the immutable [MonthlyInsightsSummary].
class _MonthBucket {
  int tripCount = 0;
  Duration driveTime = Duration.zero;
  double distanceKm = 0;

  /// Litres burned across trips that had per-sample fuel rates. Used
  /// only as the numerator in the consumption average.
  double fuelLitres = 0;

  /// Distance contributed by trips that had per-sample fuel rates.
  /// Differs from [distanceKm] (which counts every trip) — the
  /// consumption average must divide by the same trips it summed.
  double consumptionDistanceKm = 0;
}
