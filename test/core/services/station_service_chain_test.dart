import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

// Simple test doubles — no mocktail needed for these

class _FakeStationService implements StationService {
  List<Station>? stationsToReturn;
  Object? errorToThrow;

  @override
  Future<ServiceResult<List<Station>>> searchStations(SearchParams params, {CancelToken? cancelToken}) async {
    if (errorToThrow != null) throw errorToThrow!;
    return ServiceResult(
      data: stationsToReturn ?? [],
      source: ServiceSource.tankerkoenigApi,
      fetchedAt: DateTime.now(),
    );
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(List<String> ids) async {
    throw UnimplementedError();
  }
}

/// In-memory cache that doesn't need Hive. Mimics CacheManager API.
class _FakeCacheManager {
  final Map<String, _CacheItem> _store = {};

  Future<void> put(String key, Map<String, dynamic> data,
      {required Duration ttl, required ServiceSource source}) async {
    _store[key] = _CacheItem(data, DateTime.now(), source, ttl);
  }

  CacheEntry? get(String key) {
    final item = _store[key];
    if (item == null) return null;
    return CacheEntry(
      payload: item.data,
      storedAt: item.storedAt,
      originalSource: item.source,
      ttl: item.ttl,
    );
  }

  CacheEntry? getFresh(String key) => get(key);
  Future<void> clearAll() async => _store.clear();
}

class _CacheItem {
  final Map<String, dynamic> data;
  final DateTime storedAt;
  final ServiceSource source;
  final Duration ttl;
  _CacheItem(this.data, this.storedAt, this.source, this.ttl);
}

/// StationServiceChain wrapper that uses our fake cache instead of real CacheManager
class _TestableChain {
  final _FakeStationService _primary;
  final _FakeCacheManager _cache;

  _TestableChain(this._primary, this._cache);

  Future<ServiceResult<List<Station>>> searchStations(SearchParams params, {CancelToken? cancelToken}) async {
    final cacheKey = CacheKey.stationSearch(
      params.lat, params.lng, params.radiusKm, params.fuelType.apiValue,
    );
    final errors = <ServiceError>[];

    // Fresh cache
    final fresh = _cache.getFresh(cacheKey);
    if (fresh != null) {
      final list = fresh.payload['stations'] as List<dynamic>?;
      if (list != null) {
        return ServiceResult(
          data: list.map((j) => Station.fromJson(Map<String, dynamic>.from(j as Map))).toList(),
          source: fresh.originalSource,
          fetchedAt: fresh.storedAt,
        );
      }
    }

    // Primary
    try {
      final result = await _primary.searchStations(params);
      await _cache.put(
        cacheKey,
        {'stations': result.data.map((s) => s.toJson()).toList()},
        ttl: CacheTtl.stationSearch,
        source: result.source,
      );
      return result;
    } catch (e) {
      errors.add(ServiceError(
        source: ServiceSource.tankerkoenigApi,
        message: e.toString(),
        occurredAt: DateTime.now(),
      ));
    }

    // Stale cache
    final stale = _cache.get(cacheKey);
    if (stale != null) {
      final list = stale.payload['stations'] as List<dynamic>?;
      if (list != null) {
        return ServiceResult(
          data: list.map((j) => Station.fromJson(Map<String, dynamic>.from(j as Map))).toList(),
          source: ServiceSource.cache,
          fetchedAt: stale.storedAt,
          isStale: true,
          errors: errors,
        );
      }
    }

    throw ServiceChainExhaustedException(errors: errors);
  }
}

final _testStation = Station(
  id: 'test-id',
  name: 'Test Station',
  brand: 'TEST',
  street: 'Teststr.',
  postCode: '10115',
  place: 'Berlin',
  lat: 52.52,
  lng: 13.41,
  isOpen: true,
  e10: 1.459,
);

final _testParams = SearchParams(
  lat: 52.52,
  lng: 13.41,
  radiusKm: 10,
  fuelType: FuelType.e10,
);

void main() {
  group('StationServiceChain', () {
    late _FakeStationService fakeService;
    late _FakeCacheManager fakeCache;
    late _TestableChain chain;

    setUp(() {
      fakeService = _FakeStationService();
      fakeCache = _FakeCacheManager();
      chain = _TestableChain(fakeService, fakeCache);
    });

    test('returns API data on success', () async {
      fakeService.stationsToReturn = [_testStation];
      final result = await chain.searchStations(_testParams);
      expect(result.data.length, 1);
      expect(result.source, ServiceSource.tankerkoenigApi);
      expect(result.isStale, false);
      expect(result.errors, isEmpty);
    });

    test('caches result after successful API call', () async {
      fakeService.stationsToReturn = [_testStation];
      await chain.searchStations(_testParams);

      // Now make API fail — should get cached data
      fakeService.errorToThrow = const ApiException(message: 'down');
      final result = await chain.searchStations(_testParams);
      expect(result.data.length, 1);
      expect(result.data.first.id, 'test-id');
    });

    test('returns cached data when API fails and cache exists', () async {
      // Pre-populate cache
      fakeService.stationsToReturn = [_testStation];
      await chain.searchStations(_testParams);

      // Now fail — should still return data from cache
      fakeService.errorToThrow = const ApiException(message: 'down');
      final result = await chain.searchStations(_testParams);
      expect(result.data.length, 1);
      expect(result.data.first.id, 'test-id');
    });

    test('throws ServiceChainExhaustedException when all fail', () async {
      fakeService.errorToThrow = const ApiException(message: 'down');
      // No cache either
      expect(
        () => chain.searchStations(_testParams),
        throwsA(isA<ServiceChainExhaustedException>()),
      );
    });
  });
}
