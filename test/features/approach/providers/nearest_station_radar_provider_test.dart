// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tankstellen/core/services/approach_detector.dart';
import 'package:tankstellen/core/services/service_providers.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/approach/providers/effective_approach_state_provider.dart';
import 'package:tankstellen/features/approach/providers/nearest_station_radar_provider.dart';
import 'package:tankstellen/features/profile/providers/effective_fuel_type_provider.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

/// #2583 — the nearest-station radar fallback must surface only stations
/// the driver can actually price-compare: the nearest station that carries
/// a non-null, positive price for the **effective** fuel, skipping any
/// nearer but unpriced station rather than showing a `--` price.

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

Station _station(String id, {double? e10, double? diesel, double dist = 0}) =>
    Station(
      id: id,
      name: 'Station $id',
      brand: 'Brand',
      street: '',
      postCode: '',
      place: '',
      lat: 48.0,
      lng: 2.0,
      e10: e10,
      diesel: diesel,
      dist: dist,
      isOpen: true,
    );

/// Minimal [StationService] returning a fixed, distance-sorted result for
/// `searchStations`. The other interface methods are unused by the radar
/// provider and throw if hit.
class _FakeStationService implements StationService {
  _FakeStationService(this._stations);
  final List<Station> _stations;

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    return ServiceResult<List<Station>>(
      data: _stations,
      source: ServiceSource.cache,
      fetchedAt: DateTime(2026, 5, 1, 9),
    );
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String id) =>
      throw UnimplementedError();

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) =>
      throw UnimplementedError();
}

ProviderContainer _container({
  required List<Station> stations,
  FuelType fuel = FuelType.e10,
}) {
  return ProviderContainer(
    overrides: [
      effectiveApproachStateProvider.overrideWithValue(
        ApproachPolling(
          gps: _pos(lat: 48.0, lng: 2.0),
          nextPollIn: const Duration(seconds: 5),
        ),
      ),
      effectiveFuelTypeProvider.overrideWithValue(fuel),
      stationServiceProvider
          .overrideWithValue(_FakeStationService(stations)),
    ],
  );
}

void main() {
  test('skips the nearer UNPRICED station and returns the nearest PRICED one',
      () async {
    // The nearest (dist 0) has no e10 price; the next (dist 1.2) does.
    final container = _container(
      stations: [
        _station('NEAR_UNPRICED', dist: 0, diesel: 1.65),
        _station('FAR_PRICED', dist: 1.2, e10: 1.789),
      ],
    );
    addTearDown(container.dispose);

    final out = await container.read(nearestStationRadarProvider.future);
    expect(out, isNotNull);
    expect(out!.id, 'FAR_PRICED',
        reason: 'unpriced nearest is skipped for the nearest priced station');
  });

  test('returns null when NO station in range is priced for the fuel',
      () async {
    final container = _container(
      stations: [
        _station('A', dist: 0, diesel: 1.65),
        _station('B', dist: 2.0, diesel: 1.70),
      ],
      fuel: FuelType.e10,
    );
    addTearDown(container.dispose);

    final out = await container.read(nearestStationRadarProvider.future);
    expect(out, isNull,
        reason: 'none priced for e10 → genuine "no station nearby"');
  });

  test('treats a non-positive price as unpriced (<= 0 skipped)', () async {
    final container = _container(
      stations: [
        _station('ZERO', dist: 0, e10: 0),
        _station('REAL', dist: 0.5, e10: 1.5),
      ],
    );
    addTearDown(container.dispose);

    final out = await container.read(nearestStationRadarProvider.future);
    expect(out!.id, 'REAL', reason: 'a <= 0 price counts as no price');
  });

  test('returns the nearest priced station when the nearest IS priced',
      () async {
    final container = _container(
      stations: [
        _station('NEAR_PRICED', dist: 0, e10: 1.6),
        _station('FAR_PRICED', dist: 3.0, e10: 1.5),
      ],
    );
    addTearDown(container.dispose);

    final out = await container.read(nearestStationRadarProvider.future);
    expect(out!.id, 'NEAR_PRICED');
  });

  test('non-polling approach state → null (fallback stays out of the way)',
      () async {
    final container = ProviderContainer(
      overrides: [
        effectiveApproachStateProvider.overrideWithValue(null),
        effectiveFuelTypeProvider.overrideWithValue(FuelType.e10),
        stationServiceProvider.overrideWithValue(
          _FakeStationService([_station('X', e10: 1.5)]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final out = await container.read(nearestStationRadarProvider.future);
    expect(out, isNull);
  });
}
