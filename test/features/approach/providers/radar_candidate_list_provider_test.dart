// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/services/approach_detector.dart';
import 'package:tankstellen/core/services/radar/corridor_location_cache.dart';
import 'package:tankstellen/core/services/radar/jit_price_cache.dart';
import 'package:tankstellen/core/services/service_providers.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/approach/providers/effective_approach_state_provider.dart';
import 'package:tankstellen/features/approach/providers/fuel_station_radar_provider.dart';
import 'package:tankstellen/features/approach/providers/radar_candidate_list_provider.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/effective_fuel_type_provider.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

import '../../../helpers/mock_providers.dart';

/// #2664 — the swipe-to-page candidate list routes through the cache-first
/// [FuelStationRadar] at the user's **default radar radius**
/// (`profile.approachRadiusKm`), NOT a hard-coded 10 km, and NOT the search
/// chain directly. It keeps the #2633/#2583 contract: the FULL distance-ranked
/// set filtered to stations carrying a non-null, positive price for the
/// effective fuel, and `const []` for any non-[ApproachPolling] state.

/// Sentinel distinguishing "approach arg not passed" (use the default polling
/// fix) from an explicit `null` override (no GPS fix yet).
const Object _unset = Object();

Position _pos({required double lat, required double lng}) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime(2026, 5, 1, 9),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 12,
      speedAccuracy: 0,
    );

Station _station(
  String id, {
  double? e10,
  double? diesel,
  double lat = 48.0,
  double lng = 2.0,
}) =>
    Station(
      id: id,
      name: 'Station $id',
      brand: 'Brand',
      street: '',
      postCode: '',
      place: '',
      lat: lat,
      lng: lng,
      e10: e10,
      diesel: diesel,
      isOpen: true,
    );

const _profile = UserProfile(
  id: 'p1',
  name: 'Test Driver',
  // Default radar radius — the value the trip detector geofences against.
  approachRadiusKm: 1.5,
  approachMinPollSeconds: 5,
);

/// Active-profile notifier stub returning a fixed profile (or null).
class _FakeActiveProfile extends ActiveProfile {
  final UserProfile? profile;
  _FakeActiveProfile(this.profile);

  @override
  UserProfile? build() => profile;
}

/// [FuelStationRadar] subclass that records the `radiusKm` it was called with,
/// so the test can assert the provider routes through the radar at the
/// DEFAULT radar radius rather than the legacy hard-coded 10 km.
class _CapturingRadar extends FuelStationRadar {
  final List<Station> stations;
  final List<double> radiusCalls = [];

  _CapturingRadar(this.stations)
      : super(
          corridorCache: CorridorLocationCache(
            fetchCorridor: (_, _, _) async => const <Station>[],
          ),
          priceCache: JitPriceCache(fetchPrice: (s) async => s),
          isBulkSource: true,
        );

  @override
  Future<List<Station>> fetchStations(
    double lat,
    double lng,
    double radiusKm,
    String fuelTypeApiValue, {
    double? headingDegrees,
  }) async {
    radiusCalls.add(radiusKm);
    return stations;
  }
}

/// Empty in-radius station service — the default for tests that exercise only
/// the corridor (`_CapturingRadar`) path. The #2965 in-radius merge contributes
/// nothing, so the existing corridor-only assertions stay valid.
class _EmptyService implements StationService {
  const _EmptyService();

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async =>
      ServiceResult(
        data: const <Station>[],
        source: ServiceSource.cache,
        fetchedAt: DateTime(2026),
      );

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String stationId) =>
      throw UnimplementedError();

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) =>
      throw UnimplementedError();
}

ProviderContainer _container({
  required FuelStationRadar radar,
  FuelType fuel = FuelType.e10,
  UserProfile? profile = _profile,
  // `_unset` keeps the default polling fix; pass an explicit value (incl.
  // `null`) to override it — `null` can't be the default or it would be
  // indistinguishable from "not passed".
  Object? approach = _unset,
  // The direct in-radius station service the #2965 superset merge calls.
  // Defaults to an empty service so corridor-only tests are unaffected.
  StationService stationService = const _EmptyService(),
}) {
  final state = identical(approach, _unset)
      ? ApproachPolling(
          gps: _pos(lat: 48.0, lng: 2.0),
          nextPollIn: const Duration(seconds: 5),
        )
      : approach as ApproachState?;
  return ProviderContainer(
    overrides: [
      effectiveApproachStateProvider.overrideWithValue(state),
      effectiveFuelTypeProvider.overrideWithValue(fuel),
      activeProfileProvider.overrideWith(() => _FakeActiveProfile(profile)),
      fuelStationRadarProvider.overrideWithValue(radar),
      stationServiceProvider.overrideWithValue(stationService),
    ],
  );
}

