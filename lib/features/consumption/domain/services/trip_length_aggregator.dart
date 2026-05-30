// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Trip-length consumption aggregator (#1191).
///
/// Folds a list of [TripHistoryEntry]s into three fixed length buckets
/// — short (<5 km), medium (5-25 km), long (>25 km) — and returns the
/// per-bucket trip count, total distance, total litres, and average
/// L/100 km. The Carbon dashboard's Charts tab renders these as three
/// horizontally-stacked tiles so the user can see whether their car is
/// wasting fuel on cold short hops vs. cruising on long voyages.
///
/// Why fixed cuts instead of quantiles: a typical European combustion
/// engine reaches operating temperature around 5 km, and at 25 km the
/// warm-up effect is fully amortised over the trip. Quantile-based
/// bucketing would shift over time and confuse users — fixed cuts make
/// the breakdown comparable across users and over months.
///
/// Boundary convention: the upper edge belongs to the upper-side
/// bucket. A 5.0 km trip falls in MEDIUM, a 25.0 km trip falls in
/// MEDIUM, a 25.01 km trip falls in LONG. Strict `<` on the lower
/// bucket and `>` on the upper bucket — the middle bucket is
/// `[5.0, 25.0]` inclusive on both sides.
///
/// Trip filtering:
///   * When `vehicleId` is non-null, only trips whose
///     `entry.vehicleId == vehicleId` (exact match) AND trips whose
///     `entry.vehicleId == null` (legacy data tagging) are included.
///     Mirrors the convention used by `trajets_tab.dart` line 110-112.
///   * A trip's litres come from the canonical [tripConsumedLitersOrNull]
///     (#2447): the measured `fuelLitersConsumed` if present, else the
///     GPS-physics estimate recovered from `avgLPer100Km × distanceKm`.
///     Only trips with NEITHER (honest "no data") are dropped from the
///     bucket totals — silently treating them as 0 would skew the
///     average. This is the same source of truth the monthly card and
///     the reconciliation basis use, so the trajets surfaces agree.
///
/// Pure function — no Riverpod, no I/O. Mirrors the style of
/// `monthly_insights_aggregator.dart` in the same directory.
library;

import '../../data/trip_history_repository.dart';
import 'trip_consumed_liters.dart';

/// Upper edge of the SHORT bucket, in kilometres. Trips with
/// `distanceKm < this` fall in [TripLengthBreakdown.short]. Re-exported
/// so widget tests can verify the boundary value from one source.
const double tripLengthShortUpperKm = 5.0;

/// Upper edge of the MEDIUM bucket, in kilometres. Trips with
/// `distanceKm > this` fall in [TripLengthBreakdown.long]; trips with
/// `distanceKm <= this` (and `>= tripLengthShortUpperKm`) fall in
/// [TripLengthBreakdown.medium]. The boundary is inclusive on the upper
/// side per the spec — a 25.0 km trip is still MEDIUM.
const double tripLengthMediumUpperKm = 25.0;

/// Per-bucket aggregate. Value type, no side effects.
class TripLengthBucketStats {
  /// Number of trips that landed in this bucket and contributed to
  /// the totals (i.e. had both a non-null `distanceKm` and non-null
  /// `fuelLitersConsumed`). Trips dropped for missing fields are not
  /// counted here.
  final int tripCount;

  /// Sum of `summary.distanceKm` across the bucket's qualifying trips.
  /// Zero when [tripCount] is zero.
  final double totalDistanceKm;

  /// Sum of the canonical [tripConsumedLitersOrNull] (#2447 — measured
  /// litres, else the GPS estimate) across the bucket's qualifying
  /// trips. Zero when [tripCount] is zero.
  final double totalLitres;

  /// `(totalLitres / totalDistanceKm) × 100`. Null when [tripCount] is
  /// zero — averaging zero litres over zero km is undefined and the UI
  /// renders a placeholder in that case.
  final double? avgLPer100Km;

  const TripLengthBucketStats({
    required this.tripCount,
    required this.totalDistanceKm,
    required this.totalLitres,
    required this.avgLPer100Km,
  });

  /// Empty bucket — used as the default when no qualifying trip lands
  /// here. `tripCount == 0`, all numeric totals zero, average null.
  static const TripLengthBucketStats empty = TripLengthBucketStats(
    tripCount: 0,
    totalDistanceKm: 0,
    totalLitres: 0,
    avgLPer100Km: null,
  );
}

/// Result of [aggregateByTripLength] — the three buckets in fixed
/// order. Value type; consumers render directly.
class TripLengthBreakdown {
  /// Trips with `distanceKm < tripLengthShortUpperKm` (cold-engine
  /// territory).
  final TripLengthBucketStats short;

