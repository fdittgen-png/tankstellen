// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/domain/ev/charging_station.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/service_providers.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/ev/api.dart';
import 'package:tankstellen/features/station_detail/providers/station_detail_provider.dart';

import '../../../fakes/fake_hive_storage.dart';
import '../../../mocks/mocks.dart';

/// #3455 — `stationDetail` must route OpenChargeMap `ocm-*` ids to the
/// device's EV caches BEFORE any fuel-chain fallback.
///
/// Field-verified mechanism: `Countries.countryCodeForStationId('ocm-…')`
/// is null (no fuel-country prefix), so the provider fell back to the
/// ACTIVE country's fuel chain and sent the EV id to
/// prix-carburants/CMA/Luxembourg detail endpoints — `DioException 400`
/// bursts at ~1/s. These tests pin the acceptance criterion: an EV
/// favorite detail resolves with ZERO fuel-chain calls.
void main() {
  late FakeHiveStorage storage;
  late MockStationService fuelService;

  const evJson = <String, dynamic>{
    'id': 'ocm-196522',
    'name': 'Ionity Aire de Berchem',
    'operator': 'Ionity',
    'latitude': 49.55,
    'longitude': 6.12,
    'address': 'Aire de Berchem, A3',
    'place': 'Berchem',
    'postCode': '3325',
  };

  setUp(() {
    storage = FakeHiveStorage();
    fuelService = MockStationService();
  });

  ProviderContainer createContainer() {
    final c = ProviderContainer(
        // Riverpod 3 retries thrown build errors by default (exponential
        // backoff) — the typed NonFuelStationIdException would sit in
        // loading through ~10 retries. The tests assert the error itself.
        retry: (_, _) => null,
        overrides: [
      storageRepositoryProvider.overrideWithValue(storage),
      // Backed by the same fake storage — the REAL provider's settings
      // storage would open Hive via path_provider, whose platform channel
      // never answers in a unit test (the future hangs forever).
      evStationRepositoryProvider
          .overrideWithValue(EvStationRepository(storage)),
      // The active-country fuel service: any call on it is the #3455 bug.
      stationServiceProvider.overrideWithValue(fuelService),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('EV favorite detail resolves from the cached payload with ZERO '
      'fuel-chain calls', () async {
    await storage.addEvFavorite('ocm-196522');
    await storage.saveEvFavoriteStationData('ocm-196522', evJson);

    final container = createContainer();
    final result =
        await container.read(stationDetailProvider('ocm-196522').future);

    expect(result.source, ServiceSource.cache);
    expect(result.data.station.id, 'ocm-196522');
    expect(result.data.station.name, 'Ionity Aire de Berchem');
    expect(result.data.station.brand, 'Ionity');
    expect(result.data.station.lat, 49.55);
    expect(result.data.station.lng, 6.12);
    // The acceptance criterion: the fuel chain was NEVER touched.
    verifyZeroInteractions(fuelService);
  });

  test('non-favorite ocm id resolves from the recently-fetched EV cache, '
      'still zero fuel-chain calls', () async {
    // The EV map cache persists under the settings key the
    // EvStationRepository reads — not the favorites payload store.
    final cached = ChargingStation.fromJson(evJson);
    await storage.putSetting(StorageKeys.evStationsCache, [cached.toJson()]);

    final container = createContainer();
    final result =
        await container.read(stationDetailProvider('ocm-196522').future);

    expect(result.data.station.id, 'ocm-196522');
    verifyZeroInteractions(fuelService);
  });

  test('unknown ocm id throws the typed non-retrying error — the fuel '
      'chain is still never touched', () async {
    final container = createContainer();

    // Keep the autoDispose provider alive while its future settles —
    // a bare read lets the scheduler dispose it mid-load (StateError).
    final sub = container.listen(
      stationDetailProvider('ocm-999999').future,
      (_, _) {},
    );
    await expectLater(
      sub.read(),
      throwsA(isA<NonFuelStationIdException>()),
    );
    sub.close();
    verifyZeroInteractions(fuelService);
  });
}