void main() {
  group('cache-first reroute at the default radar radius (#2664)', () {
    test('routes through FuelStationRadar at profile.approachRadiusKm, not 10km',
        () async {
      final radar = _CapturingRadar([_station('A', e10: 1.5)]);
      final container = _container(radar: radar);
      addTearDown(container.dispose);

      await container.read(radarCandidateListProvider.future);

      expect(radar.radiusCalls, [1.5],
          reason: 'fetchStations is called ONCE at the default radar radius '
              '(profile.approachRadiusKm), never the legacy 10 km');
    });

    test(
        'warm corridor tile → zero station-network calls, ≤1 JIT per imminent '
        '(per-poll request budget)', () async {
      var corridorCalls = 0;
      var priceCalls = 0;
      // Real radar + counting fetch closures (the "fake caches"): the corridor
      // is fetched ONCE then cached, and only the imminent station inside the
      // approach radius gets a JIT price.
      final radar = FuelStationRadar(
        isBulkSource: false,
        corridorCache: CorridorLocationCache(
          isBulk: false,
          corridorRadiusKm: 60,
          tileStepDegrees: 0.5,
          fetchCorridor: (lat, lng, r) async {
            corridorCalls++;
            return [
              _station('NEAR', lat: lat, lng: lng, e10: 1.5), // imminent+priced
              _station('FAR', lat: lat + 0.05, lng: lng), // ~5.5 km corridor
            ];
          },
        ),
        priceCache: JitPriceCache(
          fetchPrice: (s) async {
            priceCalls++;
            return s.copyWith(e10: 1.789);
          },
        ),
      );
      final container = _container(radar: radar);
      addTearDown(container.dispose);

      final first = await container.read(radarCandidateListProvider.future);
      // Only the imminent NEAR station is priced; FAR stays location-only and
      // is filtered out of the page-set.
      expect(first.map((s) => s.id), ['NEAR']);
      expect(corridorCalls, 1, reason: '≤1 corridor fetch per poll');
      expect(priceCalls, 1, reason: '≤1 JIT price per imminent station');

      // A second poll at the same spot is a pure cache hit: NO new corridor
      // fetch (warm tile → zero station-network calls), price deduped in TTL.
      container.invalidate(radarCandidateListProvider);
      await container.read(radarCandidateListProvider.future);
      expect(corridorCalls, 1,
          reason: 'warm corridor tile → zero station-network re-query');
      expect(priceCalls, 1, reason: 'JIT price deduped within TTL');
    });
  });

  group('distance-ranked priced page-set preserved (#2633/#2583)', () {
    test('returns the FULL priced set, distance-sorted from the live fix',
        () async {
      // Fed out of distance order and with one unpriced station mixed in.
      final radar = _CapturingRadar([
        _station('FAR_PRICED', lat: 48.03, lng: 2.0, e10: 1.5),
        _station('NEAR_UNPRICED', lat: 48.0, lng: 2.0, diesel: 1.65),
        _station('MID_PRICED', lat: 48.01, lng: 2.0, e10: 1.6),
      ]);
      final container = _container(radar: radar);
      addTearDown(container.dispose);

      final out = await container.read(radarCandidateListProvider.future);
      expect(out.map((s) => s.id), ['MID_PRICED', 'FAR_PRICED'],
          reason: 'distance-sorted, unpriced dropped (#2583), full set (#2633)');
    });

    test('empty when no station in range is priced for the fuel', () async {
      final radar = _CapturingRadar([
        _station('A', lat: 48.0, lng: 2.0, diesel: 1.65),
        _station('B', lat: 48.02, lng: 2.0, e10: 0), // non-positive → unpriced
      ]);
      final container = _container(radar: radar, fuel: FuelType.e10);
      addTearDown(container.dispose);

      final out = await container.read(radarCandidateListProvider.future);
      expect(out, isEmpty);
    });

    test('re-stamps each row\'s dist from the live fix (#2808)', () async {
      // Both carry a STALE `dist` (99 km) from corridor-fetch time; the
      // swipe-card proximity bar reads `station.dist`, so each row must be
      // re-stamped with the LIVE distance or the bar never moves.
      final radar = _CapturingRadar([
        _station('NEAR', lat: 48.0, lng: 2.0, e10: 1.6).copyWith(dist: 99.0),
        _station('MID', lat: 48.01, lng: 2.0, e10: 1.5).copyWith(dist: 99.0),
      ]);
      final container = _container(radar: radar);
      addTearDown(container.dispose);

      final out = await container.read(radarCandidateListProvider.future);
      expect(out.map((s) => s.id), ['NEAR', 'MID']);
      // RED on master (frozen 99 km passes through); GREEN after the re-stamp.
      expect(out[0].dist, closeTo(0.0, 0.05),
          reason: '#2808 — NEAR at the fix re-stamped to ~0 km, not 99');
      expect(out[1].dist, closeTo(1.11, 0.1),
          reason: '#2808 — MID re-stamped to its live ~1.11 km, not 99');
    });
  });

  test('non-polling approach state → const [] (page-set stays out of the way)',
      () async {
    final radar = _CapturingRadar([_station('X', e10: 1.5)]);
    final container = _container(radar: radar, approach: null);
    addTearDown(container.dispose);

    final out = await container.read(radarCandidateListProvider.future);
    expect(out, isEmpty);
    expect(radar.radiusCalls, isEmpty,
        reason: 'no radar query for a non-polling state');
  });

  test('in-radius approach state → const [] (single locked target renders)',
      () async {
    final radar = _CapturingRadar([_station('X', e10: 1.5)]);
    final container = _container(
      radar: radar,
      approach: ApproachInRadius(
        station: _station('LOCKED', e10: 1.4),
        distanceMeters: 500,
      ),
    );
    addTearDown(container.dispose);

    final out = await container.read(radarCandidateListProvider.future);
    expect(out, isEmpty);
    expect(radar.radiusCalls, isEmpty);
  });

  test('null profile → const [] (no radar query without a default radius)',
      () async {
    final radar = _CapturingRadar([_station('X', e10: 1.5)]);
    final container = _container(radar: radar, profile: null);
    addTearDown(container.dispose);

    final out = await container.read(radarCandidateListProvider.future);
    expect(out, isEmpty);
    expect(radar.radiusCalls, isEmpty);
  });

  group('in-radius superset merge — dense-corridor truncation (#2965)', () {
    // The FR corridor fetch (`within_distance(60km)` + `limit:50`, no distance
    // order_by) AND the 15 km near-merge BOTH return a far-only slice WITHOUT
    // the genuinely-nearest station (modelling the dense-area row cap truncating
    // it out). A DIRECT in-radius `searchStations` at the default radar radius
    // (1 km) returns a priced station 269 m away. The candidate list must merge
    // that in so it can never be empty while a priced station is in range.
    //
    // Driven through the REAL `fuelStationRadarProvider` on FR (polled →
    // wide+near-merge corridor, #2813) + the REAL radar_candidate_list_provider,
    // with a radius-keyed service (NOT an echoing fake).
    //
    // RED on master (corridor-only → []); GREEN after the in-radius merge.
    test('lists the 269 m priced station the corridor row-cap truncated out',
        () async {
      // FR = polled corridor (within_distance + limit:50), so the real
      // fuelStationRadarProvider runs the wide+near-merge searches; the
      // candidate list then adds its own in-radius search (#2965). No radar
      // value-override — the production provider resolves from the FR country +
      // the radius-keyed station service.
      final container = ProviderContainer(
        overrides: [
          activeCountryOverride(Countries.byCode('FR')!),
          stationServiceProvider.overrideWithValue(_RadiusKeyedService()),
          effectiveApproachStateProvider.overrideWithValue(
            ApproachPolling(
              gps: _pos(lat: 48.0, lng: 2.0),
              nextPollIn: const Duration(seconds: 5),
            ),
          ),
          effectiveFuelTypeProvider.overrideWithValue(FuelType.e10),
          activeProfileProvider.overrideWith(
            () => _FakeActiveProfile(const UserProfile(
              id: 'p1',
              name: 'Test Driver',
              approachRadiusKm: 1.0,
              approachMinPollSeconds: 5,
            )),
          ),
        ].cast(),
      );
      addTearDown(container.dispose);

      final out = await container.read(radarCandidateListProvider.future);

      expect(out, isNotEmpty,
          reason: '#2965 — the in-radius merge rescues the truncated nearest');
      expect(out.map((s) => s.id), contains('NEAR_269M'),
          reason: 'the 269 m priced station the wide corridor cap dropped '
              'must be in the candidate list');
    });

    // Never-throws contract on the in-radius merge (#2965 / #1103): a failing
    // in-radius `searchStations` must NOT break the card — it degrades to the
    // cached corridor set rather than throwing or emptying the list.
    test('in-radius search failure degrades to corridor-only (never throws)',
        () async {
      final radar = _CapturingRadar([_station('CORRIDOR', e10: 1.55)]);
      final container = _container(
        radar: radar,
        stationService: _ThrowingService(),
      );
      addTearDown(container.dispose);

      // #2349 fault-idiom assertion: with the in-radius `searchStations`
      // dependency throwing, resolving the provider future must NOT throw — it
      // degrades to corridor-only rather than surfacing the fault. This is the
      // syntactic never-throws contract the static scanner
      // (`test/lint/never_throws_contract_test.dart`) greps the sibling test
      // for (`, completes)`).
      await expectLater(
        container.read(radarCandidateListProvider.future),
        completes,
        reason: '#2349 — a throwing in-radius fetch must not break the card; '
            'the provider future completes normally (corridor-only fallback)',
      );

      final out = await container.read(radarCandidateListProvider.future);

      // The corridor's priced station survives; the throwing in-radius fetch is
      // swallowed (no exception, no empty list).
      expect(out.map((s) => s.id), ['CORRIDOR'],
          reason: 'corridor-only fallback when the in-radius fetch throws');
    });
  });
}

