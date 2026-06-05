// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../search/domain/entities/fuel_type.dart';
import '../entities/fill_up.dart';
import '../entities/fuel_type_efficiency_stats.dart';

/// Minimum attributed closed intervals a fuel must have before the
/// "cheapest per km" verdict may crown a winner (Epic #2881).
///
/// The verdict is only shown when EVERY compared fuel that has fills clears
/// this bar — one lucky cheap tank must not crown a fuel. See
/// `docs/decisions/per-fuel-efficiency-attribution.md`.
const int kMinAttributedIntervalsForVerdict = 2;

/// Pure aggregation of [FillUp] entries into per-[FuelType]
/// [FuelTypeEfficiencyStats] under the v1 DOMINANT-FUEL attribution model
/// (Epic #2881; rule frozen in
/// `docs/decisions/per-fuel-efficiency-attribution.md`).
///
/// No Riverpod, no Flutter — drive it directly with a list of fills.
///
/// ## Attribution (summary; the doc is authoritative)
/// Walks CLOSED plein-to-plein intervals (the same interval definition as
/// `ConsumptionStats.fromFillUps` in `consumption_stats.dart` — replicated
/// faithfully here because that walker does not expose a per-interval hook).
/// Each closed interval's litres / distance / cost are attributed, whole, to
/// the fuel with the most litres among its contributing non-correction fills
/// (tie-break: the closing plein's fuel, then `apiValue` alphabetical).
/// Corrections inherit the dominant fuel and never enter the tally.
class FuelTypeEfficiencyAggregator {
  FuelTypeEfficiencyAggregator._();

  /// Compute one [FuelTypeEfficiencyStats] per fuel that has any fills,
  /// sorted by `avgCostPerKm` ascending (nulls last).
  static List<FuelTypeEfficiencyStats> byFuelType(List<FillUp> fills) {
    if (fills.isEmpty) return const [];

    // Chronological copy so callers may pass data in any order — mirrors
    // ConsumptionStats.fromFillUps.
    final sorted = [...fills]..sort((a, b) => a.date.compareTo(b.date));

    // Per-fuel accumulators, keyed by FuelType.apiValue.
    final acc = <String, _FuelAcc>{};
    _FuelAcc accFor(FuelType fuel) =>
        acc.putIfAbsent(fuel.apiValue, () => _FuelAcc(fuel));

    // ── Per-fill facts (independent of interval attribution) ──
    // totalSpent + fillCount over EVERY non-correction fill of the fuel,
    // including the opening fill of the first interval and the open tail.
    for (final f in sorted) {
      if (f.isCorrection) continue;
      final a = accFor(f.fuelType);
      a.totalSpent += f.totalCost;
      a.fillCount += 1;
    }

    // ── Closed-interval walker (mirrors consumption_stats.dart) ──
    // An interval opens at sorted[openingIndex] (first fill, or the prior
    // closing plein) and closes at the next full-tank fill. Contributing
    // fills are those strictly AFTER the opening up to + including the close.
    var openingIndex = 0;
    final pending = <FillUp>[]; // contributing fills of the current interval

    for (var i = 1; i < sorted.length; i++) {
      final fill = sorted[i];
      pending.add(fill);
      if (!fill.isFullTank) continue; // interval still open

      // Interval closes here. Distance from the odometer delta, clamped at
      // 0 so an odometer reset / out-of-order import never goes negative
      // (same clamp as consumption_stats.dart).
      final distance =
          (fill.odometerKm - sorted[openingIndex].odometerKm)
              .clamp(0, double.infinity)
              .toDouble();
      _attributeInterval(pending, fill, distance, accFor);

      openingIndex = i;
      pending.clear();
    }
    // Anything left in `pending` is the in-progress (open) window after the
    // last plein — excluded from attribution, exactly like the walker.

    final result = [
      for (final a in acc.values) a.toStats(),
    ];
    // Sort by €/km ascending; nulls (no attributed interval) last. Stable
    // secondary sort by apiValue for deterministic ordering on ties.
    result.sort((x, y) {
      final cx = x.avgCostPerKm;
      final cy = y.avgCostPerKm;
      if (cx == null && cy == null) {
        return x.fuelType.apiValue.compareTo(y.fuelType.apiValue);
      }
      if (cx == null) return 1;
      if (cy == null) return -1;
      final byCost = cx.compareTo(cy);
      if (byCost != 0) return byCost;
      return x.fuelType.apiValue.compareTo(y.fuelType.apiValue);
    });
    return result;
  }

