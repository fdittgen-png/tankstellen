// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tankstellen/core/services/approach_detector.dart';
import 'package:tankstellen/core/services/radar/corridor_location_cache.dart';
import 'package:tankstellen/core/services/radar/jit_price_cache.dart';
import 'package:tankstellen/features/approach/providers/effective_approach_state_provider.dart';
import 'package:tankstellen/features/approach/providers/fuel_station_radar_provider.dart';
import 'package:tankstellen/features/approach/providers/radar_candidate_list_provider.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/effective_fuel_type_provider.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

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

ProviderContainer _container({
  required FuelStationRadar radar,
  FuelType fuel = FuelType.e10,
  UserProfile? profile = _profile,
  // `_unset` keeps the default polling fix; pass an explicit value (incl.
  // `null`) to override it — `null` can't be the default or it would be
  // indistinguishable from "not passed".
  Object? approach = _unset,
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
}
