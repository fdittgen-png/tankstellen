import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/services/dio_factory.dart';
import '../../../../core/services/service_result.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../domain/entities/route_info.dart';

/// OSRM (Open Source Routing Machine) client for driving route calculation.
///
/// Free public demo server, no API key required.
/// Returns route geometry + distance + duration.
class RoutingService {
  final Dio _dio = DioFactory.create(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  );

  static const _baseUrl = 'https://router.project-osrm.org';

  /// Get a driving route between waypoints.
  ///
  /// Returns [RouteInfo] with full polyline geometry and sample points
  /// every ~15km for station queries along the route.
  ///
  /// When [avoidHighways] is true, attempts to exclude motorways from the
  /// route. Falls back to a normal route if the OSRM server does not
  /// support the `exclude` parameter (the public demo server doesn't).
  Future<ServiceResult<RouteInfo>> getRoute(List<RouteWaypoint> waypoints, {bool avoidHighways = false}) async {
    if (waypoints.length < 2) {
      throw const ApiException(message: 'At least 2 waypoints required');
    }

    try {
      // OSRM uses lon,lat order (not lat,lon)
      final coords = waypoints
          .map((w) => '${w.lng},${w.lat}')
          .join(';');

      Map<String, dynamic> data;

      if (avoidHighways) {
        // Try with exclude=motorway first; fall back if unsupported
        final response = await _dio.get(
          '$_baseUrl/route/v1/driving/$coords',
          queryParameters: {
            'overview': 'full',
            'geometries': 'geojson',
            'steps': 'false',
            'exclude': 'motorway',
          },
        );
        data = response.data as Map<String, dynamic>;

        if (data['code'] != 'Ok') {
          debugPrint('RouteSearch: exclude=motorway not supported, falling back to normal route');
          final fallback = await _dio.get(
            '$_baseUrl/route/v1/driving/$coords',
            queryParameters: {
              'overview': 'full',
              'geometries': 'geojson',
              'steps': 'false',
            },
          );
          data = fallback.data as Map<String, dynamic>;
        }
      } else {
        final response = await _dio.get(
          '$_baseUrl/route/v1/driving/$coords',
          queryParameters: {
            'overview': 'full',
            'geometries': 'geojson',
            'steps': 'false',
          },
        );
        data = response.data as Map<String, dynamic>;
      }

      if (data['code'] != 'Ok') {
        throw ApiException(
          message: data['message']?.toString() ?? 'OSRM routing failed',
        );
      }

      final routes = data['routes'] as List<dynamic>;
      if (routes.isEmpty) {
        throw const ApiException(message: 'No route found');
      }

      final route = routes[0] as Map<String, dynamic>;
      final distanceM = (route['distance'] as num).toDouble();
      final durationS = (route['duration'] as num).toDouble();

      // Parse GeoJSON geometry → List<LatLng>
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List<dynamic>;
      final polyline = coordinates.map((c) {
        final coord = c as List<dynamic>;
        // GeoJSON is [lon, lat]
        return LatLng(
          (coord[1] as num).toDouble(),
          (coord[0] as num).toDouble(),
        );
      }).toList();

      // Sample points every ~15km along the polyline
      final samplePoints = _sampleAlongPolyline(polyline, 15.0);

      return ServiceResult(
        data: RouteInfo(
          geometry: polyline,
          distanceKm: distanceM / 1000,
          durationMinutes: durationS / 60,
          samplePoints: samplePoints,
        ),
        source: ServiceSource.osrmRouting,
        fetchedAt: DateTime.now(),
      );
    } on DioException catch (e) {
      throw ApiException(
        message: e.message ?? 'Route calculation failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Walk the polyline and emit a point every [intervalKm] kilometers.
  List<LatLng> _sampleAlongPolyline(List<LatLng> polyline, double intervalKm) {
    if (polyline.isEmpty) return [];

    final samples = <LatLng>[polyline.first];
    double accumulated = 0;

    for (var i = 1; i < polyline.length; i++) {
      final prev = polyline[i - 1];
      final curr = polyline[i];
      final segmentDist = distanceKm(
        prev.latitude, prev.longitude,
        curr.latitude, curr.longitude,
      );
      accumulated += segmentDist;

      if (accumulated >= intervalKm) {
        samples.add(curr);
        accumulated = 0;
      }
    }

    // Always include the last point
    if (samples.last != polyline.last) {
      samples.add(polyline.last);
    }

    return samples;
  }
}