/// In-radius service that always throws — the fault seam for the #2965 /
/// #1103 never-throws contract on the candidate list's in-radius merge.
class _ThrowingService implements StationService {
  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async =>
      throw Exception('boom');

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String stationId) =>
      throw UnimplementedError();

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) =>
      throw UnimplementedError();
}

/// Radius-keyed in-radius/corridor service (NOT an echoing fake):
///  - wide corridor (radiusKm >= [kCorridorNearMergeRadiusKm]) → a single FAR
///    station, location-only (no price) — exactly what a polled FR source
///    returns for a non-imminent corridor row before JIT-pricing,
///  - direct in-radius (radiusKm < near-merge, i.e. the 1 km candidate-list
///    search) → the genuinely-nearest 269 m station, priced.
///
/// Models the FR dense-area `limit:50` cap truncating the nearest out of the
/// corridor: the far corridor row is never imminent so never gets priced, the
/// candidate-list priced filter drops it → master yields `[]` (the reported
/// empty card) while a tight in-radius search still returns the priced nearest.
class _RadiusKeyedService implements StationService {
  // Location-only (no price for ANY fuel) — a non-imminent corridor row a
  // polled FR source returns before JIT-pricing. The candidate list's priced
  // filter drops it, so corridor-only → [].
  static Station _far() => const Station(
        id: 'FAR_55KM',
        name: 'Station FAR',
        brand: 'TEST',
        street: '',
        postCode: '',
        place: '',
        lat: 48.5, // ~55 km north of the fix
        lng: 2.0,
        isOpen: true,
      );

  static Station _near() => const Station(
        id: 'NEAR_269M',
        name: 'Station NEAR',
        brand: 'TEST',
        street: '',
        postCode: '',
        place: '',
        lat: 48.002416, // ~269 m north of the fix
        lng: 2.0,
        e10: 1.60,
        isOpen: true,
      );

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    // Anything at or above the near-merge radius is the dense-corridor slice the
    // row cap truncated to a far, location-only row. A tight (< near-merge)
    // fetch is the direct in-radius search, which carries the 269 m priced
    // station back.
    final corridorSlice = params.radiusKm >= kCorridorNearMergeRadiusKm;
    return ServiceResult(
      data: corridorSlice ? [_far()] : [_near()],
      source: ServiceSource.cache,
      fetchedAt: DateTime(2026),
    );
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String stationId) =>
      throw UnimplementedError();

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) =>
      throw UnimplementedError();
}
