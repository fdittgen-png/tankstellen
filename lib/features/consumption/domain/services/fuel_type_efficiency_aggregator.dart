// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../search/domain/entities/fuel_type.dart';
import '../entities/fill_up.dart';
import '../entities/fuel_type_efficiency_stats.dart';

/// Minimum attributed closed intervals a bucket must have before the
/// "cheapest per km" verdict may crown a winner (Epic #2881).
///
/// The verdict is only shown when EVERY compared bucket that has fills clears
/// this bar — one lucky cheap tank must not crown a composition. See
/// `docs/decisions/0015-per-fuel-efficiency-composition-buckets.md`.
const int kMinAttributedIntervalsForVerdict = 2;

/// Largest minority volume share an interval may have and still count as a
/// PURE bucket (ADR 0015). Inclusive: a minority of exactly 15 % is pure
/// (equivalently, a dominant share ≥ 0.85 is pure). Above it the interval is a
/// `dominant/secondary` MIX bucket.
const double kMaxMinorityShareForPure = 0.15;

/// Pure aggregation of [FillUp] entries into per-composition-bucket
/// [FuelTypeEfficiencyStats] under the **v2 COMPOSITION-BUCKET** model
/// (Epic #2881; rule frozen in
/// `docs/decisions/0015-per-fuel-efficiency-composition-buckets.md`, which
/// supersedes ADR 0014's dominant-fuel collapse).
///
/// No Riverpod, no Flutter — drive it directly with a list of fills.
///
/// ## Attribution (summary; the ADR is authoritative)
/// Walks CLOSED plein-to-plein intervals (the same interval definition as
/// `ConsumptionStats.fromFillUps` in `consumption_stats.dart` — replicated
/// faithfully here because that walker does not expose a per-interval hook).
/// Each closed interval's litres-by-fuel composition decides its bucket:
/// dominant ≥ 85 % volume ⇒ PURE (the dominant [FuelType]); otherwise MIX
/// (the `dominant/secondary` blend, dominant first; a 3-way blend takes the
/// two largest for the label, all litres still fold into that bucket). The
/// whole interval's litres / distance / cost fold into that bucket.
/// Corrections inherit the interval's bucket and never enter the composition
/// tally (their `totalCost` is 0, so they do not move €/km).
class FuelTypeEfficiencyAggregator {
  FuelTypeEfficiencyAggregator._();

  /// Compute one [FuelTypeEfficiencyStats] per composition bucket that has at
  /// least one classified interval, sorted by `avgCostPerKm` ascending
  /// (nulls last). Only buckets ACTUALLY USED appear (ADR 0015).
  static List<FuelTypeEfficiencyStats> byFuelType(List<FillUp> fills) {
    if (fills.isEmpty) return const [];

    // Chronological copy so callers may pass data in any order — mirrors
    // ConsumptionStats.fromFillUps.
    final sorted = [...fills]..sort((a, b) => a.date.compareTo(b.date));

    // Per-bucket accumulators, keyed by FuelEfficiencyBucket.key.
    final acc = <String, _BucketAcc>{};
    _BucketAcc accFor(FuelEfficiencyBucket bucket) =>
        acc.putIfAbsent(bucket.key, () => _BucketAcc(bucket));

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
      final distance = (fill.odometerKm - sorted[openingIndex].odometerKm)
          .clamp(0, double.infinity)
          .toDouble();
      _attributeInterval(pending, distance, accFor);

      openingIndex = i;
      pending.clear();
    }
    // Anything left in `pending` is the in-progress (open) window after the
    // last plein — excluded from attribution, exactly like the walker.

