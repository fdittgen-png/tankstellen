// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../search/domain/entities/search_result_item.dart';
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

  const RouteSearchResult({
    required this.route,
    required this.stations,
    this.cheapestId,
    this.cheapestPerSegment,
    this.strategyType = RouteSearchStrategyType.uniform,
    this.isPartial = false,
    this.corridorCountryCodes = const {},
  });
}
