// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/services/fuel_service_policy.dart';
import 'package:tankstellen/core/services/service_providers.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/services/station_service_chain.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/core/utils/station_extensions.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/route_search/data/cross_border_corridor.dart';
import 'package:tankstellen/features/route_search/data/strategies/route_geometry.dart';
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';
import 'package:tankstellen/features/route_search/providers/route_search_provider.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/station_services/spain/miteco_station_service.dart';

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

/// #2631 — a [StationService] that only returns a station when the queried
/// point is INSIDE [minLat]..[maxLat], mirroring a real country source that
/// has NO coverage abroad (FR Prix-Carburants returns nothing in Spain).
/// The corridor query function queries every country service at every
/// sample point, so without this gating a 1.20-priced FR station would be
/// returned next to Barcelona and win every segment — masking the bug.
/// Returns a station priced ONLY for the requested fuel (ES → e10 set, e85
/// null), so the per-country-fuel ranking is what the test exercises.
class _RegionGatedStationService implements StationService {
  _RegionGatedStationService(
    this.brand, {
    required this.idPrefix,
    required this.minLat,
    required this.maxLat,
    required this.price,
  });

  final String brand;
  // #753 — real country services prefix their station ids (`es-`, `fr-`)
  // so a Catalonian station inside FR's bbox is still attributed to ES by
  // `Countries.countryForStation` / `fuelForStation` (#2631).
  final String idPrefix;
  final double minLat;
  final double maxLat;
  final double price;

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    if (params.lat < minLat || params.lat > maxLat) {
      return ServiceResult(
        data: const [],
        source: ServiceSource.cache,
        fetchedAt: DateTime.now(),
      );
    }
    final station = Station(
      id: '$idPrefix${params.lat.toStringAsFixed(2)}-${params.lng.toStringAsFixed(2)}',
      name: '$brand station',
      brand: brand,
      street: 'Route',
      postCode: '00000',
      place: brand,
      lat: params.lat,
      lng: params.lng,
      isOpen: true,
      // Price only the requested fuel — an ES station has e10 set, e85 null,
      // so pricing it by the active E85 yields '--' (the bug) until the
      // per-country fuel (E10) is applied.
      e85: params.fuelType == FuelType.e85 ? price : null,
      e10: params.fuelType == FuelType.e10 ? price : null,
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

/// #2641 — serves the recorded REAL geoportalgasolineras province-08 fixture
/// for `…/FiltroProvincia/08`, and an empty (but `OK`) list for any other
/// province id, so a Barcelona search drives the REAL [MitecoStationService]
/// parse against the live field split (`Precio Gasolina 95 E5` populated,
/// `Precio Gasolina 95 E10` EMPTY — Spain sells E5, not E10). NEVER hits the
/// network.
class _MitecoFixtureAdapter implements HttpClientAdapter {
  _MitecoFixtureAdapter(this._province08Body);

  final String _province08Body;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    final id = options.uri.path.split('/').last; // …/FiltroProvincia/<id>
    final body = id == '08'
        ? _province08Body
        : jsonEncode(
            {'ResultadoConsulta': 'OK', 'ListaEESSPrecio': const <dynamic>[]});
    return ResponseBody.fromBytes(utf8.encode(body), 200, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

/// In-memory [CacheStrategy] so the production ES [StationServiceChain] can be
/// stood up without Hive (#2641). The chain's bulkFile policy answers nearby
/// straight from the primary, so this is essentially a no-op store.
class _MemoryCache implements CacheStrategy {
  final Map<String, CacheEntry> _store = {};

  @override
  Future<void> put(String key, Map<String, dynamic> data,
      {required Duration ttl, required ServiceSource source}) async {
    _store[key] = CacheEntry(
        payload: data, storedAt: DateTime.now(), originalSource: source, ttl: ttl);
  }

  @override
  CacheEntry? get(String key) => _store[key];

  @override
  CacheEntry? getFresh(String key) {
    final e = _store[key];
    if (e == null || e.isExpired) return null;
    return e;
  }
}

/// Mirrors `_esPolicy` in country_service_registry.dart so the test wraps the
/// real MITECO service exactly as production's `_createMiteco` →
/// `buildService` does (bulkFile model, 6 h/24 h TTLs).
const _esBulkPolicy = FuelServicePolicy(
  model: SourceModel.bulkFile,
  minInterval: Duration(minutes: 30),
  datasetTtlSoft: Duration(hours: 6),
  datasetTtlHard: Duration(hours: 24),
  searchResultTtl: Duration.zero,
  attribution: 'Geoportal Gasolineras (MITECO)',
  license: 'Open data (MITECO)',
  sourceUrl: 'https://geoportalgasolineras.es/',
);

void main() {
  test(
      'cross-border FR→ES route queries each leg with its own service + '
      'profile fuel and merges both into one corridor result (#2595)',
      () async {
    // Corridor: Pézenas (FR) → Barcelona (ES) — the EXACT route from the
    // bug report. #2621 — the Catalonian sample point (Barcelona, 41.39)
    // sits INSIDE FR's bbox (lat 41.0–51.5), so the first-match
    // `entryByLatLng` resolved it to FR and the whole Spanish leg was
    // silently dropped. Using a real sub-Pyrenees Spanish point (not the
    // earlier hand-picked lat<41.0 one) exercises the production shadow.
    const frPoint = LatLng(43.46, 3.42); // Pézenas — FR bbox
    const esPoint = LatLng(41.39, 2.17); // Barcelona — INSIDE FR's box too
    const route = RouteInfo(
      geometry: [
        frPoint,
        LatLng(42.40, 2.20), // Pyrenees crossing
        LatLng(41.98, 2.82), // Girona — Catalonia (ES), INSIDE FR's box
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

    // #2622 — the result carries the queried corridor country codes so the
    // header can credit BOTH data sources, not just the active country.
    expect(result.corridorCountryCodes, containsAll(<String>{'FR', 'ES'}),
        reason: 'corridorCountryCodes must surface every queried country');

    // #2621 — the ES service must ACTUALLY have been queried. An empty
    // `everyElement` matcher passes vacuously, so assert the call happened
    // (the regression: ES was never queried because FR shadowed it).
    expect(esService.requestedFuels, isNotEmpty,
        reason: 'ES service must be queried for a Barcelona corridor (#2621)');

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

  // #2621 — REAL Catalonian vertices. The previous version of this test
  // hand-picked ES points at lat 40.50 / 39.50, BELOW FR's minLat (41.0),
  // so they fell outside the FR box and were attributed to ES even by the
  // first-match `entryByLatLng`. A genuine Pézenas→Barcelona route never
  // drops below 41.0 — Girona (41.98) and Barcelona (41.39) both sit INSIDE
  // the FR box (lat 41.0–51.5, lng −5.5–10.0), so first-match resolves them
  // to FR and the whole Spanish leg was silently dropped. With real coords
  // this test exercises the actual bbox shadow.
  test('corridorCountries detects every crossed country offline (#2595/#2621)',
      () {
    const route = RouteInfo(
      geometry: [
        LatLng(43.46, 3.42), // Pézenas — FR
        LatLng(42.40, 2.20), // Pyrenees crossing — FR
        LatLng(41.98, 2.82), // Girona — Catalonia (ES), INSIDE FR's box
        LatLng(41.39, 2.17), // Barcelona — Catalonia (ES), INSIDE FR's box
      ],
      distanceKm: 500,
      durationMinutes: 300,
      samplePoints: [],
    );
    expect(corridorCountries(route), containsAll(<String>{'FR', 'ES'}),
        reason: 'ES must be detected even though FR shadows every '
            'Catalonian point in first-match bbox order (#2621)');
  });

  // #2631 — THE regression. A cross-border Best Stops result must include
  // the Spanish leg's cheapest station. Before the fix, `computeBestStops`
  // (and the 4 strategies) priced EVERY station by the single active fuel
  // (FR E85). A real ES station has e10 set / e85 null, so `priceFor(E85)`
  // is null → the station is skipped from per-segment ranking → zero
  // Spanish best stops. With the per-country fuel threaded through, the ES
  // station is priced on E10 and wins its own segment.
  test(
      'cross-border Best Stops include the cheapest Spanish station, '
      'priced by ES profile fuel E10 (#2631)', () async {
    // 4 FR sample points (lat ≥ 42 → segment 0) + 1 ES point at Barcelona
    // (sample index 4 → segment 1 under the 50 km test-seam spacing:
    // (4 * 15 / 50).floor() == 1). Region-gated services mean only FR
    // answers in France and only ES answers in Spain — so segment 1's sole
    // candidate is the Spanish station.
    const frA = LatLng(43.50, 3.50);
    const frB = LatLng(43.30, 3.30);
    const frC = LatLng(43.10, 3.10);
    const frD = LatLng(42.90, 2.90);
    const esBarcelona = LatLng(41.39, 2.17);
    const route = RouteInfo(
      geometry: [frA, frB, frC, frD, LatLng(42.10, 2.40), esBarcelona],
      distanceKm: 400,
      durationMinutes: 240,
      samplePoints: [frA, frB, frC, frD, esBarcelona],
    );

    // FR sells (gated to lat ≥ 42) at E85 1.20; ES sells (gated to lat ≤ 42)
    // at E10 1.60 with no E85 grade — the exact shape that produced '--'.
    // The `es-` prefix is what lets `fuelForStation` attribute the Barcelona
    // station to ES even though it sits inside FR's continental bbox (#2631).
    final frService = _RegionGatedStationService('Total FR',
        idPrefix: 'fr-', minLat: 42.0, maxLat: 90.0, price: 1.20);
    final esService = _RegionGatedStationService('Repsol ES',
        idPrefix: 'es-', minLat: -90.0, maxLat: 42.0, price: 1.60);

    final container = ProviderContainer(
      overrides: [
        storageRepositoryProvider.overrideWith((ref) => _NoKeyStorage()),
        perCountryStationServiceProvider('FR')
            .overrideWith((ref) => frService),
        perCountryStationServiceProvider('ES')
            .overrideWith((ref) => esService),
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
    final result = await notifier.searchAlongPrebuiltRouteForTest(
      route: route,
      fuelType: FuelType.e85, // active fuel is FR's E85.
    );

    final esStation = result.stations
        .whereType<FuelStationResult>()
        .firstWhere((r) => r.station.brand == 'Repsol ES');

    // The ES station models a real MITECO row: E10 priced, E85 null.
    expect(esStation.station.e10, isNotNull);
    expect(esStation.station.e85, isNull);

    // THE assertion: the Spanish station is in Best Stops. On master this
    // is absent (the E85-priced ranking skipped it).
    expect(result.cheapestPerSegment, isNotNull);
    expect(result.cheapestPerSegment!.values, contains(esStation.station.id),
        reason: 'the cheapest Spanish station must appear in Best Stops, '
            'priced by ES profile fuel E10 (#2631)');

    // #2631 — and the result carries the per-country fuel map so the
    // map/list display can price each station the same way.
    expect(result.profileFuelByCountry['ES'], FuelType.e10);
  });

  // #2631 — the reused resolver: an ES station priced for E10 is non-null
  // once `fuelForStation` selects E10 from the ES profile, even though the
  // active search fuel (E85) is null on it. This is the one-line proof that
  // the per-country selection — not a within-country fallback — is what
  // surfaces the price.
  test('fuelForStation selects the ES profile fuel and yields a price (#2631)',
      () {
    // Barcelona (41.39) sits INSIDE FR's continental bbox; the `es-` id
    // prefix (#753) is what attributes it to ES rather than FR.
    const esStation = Station(
      id: 'es-1',
      name: 'Repsol',
      brand: 'Repsol',
      street: 'Calle',
      postCode: '08001',
      place: 'Barcelona',
      lat: 41.39,
      lng: 2.17,
      e10: 1.60, // E10 priced…
      isOpen: true,
    );
    final fuel = fuelForStation(
      esStation,
      const {'ES': FuelType.e10},
      FuelType.e85, // …while the active fuel is E85.
    );
    expect(fuel, FuelType.e10, reason: 'ES profile fuel wins over the active');
    expect(esStation.priceFor(fuel), isNotNull,
        reason: 'priced on E10, so it is no longer dropped as "--"');
    // And the active-fuel path (the bug) is null → the "--" on master.
    expect(esStation.priceFor(FuelType.e85), isNull);
  });

  // #2641 — THE faithful reproduction. The prior tests prove the per-country
  // selection mechanics with a FAKE ES station that carries whatever fuel was
  // requested (so querying ES with E10 always returned an E10 price). The
  // REAL world is the opposite: Spain sells "Gasolina 95 E5", NOT E10 —
  // 769/798 province-08 stations carry E5, exactly 1 carries E10. So the ES
  // profile grade (Super-E10) prices a real Spanish station as null → the
  // station is dropped from Best Stops / never cheapest / shows '--'. This
  // drives the REAL MitecoStationService (injected Dio, fixture parse) through
  // the REAL production ES StationServiceChain + the real corridor build, and
  // asserts the displayed price + Best-Stops membership. RED on master (no
  // E5↔E10 sibling fallback), GREEN on the fix.
  test(
      'cross-border ES leg from the REAL MITECO fixture (E5 only, no E10) is '
      'priced + enters Best Stops via the E5↔E10 sibling fallback (#2641)',
      () async {
    final fixture = File(
            'test/fixtures/miteco_barcelona_08.json')
        .readAsStringSync();

    // Pézenas (FR) → Barcelona (ES) — the bug-report corridor. 4 FR sample
    // points (lat ≥ 42 → segment 0) + Barcelona at sample index 4 → segment 1
    // ((4 * 15 / 50).floor() == 1), so the Spanish station ranks in its OWN
    // segment rather than being out-priced by the cheaper FR E85 station in a
    // shared segment 0. The Barcelona point (41.39, 2.17) resolves to province
    // 08 and hits the fixture; FR points stay in France.
    const frA = LatLng(43.50, 3.50);
    const frB = LatLng(43.30, 3.30);
    const frC = LatLng(43.10, 3.10);
    const frD = LatLng(42.90, 2.90);
    const esPoint = LatLng(41.39, 2.17); // Barcelona — INSIDE FR's bbox too
    const route = RouteInfo(
      geometry: [frA, frB, frC, frD, LatLng(42.10, 2.40), esPoint],
      distanceKm: 400,
      durationMinutes: 240,
      samplePoints: [frA, frB, frC, frD, esPoint],
    );

    // The REAL ES service: a genuine MitecoStationService whose Dio adapter
    // returns the recorded fixture, wrapped in the production StationService
    // Chain exactly as `_createMiteco` → `buildService` builds it for ES.
    final mitecoDio = Dio()
      ..httpClientAdapter = _MitecoFixtureAdapter(fixture);
    final realMiteco = MitecoStationService(dio: mitecoDio);
    final esChain = StationServiceChain(
      realMiteco,
      _MemoryCache(),
      errorSource: ServiceSource.mitecoApi,
      countryCode: 'ES',
      policy: _esBulkPolicy,
    );

    // FR is not the focus — a small region-gated fake with an E85 grade so
    // the FR leg is non-empty (and FR stations never bleed into Spain).
    final frService = _RegionGatedStationService('Total FR',
        idPrefix: 'fr-', minLat: 42.0, maxLat: 90.0, price: 1.20);

    final container = ProviderContainer(
      overrides: [
        storageRepositoryProvider.overrideWith((ref) => _NoKeyStorage()),
        perCountryStationServiceProvider('FR')
            .overrideWith((ref) => frService),
        perCountryStationServiceProvider('ES')
            .overrideWith((ref) => esChain),
        // The user's real profiles: FR/E85 active, ES/E10 — and Spain has no
        // E10 in the data, which is the whole bug.
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
    final result = await notifier.searchAlongPrebuiltRouteForTest(
      route: route,
      fuelType: FuelType.e85, // active fuel is FR's E85.
    );

    // (i) The Spanish leg arrives — a real MITECO row (id `es-…`).
    final esStation = result.stations
        .whereType<FuelStationResult>()
        .firstWhere((r) => r.station.id.startsWith('es-'),
            orElse: () => throw StateError('no ES station in corridor result'));

    // The real fixture row models live Spain: E5 priced, E10 EMPTY.
    expect(esStation.station.e5, isNotNull,
        reason: 'fixture E5 must parse (Spain sells E5)');
    expect(esStation.station.e10, isNull,
        reason: 'fixture E10 is empty (Spain does not sell E10)');

    // (ii) The PRODUCTION displayed price — priced via fuelForStation with the
    // ES/E10 profile grade. RED on master: E10 → null → '--'. GREEN on fix:
    // the E5↔E10 sibling fallback yields the E5 price.
    final displayedFuel = fuelForStation(
        esStation.station, result.profileFuelByCountry, FuelType.e85);
    expect(esStation.station.priceFor(displayedFuel), isNotNull,
        reason: 'the ES station must show a price, not "--" (#2641)');

    // (iii) The cheapest Spanish station must enter Best Stops. RED on master:
    // computeBestStops drops the null-E10 station.
    expect(result.cheapestPerSegment, isNotNull);
    expect(result.cheapestPerSegment!.values,
        contains(esStation.station.id),
        reason: 'the cheapest Spanish station must appear in Best Stops, '
            'priced by its E5 grade via the sibling fallback (#2641)');
  });

  // #2680 — THE attribution-banner bug. On a cross-border E85 route the top
  // source-attribution banner credited EVERY country the corridor queried
  // (`corridorCountryCodes` = corridor span), not the countries that actually
  // produced a displayable station. Spain sells NO E85 — every MITECO row's
  // `Precio Bioetanol` is empty (and there is no E85 sibling fallback, unlike
  // E5↔E10) — so an E85 search returns Spanish stations that all show "--".
  // The banner must therefore drop "España — MITECO" and credit France only.
  //
  // Reuse-fidelity (HARD rule, no request-echoing fakes): drives the REAL
  // MitecoStationService + the production ES StationServiceChain against the
  // recorded province-08 fixture (the same seam #2641 uses), so the ES leg's
  // empty-E85 shape is the genuine field data, not a fake that echoes E85.
  // RED on master: `corridorCountryCodes` feeds the banner → {FR, ES}.
  // GREEN: `contributingCountryCodes(E85)` → {FR}, while `corridorCountryCodes`
  // still carries ES (the contributing-vs-corridor distinction).
  test(
      'cross-border E85 banner credits FR only — ES produced no E85 station '
      'so contributingCountryCodes is {FR} while corridorCountryCodes ⊇ {ES} '
      '(#2680)', () async {
    final fixture =
        File('test/fixtures/miteco_barcelona_08.json').readAsStringSync();

    // Pézenas (FR) → Barcelona (ES) — the bug-report corridor. 4 FR sample
    // points (lat ≥ 42) + Barcelona at index 4 hit province 08 → the fixture.
    const frA = LatLng(43.50, 3.50);
    const frB = LatLng(43.30, 3.30);
    const frC = LatLng(43.10, 3.10);
    const frD = LatLng(42.90, 2.90);
    const esPoint = LatLng(41.39, 2.17); // Barcelona — INSIDE FR's bbox too
    const route = RouteInfo(
      geometry: [frA, frB, frC, frD, LatLng(42.10, 2.40), esPoint],
      distanceKm: 400,
      durationMinutes: 240,
      samplePoints: [frA, frB, frC, frD, esPoint],
    );

    // REAL ES service: a genuine MitecoStationService whose Dio adapter serves
    // the recorded fixture, wrapped in the production StationServiceChain as
    // `_createMiteco` → `buildService` builds it for ES.
    final mitecoDio = Dio()
      ..httpClientAdapter = _MitecoFixtureAdapter(fixture);
    final esChain = StationServiceChain(
      MitecoStationService(dio: mitecoDio),
      _MemoryCache(),
      errorSource: ServiceSource.mitecoApi,
      countryCode: 'ES',
      policy: _esBulkPolicy,
    );

    // FR sells E85 (region-gated to lat ≥ 42 so it never bleeds into Spain),
    // so France genuinely contributes a priced E85 station.
    final frService = _RegionGatedStationService('Total FR',
        idPrefix: 'fr-', minLat: 42.0, maxLat: 90.0, price: 1.20);

    final container = ProviderContainer(
      overrides: [
        storageRepositoryProvider.overrideWith((ref) => _NoKeyStorage()),
        perCountryStationServiceProvider('FR')
            .overrideWith((ref) => frService),
        perCountryStationServiceProvider('ES')
            .overrideWith((ref) => esChain),
        // The field case: an E85 driver crossing FR→ES. BOTH profiles use
        // E85 — so the ES leg is queried + priced for E85, which Spain lacks.
        allProfilesProvider.overrideWith((ref) => const [
              UserProfile(
                  id: 'fr', name: 'Standard',
                  countryCode: 'FR', preferredFuelType: FuelType.e85),
              UserProfile(
                  id: 'es', name: 'Espagne',
                  countryCode: 'ES', preferredFuelType: FuelType.e85),
            ]),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(routeSearchStateProvider.notifier);
    final result = await notifier.searchAlongPrebuiltRouteForTest(
      route: route,
      fuelType: FuelType.e85, // active fuel is E85.
    );

    // Sanity: the corridor DID query Spain — real MITECO rows arrived (id
    // `es-…`), they just carry no E85 price. This is what makes the bug real:
    // ES stations ARE in the found set, only unpriced for the chosen fuel.
    final esRows = result.stations
        .whereType<FuelStationResult>()
        .where((r) => r.station.id.startsWith('es-'))
        .toList();
    expect(esRows, isNotEmpty,
        reason: 'real MITECO rows must arrive in the corridor result');
    expect(esRows.every((r) => r.station.e85 == null), isTrue,
        reason: 'Spain sells no E85 — every fixture row Bioetanol is empty');

    // FR genuinely contributed a priced E85 station.
    expect(
        result.stations
            .whereType<FuelStationResult>()
            .any((r) => r.station.brand == 'Total FR'),
        isTrue,
        reason: 'the French leg produced a priced E85 station');

    // THE distinction: the corridor queried BOTH countries…
    expect(result.corridorCountryCodes, containsAll(<String>{'FR', 'ES'}),
        reason: 'corridorCountryCodes records the full queried span (#2622)');

    // …but only France produced a DISPLAYABLE (priced) E85 station, so the
    // attribution banner credits France ONLY. RED on master (no
    // contributingCountryCodes → banner shows both); GREEN after.
    expect(result.contributingCountryCodes(FuelType.e85), <String>{'FR'},
        reason: 'ES produced no E85-priced station → dropped from the banner '
            '(#2680)');
  });
}
