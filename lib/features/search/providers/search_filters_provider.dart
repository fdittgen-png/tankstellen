// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/price_utils.dart';
import '../../profile/providers/effective_fuel_type_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../domain/entities/fuel_type.dart';
import '../domain/entities/search_result_item.dart';
import '../domain/entities/station.dart';
import '../domain/search_result_filters.dart';
import '../presentation/widgets/sort_selector.dart';
import 'brand_filter_provider.dart';
import 'ignored_stations_provider.dart';
import 'mixed_results_filter_provider.dart';
import 'search_provider.dart';
import 'search_screen_ui_provider.dart';
import 'station_rating_provider.dart';

part 'search_filters_provider.g.dart';

/// Stores the resolved search location for display (ZIP + city).
@riverpod
class SearchLocation extends _$SearchLocation {
  @override
  String build() => '';

  void set(String location) => state = location;
}

@riverpod
class SelectedFuelType extends _$SelectedFuelType {
  @override
  FuelType build() {
    // Effective fuel (#704): when a profile is configured, the default
    // vehicle's fuel overrides the profile's own preferredFuelType so
    // the chips reflect "what does my car actually take" without the
    // user having to keep profile + vehicle manually in sync.
    //
    // No profile yet (fresh install, before the onboarding wizard) →
    // keep the historical "FuelType.all" wildcard so the first search
    // doesn't silently filter out non-E10 pumps.
    final profile = ref.watch(activeProfileProvider);
    if (profile == null) return FuelType.all;
    return ref.watch(effectiveFuelTypeProvider);
  }

  void select(FuelType type) {
    state = type;
  }
}

@riverpod
class SearchRadius extends _$SearchRadius {
  @override
  double build() {
    final profile = ref.watch(activeProfileProvider);
    return profile?.defaultSearchRadius ?? 10.0;
  }

  void set(double radius) {
    state = radius.clamp(1.0, 25.0);
  }
}

/// Extracts fuel [Station] objects from the unified search results.
///
/// Convenience for consumers that need [List<Station>] (cross-border
/// comparisons, driving mode, station detail lookup, brand filter chips).
@riverpod
List<Station> fuelStations(Ref ref) {
  final searchState = ref.watch(searchStateProvider);
  if (!searchState.hasValue) return const [];
  return searchState.value!.data
      .whereType<FuelStationResult>()
      .map((r) => r.station)
      .toList();
}

/// The [raw] search results after the ignored / brand / amenity / open
/// filters and the active sort — memoised (#1762).
///
/// The pipeline previously ran inline in `SearchResultsList.build()` and
/// re-executed on every rebuild. Keyed on the raw result set ([raw]) and
/// watching the filter / sort providers, it recomputes only when the
/// result set or a filter / sort input actually changes; an unrelated
/// rebuild that passes the same `raw` list reads the cached list for
/// free.
///
/// Per-kind filters never cross kinds (#1784): the brand / amenity /
/// open filters apply only to fuel rows; the EV connector / min-power
/// filters apply only to EV rows. The `ResultKind` filter then drops a
/// whole kind when the user narrows to Fuel-only or EV-only. Fuel rows
/// lead the list, preserving the fuel-first ordering before the sort.
@riverpod
List<SearchResultItem> filteredSortedSearchResults(
  Ref ref,
  List<SearchResultItem> raw,
) {
  final ignoredIds = ref.watch(ignoredStationsProvider);
  final selectedBrands = ref.watch(selectedBrandsProvider);
  final excludeHighway = ref.watch(excludeHighwayStationsProvider);
  final requiredAmenities = ref.watch(selectedAmenitiesProvider);
  final openOnly = ref.watch(openOnlyFilterProvider);
  final sortMode = ref.watch(selectedSortModeProvider);
  final fuelType = ref.watch(selectedFuelTypeProvider);
  final ratings = ref.watch(stationRatingsProvider);
  final kindFilter = ref.watch(resultKindFilterProvider);
  final evConnectors = ref.watch(evConnectorFilterProvider);
  final evMinPower = ref.watch(evMinPowerFilterProvider);

  final afterIgnored =
      raw.where((s) => !ignoredIds.contains(s.id)).toList();
  final fuelItems = afterIgnored.whereType<FuelStationResult>().toList();
  final evItems = afterIgnored.whereType<EVStationResult>().toList();

  final fuelFiltered = applyAmenityAndStatusFilters(
    applyBrandFilter(
      fuelItems.map((r) => r.station).toList(),
      selectedBrands: selectedBrands,
      excludeHighway: excludeHighway,
    ),
    requiredAmenities: requiredAmenities,
    openOnly: openOnly,
  );
  final filteredFuelIds = fuelFiltered.map((s) => s.id).toSet();
  final evFiltered = applyEvFilters(
    evItems,
    connectorTypes: evConnectors,
    minPowerKw: evMinPower,
  );
  final filtered = <SearchResultItem>[
    if (kindFilter != ResultKind.ev)
      ...fuelItems.where((r) => filteredFuelIds.contains(r.station.id)),
    if (kindFilter != ResultKind.fuel) ...evFiltered,
  ];

  return sortSearchResults(filtered, sortMode, fuelType, ratings);
}

/// Pure sort over a unified results list (#1762).
///
/// Takes the resolved fuel type and ratings as values rather than
/// reading them from a `WidgetRef`, so it is directly unit-testable.
/// An all-EV list always sorts by distance; otherwise [sortMode]
/// applies to fuel rows and EV rows fall back to distance.
List<SearchResultItem> sortSearchResults(
  List<SearchResultItem> items,
  SortMode sortMode,
  FuelType fuelType,
  Map<String, int> ratings,
) {
  final sorted = List<SearchResultItem>.from(items);

  // An all-EV list has no fuel-specific sort key — always by distance.
  if (sorted.every((item) => item is EVStationResult)) {
    sorted.sort((a, b) => a.dist.compareTo(b.dist));
    return sorted;
  }

  switch (sortMode) {
    case SortMode.distance:
      sorted.sort((a, b) => a.dist.compareTo(b.dist));
    case SortMode.price:
      sorted.sort((a, b) {
        final sa = a is FuelStationResult ? a.station : null;
        final sb = b is FuelStationResult ? b.station : null;
        if (sa != null && sb != null) return compareByPrice(sa, sb, fuelType);
        return a.dist.compareTo(b.dist);
      });
    case SortMode.name:
      sorted.sort((a, b) {
        final sa = a is FuelStationResult ? a.station : null;
        final sb = b is FuelStationResult ? b.station : null;
        if (sa != null && sb != null) return compareByName(sa, sb);
        return a.displayName.compareTo(b.displayName);
      });
    case SortMode.open24h:
      sorted.sort((a, b) {
        final sa = a is FuelStationResult ? a.station : null;
        final sb = b is FuelStationResult ? b.station : null;
        if (sa != null && sb != null) return compareByOpen24h(sa, sb);
        return a.dist.compareTo(b.dist);
      });
    case SortMode.rating:
      sorted.sort((a, b) {
        final sa = a is FuelStationResult ? a.station : null;
        final sb = b is FuelStationResult ? b.station : null;
        if (sa != null && sb != null) return compareByRating(sa, sb, ratings);
        return a.dist.compareTo(b.dist);
      });
    case SortMode.priceDistance:
      sorted.sort((a, b) {
        final sa = a is FuelStationResult ? a.station : null;
        final sb = b is FuelStationResult ? b.station : null;
        if (sa != null && sb != null) {
          return compareByPriceDistance(sa, sb, fuelType);
        }
        return a.dist.compareTo(b.dist);
      });
  }
  return sorted;
}
