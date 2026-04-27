import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_length_breakdown.freezed.dart';
part 'trip_length_breakdown.g.dart';

/// Per-bucket consumption stats for a single trip-length classification
/// (short / medium / long). Persisted on [VehicleProfile] as part of
/// the rolling driving aggregates introduced by #1193.
///
/// All fields are required and non-nullable — the absence of data is
/// signalled by the parent [TripLengthBreakdown] holding `null` for the
/// bucket itself, NOT by the bucket carrying zero/empty values. That
/// keeps "zero trips so far" distinct from "we have N trips and they
/// happen to total 0 km" (the latter shouldn't happen, but the former
/// is the common cold-start case).
///
/// Pure value object — no behaviour, no aggregation logic. The fold
/// pass that produces these instances lives in
/// `lib/features/vehicle/data/vehicle_aggregate_updater.dart`
/// (#1193 phase 2).
@freezed
abstract class TripLengthBucket with _$TripLengthBucket {
  const factory TripLengthBucket({
    /// Number of completed trips folded into this bucket.
    required int tripCount,

    /// Mean fuel consumption across the bucket, in litres per 100 km.
    /// Aggregator-side this is computed as `totalLitres / totalDistanceKm * 100`,
    /// or via Welford-style incremental update when folding a single trip
    /// into the existing bucket — phase 2 owns that math.
    required double meanLPer100km,

    /// Sum of distance (km) across every trip in this bucket. Useful
    /// for the UI "you drove X km on long trips this month" line and
    /// as the denominator if a consumer needs to recompute the mean
    /// at higher precision than [meanLPer100km] preserved.
    required double totalDistanceKm,

    /// Sum of fuel used (litres) across every trip in this bucket.
    /// Same role as [totalDistanceKm] — kept so the mean can be
    /// rederived without information loss.
    required double totalLitres,
  }) = _TripLengthBucket;

  factory TripLengthBucket.fromJson(Map<String, dynamic> json) =>
      _$TripLengthBucketFromJson(json);
}

/// Trip-length breakdown of a vehicle's rolling consumption stats.
///
/// Each of [short], [medium], [long] is independently nullable because
/// a vehicle may have enough trips in one bucket but not the other —
/// e.g. a city-only car will populate [short] long before [medium] /
/// [long] cross the per-bucket min-sample threshold. A `null` bucket
/// means "no data yet"; a populated bucket with a low [TripLengthBucket.tripCount]
/// is data the UI can choose to surface with a confidence caveat.
///
/// Bucket cutoffs (documented here, instantiated phase 2):
///
///   * Short  — distance < [shortMaxKm] km.
///   * Medium — [shortMaxKm] km <= distance < [mediumMaxKm] km.
///   * Long   — distance >= [mediumMaxKm] km.
///
/// The cutoffs are intentionally NOT baked into a method on this value
/// object — the classifier belongs in
/// `vehicle_aggregate_updater.dart` (#1193 phase 2) where it can evolve
/// independently of the persisted shape. Phase 1 only defines the
/// schema and exposes the constants for the aggregator to read.
@freezed
abstract class TripLengthBreakdown with _$TripLengthBreakdown {
  const factory TripLengthBreakdown({
    TripLengthBucket? short,
    TripLengthBucket? medium,
    TripLengthBucket? long,
  }) = _TripLengthBreakdown;

  factory TripLengthBreakdown.fromJson(Map<String, dynamic> json) =>
      _$TripLengthBreakdownFromJson(json);

  /// Upper bound (exclusive) of the "short" bucket, in kilometres.
  /// Trips with `distanceKm < shortMaxKm` go into [short].
  static const double shortMaxKm = 15;

  /// Upper bound (exclusive) of the "medium" bucket, in kilometres.
  /// Trips with `shortMaxKm <= distanceKm < mediumMaxKm` go into
  /// [medium]; everything from [mediumMaxKm] km up is [long].
  static const double mediumMaxKm = 50;
}
