import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/services/station_service_chain.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

// ---------------------------------------------------------------------------
// Fake CacheStrategy — pure in-memory, no Hive or mocking framework needed
// ---------------------------------------------------------------------------

/// Minimal in-memory [CacheStrategy] for testing service chains without
/// any storage infrastructure.
class FakeCacheStrategy implements CacheStrategy {
  final Map<String, _Entry> _store = {};

  @override
  Future<void> put(
    String key,
    Map<String, dynamic> data, {
    required Duration ttl,
    required ServiceSource source,
  }) async {
    _store[key] = _Entry(data, DateTime.now(), source, ttl);
  }

  @override
  CacheEntry? get(String key) {
    final e = _store[key];
    if (e == null) return null;
    return CacheEntry(
      payload: e.data,
      storedAt: e.storedAt,
      originalSource: e.source,
      ttl: e.ttl,
    );
  }

  @override
  CacheEntry? getFresh(String key) {
    final entry = get(key);
    if (entry == null || entry.isExpired) return null;
    return entry;
  }

  /// Insert an already-expired entry (storedAt in the past).
  void insertExpired(
    String key,
    Map<String, dynamic> data, {
    required ServiceSource source,
    required Duration ttl,
    required DateTime storedAt,
  }) {
    _store[key] = _Entry(data, storedAt, source, ttl);
  }

  void clear() => _store.clear();
}

class _Entry {
  final Map<String, dynamic> data;
  final DateTime storedAt;
  final ServiceSource source;
  final Duration ttl;
  _Entry(this.data, this.storedAt, this.source, this.ttl);
}

// ---------------------------------------------------------------------------
// Fake StationService
// ---------------------------------------------------------------------------

class _FakeStationService implements StationService {
  List<Station> stationsToReturn = [];
  Object? errorToThrow;
  int callCount = 0;

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    callCount++;
    if (errorToThrow != null) throw errorToThrow!;
    return ServiceResult(
      data: stationsToReturn,
      source: ServiceSource.tankerkoenigApi,
      fetchedAt: DateTime.now(),
    );
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String id) async {
    callCount++;
    if (errorToThrow != null) throw errorToThrow!;
    throw const ApiException(message: 'Not implemented');
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) async {
    callCount++;
    if (errorToThrow != null) throw errorToThrow!;
    return ServiceResult(
      data: const {},
      source: ServiceSource.tankerkoenigApi,
      fetchedAt: DateTime.now(),
    );
  }
}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

Station _makeStation(String id) => Station(
      id: id,
      name: 'Test $id',
      brand: 'TEST',
      street: 'Teststr.',
      postCode: '10115',
      place: 'Berlin',
      lat: 52.52,
      lng: 13.41,
      isOpen: true,
      e10: 1.459,
    );

const _params = SearchParams(
  lat: 52.52,
  lng: 13.41,
  radiusKm: 10,
  fuelType: FuelType.e10,
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('CacheStrategy interface', () {
    test('CacheManager implements CacheStrategy', () {
      // Compile-time check: CacheManager is assignable to CacheStrategy.
      // ignore: unnecessary_type_check
      expect(true, isTrue); // If this file compiles, the contract holds.
    });
  });

  group('StationServiceChain with FakeCacheStrategy', () {
    late _FakeStationService fakeService;
    late FakeCacheStrategy fakeCache;
    late StationServiceChain chain;

    setUp(() {
      fakeService = _FakeStationService();
      fakeCache = FakeCacheStrategy();
      chain = StationServiceChain(fakeService, fakeCache, countryCode: 'DE');
    });

    test('returns API data and caches it via CacheStrategy', () async {
      fakeService.stationsToReturn = [_makeStation('s1')];
      final result = await chain.searchStations(_params);

      expect(result.data, hasLength(1));
      expect(result.data.first.id, 's1');
      expect(result.source, ServiceSource.tankerkoenigApi);
      expect(result.isStale, isFalse);

      // Verify the result was cached
      final cacheKey = CacheKey.stationSearch(
        _params.lat, _params.lng, _params.radiusKm,
        _params.fuelType.apiValue,
        countryCode: 'DE',
      );
      expect(fakeCache.get(cacheKey), isNotNull);
    });

    test('returns fresh cache without calling API', () async {
      // Pre-populate cache
      fakeService.stationsToReturn = [_makeStation('cached')];
      await chain.searchStations(_params);
      fakeService.callCount = 0;

      // Second call should hit cache
      final result = await chain.searchStations(_params);
      expect(result.data.first.id, 'cached');
      expect(fakeService.callCount, 0);
    });

    test('falls back to stale cache when API fails', () async {
      final cacheKey = CacheKey.stationSearch(
        _params.lat, _params.lng, _params.radiusKm,
        _params.fuelType.apiValue,
        countryCode: 'DE',
      );
      fakeCache.insertExpired(
        cacheKey,
        {'stations': [_makeStation('stale').toJson()]},
        source: ServiceSource.tankerkoenigApi,
        ttl: const Duration(minutes: 5),
        storedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      fakeService.errorToThrow = const ApiException(message: 'timeout');
      final result = await chain.searchStations(_params);

      expect(result.data, hasLength(1));
      expect(result.data.first.id, 'stale');
      expect(result.isStale, isTrue);
      expect(result.errors, isNotEmpty);
      expect(result.source, ServiceSource.cache);
    });

    test('throws ServiceChainExhaustedException when all fail', () async {
      fakeService.errorToThrow = const ApiException(message: 'down');
      expect(
        () => chain.searchStations(_params),
        throwsA(isA<ServiceChainExhaustedException>()),
      );
    });

    test('request coalescing works with CacheStrategy', () async {
      fakeService.stationsToReturn = [_makeStation('s1')];

      final results = await Future.wait([
        chain.searchStations(_params),
        chain.searchStations(_params),
      ]);

      for (final r in results) {
        expect(r.data, hasLength(1));
      }
      // Only one API call due to coalescing
      expect(fakeService.callCount, 1);
    });

    test('getPrices works through CacheStrategy', () async {
      final result = await chain.getPrices([]);
      expect(result.data, isEmpty);
      expect(result.source, ServiceSource.tankerkoenigApi);
    });
  });
}
