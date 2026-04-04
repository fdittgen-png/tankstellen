import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';
import 'package:tankstellen/features/itinerary/providers/itinerary_provider.dart';

import '../../../mocks/mocks.dart';

void main() {
  group('ItineraryNotifier', () {
    late MockHiveStorage mockStorage;
    late ProviderContainer container;

    setUp(() {
      mockStorage = MockHiveStorage();
    });

    tearDown(() {
      container.dispose();
    });

    test('build returns empty list when storage has no itineraries', () {
      when(() => mockStorage.getItineraries()).thenReturn([]);

      container = ProviderContainer(overrides: [
        hiveStorageProvider.overrideWithValue(mockStorage),
        syncStateProvider.overrideWith(() => _DisabledSync()),
      ]);

      final itineraries = container.read(itineraryProvider);
      expect(itineraries, isEmpty);
    });

    test('build returns itineraries from storage', () {
      when(() => mockStorage.getItineraries()).thenReturn([
        {
          'id': 'route-1',
          'name': 'Test Route',
          'waypoints': <Map<String, dynamic>>[
            {'lat': 52.52, 'lng': 13.405, 'label': 'Berlin'},
          ],
          'distanceKm': 100.0,
          'durationMinutes': 60.0,
          'avoidHighways': false,
          'fuelType': 'e10',
          'selectedStationIds': <String>[],
          'createdAt': '2026-01-01T00:00:00.000',
          'updatedAt': '2026-01-01T00:00:00.000',
        },
      ]);

      container = ProviderContainer(overrides: [
        hiveStorageProvider.overrideWithValue(mockStorage),
        syncStateProvider.overrideWith(() => _DisabledSync()),
      ]);

      final itineraries = container.read(itineraryProvider);
      expect(itineraries, hasLength(1));
      expect(itineraries.first.name, 'Test Route');
      expect(itineraries.first.distanceKm, 100.0);
    });

    test('build handles malformed storage data gracefully', () {
      when(() => mockStorage.getItineraries()).thenThrow(Exception('corrupt'));

      container = ProviderContainer(overrides: [
        hiveStorageProvider.overrideWithValue(mockStorage),
        syncStateProvider.overrideWith(() => _DisabledSync()),
      ]);

      final itineraries = container.read(itineraryProvider);
      expect(itineraries, isEmpty);
    });
  });
}

class _DisabledSync extends SyncState {
  @override
  SyncConfig build() => const SyncConfig();
}
