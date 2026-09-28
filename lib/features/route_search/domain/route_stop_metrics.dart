// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:meta/meta.dart';

import '../../../core/utils/route_projection.dart';
import 'route_search_result.dart';

/// The two GEOMETRIC facts about one station on one route request
/// (#4432, checkpoint 3's distance-provenance table).
///
/// A route row used to carry one undifferentiated `Station.dist` — the
/// crow-flies figure from whichever sample-point query first returned
/// the station. The issue's table names five distinct quantities; these
/// are the two that geometry alone can answer, each with its own label:
///
/// | quantity | field | presented as |
/// |---|---|---|
/// | along-route progress | [alongKm] | "Around km N of this route" |
/// | geometric corridor offset | [offRouteKm] | "N km from the route · geometric estimate" |
///
/// The other three — road distance/time to the station, the extra road
/// distance/time of the stop, and the evidence status of those — are
/// the routed `StationTravelEstimate` contract (#4359). Nothing here
/// stands in for them: neither figure is a driven distance, and neither
/// is "from you" once the driver has moved.
///
/// Both come from the ONE itinerary pass of [RouteProjection] — the same
/// pass the corridor filter admitted the station by and the list sorts
/// by — so the number on a row always agrees with the row's position in
/// the list. [routeRevision] ties the value to the request it was
/// measured on: a metric of the previous route can never be read as one
/// of the current route.
@immutable
class RouteStopMetrics {
  const RouteStopMetrics({
    required this.routeRevision,
    required this.alongKm,
    required this.offRouteKm,
  });

  /// The route request these metrics were measured on.
  final int routeRevision;

  /// How far from the route START the route meets the station, in km —
  /// its ordered position on the route, not a distance from the driver.
  final double alongKm;

  /// Straight-line distance from the route line to the station, in km —
  /// one way, flown not driven: never a road detour.
  final double offRouteKm;

  @override
  bool operator ==(Object other) =>
      other is RouteStopMetrics &&
      other.routeRevision == routeRevision &&
      other.alongKm == alongKm &&
      other.offRouteKm == offRouteKm;

  @override
  int get hashCode => Object.hash(routeRevision, alongKm, offRouteKm);

  @override
  String toString() => 'RouteStopMetrics(r$routeRevision, '
      'along: ${alongKm.toStringAsFixed(2)}, '
      'off: ${offRouteKm.toStringAsFixed(2)})';
}

/// Station id → [RouteStopMetrics] for every station of [result],
/// measured on [result]'s own route geometry.
///
/// Empty when the route has no geometry: with nothing to measure against,
/// no route figure is invented.
Map<String, RouteStopMetrics> routeStopMetricsFor(RouteSearchResult result) {
  final projection = RouteProjection(result.route.geometry);
  if (projection.isEmpty) return const <String, RouteStopMetrics>{};
  final revision = result.routeRevision;
  return <String, RouteStopMetrics>{
    for (final station in result.stations)
      if (projection.project(station.lat, station.lng)
          case (:final alongKm, :final offRouteKm))
        station.id: RouteStopMetrics(
          routeRevision: revision,
          alongKm: alongKm,
          offRouteKm: offRouteKm,
        ),
  };
}
