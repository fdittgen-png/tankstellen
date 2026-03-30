import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/favorites/providers/favorites_provider.dart';

import '../../../mocks/mocks.dart';

void main() {
  late MockHiveStorage mockStorage;
  late ProviderContainer container;

  setUp(() {
    mockStorage = MockHiveStorage();
  });

  ProviderContainer createContainer() {
    final c = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(mockStorage),
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
      // Read once to initialize
      container.read(favoritesProvider);

      // After add, getFavoriteIds will return the updated list
      when(() => mockStorage.getFavoriteIds()).thenReturn(['station-1']);
      await container.read(favoritesProvider.notifier).add('station-1');

      verify(() => mockStorage.addFavorite('station-1')).called(1);
      expect(container.read(favoritesProvider), ['station-1']);
    });

    test('remove() removes station ID from list', () async {
      when(() => mockStorage.getFavoriteIds()).thenReturn(['station-1']);
      when(() => mockStorage.removeFavorite(any())).thenAnswer((_) async {});
      when(() => mockStorage.getRatings()).thenReturn({});
      when(() => mockStorage.removeRating(any())).thenAnswer((_) async {});
      when(() => mockStorage.clearPriceHistoryForStation(any())).thenAnswer((_) async {});

      container = createContainer();
      expect(container.read(favoritesProvider), ['station-1']);

      when(() => mockStorage.getFavoriteIds()).thenReturn([]);
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
  });

  group('isFavoriteProvider', () {
    test('returns true for a favorited station', () {
      when(() => mockStorage.getFavoriteIds()).thenReturn(['station-1']);

      container = createContainer();
      final result = container.read(isFavoriteProvider('station-1'));

      expect(result, isTrue);
    });

    test('returns false for a non-favorite station', () {
      when(() => mockStorage.getFavoriteIds()).thenReturn(['station-1']);

      container = createContainer();
      final result = container.read(isFavoriteProvider('station-2'));

      expect(result, isFalse);
    });

    test('returns false when no favorites exist', () {
      when(() => mockStorage.getFavoriteIds()).thenReturn([]);

      container = createContainer();
      final result = container.read(isFavoriteProvider('station-1'));

      expect(result, isFalse);
    });
  });
}
