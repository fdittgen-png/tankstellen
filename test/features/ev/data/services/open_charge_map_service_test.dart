import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/ev/data/services/open_charge_map_service.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_station.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart'
    show ConnectorType;

/// Recording fake that captures every fetchStations call so the test can
/// assert the wrapping [OpenChargeMapService] forwards parameters
/// unchanged.
class _RecordingFallback implements EvStationService {
  _RecordingFallback({this.response = const <ChargingStation>[]});

  final List<({double lat, double lng, double radius})> calls = [];
  final List<ChargingStation> response;

  @override
  Future<List<ChargingStation>> fetchStations({
    required double centerLat,
    required double centerLng,
    required double radiusKm,
  }) async {
    calls.add((lat: centerLat, lng: centerLng, radius: radiusKm));
    return response;
  }
}

void main() {
  group('OpenChargeMapService', () {
    const marker = ChargingStation(
      id: 'fake-1',
      name: 'Fake Station',
      latitude: 48.0,
      longitude: 2.0,
      connectors: [
        EvConnector(
          id: 'fake-1-a',
          type: ConnectorType.ccs,
          maxPowerKw: 50,
          status: ConnectorStatus.available,
        ),
      ],
    );

    test('default constructor uses DemoEvStationService as fallback', () async {
      // No fallback injected. Should still produce demo stations
      // (DemoEvStationService is exercised indirectly).
      final service = OpenChargeMapService();
      final stations = await service.fetchStations(
        centerLat: 48.0,
        centerLng: 2.0,
        radiusKm: 5,
      );
      expect(stations, isNotEmpty);
      // Demo dataset is fixed at 4 entries.
      expect(stations, hasLength(4));
    });

    test('null apiKey delegates to fallback with the original args',
        () async {
      final fallback = _RecordingFallback(response: [marker]);
      final service = OpenChargeMapService(fallback: fallback);

      final out = await service.fetchStations(
        centerLat: 48.5,
        centerLng: 2.5,
        radiusKm: 7,
      );

      expect(out, [marker]);
      expect(fallback.calls, hasLength(1));
      expect(fallback.calls.single.lat, 48.5);
      expect(fallback.calls.single.lng, 2.5);
      expect(fallback.calls.single.radius, 7);
    });

    test('empty apiKey delegates to fallback', () async {
      final fallback = _RecordingFallback(response: [marker]);
      final service =
          OpenChargeMapService(apiKey: '', fallback: fallback);

      final out = await service.fetchStations(
        centerLat: 1.0,
        centerLng: 2.0,
        radiusKm: 3,
      );

      expect(out, [marker]);
      expect(fallback.calls, hasLength(1));
      expect(fallback.calls.single.lat, 1.0);
      expect(fallback.calls.single.lng, 2.0);
      expect(fallback.calls.single.radius, 3);
    });

    test('whitespace-only apiKey delegates to fallback (trim check)',
        () async {
      final fallback = _RecordingFallback(response: [marker]);
      final service =
          OpenChargeMapService(apiKey: '   ', fallback: fallback);

      final out = await service.fetchStations(
        centerLat: 10.0,
        centerLng: 20.0,
        radiusKm: 4,
      );

      expect(out, [marker]);
      expect(fallback.calls, hasLength(1));
      expect(fallback.calls.single.lat, 10.0);
      expect(fallback.calls.single.lng, 20.0);
      expect(fallback.calls.single.radius, 4);
    });

    test(
        'non-empty apiKey still delegates to fallback (real call '
        'unimplemented)', () async {
      final fallback = _RecordingFallback(response: [marker]);
      final service = OpenChargeMapService(
        apiKey: 'real-looking-key',
        fallback: fallback,
      );

      final out = await service.fetchStations(
        centerLat: 51.5,
        centerLng: -0.1,
        radiusKm: 12,
      );

      expect(out, [marker]);
      expect(fallback.calls, hasLength(1));
      expect(fallback.calls.single.lat, 51.5);
      expect(fallback.calls.single.lng, -0.1);
      expect(fallback.calls.single.radius, 12);
    });

    test('forwards arguments unchanged on every call', () async {
      final fallback = _RecordingFallback();
      final service = OpenChargeMapService(fallback: fallback);

      await service.fetchStations(
        centerLat: 10.0, centerLng: 20.0, radiusKm: 1,
      );
      await service.fetchStations(
        centerLat: 30.0, centerLng: 40.0, radiusKm: 5,
      );
      await service.fetchStations(
        centerLat: -10.5, centerLng: -20.5, radiusKm: 9,
      );

      expect(fallback.calls, hasLength(3));
      expect(fallback.calls[0], (lat: 10.0, lng: 20.0, radius: 1.0));
      expect(fallback.calls[1], (lat: 30.0, lng: 40.0, radius: 5.0));
      expect(fallback.calls[2], (lat: -10.5, lng: -20.5, radius: 9.0));
    });
  });

  group('DemoEvStationService', () {
    const service = DemoEvStationService();

    test('returns a non-empty list of ChargingStation for typical inputs',
        () async {
      final stations = await service.fetchStations(
        centerLat: 48.0,
        centerLng: 2.0,
        radiusKm: 5,
      );
      expect(stations, isNotEmpty);
      expect(stations, hasLength(4));
      expect(stations, everyElement(isA<ChargingStation>()));
    });

    test('coordinates are near the requested center (within ~5 km cap)',
        () async {
      const centerLat = 48.0;
      const centerLng = 2.0;
      final stations = await service.fetchStations(
        centerLat: centerLat,
        centerLng: centerLng,
        radiusKm: 5,
      );

      // The implementation caps offsets to roughly ~5 km regardless of
      // request size — ~0.009 deg/km × 1.4 = ~0.0126 deg max offset.
      const maxDelta = 0.02;
      for (final s in stations) {
        expect((s.latitude - centerLat).abs(), lessThan(maxDelta),
            reason: '${s.id} lat ${s.latitude} too far from $centerLat');
        expect((s.longitude - centerLng).abs(), lessThan(maxDelta),
            reason: '${s.id} lng ${s.longitude} too far from $centerLng');
      }
    });

    test('radiusKm does not blow past the documented ~5 km cap', () async {
      // Even when the caller asks for a huge radius, demo data stays
      // clustered around the center.
      const centerLat = 0.0;
      const centerLng = 0.0;
      final stations = await service.fetchStations(
        centerLat: centerLat,
        centerLng: centerLng,
        radiusKm: 5000,
      );

      const maxDelta = 0.02;
      for (final s in stations) {
        expect(s.latitude.abs(), lessThan(maxDelta));
        expect(s.longitude.abs(), lessThan(maxDelta));
      }
    });

    test('same input produces same coordinates (deterministic)', () async {
      final a = await service.fetchStations(
        centerLat: 12.34, centerLng: 56.78, radiusKm: 5,
      );
      final b = await service.fetchStations(
        centerLat: 12.34, centerLng: 56.78, radiusKm: 5,
      );

      expect(a.length, b.length);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].id, b[i].id);
        expect(a[i].name, b[i].name);
        expect(a[i].operator, b[i].operator);
        expect(a[i].latitude, b[i].latitude);
        expect(a[i].longitude, b[i].longitude);
      }
    });

    test('every station has the required fields populated', () async {
      final stations = await service.fetchStations(
        centerLat: 48.0,
        centerLng: 2.0,
        radiusKm: 5,
      );

      for (final s in stations) {
        expect(s.id, isNotEmpty);
        expect(s.name, isNotEmpty);
        expect(s.operator, isNotNull);
        expect(s.operator, isNotEmpty);
        expect(s.connectors, isNotEmpty);
        expect(s.lastUpdate, isNotNull);
        for (final c in s.connectors) {
          expect(c.id, isNotEmpty);
          expect(c.maxPowerKw, greaterThan(0));
        }
      }
    });

    test('produces stations with the expected demo ids', () async {
      final stations = await service.fetchStations(
        centerLat: 48.0,
        centerLng: 2.0,
        radiusKm: 5,
      );
      expect(
        stations.map((s) => s.id).toList(),
        ['demo-1', 'demo-2', 'demo-3', 'demo-4'],
      );
    });

    test('exposes a mix of connector types covering the demo dataset',
        () async {
      final stations = await service.fetchStations(
        centerLat: 48.0,
        centerLng: 2.0,
        radiusKm: 5,
      );
      final allConnectors =
          stations.expand((s) => s.connectors).toList();
      final types = allConnectors.map((c) => c.type).toSet();

      expect(types, contains(ConnectorType.ccs));
      expect(types, contains(ConnectorType.tesla));
      expect(types, contains(ConnectorType.type2));
      expect(types, contains(ConnectorType.chademo));
    });

    test('exposes a mix of connector statuses covering the demo dataset',
        () async {
      final stations = await service.fetchStations(
        centerLat: 48.0,
        centerLng: 2.0,
        radiusKm: 5,
      );
      final statuses = stations
          .expand((s) => s.connectors)
          .map((c) => c.status)
          .toSet();

      expect(statuses, contains(ConnectorStatus.available));
      expect(statuses, contains(ConnectorStatus.occupied));
      expect(statuses, contains(ConnectorStatus.unknown));
      expect(statuses, contains(ConnectorStatus.outOfOrder));
    });

    test('coordinates shift consistently with the requested center',
        () async {
      final centerA = await service.fetchStations(
        centerLat: 0.0, centerLng: 0.0, radiusKm: 5,
      );
      final centerB = await service.fetchStations(
        centerLat: 10.0, centerLng: 20.0, radiusKm: 5,
      );

      // Same offsets relative to the requested center.
      for (var i = 0; i < centerA.length; i++) {
        expect(centerB[i].latitude - centerA[i].latitude, closeTo(10.0, 1e-9));
        expect(centerB[i].longitude - centerA[i].longitude, closeTo(20.0, 1e-9));
      }
    });
  });
}
