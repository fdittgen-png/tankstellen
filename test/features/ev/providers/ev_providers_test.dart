import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/ev/data/services/open_charge_map_service.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_station.dart';
import 'package:tankstellen/features/ev/providers/ev_providers.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart'
    show ConnectorType;

void main() {
  group('EvFilter.matches', () {
    const stationCcs50Available = ChargingStation(
      id: 'a',
      name: 'A',
      latitude: 0,
      longitude: 0,
      connectors: [
        EvConnector(
          id: 'a1',
          type: ConnectorType.ccs,
          maxPowerKw: 50,
          status: ConnectorStatus.available,
        ),
      ],
    );
    const stationType2Occupied = ChargingStation(
      id: 'b',
      name: 'B',
      latitude: 0,
      longitude: 0,
      connectors: [
        EvConnector(
          id: 'b1',
          type: ConnectorType.type2,
          maxPowerKw: 22,
          status: ConnectorStatus.occupied,
        ),
      ],
    );

    test('empty filter matches everything', () {
      const filter = EvFilter();
      expect(filter.matches(stationCcs50Available), isTrue);
      expect(filter.matches(stationType2Occupied), isTrue);
    });

    test('connector type filter keeps matching plug only', () {
      const filter = EvFilter(connectorTypes: {ConnectorType.ccs});
      expect(filter.matches(stationCcs50Available), isTrue);
      expect(filter.matches(stationType2Occupied), isFalse);
    });

    test('minPowerKw filters out slow chargers', () {
      const filter = EvFilter(minPowerKw: 50);
      expect(filter.matches(stationCcs50Available), isTrue);
      expect(filter.matches(stationType2Occupied), isFalse);
    });

    test('availableOnly removes stations without free connectors', () {
      const filter = EvFilter(availableOnly: true);
      expect(filter.matches(stationCcs50Available), isTrue);
      expect(filter.matches(stationType2Occupied), isFalse);
    });

    test('copyWith preserves untouched fields', () {
      const base = EvFilter(
        connectorTypes: {ConnectorType.ccs},
        minPowerKw: 50,
        availableOnly: true,
      );
      final next = base.copyWith(availableOnly: false);
      expect(next.connectorTypes, {ConnectorType.ccs});
      expect(next.minPowerKw, 50);
      expect(next.availableOnly, isFalse);
    });

    test('equality compares all fields including sets', () {
      const a = EvFilter(
        connectorTypes: {ConnectorType.ccs, ConnectorType.type2},
        minPowerKw: 22,
      );
      const b = EvFilter(
        connectorTypes: {ConnectorType.type2, ConnectorType.ccs},
        minPowerKw: 22,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('DemoEvStationService', () {
    test('returns a non-empty list of stations centered near the request',
        () async {
      const service = DemoEvStationService();
      final stations = await service.fetchStations(
        centerLat: 48.85,
        centerLng: 2.35,
        radiusKm: 5,
      );
      expect(stations, isNotEmpty);
      for (final s in stations) {
        expect((s.latitude - 48.85).abs() < 0.1, isTrue);
        expect((s.longitude - 2.35).abs() < 0.1, isTrue);
      }
    });

    test('OpenChargeMapService without API key falls back to demo data',
        () async {
      final service = OpenChargeMapService();
      final stations = await service.fetchStations(
        centerLat: 48.85,
        centerLng: 2.35,
        radiusKm: 5,
      );
      expect(stations, isNotEmpty);
    });
  });

  group('evShowOnMapProvider', () {
    test('defaults to false and can be toggled', () async {
      final storage = _FakeSettings();
      final container = ProviderContainer(
        overrides: [
          settingsStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(evShowOnMapProvider), isFalse);
      await container.read(evShowOnMapProvider.notifier).toggle();
      expect(container.read(evShowOnMapProvider), isTrue);
      await container.read(evShowOnMapProvider.notifier).set(false);
      expect(container.read(evShowOnMapProvider), isFalse);
    });
  });

  group('evStationsProvider', () {
    test('fetches from service, caches in repo, applies filter', () async {
      final storage = _FakeSettings();
      final container = ProviderContainer(
        overrides: [
          settingsStorageProvider.overrideWithValue(storage),
          evStationServiceProvider.overrideWith(
            (ref) => const DemoEvStationService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Narrow the filter to CCS only so we can assert filtering happens.
      container
          .read(evFilterControllerProvider.notifier)
          .setConnectorTypes({ConnectorType.ccs});

      final result = await container.read(
        evStationsProvider(
          const EvViewport(latitude: 48.85, longitude: 2.35, radiusKm: 5),
        ).future,
      );
      expect(result, isNotEmpty);
      for (final s in result) {
        expect(
          s.connectors.any((c) => c.type == ConnectorType.ccs),
          isTrue,
        );
      }

      // Repository should now hold the full (unfiltered) list.
      final repo = container.read(evStationRepositoryProvider);
      expect(repo.getAll(), isNotEmpty);
    });
  });
}

class _FakeSettings implements SettingsStorage {
  final Map<String, dynamic> _data = {};

  @override
  dynamic getSetting(String key) => _data[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  bool get isSetupComplete => false;

  @override
  bool get isSetupSkipped => false;

  @override
  Future<void> skipSetup() async {}

  @override
  Future<void> resetSetupSkip() async {}
}