  /// Trips with `distanceKm` in `[tripLengthShortUpperKm,
  /// tripLengthMediumUpperKm]` (engine warm, mostly urban / mixed).
  final TripLengthBucketStats medium;

  /// Trips with `distanceKm > tripLengthMediumUpperKm` (stable-
  /// temperature cruising).
  final TripLengthBucketStats long;

  const TripLengthBreakdown({
    required this.short,
    required this.medium,
    required this.long,
  });

  /// All-empty breakdown — every bucket has `tripCount == 0`. Returned
  /// when the input trip list is empty (or every trip was filtered
  /// out / dropped for missing fields).
  static const TripLengthBreakdown empty = TripLengthBreakdown(
    short: TripLengthBucketStats.empty,
    medium: TripLengthBucketStats.empty,
    long: TripLengthBucketStats.empty,
  );

  /// True when every bucket has zero trips. The dashboard hides the
  /// card entirely when this is true so an empty 3-tile row doesn't
  /// waste vertical space.
  bool get isEmpty =>
      short.tripCount == 0 && medium.tripCount == 0 && long.tripCount == 0;
}

/// Fold the [trips] iterable into a three-bucket [TripLengthBreakdown].
///
/// When [vehicleId] is non-null, the function only considers trips
/// whose `summary.vehicleId == vehicleId` AND legacy trips whose
/// `summary.vehicleId == null` (matching the Trajets tab convention).
/// When null, every trip in [trips] is considered.
///
/// A trip's litres come from the canonical [tripConsumedLitersOrNull]
/// (#2447) — measured litres, else the GPS estimate. Only trips with
/// neither (honest "no data") are skipped; the average is undefined
/// without litres. (`summary.distanceKm` is non-nullable on the model.)
TripLengthBreakdown aggregateByTripLength(
  Iterable<TripHistoryEntry> trips, {
  String? vehicleId,
}) {
  final shortBucket = _Bucket();
  final mediumBucket = _Bucket();
  final longBucket = _Bucket();

  for (final entry in trips) {
    if (vehicleId != null &&
        entry.vehicleId != null &&
        entry.vehicleId != vehicleId) {
      continue;
    }

    final distanceKm = entry.summary.distanceKm;
    // #2447 — canonical trip litres: a null-fuel trip that still carries
    // a GPS estimate (avgLPer100Km) now contributes that estimate instead
    // of being dropped, so this surface agrees with the monthly card and
    // the reconciliation basis. Trips with NEITHER litres NOR an estimate
    // remain "no data" and are still skipped (honest, not zero-filled).
    final litres = tripConsumedLitersOrNull(entry.summary);
    if (litres == null) continue;
    // distanceKm is non-nullable on TripSummary; a 0 km trip is rare
    // (synthetic test data) but folds cleanly into the SHORT bucket.

    final bucket = _bucketFor(distanceKm);
    switch (bucket) {
      case _BucketKind.shortB:
        shortBucket.add(distanceKm, litres);
      case _BucketKind.mediumB:
        mediumBucket.add(distanceKm, litres);
      case _BucketKind.longB:
        longBucket.add(distanceKm, litres);
    }
  }

  return TripLengthBreakdown(
    short: shortBucket.toStats(),
    medium: mediumBucket.toStats(),
    long: longBucket.toStats(),
  );
}

/// Pick the bucket for [distanceKm]. See the boundary convention in the
/// library docstring — the short bucket is strict `<5`, medium is
/// `[5, 25]` inclusive on both sides, long is strict `>25`.
_BucketKind _bucketFor(double distanceKm) {
  if (distanceKm < tripLengthShortUpperKm) return _BucketKind.shortB;
  if (distanceKm > tripLengthMediumUpperKm) return _BucketKind.longB;
  return _BucketKind.mediumB;
}

enum _BucketKind { shortB, mediumB, longB }

/// Mutable accumulator. Public surface is the immutable
/// [TripLengthBucketStats] produced by [toStats].
class _Bucket {
  int tripCount = 0;
  double totalDistanceKm = 0;
  double totalLitres = 0;

  void add(double distanceKm, double litres) {
    tripCount++;
    totalDistanceKm += distanceKm;
    totalLitres += litres;
  }

  TripLengthBucketStats toStats() {
    if (tripCount == 0) return TripLengthBucketStats.empty;
    final avg = totalDistanceKm > 0
        ? (totalLitres / totalDistanceKm) * 100.0
        : null;
    return TripLengthBucketStats(
      tripCount: tripCount,
      totalDistanceKm: totalDistanceKm,
      totalLitres: totalLitres,
      avgLPer100Km: avg,
    );
  }
}
