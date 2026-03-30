import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/search/providers/station_rating_provider.dart';

import '../../../mocks/mocks.dart';

void main() {
  late MockHiveStorage mockStorage;

  setUp(() {
    mockStorage = MockHiveStorage();
    // Default stub for sync state (disabled)
    when(() => mockStorage.getSetting(any())).thenReturn(null);
  });

  ProviderContainer createContainer() {
    final c = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(mockStorage),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('StationRatings', () {
    test('build returns ratings from storage', () {
      when(() => mockStorage.getRatings())
          .thenReturn({'station1': 4, 'station2': 2});

      final container = createContainer();
      final ratings = container.read(stationRatingsProvider);

      expect(ratings, {'station1': 4, 'station2': 2});
    });

    test('build returns empty map when storage has no ratings', () {
      when(() => mockStorage.getRatings()).thenReturn({});

      final container = createContainer();
      final ratings = container.read(stationRatingsProvider);

      expect(ratings, isEmpty);
    });

    test('rate saves clamped rating to storage', () async {
      when(() => mockStorage.getRatings()).thenReturn({});
      when(() => mockStorage.setRating(any(), any())).thenAnswer((_) async {});

      final container = createContainer();
      await container.read(stationRatingsProvider.notifier).rate('s1', 3);

      verify(() => mockStorage.setRating('s1', 3)).called(1);
    });

    test('rate clamps rating below 1 to 1', () async {
      when(() => mockStorage.getRatings()).thenReturn({});
      when(() => mockStorage.setRating(any(), any())).thenAnswer((_) async {});

      final container = createContainer();
      await container.read(stationRatingsProvider.notifier).rate('s1', 0);

      verify(() => mockStorage.setRating('s1', 1)).called(1);
    });

    test('rate clamps rating above 5 to 5', () async {
      when(() => mockStorage.getRatings()).thenReturn({});
      when(() => mockStorage.setRating(any(), any())).thenAnswer((_) async {});

      final container = createContainer();
      await container.read(stationRatingsProvider.notifier).rate('s1', 10);

      verify(() => mockStorage.setRating('s1', 5)).called(1);
    });

    test('remove calls removeRating on storage', () async {
      when(() => mockStorage.getRatings()).thenReturn({'s1': 4});
      when(() => mockStorage.removeRating(any())).thenAnswer((_) async {});

      final container = createContainer();
      await container.read(stationRatingsProvider.notifier).remove('s1');

      verify(() => mockStorage.removeRating('s1')).called(1);
    });
  });

  group('stationRating', () {
    test('returns correct rating for known station', () {
      when(() => mockStorage.getRatings())
          .thenReturn({'s1': 4, 's2': 2});

      final container = createContainer();
      expect(container.read(stationRatingProvider('s1')), 4);
    });

    test('returns null for unknown station', () {
      when(() => mockStorage.getRatings()).thenReturn({'s1': 4});

      final container = createContainer();
      expect(container.read(stationRatingProvider('unknown')), isNull);
    });

    test('returns null when no ratings exist', () {
      when(() => mockStorage.getRatings()).thenReturn({});

      final container = createContainer();
      expect(container.read(stationRatingProvider('s1')), isNull);
    });
  });
}
