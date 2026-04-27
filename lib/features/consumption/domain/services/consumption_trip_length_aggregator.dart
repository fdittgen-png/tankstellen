/// Carbon-dashboard "cold-start lens" aggregator (#1191).
///
/// Folds a list of [TripHistoryEntry] into three fixed buckets — short
/// (< 5 km), medium (5–25 km), long (>= 25 km) — and reports the
/// per-bucket trip count, total distance, total litres burned, and
/// average L/100 km. The carbon dashboard renders these on the Charts
/// tab so the user can see whether their fuel cost is concentrated on
/// cold-engine short hops or on long voyages.
///
/// IMPORTANT — naming separation from the vehicle/domain
/// `TripLengthBreakdown` class
/// (`lib/features/vehicle/domain/entities/trip_length_breakdown.dart`):
/// that one is a different lens (#1193) with cutoffs at 15 km / 50 km,
/// designed for rolling driving aggregates persisted on a vehicle
/// profile. This file is the cold-start carbon lens with cutoffs at
/// 5 km / 25 km. The two coexist by name (`Consumption*` prefix here)
/// so neither feature blocks the other.
///
/// Bucket cutoffs (cold-start lens):
///   * Short  — `distanceKm < 5.0`. Cold-engine territory.
///   * Medium — `5.0 <= distanceKm < 25.0`. Engine warm, urban / mixed.
///   * Long   — `25.0 <= distanceKm`. Stable-temperature cruising.
///
/// Boundary inclusivity is tested in the unit suite: 5.0 km belongs to
/// medium (the lower bound is inclusive), and 25.0 km belongs to long
/// (the lower bound is inclusive).
///
/// Trip filtering rules:
///   * `fuelLitersConsumed == null` — excluded entirely. The trip
///     carries no per-sample fuel-rate signal, so it cannot contribute
///     to L/100 km. Mirrors the same rule in
///     `monthly_insights_aggregator.dart`.
///   * `distanceKm <= 0` — excluded entirely. A zero-distance trip
///     would either crash the L/100 km divide or contribute a degenerate
///     denominator; in either case it is no signal.
///   * `vehicleId != filterVehicleId` — excluded when [vehicleId] is
///     set on the call. When [vehicleId] is null, every vehicle is
///     considered; this is also how the dashboard renders the
///     "all vehicles" mode if no profile is active.
///
/// The aggregator is a pure top-level function with no Riverpod / I/O
/// dependency, mirroring the style of
/// `lib/features/consumption/domain/services/monthly_insights_aggregator.dart`.
library;

import '../../data/trip_history_repository.dart';

/// Inclusive lower bound of the medium bucket — trips with
/// `distanceKm < 5.0` go into [ConsumptionTripLengthBreakdown.short].
const double kConsumptionTripLengthShortMaxKm = 5.0;

/// Inclusive lower bound of the long bucket — trips with
/// `5.0 <= distanceKm < 25.0` go into
/// [ConsumptionTripLengthBreakdown.medium]; everything from 25.0 km
/// up is [ConsumptionTripLengthBreakdown.long].
const double kConsumptionTripLengthMediumMaxKm = 25.0;

/// Per-bucket roll-up returned inside [ConsumptionTripLengthBreakdown].
///
/// Value type — immutable, equality by field. The card widget keys on
/// the bucket label (Short / Medium / Long) and reads these stats
/// directly; nothing else owns this shape.
class ConsumptionTripLengthBucketStats {
  /// Number of qualifying trips folded into this bucket.
  final int tripCount;

  /// Sum of `summary.distanceKm` across the bucket's trips, in km.
  final double totalDistanceKm;

  /// Sum of `summary.fuelLitersConsumed` across the bucket's trips, in
  /// litres. Trips with a null `fuelLitersConsumed` were excluded
  /// upstream, so this is always a real sum (never partially null).
  final double totalLitres;

  /// `(totalLitres / totalDistanceKm) * 100` when the bucket has at
  /// least one qualifying trip; null when [tripCount] is zero.
  /// Formatted to one decimal in the UI.
  final double? avgLPer100Km;

  const ConsumptionTripLengthBucketStats({
    required this.tripCount,
    required this.totalDistanceKm,
    required this.totalLitres,
    required this.avgLPer100Km,
  });

  /// All-zero / null bucket — used when no trip lands in this bucket.
  static const ConsumptionTripLengthBucketStats empty =
      ConsumptionTripLengthBucketStats(
    tripCount: 0,
    totalDistanceKm: 0,
    totalLitres: 0,
    avgLPer100Km: null,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConsumptionTripLengthBucketStats &&
        other.tripCount == tripCount &&
        other.totalDistanceKm == totalDistanceKm &&
        other.totalLitres == totalLitres &&
        other.avgLPer100Km == avgLPer100Km;
  }

  @override
  int get hashCode => Object.hash(
        tripCount,
        totalDistanceKm,
        totalLitres,
        avgLPer100Km,
      );

  @override
  String toString() =>
      'ConsumptionTripLengthBucketStats(tripCount: $tripCount, '
      'totalDistanceKm: $totalDistanceKm, totalLitres: $totalLitres, '
      'avgLPer100Km: $avgLPer100Km)';
}

