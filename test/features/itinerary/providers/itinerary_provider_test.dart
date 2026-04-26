import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';
import 'package:tankstellen/features/itinerary/providers/itinerary_provider.dart';

import '../../../fakes/fake_hive_storage.dart';

void main() {
  group('ItineraryNotifier', () {
    late FakeHiveStorage fakeStorage;
    late ProviderContainer container;

    setUp(() {
      fakeStorage = FakeHiveStorage();
    });

    tearDown(() {
      container.dispose();
    });

    test('build returns empty list when storage has no itineraries', () {
      container = ProviderContainer(overrides: [
        hiveStorageProvider.overrideWithValue(fakeStorage),
        syncStateProvider.overrideWith(() => _DisabledSync()),
      ]);

      final itineraries = container.read(itineraryProvider);
      expect(itineraries, isEmpty);
    });

    test('build returns itineraries from storage', () async {
      await fakeStorage.saveItineraries([
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
        hiveStorageProvider.overrideWithValue(fakeStorage),
        syncStateProvider.overrideWith(() => _DisabledSync()),
      ]);

      final itineraries = container.read(itineraryProvider);
      expect(itineraries, hasLength(1));
      expect(itineraries.first.name, 'Test Route');
      expect(itineraries.first.distanceKm, 100.0);
    });

    test('build handles malformed storage data gracefully', () {
      // Use a fake variant whose getItineraries throws to exercise the
      // catch-and-fall-back path. The previous mocktail spec used
      // thenThrow; here we extend the fake to model the same condition.
      final throwingStorage = _ThrowingItineraryFake();

      container = ProviderContainer(overrides: [
        hiveStorageProvider.overrideWithValue(throwingStorage),
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

class _ThrowingItineraryFake extends FakeHiveStorage {
  @override
  List<Map<String, dynamic>> getItineraries() {
    throw Exception('corrupt');
  }
}
