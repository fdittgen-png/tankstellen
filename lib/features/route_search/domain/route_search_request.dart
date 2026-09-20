// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/domain/fuel_type.dart';
import 'entities/route_info.dart';
import 'route_search_strategy.dart';

/// One submitted route search, frozen (#4432).
///
/// The search used to exist only as arguments on the wire: once
/// `searchAlongRoute` had been called there was nothing to point at that
/// said "this is the request the results belong to". Two consequences
/// the field report walked into — a refresh could not re-run the ROUTE
/// (the screens replayed the nearby search instead, which re-fixed the
/// stored user position and left the corridor exactly as stale), and
/// nothing could tell an old sweep's late answer from the current one.
///
/// [revision] is the generation the provider fenced its publications
/// against, so a stored request and a published result can be matched.
@immutable
class RouteSearchRequest {
  const RouteSearchRequest({
    required this.revision,
    required this.waypoints,
    required this.fuelType,
    required this.searchRadiusKm,
    required this.strategyType,
    this.segmentKm,
    this.minSavingPerLiter,
    this.originCapturedAt,
  });

  final int revision;
  final List<RouteWaypoint> waypoints;
  final FuelType fuelType;
  final double searchRadiusKm;
  final RouteSearchStrategyType strategyType;
  final double? segmentKm;
  final double? minSavingPerLiter;

  /// When the origin fix was measured, for a vehicle-position origin.
  final DateTime? originCapturedAt;

  /// Whether the start is the driver's own position rather than a place
  /// they named — the difference between "refresh means from where I am
  /// now" and "refresh means the same origin, newer prices".
  bool get originIsVehiclePosition =>
      waypoints.isNotEmpty && waypoints.first.isVehiclePosition;

  /// The same request with the origin moved to [coords], measured at
  /// [at]. Every other endpoint, waypoint and option is carried
  /// unchanged — a refresh must not quietly become a different search.
  RouteSearchRequest withOrigin(LatLng coords, DateTime? at) =>
      RouteSearchRequest(
        revision: revision,
        waypoints: [
          waypoints.first.copyWith(
            lat: coords.latitude,
            lng: coords.longitude,
          ),
          ...waypoints.skip(1),
        ],
        fuelType: fuelType,
        searchRadiusKm: searchRadiusKm,
        strategyType: strategyType,
        segmentKm: segmentKm,
        minSavingPerLiter: minSavingPerLiter,
        originCapturedAt: at,
      );
}
