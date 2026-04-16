import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/favorites/providers/favorites_provider.dart';

import '../../../fixtures/stations.dart';
import '../../../mocks/mocks.dart';

/// Regression guard for #474 — the favorites tab hangs on the loading
/// skeleton on first open after adding a favorite, only fixed by app
/// restart.
///
/// Root cause: `FavoriteStations.build()` was reading
/// `favoritesProvider` instead of watching it, so when the user added
/// a favorite the loaded station list never invalidated. The loading
/// view condition `result.data.isEmpty && !hasEvFavorites` then stayed
/// true forever because the new favorite never propagated.
///
/// This test exercises the full chain:
/// 1. Empty favorites → `FavoriteStations` returns empty data
/// 2. Add a favorite via `Favorites.add` (the same path the search
///    screen's star button uses)
/// 3. Re-read `FavoriteStations` — the new station must be present
///    *without any explicit invalidate* because the provider should
///    have rebuilt automatically when `favoritesProvider` changed.
void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  group('FavoriteStations rebuilds when Favorites changes (regression #474)',
      () {
    late MockStorageRepository storage;
    late ProviderContainer container;
    final Map<String, Map<String, dynamic>> persistedStationData = {};
    List<String> persistedIds = [];

    setUp(() {
      storage = MockStorageRepository();
      persistedIds = [];
      persistedStationData.clear();

      // Wire the mock to a tiny in-memory store so add/get round-trip.
      when(() => storage.getFavoriteIds()).thenAnswer((_) => List.of(persistedIds));
      when(() => storage.addFavorite(any())).thenAnswer((inv) async {
        final id = inv.positionalArguments.first as String;
        if (!persistedIds.contains(id)) {
          persistedIds = [...persistedIds, id];
        }
      });
      when(() => storage.removeFavorite(any())).thenAnswer((inv) async {
        final id = inv.positionalArguments.first as String;
        persistedIds = persistedIds.where((x) => x != id).toList();
      });
      when(() => storage.removeFavoriteStationData(any()))
          .thenAnswer((inv) async {
        persistedStationData.remove(inv.positionalArguments.first);
      });
      when(() => storage.saveFavoriteStationData(any(), any()))
          .thenAnswer((inv) async {
        final id = inv.positionalArguments.first as String;
        final data = inv.positionalArguments[1] as Map<String, dynamic>;
        persistedStationData[id] = data;
      });
      when(() => storage.getFavoriteStationData(any())).thenAnswer((inv) {
        return persistedStationData[inv.positionalArguments.first];
      });
      // EV stubs (unified Favorites.build merges both lists)
      when(() => storage.getEvFavoriteIds()).thenReturn([]);
      when(() => storage.isFavorite(any())).thenReturn(true);
      when(() => storage.isEvFavorite(any())).thenReturn(false);

      container = ProviderContainer(
        overrides: [
          storageRepositoryProvider.overrideWithValue(storage),
        ],
      );
    });

    tearDown(() => container.dispose());

    test(
      'starting empty -> add a favorite -> FavoriteStations now contains '
      'the new station without a manual invalidate',
      () async {
        // Step 1 — initial state is empty
        final initial = container.read(favoriteStationsProvider);
        expect(initial.value?.data, isEmpty,
            reason: 'no favorites yet, station list should be empty');

        // Step 2 — user stars a station from the search screen
        await container
            .read(favoritesProvider.notifier)
            .add(testStation.id, stationData: testStation);

        // Step 3 — without any explicit invalidate, FavoriteStations must
        // have rebuilt and now contain the starred station. Before the fix
        // for #474 this returned an empty list because build() used `read`
        // instead of `watch`.
        final after = container.read(favoriteStationsProvider);
        expect(after.value?.data, hasLength(1));
        expect(after.value?.data.first.id, testStation.id);
      },
    );

    test('removing a favorite also rebuilds FavoriteStations', () async {
      // Pre-populate with one favorite
      await container
          .read(favoritesProvider.notifier)
          .add(testStation.id, stationData: testStation);
      expect(container.read(favoriteStationsProvider).value?.data, hasLength(1));

      // Remove
      when(() => storage.clearPriceHistoryForStation(any()))
          .thenAnswer((_) async {});
      when(() => storage.getRatings()).thenReturn(const <String, int>{});
      when(() => storage.removeRating(any())).thenAnswer((_) async {});
      await container.read(favoritesProvider.notifier).remove(testStation.id);

      // FavoriteStations should now reflect the empty list
      final after = container.read(favoriteStationsProvider);
      expect(after.value?.data, isEmpty,
          reason: 'removing a favorite should rebuild FavoriteStations');
    });
  });
}
