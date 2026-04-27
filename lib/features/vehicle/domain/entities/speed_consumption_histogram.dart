import 'package:freezed_annotation/freezed_annotation.dart';

part 'speed_consumption_histogram.freezed.dart';
part 'speed_consumption_histogram.g.dart';

/// One band in the speed-vs-consumption histogram.
///
/// A band is a half-open speed interval `[minKmh, maxKmh)` — the lower
/// bound is inclusive, the upper bound is exclusive. The top band's
/// upper bound is open-ended; model that case with `maxKmh == null`.
///
/// All numeric fields are required and non-nullable. "We have no data
/// for this band yet" is represented at the parent level — see
/// [SpeedConsumptionHistogram.bands] — by simply omitting the band
/// from the list, not by carrying zero values here.
@freezed
abstract class SpeedBand with _$SpeedBand {
  const factory SpeedBand({
    /// Lower bound of the band (km/h, inclusive).
    required int minKmh,

    /// Upper bound of the band (km/h, exclusive). `null` for the
    /// open-ended top band — speeds at or above [minKmh] without an
    /// upper cutoff (autobahn / motorway "everything else" tail).
    required int? maxKmh,

    /// Number of speed-consumption samples folded into this band.
    /// Aggregator-side this is the count of `TripDetailSample`s whose
    /// instantaneous speed fell inside the half-open interval; phase 2
    /// owns that classification.
    required int sampleCount,

    /// Mean fuel consumption across samples in this band, in litres
    /// per 100 km. Computed by the phase-2 aggregator from the stored
    /// totals; persisted directly so the UI doesn't have to re-derive.
    required double meanLPer100km,

    /// Fraction of total observed driving time that fell into this
    /// band, in `[0, 1]`. Across every band in a populated
    /// [SpeedConsumptionHistogram] the share rolls up to `1.0`
    /// (modulo float rounding). Useful for "you spend 40 % of your
    /// driving in 50–80 km/h" callouts on the vehicle profile screen.
    required double timeShareFraction,
  }) = _SpeedBand;

  factory SpeedBand.fromJson(Map<String, dynamic> json) =>
      _$SpeedBandFromJson(json);
}

/// Per-vehicle speed-vs-consumption histogram, used by the Carbon
/// dashboard chart and the vehicle-profile screen. Persisted on
/// [VehicleProfile] as part of #1193's rolling aggregates.
///
/// An empty [bands] list is the cold-start signal — "we have no data
/// yet". A populated histogram holds at most one [SpeedBand] per
/// `(minKmh, maxKmh)` template entry from
/// [standardBandTemplate]; bands the vehicle has never driven in are
/// simply omitted from the list rather than carrying zero values.
///
/// The aggregator (#1193 phase 2) seeds new histograms from
/// [standardBandTemplate]. Phase 1 only defines the shape and the
/// canonical layout — the template is intentionally a static `const`
/// list rather than a `factory` so the boundaries are visible in code
/// review without running the aggregator.
@freezed
abstract class SpeedConsumptionHistogram with _$SpeedConsumptionHistogram {
  const factory SpeedConsumptionHistogram({
    @Default(<SpeedBand>[]) List<SpeedBand> bands,
  }) = _SpeedConsumptionHistogram;

  factory SpeedConsumptionHistogram.fromJson(Map<String, dynamic> json) =>
      _$SpeedConsumptionHistogramFromJson(json);

  /// Canonical band layout used by the phase-2 aggregator when seeding
  /// a new histogram. Each tuple is `(minKmh, maxKmh?)`; the final
  /// band's `maxKmh` is `null` to mark the open-ended top tail.
  ///
  ///   * `0–30`    — urban crawl, idle, low-speed manoeuvring.
  ///   * `30–50`   — typical urban cruise.
  ///   * `50–80`   — extra-urban / fast town roads.
  ///   * `80–110`  — secondary-road / national-route cruise.
  ///   * `110+`    — motorway / autobahn cruise (open-ended).
  ///
  /// Stored as `List<(int, int?)>` so a Dart-3 records iteration
  /// reads naturally on the consumer side without an extra helper
  /// type. If the layout ever needs to change, bumping this list
  /// is a recompute trigger — older persisted histograms can keep
  /// their bands; the aggregator emits the new bands on the next
  /// pass.
  static const List<(int, int?)> standardBandTemplate = <(int, int?)>[
    (0, 30),
    (30, 50),
    (50, 80),
    (80, 110),
    (110, null),
  ];
}
