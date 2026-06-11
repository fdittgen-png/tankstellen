// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/service_providers.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/approach/providers/fuel_station_radar_provider.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/domain/station.dart';

import '../../../helpers/mock_providers.dart';

/// #2813 — the polled corridor fetch is row-capped with no distance ordering
/// (FR `within_distance(60km)` + `limit:50`), so in a sparse area the nearest
/// forecourts get truncated out of the wide slice and the recording "Closest
/// station" card shows a far one. The real `fuelStationRadarProvider` closure
/// must merge a tight near-radius fetch (not row-capped) so the nearest survive.
///
/// Driven through the REAL provider + a radius-keyed service (NOT an echoing
/// fake): the wide (60 km) query returns ONLY the far station — modelling the
/// cap truncating the near ones — while the tight ([kCorridorNearMergeRadiusKm])
/// query returns the near one, exactly as a sparse real fetch would.
Station _station(String id, double lat, double lng, {double? e10}) => Station(
      id: id,
      name: 'Station $id',
      brand: 'TEST',
      street: '',
      postCode: '',
      place: '',
      lat: lat,
      lng: lng,
      e10: e10,
      isOpen: true,
    );

class _RadiusKeyedService implements StationService {
  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    // Wide corridor (> near radius): the cap dropped the near station — only a
    // far one survives. Tight near fetch: returns the genuinely-nearest.
    final wide = params.radiusKm > kCorridorNearMergeRadiusKm;
    return ServiceResult(
      data: wide
          ? [_station('FAR', 48.5, 2.0, e10: 1.80)] // ~55 km
          : [_station('NEAR', 48.01, 2.0, e10: 1.60)], // ~1.1 km
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

void main() {
  test('polled corridor merges the tight near set so the nearest is not '
      'truncated by the row cap (#2813)', () async {
    final container = ProviderContainer(
      overrides: [
        // FR = polled (within_distance + limit:50), so the near-merge runs.
        activeCountryOverride(Countries.byCode('FR')!),
        stationServiceProvider.overrideWithValue(_RadiusKeyedService()),
      ].cast(),
    );
    addTearDown(container.dispose);

    final radar = container.read(fuelStationRadarProvider);
    final out = await radar.fetchStations(48.0, 2.0, 1.5, 'e10');
    final ids = out.map((s) => s.id).toSet();

    // RED on master: wide-only → {FAR}, the NEAR station truncated.
    // GREEN after the merge: the tight near fetch carries NEAR back.
    expect(ids, containsAll(<String>{'NEAR', 'FAR'}),
        reason: '#2813 — the nearest forecourt survives the wide row cap');
  });
}
