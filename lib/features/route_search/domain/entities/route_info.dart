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
    /// The distinction is not cosmetic. An origin that is the driver has
    /// a direction: everything behind it has been passed and is not a
    /// candidate (`dropStationsBehindOrigin`). A named city has no
    /// behind — it has a near side and a far side — so the flag defaults
    /// to false and every existing caller keeps the old corridor.
    @Default(false) bool isVehiclePosition,
  }) = _RouteWaypoint;
}
