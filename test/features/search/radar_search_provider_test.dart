// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/location/geolocator_wrapper.dart';
import 'package:tankstellen/core/location/user_position_provider.dart';
import 'package:tankstellen/core/services/mixins/station_service_helpers.dart';
import 'package:tankstellen/core/services/radar/corridor_location_cache.dart';
import 'package:tankstellen/core/services/radar/jit_price_cache.dart';
import 'package:tankstellen/core/services/service_providers.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/utils/station_extensions.dart';
import 'package:tankstellen/features/approach/providers/fuel_station_radar_provider.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/search/providers/radar_search_provider.dart';
import 'package:tankstellen/features/search/providers/search_filters_provider.dart';

/// #2674 — the on-search radar drives the REAL `FuelStationRadar.fetchStations`
/// through a recorded corridor-cache fixture (a bulk slice that already carries
/// prices, like ES/IT do), NOT a request-echoing fake. This pins the
/// data-shape contract the regular fetch + the provider's distance-sort +
/// priced-filter actually deliver — see the false-green-fakes memory.

/// Real-shaped corridor station. `e10` null/<=0 models an unpriced forecourt
/// the radar must drop.
Station _station(
  String id,
  double lat,
  double lng, {
  double? e10,
}) =>
    Station(
      id: id,
      name: 'Station $id',
      brand: 'TEST',
      street: 'Teststr.',
      postCode: '00000',
      place: 'Test',
      lat: lat,
      lng: lng,
      e10: e10,
      isOpen: true,
    );

/// Builds a REAL [FuelStationRadar] over a recorded corridor slice. Bulk
/// source → the slice already carries prices, so no JIT round-trip fires
/// (mirrors `fuel_station_radar_provider.dart`'s ES/IT branch).
FuelStationRadar _recordedRadar(List<Station> corridor) => FuelStationRadar(
      isBulkSource: true,
      corridorCache: CorridorLocationCache(
        isBulk: true,
        corridorRadiusKm: 60,
        tileStepDegrees: 0.5,
        fetchCorridor: (lat, lng, r) async => corridor,
      ),
      priceCache: JitPriceCache(fetchPrice: (s) async => s),
    );

class _FixedUserPosition extends UserPosition {
  _FixedUserPosition(this._lat, this._lng, {({double lat, double lng})? refreshTo})
      : _refreshTo = refreshTo;
  final double _lat;
  final double _lng;

  /// When set, [updateFromGps] moves the position here — models the #2806 live
  /// refresh. When null it is a no-op (keeps the persisted point), which also
  /// keeps the unit test off the geolocator method channel.
  final ({double lat, double lng})? _refreshTo;

  @override
  UserPositionData? build() => UserPositionData(
        lat: _lat,
        lng: _lng,
        updatedAt: DateTime.now(),
        source: 'test',
      );

  @override
  Future<void> updateFromGps() async {
    final r = _refreshTo;
    if (r == null) return;
    state = UserPositionData(
      lat: r.lat,
      lng: r.lng,
      updatedAt: DateTime.now(),
      source: 'gps',
    );
  }
}

class _NullUserPosition extends UserPosition {
  @override
  UserPositionData? build() => null;
}

/// #3042 — no persisted position AND the live GPS refresh is denied (the
/// fresh-install permission-denied case). [updateFromGps] throws, [build]
/// stays null, so `runRadar` has nowhere to scan and must surface the failure.
class _DeniedUserPosition extends UserPosition {
  @override
  UserPositionData? build() => null;

  @override
  Future<void> updateFromGps() async =>
      throw const LocationException(message: 'Location permission denied.');
}

class _FixedFuelType extends SelectedFuelType {
  _FixedFuelType(this._type);
  final FuelType _type;
  @override
  FuelType build() => _type;
}

class _FixedRadius extends SearchRadius {
  _FixedRadius(this._km);
  final double _km;
  @override
  double build() => _km;
}

/// A minimal [StationService] that returns a fixed in-radius slice — the
/// #2806 seam the radar now merges so its list is a superset of the regular
/// search. Set [throws] to model an in-radius fetch failure (radar must then
/// degrade to its cached corridor, not error).
class _FakeStationService implements StationService {
  _FakeStationService(this._inRadius, {this.throws = false});
  final List<Station> _inRadius;
  final bool throws;

