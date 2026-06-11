// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/domain/fuel_type.dart';
import '../../../core/domain/search_result_item.dart';
import '../data/cross_border_corridor.dart' show contributingCountryCodesFor;
import 'entities/route_info.dart';
import 'route_search_strategy.dart';

/// State for route-based search: the route itself + stations found along it.
class RouteSearchResult {
  final RouteInfo route;
  final List<SearchResultItem> stations;
  final String? cheapestId;

  /// Maps segment index to the cheapest station ID within that segment.
  /// Segments are computed based on [segmentKm] intervals along the route.
  final Map<int, String>? cheapestPerSegment;

  /// Which strategy was used for this search.
  final RouteSearchStrategyType strategyType;

  /// #2103 lever C — true when emitted from the incremental
  /// `onPartial` sink mid-sweep, false on the final post-isolate
  /// result. Allows the UI to render a "still loading" affordance
  /// on top of the running list. Defaults to false so existing
  /// consumers see no behaviour change.
  final bool isPartial;

  /// #2622 — the upper-cased ISO codes of every country the search's
  /// corridor actually queried (the keys of `buildCorridorServiceMap`).
  ///
  /// For a cross-border route (#2626) this carries e.g. `{FR, ES}` so the
  /// result header can credit BOTH data sources instead of only the active
  /// country. Empty for a single-country route or when the corridor map was
  /// empty (an entirely mid-sea route), in which case the UI falls back to
  /// the single-country attribution.
  final Set<String> corridorCountryCodes;

  /// #2680 — the upper-cased ISO codes of the countries that ACTUALLY produced
  /// a *displayable* fuel station in [stations], a SUBSET of
  /// [corridorCountryCodes].
  ///
  /// The attribution banner consumes THIS (not [corridorCountryCodes]) so a
  /// cross-border search for a fuel a country doesn't sell (E85 in Spain —
  /// every MITECO row's `Precio Bioetanol` is empty) credits only the data
  /// sources that produced a priced station, never a leg shown entirely as
  /// "--". Each station's displayed grade is resolved exactly as the list/map
  /// resolve it — [contributingCountryCodesFor] runs [fuelForStation] with
  /// THIS result's [profileFuelByCountry] and the caller's active [fuelType]
  /// fallback. Derived from the full found set [stations] (not the Best-Stops
  /// display subset), so the banner is stable across the All / Best toggle.
  /// [corridorCountryCodes] is retained for diagnostics (it records the full
  /// geographic span the search queried).
  Set<String> contributingCountryCodes(FuelType fuelType) =>
      contributingCountryCodesFor(stations, profileFuelByCountry, fuelType);

  /// #2631 — profile fuel keyed by upper-cased country code (the same map
  /// `buildCorridorServiceMap` was built from). The map + list display
  /// resolve each station's price by ITS country's fuel from this map
  /// (offline, via the station's lat/lng), so a cross-border ES station
  /// shows the E10 price an E85 driver would actually pay instead of '--'.
  /// Empty for the single-country path, where the active fuel is used and
  /// the display is byte-identical to the pre-#2631 strict behaviour
  /// (#2510 — no within-country fallback).
  final Map<String, FuelType> profileFuelByCountry;

  const RouteSearchResult({
    required this.route,
    required this.stations,
    this.cheapestId,
    this.cheapestPerSegment,
    this.strategyType = RouteSearchStrategyType.uniform,
    this.isPartial = false,
    this.corridorCountryCodes = const {},
    this.profileFuelByCountry = const {},
  });
}
