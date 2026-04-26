import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_station.dart';
import 'package:tankstellen/features/favorites/providers/ev_favorites_provider.dart';
import 'package:tankstellen/features/favorites/providers/favorites_provider.dart';

import '../../../fakes/fake_hive_storage.dart';

/// Tests that exercise the REAL code path on the device:
///
/// 1. EVChargingService returns canonical [ChargingStation] (post-#560)
/// 2. EVStationResult wraps it
/// 3. Router passes it to EVStationDetailScreen
/// 4. User taps star → calls favoritesProvider.notifier.toggle(id, rawJson: …)
/// 5. Favorites tab reads evFavoriteStationsProvider → station must appear
void main() {
  late FakeHiveStorage fakeStorage;

  // Canonical unified type after #560 — same entity everywhere.
  const searchStation = ChargingStation(
    id: 'ocm-12345',
    name: 'Charger Pézenas',
    operator: 'Ionity',
    latitude: 43.46,
    longitude: 3.42,
    address: '1 Avenue du Test',
  );

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

  group('Real device flow: EV favorite from search results', () {
    test(
      'EXACT DEVICE PATH: toggle(stationId) with rawJson — '
      'station MUST appear in evFavoriteStationsProvider',
      () async {
        final container = createContainer();

        // This is exactly what EVStationDetailScreen does:
        // ref.read(favoritesProvider.notifier).toggle(
        //   station.id, rawJson: station.toJson());
        await container
            .read(favoritesProvider.notifier)
            .toggle(searchStation.id, rawJson: searchStation.toJson());

        // The ID should be in the unified list
        expect(container.read(favoritesProvider), contains('ocm-12345'),
            reason: 'toggle adds the ID');

        // With the unified entity, fromJson handles the serialised form
        // natively so EvFavoriteStations rehydrates the station.
        final evStations = container.read(evFavoriteStationsProvider);
        expect(evStations, hasLength(1),
            reason:
                'EV station favorited via toggle() must appear in EV favorites');
        expect(evStations.first.id, 'ocm-12345');
      },
    );

    test(
      'toggle(id) for an EV station (ocm- prefix) persists station data '
      'so EvFavoriteStations can load it',
      () async {
        final container = createContainer();

        await container
            .read(favoritesProvider.notifier)
            .toggle(searchStation.id, rawJson: searchStation.toJson());

        expect(container.read(favoritesProvider), contains('ocm-12345'));

        final hasEvData =
            fakeStorage.getEvFavoriteStationData('ocm-12345') != null;
        final hasFuelData =
            fakeStorage.getFavoriteStationData('ocm-12345') != null;
        expect(hasEvData || hasFuelData, isTrue,
            reason:
                'Station data must be persisted for favorites to display it');
      },
    );
  });
}
