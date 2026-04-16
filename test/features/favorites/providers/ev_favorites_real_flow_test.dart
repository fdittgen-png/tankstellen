import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/search/domain/entities/charging_station.dart';
import 'package:tankstellen/features/favorites/providers/ev_favorites_provider.dart';
import 'package:tankstellen/features/favorites/providers/favorites_provider.dart';

import '../../../mocks/mocks.dart';

/// Tests that exercise the REAL code path on the device:
///
/// 1. EVChargingService returns search/ ChargingStation
/// 2. EVStationResult wraps it
/// 3. Router passes it to EVStationDetailScreen (search/ version)
/// 4. User taps star → calls favoritesProvider.notifier.toggle(id)
///    (BUG: should call toggleEv with stationData)
/// 5. Favorites tab reads evFavoriteStationsProvider → should show the station
void main() {
  late MockHiveStorage mockStorage;
  late List<String> fuelIds;
  late List<String> evIds;
  late Map<String, Map<String, dynamic>> fuelStationData;
  late Map<String, Map<String, dynamic>> evStationData;

  // This is the type returned by EVChargingService and wrapped in EVStationResult
  const searchStation = ChargingStation(
    id: 'ocm-12345',
    name: 'Charger Pézenas',
    operator: 'Ionity',
    lat: 43.46,
    lng: 3.42,
    address: '1 Avenue du Test',
    connectors: [],
  );

  setUp(() {
    mockStorage = MockHiveStorage();
    fuelIds = [];
    evIds = [];
    fuelStationData = {};
    evStationData = {};

    // Fuel storage
    when(() => mockStorage.getFavoriteIds())
        .thenAnswer((_) => List.of(fuelIds));
    when(() => mockStorage.addFavorite(any())).thenAnswer((inv) async {
      final id = inv.positionalArguments.first as String;
      if (!fuelIds.contains(id)) fuelIds.add(id);
    });
    when(() => mockStorage.removeFavorite(any())).thenAnswer((inv) async {
      fuelIds.remove(inv.positionalArguments.first);
    });
    when(() => mockStorage.isFavorite(any()))
        .thenAnswer((inv) => fuelIds.contains(inv.positionalArguments.first));
    when(() => mockStorage.saveFavoriteStationData(any(), any()))
        .thenAnswer((inv) async {
      fuelStationData[inv.positionalArguments.first as String] =
          inv.positionalArguments[1] as Map<String, dynamic>;
    });
    when(() => mockStorage.getFavoriteStationData(any())).thenAnswer((inv) {
      return fuelStationData[inv.positionalArguments.first];
    });
    when(() => mockStorage.removeFavoriteStationData(any()))
        .thenAnswer((inv) async {
      fuelStationData.remove(inv.positionalArguments.first);
    });

    // EV storage
    when(() => mockStorage.getEvFavoriteIds())
        .thenAnswer((_) => List.of(evIds));
    when(() => mockStorage.addEvFavorite(any())).thenAnswer((inv) async {
      final id = inv.positionalArguments.first as String;
      if (!evIds.contains(id)) evIds.add(id);
    });
    when(() => mockStorage.removeEvFavorite(any())).thenAnswer((inv) async {
      evIds.remove(inv.positionalArguments.first);
    });
    when(() => mockStorage.isEvFavorite(any()))
        .thenAnswer((inv) => evIds.contains(inv.positionalArguments.first));
    when(() => mockStorage.saveEvFavoriteStationData(any(), any()))
        .thenAnswer((inv) async {
      evStationData[inv.positionalArguments.first as String] =
          inv.positionalArguments[1] as Map<String, dynamic>;
    });
    when(() => mockStorage.getEvFavoriteStationData(any())).thenAnswer((inv) {
      return evStationData[inv.positionalArguments.first];
    });
    when(() => mockStorage.removeEvFavoriteStationData(any()))
        .thenAnswer((inv) async {
      evStationData.remove(inv.positionalArguments.first);
    });

    // Misc
    when(() => mockStorage.getSetting(any())).thenReturn(null);
    when(() => mockStorage.getRatings()).thenReturn({});
    when(() => mockStorage.removeRating(any())).thenAnswer((_) async {});
    when(() => mockStorage.clearPriceHistoryForStation(any()))
        .thenAnswer((_) async {});

    registerFallbackValue(<String, dynamic>{});
  });

  ProviderContainer createContainer() {
    final c = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(mockStorage),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('Real device flow: EV favorite from search results', () {
    test(
      'EXACT DEVICE PATH: toggle(stationId) without stationData — '
      'station MUST appear in evFavoriteStationsProvider',
      () async {
        final container = createContainer();

        // This is exactly what EVStationDetailScreen (search/ version) does:
        // ref.read(favoritesProvider.notifier).toggle(station.id, rawJson: station.toJson());
        await container
            .read(favoritesProvider.notifier)
            .toggle(searchStation.id, rawJson: searchStation.toJson());

        // The ID should be in the unified list
        expect(container.read(favoritesProvider), contains('ocm-12345'),
            reason: 'toggle adds the ID');

        // But is it in evFavoriteStationsProvider? On the device: NO,
        // because toggle() adds to FUEL storage, not EV storage.
        // EvFavoriteStations reads from EV storage → station is missing.
        final evStations = container.read(evFavoriteStationsProvider);

        // THIS IS THE ASSERTION THAT MUST PASS FOR THE FIX TO WORK:
        // The EV station should appear in the favorites list.
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

        // The search/ detail screen passes rawJson from station.toJson().
        await container
            .read(favoritesProvider.notifier)
            .toggle(searchStation.id, rawJson: searchStation.toJson());

        // Even without explicit stationData, the favorites tab should
        // show SOMETHING for this station (at minimum the ID).
        expect(container.read(favoritesProvider), contains('ocm-12345'));

        // Check that station data was persisted in SOME storage
        final hasEvData = evStationData.containsKey('ocm-12345');
        final hasFuelData = fuelStationData.containsKey('ocm-12345');
        expect(hasEvData || hasFuelData, isTrue,
            reason: 'Station data must be persisted for favorites to display it');
      },
    );
  });
}
