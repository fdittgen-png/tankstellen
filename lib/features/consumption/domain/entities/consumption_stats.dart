import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/services/co2_calculator.dart';
import 'fill_up.dart';

part 'consumption_stats.freezed.dart';

/// Aggregated statistics computed from a list of [FillUp] entries.
///
/// All values may be `null` when insufficient data is present (e.g. fewer
/// than two fill-ups prevent consumption calculation, since distance
/// requires odometer deltas).
///
/// Since #1362 the consumption average walks plein-to-plein **windows**
/// instead of trusting the naive first-to-last odometer delta. A window
/// opens at a plein-complet (or at the very first fill, when no prior
/// plein exists) and closes on the next plein. Partials and corrections
/// inside the window count toward that window's liters total. The
/// in-progress window after the latest plein is excluded from the
/// average and surfaced separately via [openWindowFillCount] /
/// [openWindowLiters], so partial fills no longer silently corrupt the
/// reported L/100km.
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

    /// Sum of `liters` from `isCorrection: true` fill-ups inside CLOSED
    /// plein-to-plein windows (#1362). Always 0 when no corrections
    /// landed in a closed window.
    @Default(0) double correctionLitersTotal,

    /// Fraction of [totalLiters] that came from auto-corrections inside
    /// closed windows (#1362). Range 0..1; 0 when [totalLiters] is 0.
    /// The UI surfaces a hint when this exceeds 5 %.
    @Default(0) double correctionShare,

    /// Number of fills inside the in-progress window — i.e. after the
    /// most recent plein-complet (#1362). 0 when the latest fill is
    /// itself a plein-complet (no open window).
    @Default(0) int openWindowFillCount,

    /// Sum of `liters` inside the in-progress window after the most
    /// recent plein-complet (#1362). 0 when [openWindowFillCount] is 0.
    @Default(0) double openWindowLiters,
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
  /// Consumption is computed by walking plein-to-plein windows: each
  /// window opens with a plein-complet (or with the very first fill
  /// when no prior plein exists) and closes at the next plein. The
  /// liters of every fill INSIDE the window — including partials and
  /// auto-corrections — are summed against the odometer delta from
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
    final sorted = [...fillUps]..sort((a, b) => a.date.compareTo(b.date));

    final totalLiters = sorted.fold<double>(0, (sum, f) => sum + f.liters);
    final totalSpent = sorted.fold<double>(0, (sum, f) => sum + f.totalCost);
    final totalCo2 = Co2Calculator.cumulativeCo2(sorted);

    final firstOdo = sorted.first.odometerKm;
    final lastOdo = sorted.last.odometerKm;
    final totalDistance =
        (lastOdo - firstOdo).clamp(0, double.infinity).toDouble();

    // ─── Window walker ────────────────────────────────────────────────
    // Every closed window starts at an "opening" fill (the first fill
    // of the entire list, OR the previous closing plein) and ends at
    // a closing plein. We accumulate per-window liters/distance/etc.
    // for fills strictly AFTER the opening — the opening fill's liters
    // belong to the previous window's tally (or are excluded when the
    // opening is the very first fill).
    var closedLitersSum = 0.0;
    var closedDistanceSum = 0.0;
    var closedCostSum = 0.0;
    var closedCorrectionLiters = 0.0;
    var windowsClosed = 0;

    var openingIndex = 0;
    var pendingLiters = 0.0;
    var pendingCost = 0.0;
    var pendingCorrectionLiters = 0.0;
    var pendingFillCount = 0; // fills strictly after the opening

    for (var i = 1; i < sorted.length; i++) {
      final fill = sorted[i];
      pendingLiters += fill.liters;
      pendingCost += fill.totalCost;
      pendingFillCount += 1;
      if (fill.isCorrection) {
        pendingCorrectionLiters += fill.liters;
      }
      if (fill.isFullTank) {
        // Window closes here.
        final dist = (fill.odometerKm - sorted[openingIndex].odometerKm)
            .clamp(0, double.infinity)
            .toDouble();
        closedLitersSum += pendingLiters;
        closedDistanceSum += dist;
        closedCostSum += pendingCost;
        closedCorrectionLiters += pendingCorrectionLiters;
        windowsClosed += 1;

        openingIndex = i;
        pendingLiters = 0;
        pendingCost = 0;
        pendingCorrectionLiters = 0;
        pendingFillCount = 0;
      }
    }

    // Anything left in the "pending" buckets after the loop belongs to
    // the in-progress (open) window — i.e. fills logged after the most
    // recent plein. These are EXCLUDED from the average but surfaced
    // separately so the UI can warn the user.
    final openWindowFillCount = pendingFillCount;
    final openWindowLiters = pendingLiters;

    double? avgL100;
    double? avgCostKm;
    double? avgCo2Km;
    if (closedDistanceSum > 0) {
      avgL100 = (closedLitersSum / closedDistanceSum) * 100;
      avgCostKm = closedCostSum / closedDistanceSum;
    }
    // CO2/km mirrors the per-window walker: we re-derive from the same
    // closed liters by mapping fuel-type emission factors. To keep the
    // legacy "first-tank-excluded" behaviour byte-identical for the
    // all-plein case, walk the closed windows again for fuel-type-aware
    // CO2 — same fills the liter walker already counted.
    if (closedDistanceSum > 0) {
      final closedCo2 = _closedWindowsCo2(sorted);
      if (closedCo2 > 0) {
        avgCo2Km = closedCo2 / closedDistanceSum;
      }
    }

    final avgPriceLiter = totalLiters > 0 ? totalSpent / totalLiters : null;

    final correctionShare = totalLiters > 0
        ? (closedCorrectionLiters / totalLiters).clamp(0, 1).toDouble()
        : 0.0;

    debugPrint(
      '[stats] windows=$windowsClosed '
      'closed_liters=${closedLitersSum.toStringAsFixed(2)} '
      'closed_dist=${closedDistanceSum.toStringAsFixed(2)} '
      'corrections=${closedCorrectionLiters.toStringAsFixed(2)} '
      'open_partials=$openWindowFillCount',
    );

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
      correctionLitersTotal: closedCorrectionLiters,
      correctionShare: correctionShare,
      openWindowFillCount: openWindowFillCount,
      openWindowLiters: openWindowLiters,
    );
  }

  /// Sum CO2 across fills inside CLOSED plein-to-plein windows — i.e.
  /// every fill EXCEPT the first one and the in-progress tail after
  /// the latest plein. Mirrors the liter walker so per-km math stays
  /// internally consistent.
  static double _closedWindowsCo2(List<FillUp> sorted) {
    if (sorted.length < 2) return 0;
    // Find the index of the LAST plein-complet — fills after it are
    // the open window and don't count.
    var lastPleinIdx = -1;
    for (var i = sorted.length - 1; i >= 0; i--) {
      if (sorted[i].isFullTank) {
        lastPleinIdx = i;
        break;
      }
    }
    if (lastPleinIdx <= 0) return 0;
    // Fills 1..lastPleinIdx (inclusive) — first is excluded as the
    // opening of the first window.
    final closedFills = sorted.sublist(1, lastPleinIdx + 1);
    return Co2Calculator.cumulativeCo2(closedFills);
  }
}
