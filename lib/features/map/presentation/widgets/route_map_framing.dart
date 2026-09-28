// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/domain/search_result_item.dart';
import '../../../route_search/api.dart'
    show
        RouteInfo,
        RouteSearchResult,
        RouteStopMetrics,
        routeStopMetricsFor;
import 'station_map_geometry.dart';

/// What the route map derives from its result and must hold per ROUTE,
/// not per rebuild and not per widget lifetime (#4432): the camera frame
/// and the per-station route metrics.
///
/// Owned by the route map's state. Split out of `RouteMapView` so the
/// keying rule — when is a result "the same route"? — lives in one small,
/// testable place.
class RouteMapFraming {
  LatLngBounds? _bounds;
  int? _boundsRevision;
  RouteInfo? _boundsRoute;
  bool _boundsFromStations = false;

  RouteSearchResult? _metricsOf;
  Map<String, RouteStopMetrics> _metrics = const {};

  /// Whether [now] is a different route from [old]: a new request
  /// revision, or a new route object (a re-route inside one request).
  /// Partial batches of one request share both.
  static bool isNewRoute(RouteSearchResult old, RouteSearchResult now) =>
      old.routeRevision != now.routeRevision ||
      !identical(old.route, now.route);

  /// #2782 — the camera target: the bounds of the along-route fuel
  /// STATIONS (the search results). #2755 originally framed the full route
  /// polyline so the camera showed the COMPLETE itinerary, but for a
  /// cross-border itinerary that polyline spans both countries and the
  /// camera zooms far out ("shows far too much"). Framing the results
  /// keeps the scope fit to what the user is actually looking at.
  /// Computed from ALL result stations (not the displayed All/Best
  /// subset), so it stays constant across the toggle and keeps
  /// `StationMapLayers`' value-`==` `_lastFitBounds` guard a no-op — the
  /// camera holds and never re-zooms to the changed subset.
  ///
  /// #4432 — keyed by the ROUTE. This used to be a `late final` on the
  /// map state, so a new search (route revision N+1) landing on the same
  /// map kept framing revision N's stations. It is now recomputed exactly
  /// when the route changes ([isNewRoute]) and otherwise held, so the
  /// partial batches of one route and the All/Best toggle do not move
  /// the camera. The one same-route recompute is the first batch that
  /// brings stations to a route framed so far only by its polyline
  /// (nothing had been found yet); after that the frame is fixed.
  LatLngBounds boundsFor(RouteSearchResult result) {
    final bounds = _bounds;
    final sameRoute = bounds != null &&
        _boundsRevision == result.routeRevision &&
        identical(_boundsRoute, result.route);
    if (sameRoute &&
        (_boundsFromStations ||
            !result.stations.any((s) => s is FuelStationResult))) {
      return bounds;
    }
    final (fresh, fromStations) = _computeBounds(result);
    _bounds = fresh;
    _boundsRevision = result.routeRevision;
    _boundsRoute = result.route;
    _boundsFromStations = fromStations;
    return fresh;
  }

  /// #4432 — along-route progress and corridor offset of every result
  /// station, measured on THIS result's route (never the first-seen
  /// `Station.dist`). Memoised on the result object: one O(n · P)
  /// projection per published result, not per rebuild.
  Map<String, RouteStopMetrics> metricsFor(RouteSearchResult result) {
    if (!identical(_metricsOf, result)) {
      _metricsOf = result;
      _metrics = routeStopMetricsFor(result);
    }
    return _metrics;
  }

  /// Build the framing bounds from the along-route fuel STATIONS (the
  /// search results) so the camera scope fits what was found (#2782).
  /// Falls back to the full route polyline only when there are no
  /// stations (so an empty route still frames something), then to a
  /// Paris box if there is no geometry either. A degenerate single-point
  /// set gets a tiny epsilon box so `CameraFit.bounds` can't
  /// divide-by-zero (as in `trip_path_map_card.dart`).
  ///
  /// Also answers whether the bounds came from stations (true) or only
  /// from the polyline fallback (false).
  static (LatLngBounds, bool) _computeBounds(RouteSearchResult result) {
    final points = <LatLng>[
      for (final r in result.stations.whereType<FuelStationResult>())
        LatLng(r.station.lat, r.station.lng),
    ];
    final fromStations = points.isNotEmpty;
    if (points.isEmpty) {
      // No results to frame — fall back to the route geometry so the
      // itinerary is still visible, then to the canonical fallback box.
      points.addAll(result.route.geometry);
    }
    // #3488 — delegates to the canonical NaN-safe / zero-span-safe helper:
    // it drops non-finite points, falls back to a finite box when empty,
    // and epsilon-pads any near-zero span (single point OR several
    // co-located stations) so `CameraFit.bounds` never divides-by-zero.
    return (StationMapGeometry.boundsOfPoints(points), fromStations);
  }
}
