import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/favorites/providers/favorites_provider.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

/// #695 — Favorites from countries other than the active profile's country
/// must still be visible and refreshable. The provider groups favorites
/// by `Countries.countryForStation(...)` and refreshes each group using
/// `stationServiceForCountry(...)`.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('cross_country_fav_test_');
    Hive.init(tempDir.path);
    await HiveStorage.initForTest();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('favorites from multiple countries all appear in the state', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final storage = container.read(storageRepositoryProvider);

    // Seed storage: one DE station (Tankerkoenig UUID-like id), one
    // FR station (numeric id), one IT station (prefixed).
    const deStation = Station(
      id: '51d4b477-a095-1aa0-e100-80009459e03a',
      name: 'Shell Berlin',
      brand: 'Shell',
      street: 'Unter den Linden',
      houseNumber: '1',
      postCode: '10117',
      place: 'Berlin',
      lat: 52.52,
      lng: 13.41,
      dist: 0,
      e10: 1.729,
      isOpen: true,
    );
    const frStation = Station(
      id: '69100001',
      name: 'Total Villeurbanne',
      brand: 'Total',
      street: 'Cours Tolstoï',
      houseNumber: '1',
      postCode: '69100',
      place: 'Villeurbanne',
      lat: 45.77,
      lng: 4.88,
      dist: 0,
      e10: 1.779,
      isOpen: true,
    );
    const itStation = Station(
      id: 'it-12345',
      name: 'Eni Roma Centro',
      brand: 'Eni',
      street: 'Via del Corso',
      houseNumber: '1',
      postCode: '00187',
      place: 'Roma',
      lat: 41.90,
      lng: 12.48,
      dist: 0,
      e10: 1.859,
      isOpen: true,
    );

    await storage.addFavorite(deStation.id);
    await storage.saveFavoriteStationData(deStation.id, deStation.toJson());
    await storage.addFavorite(frStation.id);
    await storage.saveFavoriteStationData(frStation.id, frStation.toJson());
    await storage.addFavorite(itStation.id);
    await storage.saveFavoriteStationData(itStation.id, itStation.toJson());

    // Trigger a rebuild of the provider so it re-reads storage.
    container.invalidate(favoritesProvider);

    final state = container.read(favoriteStationsProvider);
    expect(state, isA<AsyncData>(),
        reason: 'Provider builds synchronously from storage');
    final stations = state.value!.data;
    expect(stations, hasLength(3),
        reason:
            'All three favorites (DE, FR, IT) must appear regardless of active country');
    expect(
      stations.map((s) => s.id).toSet(),
      containsAll([deStation.id, frStation.id, itStation.id]),
    );
  });

  test('Countries.countryForStation resolves each station correctly', () {
    // Pin the grouping key the provider uses so a regression in the
    // resolver fails this test rather than silently putting everything
    // under the active-country bucket.
    final de = Countries.countryForStation(
      id: '51d4b477-a095-1aa0-e100-80009459e03a',
      lat: 52.52,
      lng: 13.41,
    );
    expect(de?.code, 'DE');

    final fr = Countries.countryForStation(
      id: '69100001',
      lat: 45.77,
      lng: 4.88,
    );
    expect(fr?.code, 'FR');

    final it = Countries.countryForStation(
      id: 'it-12345',
      lat: 41.90,
      lng: 12.48,
    );
    expect(it?.code, 'IT');
  });
}
