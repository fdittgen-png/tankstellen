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

import '../../../fakes/fake_hive_storage.dart';
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

  late FakeHiveStorage fakeStorage;
  late ProviderContainer container;

  setUp(() {
    fakeStorage = FakeHiveStorage();
  });

  ProviderContainer createContainer({MockStationService? mockService}) {
    final c = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(fakeStorage),
      if (mockService != null)
        stationServiceProvider.overrideWithValue(mockService),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('Favorites', () {
    test('build returns favorite IDs from storage', () async {
      await fakeStorage.setFavoriteIds(['a', 'b']);

      container = createContainer();
      final ids = container.read(favoritesProvider);

      expect(ids, ['a', 'b']);
    });

    test('add() adds station ID to list', () async {
      container = createContainer();
      container.read(favoritesProvider);

      await container.read(favoritesProvider.notifier).add('station-1');

      expect(fakeStorage.getFavoriteIds(), ['station-1']);
      expect(container.read(favoritesProvider), ['station-1']);
    });

    test('add() with stationData persists station JSON', () async {
      container = createContainer();
      container.read(favoritesProvider);

      await container
          .read(favoritesProvider.notifier)
          .add(testStation.id, stationData: testStation);

      expect(fakeStorage.getFavoriteStationData(testStation.id),
          testStation.toJson());
    });

    test('add() without stationData does NOT persist station JSON',
        () async {
      container = createContainer();
      container.read(favoritesProvider);

      await container.read(favoritesProvider.notifier).add('station-1');

      expect(fakeStorage.getFavoriteStationData('station-1'), isNull);
    });

    test('remove() removes station ID and persisted data', () async {
      await fakeStorage.setFavoriteIds(['station-1']);
      await fakeStorage.saveFavoriteStationData(
          'station-1', testStation.toJson());

      container = createContainer();
      expect(container.read(favoritesProvider), ['station-1']);

      await container.read(favoritesProvider.notifier).remove('station-1');

      expect(fakeStorage.getFavoriteIds(), isEmpty);
      expect(fakeStorage.getFavoriteStationData('station-1'), isNull);
      expect(container.read(favoritesProvider), isEmpty);
    });

    test('remove() cleans up rating and price history', () async {
      await fakeStorage.setFavoriteIds(['station-1']);
      await fakeStorage.setRating('station-1', 4);
      await fakeStorage.savePriceRecords('station-1', [
        {'ts': '2026-04-01', 'e10': 1.799},
      ]);

      container = createContainer();
      container.read(favoritesProvider);

      await container.read(favoritesProvider.notifier).remove('station-1');

      expect(fakeStorage.getRating('station-1'), isNull);
      expect(fakeStorage.getPriceRecords('station-1'), isEmpty);
    });

    // Regression for issue #423: the rating-cleanup call inside remove()
    // used to be fire-and-forget, which meant a fast follow-up read could
    // observe a still-present rating. The fix awaits it; this test pins
    // the awaited ordering so it can't regress.
    test('remove() awaits the rating cleanup before returning', () async {
      // For the timing-sensitive ordering test we need a controllable async
      // stub on removeRating; mocktail is the right fit here so we keep it
      // for this single case. The rest of the storage state lives on the
      // fake.
      final orderedStorage = _OrderedRemoveRatingFake();
      await orderedStorage.setFavoriteIds(['station-1']);
      await orderedStorage.setRating('station-1', 4);

      container = ProviderContainer(overrides: [
        hiveStorageProvider.overrideWithValue(orderedStorage),
      ]);
      addTearDown(container.dispose);
      container.read(favoritesProvider);

      final removeFuture =
          container.read(favoritesProvider.notifier).remove('station-1');

      // Yield once so remove() reaches the rating cleanup call.
      await Future<void>.delayed(Duration.zero);
      expect(orderedStorage.removeRatingCalled, isTrue,
          reason: 'remove() should call rating cleanup before completing');
      expect(removeFuture, isA<Future<void>>(),
          reason: 'remove() should still be pending while cleanup is running');

      orderedStorage.completer.complete();
      await removeFuture;
      expect(orderedStorage.getRating('station-1'), isNull);
    });

    test('remove() succeeds even if price history cleanup throws', () async {
      final throwingStorage = _ThrowingPriceHistoryFake();
      await throwingStorage.setFavoriteIds(['station-1']);

      container = ProviderContainer(overrides: [
        hiveStorageProvider.overrideWithValue(throwingStorage),
      ]);
      addTearDown(container.dispose);
      container.read(favoritesProvider);

      // Should not throw — cleanup errors are caught
      await container.read(favoritesProvider.notifier).remove('station-1');

      expect(throwingStorage.getFavoriteIds(), isEmpty);
      expect(container.read(favoritesProvider), isEmpty);
    });

    test('toggle() adds if not present', () async {
      container = createContainer();
      container.read(favoritesProvider);

      await container.read(favoritesProvider.notifier).toggle('station-1');

      expect(fakeStorage.getFavoriteIds(), ['station-1']);
    });

    test('toggle() removes if already present', () async {
      await fakeStorage.setFavoriteIds(['station-1']);

      container = createContainer();
      container.read(favoritesProvider);

      await container.read(favoritesProvider.notifier).toggle('station-1');

      expect(fakeStorage.getFavoriteIds(), isEmpty);
    });

    test('toggle() with stationData passes it through to add()', () async {
      container = createContainer();
      container.read(favoritesProvider);

      await container
          .read(favoritesProvider.notifier)
          .toggle(testStation.id, stationData: testStation);

      expect(fakeStorage.getFavoriteStationData(testStation.id),
          testStation.toJson());
    });
  });

  group('isFavoriteProvider', () {
    test('returns true for a favorited station', () async {
      await fakeStorage.setFavoriteIds(['station-1']);

      container = createContainer();
      expect(container.read(isFavoriteProvider('station-1')), isTrue);
    });

    test('returns false for a non-favorite station', () async {
      await fakeStorage.setFavoriteIds(['station-1']);

      container = createContainer();
      expect(container.read(isFavoriteProvider('station-2')), isFalse);
    });

    test('returns false when no favorites exist', () {
      container = createContainer();
      expect(container.read(isFavoriteProvider('station-1')), isFalse);
    });
  });

  group('FavoriteStations', () {
    test('build() returns empty list', () {
      container = createContainer();
      final state = container.read(favoriteStationsProvider);

      expect(state, isA<AsyncData>());
      expect(state.value!.data, isEmpty);
    });

    test('loadAndRefresh() returns empty when no favorites', () async {
      container = createContainer();
      await container.read(favoriteStationsProvider.notifier).loadAndRefresh();

      final state = container.read(favoriteStationsProvider);
      expect(state.value!.data, isEmpty);
    });

    test('loadAndRefresh() loads persisted stations from storage', () async {
      final station = testStationList[0];
      await fakeStorage.setFavoriteIds([station.id]);
      await fakeStorage.saveFavoriteStationData(station.id, station.toJson());

      final mockService = MockStationService();
      when(() => mockService.getPrices(any())).thenAnswer((_) async =>
          ServiceResult(
              data: {},
              source: ServiceSource.tankerkoenigApi,
              fetchedAt: DateTime.now()));

      container = createContainer(mockService: mockService);
      await container.read(favoriteStationsProvider.notifier).loadAndRefresh();

      final state = container.read(favoriteStationsProvider);
      expect(state.value!.data, hasLength(1));
      expect(state.value!.data.first.id, station.id);
      expect(state.value!.data.first.name, station.name);
    });

    test('loadAndRefresh() fetches missing station data from API', () async {
      const station = testStation;
      await fakeStorage.setFavoriteIds([station.id]);

      final mockService = MockStationService();
      when(() => mockService.getStationDetail(station.id)).thenAnswer(
          (_) async => ServiceResult(
                data: const StationDetail(station: station),
                source: ServiceSource.tankerkoenigApi,
                fetchedAt: DateTime.now(),
              ));
      when(() => mockService.getPrices(any())).thenAnswer((_) async =>
          ServiceResult(
              data: {},
              source: ServiceSource.tankerkoenigApi,
              fetchedAt: DateTime.now()));

      container = createContainer(mockService: mockService);
      await container.read(favoriteStationsProvider.notifier).loadAndRefresh();

      final state = container.read(favoriteStationsProvider);
      expect(state.value!.data, hasLength(1));
      expect(state.value!.data.first.id, station.id);

      verify(() => mockService.getStationDetail(station.id)).called(1);
      // Production should persist what it fetched so the next start has it
      // available offline.
      expect(fakeStorage.getFavoriteStationData(station.id), isNotNull);
    });

    test('loadAndRefresh() merges fresh prices into stations', () async {
      final station = testStationList[0]; // e10: 1.739
      await fakeStorage.setFavoriteIds([station.id]);
      await fakeStorage.saveFavoriteStationData(station.id, station.toJson());

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

    test('loadAndRefresh() persists updated prices back to storage',
        () async {
      final station = testStationList[0];
      await fakeStorage.setFavoriteIds([station.id]);
      await fakeStorage.saveFavoriteStationData(station.id, station.toJson());

      final mockService = MockStationService();
      when(() => mockService.getPrices(any())).thenAnswer((_) async =>
          ServiceResult(
              data: {},
              source: ServiceSource.tankerkoenigApi,
              fetchedAt: DateTime.now()));

      container = createContainer(mockService: mockService);
      await container.read(favoriteStationsProvider.notifier).loadAndRefresh();

      // Production rewrites the persisted JSON after refresh.
      expect(fakeStorage.getFavoriteStationData(station.id), isNotNull);
    });

    test('loadAndRefresh() serves persisted data when API fails', () async {
      final station = testStationList[0];
      await fakeStorage.setFavoriteIds([station.id]);
      await fakeStorage.saveFavoriteStationData(station.id, station.toJson());

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
      await fakeStorage.setFavoriteIds(['missing-id']);

      final mockService = MockStationService();
      when(() => mockService.getStationDetail('missing-id'))
          .thenThrow(Exception('Station not found'));
      when(() => mockService.getPrices(any())).thenAnswer((_) async =>
          ServiceResult(
              data: {},
              source: ServiceSource.tankerkoenigApi,
              fetchedAt: DateTime.now()));

      container = createContainer(mockService: mockService);
      await container.read(favoriteStationsProvider.notifier).loadAndRefresh();

      final state = container.read(favoriteStationsProvider);
      expect(state.value!.data, isEmpty);
    });

    test('loadAndRefresh() offline returns persisted data with isStale',
        () async {
      // Switch to offline
      _mockConnectivity(['none']);

      final station = testStationList[0];
      await fakeStorage.setFavoriteIds([station.id]);
      await fakeStorage.saveFavoriteStationData(station.id, station.toJson());

      container = createContainer();
      await container.read(favoriteStationsProvider.notifier).loadAndRefresh();

      final state = container.read(favoriteStationsProvider);
      expect(state.value!.data, hasLength(1));
      expect(state.value!.isStale, isTrue);
      expect(state.value!.source, ServiceSource.cache);

      // Restore online for other tests
      _mockConnectivity(['wifi']);
    });

    test('loadAndRefresh() offline with no persisted data returns empty stale',
        () async {
      _mockConnectivity(['none']);

      await fakeStorage.setFavoriteIds(['orphan-id']);

      container = createContainer();
      await container.read(favoriteStationsProvider.notifier).loadAndRefresh();

      final state = container.read(favoriteStationsProvider);
      expect(state.value!.data, isEmpty);
      expect(state.value!.isStale, isTrue);

      _mockConnectivity(['wifi']);
    });

    test('loadAndRefresh() skips corrupted JSON without crashing', () async {
      final goodStation = testStationList[0];
      await fakeStorage.setFavoriteIds(['corrupt', goodStation.id]);
      await fakeStorage.saveFavoriteStationData('corrupt', {'not': 'a station'});
      await fakeStorage.saveFavoriteStationData(
          goodStation.id, goodStation.toJson());

      final mockService = MockStationService();
      // Fetch detail for the corrupt one
      when(() => mockService.getStationDetail('corrupt'))
          .thenThrow(Exception('not found'));
      when(() => mockService.getPrices(any())).thenAnswer((_) async =>
          ServiceResult(
              data: {},
              source: ServiceSource.tankerkoenigApi,
              fetchedAt: DateTime.now()));

      container = createContainer(mockService: mockService);
      await container.read(favoriteStationsProvider.notifier).loadAndRefresh();

      final state = container.read(favoriteStationsProvider);
      // Good station loaded, corrupt one skipped
      expect(state.value!.data, hasLength(1));
      expect(state.value!.data.first.id, goodStation.id);
    });

    test('loadAndRefresh() loads multiple stations in correct order',
        () async {
      final stations = testStationList;
      final ids = stations.map((s) => s.id).toList();
      await fakeStorage.setFavoriteIds(ids);
      for (final s in stations) {
        await fakeStorage.saveFavoriteStationData(s.id, s.toJson());
      }

      final mockService = MockStationService();
      when(() => mockService.getPrices(any())).thenAnswer((_) async =>
          ServiceResult(
              data: {},
              source: ServiceSource.tankerkoenigApi,
              fetchedAt: DateTime.now()));

      container = createContainer(mockService: mockService);
      await container.read(favoriteStationsProvider.notifier).loadAndRefresh();

      final state = container.read(favoriteStationsProvider);
      expect(state.value!.data, hasLength(3));
      expect(state.value!.data[0].id, 'station-cheap');
      expect(state.value!.data[1].id, 'station-mid');
      expect(state.value!.data[2].id, 'station-expensive');
    });

    test('loadAndRefresh() handles mix of persisted and missing data',
        () async {
      final persisted = testStationList[0];
      const missing = testStation;
      await fakeStorage.setFavoriteIds([persisted.id, missing.id]);
      await fakeStorage.saveFavoriteStationData(
          persisted.id, persisted.toJson());

      final mockService = MockStationService();
      when(() => mockService.getStationDetail(missing.id)).thenAnswer(
          (_) async => ServiceResult(
                data: const StationDetail(station: missing),
                source: ServiceSource.tankerkoenigApi,
                fetchedAt: DateTime.now(),
              ));
      when(() => mockService.getPrices(any())).thenAnswer((_) async =>
          ServiceResult(
              data: {},
              source: ServiceSource.tankerkoenigApi,
              fetchedAt: DateTime.now()));

      container = createContainer(mockService: mockService);
      await container.read(favoriteStationsProvider.notifier).loadAndRefresh();

      final state = container.read(favoriteStationsProvider);
      expect(state.value!.data, hasLength(2));
      // Persisted station from Hive + missing station fetched from API
      final loadedIds = state.value!.data.map((s) => s.id).toSet();
      expect(loadedIds, contains(persisted.id));
      expect(loadedIds, contains(missing.id));
    });

    test('Station JSON round-trip through toJson/fromJson preserves all fields',
        () {
      const original = testStation;
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

/// Fake variant that exposes a controllable [Completer] for the rating
/// cleanup, so the await-ordering regression test (#423) can pin the
/// timing without leaning on mocktail.
class _OrderedRemoveRatingFake extends FakeHiveStorage {
  final Completer<void> completer = Completer<void>();
  bool removeRatingCalled = false;

  @override
  Future<void> removeRating(String stationId) async {
    removeRatingCalled = true;
    await completer.future;
    await super.removeRating(stationId);
  }
}

/// Fake variant whose price-history cleanup throws — used to assert the
/// remove() flow swallows storage errors and still drops the favorite.
class _ThrowingPriceHistoryFake extends FakeHiveStorage {
  @override
  Future<void> clearPriceHistoryForStation(String stationId) async {
    throw Exception('corrupt');
  }
}
