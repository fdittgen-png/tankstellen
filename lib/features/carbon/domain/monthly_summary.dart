import '../../../core/services/co2_calculator.dart';
import '../../consumption/domain/entities/fill_up.dart';

/// Aggregated totals for a single calendar month.
///
/// All fields are in SI / market units: cost in the user's currency
/// (no FX conversion is performed), liters of fuel, kilograms of CO2.
class MonthlySummary {
  /// First day of the month at 00:00 local time.
  final DateTime month;
  final double totalCost;
  final double totalLiters;
  final double totalCo2Kg;
  final int fillUpCount;

  const MonthlySummary({
    required this.month,
    required this.totalCost,
    required this.totalLiters,
    required this.totalCo2Kg,
    required this.fillUpCount,
  });

  /// Average price per liter across all fill-ups in this month.
  double get avgPricePerLiter =>
      totalLiters > 0 ? totalCost / totalLiters : 0;
}

/// Pure aggregation helpers for building monthly views from fill-ups.
class MonthlyAggregator {
  MonthlyAggregator._();

  /// Groups [fillUps] by calendar month and returns summaries sorted
  /// oldest first. Months with no fill-ups are omitted.
  static List<MonthlySummary> byMonth(List<FillUp> fillUps) {
    if (fillUps.isEmpty) return const [];
    final buckets = <DateTime, _Bucket>{};
    for (final f in fillUps) {
      final key = DateTime(f.date.year, f.date.month);
      final b = buckets.putIfAbsent(key, _Bucket.new);
      b.cost += f.totalCost;
      b.liters += f.liters;
      b.co2 += Co2Calculator.co2ForFillUp(f);
      b.count += 1;
    }
    final keys = buckets.keys.toList()..sort();
    return [
      for (final k in keys)
        MonthlySummary(
          month: k,
          totalCost: buckets[k]!.cost,
          totalLiters: buckets[k]!.liters,
          totalCo2Kg: buckets[k]!.co2,
          fillUpCount: buckets[k]!.count,
        ),
    ];
  }

  /// Returns only the last [months] entries from a full summary list,
  /// preserving chronological order (oldest first). If fewer summaries
  /// exist, returns them all.
  static List<MonthlySummary> lastN(
    List<MonthlySummary> summaries,
    int months,
  ) {
    if (months <= 0 || summaries.length <= months) return summaries;
    return summaries.sublist(summaries.length - months);
  }

  /// Total cost across all summaries.
  static double totalCost(List<MonthlySummary> summaries) {
    double sum = 0;
    for (final s in summaries) {
      sum += s.totalCost;
    }
    return sum;
  }

  /// Total CO2 across all summaries.
  static double totalCo2(List<MonthlySummary> summaries) {
    double sum = 0;
    for (final s in summaries) {
      sum += s.totalCo2Kg;
    }
    return sum;
  }

  /// Total liters across all summaries.
  static double totalLiters(List<MonthlySummary> summaries) {
    double sum = 0;
    for (final s in summaries) {
      sum += s.totalLiters;
    }
    return sum;
  }
}

class _Bucket {
  double cost = 0;
  double liters = 0;
  double co2 = 0;
  int count = 0;
}