/// Three-bucket roll-up of consumption by trip length — the Carbon
/// dashboard's cold-start lens (#1191). See file-level docs for the
/// cutoff rationale and the naming-separation note from the vehicle
/// `TripLengthBreakdown`.
class ConsumptionTripLengthBreakdown {
  /// Short bucket — `distanceKm < 5 km`.
  final ConsumptionTripLengthBucketStats short;

  /// Medium bucket — `5 km <= distanceKm < 25 km`.
  final ConsumptionTripLengthBucketStats medium;

  /// Long bucket — `25 km <= distanceKm`.
  final ConsumptionTripLengthBucketStats long;

  /// Vehicle-wide L/100 km derived from the same filtered trip set.
  /// Null when no trip qualified (every bucket has tripCount == 0).
  /// The card uses this as the comparison anchor: each bucket's
  /// avg L/100 km is rendered as above-/below-average against this.
  /// Computing it here (alongside the per-bucket sums) means the
  /// widget never has to walk the trip list a second time.
  final double? overallAvgLPer100Km;

  const ConsumptionTripLengthBreakdown({
    required this.short,
    required this.medium,
    required this.long,
    required this.overallAvgLPer100Km,
  });

  /// All-empty breakdown — returned when the trip list is empty or
  /// when no trip survives the qualifying filter.
  static const ConsumptionTripLengthBreakdown empty =
      ConsumptionTripLengthBreakdown(
    short: ConsumptionTripLengthBucketStats.empty,
    medium: ConsumptionTripLengthBucketStats.empty,
    long: ConsumptionTripLengthBucketStats.empty,
    overallAvgLPer100Km: null,
  );

  /// `true` when no bucket has any data — the card uses this to hide
  /// itself entirely instead of rendering three empty tiles.
  bool get isEmpty =>
      short.tripCount == 0 && medium.tripCount == 0 && long.tripCount == 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConsumptionTripLengthBreakdown &&
        other.short == short &&
        other.medium == medium &&
        other.long == long &&
        other.overallAvgLPer100Km == overallAvgLPer100Km;
  }

  @override
  int get hashCode => Object.hash(short, medium, long, overallAvgLPer100Km);
}

/// Fold [trips] into the three trip-length buckets used by the Carbon
/// dashboard's Charts tab (#1191).
///
/// When [vehicleId] is non-null, every trip whose `vehicleId` does not
/// match is dropped before bucketing. When [vehicleId] is null, every
/// trip is considered — useful for an "all vehicles" view.
///
/// Trips are dropped from every bucket when:
///   * `summary.fuelLitersConsumed == null` (no per-sample fuel rate),
///   * `summary.distanceKm <= 0` (would skew the L/100 km divide).
///
/// Returns [ConsumptionTripLengthBreakdown.empty] when no trip
/// qualifies. The function walks the trip list exactly once; cost is
/// O(n) regardless of bucket distribution.
ConsumptionTripLengthBreakdown aggregateConsumptionByTripLength(
  Iterable<TripHistoryEntry> trips, {
  String? vehicleId,
}) {
  final shortAcc = _BucketAcc();
  final mediumAcc = _BucketAcc();
  final longAcc = _BucketAcc();

  for (final entry in trips) {
    if (vehicleId != null && entry.vehicleId != vehicleId) continue;

    final summary = entry.summary;
    final litres = summary.fuelLitersConsumed;
    if (litres == null) continue; // no fuel-rate signal — excluded.

    final distance = summary.distanceKm;
    if (distance <= 0) continue; // degenerate denominator — excluded.

    final acc = _bucketFor(distance, shortAcc, mediumAcc, longAcc);
    acc.tripCount += 1;
    acc.totalDistanceKm += distance;
    acc.totalLitres += litres;
  }

  // Overall avg uses the union of all qualifying trips — same numerator
  // / denominator that produced the buckets.
  final totalLitres =
      shortAcc.totalLitres + mediumAcc.totalLitres + longAcc.totalLitres;
  final totalDistanceKm = shortAcc.totalDistanceKm +
      mediumAcc.totalDistanceKm +
      longAcc.totalDistanceKm;
  final overallAvg =
      totalDistanceKm > 0 ? (totalLitres / totalDistanceKm) * 100.0 : null;

  return ConsumptionTripLengthBreakdown(
    short: shortAcc.toStats(),
    medium: mediumAcc.toStats(),
    long: longAcc.toStats(),
    overallAvgLPer100Km: overallAvg,
  );
}

_BucketAcc _bucketFor(
  double distanceKm,
  _BucketAcc shortAcc,
  _BucketAcc mediumAcc,
  _BucketAcc longAcc,
) {
  if (distanceKm < kConsumptionTripLengthShortMaxKm) return shortAcc;
  if (distanceKm < kConsumptionTripLengthMediumMaxKm) return mediumAcc;
  return longAcc;
}

/// Mutable accumulator — public surface is the immutable
/// [ConsumptionTripLengthBucketStats] returned by [toStats].
class _BucketAcc {
  int tripCount = 0;
  double totalDistanceKm = 0;
  double totalLitres = 0;

  ConsumptionTripLengthBucketStats toStats() {
    if (tripCount == 0) return ConsumptionTripLengthBucketStats.empty;
    final avg = totalDistanceKm > 0
        ? (totalLitres / totalDistanceKm) * 100.0
        : null;
    return ConsumptionTripLengthBucketStats(
      tripCount: tripCount,
      totalDistanceKm: totalDistanceKm,
      totalLitres: totalLitres,
      avgLPer100Km: avg,
    );
  }
}
