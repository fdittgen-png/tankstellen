/// Direction the current fill-up moved relative to the rolling baseline.
///
/// Used on the fill-up card as a single glance cue: did I drive more
/// economically this tank, or less?
enum EcoScoreDirection {
  /// Current fill-up consumed meaningfully less fuel per 100 km than
  /// the rolling average. Rendered in green.
  improving,

  /// Change is within noise (±3 %). Rendered neutrally.
  stable,

  /// Current fill-up consumed meaningfully more. Rendered in amber.
  worsening,
}

/// Per-fill-up consumption score — "how economically did I drive this
/// tank?"
///
/// A small value-object exposing:
///
/// - [litersPer100Km] — consumption for the current fill-up alone.
/// - [rollingAverage] — the baseline it's compared against (mean of the
///   previous N fill-ups of the SAME fuel type on the same vehicle).
/// - [deltaPercent] — `(current - rolling) / rolling * 100`.
///   Negative = better than baseline, positive = worse.
/// - [direction] — discretised from [deltaPercent] via [threshold].
///
/// Returned by [EcoScoreCalculator.compute]. `null` return means the
/// score is not meaningful yet (first-ever fill-up, odometer rollback,
/// too little history).
class EcoScore {
  /// Change in percent beyond which the direction leaves [stable].
  /// Chosen so a hot summer week or a single highway detour doesn't
  /// push a conscientious driver into the amber bucket.
  static const double threshold = 3.0;

  final double litersPer100Km;
  final double rollingAverage;
  final double deltaPercent;
  final EcoScoreDirection direction;

  const EcoScore({
    required this.litersPer100Km,
    required this.rollingAverage,
    required this.deltaPercent,
    required this.direction,
  });
}
