// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/dio_factory.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart'
    show ConnectorType;
import '../../domain/entities/charging_station.dart';
import 'ocm_poi_parser.dart';

/// Abstract contract for an EV charging station backend.
///
/// Allows the rest of the app to swap between real OpenChargeMap calls
/// and the built-in [DemoEvStationService] without leaking Dio/HTTP
/// details into the presentation layer.
abstract class EvStationService {
  /// Fetch charging stations inside a bounding box around [centerLat]/
  /// [centerLng] with the given [radiusKm].
  Future<List<ChargingStation>> fetchStations({
    required double centerLat,
    required double centerLng,
    required double radiusKm,
  });
}

/// Open Charge Map-backed [EvStationService].
///
/// Performs a live OCM `/poi/` query around the viewport centre and
/// parses each result via the shared [OcmPoiParser] — the *same* logic
/// (including the `UsageType` access-cost signal, #2618) the search-side
/// `EVChargingService` uses (#2634). [DemoEvStationService] remains the
/// safety net: no API key, a network/parse error, or tests/offline all
/// transparently fall back to the deterministic demo dataset, so map
/// markers degrade gracefully instead of vanishing.
class OpenChargeMapService implements EvStationService {
  final String? apiKey;
  final EvStationService _fallback;
  final Dio _dio;

  /// Default Dio — separate so tests can inject a capturing/recorded Dio
  /// without re-implementing the BaseOptions (mirrors EVChargingService).
  static Dio _defaultDio() => DioFactory.create(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
      );

  OpenChargeMapService({
    this.apiKey,
    EvStationService? fallback,
    Dio? dio,
  })  : _fallback = fallback ?? const DemoEvStationService(),
        _dio = dio ?? _defaultDio();

  /// Same OCM POI endpoint the search-side service hits.
  static const _baseUrl = 'https://api.openchargemap.io/v3/poi/';

  @override
  Future<List<ChargingStation>> fetchStations({
    required double centerLat,
    required double centerLng,
    required double radiusKm,
  }) async {
    final key = apiKey?.trim();
    if (key == null || key.isEmpty) {
      debugPrint('OpenChargeMapService: no API key, using demo data');
      return _demo(centerLat, centerLng, radiusKm);
    }

    try {
      final response = await _dio.get<dynamic>(
        _baseUrl,
        queryParameters: {
          'output': 'json',
          'latitude': centerLat,
          'longitude': centerLng,
          'distance': radiusKm,
          'distanceunit': 'KM',
          'maxresults': 100,
          'compact': true,
          'verbose': false,
          // 'countrycode' intentionally omitted — OCM's strict country
          // filter drops legitimate border-region chargers (#697); the
          // lat/lng + distance bbox is the geographic constraint we need.
          'key': key,
        },
      );

      final data = response.data;
      if (data is! List) {
        return _demo(centerLat, centerLng, radiusKm);
      }
      return OcmPoiParser.parsePoiList(data, centerLat, centerLng);
    } on DioException catch (e, st) {
      // Network error / non-2xx / cancel — degrade to demo so the map
      // overlay still renders something rather than throwing (#2634).
      debugPrint('OpenChargeMapService: OCM fetch failed ($e); using demo. $st');
      return _demo(centerLat, centerLng, radiusKm);
    }
  }

  Future<List<ChargingStation>> _demo(
    double centerLat,
    double centerLng,
    double radiusKm,
  ) =>
      _fallback.fetchStations(
        centerLat: centerLat,
        centerLng: centerLng,
        radiusKm: radiusKm,
      );
}

/// Deterministic demo dataset used when no API key is configured.
///
/// Generates a small cluster of synthetic charging stations around the
/// requested map center so the feature is visibly functional end-to-end
/// without external dependencies. Coordinates are offset in both axes and
/// capped to a 5 km radius regardless of request size.
class DemoEvStationService implements EvStationService {
  const DemoEvStationService();

  @override
  Future<List<ChargingStation>> fetchStations({
    required double centerLat,
    required double centerLng,
    required double radiusKm,
  }) async {
    // ~0.009 deg latitude ≈ 1 km.
    const step = 0.009;
    final samples = <_DemoSample>[
      const _DemoSample(
        id: 'demo-1',
        name: 'Demo Fast Charger',
        operator: 'Ionity',
        latOffset: step * 1.2,
        lngOffset: step * 0.8,
        connectors: [
          EvConnector(
            id: 'demo-1-a',
            type: ConnectorType.ccs,
            maxPowerKw: 150,
            status: ConnectorStatus.available,
          ),
          EvConnector(
            id: 'demo-1-b',
            type: ConnectorType.ccs,
            maxPowerKw: 150,
            status: ConnectorStatus.occupied,
          ),
        ],
      ),
      const _DemoSample(
        id: 'demo-2',
        name: 'Demo Destination Charger',
        operator: 'Tesla',
        latOffset: -step * 0.6,
        lngOffset: step * 1.6,
        connectors: [
          EvConnector(
            id: 'demo-2-a',
            type: ConnectorType.tesla,
            maxPowerKw: 120,
            status: ConnectorStatus.available,
          ),
          EvConnector(
            id: 'demo-2-b',
            type: ConnectorType.type2,
            maxPowerKw: 22,
            status: ConnectorStatus.unknown,
          ),
        ],
      ),
      const _DemoSample(
        id: 'demo-3',
        name: 'Demo AC Point',
        operator: 'EnBW',
        latOffset: step * 0.4,
        lngOffset: -step * 1.1,
        connectors: [
          EvConnector(
            id: 'demo-3-a',
            type: ConnectorType.type2,
            maxPowerKw: 22,
            status: ConnectorStatus.available,
          ),
        ],
      ),
      const _DemoSample(
        id: 'demo-4',
        name: 'Demo CHAdeMO',
        operator: 'Allego',
        latOffset: -step * 1.4,
        lngOffset: -step * 0.5,
        connectors: [
          EvConnector(
            id: 'demo-4-a',
            type: ConnectorType.chademo,
            maxPowerKw: 50,
            status: ConnectorStatus.outOfOrder,
          ),
          EvConnector(
            id: 'demo-4-b',
            type: ConnectorType.ccs,
            maxPowerKw: 50,
            status: ConnectorStatus.available,
          ),
        ],
      ),
    ];

    return samples
        .map((s) => ChargingStation(
              id: s.id,
              name: s.name,
              operator: s.operator,
              latitude: centerLat + s.latOffset,
              longitude: centerLng + s.lngOffset,
              connectors: s.connectors,
              lastUpdate: DateTime.now(),
            ))
        .toList();
  }
}

class _DemoSample {
  final String id;
  final String name;
  final String operator;
  final double latOffset;
  final double lngOffset;
  final List<EvConnector> connectors;

  const _DemoSample({
    required this.id,
    required this.name,
    required this.operator,
    required this.latOffset,
    required this.lngOffset,
    required this.connectors,
  });
}
