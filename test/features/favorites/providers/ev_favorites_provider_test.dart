import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_station.dart';
import 'package:tankstellen/features/favorites/providers/ev_favorites_provider.dart';

import '../../../fakes/fake_hive_storage.dart';

void main() {
  late FakeHiveStorage fakeStorage;
  late ProviderContainer container;

  setUp(() {
    fakeStorage = FakeHiveStorage();

    container = ProviderContainer(
      overrides: [hiveStorageProvider.overrideWithValue(fakeStorage)],
    );
  });

  tearDown(() => container.dispose());

  group('EvFavorites', () {
    test('initial state is empty', () {
      final favorites = container.read(evFavoritesProvider);
      expect(favorites, isEmpty);
    });

    test('add adds station ID to favorites', () async {
      await container.read(evFavoritesProvider.notifier).add('ev-1');

      expect(fakeStorage.getEvFavoriteIds(), ['ev-1']);
      expect(container.read(evFavoritesProvider), ['ev-1']);
    });

    test('add persists station data when provided', () async {
      const station = ChargingStation(
        id: 'ev-1',
        name: 'Test Charger',
        operator: '',
        latitude: 48.0,
        longitude: 2.0,
        address: '',
      );

      await container
          .read(evFavoritesProvider.notifier)
          .add('ev-1', stationData: station);

      expect(fakeStorage.getEvFavoriteStationData('ev-1'), isNotNull);
      expect(fakeStorage.getEvFavoriteStationData('ev-1')!['name'],
          'Test Charger');
    });

    test('remove removes station ID and data', () async {
      await fakeStorage.addEvFavorite('ev-1');
      await fakeStorage
          .saveEvFavoriteStationData('ev-1', {'id': 'ev-1', 'name': 'X'});
      // Initialize the provider so it picks up the seeded value.
      container.read(evFavoritesProvider);

      await container.read(evFavoritesProvider.notifier).remove('ev-1');

      expect(fakeStorage.getEvFavoriteIds(), isEmpty);
      expect(fakeStorage.getEvFavoriteStationData('ev-1'), isNull);
    });

    test('toggle adds when not favorited', () async {
      container.read(evFavoritesProvider); // initialize empty

      await container.read(evFavoritesProvider.notifier).toggle('ev-1');

      expect(fakeStorage.getEvFavoriteIds(), ['ev-1']);
    });

    test('toggle removes when already favorited', () async {
      await fakeStorage.addEvFavorite('ev-1');
      container.read(evFavoritesProvider); // initialize with ev-1

      await container.read(evFavoritesProvider.notifier).toggle('ev-1');

      expect(fakeStorage.getEvFavoriteIds(), isEmpty);
    });
  });

  group('isEvFavorite', () {
    test('returns true when station is favorited', () async {
      await fakeStorage.addEvFavorite('ev-1');
      expect(container.read(isEvFavoriteProvider('ev-1')), isTrue);
    });

    test('returns false when station is not favorited', () {
      expect(container.read(isEvFavoriteProvider('ev-1')), isFalse);
    });
  });

  group('EvFavoriteStations', () {
    test('returns empty list when no favorites', () {
      final stations = container.read(evFavoriteStationsProvider);
      expect(stations, isEmpty);
    });

    test('loads persisted station data (canonical key shape)', () async {
      await fakeStorage.addEvFavorite('ev-1');
      await fakeStorage.saveEvFavoriteStationData('ev-1', {
        'id': 'ev-1',
        'name': 'Test Charger',
        'latitude': 48.0,
        'longitude': 2.0,
        'operator': '',
        'address': '',
        'connectors': <dynamic>[],
        'amenities': <dynamic>[],
      });

      final stations = container.read(evFavoriteStationsProvider);
      expect(stations, hasLength(1));
      expect(stations.first.name, 'Test Charger');
      expect(stations.first.latitude, 48.0);
    });

    test('loads persisted station data (legacy lat/lng key shape)', () async {
      // Pre-#560 the search-side entity persisted `lat`/`lng`. The
      // unified entity must still parse this shape.
      await fakeStorage.addEvFavorite('ev-1');
      await fakeStorage.saveEvFavoriteStationData('ev-1', {
        'id': 'ev-1',
        'name': 'Test Charger',
        'lat': 48.0,
        'lng': 2.0,
        'operator': '',
        'address': '',
        'connectors': <dynamic>[],
      });

      final stations = container.read(evFavoriteStationsProvider);
      expect(stations, hasLength(1));
      expect(stations.first.name, 'Test Charger');
      expect(stations.first.latitude, 48.0);
      expect(stations.first.longitude, 2.0);
    });

    test('skips stations with no persisted data', () async {
      await fakeStorage.addEvFavorite('ev-1');
      await fakeStorage.addEvFavorite('ev-2');
      await fakeStorage.saveEvFavoriteStationData('ev-1', {
        'id': 'ev-1',
        'name': 'Test Charger',
        'latitude': 48.0,
        'longitude': 2.0,
        'operator': '',
        'address': '',
        'connectors': <dynamic>[],
      });

      final stations = container.read(evFavoriteStationsProvider);
      expect(stations, hasLength(1));
    });
  });
}
