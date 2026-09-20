// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../core/domain/fuel/fuel_grade.dart';
import '../../../../core/domain/fuel/fuel_quantity_unit.dart';
import '../../../../core/domain/fuel/tank_blend_snapshot.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/money_tally.dart';
import '../entities/fill_up.dart';
import '../entities/fuel_type_efficiency_stats.dart';
import 'fuel_type_efficiency_aggregator.dart' show kMaxMinorityShareForPure;

// Internals of `fuel_type_efficiency_aggregator.dart`, split out to keep
// that file under the #1680 400-line cap (move-only, behaviour
// preserved): the #3846 per-fuel pricing table and the two value
// holders the interval walker accumulates into. Nothing here is part of
// the feature's public contract — `fill_ups/api.dart` does not export it.

/// The per-fuel pricing evidence of ONE denomination (#3846, #4364).
///
/// [pricePerLitre] is empty — never guessed — whenever the supplied fills
/// span more than one currency ([mixedCurrencies]): a volume-weighted
/// mean over EUR and DKK receipts is a number that is true in neither.
class FuelPriceTable {
  const FuelPriceTable({
    required this.pricePerLitre,
    required this.spend,
    required this.unpricedFillCount,
  });

  /// Volume-weighted price per `FuelType.apiValue`, in [currency].
  final Map<String, double> pricePerLitre;

  /// The priced fills' money, segregated by the currency each recorded.
  final MoneyTally spend;

  /// Non-correction fills that carried no cost at all.
  final int unpricedFillCount;

  /// The one denomination the table is expressed in, or null when the
  /// fills were empty or spanned several.
  String? get currency => spend.soleCurrency;

  bool get mixedCurrencies => !spend.isSingleDenomination;
}

/// Volume-weighted price per litre for each fuel, over the supplied real
/// fills of that fuel (#3846) — one denomination only (#4364).
///
/// Weighted by volume rather than a plain mean so a 40 L fill counts more
/// than a 5 L top-up. Corrections are excluded (no litres, no money) and so
/// are fills with no recorded cost — a zero-cost fill would drag the average
/// toward zero and quietly make a fuel look free; those are COUNTED instead
/// ([FuelPriceTable.unpricedFillCount]) so the caller can withhold the money
/// rather than understate it.
///
/// The caller decides which fills to pass. `FuelTypeEfficiencyAggregator`
/// passes only the fills up to and including the last CLOSING plein, so a
/// purchase logged after every counted window cannot reprice an earlier
/// period (#4364).
FuelPriceTable weightedPricePerLitre(List<FillUp> sorted) {
  var spend = MoneyTally.empty;
  var unpriced = 0;
  for (final f in sorted) {
    if (f.isCorrection) continue;
    if (f.totalCost <= 0) {
      unpriced += 1;
      continue;
    }
    if (f.liters <= 0) continue;
    spend = spend.plus(f.totalCost, f.currency);
  }
  if (!spend.isSingleDenomination) {
    return FuelPriceTable(
        pricePerLitre: const {}, spend: spend, unpricedFillCount: unpriced);
  }
  final litres = <String, double>{};
  final cost = <String, double>{};
  for (final f in sorted) {
    if (f.isCorrection) continue;
    if (f.liters <= 0 || f.totalCost <= 0) continue;
    final key = f.fuelType.apiValue;
    litres.update(key, (v) => v + f.liters, ifAbsent: () => f.liters);
    cost.update(key, (v) => v + f.totalCost, ifAbsent: () => f.totalCost);
  }
  return FuelPriceTable(
    pricePerLitre: {
      for (final key in litres.keys)
        if (litres[key]! > 0) key: cost[key]! / litres[key]!,
    },
    spend: spend,
    unpricedFillCount: unpriced,
  );
}

/// An interval's carried-over opening tank content (v3, #3764): litres per
/// `FuelType.apiValue` plus the fuel objects for label resolution.
///
/// #4322 — read from the evidence-only tank blend, so part of the tank may
/// be attributable to no grade: [unknownLitres]. Those litres are never
/// handed to a grade; [classifyComposition] only crowns a bucket they
/// could not change.
class OpeningContent {
  const OpeningContent(this.litresByFuel, this.fuelByApiValue,
      {this.unknownLitres = 0});

  /// The litres the blend guarantees to each grade.
  final Map<String, double> litresByFuel;
  final Map<String, FuelType> fuelByApiValue;

  /// The litres of the full tank no evidence attributes to any grade.
  final double unknownLitres;

  /// The full tank of [capacityL] after a plein, as the blend [after]
  /// that fill describes it — or null when the blend guarantees no grade
  /// at all (nothing to classify by).
  static OpeningContent? ofBlend(TankBlendSnapshot after, double capacityL) {
    final litres = <String, double>{};
    final fuels = <String, FuelType>{};
    for (final entry in after.gradeShares.entries) {
      if (entry.key == FuelGrade.unknown || entry.value <= 0) continue;
      final fuel = FuelType.fromString(entry.key.key);
      litres[fuel.apiValue] = entry.value * capacityL;
      fuels[fuel.apiValue] = fuel;
    }
    if (litres.isEmpty) return null;
    return OpeningContent(litres, fuels,
        unknownLitres: after.unknownShare * capacityL);
  }
}

