// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/domain/money_tally.dart';
import '../../../../core/services/co2_calculator.dart';
import 'fill_up.dart';
import '../services/physical_tank_windows.dart';

part 'consumption_stats.freezed.dart';

/// Aggregated statistics computed from a list of [FillUp] entries.
///
/// All values may be `null` when insufficient data is present (e.g. fewer
/// than two fill-ups prevent consumption calculation, since distance
/// requires odometer deltas).
///
/// Since #1362 the consumption average walks plein-to-plein **windows**
/// instead of trusting the naive first-to-last odometer delta. A window
/// opens at a physical full tank and closes on the next physical full tank.
/// Physical partials count; synthetic bookkeeping corrections are separate. The
/// in-progress window after the latest plein is excluded from the
/// average and surfaced separately via [openWindowFillCount] /
/// [openWindowLiters], so partial fills no longer silently corrupt the
/// reported L/100km.
@freezed
abstract class ConsumptionStats with _$ConsumptionStats {
  const ConsumptionStats._();

  const factory ConsumptionStats({
    required int fillUpCount,

    /// Σ real PUMPED litres — fills where NOT [FillUp.isCorrection]
    /// (#2446 / Epic #2439 decision #4). The headline "Total L" the
    /// user sees: correction entries are excluded so it stays honest
    /// about what actually came out of the pump, and are surfaced
    /// separately via [correctionLitersTotal].
    required double totalLiters,

    /// Σ recorded purchase spend over the non-correction fills — but
    /// **null when the history spans more than one denomination**
    /// (#4364). €30 + DKK 225 is not 255 of anything, and the active
    /// country's symbol painted on that sum is the defect `FillUp`'s
    /// own currency doc warns about. The per-denomination breakdown is
    /// always in [spend]; an absent total is absent, never zero.
    double? totalSpent,
    required double totalDistanceKm,
    @Default(0) double totalCo2Kg,
    double? avgConsumptionL100km,
    double? avgCostPerKm,
    double? avgPricePerLiter,
    double? avgCo2PerKm,
    DateTime? periodStart,
    DateTime? periodEnd,

    /// Sum of `liters` from `isCorrection: true` fill-ups inside CLOSED
    /// plein-to-plein windows (#1362). Always 0 when no corrections
    /// landed in a closed window.
    @Default(0) double correctionLitersTotal,

    /// Fraction of pumped-plus-correction litres that came from
    /// corrections inside closed windows (#1362). Denominator is
    /// `totalLiters + correctionLitersTotal` (NOT the correction-
    /// excluded [totalLiters] headline — #2446), so the hint keeps its
    /// original meaning. Range 0..1; 0 when there are no litres at all.
    /// The UI surfaces a hint when this exceeds 5 %.
    @Default(0) double correctionShare,

    /// Number of fills inside the in-progress window — i.e. after the
    /// most recent plein-complet (#1362). 0 when the latest fill is
    /// itself a plein-complet (no open window).
    @Default(0) int openWindowFillCount,

    /// Sum of `liters` inside the in-progress window after the most
    /// recent plein-complet (#1362). 0 when [openWindowFillCount] is 0.
    @Default(0) double openWindowLiters,

    /// Recorded purchase spend SEGREGATED by the currency each fill
    /// recorded (#4364). `FillUp.currency` defines null as *unknown*, so
    /// those amounts land in their own [kUnknownCurrency] bucket and are
    /// never relabelled with today's country's currency.
    @Default(MoneyTally.empty) MoneyTally spend,

    /// The same segregation over the CLOSED plein-to-plein windows only
    /// — the money [avgCostPerKm] may be derived from (#4364).
    @Default(MoneyTally.empty) MoneyTally closedWindowSpend,

    /// Non-correction fills with no recorded cost (#4364). A fill with
    /// no price contributes its distance but no money, which shrinks a
    /// €/km numerator while keeping the whole denominator — a cheaper
    /// vehicle manufactured out of missing data. Non-zero therefore
    /// withholds [avgCostPerKm].
    @Default(0) int unpricedFillCount,

    /// Of [unpricedFillCount], how many fell inside a closed window.
    @Default(0) int unpricedClosedWindowFillCount,

    /// Litres that DID carry a price — the matched denominator of
    /// [avgPricePerLiter] (#4364).
    @Default(0) double pricedLiters,

    /// Closed plein-to-plein windows the averages rest on (#4364). The
    /// sample size a comparison must show: four windows and one window
    /// are not the same evidence.
    @Default(0) int closedWindowCount,
  }) = _ConsumptionStats;

