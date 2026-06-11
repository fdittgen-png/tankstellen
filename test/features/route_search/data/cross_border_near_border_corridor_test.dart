// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/services/fuel_service_policy.dart';
import 'package:tankstellen/core/services/service_providers.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service_chain.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/core/utils/station_extensions.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/route_search/data/cross_border_corridor.dart';
import 'package:tankstellen/features/route_search/data/strategies/route_geometry.dart';
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';
import 'package:tankstellen/features/route_search/providers/route_search_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/station_services/france/prix_carburants_station_service.dart';
import 'package:tankstellen/features/station_services/spain/miteco_station_service.dart';

/// #2741 — the catastrophic near-border regression. In "search along route"
/// mode a route Pézenas→Perpignan or Pézenas→Paris (BOTH endpoints in FRANCE)
/// with an FR-ONLY profile showed SPANISH stations (or zero stations).
///
/// Root cause: FR's bounding box over-extends ~165 km south of the Pyrenees
/// and ES's symmetrically north, so EVERY vertex of a purely-French southern
/// route sits inside BOTH boxes. The un-gated `corridorCountries` union then
/// returned {FR, ES}, the corridor queried a full Spanish MITECO leg with no
/// ES profile (spurious Spanish stations) and that heavy uncached leg starved
/// the shared query budget so the FR legs timed out → silent "Aucune station".
///
/// The maintainer's binding rule: query a country IF AND ONLY IF (a) the route
/// GENUINELY enters it AND (b) the user has a profile for it. French-only
/// profile ⇒ French data only, ALWAYS — even on a route that crosses into
/// Spain. Cross-border FR→ES shows BOTH only when profiles for BOTH exist.
///
/// REUSE-FIDELITY (HARD rule — the bug class survived 3 fixes via fakes):
/// drives the REAL `PrixCarburantsStationService` + REAL `MitecoStationService`
/// against RECORDED real-API fixtures (genuine keys / decimals / nulls), the
/// REAL production ES `StationServiceChain`, REAL `corridorCountries` geometry,
/// and the real `searchAlongPrebuiltRouteForTest` corridor build. NO
/// request-echoing fakes that would hide the data-shape bug.

// ---------------------------------------------------------------------------
// Test doubles — the SAME minimal Hive/cache stubs the #2641 reuse-fidelity
// test uses, never echoing the request.
// ---------------------------------------------------------------------------

/// FR + ES are keyless, so `hasApiKey()` does not gate them.
class _NoKeyStorage implements StorageRepository {
  @override
  bool hasApiKey() => false;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// In-memory [CacheStrategy] so the production ES [StationServiceChain] stands
/// up without Hive — the bulkFile policy answers nearby straight from the
/// primary, so this is a near no-op store.
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
/// `buildService` does (bulkFile model, 6 h / 24 h TTLs).
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

/// Serves the recorded REAL Prix-Carburants A9-corridor fixture for geo queries
/// near the corridor, and an empty (but valid) envelope for queries far from it
/// — mirroring the live API, which has NO French stations south of the Pyrenees
/// in Catalonia (the recorded stations are all around Perpignan, lat ~42.6–42.8).
///
/// This faithfulness matters: the shared `filterByRadius` helper returns the
/// NEAREST 20 stations as a fallback when none fall inside the radius, so an
/// adapter that echoed the Perpignan fixture for a Barcelona query would inject
/// 20 Perpignan stations (priced for E10) onto a Catalonia sample point,
/// out-ranking the E10-null real Spanish rows and masking the ES leg. The live
/// API returns an empty list there, so the fixture must too. The fixture body
/// is replayed verbatim otherwise — real keys, real decimals, real nulls.
/// Counts the calls so the test can prove FR WAS queried. Never hits network.
class _PrixCarburantsFixtureAdapter implements HttpClientAdapter {
  _PrixCarburantsFixtureAdapter(this._body);

  final String _body;
  int calls = 0;

  static final _emptyBody =
      jsonEncode({'total_count': 0, 'results': const <dynamic>[]});

