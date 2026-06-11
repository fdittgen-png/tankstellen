// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/services/diagnostics/data_access_event.dart';
import 'package:tankstellen/core/services/diagnostics/data_access_recorder.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/services/station_service_chain.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';

import '../../../helpers/silence_error_logger.dart';

/// Fake primary that counts upstream calls so a test can assert the chain hit
/// the network exactly once for a fresh search and NOT at all on a cache hit.
class _CountingStationService implements StationService {
  int searchCalls = 0;
  List<Station> stations;

  _CountingStationService({this.stations = const []});

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    searchCalls++;
    return ServiceResult(
      data: stations,
      source: ServiceSource.prixCarburantsApi,
      fetchedAt: DateTime.now(),
    );
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String id) async =>
      throw UnimplementedError();

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) async =>
      throw UnimplementedError();
}

/// Trivial in-memory [CacheStrategy] — no Hive. Honours TTL so getFresh
/// returns a hit while the entry is within its TTL window.
class _InMemoryCache implements CacheStrategy {
  final Map<String, CacheEntry> _store = {};

  @override
  Future<void> put(
    String key,
    Map<String, dynamic> data, {
    required Duration ttl,
    required ServiceSource source,
  }) async {
    _store[key] = CacheEntry(
      payload: data,
      storedAt: DateTime.now(),
      originalSource: source,
      ttl: ttl,
    );
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

void main() {
  silenceErrorLoggerSpool();

  const station = Station(
    id: 'fr-1',
    name: 'Total Lyon',
    brand: 'TOTAL',
    street: 'Rue X',
    postCode: '69001',
    place: 'Lyon',
    lat: 45.76,
    lng: 4.83,
    isOpen: true,
    e10: 1.799,
  );

  const geoParams = SearchParams(
    lat: 45.76,
    lng: 4.83,
    radiusKm: 10,
    fuelType: FuelType.e10,
  );

  group('StationServiceChain data-access tap (#2824)', () {
    test('first search records exactly one networkApi event (no double '
        'count), with endpoint searchGeo, country FR and result count', () async {
      final recorder = DataAccessRecorder();
      final primary = _CountingStationService(stations: const [station]);
      final chain = StationServiceChain(
        primary,
        _InMemoryCache(),
        errorSource: ServiceSource.prixCarburantsApi,
        countryCode: 'FR',
        recorder: recorder,
      );

      await chain.searchStations(geoParams);

      expect(primary.searchCalls, 1);
      expect(recorder.events.length, 1, reason: 'exactly one event per access');
      final e = recorder.events.single;
      expect(e.hit, DataAccessHit.networkApi);
      expect(e.endpoint, DataAccessEndpoint.searchGeo);
      expect(e.country, 'FR');
      expect(e.source, ServiceSource.prixCarburantsApi.name);
      expect(e.resultCount, 1);
      expect(e.latencyMicros, isNotNull);
      expect(e.isNetwork, isTrue);
    });

    test('second search hits fresh cache → a hiveFresh event and the primary '
        'is NOT called again', () async {
      final recorder = DataAccessRecorder();
      final primary = _CountingStationService(stations: const [station]);
      final chain = StationServiceChain(
        primary,
        _InMemoryCache(),
        errorSource: ServiceSource.prixCarburantsApi,
        countryCode: 'FR',
        recorder: recorder,
      );

      await chain.searchStations(geoParams); // network
      await chain.searchStations(geoParams); // fresh cache

      expect(primary.searchCalls, 1, reason: 'second search served from cache');
      expect(recorder.events.length, 2);
      expect(recorder.events[0].hit, DataAccessHit.networkApi);
      expect(recorder.events[1].hit, DataAccessHit.hiveFresh);
      expect(recorder.events[1].resultCount, 1);
    });

    test('a postalCode search records endpoint searchPostcode', () async {
      final recorder = DataAccessRecorder();
      final primary = _CountingStationService(stations: const [station]);
      final chain = StationServiceChain(
        primary,
        _InMemoryCache(),
        errorSource: ServiceSource.prixCarburantsApi,
        countryCode: 'FR',
        recorder: recorder,
      );

      await chain.searchStations(const SearchParams(
        lat: 45.76,
        lng: 4.83,
        radiusKm: 10,
        fuelType: FuelType.e10,
        postalCode: '69001',
      ));

      expect(recorder.events.single.endpoint,
          DataAccessEndpoint.searchPostcode);
    });

    test('a null recorder is a no-op — chain behaves exactly as before', () async {
      final primary = _CountingStationService(stations: const [station]);
      final chain = StationServiceChain(
        primary,
        _InMemoryCache(),
        errorSource: ServiceSource.prixCarburantsApi,
        countryCode: 'FR',
        // recorder omitted → null
      );

      final result = await chain.searchStations(geoParams);
      expect(result.data.single.id, 'fr-1');
      expect(primary.searchCalls, 1);
      // No throw, no recorder to inspect — the absence of a crash IS the test.
    });
  });
}
