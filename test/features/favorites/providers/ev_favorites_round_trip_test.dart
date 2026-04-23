import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_station.dart';
import 'package:tankstellen/features/favorites/providers/ev_favorites_provider.dart';
import 'package:tankstellen/features/favorites/providers/favorites_provider.dart';

import '../../../mocks/mocks.dart';

/// End-to-end round-trip test: add an EV favorite via the unified
/// favoritesProvider.toggleEv(), then verify it appears in
/// evFavoriteStationsProvider. This is the exact chain the user
/// exercises: EV detail screen → star tap → Favorites tab.
///
/// Post-#560, [ChargingStation.fromJson] handles BOTH `lat`/`lng` and
/// `latitude`/`longitude` natively, so the old EvFavoriteStations
/// fallback parser is gone and the test that used to exercise it now
/// simply verifies the canonical fromJson handles the legacy key
/// naming directly.
void main() {
  late MockHiveStorage mockStorage;

  // In-memory stores that behave like real Hive.
  late List<String> fuelIds;
  late List<String> evIds;
  late Map<String, Map<String, dynamic>> evStationData;

  // Canonical ChargingStation — the single unified type after #560.
  const testEvStation = ChargingStation(
    id: 'ev-42',
    name: 'Test Charger Paris',
    operator: 'Test Operator',
    latitude: 48.85,
    longitude: 2.35,
    address: '1 Rue de Test',
  );

  setUp(() {
    mockStorage = MockHiveStorage();
    fuelIds = [];
    evIds = [];
    evStationData = {};

    // Fuel stubs
    when(() => mockStorage.getFavoriteIds()).thenAnswer((_) => List.of(fuelIds));
    when(() => mockStorage.isFavorite(any()))
        .thenAnswer((inv) => fuelIds.contains(inv.positionalArguments.first));
    when(() => mockStorage.getFavoriteStationData(any())).thenReturn(null);

    // EV stubs — in-memory round-trip
    when(() => mockStorage.getEvFavoriteIds()).thenAnswer((_) => List.of(evIds));
    when(() => mockStorage.isEvFavorite(any()))
        .thenAnswer((inv) => evIds.contains(inv.positionalArguments.first));
    when(() => mockStorage.addEvFavorite(any())).thenAnswer((inv) async {
      final id = inv.positionalArguments.first as String;
      if (!evIds.contains(id)) evIds.add(id);
    });
    when(() => mockStorage.removeEvFavorite(any())).thenAnswer((inv) async {
      evIds.remove(inv.positionalArguments.first);
    });
    when(() => mockStorage.saveEvFavoriteStationData(any(), any()))
        .thenAnswer((inv) async {
      evStationData[inv.positionalArguments.first as String] =
          inv.positionalArguments[1] as Map<String, dynamic>;
    });
    when(() => mockStorage.getEvFavoriteStationData(any())).thenAnswer((inv) {
      return evStationData[inv.positionalArguments.first];
    });
    when(() => mockStorage.removeEvFavoriteStationData(any()))
        .thenAnswer((inv) async {
      evStationData.remove(inv.positionalArguments.first);
    });

    // Misc stubs
    when(() => mockStorage.getSetting(any())).thenReturn(null);
    when(() => mockStorage.getRatings()).thenReturn({});

    registerFallbackValue(<String, dynamic>{});
  });

  ProviderContainer createContainer() {
    final c = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(mockStorage),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('EV favorites round-trip (TDD)', () {
    test('toggleEv adds EV station and it appears in evFavoriteStationsProvider',
        () async {
      final container = createContainer();

      // Precondition: no favorites of any kind
      expect(container.read(favoritesProvider), isEmpty);
      expect(container.read(evFavoriteStationsProvider), isEmpty);

      // ACT: toggle EV favorite (same path as EV detail screen star tap)
      await container
          .read(favoritesProvider.notifier)
          .toggleEv('ev-42', stationData: testEvStation);

      // ASSERT 1: unified ID list contains the EV station
      expect(container.read(favoritesProvider), contains('ev-42'));

      // ASSERT 2: evFavoriteStationsProvider returns the station data
      final evStations = container.read(evFavoriteStationsProvider);
      expect(evStations, hasLength(1));
      expect(evStations.first.id, 'ev-42');
      expect(evStations.first.name, 'Test Charger Paris');
    });

    test('toggleEv twice removes the EV favorite', () async {
      final container = createContainer();

      // Add
      await container
          .read(favoritesProvider.notifier)
          .toggleEv('ev-42', stationData: testEvStation);
      expect(container.read(favoritesProvider), contains('ev-42'));

      // Remove
      await container.read(favoritesProvider.notifier).toggleEv('ev-42');
      expect(container.read(favoritesProvider), isNot(contains('ev-42')));
      expect(container.read(evFavoriteStationsProvider), isEmpty);
    });

    test('isFavoriteProvider returns true for added EV station', () async {
      final container = createContainer();

      await container
          .read(favoritesProvider.notifier)
          .toggleEv('ev-42', stationData: testEvStation);

      expect(container.read(isFavoriteProvider('ev-42')), isTrue);
    });

    test(
      'legacy-shape JSON (lat/lng keys) persisted by the pre-#560 '
      'search/ ChargingStation round-trips natively through '
      'ChargingStation.fromJson — no fallback parser needed',
      () async {
        // Simulate stored data from the pre-#560 search-side entity.
        // The unified entity's fromJson handles the legacy shape
        // directly, so EvFavoriteStations no longer needs a fallback
        // parser hack.
        final legacyJson = {
          'id': 'ev-42',
          'name': 'Test Charger Paris',
          'operator': 'Test Operator',
          'lat': 48.85,
          'lng': 2.35,
          'address': '1 Rue de Test',
          'connectors': <dynamic>[],
        };
        evStationData['ev-42'] = legacyJson;
        evIds.add('ev-42');

        final container = createContainer();
        final stations = container.read(evFavoriteStationsProvider);

        // Canonical fromJson handles the legacy shape directly.
        expect(stations, hasLength(1));
        expect(stations.first.id, 'ev-42');
        expect(stations.first.lat, 48.85,
            reason: 'lat getter aliases latitude after #560');
        expect(stations.first.latitude, 48.85);
        expect(stations.first.longitude, 2.35);
        expect(stations.first.name, 'Test Charger Paris');
      },
    );

    test(
      'canonical ChargingStation round-trips through storage',
      () async {
        final container = createContainer();

        await container
            .read(favoritesProvider.notifier)
            .toggleEv('ev-42', stationData: testEvStation);

        final stations = container.read(evFavoriteStationsProvider);
        expect(stations, hasLength(1));
        expect(stations.first.latitude, 48.85,
            reason: 'canonical latitude preserved through storage');
        expect(stations.first.lat, 48.85,
            reason: 'lat getter still works on canonical entity');
      },
    );
  });
}
