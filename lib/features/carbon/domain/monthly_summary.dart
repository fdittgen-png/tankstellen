// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../../core/domain/money_tally.dart';
import '../../../core/services/co2_calculator.dart';
import '../../fill_ups/api.dart';

/// Aggregated totals for a single calendar month.
///
/// Litres and kilograms of CO2 are plain sums. Money is not (#4437 E):
/// a month holding a CHF fill and a EUR fill has no single cost, so
/// [spend] keeps each denomination apart and [totalCost] is **null** for
/// such a month — absent, never zero, never a cross-currency sum. No FX
/// conversion is performed; a settled foreign fill counts as what the
/// card statement charged (`FillUpSettlementX.bookedSpend`).
class MonthlySummary {
  /// First day of the month at 00:00 local time.
  final DateTime month;

  /// The month's cost in its one denomination, or null when the month
  /// spans several.
  final double? totalCost;
  final double totalLiters;
  final double totalCo2Kg;
  final int fillUpCount;

  /// The month's spend per denomination (#4437). Empty on a summary
  /// built by hand as a chart value holder.
  final MoneyTally spend;

  const MonthlySummary({
    required this.month,
    required this.totalCost,
    required this.totalLiters,
    required this.totalCo2Kg,
    required this.fillUpCount,
    this.spend = MoneyTally.empty,
  });

  /// Average price per liter across all fill-ups in this month, or null
  /// when the month has no single cost.
  double? get avgPricePerLiter {
    final cost = totalCost;
    if (cost == null) return null;
    return totalLiters > 0 ? cost / totalLiters : 0;
  }
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
      if (f.totalCost > 0) {
        final (amount, currency) = f.bookedSpend;
        b.spend = b.spend.plus(amount, currency);
      }
      b.liters += f.liters;
      b.co2 += Co2Calculator.co2ForFillUp(f);
      b.count += 1;
    }
    final keys = buckets.keys.toList()..sort();
    return [
      for (final k in keys)
        MonthlySummary(
          month: k,
          totalCost: buckets[k]!.spend.soleAmount,
          spend: buckets[k]!.spend,
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

  /// Spend of [fillUps] per denomination, one entry per priced fill —
  /// the tally a "why is there no total" line counts from (#4437).
  static MoneyTally spendOf(List<FillUp> fillUps) => MoneyTally.of([
        for (final f in fillUps)
          if (!f.isCorrection && f.totalCost > 0) f.bookedSpend,
      ]);

  /// Spend across all summaries, per denomination (#4437).
  static MoneyTally spend(List<MonthlySummary> summaries) {
    var tally = MoneyTally.empty;
    for (final s in summaries) {
      for (final e in s.spend.byCurrency.entries) {
        tally = tally.plus(e.value, e.key == kUnknownCurrency ? null : e.key);
      }
    }
    return tally;
  }

  /// Total cost across all summaries, or **null** when they span more
  /// than one denomination (#4437) — a EUR January and a CHF February
  /// have no sum. Summaries built by hand without a [MonthlySummary.spend]
  /// sum their [MonthlySummary.totalCost] as before.
  static double? totalCost(List<MonthlySummary> summaries) {
    if (!spend(summaries).isSingleDenomination) return null;
    double sum = 0;
    for (final s in summaries) {
      final cost = s.totalCost;
      if (cost == null) return null;
      sum += cost;
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
  MoneyTally spend = MoneyTally.empty;
  double liters = 0;
  double co2 = 0;
  int count = 0;
}
