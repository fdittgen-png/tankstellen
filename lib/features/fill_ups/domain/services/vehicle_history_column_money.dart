// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The money half of a #4365 comparison column — three bases, three
/// accumulators, never one running `double` (#4364).
///
/// The three are not interchangeable and never share a total:
///
///  * **recorded purchase spend** — Σ of what the period's fills cost
///    at the pump. The only figure here that is a fact about money.
///  * **closing-window purchase cost** — what the COUNTED windows' own
///    fills cost, over the distance those windows covered.
///  * **modelled consumed-fuel valuation** — the litres each window
///    burned, valued at what the tank was filled with when that window
///    OPENED. Only the counted windows' openings supply a price, so a
///    later, more expensive purchase can never retroactively rewrite an
///    earlier period's observed cost.
///
/// The last two coincide only when price never moved: on a fuel switch,
/// or across any price change, they separate — which is exactly the
/// point of showing both.
library;

import '../../../../core/domain/comparison_eligibility.dart';
import '../../../../core/domain/data_value.dart';
import '../../../../core/domain/money.dart';
import '../../../../core/domain/money_tally.dart';
import '../entities/fill_up.dart';
import 'tank_report.dart';

/// Every monetary accumulation of one column.
class ColumnMoney {
  const ColumnMoney({
    required this.matchedSpend,
    required this.purchaseSpend,
    required this.consumedFuelValuation,
    required this.unpricedWindowFills,
    required this.unpricedPeriodFills,
    required this.unpricedOpenings,
    required this.pricedQuantity,
  });

  factory ColumnMoney.of(
    List<TankPeriod> matched,
    Map<String, List<FillUp>> windowFills,
    List<FillUp> periodFills,
  ) {
    var matchedSpend = MoneyTally.empty;
    var unpricedWindow = 0;
    for (final w in matched) {
      for (final f in windowFills[w.closing.id] ?? const <FillUp>[]) {
        if (f.isCorrection) continue;
        if (f.totalCost > 0) {
          matchedSpend = matchedSpend.plus(f.totalCost, f.currency);
        } else {
          unpricedWindow += 1;
        }
      }
    }
    var purchase = MoneyTally.empty;
    var unpricedPeriod = 0;
    var pricedQuantity = 0.0;
    for (final f in periodFills) {
      if (f.totalCost > 0) {
        purchase = purchase.plus(f.totalCost, f.currency);
        pricedQuantity += f.liters;
      } else {
        unpricedPeriod += 1;
      }
    }
    var consumed = MoneyTally.empty;
    var unpricedOpenings = 0;
    for (final w in matched) {
      final o = w.opening;
      if (o.liters > 0 && o.totalCost > 0) {
        consumed =
            consumed.plus(w.liters * (o.totalCost / o.liters), o.currency);
      } else {
        unpricedOpenings += 1;
      }
    }
    return ColumnMoney(
      matchedSpend: matchedSpend,
      purchaseSpend: purchase,
      consumedFuelValuation: consumed,
      unpricedWindowFills: unpricedWindow,
      unpricedPeriodFills: unpricedPeriod,
      unpricedOpenings: unpricedOpenings,
      pricedQuantity: pricedQuantity,
    );
  }

  final MoneyTally matchedSpend;
  final MoneyTally purchaseSpend;
  final MoneyTally consumedFuelValuation;
  final int unpricedWindowFills;
  final int unpricedPeriodFills;
  final int unpricedOpenings;
  final double pricedQuantity;

  ComparableMetric<double> costPerKm(
    double distance,
    ComparisonCoverage coverage,
    bool ambiguous,
    DataValue<double> Function(double) wrap,
  ) =>
      _perDistance(matchedSpend, unpricedWindowFills, distance, coverage,
          ambiguous, wrap);

  ComparableMetric<double> consumedFuelCostPerKm(
    double distance,
    ComparisonCoverage coverage,
    DataValue<double> Function(double) wrap,
  ) =>
      _perDistance(consumedFuelValuation, unpricedOpenings, distance, coverage,
          false, wrap);

  ComparableMetric<double> _perDistance(
    MoneyTally tally,
    int unpriced,
    double distance,
    ComparisonCoverage coverage,
    bool ambiguous,
    DataValue<double> Function(double) wrap,
  ) {
    if (ambiguous) {
      return ComparableMetric.unavailable(
          ComparisonUnavailableReason.ambiguousAttribution,
          coverage: coverage);
    }
    final refusal = moneyRefusal(tally, unpriced: unpriced);
    if (refusal != null) {
      return ComparableMetric.unavailable(refusal, coverage: coverage);
    }
    final amount = tally.soleAmount;
    if (amount == null || distance <= 0 || !distance.isFinite) {
      return ComparableMetric.unavailable(
          coverage.windowCount == 0
              ? ComparisonUnavailableReason.noEvidence
              : ComparisonUnavailableReason.noMatchedDistance,
          coverage: coverage);
    }
    return ComparableMetric.comparable(wrap(amount / distance),
        coverage: coverage);
  }

  /// The period's actual pump spend. Never sourced from
  /// `FuelTypeEfficiencyStats.totalSpent`, which is a reconstruction.
  ComparableMetric<Money> recordedSpend(ComparisonCoverage coverage) {
    final refusal = moneyRefusal(purchaseSpend, unpriced: 0);
    if (refusal != null) {
      return ComparableMetric.unavailable(refusal, coverage: coverage);
    }
    final money = purchaseSpend.soleMoney;
    if (money == null) {
      return ComparableMetric.unavailable(
          ComparisonUnavailableReason.noEvidence,
          coverage: coverage);
    }
    return ComparableMetric.comparable(DataValue.measured(money),
        coverage: coverage);
  }

  ComparableMetric<double> pricePerUnit(
    ComparisonCoverage coverage,
    DataValue<double> Function(double) wrap,
  ) {
    final refusal = moneyRefusal(purchaseSpend, unpriced: 0);
    if (refusal != null) {
      return ComparableMetric.unavailable(refusal, coverage: coverage);
    }
    final amount = purchaseSpend.soleAmount;
    if (amount == null || pricedQuantity <= 0) {
      return ComparableMetric.unavailable(
          ComparisonUnavailableReason.noEvidence,
          coverage: coverage);
    }
    return ComparableMetric.comparable(wrap(amount / pricedQuantity),
        coverage: coverage);
  }
}

/// Why [tally] may not produce one comparable number, or null when it
/// may. Unknown currency is refused BEFORE mixing: an amount whose
/// currency was never recorded cannot enter a euro figure, and the
/// active country's currency is not evidence of what was paid.
ComparisonUnavailableReason? moneyRefusal(MoneyTally tally,
    {required int unpriced}) {
  if (unpriced > 0) return ComparisonUnavailableReason.missingPrices;
  if (!tally.isSingleDenomination) {
    return ComparisonUnavailableReason.mixedCurrencies;
  }
  if (tally.hasUnknownCurrency) {
    return ComparisonUnavailableReason.unknownCurrency;
  }
  return null;
}