  /// How many direct in-radius searches the radar issued — the #3254 gate
  /// assertion checks this stays bounded as the user moves.
  int searchCalls = 0;

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    searchCalls++;
    if (throws) throw StateError('in-radius fetch failed');
    return ServiceResult(
      data: _inRadius,
      source: ServiceSource.cache,
      fetchedAt: DateTime.now(),
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

/// A [GeolocatorWrapper] whose live position stream the test drives by hand —
/// the on-search radar now subscribes to it for live distance re-stamping
/// (#3267). Default-empty so the existing one-shot assertions are unaffected.
class _FakeGeolocator extends GeolocatorWrapper {
  _FakeGeolocator(this.controller);
  final StreamController<Position> controller;

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) =>
      controller.stream;
}

/// A [GeolocatorWrapper] whose position stream THROWS synchronously on
/// subscribe — models a platform-less / location-off device. The on-search
/// radar's `_subscribeGps` documents a never-throws contract: it must swallow
/// this and keep the radar usable off the persisted / refreshed fix (#3267).
class _ThrowingGeolocator extends GeolocatorWrapper {
  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) =>
      throw StateError('no platform location stream');
}

/// A real-shaped [Position] for the live GPS stream.
Position _pos(double lat, double lng, {double heading = 90}) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: heading,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

ProviderContainer _container({
  required ({double lat, double lng})? position,
  required List<Station> corridor,
  List<Station> inRadius = const [],
  bool inRadiusThrows = false,
  bool deniedRefresh = false,
  ({double lat, double lng})? refreshTo,
  FuelType fuel = FuelType.e10,
  double radiusKm = 10.0,
  StreamController<Position>? gps,
  _FakeStationService? service,
}) =>
    ProviderContainer(
      overrides: [
        userPositionProvider.overrideWith(
          () => deniedRefresh
              ? _DeniedUserPosition()
              : position == null
                  ? _NullUserPosition()
                  : _FixedUserPosition(position.lat, position.lng,
                      refreshTo: refreshTo),
        ),
        selectedFuelTypeProvider.overrideWith(() => _FixedFuelType(fuel)),
        searchRadiusProvider.overrideWith(() => _FixedRadius(radiusKm)),
        fuelStationRadarProvider.overrideWithValue(_recordedRadar(corridor)),
        stationServiceProvider.overrideWithValue(
          service ?? _FakeStationService(inRadius, throws: inRadiusThrows),
        ),
        // The on-search radar subscribes to the live GPS stream (#3267).
        // A broadcast controller the test can push fixes into; default-empty
        // (never emits) for the one-shot assertions.
        geolocatorWrapperProvider.overrideWithValue(
          _FakeGeolocator(gps ?? StreamController<Position>.broadcast()),
        ),
      ],
    );

