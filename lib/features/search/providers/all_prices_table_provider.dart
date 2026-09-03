// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Riverpod seams for the all-prices fuel comparison table (#3933,
/// Epic #3925).
///
/// The card reads EVERYTHING it needs from here rather than from new
/// constructor parameters: `search_results_list.dart` is owned by the
/// sibling #3926 work and must not grow another argument. Three reads:
///
///   1. [allPricesBestByFuelProvider] — the cheapest price per fuel over
///      the visible result set (the delta reference + the emphasis).
///   2. [allPricesFuelCostModelProvider] — the active vehicle's measured
///      litres/100 km per fuel and the fuels it can physically take.
///   3. [allPricesColumnsProvider] — the stable column set for the list.
///
/// Cross-feature data is reached ONLY through the owning features'
/// `api.dart` barrels (`fill_ups`, `vehicle`), which
/// `test/lint/feature_boundary_test.dart` exempts — so no pair count moves.
///
/// Every provider degrades to an empty value on a fault: the all-prices
/// card must render a plain price table rather than take the search list
/// down when fill-up storage is not initialised (widget tests, first run).
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/country/country_provider.dart';
import '../../../core/domain/fuel_type.dart';
import '../../../core/domain/search_result_item.dart';
import '../../../core/domain/station.dart';
import '../../../core/error/guarded.dart';
import '../../../core/utils/station_extensions.dart';
import '../../fill_ups/api.dart';
import '../../vehicle/api.dart';
import 'all_prices_comparison_model.dart';
import 'search_provider.dart';

part 'all_prices_table_provider.g.dart';

/// What the active vehicle costs to drive, per fuel.
///
/// [litersPer100kmByFuel] is measured, never guessed: it comes from the
/// user's own full-to-full tank windows. [usableFuels] empty means "no
/// active vehicle" — the table then dims nothing and shows no per-100 km
/// row, exactly the documented degradation path.
class FuelCostModel {
  final Map<FuelType, double> litersPer100kmByFuel;
  final Set<FuelType> usableFuels;

  const FuelCostModel({
    this.litersPer100kmByFuel = const <FuelType, double>{},
    this.usableFuels = const <FuelType>{},
  });

  static const empty = FuelCostModel();

  /// True when at least one fuel has a measured consumption — i.e. the
  /// second number in each cell and the verdict line can be rendered.
  bool get hasConsumption => litersPer100kmByFuel.isNotEmpty;
}

/// Cheapest price per fuel across the results the list is showing.
///
/// Reads the SAME pipeline the list renders (`searchState` → the memoised
/// filter/sort), so the delta a cell shows is measured against what the
/// user can actually see, not against a hidden result set.
@riverpod
Map<FuelType, double> allPricesBestByFuel(Ref ref) {
  try {
    final state = ref.watch(searchStateProvider);
    final raw = state.asData?.value.data;
    if (raw == null || raw.isEmpty) return const <FuelType, double>{};
    final visible = ref.watch(filteredSortedSearchResultsProvider(raw));
    final stations = visible
        .whereType<FuelStationResult>()
        .map((r) => r.station)
        .toList(growable: false);
    return bestPriceByFuel(stations);
  } catch (e, st) {
    logFailure(e, st, where: 'allPricesBestByFuel');
    return const <FuelType, double>{};
  }
}

/// The active vehicle's per-fuel cost model, or [FuelCostModel.empty]
/// when there is no vehicle / no usable history.
///
/// The consumption numbers are NOT re-derived here (#3934): they come from
/// `fuelTypeEfficiencyComparisonProvider` — the fill-ups feature's own
/// per-fuel aggregator (ADR 0015 v3), the same one the consumption screen
/// renders — reached through the `fill_ups/api.dart` barrel. One model, so
/// the table and that screen can never state two different L/100 km for the
/// same tank history.
///
/// Only PURE buckets become a per-fuel figure. A MIX bucket (`E85/E10`) is
/// a blend the driver burned, not a grade they can buy at the pump, and
/// crediting its litres to the dominant grade is exactly the ADR 0014
/// collapse ADR 0015 rejected — so a mix contributes to no column, and a
/// fuel only ever driven blended simply has no cost-per-100 km cell.
///
/// The aggregator also owns the vehicle scoping: it keeps the ACTIVE
/// vehicle's own fills only, where the deleted local copy also swept in
/// fills carrying no `vehicleId`. Single-vehicle users see no difference
/// (their fills are the vehicle's); multi-vehicle users no longer risk a
/// stray unassigned fill of another car moving this car's number.
///
/// The pump-anchored gain (`VehicleProfile.pumpGain*`, Epic #3886) is
/// deliberately NOT applied: it trims ESTIMATED OBD2 fuel rates onto the
/// pump's litres, and these litres already come from the pump.
@riverpod
FuelCostModel allPricesFuelCostModel(Ref ref) {
  try {
    final vehicle = ref.watch(activeVehicleProfileProvider);
    if (vehicle == null) return FuelCostModel.empty;

    final declared = vehicle.preferredFuelType;
    final primary =
        declared == null ? FuelType.all : FuelType.fromString(declared);
    final usable = primary == FuelType.all
        ? const <FuelType>{}
        : (vehicle.multiFuelCapable
            ? compatibleFuelsFor(primary).toSet()
            : <FuelType>{primary});

    final byFuel = <FuelType, double>{};
    for (final stats in ref.watch(fuelTypeEfficiencyComparisonProvider)) {
      if (stats.isMix) continue;
      final l100 = stats.avgL100km;
      if (l100 == null || l100 <= 0) continue;
      byFuel[stats.dominant] = l100;
    }

    return FuelCostModel(
      litersPer100kmByFuel: byFuel,
      usableFuels: usable,
    );
  } catch (e, st) {
    logFailure(e, st, where: 'allPricesFuelCostModel');
    return FuelCostModel.empty;
  }
}

/// The stable column set every all-prices card renders.
///
/// Derived only from list-wide inputs (country fuel set, active vehicle,
/// best prices), so every card in the list gets the identical answer and
/// the columns line up.
@riverpod
AllPricesColumns allPricesColumns(Ref ref) {
  try {
    final country = ref.watch(activeCountryProvider);
    final cost = ref.watch(allPricesFuelCostModelProvider);
    return selectFuelColumns(
      countryFuels: country.supportedFuelTypes,
      vehicleFuels: cost.usableFuels,
      bestByFuel: ref.watch(allPricesBestByFuelProvider),
    );
  } catch (e, st) {
    logFailure(e, st, where: 'allPricesColumns');
    return AllPricesColumns.empty;
  }
}

/// The columns a single [station] should render when the list-wide set is
/// empty (no country resolved / a fault) — the station's own priced fuels
/// in canonical order. Keeps the card useful in isolation (route results,
/// widget tests) without ever reflowing inside a real result list.
AllPricesColumns fallbackColumnsForStation(Station station) {
  final own = kAllPricesFuelOrder
      .where((f) =>
          (station.priceFor(f) ?? 0) > 0 ||
          station.unavailableFuels.contains(f.apiValue))
      .toList(growable: false);
  return AllPricesColumns(
    visible: own.take(kAllPricesMaxColumns).toList(growable: false),
    overflow: own.skip(kAllPricesMaxColumns).toList(growable: false),
  );
}
