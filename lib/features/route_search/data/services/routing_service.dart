// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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
        final response = await _dio.get<dynamic>(
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
          final fallback = await _dio.get<dynamic>(
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
        final response = await _dio.get<dynamic>(
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
    } on DioException catch (e, st) {
      Error.throwWithStackTrace(
        ApiException(
          message: e.message ?? 'Route calculation failed',
          statusCode: e.response?.statusCode,
        ),
        st,
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

  /// #3634 — real road distances from ONE origin to [destinations] in a
  /// single OSRM `/table` request (`sources=0`, distance annotation).
  ///
  /// Returns km per destination, `null` where OSRM reports the point
  /// unreachable or omits the distances matrix (some servers disable the
  /// annotation) — callers keep the crow-flies figure then. Never maps
  /// durations onto distances.
  /// #3637 — with [originBearingDegrees] the origin snaps only onto road
  /// segments matching the travel direction (±[kOsrmBearingToleranceDeg]),
  /// so a driver on the northbound carriageway gets northbound-departure
  /// distances — the opposite carriageway and backwards departures cost
  /// their real turn-around km. If the constrained call answers all-null
  /// (no segment matched a noisy heading), ONE unconstrained retry keeps
  /// the feature alive — direction-awareness must never cost the figures.
  Future<List<double?>> roadDistancesKm({
    required double originLat,
    required double originLng,
    required List<({double lat, double lng})> destinations,
    double? originBearingDegrees,
  }) async {
    if (destinations.isEmpty) return const [];
    Future<List<double?>> call(double? bearing) async {
      final response = await _dio.get<dynamic>(
        '$_baseUrl/table/v1/driving/'
        '${osrmTableCoords(originLat, originLng, destinations)}',
        queryParameters: osrmTableParams(
          destinationCount: destinations.length,
          originBearingDegrees: bearing,
        ),
      );
      return parseOsrmTableDistancesKm(
        response.data as Map<String, dynamic>,
        destinationCount: destinations.length,
      );
    }

    final first = await call(originBearingDegrees);
    if (originBearingDegrees == null || first.any((d) => d != null)) {
      return first;
    }
    return call(null);
  }
}

/// Pure parser for the OSRM `/table` response (#3634): the first (only)
/// row of `distances` holds metres from the origin, index 0 being the
/// origin-to-origin zero which is skipped. Null-safe against servers
/// that omit the matrix, rows shorter than expected, and per-cell nulls
/// (unreachable snap).
List<double?> parseOsrmTableDistancesKm(
  Map<String, dynamic> json, {
  required int destinationCount,
}) {
  final none = List<double?>.filled(destinationCount, null);
  if (json['code'] != 'Ok') return none;
  final distances = json['distances'];
  if (distances is! List || distances.isEmpty) return none;
  final row = distances.first;
  if (row is! List) return none;
  return [
    for (var i = 1; i <= destinationCount; i++)
      if (i < row.length && row[i] is num)
        (row[i] as num).toDouble() / 1000.0
      else
        null,
  ];
}

/// Bearing snap tolerance (°) for the direction-aware origin (#3637) —
/// wide enough for GPS course noise on a straight carriageway, narrow
/// enough to exclude the opposite direction.
const double kOsrmBearingToleranceDeg = 25;

/// OSRM `lon,lat;lon,lat…` coordinate path segment (#3637, extracted so
/// the query shape is unit-testable without Dio).
String osrmTableCoords(
  double originLat,
  double originLng,
  List<({double lat, double lng})> destinations,
) {
  final coords = StringBuffer('$originLng,$originLat');
  for (final d in destinations) {
    coords.write(';${d.lng},${d.lat}');
  }
  return coords.toString();
}

/// OSRM `/table` query parameters (#3637). The `bearings` list MUST
/// carry one entry per coordinate — the origin's `deg,tolerance`
/// followed by one empty (unconstrained) entry per destination.
Map<String, String> osrmTableParams({
  required int destinationCount,
  double? originBearingDegrees,
}) {
  final params = <String, String>{
    'sources': '0',
    'annotations': 'distance',
  };
  final b = originBearingDegrees;
  if (b != null && b.isFinite) {
    params['bearings'] =
        '${b.round() % 360},${kOsrmBearingToleranceDeg.round()}'
        '${';' * destinationCount}';
  }
  return params;
}
