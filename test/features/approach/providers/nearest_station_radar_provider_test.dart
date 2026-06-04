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
import 'package:tankstellen/features/approach/providers/nearest_station_radar_provider.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/effective_fuel_type_provider.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

/// #2664 — the nearest-station radar fallback routes through the cache-first
/// [FuelStationRadar] at the user's **default radar radius**
/// (`profile.approachRadiusKm`), NOT a hard-coded 10 km, and NOT the search
/// chain directly. It keeps the #2583 priced-only contract: surface the
/// nearest station carrying a non-null, positive price for the effective fuel,
/// skipping any nearer-but-unpriced station rather than showing a `--` price.

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
  // The provider must pass THIS to `fetchStations`, never a hard-coded 10 km.
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

      await container.read(nearestStationRadarProvider.future);

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
              _station('NEAR', lat: lat, lng: lng), // ~0 m — imminent
              _station('FAR', lat: lat + 0.05, lng: lng), // ~5.5 km — corridor
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

      // First poll seeds the corridor + JIT-prices the imminent station.
      final first = await container.read(nearestStationRadarProvider.future);
      expect(first?.id, 'NEAR');
      expect(corridorCalls, 1, reason: '≤1 corridor fetch per poll');
      expect(priceCalls, 1, reason: '≤1 JIT price per imminent station');

      // A second poll at the same spot is a pure cache hit: NO new corridor
      // fetch (warm tile → zero station-network calls), price deduped in TTL.
      container.invalidate(nearestStationRadarProvider);
      await container.read(nearestStationRadarProvider.future);
      expect(corridorCalls, 1,
          reason: 'warm corridor tile → zero station-network re-query');
      expect(priceCalls, 1, reason: 'JIT price deduped within TTL');
    });
  });

  group('priced-only nearest contract preserved (#2583)', () {
    test('skips the nearer UNPRICED station and returns the nearest PRICED one',
        () async {
      // The nearest (lat 48.0) has no e10 price; the next is farther but priced.
      final radar = _CapturingRadar([
        _station('NEAR_UNPRICED', lat: 48.0, lng: 2.0, diesel: 1.65),
        _station('FAR_PRICED', lat: 48.01, lng: 2.0, e10: 1.789),
      ]);
      final container = _container(radar: radar);
      addTearDown(container.dispose);

      final out = await container.read(nearestStationRadarProvider.future);
      expect(out, isNotNull);
      expect(out!.id, 'FAR_PRICED',
          reason: 'unpriced nearest is skipped for the nearest priced station');
    });

    test('returns null when NO station in range is priced for the fuel',
        () async {
      final radar = _CapturingRadar([
        _station('A', lat: 48.0, lng: 2.0, diesel: 1.65),
        _station('B', lat: 48.02, lng: 2.0, diesel: 1.70),
      ]);
      final container = _container(radar: radar, fuel: FuelType.e10);
      addTearDown(container.dispose);

      final out = await container.read(nearestStationRadarProvider.future);
      expect(out, isNull,
          reason: 'none priced for e10 → genuine "no station nearby"');
    });

    test('treats a non-positive price as unpriced (<= 0 skipped)', () async {
      final radar = _CapturingRadar([
        _station('ZERO', lat: 48.0, lng: 2.0, e10: 0),
        _station('REAL', lat: 48.005, lng: 2.0, e10: 1.5),
      ]);
      final container = _container(radar: radar);
      addTearDown(container.dispose);

      final out = await container.read(nearestStationRadarProvider.future);
      expect(out!.id, 'REAL', reason: 'a <= 0 price counts as no price');
    });

    test('returns the nearest priced station, sorted by distance from the fix',
        () async {
      // Fed out of distance order — the provider must distance-sort the cached
      // corridor set against the live fix before picking the nearest priced.
      final radar = _CapturingRadar([
        _station('FAR_PRICED', lat: 48.03, lng: 2.0, e10: 1.5),
        _station('NEAR_PRICED', lat: 48.0, lng: 2.0, e10: 1.6),
      ]);
      final container = _container(radar: radar);
      addTearDown(container.dispose);

      final out = await container.read(nearestStationRadarProvider.future);
      expect(out!.id, 'NEAR_PRICED');
    });
  });

  group('live distance re-stamp (#2808 — PiP proximity bar)', () {
    test('re-stamps dist from the live fix, not the frozen corridor dist',
        () async {
      // ~1.11 km from the fix (48.0,2.0), but carrying a STALE `dist` (99 km)
      // baked in at corridor-fetch time. The PiP proximity bar reads
      // `station.dist`, so the provider must overwrite it with the LIVE
      // distance or the bar never moves as the driver approaches.
      final stale =
          _station('S', lat: 48.01, lng: 2.0, e10: 1.5).copyWith(dist: 99.0);
      final radar = _CapturingRadar([stale]);
      final container = _container(radar: radar);
      addTearDown(container.dispose);

      final out = await container.read(nearestStationRadarProvider.future);
      expect(out, isNotNull);
      // RED on master (passes the frozen 99 km through); GREEN after the
      // re-stamp. 0.01° lat ≈ 1.11 km.
      expect(out!.dist, closeTo(1.11, 0.1),
          reason: '#2808 — live distance re-stamped, not the frozen 99 km');
    });
  });

  test('non-polling approach state → null (fallback stays out of the way)',
      () async {
    final radar = _CapturingRadar([_station('X', e10: 1.5)]);
    final container = _container(radar: radar, approach: null);
    addTearDown(container.dispose);

    final out = await container.read(nearestStationRadarProvider.future);
    expect(out, isNull);
    expect(radar.radiusCalls, isEmpty,
        reason: 'no radar query for a non-polling state');
  });

  test('null profile → null (no radar query without a default radius)',
      () async {
    final radar = _CapturingRadar([_station('X', e10: 1.5)]);
    final container = _container(radar: radar, profile: null);
    addTearDown(container.dispose);

    final out = await container.read(nearestStationRadarProvider.future);
    expect(out, isNull);
    expect(radar.radiusCalls, isEmpty);
  });
}
