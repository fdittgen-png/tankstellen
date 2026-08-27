// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../core/domain/fuel_type.dart';
import '../entities/fill_up.dart';
import '../entities/fuel_type_efficiency_stats.dart';

// Internals of `fuel_type_efficiency_aggregator.dart`, split out to keep
// that file under the #1680 400-line cap (move-only, behaviour
// preserved): the #3846 per-fuel pricing table and the two value
// holders the interval walker accumulates into. Nothing here is part of
// the feature's public contract — `fill_ups/api.dart` does not export it.

/// Volume-weighted price per litre for each fuel, over every real fill of
/// that fuel (#3846).
///
/// Weighted by volume rather than a plain mean so a 40 L fill counts more
/// than a 5 L top-up. Corrections are excluded (no litres, no money) and so
/// are fills with no recorded cost — a zero-cost fill would drag the average
/// toward zero and quietly make a fuel look free.
Map<String, double> weightedPricePerLitre(List<FillUp> sorted) {
  final litres = <String, double>{};
  final cost = <String, double>{};
  for (final f in sorted) {
    if (f.isCorrection) continue;
    if (f.liters <= 0 || f.totalCost <= 0) continue;
    final key = f.fuelType.apiValue;
    litres.update(key, (v) => v + f.liters, ifAbsent: () => f.liters);
    cost.update(key, (v) => v + f.totalCost, ifAbsent: () => f.totalCost);
  }
  return {
    for (final key in litres.keys)
      if (litres[key]! > 0) key: cost[key]! / litres[key]!,
  };
}

/// An interval's carried-over opening tank content (v3, #3764): litres per
/// `FuelType.apiValue` plus the fuel objects for label resolution.
class OpeningContent {
  const OpeningContent(this.litresByFuel, this.fuelByApiValue);

  final Map<String, double> litresByFuel;
  final Map<String, FuelType> fuelByApiValue;
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
      legacyAttributedIntervalCount: legacyAttributedIntervalCount,
      // #3828 — these three were summed here and then dropped on the floor.
      // Surfacing them is what lets the screen state price per litre and
      // distance driven instead of only the two derived averages.
      totalLitres: intervalLitres,
      totalDistanceKm: intervalDistance,
      intervalCost: intervalCost,
    );
  }
}
