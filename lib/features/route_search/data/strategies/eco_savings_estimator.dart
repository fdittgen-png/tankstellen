/// Estimated litres saved by picking the eco route over the fastest.
///
/// Simple model: distance × consumption_baseline_lPer100km / 100,
/// adjusted by the eco route's expected efficiency uplift relative
/// to the fastest. We assume the eco route burns
/// `1 / (1 + ecoEfficiencyLift)` as much per km as the fastest —
/// `0.07` (7 % less) is a defensible default for a steady-cruise
/// vs zigzag delta on a typical European motorway+B-road mix.
///
/// Returns 0.0 when either route is empty or the math underflows.
class EcoSavingsEstimator {
  /// Default consumption (L / 100 km) when the user hasn't set a
  /// vehicle baseline. 7 L is roughly the EU fleet average for
  /// petrol passenger cars (EEA 2023). Diesel users will see a
  /// slight over-estimate — fine for a UI hint.
  static const double defaultConsumptionLPer100km = 7.0;

  /// Eco route burns `1 / (1 + lift)` × the fastest route's per-km
  /// consumption. 7 % is a conservative midpoint of the
  /// 5–10 % range reported by EU eco-driving studies for steady
  /// cruise vs aggressive variable-speed driving.
  static const double ecoEfficiencyLift = 0.07;

  /// Compute estimated litres saved by switching from [fastest] to
  /// [eco]. Both arguments are total-route distances in km +
  /// total-route durations in minutes; consumption is L/100 km.
  ///
  /// Returns a non-negative value (clamped at 0) — if the model
  /// somehow predicts the eco route burns *more*, we hide the
  /// preview rather than scare the user.
  static double estimateLitersSaved({
    required double fastestDistanceKm,
    required double ecoDistanceKm,
    required double consumptionLPer100km,
  }) {
    if (fastestDistanceKm <= 0 || ecoDistanceKm <= 0) return 0.0;
    if (consumptionLPer100km <= 0) return 0.0;
    final fastestL = fastestDistanceKm * consumptionLPer100km / 100.0;
    final ecoConsumption =
        consumptionLPer100km / (1.0 + ecoEfficiencyLift);
    final ecoL = ecoDistanceKm * ecoConsumption / 100.0;
    final delta = fastestL - ecoL;
    return delta > 0 ? delta : 0.0;
  }
}