    final result = [
      for (final a in acc.values) a.toStats(),
    ];
    // Sort by €/km ascending; nulls (no usable distance) last. Stable
    // secondary sort by bucket key for deterministic ordering on ties.
    result.sort((x, y) {
      final cx = x.avgCostPerKm;
      final cy = y.avgCostPerKm;
      if (cx == null && cy == null) {
        return x.bucket.key.compareTo(y.bucket.key);
      }
      if (cx == null) return 1;
      if (cy == null) return -1;
      final byCost = cx.compareTo(cy);
      if (byCost != 0) return byCost;
      return x.bucket.key.compareTo(y.bucket.key);
    });
    return result;
  }

  /// The lowest-`avgCostPerKm` bucket — but ONLY when every entry that has
  /// fills has `attributedIntervalCount >= kMinAttributedIntervalsForVerdict`.
  /// Returns `null` below the threshold (no crown) or when no bucket has a
  /// non-null €/km. Compares across ALL buckets (pure + mix — ADR 0015).
  static FuelEfficiencyBucket? cheapestPerKm(
    List<FuelTypeEfficiencyStats> stats,
  ) {
    if (stats.isEmpty) return null;
    final withFills = stats.where((s) => s.fillCount > 0);
    final everyBucketHasEnough = withFills.every(
      (s) => s.attributedIntervalCount >= kMinAttributedIntervalsForVerdict,
    );
    if (!everyBucketHasEnough) return null;

    FuelTypeEfficiencyStats? best;
    for (final s in stats) {
      if (s.avgCostPerKm == null) continue;
      if (best == null || s.avgCostPerKm! < best.avgCostPerKm!) {
        best = s;
      }
    }
    return best?.bucket;
  }

  /// Tally litres per fuel among the [contributing] NON-correction fills,
  /// classify the interval into a PURE or MIX [FuelEfficiencyBucket] by its
  /// composition (ADR 0015), and fold the interval's litres / distance / cost
  /// (incl. corrections, which inherit the bucket) into that bucket.
  static void _attributeInterval(
    List<FillUp> contributing,
    double distance,
    _BucketAcc Function(FuelEfficiencyBucket) accFor,
  ) {
    if (contributing.isEmpty) return;

    final litresByFuel = <String, double>{};
    final fuelByApiValue = <String, FuelType>{};
    for (final f in contributing) {
      if (f.isCorrection) continue; // never enters the composition tally
      litresByFuel.update(
        f.fuelType.apiValue,
        (v) => v + f.liters,
        ifAbsent: () => f.liters,
      );
      fuelByApiValue[f.fuelType.apiValue] = f.fuelType;
    }

    // An interval of corrections-only has no composition — attribute nothing
    // (its litres/distance/cost have no real fuel to credit).
    if (litresByFuel.isEmpty) return;

    final bucket = _classify(litresByFuel, fuelByApiValue);

    // Litres + cost include corrections (they inherit the bucket); distance
    // is the whole interval's odometer delta. fillCount counts only the
    // non-correction fills folded into this bucket.
    var intervalLitres = 0.0;
    var intervalCost = 0.0;
    var intervalFills = 0;
    for (final f in contributing) {
      intervalLitres += f.liters;
      intervalCost += f.totalCost; // corrections carry 0
      if (!f.isCorrection) intervalFills += 1;
    }

    final a = accFor(bucket);
    a.intervalLitres += intervalLitres;
    a.intervalDistance += distance;
    a.intervalCost += intervalCost;
    a.attributedIntervalCount += 1;
    a.fillCount += intervalFills;
    a.totalSpent += intervalCost;
  }

  /// Classify an interval's litres-by-fuel composition into a PURE or MIX
  /// bucket. The dominant fuel is the largest volume share; the secondary the
  /// next largest. Dominant share ≥ (1 − [kMaxMinorityShareForPure]) ⇒ PURE
  /// (secondary dropped). Otherwise MIX (dominant/secondary). Ties on share
  /// break by lowest `apiValue` alphabetically for determinism.
  static FuelEfficiencyBucket _classify(
    Map<String, double> litresByFuel,
    Map<String, FuelType> fuelByApiValue,
  ) {
    // Total volume — known non-empty (caller guards litresByFuel.isEmpty).
    var total = 0.0;
    for (final l in litresByFuel.values) {
      total += l;
    }

    // Order fuels by descending litres, tie-break ascending apiValue.
    final ordered = litresByFuel.keys.toList()
      ..sort((a, b) {
        final byLitres = litresByFuel[b]!.compareTo(litresByFuel[a]!);
        if (byLitres != 0) return byLitres;
        return a.compareTo(b);
      });

    final dominant = fuelByApiValue[ordered.first]!;

    // Single-fuel interval, or a total of 0 (defensive): always pure.
    if (ordered.length == 1 || total <= 0) {
      return FuelEfficiencyBucket(dominant: dominant);
    }

    final dominantShare = litresByFuel[ordered.first]! / total;
    // Minority share = 1 − dominantShare. Pure when minority ≤ threshold,
    // i.e. dominantShare ≥ 1 − threshold (inclusive). A tiny epsilon keeps
    // the exact-boundary case (e.g. exactly 15 % minority) on the pure side
    // despite float rounding.
    const eps = 1e-9;
    if (dominantShare >= (1 - kMaxMinorityShareForPure) - eps) {
      return FuelEfficiencyBucket(dominant: dominant);
    }

    // MIX: dominant + the next-largest (the two largest for a 3-way blend).
    final secondary = fuelByApiValue[ordered[1]]!;
    return FuelEfficiencyBucket(dominant: dominant, secondary: secondary);
  }
}

/// Mutable per-bucket accumulator used only inside [byFuelType].
class _BucketAcc {
  _BucketAcc(this.bucket);

  final FuelEfficiencyBucket bucket;

  // Per-bucket sums over the intervals classified into this bucket.
  double intervalLitres = 0;
  double intervalDistance = 0;
  double intervalCost = 0;
  int attributedIntervalCount = 0;

  // Per-fill facts folded from this bucket's intervals.
  double totalSpent = 0;
  int fillCount = 0;

  FuelTypeEfficiencyStats toStats() {
    final hasDistance = attributedIntervalCount > 0 && intervalDistance > 0;
    return FuelTypeEfficiencyStats(
      bucket: bucket,
      avgL100km: hasDistance ? (intervalLitres / intervalDistance) * 100 : null,
      avgCostPerKm: hasDistance ? intervalCost / intervalDistance : null,
      totalSpent: totalSpent,
      fillCount: fillCount,
      attributedIntervalCount: attributedIntervalCount,
    );
  }
}
