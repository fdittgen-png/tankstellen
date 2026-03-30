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
  }) = _RouteWaypoint;
}