  /// The one denomination every money figure here is in — an ISO code,
  /// [kUnknownCurrency] when the fills recorded none, or null when the
  /// history spans several (#4364). Never the active country's currency.
  String? get spendCurrency => spend.soleCurrency;

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
  /// Consumption is computed by walking plein-to-plein windows: each
  /// window opens with a physical full tank and closes at the next full tank. The
  /// liters of every fill INSIDE the window — including physical partials but excluding
  /// synthetic corrections — are summed against the odometer delta from
  /// the opening fill to the closing plein. The in-progress window
  /// after the latest plein is excluded from the average; its fills
  /// are surfaced via [openWindowFillCount] / [openWindowLiters] so
  /// the UI can warn the user that an L/100km reading is pending.
  ///
  /// Backward compatibility: when every fill has `isFullTank: true`
  /// and no corrections exist, the walker collapses to the legacy
  /// "skip first tank" formula and produces byte-identical numbers.
  factory ConsumptionStats.fromFillUps(List<FillUp> fillUps) {
    if (fillUps.isEmpty) return empty;

    // Work on an immutable, chronologically-ordered copy so callers may
    // pass data in any order.
    final sorted = [...fillUps]..sort(comparePhysicalFills);

    // #2446 — Total L honesty (Epic #2439 decision #4). The headline
    // "Total L" reflects only what the user actually PUMPED, so
    // correction entries are excluded from it; they are surfaced
    // transparently on their own line via [correctionLitersTotal]
    // rather than silently folded into the headline. Corrections
    // always carry totalCost 0, so [totalSpent] is unaffected either
    // way — the explicit filter just keeps the intent legible.
    final totalLiters = sorted.fold<double>(
      0,
      (sum, f) => f.isCorrection ? sum : sum + f.liters,
    );
    // #4364 — spend is accumulated per DENOMINATION. A fill with no
    // recorded cost is counted, not summed as a zero: its litres and
    // its distance are real, its money is simply not known.
    var spend = MoneyTally.empty;
    var unpricedFillCount = 0;
    var pricedLiters = 0.0;
    for (final f in sorted) {
      if (f.isCorrection) continue;
      if (f.totalCost > 0) {
        // #4437 — a settled foreign fill is booked as what the card
        // statement charged; an unsettled one keeps its native amount.
        final (amount, currency) = f.bookedSpend;
        spend = spend.plus(amount, currency);
        pricedLiters += f.liters;
      } else {
        unpricedFillCount += 1;
      }
    }
    final totalCo2 = Co2Calculator.cumulativeCo2(
      sorted.where((f) => !f.isCorrection).toList(growable: false),
    );

    final firstOdo = sorted.first.odometerKm;
    final lastOdo = sorted.last.odometerKm;
    final totalDistance = (lastOdo - firstOdo)
        .clamp(0, double.infinity)
        .toDouble();

    // #4469 — report, reference and stats share qualified physical windows.
    // Accounting corrections stay visible but are never pump-measured fuel.
    final windows = physicalTankWindows(sorted);
    final closedFills = [for (final w in windows.closed) ...w.fills];
    final physicalClosed = closedFills.where((f) => !f.isCorrection).toList();
    final closedLitersSum = windows.closed.fold(0.0, (n, w) => n + w.liters);
    final closedDistanceSum = windows.closed.fold(
      0.0,
      (n, w) => n + w.distanceKm,
    );
    final closedSpend = MoneyTally.of([
      for (final f in physicalClosed)
        if (f.totalCost > 0) f.bookedSpend,
    ]);
    final closedUnpricedFills = physicalClosed
        .where((f) => f.totalCost <= 0)
        .length;
    final closedCorrectionLiters = closedFills
        .where((f) => f.isCorrection)
        .fold(0.0, (n, f) => n + f.liters);
    final windowsClosed = windows.closed.length;
    final openWindowFillCount = windows.pending.length;
    final openWindowLiters = windows.pending.fold(0.0, (n, f) => n + f.liters);

    double? avgL100;
    double? avgCostKm;
    double? avgCo2Km;
    if (closedDistanceSum > 0) {
      avgL100 = (closedLitersSum / closedDistanceSum) * 100;
      // #4364 — a €/km needs a numerator and a denominator that speak
      // for the SAME thing. Two denominations cannot be summed at all,
      // and an unpriced fill inside the window keeps its distance while
      // contributing no money: dividing anyway invents a cheaper tank.
      // Both cases withhold the figure rather than understate it.
      // The whole history must be one denomination, not just the closed
      // windows: nothing downstream carries a currency beside the number,
      // so a DKK figure would be painted with the active country's symbol.
      final closedAmount = closedSpend.soleAmount;
      if (closedAmount != null &&
          closedUnpricedFills == 0 &&
          spend.isSingleDenomination) {
        avgCostKm = closedAmount / closedDistanceSum;
      }
    }
    // CO2/km mirrors the per-window walker: we re-derive from the same
    // closed liters by mapping fuel-type emission factors. To keep the
    // legacy "first-tank-excluded" behaviour byte-identical for the
    // all-plein case, walk the closed windows again for fuel-type-aware
    // CO2 — same fills the liter walker already counted.
    if (closedDistanceSum > 0) {
      final closedCo2 = Co2Calculator.cumulativeCo2(physicalClosed);
      if (closedCo2 > 0) {
        avgCo2Km = closedCo2 / closedDistanceSum;
      }
    }

    // Price per litre matches its own numerator: only the litres that
    // carried a price, and only when they are all one denomination.
    final spendAmount = spend.soleAmount;
    final avgPriceLiter = pricedLiters > 0 && spendAmount != null
        ? spendAmount / pricedLiters
        : null;

    // #2446 — share denominator is pumped + corrections (NOT the
    // correction-excluded headline [totalLiters]), so the "% of fuel
    // from corrections" hint keeps its original meaning now that
    // [totalLiters] no longer carries correction litres.
    final litersInclCorrections = totalLiters + closedCorrectionLiters;
    final correctionShare = litersInclCorrections > 0
        ? (closedCorrectionLiters / litersInclCorrections)
              .clamp(0, 1)
              .toDouble()
        : 0.0;

    debugPrint(
      '[stats] windows=$windowsClosed '
      'closed_liters=${closedLitersSum.toStringAsFixed(2)} '
      'closed_dist=${closedDistanceSum.toStringAsFixed(2)} '
      'currencies=${closedSpend.currencies.join(",")} '
      'corrections=${closedCorrectionLiters.toStringAsFixed(2)} '
      'open_partials=$openWindowFillCount',
    );

    return ConsumptionStats(
      fillUpCount: sorted.length,
      totalLiters: totalLiters,
      totalSpent: spendAmount,
      totalDistanceKm: totalDistance,
      totalCo2Kg: totalCo2,
      avgConsumptionL100km: avgL100,
      avgCostPerKm: avgCostKm,
      avgPricePerLiter: avgPriceLiter,
      avgCo2PerKm: avgCo2Km,
      periodStart: sorted.first.date,
      periodEnd: sorted.last.date,
      correctionLitersTotal: closedCorrectionLiters,
      correctionShare: correctionShare,
      openWindowFillCount: openWindowFillCount,
      openWindowLiters: openWindowLiters,
      spend: spend,
      closedWindowSpend: closedSpend,
      unpricedFillCount: unpricedFillCount,
      unpricedClosedWindowFillCount: closedUnpricedFills,
      pricedLiters: pricedLiters,
      closedWindowCount: windowsClosed,
    );
  }
}
