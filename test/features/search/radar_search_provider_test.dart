// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tankstellen/core/location/user_position_provider.dart';
import 'package:tankstellen/core/services/radar/corridor_location_cache.dart';
import 'package:tankstellen/core/services/radar/jit_price_cache.dart';
import 'package:tankstellen/core/services/service_providers.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/utils/station_extensions.dart';
import 'package:tankstellen/features/approach/providers/fuel_station_radar_provider.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
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

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
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

ProviderContainer _container({
  required ({double lat, double lng})? position,
  required List<Station> corridor,
  List<Station> inRadius = const [],
  bool inRadiusThrows = false,
  ({double lat, double lng})? refreshTo,
  FuelType fuel = FuelType.e10,
  double radiusKm = 10.0,
}) =>
    ProviderContainer(
      overrides: [
        userPositionProvider.overrideWith(
          () => position == null
              ? _NullUserPosition()
              : _FixedUserPosition(position.lat, position.lng,
                  refreshTo: refreshTo),
        ),
        selectedFuelTypeProvider.overrideWith(() => _FixedFuelType(fuel)),
        searchRadiusProvider.overrideWith(() => _FixedRadius(radiusKm)),
        fuelStationRadarProvider.overrideWithValue(_recordedRadar(corridor)),
        stationServiceProvider.overrideWithValue(
          _FakeStationService(inRadius, throws: inRadiusThrows),
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

    test('no-ops with active=false when the user position is unknown',
        () async {
      final container = _container(
        position: null,
        corridor: [_station('NEAR', 48.0, 2.0, e10: 1.5)],
      );
      addTearDown(container.dispose);

      await container.read(radarSearchProvider.notifier).runRadar();

      expect(container.read(radarSearchProvider).active, isFalse,
          reason: 'no position → nothing to scan around');
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
}
