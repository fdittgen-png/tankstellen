// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tankstellen/core/location/user_position_provider.dart';
import 'package:tankstellen/core/services/radar/corridor_location_cache.dart';
import 'package:tankstellen/core/services/radar/jit_price_cache.dart';
import 'package:tankstellen/core/utils/station_extensions.dart';
import 'package:tankstellen/features/approach/providers/fuel_station_radar_provider.dart';
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
  _FixedUserPosition(this._lat, this._lng);
  final double _lat;
  final double _lng;

  @override
  UserPositionData? build() => UserPositionData(
        lat: _lat,
        lng: _lng,
        updatedAt: DateTime.now(),
        source: 'test',
      );
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

ProviderContainer _container({
  required ({double lat, double lng})? position,
  required List<Station> corridor,
  FuelType fuel = FuelType.e10,
  double radiusKm = 10.0,
}) =>
    ProviderContainer(
      overrides: [
        userPositionProvider.overrideWith(
          () => position == null
              ? _NullUserPosition()
              : _FixedUserPosition(position.lat, position.lng),
        ),
        selectedFuelTypeProvider.overrideWith(() => _FixedFuelType(fuel)),
        searchRadiusProvider.overrideWith(() => _FixedRadius(radiusKm)),
        fuelStationRadarProvider.overrideWithValue(_recordedRadar(corridor)),
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
}