void main() {
  group('RadarSearch — on-search radar over the real fetch', () {
    test('runRadar flips active and surfaces a distance-sorted priced list',
        () async {
      // Three priced stations + one unpriced, scattered around the user. The
      // user sits at (48.0, 2.0); FAR is ~3.3 km N, NEAR is ~0 m, MID ~1.1 km.
      final container = _container(
        position: (lat: 48.0, lng: 2.0),
        corridor: [
          _station('FAR', 48.03, 2.0, e10: 1.799),
          _station('NEAR', 48.0, 2.0, e10: 1.659),
          _station('MID', 48.01, 2.0, e10: 1.729),
          _station('UNPRICED', 48.005, 2.0, e10: null),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(radarSearchProvider).active, isFalse);

      await container.read(radarSearchProvider.notifier).runRadar();

      final state = container.read(radarSearchProvider);
      expect(state.active, isTrue, reason: 'radar flips active after a run');

      final list = state.stations.value!;
      // UNPRICED dropped; the three priced ones survive.
      expect(list.map((s) => s.id), ['NEAR', 'MID', 'FAR'],
          reason: 'priced rows only, sorted by ascending distance');
      expect(list.every((s) => (s.priceFor(FuelType.e10) ?? 0) > 0), isTrue);
      // Distance stamped (km) from the user — drives the PiP tile + sort.
      expect(list.first.dist, lessThan(0.1));
      expect(list.last.dist, greaterThan(2.0));

      // The derived nearest provider points at the closest priced station.
      expect(container.read(radarSearchNearestProvider)?.id, 'NEAR');
    });

    test('drops every row when nothing in the corridor has a usable price',
        () async {
      final container = _container(
        position: (lat: 48.0, lng: 2.0),
        corridor: [
          _station('A', 48.0, 2.0, e10: null),
          _station('B', 48.01, 2.0, e10: 0.0),
        ],
      );
      addTearDown(container.dispose);

      await container.read(radarSearchProvider.notifier).runRadar();

      final state = container.read(radarSearchProvider);
      expect(state.active, isTrue);
      expect(state.stations.value, isEmpty);
      expect(container.read(radarSearchNearestProvider), isNull);
    });

    test(
        'surfaces an actionable error (never silent) when no position is known '
        'and the GPS refresh is denied (#3042)', () async {
      final container = _container(
        position: null,
        deniedRefresh: true,
        corridor: [_station('NEAR', 48.0, 2.0, e10: 1.5)],
      );
      addTearDown(container.dispose);

      await container.read(radarSearchProvider.notifier).runRadar();

      final state = container.read(radarSearchProvider);
      // #3042 — the fresh-install permission-denied case used to flip the
      // radar to idle/empty with ZERO feedback. It must now OWN the results
      // area (active) and surface the location failure as an error so
      // SearchResultsContent renders an actionable banner (grant / open
      // settings / search by postal code) instead of "no stations".
      expect(state.active, isTrue,
          reason: 'radar owns the results area to show the error');
      expect(state.stations.hasError, isTrue,
          reason: 'permission denial surfaces as an error, not empty silence');
      expect(state.stations.error, isA<LocationException>());
      expect(container.read(radarSearchNearestProvider), isNull);
    });

    test('dismiss flips active back to false', () async {
      final container = _container(
        position: (lat: 48.0, lng: 2.0),
        corridor: [_station('NEAR', 48.0, 2.0, e10: 1.5)],
      );
      addTearDown(container.dispose);

      await container.read(radarSearchProvider.notifier).runRadar();
      expect(container.read(radarSearchProvider).active, isTrue);

      container.read(radarSearchProvider.notifier).dismiss();
      expect(container.read(radarSearchProvider).active, isFalse);
      expect(container.read(radarSearchNearestProvider), isNull);
    });
  });

  group('RadarSearch — superset of the in-radius search (#2806)', () {
    // User at (48.0, 2.0); 0.01° lat ≈ 1.11 km. The wide corridor (capped at
    // 50, un-distance-ordered) returns only FAR stations — the field bug where
    // the radar showed a 13–19 km band and excluded the close stations the
    // 10 km search found.
    Station far1() => _station('FAR1', 48.12, 2.0, e10: 1.799); // ≈13.3 km
    Station far2() => _station('FAR2', 48.16, 2.0, e10: 1.829); // ≈17.8 km
    Station near() => _station('NEAR', 48.0, 2.0, e10: 1.659); //  ≈0 km
    Station mid() => _station('MID', 48.03, 2.0, e10: 1.729); //  ≈3.3 km

    test('merges the in-radius near stations the corridor missed', () async {
      final container = _container(
        position: (lat: 48.0, lng: 2.0),
        corridor: [far1(), far2()], // corridor missed the near zone
        inRadius: [near(), mid()], // the regular 10 km search keeps them
      );
      addTearDown(container.dispose);

      await container.read(radarSearchProvider.notifier).runRadar();

      final list = container.read(radarSearchProvider).stations.value!;
      // RED on master (corridor-only → [FAR1, FAR2]); the radar must now be a
      // superset of the in-radius search, distance-sorted from the user.
      expect(list.map((s) => s.id), ['NEAR', 'MID', 'FAR1', 'FAR2']);
      expect(container.read(radarSearchNearestProvider)?.id, 'NEAR');
    });

    test('dedups a station present in both corridor and in-radius', () async {
      final container = _container(
        position: (lat: 48.0, lng: 2.0),
        // Same id in both; the in-radius row carries the fresher price.
        corridor: [_station('DUP', 48.0, 2.0, e10: 1.999)],
        inRadius: [_station('DUP', 48.0, 2.0, e10: 1.659)],
      );
      addTearDown(container.dispose);

      await container.read(radarSearchProvider.notifier).runRadar();

      final list = container.read(radarSearchProvider).stations.value!;
      expect(list, hasLength(1));
      expect(list.single.priceFor(FuelType.e10), 1.659,
          reason: 'in-radius row wins the dedup (freshest price)');
    });

    test('degrades to the cached corridor when the in-radius fetch fails',
        () async {
      final container = _container(
        position: (lat: 48.0, lng: 2.0),
        corridor: [far1(), far2()],
        inRadiusThrows: true,
      );
      addTearDown(container.dispose);

      await container.read(radarSearchProvider.notifier).runRadar();

      final state = container.read(radarSearchProvider);
      // No error surfaced; the radar still shows the corridor it had.
      expect(state.stations.hasError, isFalse);
      expect(state.stations.value!.map((s) => s.id), ['FAR1', 'FAR2']);
    });

    test(
        'consistency invariant: the radar set equals the in-radius search '
        'hard-filtered by the same fuel (#2926)', () async {
      // Same position + radius + specific fuel. The corridor + in-radius slice
      // both contain stations that DON\'T sell E85 (e10-only). Both the regular
      // search (StationServiceChain → filterByFuel) and the radar must surface
      // ONLY the E85 sellers, so the two result sets are identical.
      final e85Total = _station('TOTAL', 48.0, 2.0)
          .copyWith(e85: 0.84, e10: 1.77);
      final e85Avia =
          _station('AVIA', 48.01, 2.0).copyWith(e85: 0.86, e10: 1.79);
      final e10Only = _station('ESSO', 48.005, 2.0, e10: 1.75); // no E85
      final container = _container(
        position: (lat: 48.0, lng: 2.0),
        corridor: [e85Total, e10Only],
        inRadius: [e85Avia, e10Only],
        fuel: FuelType.e85,
      );
      addTearDown(container.dispose);

      await container.read(radarSearchProvider.notifier).runRadar();
      final radarIds = container
          .read(radarSearchProvider)
          .stations
          .value!
          .map((s) => s.id)
          .toSet();

      // The in-radius search, run through the SAME shared filter the chain
      // applies, over the merged corridor+in-radius superset.
      final expected = StationServiceHelpers.filterByFuel(
        [e85Total, e85Avia, e10Only],
        FuelType.e85,
      ).map((s) => s.id).toSet();

      expect(radarIds, expected,
          reason: 'radar set == in-radius search hard-filtered by fuel');
      expect(radarIds, {'TOTAL', 'AVIA'},
          reason: 'the e10-only ESSO is dropped on BOTH paths');
    });

    test('FuelType.all keeps every station on the radar path (no filter)',
        () async {
      final container = _container(
        position: (lat: 48.0, lng: 2.0),
        corridor: [_station('A', 48.0, 2.0, e10: 1.50)],
        inRadius: [_station('B', 48.01, 2.0)], // no priced fuel at all
        fuel: FuelType.all,
      );
      addTearDown(container.dispose);

      await container.read(radarSearchProvider.notifier).runRadar();
      final ids = container
          .read(radarSearchProvider)
          .stations
          .value!
          .map((s) => s.id)
          .toSet();
      expect(ids, {'A', 'B'},
          reason: 'the all wildcard surfaces every station, priced or not');
    });

    test('refreshes live GPS, so it scans the user\'s current position',
        () async {
      // Persisted point is stale (49.0, 3.0 — ~130 km away); the live fix is
      // (48.0, 2.0). The corridor + in-radius are around the LIVE point.
      final container = _container(
        position: (lat: 49.0, lng: 3.0),
        refreshTo: (lat: 48.0, lng: 2.0),
        corridor: [far1()],
        inRadius: [near()],
      );
      addTearDown(container.dispose);

      await container.read(radarSearchProvider.notifier).runRadar();

      final list = container.read(radarSearchProvider).stations.value!;
      // Distances are stamped from the REFRESHED (live) point: NEAR ≈ 0 km.
      // On master (no refresh) they'd be stamped from the stale (49,3) point,
      // where NEAR is ~130 km away and would sort after FAR1.
      expect(list.first.id, 'NEAR');
      expect(list.first.dist, lessThan(0.1));
    });
  });

  group('RadarSearch — live distance updates (#3267)', () {
    test(
        'a live GPS fix re-stamps distance closer as the user approaches '
        '(no longer a frozen one-shot)', () async {
      // One station ~5.5 km north of the user's start. As the user drives
      // toward it the live stream must re-stamp the distance DOWN — the core
      // bug: the on-search radar used to stamp distance once and freeze it.
      final gps = StreamController<Position>.broadcast();
      addTearDown(gps.close);
      final container = _container(
        position: (lat: 48.0, lng: 2.0),
        corridor: [_station('AHEAD', 48.05, 2.0, e10: 1.65)],
        gps: gps,
      );
      addTearDown(container.dispose);
      // Keep the autoDispose provider alive across pumps, as the search screen
      // does by watching it (else it disposes between reads and resets to idle).
      addTearDown(container.listen(radarSearchProvider, (_, _) {}).close);

      await container.read(radarSearchProvider.notifier).runRadar();
      final startDist =
          container.read(radarSearchProvider).stations.value!.first.dist;
      expect(startDist, greaterThan(5.0),
          reason: 'AHEAD starts ~5.5 km away');

      // Drive halfway toward it.
      gps.add(_pos(48.025, 2.0));
      await pumpEventQueue();

      final midDist =
          container.read(radarSearchProvider).stations.value!.first.dist;
      expect(midDist, lessThan(startDist),
          reason: 'distance ticks DOWN on a live fix, not frozen');
      expect(midDist, greaterThan(2.0));

      // Arrive next to it.
      gps.add(_pos(48.05, 2.0));
      await pumpEventQueue();

      final endDist =
          container.read(radarSearchProvider).stations.value!.first.dist;
      expect(endDist, lessThan(0.2),
          reason: 'at the station the live distance is ~0');
      // The derived PiP-tile nearest carries the SAME live distance (#3255).
      expect(container.read(radarSearchNearestProvider)!.dist, lessThan(0.2));
    });

    test(
        'live re-rank between fixes issues NO extra in-radius chain search '
        'while inside the cache cell (#3254 gate)', () async {
      final gps = StreamController<Position>.broadcast();
      addTearDown(gps.close);
      final service = _FakeStationService(const []);
      final container = _container(
        position: (lat: 48.0, lng: 2.0),
        corridor: [_station('AHEAD', 48.05, 2.0, e10: 1.65)],
        service: service,
        gps: gps,
      );
      addTearDown(container.dispose);
      addTearDown(container.listen(radarSearchProvider, (_, _) {}).close);

      await container.read(radarSearchProvider.notifier).runRadar();
      final afterRun = service.searchCalls;
      expect(afterRun, 1, reason: 'one authoritative in-radius search on run');

      // Several sub-cell jitters (<111 m) — the live distance still updates off
      // the cached set, but NOT one chain search per fix.
      for (final dLat in [0.0001, 0.0002, 0.0003, 0.0004]) {
        gps.add(_pos(48.0 + dLat, 2.0));
        await pumpEventQueue();
      }
      expect(service.searchCalls, afterRun,
          reason: 'in-cell fixes reuse the gated merge — no new chain search');
    });

    test(
        '_subscribeGps never throws — a platform-less position stream is '
        'swallowed and the radar still scans (#3267 never-throws contract)',
        () async {
      final container = ProviderContainer(overrides: [
        userPositionProvider
            .overrideWith(() => _FixedUserPosition(48.0, 2.0)),
        selectedFuelTypeProvider.overrideWith(() => _FixedFuelType(FuelType.e10)),
        searchRadiusProvider.overrideWith(() => _FixedRadius(10.0)),
        fuelStationRadarProvider.overrideWithValue(
          _recordedRadar([_station('NEAR', 48.0, 2.0, e10: 1.5)]),
        ),
        stationServiceProvider
            .overrideWithValue(_FakeStationService(const [])),
        // The GPS stream throws on subscribe — the fault injected here.
        geolocatorWrapperProvider.overrideWithValue(_ThrowingGeolocator()),
      ]);
      addTearDown(container.dispose);

      // The throwing stream must NOT propagate out of runRadar.
      await expectLater(
        container.read(radarSearchProvider.notifier).runRadar(),
        completes,
      );
      // …and the radar still scanned off the persisted / refreshed fix.
      expect(container.read(radarSearchProvider).stations.value, isNotEmpty);
    });

    test('locating flips false once the fresh fix lands', () async {
      final container = _container(
        position: (lat: 48.0, lng: 2.0),
        corridor: [_station('NEAR', 48.0, 2.0, e10: 1.5)],
      );
      addTearDown(container.dispose);

      await container.read(radarSearchProvider.notifier).runRadar();
      expect(container.read(radarSearchProvider).locating, isFalse,
          reason: 'authoritative scan around the fresh fix clears locating');
    });
  });
}