/// The ADR 0015 bucket of a composition tally in which [unknownLitres]
/// belong to no known grade — or null when the evidence does not settle it
/// (#4322).
///
/// The bucket is settled only when EVERY possible attribution of the
/// unknown litres yields the same one. Each bucket region (a dominant
/// grade, its secondary, pure vs mix) is an intersection of half-spaces
/// over the per-grade litres, hence convex; the attributions form a
/// simplex whose corners are "all of it to one grade". So it suffices to
/// test the corners: all to each known grade, and all to a grade the tally
/// has not seen. A corner that names the unseen grade, or any two corners
/// that disagree, leaves the bucket unsettled — the caller then falls back
/// to the ADR's legacy tally rather than guess.
FuelEfficiencyBucket? classifyComposition(
  Map<String, double> litresByFuel,
  Map<String, FuelType> fuelByApiValue, {
  double unknownLitres = 0,
}) {
  if (litresByFuel.isEmpty) return null;
  final known = litresByFuel.values.fold<double>(0, (a, b) => a + b);
  if (unknownLitres <= 1e-9 * (known + 1)) {
    return _bucketOf(_rank(litresByFuel), fuelByApiValue);
  }
  // The unseen grade sorts first on ties, so a tie resolves AGAINST the
  // settled reading — the conservative side.
  const unseen = '';
  final corners = [
    for (final key in [...litresByFuel.keys, unseen])
      _rank({...litresByFuel, key: (litresByFuel[key] ?? 0) + unknownLitres}),
  ];
  final first = corners.first;
  for (final c in corners) {
    if (c.dominant == unseen || c.secondary == unseen) return null;
    if (c.dominant != first.dominant || c.secondary != first.secondary) {
      return null;
    }
  }
  return _bucketOf(first, fuelByApiValue);
}

FuelEfficiencyBucket _bucketOf(
        ({String dominant, String? secondary}) ranked,
        Map<String, FuelType> fuelByApiValue) =>
    FuelEfficiencyBucket(
      dominant: fuelByApiValue[ranked.dominant]!,
      secondary: ranked.secondary == null
          ? null
          : fuelByApiValue[ranked.secondary]!,
    );

/// Dominant fuel = largest volume share; secondary = the next largest, or
/// null when the tally is PURE (a single fuel, or a dominant share ≥
/// 1 − [kMaxMinorityShareForPure], inclusive). Ties on litres break by
/// lowest `apiValue` alphabetically for determinism (ADR 0015).
({String dominant, String? secondary}) _rank(Map<String, double> litres) {
  final total = litres.values.fold<double>(0, (a, b) => a + b);
  final ordered = litres.keys.toList()
    ..sort((a, b) {
      final byLitres = litres[b]!.compareTo(litres[a]!);
      return byLitres != 0 ? byLitres : a.compareTo(b);
    });
  final dominant = ordered.first;
  if (ordered.length == 1 || total <= 0) return (dominant: dominant, secondary: null);
  // A tiny epsilon keeps the exact-boundary case (e.g. exactly 15 %
  // minority) on the pure side despite float rounding.
  const eps = 1e-9;
  if (litres[dominant]! / total >= (1 - kMaxMinorityShareForPure) - eps) {
    return (dominant: dominant, secondary: null);
  }
  return (dominant: dominant, secondary: ordered[1]);
}

/// Mutable per-bucket accumulator used only inside `FuelTypeEfficiencyAggregator.byFuelType`.
class BucketAcc {
  BucketAcc(this.bucket);

  final FuelEfficiencyBucket bucket;

  // Per-bucket sums over the intervals classified into this bucket.
  double intervalLitres = 0;
  double intervalDistance = 0;
  double intervalCost = 0;
  int attributedIntervalCount = 0;
  int legacyAttributedIntervalCount = 0;

  // Per-fill facts folded from this bucket's intervals (#4364): what the
  // pump ACTUALLY charged, segregated by denomination, beside the count
  // of fills that recorded no price at all.
  MoneyTally recordedSpend = MoneyTally.empty;
  int unpricedFillCount = 0;
  int fillCount = 0;

  /// False once an interval was folded in whose pricing table spanned
  /// more than one currency — no money figure may be derived then.
  bool pricingDenominable = true;

  FuelTypeEfficiencyStats toStats() {
    final unit = commonFuelQuantityUnit([
          FuelQuantityUnit.fromPriceUnit(bucket.dominant.unit),
          if (bucket.secondary case final s?)
            FuelQuantityUnit.fromPriceUnit(s.unit),
        ]) ??
        FuelQuantityUnit.unknown;
    final hasDistance = attributedIntervalCount > 0 && intervalDistance > 0;
    // #4364 — money is only a number when it is one denomination AND
    // every contributing fill carried a price. Otherwise it is absent,
    // not zero: a partial numerator over a whole denominator is how a
    // fuel is made to look cheap.
    final denominable = pricingDenominable &&
        recordedSpend.isSingleDenomination &&
        unpricedFillCount == 0;
    final cost = denominable ? intervalCost : null;
    return FuelTypeEfficiencyStats(
      bucket: bucket,
      avgL100km: hasDistance && unit.isLitreBased
          ? (intervalLitres / intervalDistance) * 100
          : null,
      avgCostPerKm:
          hasDistance && cost != null ? cost / intervalDistance : null,
      recordedPurchaseSpend: denominable ? recordedSpend.soleAmount : null,
      recordedSpend: recordedSpend,
      unpricedFillCount: unpricedFillCount,
      quantityUnit: unit,
      fillCount: fillCount,
      attributedIntervalCount: attributedIntervalCount,
      legacyAttributedIntervalCount: legacyAttributedIntervalCount,
      // #3828 — these three were summed here and then dropped on the floor.
      // Surfacing them is what lets the screen state price per litre and
      // distance driven instead of only the two derived averages.
      totalLitres: intervalLitres,
      totalDistanceKm: intervalDistance,
      intervalCost: cost,
    );
  }
}
