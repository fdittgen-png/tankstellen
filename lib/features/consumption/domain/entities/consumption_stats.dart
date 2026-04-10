import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/services/co2_calculator.dart';
import 'fill_up.dart';

part 'consumption_stats.freezed.dart';

/// Aggregated statistics computed from a list of [FillUp] entries.
///
/// All values may be `null` when insufficient data is present (e.g. fewer
/// than two fill-ups prevent consumption calculation, since distance
/// requires odometer deltas).
@freezed
abstract class ConsumptionStats with _$ConsumptionStats {
  const ConsumptionStats._();

  const factory ConsumptionStats({
    required int fillUpCount,
    required double totalLiters,
    required double totalSpent,
    required double totalDistanceKm,
    @Default(0) double totalCo2Kg,
    double? avgConsumptionL100km,
    double? avgCostPerKm,
    double? avgPricePerLiter,
    double? avgCo2PerKm,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) = _ConsumptionStats;

  /// Empty stats for when there are no fill-ups.
  static const empty = ConsumptionStats(
    fillUpCount: 0,
    totalLiters: 0,
    totalSpent: 0,
    totalDistanceKm: 0,
    totalCo2Kg: 0,
  );

  /// Compute aggregated stats from a list of fill-ups.
  ///
  /// Consumption is computed using the classic "fill-to-fill" method:
  /// liters of a given tank divided by the distance driven since the
  /// previous fill-up. The very first fill-up is excluded from the
  /// consumption average because its prior distance is unknown.
  factory ConsumptionStats.fromFillUps(List<FillUp> fillUps) {
    if (fillUps.isEmpty) return empty;

    // Work on an immutable, chronologically-ordered copy so callers may
    // pass data in any order.
    final sorted = [...fillUps]..sort((a, b) => a.date.compareTo(b.date));

    final totalLiters =
        sorted.fold<double>(0, (sum, f) => sum + f.liters);
    final totalSpent =
        sorted.fold<double>(0, (sum, f) => sum + f.totalCost);
    final totalCo2 = Co2Calculator.cumulativeCo2(sorted);

    final firstOdo = sorted.first.odometerKm;
    final lastOdo = sorted.last.odometerKm;
    final totalDistance =
        (lastOdo - firstOdo).clamp(0, double.infinity).toDouble();

    double? avgL100;
    double? avgCostKm;
    double? avgCo2Km;
    if (sorted.length >= 2 && totalDistance > 0) {
      // Liters used between first and last fill-up — exclude the first
      // tank since its prior distance is unknown.
      final litersBetween = sorted
          .skip(1)
          .fold<double>(0, (sum, f) => sum + f.liters);
      avgL100 = (litersBetween / totalDistance) * 100;

      final costBetween = sorted
          .skip(1)
          .fold<double>(0, (sum, f) => sum + f.totalCost);
      avgCostKm = costBetween / totalDistance;

      // CO2 per km — also excludes the first tank for the same reason.
      final co2Between = Co2Calculator.cumulativeCo2(sorted.skip(1).toList());
      if (co2Between > 0) {
        avgCo2Km = co2Between / totalDistance;
      }
    }

    final avgPriceLiter = totalLiters > 0 ? totalSpent / totalLiters : null;

    return ConsumptionStats(
      fillUpCount: sorted.length,
      totalLiters: totalLiters,
      totalSpent: totalSpent,
      totalDistanceKm: totalDistance,
      totalCo2Kg: totalCo2,
      avgConsumptionL100km: avgL100,
      avgCostPerKm: avgCostKm,
      avgPricePerLiter: avgPriceLiter,
      avgCo2PerKm: avgCo2Km,
      periodStart: sorted.first.date,
      periodEnd: sorted.last.date,
    );
  }
}
