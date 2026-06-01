// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/core/services/service_providers.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/route_search/data/strategies/route_geometry.dart';
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';
import 'package:tankstellen/features/route_search/providers/route_search_provider.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

/// #2595 — a route that crosses from France into Spain must query BOTH
/// countries' open-data sources (per the available profiles) and merge
/// the legs into one corridor result — each leg priced for ITS country's
/// profile fuel. Before the fix, the search resolved the country via a
/// network geocode that, on null/timeout, fell back to the active
/// profile's country (FR Prix-Carburants) and queried it with the single
/// active fuel (E85), so the Spanish leg was empty.
///
/// The OSRM `RoutingService` is constructed inside `searchAlongRoute` and
/// not injectable, so this drives the dedicated
/// `searchAlongPrebuiltRouteForTest` seam with a hand-built corridor — it
/// runs the exact corridor-map build + per-country-fuel query function +
/// strategy sweep + merge that production uses, with NO network.

/// A fake [StationService] for one country that returns a single branded
/// station AT each queried point (so it lands on the route polyline and
/// survives the detour filter), priced for whatever fuel was requested.
/// Records the fuel types it was asked for so the test can assert each
/// leg was queried with its own profile fuel.
class _BrandedStationService implements StationService {
  _BrandedStationService(this.brand);

  final String brand;
  final requestedFuels = <FuelType>[];

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    requestedFuels.add(params.fuelType);
    final station = Station(
      id: '$brand-${params.lat.toStringAsFixed(2)}-${params.lng.toStringAsFixed(2)}',
      name: '$brand station',
      brand: brand,
      street: 'Route',
      postCode: '00000',
      place: brand,
      lat: params.lat,
      lng: params.lng,
      isOpen: true,
      // Price only the requested fuel — mirrors a real country dataset
      // that doesn't carry the other country's grade (ES has no E85).
      e85: params.fuelType == FuelType.e85 ? 1.20 : null,
      e10: params.fuelType == FuelType.e10 ? 1.60 : null,
    );
    return ServiceResult(
      data: [station],
      source: ServiceSource.cache,
      fetchedAt: DateTime.now(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// Minimal [StorageRepository] stub so `_buildCorridorServiceMap` can read
/// `hasApiKey()` without standing up Hive. FR + ES are keyless so the
/// value doesn't gate them; it only matters for the DE/CL/KR demo guard.
class _NoKeyStorage implements StorageRepository {
  @override
  bool hasApiKey() => false;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

void main() {
  test(
      'cross-border FR→ES route queries each leg with its own service + '
      'profile fuel and merges both into one corridor result (#2595)',
      () async {
    // Corridor: Pézenas (FR) heading south-west into Spain. The lower
    // vertices fall in ES-only bbox territory, so corridorCountries
    // returns {FR, ES}. Sample points sit on the polyline.
    const frPoint = LatLng(43.46, 3.42); // Pézenas — FR bbox
    const esPoint = LatLng(40.50, 0.50); // Castelló-ish — ES-only bbox
    const route = RouteInfo(
      geometry: [
        frPoint,
        LatLng(42.40, 2.20), // Pyrenees crossing
        esPoint,
      ],
      distanceKm: 400,
      durationMinutes: 240,
      samplePoints: [frPoint, esPoint],
    );

    final frService = _BrandedStationService('Total FR');
    final esService = _BrandedStationService('Repsol ES');

    final container = ProviderContainer(
      overrides: [
        storageRepositoryProvider.overrideWith((ref) => _NoKeyStorage()),
        // The documented #753 seam — override the per-country family so the
        // corridor map resolves to our branded fakes.
        perCountryStationServiceProvider('FR')
            .overrideWith((ref) => frService),
        perCountryStationServiceProvider('ES')
            .overrideWith((ref) => esService),
        // FR profile uses E85, ES profile uses E10 — the per-country fuel
        // the issue calls out (E85 availability differs by country).
        allProfilesProvider.overrideWith((ref) => const [
              UserProfile(
                  id: 'fr', name: 'Standard',
                  countryCode: 'FR', preferredFuelType: FuelType.e85),
              UserProfile(
                  id: 'es', name: 'Espagne',
                  countryCode: 'ES', preferredFuelType: FuelType.e10),
            ]),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(routeSearchStateProvider.notifier);
    // The active search fuel is FR's E85; the ES leg must NOT inherit it.
    final result = await notifier.searchAlongPrebuiltRouteForTest(
      route: route,
      fuelType: FuelType.e85,
    );

    final brands = result.stations
        .whereType<FuelStationResult>()
        .map((r) => r.station.brand)
        .toSet();

    // Both legs present — the Spanish leg is no longer empty.
    expect(brands, contains('Total FR'),
        reason: 'French leg must be present');
    expect(brands, contains('Repsol ES'),
        reason: 'Spanish leg must be present (was empty before #2595)');

    // Each country's service was queried with ITS profile fuel, not the
    // single active fuel.
    expect(frService.requestedFuels, everyElement(FuelType.e85),
        reason: 'FR leg queried with FR profile fuel E85');
    expect(esService.requestedFuels, everyElement(FuelType.e10),
        reason: 'ES leg queried with ES profile fuel E10 (not E85)');

    // The ES station is priced for E10 (it has no E85 grade), proving the
    // per-country-fuel pricing rather than the single active fuel.
    final esStation = result.stations
        .whereType<FuelStationResult>()
        .firstWhere((r) => r.station.brand == 'Repsol ES');
    expect(esStation.station.e10, isNotNull);
    expect(esStation.station.e85, isNull);

    // Merged result is sorted by corridor position: the FR station (near
    // the start) precedes the ES station (near the end).
    final ordered = result.stations
        .whereType<FuelStationResult>()
        .map((r) => r.station.brand)
        .toList();
    expect(ordered.indexOf('Total FR'),
        lessThan(ordered.lastIndexOf('Repsol ES')),
        reason: 'FR + ES stops interleave by true corridor position');
  });

  test('corridorCountries detects every crossed country offline (#2595)',
      () {
    const route = RouteInfo(
      geometry: [
        LatLng(43.46, 3.42), // FR
        LatLng(42.40, 2.20), // FR (Pyrenees)
        LatLng(40.50, 0.50), // ES
        LatLng(39.50, -0.40), // ES
      ],
      distanceKm: 500,
      durationMinutes: 300,
      samplePoints: [],
    );
    expect(corridorCountries(route), containsAll(<String>{'FR', 'ES'}));
  });
}
