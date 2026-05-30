// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/services/fuel_service_policy.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/services/station_service_chain.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

/// #2264 concern 4 — the chain branches on [FuelServicePolicy.model]:
/// bulkFile sources answer nearby straight from the primary (no per-key
/// Hive cache), polled sources keep the per-key TTL cache.

class _CountingService implements StationService {
  int searchCalls = 0;
  List<Station> stations = const [];

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    searchCalls++;
    return ServiceResult(
      data: stations,
      source: ServiceSource.mitecoApi,
      fetchedAt: DateTime.now(),
    );
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String id) async =>
      throw UnimplementedError();

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
          List<String> ids) async =>
      throw UnimplementedError();
}

/// Records every put so the test can assert the per-key cache is/isn't used.
class _SpyCache implements CacheStrategy {
  final Map<String, CacheEntry> _store = {};
  final List<String> putKeys = [];

  @override
  Future<void> put(String key, Map<String, dynamic> data,
      {required Duration ttl, required ServiceSource source}) async {
    putKeys.add(key);
    _store[key] =
        CacheEntry(payload: data, storedAt: DateTime.now(), originalSource: source, ttl: ttl);
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

const _bulkPolicy = FuelServicePolicy(
  model: SourceModel.bulkFile,
  minInterval: Duration(minutes: 30),
  datasetTtlSoft: Duration(hours: 6),
  datasetTtlHard: Duration(hours: 24),
  searchResultTtl: Duration.zero,
  attribution: 'Test bulk',
  license: 'Test',
  sourceUrl: 'https://example.test/bulk',
);

const _polledPolicy = FuelServicePolicy(
  model: SourceModel.polledApi,
  minInterval: Duration(seconds: 60),
  datasetTtlSoft: Duration.zero,
  datasetTtlHard: Duration.zero,
  searchResultTtl: Duration(minutes: 5),
  attribution: 'Test polled',
  license: 'Test',
  sourceUrl: 'https://example.test/polled',
);

SearchParams _params() => const SearchParams(
      lat: 40.0,
      lng: -3.0,
      radiusKm: 5,
      fuelType: FuelType.e5,
    );

void main() {
  group('StationServiceChain bulk-vs-polled (#2264)', () {
    test('bulkFile source never writes a per-key cache entry', () async {
      final primary = _CountingService()
        ..stations = [
          const Station(
            id: 'es-1',
            name: 'A',
            brand: 'A',
            street: '',
            postCode: '',
            place: '',
            lat: 40.0,
            lng: -3.0,
            dist: 0.1,
            e5: 1.5,
            isOpen: true,
          ),
        ];
      final cache = _SpyCache();
      final chain = StationServiceChain(primary, cache,
          errorSource: ServiceSource.mitecoApi,
          countryCode: 'ES',
          policy: _bulkPolicy);

      final result = await chain.searchStations(_params());

      expect(result.data, hasLength(1));
      expect(result.data.first.id, 'es-1');
      expect(cache.putKeys, isEmpty,
          reason: 'bulk source must not write the per-key cache');
      expect(primary.searchCalls, 1);
    });

    test('bulkFile source preserves the primary result verbatim', () async {
      final stations = [
        const Station(
          id: 'es-1',
          name: 'A',
          brand: 'A',
          street: '',
          postCode: '',
          place: '',
          lat: 40.0,
          lng: -3.0,
          dist: 0.1,
          e5: 1.5,
          isOpen: true,
        ),
      ];
      final primary = _CountingService()..stations = stations;
      final chain = StationServiceChain(primary, _SpyCache(),
          countryCode: 'ES', policy: _bulkPolicy);

      final result = await chain.searchStations(_params());
      expect(result.data, equals(stations));
      expect(result.source, ServiceSource.mitecoApi);
    });

    test('polledApi source still writes a per-key cache entry', () async {
      final primary = _CountingService()
        ..stations = [
          const Station(
            id: 'de-1',
            name: 'B',
            brand: 'B',
            street: '',
            postCode: '',
            place: '',
            lat: 40.0,
            lng: -3.0,
            dist: 0.1,
            e5: 1.5,
            isOpen: true,
          ),
        ];
      final cache = _SpyCache();
      final chain = StationServiceChain(primary, cache,
          countryCode: 'DE', policy: _polledPolicy);

      await chain.searchStations(_params());

      expect(cache.putKeys, isNotEmpty,
          reason: 'polled source must keep the per-key cache');
      expect(cache.putKeys.single, startsWith('search:DE:'));
    });

    test('polledApi second search is served from the per-key cache', () async {
      final primary = _CountingService()
        ..stations = [
          const Station(
            id: 'de-1',
            name: 'B',
            brand: 'B',
            street: '',
            postCode: '',
            place: '',
            lat: 40.0,
            lng: -3.0,
            dist: 0.1,
            e5: 1.5,
            isOpen: true,
          ),
        ];
      final chain = StationServiceChain(primary, _SpyCache(),
          countryCode: 'DE', policy: _polledPolicy);

      await chain.searchStations(_params());
      await chain.searchStations(_params());

      expect(primary.searchCalls, 1,
          reason: 'fresh per-key cache must skip the second API call');
    });
  });
}
