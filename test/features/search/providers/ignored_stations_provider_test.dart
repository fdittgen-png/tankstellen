import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/search/providers/ignored_stations_provider.dart';

import '../../../mocks/mocks.dart';

void main() {
  late MockHiveStorage mockStorage;

  setUp(() {
    mockStorage = MockHiveStorage();
    when(() => mockStorage.getSetting(any())).thenReturn(null);
  });

  ProviderContainer createContainer() {
    final c = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(mockStorage),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('IgnoredStations', () {
    test('build returns ignored IDs from storage', () {
      when(() => mockStorage.getIgnoredIds())
          .thenReturn(['station1', 'station2']);

      final container = createContainer();
      final ignored = container.read(ignoredStationsProvider);

      expect(ignored, ['station1', 'station2']);
    });

    test('build returns empty list when no ignored stations', () {
      when(() => mockStorage.getIgnoredIds()).thenReturn([]);

      final container = createContainer();
      expect(container.read(ignoredStationsProvider), isEmpty);
    });

    test('add calls addIgnored on storage', () async {
      when(() => mockStorage.getIgnoredIds()).thenReturn([]);
      when(() => mockStorage.addIgnored(any())).thenAnswer((_) async {});

      final container = createContainer();
      await container.read(ignoredStationsProvider.notifier).add('station1');

      verify(() => mockStorage.addIgnored('station1')).called(1);
    });

    test('remove calls removeIgnored on storage', () async {
      when(() => mockStorage.getIgnoredIds()).thenReturn(['station1']);
      when(() => mockStorage.removeIgnored(any())).thenAnswer((_) async {});

      final container = createContainer();
      await container.read(ignoredStationsProvider.notifier).remove('station1');

      verify(() => mockStorage.removeIgnored('station1')).called(1);
    });
  });

  group('isIgnored', () {
    test('returns true for ignored station', () {
      when(() => mockStorage.getIgnoredIds()).thenReturn(['s1', 's2']);

      final container = createContainer();
      expect(container.read(isIgnoredProvider('s1')), isTrue);
    });

    test('returns false for non-ignored station', () {
      when(() => mockStorage.getIgnoredIds()).thenReturn(['s1']);

      final container = createContainer();
      expect(container.read(isIgnoredProvider('s2')), isFalse);
    });

    test('returns false when no stations ignored', () {
      when(() => mockStorage.getIgnoredIds()).thenReturn([]);

      final container = createContainer();
      expect(container.read(isIgnoredProvider('s1')), isFalse);
    });
  });
}
