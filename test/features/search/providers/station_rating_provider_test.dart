import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/search/providers/station_rating_provider.dart';

import '../../../fakes/fake_hive_storage.dart';

void main() {
  late FakeHiveStorage fakeStorage;

  setUp(() {
    fakeStorage = FakeHiveStorage();
  });

  ProviderContainer createContainer() {
    final c = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(fakeStorage),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('StationRatings', () {
    test('build returns ratings from storage', () async {
      await fakeStorage.setRating('station1', 4);
      await fakeStorage.setRating('station2', 2);

      final container = createContainer();
      final ratings = container.read(stationRatingsProvider);

      expect(ratings, {'station1': 4, 'station2': 2});
    });

    test('build returns empty map when storage has no ratings', () {
      final container = createContainer();
      final ratings = container.read(stationRatingsProvider);

      expect(ratings, isEmpty);
    });

    test('rate saves clamped rating to storage', () async {
      final container = createContainer();
      await container.read(stationRatingsProvider.notifier).rate('s1', 3);

      expect(fakeStorage.getRating('s1'), 3);
    });

    test('rate clamps rating below 1 to 1', () async {
      final container = createContainer();
      await container.read(stationRatingsProvider.notifier).rate('s1', 0);

      expect(fakeStorage.getRating('s1'), 1);
    });

    test('rate clamps rating above 5 to 5', () async {
      final container = createContainer();
      await container.read(stationRatingsProvider.notifier).rate('s1', 10);

      expect(fakeStorage.getRating('s1'), 5);
    });

    test('remove calls removeRating on storage', () async {
      await fakeStorage.setRating('s1', 4);

      final container = createContainer();
      await container.read(stationRatingsProvider.notifier).remove('s1');

      expect(fakeStorage.getRating('s1'), isNull);
    });
  });

  group('stationRating', () {
    test('returns correct rating for known station', () async {
      await fakeStorage.setRating('s1', 4);
      await fakeStorage.setRating('s2', 2);

      final container = createContainer();
      expect(container.read(stationRatingProvider('s1')), 4);
    });

    test('returns null for unknown station', () async {
      await fakeStorage.setRating('s1', 4);

      final container = createContainer();
      expect(container.read(stationRatingProvider('unknown')), isNull);
    });

    test('returns null when no ratings exist', () {
      final container = createContainer();
      expect(container.read(stationRatingProvider('s1')), isNull);
    });
  });
}
