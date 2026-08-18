// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/fuel_type.dart';
import '../domain/entities/consumption_stats.dart';
import '../domain/services/fill_up_monthly_stats_aggregator.dart';
import 'consumption_providers.dart';

part 'monthly_fuel_stats_provider.g.dart';

/// Per-month fill-up statistics for the consumption-statistics detail
/// page (#2698), oldest first. Each month carries the FULL
/// `ConsumptionStats` for that month's fill-ups via the canonical
/// `ConsumptionStats.fromFillUps` window walker — so the page can show
/// month-over-month comparison + evolution charts with no new storage.
///
/// Lives in its own file (not the [fillUpListProvider] god-class) so the
/// 975-line consumption_providers.dart stays at its file_length snapshot.
@riverpod
List<MonthlyFuelStats> monthlyFuelStats(Ref ref) =>
    FillUpMonthlyStatsAggregator.byMonth(ref.watch(fillUpListProvider));

/// Distinct fuel types present in the fill-up list, first-seen order —
/// drives the per-fuel filter chips on the statistics page (#3691).
@riverpod
List<FuelType> loggedFuelTypes(Ref ref) {
  final seen = <FuelType>[];
  for (final f in ref.watch(fillUpListProvider)) {
    if (!seen.contains(f.fuelType)) seen.add(f.fuelType);
  }
  return seen;
}

/// [monthlyFuelStats] restricted to ONE fuel type (#3691) — null keeps
/// the all-fuels view. Same aggregator, filtered input, so every
/// per-month metric answers "how does THIS fuel perform on the car".
@riverpod
List<MonthlyFuelStats> monthlyFuelStatsForFuel(Ref ref, FuelType? fuel) {
  if (fuel == null) return ref.watch(monthlyFuelStatsProvider);
  return FillUpMonthlyStatsAggregator.byMonth([
    for (final f in ref.watch(fillUpListProvider))
      if (f.fuelType == fuel) f,
  ]);
}

/// [consumptionStats] restricted to ONE fuel type (#3691) — null keeps
/// the all-fuels aggregate. Feeds the header tiles and the
/// month-over-month card under a fuel filter.
@riverpod
ConsumptionStats consumptionStatsForFuel(Ref ref, FuelType? fuel) {
  if (fuel == null) return ref.watch(consumptionStatsProvider);
  return ConsumptionStats.fromFillUps([
    for (final f in ref.watch(fillUpListProvider))
      if (f.fuelType == fuel) f,
  ]);
}
