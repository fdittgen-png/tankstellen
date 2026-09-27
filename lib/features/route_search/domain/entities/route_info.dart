// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:latlong2/latlong.dart';

part 'route_info.freezed.dart';

/// A resolved driving route from OSRM.
@freezed
abstract class RouteInfo with _$RouteInfo {
  const factory RouteInfo({
    required List<LatLng> geometry,       // Full polyline coordinates
    required double distanceKm,
    required double durationMinutes,
    required List<LatLng> samplePoints,  // Every ~15km for station queries
  }) = _RouteInfo;
}

/// A named waypoint in a route (start, stop, or destination).
@freezed
abstract class RouteWaypoint with _$RouteWaypoint {
  const factory RouteWaypoint({
    required double lat,
    required double lng,
    required String label,

    /// #4432 — this waypoint is where the VEHICLE is, read from GPS at
    /// search time, not a place the user named.
    ///
    /// The distinction is not cosmetic. An origin that is the driver
    /// moves: a refresh re-resolves it from GPS, so the corridor starts
    /// where the vehicle is NOW and a forecourt already passed falls out
    /// of it (`RouteSearchState.refresh`). A named city stays put, so the
    /// flag defaults to false and every existing caller keeps a fixed
    /// origin.
    @Default(false) bool isVehiclePosition,
  }) = _RouteWaypoint;
}
