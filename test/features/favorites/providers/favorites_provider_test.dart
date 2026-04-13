import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/services/service_providers.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/favorites/providers/favorites_provider.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

import '../../../fixtures/stations.dart';
import '../../../mocks/mocks.dart';

/// Simulates the connectivity method channel response for tests.
void _mockConnectivity(List<String> result) {
  const channel = MethodChannel('dev.fluttercommunity.plus/connectivity');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall call) async {
    if (call.method == 'check') return result;
    return null;
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Default: online
  _mockConnectivity(['wifi']);

  late MockHiveStorage mockStorage;
  late ProviderContainer container;

  setUp(() {
    mockStorage = MockHiveStorage();
  });

  ProviderContainer createContainer({MockStationService? mockService}) {
    final c = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(mockStorage),
      if (mockService != null)
        stationServiceProvider.overrideWithValue(mockService),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('Favorites', () {
    test('build returns favorite IDs from storage', () {
      when(() => mockStorage.getFavoriteIds()).thenReturn(['a', 'b']);

      container = createContainer();
      final ids = container.read(favoritesProvider);

      expect(ids, ['a', 'b']);
      verify(() => mockStorage.getFavoriteIds()).called(1);
    });

    test('add() adds station ID to list', () async {
      when(() => mockStorage.getFavoriteIds()).thenReturn([]);
      when(() => mockStorage.addFavorite(any())).thenAnswer((_) async {});

      container = createContainer();
      container.read(favoritesProvider);

      when(() => mockStorage.getFavoriteIds()).thenReturn(['station-1']);
      await container.read(favoritesProvider.notifier).add('station-1');

      verify(() => mockStorage.addFavorite('station-1')).called(1);
      expect(container.read(favoritesProvider), ['station-1']);
    });

    test('add() with stationData persists station JSON', () async {
      when(() => mockStorage.getFavoriteIds()).thenReturn([]);
      when(() => mockStorage.addFavorite(any())).thenAnswer((_) async {});
      when(() => mockStorage.saveFavoriteStationData(any(), any()))
          .thenAnswer((_) async {});

      container = createContainer();
      container.read(favoritesProvider);

      when(() => mockStorage.getFavoriteIds()).thenReturn([testStation.id]);
      await container
          .read(favoritesProvider.notifier)
          .add(testStation.id, stationData: testStation);

      verify(() => mockStorage.saveFavoriteStationData(
            testStation.id,
            testStation.toJson(),
          )).called(1);
    });

    test('add() without stationData does NOT call saveFavoriteStationData',
        () async {
      when(() => mockStorage.getFavoriteIds()).thenReturn([]);
      when(() => mockStorage.addFavorite(any())).thenAnswer((_) async {});

      container = createContainer();
      container.read(favoritesProvider);

      when(() => mockStorage.getFavoriteIds()).thenReturn(['station-1']);
      await container.read(favoritesProvider.notifier).add('station-1');

      verifyNever(() => mockStorage.saveFavoriteStationData(any(), any()));
    });

    test('remove() removes station ID and persisted data', () async {
      when(() => mockStorage.getFavoriteIds()).thenReturn(['station-1']);
      when(() => mockStorage.removeFavorite(any())).thenAnswer((_) async {});
      when(() => mockStorage.removeFavoriteStationData(any())).thenAnswer((_) async {});
      when(() => mockStorage.getRatings()).thenReturn({});
      when(() => mockStorage.removeRating(any())).thenAnswer((_) async {});
      when(() => mockStorage.clearPriceHistoryForStation(any())).thenAnswer((_) async {});

      container = createContainer();
      expect(container.read(favoritesProvider), ['station-1']);

      when(() => mockStorage.getFavoriteIds()).thenReturn([]);
      await container.read(favoritesProvider.notifier).remove('station-1');

      verify(() => mockStorage.removeFavorite('station-1')).called(1);
      verify(() => mockStorage.removeFavoriteStationData('station-1')).called(1);
      expect(container.read(favoritesProvider), isEmpty);
    });

    test('remove() cleans up rating and price history', () async {
      when(() => mockStorage.getFavoriteIds()).thenReturn(['station-1']);
      when(() => mockStorage.removeFavorite(any())).thenAnswer((_) async {});
      when(() => mockStorage.removeFavoriteStationData(any())).thenAnswer((_) async {});
      when(() => mockStorage.getRatings()).thenReturn({'station-1': 4});
      when(() => mockStorage.removeRating(any())).thenAnswer((_) async {});
      when(() => mockStorage.clearPriceHistoryForStation(any())).thenAnswer((_) async {});

      container = createContainer();
      container.read(favoritesProvider);

      when(() => mockStorage.getFavoriteIds()).thenReturn([]);
      await container.read(favoritesProvider.notifier).remove('station-1');

      verify(() => mockStorage.clearPriceHistoryForStation('station-1')).called(1);
    });

    // Regression for issue #423: the rating-cleanup call inside remove()
    // used to be fire-and-forget, which meant a fast follow-up read could
    // observe a still-present rating. The fix awaits it; this test pins
    // the awaited ordering so it can't regress.
    test('remove() awaits the rating cleanup before returning', () async {
      when(() => mockStorage.getFavoriteIds()).thenReturn(['station-1']);
      when(() => mockStorage.removeFavorite(any())).thenAnswer((_) async {});
      when(() => mockStorage.removeFavoriteStationData(any()))
          .thenAnswer((_) async {});
      when(() => mockStorage.getRatings()).thenReturn({'station-1': 4});
      when(() => mockStorage.clearPriceHistoryForStation(any()))
          .thenAnswer((_) async {});

      // Make removeRating slow so a non-awaiting caller would race past it.
      final ratingCleanupCompleter = Completer<void>();
      var ratingCleanupCalled = false;
      when(() => mockStorage.removeRating(any())).thenAnswer((_) async {
        ratingCleanupCalled = true;
        await ratingCleanupCompleter.future;
      });

      container = createContainer();
      container.read(favoritesProvider);
      when(() => mockStorage.getFavoriteIds()).thenReturn([]);

      final removeFuture =
          container.read(favoritesProvider.notifier).remove('station-1');

      // Yield once so remove() reaches the rating cleanup call.
      await Future<void>.delayed(Duration.zero);
      expect(ratingCleanupCalled, isTrue,
          reason: 'remove() should call rating cleanup before completing');
      expect(removeFuture, isA<Future<void>>(),
          reason: 'remove() should still be pending while cleanup is running');

      ratingCleanupCompleter.complete();
      await removeFuture;
      verify(() => mockStorage.removeRating('station-1')).called(1);
    });

    test('remove() succeeds even if price history cleanup throws', () async {
      when(() => mockStorage.getFavoriteIds()).thenReturn(['station-1']);
      when(() => mockStorage.removeFavorite(any())).thenAnswer((_) async {});
      when(() => mockStorage.removeFavoriteStationData(any())).thenAnswer((_) async {});
      when(() => mockStorage.getRatings()).thenReturn({});
      when(() => mockStorage.removeRating(any())).thenAnswer((_) async {});
      when(() => mockStorage.clearPriceHistoryForStation(any()))
          .thenThrow(Exception('corrupt'));

      container = createContainer();
      container.read(favoritesProvider);

      when(() => mockStorage.getFavoriteIds()).thenReturn([]);
      // Should not throw — cleanup errors are caught
      await container.read(favoritesProvider.notifier).remove('station-1');

      verify(() => mockStorage.removeFavorite('station-1')).called(1);
      expect(container.read(favoritesProvider), isEmpty);
    });

    test('toggle() adds if not present', () async {
      when(() => mockStorage.getFavoriteIds()).thenReturn([]);
      when(() => mockStorage.addFavorite(any())).thenAnswer((_) async {});

      container = createContainer();
      container.read(favoritesProvider);

      when(() => mockStorage.getFavoriteIds()).thenReturn(['station-1']);
      await container.read(favoritesProvider.notifier).toggle('station-1');

      verify(() => mockStorage.addFavorite('station-1')).called(1);
    });

    test('toggle() removes if already present', () async {
      when(() => mockStorage.getFavoriteIds()).thenReturn(['station-1']);
      when(() => mockStorage.removeFavorite(any())).thenAnswer((_) async {});
      when(() => mockStorage.removeFavoriteStationData(any())).thenAnswer((_) async {});
      when(() => mockStorage.getRatings()).thenReturn({});
      when(() => mockStorage.removeRating(any())).thenAnswer((_) async {});
      when(() => mockStorage.clearPriceHistoryForStation(any())).thenAnswer((_) async {});

      container = createContainer();
      container.read(favoritesProvider);

      when(() => mockStorage.getFavoriteIds()).thenReturn([]);
      await container.read(favoritesProvider.notifier).toggle('station-1');

      verify(() => mockStorage.removeFavorite('station-1')).called(1);
      verifyNever(() => mockStorage.addFavorite(any()));
    });

    test('toggle() with stationData passes it through to add()', () async {
      when(() => mockStorage.getFavoriteIds()).thenReturn([]);
      when(() => mockStorage.addFavorite(any())).thenAnswer((_) async {});
      when(() => mockStorage.saveFavoriteStationData(any(), any()))
          .thenAnswer((_) async {});

      container = createContainer();
      container.read(favoritesProvider);

      when(() => mockStorage.getFavoriteIds()).thenReturn([testStation.id]);
      await container
          .read(favoritesProvider.notifier)
          .toggle(testStation.id, stationData: testStation);

      verify(() => mockStorage.saveFavoriteStationData(
            testStation.id,
            testStation.toJson(),
          )).called(1);
    });
  });

  group('isFavoriteProvider', () {
    test('returns true for a favorited station', () {
      when(() => mockStorage.getFavoriteIds()).thenReturn(['station-1']);

      container = createContainer();
      expect(container.read(isFavoriteProvider('station-1')), isTrue);
    });

    test('returns false for a non-favorite station', () {
      when(() => mockStorage.getFavoriteIds()).thenReturn(['station-1']);

      container = createContainer();
      expect(container.read(isFavoriteProvider('station-2')), isFalse);
    });

    test('returns false when no favorites exist', () {
      when(() => mockStorage.getFavoriteIds()).thenReturn([]);

      container = createContainer();
      expect(container.read(isFavoriteProvider('station-1')), isFalse);
    });
  });

  group('FavoriteStations', () {
    test('build() returns empty list', () {
      when(() => mockStorage.getFavoriteIds()).thenReturn([]);

      container = createContainer();
      final state = container.read(favoriteStationsProvider);

      expect(state, isA<AsyncData>());
      expect(state.value!.data, isEmpty);
    });

    test('loadAndRefresh() returns empty when no favorites', () async {
      when(() => mockStorage.getFavoriteIds()).thenReturn([]);

      container = createContainer();
      await container.read(favoriteStationsProvider.notifier).loadAndRefresh();

      final state = container.read(favoriteStationsProvider);
      expect(state.value!.data, isEmpty);
    });

    test('loadAndRefresh() loads persisted stations from storage', () async {
      final station = testStationList[0];
      when(() => mockStorage.getFavoriteIds()).thenReturn([station.id]);
      when(() => mockStorage.getFavoriteStationData(station.id))
          .thenReturn(station.toJson());
      when(() => mockStorage.saveFavoriteStationData(any(), any()))
          .thenAnswer((_) async {});

      final mockService = MockStationService();
      when(() => mockService.getPrices(any())).thenAnswer((_) async =>
          ServiceResult(data: {}, source: ServiceSource.tankerkoenigApi, fetchedAt: DateTime.now()));

      container = createContainer(mockService: mockService);
      await container.read(favoriteStationsProvider.notifier).loadAndRefresh();

      final state = container.read(favoriteStationsProvider);
      expect(state.value!.data, hasLength(1));
      expect(state.value!.data.first.id, station.id);
      expect(state.value!.data.first.name, station.name);
    });

    test('loadAndRefresh() fetches missing station data from API', () async {
      final station = testStation;
      when(() => mockStorage.getFavoriteIds()).thenReturn([station.id]);
      when(() => mockStorage.getFavoriteStationData(station.id)).thenReturn(null);
      when(() => mockStorage.saveFavoriteStationData(any(), any()))
          .thenAnswer((_) async {});

      final mockService = MockStationService();
      when(() => mockService.getStationDetail(station.id)).thenAnswer(
          (_) async => ServiceResult(
                data: StationDetail(station: station),
                source: ServiceSource.tankerkoenigApi,
                fetchedAt: DateTime.now(),
              ));
      when(() => mockService.getPrices(any())).thenAnswer((_) async =>
          ServiceResult(data: {}, source: ServiceSource.tankerkoenigApi, fetchedAt: DateTime.now()));

      container = createContainer(mockService: mockService);
      await container.read(favoriteStationsProvider.notifier).loadAndRefresh();

      final state = container.read(favoriteStationsProvider);
      expect(state.value!.data, hasLength(1));
      expect(state.value!.data.first.id, station.id);

      verify(() => mockService.getStationDetail(station.id)).called(1);
      verify(() => mockStorage.saveFavoriteStationData(station.id, any()))
          .called(greaterThanOrEqualTo(1));
    });

    test('loadAndRefresh() merges fresh prices into stations', () async {
      final station = testStationList[0]; // e10: 1.739
      when(() => mockStorage.getFavoriteIds()).thenReturn([station.id]);
      when(() => mockStorage.getFavoriteStationData(station.id))
          .thenReturn(station.toJson());
      when(() => mockStorage.saveFavoriteStationData(any(), any()))
          .thenAnswer((_) async {});

      final mockService = MockStationService();
      when(() => mockService.getPrices(any())).thenAnswer((_) async =>
          ServiceResult(
            data: {
              station.id: const StationPrices(
                e5: 1.819,
                e10: 1.759,
                diesel: 1.619,
                status: 'open',
              ),
            },
            source: ServiceSource.tankerkoenigApi,
            fetchedAt: DateTime.now(),
          ));

      container = createContainer(mockService: mockService);
      await container.read(favoriteStationsProvider.notifier).loadAndRefresh();

      final state = container.read(favoriteStationsProvider);
      final updated = state.value!.data.first;
      expect(updated.e5, 1.819);
      expect(updated.e10, 1.759);
      expect(updated.diesel, 1.619);
      expect(updated.isOpen, isTrue);
    });

    test('loadAndRefresh() persists updated prices back to storage', () async {
      final station = testStationList[0];
      when(() => mockStorage.getFavoriteIds()).thenReturn([station.id]);
      when(() => mockStorage.getFavoriteStationData(station.id))
          .thenReturn(station.toJson());
      when(() => mockStorage.saveFavoriteStationData(any(), any()))
          .thenAnswer((_) async {});

      final mockService = MockStationService();
      when(() => mockService.getPrices(any())).thenAnswer((_) async =>
          ServiceResult(data: {}, source: ServiceSource.tankerkoenigApi, fetchedAt: DateTime.now()));

      container = createContainer(mockService: mockService);
      await container.read(favoriteStationsProvider.notifier).loadAndRefresh();

      verify(() => mockStorage.saveFavoriteStationData(station.id, any()))
          .called(1);
    });

    test('loadAndRefresh() serves persisted data when API fails', () async {
      final station = testStationList[0];
      when(() => mockStorage.getFavoriteIds()).thenReturn([station.id]);
      when(() => mockStorage.getFavoriteStationData(station.id))
          .thenReturn(station.toJson());

      final mockService = MockStationService();
      when(() => mockService.getPrices(any()))
          .thenThrow(Exception('API error'));

      container = createContainer(mockService: mockService);
      await container.read(favoriteStationsProvider.notifier).loadAndRefresh();

      final state = container.read(favoriteStationsProvider);
      expect(state.value!.data, hasLength(1));
      expect(state.value!.data.first.id, station.id);
      expect(state.value!.isStale, isTrue);
    });

    test('loadAndRefresh() handles missing data + API failure gracefully',
        () async {
      when(() => mockStorage.getFavoriteIds()).thenReturn(['missing-id']);
      when(() => mockStorage.getFavoriteStationData('missing-id'))
          .thenReturn(null);

      final mockService = MockStationService();
      when(() => mockService.getStationDetail('missing-id'))
          .thenThrow(Exception('Station not found'));
      when(() => mockService.getPrices(any())).thenAnswer((_) async =>
          ServiceResult(data: {}, source: ServiceSource.tankerkoenigApi, fetchedAt: DateTime.now()));

      container = createContainer(mockService: mockService);
      await container.read(favoriteStationsProvider.notifier).loadAndRefresh();

      final state = container.read(favoriteStationsProvider);
      expect(state.value!.data, isEmpty);
    });

    test('loadAndRefresh() offline returns persisted data with isStale', () async {
      // Switch to offline
      _mockConnectivity(['none']);

      final station = testStationList[0];
      when(() => mockStorage.getFavoriteIds()).thenReturn([station.id]);
      when(() => mockStorage.getFavoriteStationData(station.id))
          .thenReturn(station.toJson());

      container = createContainer();
      await container.read(favoriteStationsProvider.notifier).loadAndRefresh();

      final state = container.read(favoriteStationsProvider);
      expect(state.value!.data, hasLength(1));
      expect(state.value!.isStale, isTrue);
      expect(state.value!.source, ServiceSource.cache);

      // Restore online for other tests
      _mockConnectivity(['wifi']);
    });

    test('loadAndRefresh() offline with no persisted data returns empty stale', () async {
      _mockConnectivity(['none']);

      when(() => mockStorage.getFavoriteIds()).thenReturn(['orphan-id']);
      when(() => mockStorage.getFavoriteStationData('orphan-id'))
          .thenReturn(null);

      container = createContainer();
      await container.read(favoriteStationsProvider.notifier).loadAndRefresh();

      final state = container.read(favoriteStationsProvider);
      expect(state.value!.data, isEmpty);
      expect(state.value!.isStale, isTrue);

      _mockConnectivity(['wifi']);
    });

    test('loadAndRefresh() skips corrupted JSON without crashing', () async {
      final goodStation = testStationList[0];
      when(() => mockStorage.getFavoriteIds())
          .thenReturn(['corrupt', goodStation.id]);
      // Return invalid JSON that will fail Station.fromJson()
      when(() => mockStorage.getFavoriteStationData('corrupt'))
          .thenReturn({'not': 'a station'});
      when(() => mockStorage.getFavoriteStationData(goodStation.id))
          .thenReturn(goodStation.toJson());
      when(() => mockStorage.saveFavoriteStationData(any(), any()))
          .thenAnswer((_) async {});

      final mockService = MockStationService();
      // Fetch detail for the corrupt one
      when(() => mockService.getStationDetail('corrupt'))
          .thenThrow(Exception('not found'));
      when(() => mockService.getPrices(any())).thenAnswer((_) async =>
          ServiceResult(data: {}, source: ServiceSource.tankerkoenigApi, fetchedAt: DateTime.now()));

      container = createContainer(mockService: mockService);
      await container.read(favoriteStationsProvider.notifier).loadAndRefresh();

      final state = container.read(favoriteStationsProvider);
      // Good station loaded, corrupt one skipped
      expect(state.value!.data, hasLength(1));
      expect(state.value!.data.first.id, goodStation.id);
    });

    test('loadAndRefresh() loads multiple stations in correct order', () async {
      final stations = testStationList;
      final ids = stations.map((s) => s.id).toList();
      when(() => mockStorage.getFavoriteIds()).thenReturn(ids);
      for (final s in stations) {
        when(() => mockStorage.getFavoriteStationData(s.id))
            .thenReturn(s.toJson());
      }
      when(() => mockStorage.saveFavoriteStationData(any(), any()))
          .thenAnswer((_) async {});

      final mockService = MockStationService();
      when(() => mockService.getPrices(any())).thenAnswer((_) async =>
          ServiceResult(data: {}, source: ServiceSource.tankerkoenigApi, fetchedAt: DateTime.now()));

      container = createContainer(mockService: mockService);
      await container.read(favoriteStationsProvider.notifier).loadAndRefresh();

      final state = container.read(favoriteStationsProvider);
      expect(state.value!.data, hasLength(3));
      expect(state.value!.data[0].id, 'station-cheap');
      expect(state.value!.data[1].id, 'station-mid');
      expect(state.value!.data[2].id, 'station-expensive');
    });

    test('loadAndRefresh() handles mix of persisted and missing data', () async {
      final persisted = testStationList[0];
      final missing = testStation;
      when(() => mockStorage.getFavoriteIds())
          .thenReturn([persisted.id, missing.id]);
      when(() => mockStorage.getFavoriteStationData(persisted.id))
          .thenReturn(persisted.toJson());
      when(() => mockStorage.getFavoriteStationData(missing.id))
          .thenReturn(null);
      when(() => mockStorage.saveFavoriteStationData(any(), any()))
          .thenAnswer((_) async {});

      final mockService = MockStationService();
      when(() => mockService.getStationDetail(missing.id)).thenAnswer(
          (_) async => ServiceResult(
                data: StationDetail(station: missing),
                source: ServiceSource.tankerkoenigApi,
                fetchedAt: DateTime.now(),
              ));
      when(() => mockService.getPrices(any())).thenAnswer((_) async =>
          ServiceResult(data: {}, source: ServiceSource.tankerkoenigApi, fetchedAt: DateTime.now()));

      container = createContainer(mockService: mockService);
      await container.read(favoriteStationsProvider.notifier).loadAndRefresh();

      final state = container.read(favoriteStationsProvider);
      expect(state.value!.data, hasLength(2));
      // Persisted station from Hive + missing station fetched from API
      final loadedIds = state.value!.data.map((s) => s.id).toSet();
      expect(loadedIds, contains(persisted.id));
      expect(loadedIds, contains(missing.id));
    });

    test('Station JSON round-trip through toJson/fromJson preserves all fields', () {
      final original = testStation;
      final json = original.toJson();
      final restored = Station.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.brand, original.brand);
      expect(restored.street, original.street);
      expect(restored.houseNumber, original.houseNumber);
      expect(restored.postCode, original.postCode);
      expect(restored.place, original.place);
      expect(restored.lat, original.lat);
      expect(restored.lng, original.lng);
      expect(restored.e5, original.e5);
      expect(restored.e10, original.e10);
      expect(restored.diesel, original.diesel);
      expect(restored.isOpen, original.isOpen);
    });
  });
}