  /// The lowest-`avgCostPerKm` fuel — but ONLY when every entry that has
  /// fills has `attributedIntervalCount >= kMinAttributedIntervalsForVerdict`.
  /// Returns `null` below the threshold (no crown) or when no fuel has a
  /// non-null €/km.
  static FuelType? cheapestPerKm(List<FuelTypeEfficiencyStats> stats) {
    if (stats.isEmpty) return null;
    final withFills = stats.where((s) => s.fillCount > 0);
    final everyFuelHasEnough = withFills.every(
      (s) => s.attributedIntervalCount >= kMinAttributedIntervalsForVerdict,
    );
    if (!everyFuelHasEnough) return null;

    FuelTypeEfficiencyStats? best;
    for (final s in stats) {
      if (s.avgCostPerKm == null) continue;
      if (best == null || s.avgCostPerKm! < best.avgCostPerKm!) {
        best = s;
      }
    }
    return best?.fuelType;
  }

  /// Tally litres per fuel among the [contributing] NON-correction fills,
  /// pick the dominant fuel, and fold the interval's litres / distance /
  /// cost (including corrections, which inherit the dominant fuel) into that
  /// fuel's accumulator.
  static void _attributeInterval(
    List<FillUp> contributing,
    FillUp closing,
    double distance,
    _FuelAcc Function(FuelType) accFor,
  ) {
    if (contributing.isEmpty) return;

    final litresByFuel = <String, double>{};
    final fuelByApiValue = <String, FuelType>{};
    for (final f in contributing) {
      if (f.isCorrection) continue; // never enters the dominance tally
      litresByFuel.update(
        f.fuelType.apiValue,
        (v) => v + f.liters,
        ifAbsent: () => f.liters,
      );
      fuelByApiValue[f.fuelType.apiValue] = f.fuelType;
    }

    // An interval of corrections-only has no dominance tally — attribute
    // nothing (its litres/distance/cost have no real fuel to credit).
    if (litresByFuel.isEmpty) return;

    final dominant = _dominantFuel(litresByFuel, fuelByApiValue, closing);
    final isMixed = litresByFuel.length > 1;

    // Litres + cost include corrections (they inherit the dominant fuel);
    // distance is the whole interval's odometer delta.
    var intervalLitres = 0.0;
    var intervalCost = 0.0;
    for (final f in contributing) {
      intervalLitres += f.liters;
      intervalCost += f.totalCost; // corrections carry 0
    }

    final a = accFor(dominant);
    a.intervalLitres += intervalLitres;
    a.intervalDistance += distance;
    a.intervalCost += intervalCost;
    a.attributedIntervalCount += 1;
    if (isMixed) a.mixedIntervalCount += 1;
  }

  /// Dominant fuel = most litres; tie-break 1 the closing plein's fuel,
  /// tie-break 2 lowest `apiValue` alphabetical (determinism).
  static FuelType _dominantFuel(
    Map<String, double> litresByFuel,
    Map<String, FuelType> fuelByApiValue,
    FillUp closing,
  ) {
    var maxLitres = double.negativeInfinity;
    for (final l in litresByFuel.values) {
      if (l > maxLitres) maxLitres = l;
    }
    // Candidates within a tiny epsilon of the max (float-safe tie).
    const eps = 1e-9;
    final leaders = litresByFuel.entries
        .where((e) => (maxLitres - e.value).abs() <= eps)
        .map((e) => e.key)
        .toList(growable: false);

    if (leaders.length == 1) return fuelByApiValue[leaders.first]!;

    // Tie-break 1: the closing plein's fuel, if it is among the leaders and
    // is itself a contributing (non-correction) fuel of this interval.
    final closingKey = closing.fuelType.apiValue;
    if (!closing.isCorrection && leaders.contains(closingKey)) {
      return fuelByApiValue[closingKey]!;
    }
    // Tie-break 2: lowest apiValue alphabetical.
    leaders.sort();
    return fuelByApiValue[leaders.first]!;
  }
}

/// Mutable per-fuel accumulator used only inside [byFuelType].
class _FuelAcc {
  _FuelAcc(this.fuelType);

  final FuelType fuelType;

  // Per-fill facts.
  double totalSpent = 0;
  int fillCount = 0;

  // Per dominant-attributed-interval sums.
  double intervalLitres = 0;
  double intervalDistance = 0;
  double intervalCost = 0;
  int attributedIntervalCount = 0;
  int mixedIntervalCount = 0;

  FuelTypeEfficiencyStats toStats() {
    final hasDistance = attributedIntervalCount > 0 && intervalDistance > 0;
    return FuelTypeEfficiencyStats(
      fuelType: fuelType,
      avgL100km: hasDistance ? (intervalLitres / intervalDistance) * 100 : null,
      avgCostPerKm: hasDistance ? intervalCost / intervalDistance : null,
      totalSpent: totalSpent,
      fillCount: fillCount,
      attributedIntervalCount: attributedIntervalCount,
      mixedIntervalCount: mixedIntervalCount,
    );
  }
}