  // The recorded A9 stations cluster around Perpignan (lat ~42.6–42.8); the
  // live feed has none south of ~42.4. Parse the query point out of the
  // `within_distance(geom,geom'POINT(lng lat)',…)` ODSQL `where` clause and
  // serve the fixture ONLY for genuinely-French corridor points.
  static final _pointRe =
      RegExp(r'POINT\(\s*(-?[\d.]+)\s+(-?[\d.]+)\s*\)');

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    calls++;
    final where = options.uri.queryParameters['where'] ?? '';
    final m = _pointRe.firstMatch(where);
    final lat = m == null ? null : double.tryParse(m.group(2)!);
    // North of the Pyrenees foothills → real French data; otherwise empty,
    // as the live API returns no FR stations inside Spain.
    final body = (lat != null && lat >= 42.4) ? _body : _emptyBody;
    return ResponseBody.fromBytes(utf8.encode(body), 200, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

/// Serves the recorded REAL MITECO province fixtures: Girona (17) and
/// Barcelona (08), and an empty `OK` list for any other province id — so a
/// genuine-crossing Catalonia route drives the REAL [MitecoStationService]
/// parse against the live field split (`Precio Gasolina 95 E5` populated,
/// `Precio Gasolina 95 E10` EMPTY — Spain sells E5, not E10). Counts the calls
/// so a test can prove ES was NEVER queried for an FR-only profile. Never hits
/// network.
class _MitecoFixtureAdapter implements HttpClientAdapter {
  _MitecoFixtureAdapter({required this.girona17, required this.barcelona08});

  final String girona17;
  final String barcelona08;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    calls++;
    final id = options.uri.path.split('/').last; // …/FiltroProvincia/<id>
    final body = id == '17'
        ? girona17
        : id == '08'
            ? barcelona08
            : jsonEncode(
                {'ResultadoConsulta': 'OK', 'ListaEESSPrecio': const <dynamic>[]});
    return ResponseBody.fromBytes(utf8.encode(body), 200, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

// ---------------------------------------------------------------------------
// REAL OSRM-shaped geometries.
// ---------------------------------------------------------------------------

/// Pézenas → Perpignan: a purely-French A9 corridor. Southernmost vertex
/// lat 42.6973 — 1.70° north of ES's exclusive southern edge (FR.minLat 41.0),
/// so it is NOT a genuine entry into Spain. EVERY vertex sits inside BOTH the
/// FR and ES boxes (the over-generous border overlap), which is exactly what
/// made master return {FR, ES}.
const _perpignanRoute = RouteInfo(
  geometry: [
    LatLng(43.4600, 3.4200), // Pézenas
    LatLng(43.2100, 3.2200), // Béziers
    LatLng(43.1800, 3.0040), // Narbonne
    LatLng(42.9800, 2.9000), // Leucate
    LatLng(42.8000, 2.9100), // Rivesaltes
    LatLng(42.6973, 2.8954), // Perpignan — southernmost, still FR
  ],
  distanceKm: 100,
  durationMinutes: 70,
  samplePoints: [
    LatLng(43.4600, 3.4200),
    LatLng(43.2100, 3.2200),
    LatLng(43.1800, 3.0040),
    LatLng(42.9800, 2.9000),
    LatLng(42.8000, 2.9100),
    LatLng(42.6973, 2.8954),
  ],
);

/// Perpignan → Paris: a long purely-French route. Its southern end sits in the
/// FR/ES overlap band (Perpignan lat 42.6973 — the same near-border start the
/// field bug reported), the rest is unambiguously FR. Anchored at Perpignan so
/// a sample point coincides with the recorded A9 fixture stations and the FR
/// leg is non-empty, while the northern reach proves the route is all-French.
const _parisRoute = RouteInfo(
  geometry: [
    LatLng(42.6973, 2.8954), // Perpignan — near-border start
    LatLng(43.6100, 3.8800), // Montpellier
    LatLng(44.5000, 3.5000), // Massif Central
    LatLng(45.7600, 4.8300), // Lyon
    LatLng(47.3200, 5.0400), // Dijon
    LatLng(48.8566, 2.3522), // Paris
  ],
  distanceKm: 850,
  durationMinutes: 510,
  samplePoints: [
    LatLng(42.6973, 2.8954),
    LatLng(43.6100, 3.8800),
    LatLng(44.5000, 3.5000),
    LatLng(45.7600, 4.8300),
    LatLng(47.3200, 5.0400),
    LatLng(48.8566, 2.3522),
  ],
);

/// Pézenas → Barcelona: a GENUINE cross-border route. It penetrates Catalonia —
/// Girona (41.98) is 0.98° and Barcelona (41.39) 0.39° north of ES's exclusive
/// southern edge, both within the 1.0° genuine-entry margin — so ES IS credited.
const _barcelonaRoute = RouteInfo(
  geometry: [
    LatLng(43.4600, 3.4200), // Pézenas — FR
    LatLng(42.8000, 2.9100), // Rivesaltes — FR
    LatLng(42.4000, 2.2000), // Pyrenees crossing
    LatLng(41.9794, 2.8214), // Girona — Catalonia (ES, province 17)
    LatLng(41.6800, 2.4800), // Maçanet
    LatLng(41.3900, 2.1700), // Barcelona — Catalonia (ES, province 08)
  ],
  distanceKm: 350,
  durationMinutes: 220,
  samplePoints: [
    LatLng(43.4600, 3.4200),
    LatLng(42.8000, 2.9100),
    LatLng(42.4000, 2.2000),
    LatLng(41.9794, 2.8214),
    LatLng(41.6800, 2.4800),
    LatLng(41.3900, 2.1700),
  ],
);

/// Builds a [ProviderContainer] wiring the REAL FR + ES services to the
/// recorded fixtures, with the supplied [profiles]. [esAdapter] is shared so a
/// test can read its call count (the regression: ES queried with no ES profile).
ProviderContainer _container({
  required List<UserProfile> profiles,
  required _PrixCarburantsFixtureAdapter frAdapter,
  required _MitecoFixtureAdapter esAdapter,
}) {
  // REAL FR service: a genuine PrixCarburantsStationService whose Dio adapter
  // returns the recorded A9 fixture (no enricher → keeps the address-heuristic
  // brand, no network). baseUrl '' so the adapter intercepts every request.
  final frDio = Dio(BaseOptions(baseUrl: ''))..httpClientAdapter = frAdapter;
  final frService =
      PrixCarburantsStationService(dio: frDio, enricher: null, baseUrl: '');

  // REAL ES service: a genuine MitecoStationService whose Dio adapter serves
  // the recorded Girona/Barcelona fixtures, wrapped in the production
  // StationServiceChain exactly as `_createMiteco` → `buildService` builds it.
  final esDio = Dio()..httpClientAdapter = esAdapter;
  final esChain = StationServiceChain(
    MitecoStationService(dio: esDio),
    _MemoryCache(),
    errorSource: ServiceSource.mitecoApi,
    countryCode: 'ES',
    policy: _esBulkPolicy,
  );

  return ProviderContainer(
    overrides: [
      storageRepositoryProvider.overrideWith((ref) => _NoKeyStorage()),
      perCountryStationServiceProvider('FR').overrideWith((ref) => frService),
      perCountryStationServiceProvider('ES').overrideWith((ref) => esChain),
      allProfilesProvider.overrideWith((ref) => profiles),
    ],
  );
}

const _frProfile = UserProfile(
  id: 'fr',
  name: 'Standard',
  countryCode: 'FR',
  preferredFuelType: FuelType.e10,
);
const _esProfile = UserProfile(
  id: 'es',
  name: 'España',
  countryCode: 'ES',
  preferredFuelType: FuelType.e5,
);

Set<String> _attributedCountries(List<SearchResultItem> stations) => stations
    .whereType<FuelStationResult>()
    .map((r) => r.station.id.startsWith('es-')
        ? 'ES'
        : r.station.id.startsWith('fr-')
            ? 'FR'
            : '??')
    .toSet();

void main() {
  late String frFixture;
  late String gironaFixture;
  late String barcelonaFixture;

  setUpAll(() {
    frFixture =
        File('test/fixtures/prix_carburants_a9_corridor.json').readAsStringSync();
    gironaFixture =
        File('test/fixtures/miteco_girona_17.json').readAsStringSync();
    barcelonaFixture =
        File('test/fixtures/miteco_barcelona_08.json').readAsStringSync();
  });

  // ── Assertion 1 — Perpignan, FR-only profile ─────────────────────────────
  // The reported field route. RED on master: `corridorCountries` returns
  // {FR, ES} and the corridor queries ES.
  test(
      'Perpignan (FR route, FR-only profile): corridor == {FR}, ES never '
      'queried, results non-empty and FR-only (#2741)', () async {
    // The geometric gate is profile-independent — assert it directly.
    expect(corridorCountries(_perpignanRoute), <String>{'FR'},
        reason: 'a purely-French Perpignan route must NOT credit ES — every '
            'vertex is in both boxes but none genuinely enters Spain (#2741)');

    final frAdapter = _PrixCarburantsFixtureAdapter(frFixture);
    final esAdapter = _MitecoFixtureAdapter(
        girona17: gironaFixture, barcelona08: barcelonaFixture);
    final container = _container(
      profiles: const [_frProfile],
      frAdapter: frAdapter,
      esAdapter: esAdapter,
    );
    addTearDown(container.dispose);

    final notifier = container.read(routeSearchStateProvider.notifier);
    final result = await notifier.searchAlongPrebuiltRouteForTest(
      route: _perpignanRoute,
      fuelType: FuelType.e10,
    );

    expect(result.corridorCountryCodes, <String>{'FR'},
        reason: 'FR-only profile ⇒ French data only (#2741)');
    expect(esAdapter.calls, 0,
        reason: 'the ES MITECO source must NEVER be queried for an FR-only '
            'profile (RED on master: it WAS, leaking Spanish stations) (#2741)');
    expect(frAdapter.calls, greaterThan(0),
        reason: 'the FR source must be queried');

    final stations = result.stations.whereType<FuelStationResult>().toList();
    expect(stations, isNotEmpty,
        reason: 'a French A9 corridor must return French stations, never the '
            'silent "Aucune station trouvée" zero (#2741)');
    expect(_attributedCountries(result.stations), <String>{'FR'},
        reason: 'every station must be FR-attributed (id `fr-…`)');
  });

  // ── Assertion 2 — Paris, FR-only profile ─────────────────────────────────
  test(
      'Paris (FR route, FR-only profile): corridor == {FR}, ES never queried, '
      'non-empty FR results (#2741)', () async {
    expect(corridorCountries(_parisRoute), <String>{'FR'},
        reason: 'a Pézenas→Paris route is entirely French (#2741)');

    final frAdapter = _PrixCarburantsFixtureAdapter(frFixture);
    final esAdapter = _MitecoFixtureAdapter(
        girona17: gironaFixture, barcelona08: barcelonaFixture);
    final container = _container(
      profiles: const [_frProfile],
      frAdapter: frAdapter,
      esAdapter: esAdapter,
    );
    addTearDown(container.dispose);

    final notifier = container.read(routeSearchStateProvider.notifier);
    final result = await notifier.searchAlongPrebuiltRouteForTest(
      route: _parisRoute,
      fuelType: FuelType.e10,
    );

    expect(result.corridorCountryCodes, <String>{'FR'});
    expect(esAdapter.calls, 0,
        reason: 'ES must never be queried on a French route (#2741)');
    expect(result.stations.whereType<FuelStationResult>(), isNotEmpty);
    expect(_attributedCountries(result.stations), <String>{'FR'});
  });

  // ── Assertion 3 — Barcelona, FR+ES profiles ──────────────────────────────
  // No-regression on the LEGITIMATE cross-border case (#2595/#2641).
  test(
      'Barcelona (cross-border, FR+ES profiles): corridor ⊇ {FR, ES}, ≥1 ES '
      'station priced via the E5 fallback (#2741 keeps #2595/#2641)', () async {
    expect(corridorCountries(_barcelonaRoute), containsAll(<String>{'FR', 'ES'}),
        reason: 'a genuine Catalonia crossing (Girona 41.98 / Barcelona 41.39 '
            'are within the 1.0° genuine-entry margin) must credit ES (#2741)');

    final frAdapter = _PrixCarburantsFixtureAdapter(frFixture);
    final esAdapter = _MitecoFixtureAdapter(
        girona17: gironaFixture, barcelona08: barcelonaFixture);
    final container = _container(
      profiles: const [_frProfile, _esProfile],
      frAdapter: frAdapter,
      esAdapter: esAdapter,
    );
    addTearDown(container.dispose);

    final notifier = container.read(routeSearchStateProvider.notifier);
    final result = await notifier.searchAlongPrebuiltRouteForTest(
      route: _barcelonaRoute,
      fuelType: FuelType.e10, // active FR fuel; the ES leg uses ES profile E5.
    );

    expect(result.corridorCountryCodes, containsAll(<String>{'FR', 'ES'}),
        reason: 'both profiles present + both genuinely entered ⇒ both queried');
    expect(esAdapter.calls, greaterThan(0),
        reason: 'the ES MITECO source must be queried on a genuine crossing');

    final esStations = result.stations
        .whereType<FuelStationResult>()
        .where((r) => r.station.id.startsWith('es-'))
        .toList();
    expect(esStations, isNotEmpty,
        reason: 'real MITECO rows must arrive on the genuine crossing (#2595)');
    // The real Girona/Barcelona rows: E5 priced, E10 EMPTY (Spain sells E5).
    final priced = esStations.where((r) {
      final fuel = fuelForStation(
          r.station, result.profileFuelByCountry, FuelType.e10);
      return r.station.priceFor(fuel) != null;
    });
    expect(priced, isNotEmpty,
        reason: 'an ES station must be priced via the #2641 E5↔E10 sibling '
            'fallback (ES profile E5 → E5 price), not shown as "--"');
  });

  // ── Assertion 4 — Barcelona, FR-ONLY profile ─────────────────────────────
  // The maintainer's "both ONLY if both profiles" rule: ES is SUPPRESSED on a
  // genuine crossing because the user has no ES profile.
  test(
      'Barcelona (cross-border, FR-ONLY profile): corridor == {FR}, ES never '
      'queried, FR-only results — the profile rule (#2741)', () async {
    // Geometry alone DOES genuinely enter ES …
    expect(corridorCountries(_barcelonaRoute), containsAll(<String>{'FR', 'ES'}),
        reason: 'geometric gate still credits the genuine crossing');

    final frAdapter = _PrixCarburantsFixtureAdapter(frFixture);
    final esAdapter = _MitecoFixtureAdapter(
        girona17: gironaFixture, barcelona08: barcelonaFixture);
    // … but with NO ES profile the corridor must still query FR only.
    final container = _container(
      profiles: const [_frProfile],
      frAdapter: frAdapter,
      esAdapter: esAdapter,
    );
    addTearDown(container.dispose);

    final notifier = container.read(routeSearchStateProvider.notifier);
    final result = await notifier.searchAlongPrebuiltRouteForTest(
      route: _barcelonaRoute,
      fuelType: FuelType.e10,
    );

    expect(result.corridorCountryCodes, <String>{'FR'},
        reason: 'no ES profile ⇒ ES suppressed despite genuine entry — both '
            'ONLY if both profiles exist (#2741)');
    expect(esAdapter.calls, 0,
        reason: 'the ES source must NOT be queried without an ES profile '
            '(RED on master: it WAS) (#2741)');
    expect(_attributedCountries(result.stations), <String>{'FR'},
        reason: 'FR-only profile ⇒ French data only, even on a route that '
            'crosses into Spain (#2741)');
  });
}
