// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../entities/consumption_stats.dart';
import '../entities/fill_up.dart';

/// One calendar month's worth of fill-up statistics (#2698).
///
/// [month] is the first day of the month at 00:00 local time (the same
/// `DateTime(year, month)` bucket key used by `MonthlyAggregator.byMonth`).
/// [stats] is the FULL [ConsumptionStats] computed from that month's
/// fill-ups via the canonical [ConsumptionStats.fromFillUps] window
/// walker — so litres / spend / avg price-per-litre are always present,
/// while [ConsumptionStats.avgConsumptionL100km] / `avgCostPerKm` are
/// non-null ONLY when a closed plein-to-plein window falls inside the
/// month. Charts and the comparison card null-skip those metrics.
class MonthlyFuelStats {
  /// First day of the month at 00:00 local time.
  final DateTime month;

  /// Full stat set for the month, via [ConsumptionStats.fromFillUps].
  final ConsumptionStats stats;

  const MonthlyFuelStats({required this.month, required this.stats});
}

/// Pure aggregation of [FillUp] entries into per-month [MonthlyFuelStats]
/// (#2698).
///
/// Groups fill-ups by `DateTime(date.year, date.month)` — the same bucket
/// idiom as `MonthlyAggregator.byMonth` — and computes each month's stat
/// set by handing that month's slice to the EXISTING
/// [ConsumptionStats.fromFillUps] plein-to-plein window walker. No
/// consumption maths is re-implemented here; the per-month L/100 km only
/// materialises when a closed window happens to fall inside one calendar
/// month, which the comparison/charts handle by skipping nulls.
class FillUpMonthlyStatsAggregator {
  FillUpMonthlyStatsAggregator._();

  /// Group [fillUps] by calendar month and return one [MonthlyFuelStats]
  /// per non-empty month, sorted oldest first. Months with no fill-ups
  /// are omitted.
  static List<MonthlyFuelStats> byMonth(List<FillUp> fillUps) {
    if (fillUps.isEmpty) return const [];
    final buckets = <DateTime, List<FillUp>>{};
    for (final f in fillUps) {
      final key = DateTime(f.date.year, f.date.month);
      buckets.putIfAbsent(key, () => <FillUp>[]).add(f);
    }
    final keys = buckets.keys.toList()..sort();
    return [
      for (final k in keys)
        MonthlyFuelStats(
          month: k,
          stats: ConsumptionStats.fromFillUps(buckets[k]!),
        ),
    ];
  }
}
