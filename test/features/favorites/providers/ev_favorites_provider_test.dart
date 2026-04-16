import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/search/domain/entities/charging_station.dart';
import 'package:tankstellen/features/favorites/providers/ev_favorites_provider.dart';

import '../../../mocks/mocks.dart';

void main() {
  late MockHiveStorage mockStorage;
  late ProviderContainer container;

  setUp(() {
    mockStorage = MockHiveStorage();
    // Fuel favorites stubs (unified Favorites.build merges both lists)
    when(() => mockStorage.getFavoriteIds()).thenReturn([]);
    when(() => mockStorage.getFavoriteStationData(any())).thenReturn(null);
    when(() => mockStorage.isFavorite(any())).thenReturn(false);
    when(() => mockStorage.isEvFavorite(any())).thenReturn(false);
    when(() => mockStorage.getSetting(any())).thenReturn(null);
    // EV favorites stubs
    when(() => mockStorage.getEvFavoriteIds()).thenReturn([]);
    when(() => mockStorage.addEvFavorite(any())).thenAnswer((_) async {});
    when(() => mockStorage.removeEvFavorite(any())).thenAnswer((_) async {});
    when(() => mockStorage.saveEvFavoriteStationData(any(), any()))
        .thenAnswer((_) async {});
    when(() => mockStorage.removeEvFavoriteStationData(any()))
        .thenAnswer((_) async {});
    when(() => mockStorage.getEvFavoriteStationData(any())).thenReturn(null);

    container = ProviderContainer(
      overrides: [hiveStorageProvider.overrideWithValue(mockStorage)],
    );
  });

  tearDown(() => container.dispose());

  group('EvFavorites', () {
    test('initial state is empty', () {
      final favorites = container.read(evFavoritesProvider);
      expect(favorites, isEmpty);
    });

    test('add adds station ID to favorites', () async {
      when(() => mockStorage.getEvFavoriteIds()).thenReturn(['ev-1']);

      await container.read(evFavoritesProvider.notifier).add('ev-1');

      verify(() => mockStorage.addEvFavorite('ev-1')).called(1);
      expect(container.read(evFavoritesProvider), ['ev-1']);
    });

    test('add persists station data when provided', () async {
      when(() => mockStorage.getEvFavoriteIds()).thenReturn(['ev-1']);

      const station = ChargingStation(
        id: 'ev-1',
        name: 'Test Charger',
        operator: '',
        lat: 48.0,
        lng: 2.0,
        address: '',
        connectors: [],
      );

      await container
          .read(evFavoritesProvider.notifier)
          .add('ev-1', stationData: station);

      verify(() => mockStorage.saveEvFavoriteStationData('ev-1', any()))
          .called(1);
    });

    test('remove removes station ID and data', () async {
      when(() => mockStorage.getEvFavoriteIds()).thenReturn([]);

      await container.read(evFavoritesProvider.notifier).remove('ev-1');

      verify(() => mockStorage.removeEvFavorite('ev-1')).called(1);
      verify(() => mockStorage.removeEvFavoriteStationData('ev-1')).called(1);
    });

    test('toggle adds when not favorited', () async {
      when(() => mockStorage.getEvFavoriteIds()).thenReturn([]);
      container.read(evFavoritesProvider); // initialize empty

      when(() => mockStorage.getEvFavoriteIds()).thenReturn(['ev-1']);
      await container.read(evFavoritesProvider.notifier).toggle('ev-1');

      verify(() => mockStorage.addEvFavorite('ev-1')).called(1);
    });

    test('toggle removes when already favorited', () async {
      when(() => mockStorage.getEvFavoriteIds()).thenReturn(['ev-1']);
      container.read(evFavoritesProvider); // initialize with ev-1

      when(() => mockStorage.getEvFavoriteIds()).thenReturn([]);
      await container.read(evFavoritesProvider.notifier).toggle('ev-1');

      verify(() => mockStorage.removeEvFavorite('ev-1')).called(1);
    });
  });

  group('isEvFavorite', () {
    test('returns true when station is favorited', () {
      when(() => mockStorage.getEvFavoriteIds()).thenReturn(['ev-1']);
      expect(container.read(isEvFavoriteProvider('ev-1')), isTrue);
    });

    test('returns false when station is not favorited', () {
      when(() => mockStorage.getEvFavoriteIds()).thenReturn([]);
      expect(container.read(isEvFavoriteProvider('ev-1')), isFalse);
    });
  });

  group('EvFavoriteStations', () {
    test('returns empty list when no favorites', () {
      when(() => mockStorage.getEvFavoriteIds()).thenReturn([]);
      final stations = container.read(evFavoriteStationsProvider);
      expect(stations, isEmpty);
    });

    test('loads persisted station data', () {
      when(() => mockStorage.getEvFavoriteIds()).thenReturn(['ev-1']);
      when(() => mockStorage.getEvFavoriteStationData('ev-1')).thenReturn({
        'id': 'ev-1',
        'name': 'Test Charger',
        'lat': 48.0, 'operator': '', 'address': '',
        'lng': 2.0,
        'connectors': <dynamic>[],
        'amenities': <dynamic>[],
      });

      final stations = container.read(evFavoriteStationsProvider);
      expect(stations, hasLength(1));
      expect(stations.first.name, 'Test Charger');
    });

    test('skips stations with no persisted data', () {
      when(() => mockStorage.getEvFavoriteIds()).thenReturn(['ev-1', 'ev-2']);
      when(() => mockStorage.getEvFavoriteStationData('ev-1')).thenReturn({
        'id': 'ev-1',
        'name': 'Test Charger',
        'lat': 48.0, 'operator': '', 'address': '',
        'lng': 2.0,
        'connectors': <dynamic>[],
        'amenities': <dynamic>[],
      });
      when(() => mockStorage.getEvFavoriteStationData('ev-2'))
          .thenReturn(null);

      final stations = container.read(evFavoriteStationsProvider);
      expect(stations, hasLength(1));
    });
  });
}
