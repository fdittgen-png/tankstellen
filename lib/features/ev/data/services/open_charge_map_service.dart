import 'package:flutter/foundation.dart';

import '../../../vehicle/domain/entities/vehicle_profile.dart'
    show ConnectorType;
import '../../domain/entities/charging_station.dart';

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
/// Currently a stub: if no API key is configured, it transparently falls
/// back to [DemoEvStationService]. The real HTTP integration is tracked
/// separately so this PR can ship the client end-to-end without coupling
/// to network flakiness.
///
/// TODO(#177-followup): implement real https://api.openchargemap.io/v3
/// REST call using Dio with a Bearer API key, cache TTL, and full
/// connector/tariff mapping.
class OpenChargeMapService implements EvStationService {
  final String? apiKey;
  final EvStationService _fallback;

  OpenChargeMapService({
    this.apiKey,
    EvStationService? fallback,
  }) : _fallback = fallback ?? const DemoEvStationService();

  @override
  Future<List<ChargingStation>> fetchStations({
    required double centerLat,
    required double centerLng,
    required double radiusKm,
  }) async {
    if (apiKey == null || apiKey!.trim().isEmpty) {
      debugPrint('OpenChargeMapService: no API key, using demo data');
      return _fallback.fetchStations(
        centerLat: centerLat,
        centerLng: centerLng,
        radiusKm: radiusKm,
      );
    }
    // Real call intentionally unimplemented — see class docs.
    return _fallback.fetchStations(
      centerLat: centerLat,
      centerLng: centerLng,
      radiusKm: radiusKm,
    );
  }
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
