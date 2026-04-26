import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/search/providers/ignored_stations_provider.dart';

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

  group('IgnoredStations', () {
    test('build returns ignored IDs from storage', () async {
      await fakeStorage.setIgnoredIds(['station1', 'station2']);

      final container = createContainer();
      final ignored = container.read(ignoredStationsProvider);

      expect(ignored, ['station1', 'station2']);
    });

    test('build returns empty list when no ignored stations', () {
      final container = createContainer();
      expect(container.read(ignoredStationsProvider), isEmpty);
    });

    test('add calls addIgnored on storage', () async {
      final container = createContainer();
      await container.read(ignoredStationsProvider.notifier).add('station1');

      expect(fakeStorage.getIgnoredIds(), contains('station1'));
    });

    test('remove calls removeIgnored on storage', () async {
      await fakeStorage.setIgnoredIds(['station1']);

      final container = createContainer();
      await container
          .read(ignoredStationsProvider.notifier)
          .remove('station1');

      expect(fakeStorage.getIgnoredIds(), isNot(contains('station1')));
    });
  });

  group('isIgnored', () {
    test('returns true for ignored station', () async {
      await fakeStorage.setIgnoredIds(['s1', 's2']);

      final container = createContainer();
      expect(container.read(isIgnoredProvider('s1')), isTrue);
    });

    test('returns false for non-ignored station', () async {
      await fakeStorage.setIgnoredIds(['s1']);

      final container = createContainer();
      expect(container.read(isIgnoredProvider('s2')), isFalse);
    });

    test('returns false when no stations ignored', () {
      final container = createContainer();
      expect(container.read(isIgnoredProvider('s1')), isFalse);
    });
  });
}
