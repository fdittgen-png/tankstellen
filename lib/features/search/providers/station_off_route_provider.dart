// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/search_mode.dart';
import '../../route_search/api.dart';
import 'search_mode_provider.dart';

part 'station_off_route_provider.g.dart';

/// Station id → where that station sits on the ACTIVE route (#4432):
/// its along-route progress and its geometric offset from the route
/// line, as one [RouteStopMetrics] stamped with the route revision.
///
/// ## What this is, exactly
///
/// Both figures are measured against THIS route's own geometry by
/// `routeStopMetricsFor` — the one `RouteProjection` itinerary pass the
/// corridor filter, the list order and the refuel plan (#4146) share,
/// so "off the route" and "how far along" each have one definition.
/// They are **geometric**: neither is the distance from the driver nor
/// the extra driving a stop would cost (those are the routed
/// `StationTravelEstimate` quantities, #4359), and the row that shows
/// them says so.
///
/// ## The bug it replaces
///
/// A route row showed `Auchan · 4,4 km` in exactly the typography a
/// proximity row uses for "4.4 km from you". That number was
/// `Station.dist` — computed by the country service from whichever
/// sample point's query happened to return the station first, and kept
/// by the dedup — so it was not a stable quantity at all: the same
/// station could carry a different figure depending on batch order. The
/// route surfaces must not show it, and must not substitute the radar's
/// `roadDistancesProvider` value either, which is keyed by station id
/// from a different search's origin.
///
/// ## Why a side channel
///
/// Same shape as `roadDistancesProvider` and
/// `highwayExitInfoMapProvider`: the station card is shared by the
/// search list, the favourites list, the radar and the route list, and
/// threading one more value through every call site costs more than it
/// buys (and would push `StationCard` past the #3985 constructor-arity
/// gate). A row asks this map whether IT belongs to the active route;
/// every other surface reads an empty map and renders as before.
///
/// Empty unless a route search is the active one, so a route result
/// left in memory cannot relabel the distances in a nearby search.
@riverpod
Map<String, RouteStopMetrics> stationRouteMetrics(Ref ref) {
  if (ref.watch(activeSearchModeProvider) != SearchMode.route) {
    return const <String, RouteStopMetrics>{};
  }
  final result = ref.watch(routeSearchStateProvider).value;
  if (result == null || result.stations.isEmpty) {
    return const <String, RouteStopMetrics>{};
  }
  return routeStopMetricsFor(result);
}
