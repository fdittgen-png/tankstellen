import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../domain/entities/traffic_signal.dart';

/// Thrown by [OsmTrafficSignalClient] when the Overpass query fails to
/// reach the server, returns a non-2xx status, or yields a payload the
/// parser can't make sense of (#1125 phase 1).
///
/// All failure paths surface as this typed exception so the future
/// repository (and any UI it feeds) can branch on a single class instead
/// of catching `DioException` plus `FormatException` plus `TypeError`.
/// Mirrors the `*Exception` pattern used elsewhere in `lib/core/error/`.
class OsmTrafficSignalException implements Exception {
  final String message;
  const OsmTrafficSignalException(this.message);

  @override
  String toString() => 'OsmTrafficSignalException: $message';
}

/// HTTP client for OSM's Overpass API, scoped to the
/// `highway=traffic_signals` query the glide coach needs (#1125 phase 1).
///
/// Issues one Overpass query per bounding box and parses the JSON
/// response into [TrafficSignal] entities. The query is intentionally
/// narrow — node-only, single tag — so the public Overpass instance
/// (`overpass-api.de`) doesn't rate-limit users on routine calls.
///
/// The constructor accepts a [Dio] so tests can inject a mock; production
/// callers can pass nothing and pick up a default [Dio] instance.
///
/// All errors throw [OsmTrafficSignalException] — never silent. The
/// `test/lint/no_silent_catch_test.dart` static scan enforces this and
/// the rethrow path keeps the original cause attached via toString().
class OsmTrafficSignalClient {
  final Dio _dio;

  /// Endpoint for the public Overpass instance. The path is part of the
  /// URL (not the base) because Dio's request method takes the full URL
  /// when no base is configured — keeps test mocks straightforward.
  static const String endpoint = 'https://overpass-api.de/api/interpreter';

  OsmTrafficSignalClient({Dio? dio}) : _dio = dio ?? Dio();

  /// Fetch every `highway=traffic_signals` node inside the bounding box
  /// described by [south] / [west] / [north] / [east].
  ///
  /// [timeout] caps both connect and receive — the default of 15s sits
  /// between Overpass's own `[timeout:25]` ceiling and a tight enough
  /// budget that a hung server doesn't block the calling repo for long.
  Future<List<TrafficSignal>> fetchInBoundingBox({
    required double south,
    required double west,
    required double north,
    required double east,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final query =
        '[out:json][timeout:25];\n'
        'node["highway"="traffic_signals"]($south,$west,$north,$east);\n'
        'out;';

    Response<dynamic> response;
    try {
      response = await _dio.post<dynamic>(
        endpoint,
        data: query,
        options: Options(
          contentType: 'text/plain',
          responseType: ResponseType.json,
          sendTimeout: timeout,
          receiveTimeout: timeout,
        ),
      );
    } on DioException catch (e, st) {
      debugPrint('OsmTrafficSignalClient.fetchInBoundingBox dio error: '
          '${e.message}\n$st');
      throw OsmTrafficSignalException(
        'Overpass request failed: ${e.message ?? e.type.name}',
      );
    }

    if (response.statusCode == null ||
        response.statusCode! < 200 ||
        response.statusCode! >= 300) {
      throw OsmTrafficSignalException(
        'Overpass returned HTTP ${response.statusCode}',
      );
    }

    final data = response.data;
    if (data is! Map) {
      throw const OsmTrafficSignalException(
        'Overpass response was not a JSON object',
      );
    }

    final elements = data['elements'];
    if (elements is! List) {
      throw const OsmTrafficSignalException(
        'Overpass response is missing the "elements" array',
      );
    }

    try {
      return elements
          .whereType<Map>()
          .map(_parseElement)
          .whereType<TrafficSignal>()
          .toList(growable: false);
    } catch (e, st) {
      debugPrint('OsmTrafficSignalClient.fetchInBoundingBox parse error: '
          '$e\n$st');
      throw OsmTrafficSignalException('Failed to parse Overpass response: $e');
    }
  }

  /// Convert one Overpass element into a [TrafficSignal]. Returns null
  /// when the element is missing a coordinate so a single bad row
  /// doesn't poison the whole batch — the caller filters nulls out.
  TrafficSignal? _parseElement(Map element) {
    final lat = element['lat'];
    final lon = element['lon'];
    if (lat is! num || lon is! num) return null;

    final tagsRaw = element['tags'];
    String? crossing;
    String? highway;
    if (tagsRaw is Map) {
      final crossingRaw = tagsRaw['crossing'];
      final highwayRaw = tagsRaw['highway'];
      if (crossingRaw is String) crossing = crossingRaw;
      if (highwayRaw is String) highway = highwayRaw;
    }

    return TrafficSignal(
      id: element['id'].toString(),
      lat: lat.toDouble(),
      lng: lon.toDouble(),
      crossing: crossing,
      highway: highway,
    );
  }
}
