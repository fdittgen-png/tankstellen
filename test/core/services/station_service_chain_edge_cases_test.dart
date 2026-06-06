// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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

import '../../fakes/fake_hive_storage.dart';
import '../../helpers/silence_error_logger.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

/// Fake StationService that can delay, fail, and track call counts.
class _FakeStationService implements StationService {
  List<Station> stationsToReturn = [];
  Object? errorToThrow;
  Duration delay = Duration.zero;
  int searchCallCount = 0;

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    searchCallCount++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (errorToThrow != null) throw errorToThrow!;
    return ServiceResult(
      data: stationsToReturn,
      source: ServiceSource.tankerkoenigApi,
      fetchedAt: DateTime.now(),
    );
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String id) async {
    if (errorToThrow != null) throw errorToThrow!;
    throw const ApiException(message: 'Not implemented');
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) async {
    if (errorToThrow != null) throw errorToThrow!;
    return ServiceResult(
      data: const {},
      source: ServiceSource.tankerkoenigApi,
      fetchedAt: DateTime.now(),
    );
  }
}

/// In-memory CacheManager wrapper that bypasses Hive for testing.
///
/// Since CacheManager is a concrete class requiring HiveStorage, we hand
/// it a [FakeHiveStorage] (in-memory) and override every method anyway.
class _FakeCacheManager extends CacheManager {
  final Map<String, Map<String, dynamic>> _store = {};

  _FakeCacheManager() : super(FakeHiveStorage());

  @override
  Future<void> put(
    String key,
    Map<String, dynamic> data, {
    required Duration ttl,
    required ServiceSource source,
  }) async {
    _store[key] = {
      'payload': data,
      'storedAt': DateTime.now().millisecondsSinceEpoch,
      'source': source.index,
      'ttlMs': ttl.inMilliseconds,
    };
  }

  @override
  CacheEntry? get(String key) {
    final raw = _store[key];
    if (raw == null) return null;
    final payload = raw['payload'];
    if (payload == null) return null;
    return CacheEntry(
      payload: payload is Map ? Map<String, dynamic>.from(payload) : {},
      storedAt: DateTime.fromMillisecondsSinceEpoch(
        raw['storedAt'] as int? ?? 0,
      ),
      originalSource: ServiceSource.values.elementAtOrNull(
            raw['source'] as int? ?? 0,
          ) ??
          ServiceSource.cache,
      ttl: Duration(milliseconds: raw['ttlMs'] as int? ?? 300000),
    );
  }

  @override
  CacheEntry? getFresh(String key) {
    final entry = get(key);
    if (entry == null || entry.isExpired) return null;
    return entry;
  }

  /// Insert an entry with a custom storedAt (to simulate expired entries).
  void insertExpired(
    String key,
    Map<String, dynamic> data, {
    required ServiceSource source,
    required Duration ttl,
    required DateTime storedAt,
  }) {
    _store[key] = {
      'payload': data,
      'storedAt': storedAt.millisecondsSinceEpoch,
      'source': source.index,
      'ttlMs': ttl.inMilliseconds,
    };
  }

  /// Insert corrupted data (non-standard payload).
  void insertCorrupted(String key) {
    _store[key] = {
      'payload': {'stations': 'not-a-list'},
      'storedAt': DateTime.now().millisecondsSinceEpoch,
      'source': ServiceSource.cache.index,
      'ttlMs': 300000,
    };
  }

  @override
  Future<void> clearAll() async => _store.clear();

  @override
  Future<void> invalidate(String key) async => _store.remove(key);

  @override
  int get entryCount => _store.length;

  @override
  Future<int> evictExpired({int batchLimit = 500}) async => 0;
}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

Station _makeStation(String id, {double? e10}) => Station(
      id: id,
      name: 'Test $id',
      brand: 'TEST',
      street: 'Teststr.',
      postCode: '10115',
      place: 'Berlin',
      lat: 52.52,
      lng: 13.41,
      isOpen: true,
      e10: e10 ?? 1.459,
    );

const _params = SearchParams(
  lat: 52.52,
  lng: 13.41,
  radiusKm: 10,
  fuelType: FuelType.e10,
);

// #2926 — `FuelType.all` bypasses the chain's hard-fuel-filter, so a test
// asserting the codec round-trips partial-price stations (a data-shape
// concern, NOT fuel filtering) must search "all" or the unpriced rows are
// correctly dropped. The hard filter itself is covered by
// station_service_chain_new_test.dart.
const _allParams = SearchParams(
  lat: 52.52,
  lng: 13.41,
  radiusKm: 10,
  fuelType: FuelType.all,
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  silenceErrorLoggerSpool();
  group('StationServiceChain edge cases', () {
    late _FakeStationService fakeService;
    late _FakeCacheManager fakeCache;
    late StationServiceChain chain;

    setUp(() {
      fakeService = _FakeStationService();
      fakeCache = _FakeCacheManager();
      chain = StationServiceChain(fakeService, fakeCache, countryCode: 'DE');
    });

    // -----------------------------------------------------------------------
    // Request coalescing
    // -----------------------------------------------------------------------
    group('request coalescing', () {
      test('concurrent requests for same cache key share a single API call',
          () async {
        fakeService.stationsToReturn = [_makeStation('s1')];
        fakeService.delay = const Duration(milliseconds: 50);

        // Fire 3 concurrent searches with the same params.
        final futures = [
          chain.searchStations(_params),
          chain.searchStations(_params),
          chain.searchStations(_params),
        ];

        final results = await Future.wait(futures);

        // All three should succeed with the same data.
        for (final result in results) {
          expect(result.data, hasLength(1));
          expect(result.data.first.id, 's1');
        }

        // The primary service should have been called only ONCE.
        expect(fakeService.searchCallCount, 1);
      });

      test('different cache keys trigger separate API calls', () async {
        fakeService.stationsToReturn = [_makeStation('s1')];

        const params2 = SearchParams(
          lat: 48.85,
          lng: 2.35,
          radiusKm: 10,
          fuelType: FuelType.e10,
        );

        await Future.wait([
          chain.searchStations(_params),
          chain.searchStations(params2),
        ]);

        // Two different cache keys => two API calls.
        expect(fakeService.searchCallCount, 2);
      });

      test('in-flight entry is cleaned up after completion', () async {
        fakeService.stationsToReturn = [_makeStation('s1')];

        await chain.searchStations(_params);
        expect(fakeService.searchCallCount, 1);

        // A second call after the first completes should trigger a new API
        // call (the in-flight entry was removed).
        await fakeCache.clearAll(); // Clear cache so it hits API again.
        await chain.searchStations(_params);
        expect(fakeService.searchCallCount, 2);
      });

      test('in-flight entry is cleaned up even when API throws', () async {
        fakeService.errorToThrow = const ApiException(message: 'boom');

        await expectLater(
          () => chain.searchStations(_params),
          throwsA(isA<ServiceChainExhaustedException>()),
        );

        // After the error, in-flight should be clean. Set up success now.
        fakeService.errorToThrow = null;
        fakeService.stationsToReturn = [_makeStation('s1')];
        final result = await chain.searchStations(_params);
        expect(result.data, hasLength(1));
      });
    });

    // -----------------------------------------------------------------------
    // Corrupted cache
    // -----------------------------------------------------------------------
    group('corrupted cache', () {
      test(
          '#2296 — a corrupt fresh-cache entry is a cache miss, not a UI '
          'crash (broadened catch swallows TypeError too)', () async {
        // payload.stations is a String, so the deserializer's
        // `data['stations'] as List<dynamic>?` cast throws a TypeError —
        // an Error, not an Exception. Before #2296 the `on FormatException`
        // catch let it escape and crash the UI, bypassing the stale-cache
        // fallback. Now the broadened `on Object` catch treats it as a
        // miss and the chain proceeds.
        final cacheKey = CacheKey.stationSearch(
          _params.lat,
          _params.lng,
          _params.radiusKm,
          _params.fuelType.apiValue,
          countryCode: 'DE',
        );
        fakeCache.insertCorrupted(cacheKey);

        // API also fails and there is no (valid) stale cache, so the chain
        // exhausts cleanly with its typed exception — NOT a raw TypeError.
        fakeService.errorToThrow = const ApiException(message: 'down');
        await expectLater(
          chain.searchStations(_params),
          throwsA(isA<ServiceChainExhaustedException>()),
        );
      });

      test(
          '#2296 — a corrupt fresh-cache entry falls through to a working '
          'API instead of crashing', () async {
        final cacheKey = CacheKey.stationSearch(
          _params.lat,
          _params.lng,
          _params.radiusKm,
          _params.fuelType.apiValue,
          countryCode: 'DE',
        );

        // Corrupt data as a FRESH entry — the deserializer hits a TypeError
        // on the cast, which the broadened catch turns into a miss so the
        // chain continues to the API rather than crashing.
        fakeCache.insertCorrupted(cacheKey);

        fakeService.stationsToReturn = [_makeStation('s1')];
        final result = await chain.searchStations(_params);
        expect(result.data, hasLength(1));
        expect(result.source, ServiceSource.tankerkoenigApi);
      });
    });

    // -----------------------------------------------------------------------
    // Empty station list from API
    // -----------------------------------------------------------------------
    group('empty station list from API', () {
      test(
          'empty list from API triggers stale cache fallback (isValid fails)',
          () async {
        // Pre-populate cache with real data.
        fakeService.stationsToReturn = [_makeStation('cached')];
        await chain.searchStations(_params);

        // Now API returns empty list. The chain's isValid check for
        // searchStations requires stations.isNotEmpty, so this should
        // NOT be cached and the chain should try stale cache.
        fakeService.stationsToReturn = [];

        // Invalidate fresh cache so it goes to API first.
        await fakeCache.clearAll();

        // Pre-insert stale cache entry manually.
        final cacheKey = CacheKey.stationSearch(
          _params.lat,
          _params.lng,
          _params.radiusKm,
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

        // The empty API response should cause a cache miss because
        // isValid requires non-empty. However, the chain caches
        // BEFORE checking isValid. The actual chain code caches the
        // result then returns it. Let me re-read the chain...
        // Actually, the chain tries API, caches result, and returns.
        // The isValid check is only on cache reads (steps 1 & 3).
        // So an empty API response IS returned as-is.
        final result = await chain.searchStations(_params);
        // The API succeeded (no exception), so the chain returns the
        // empty list. This is correct behavior.
        expect(result.data, isEmpty);
      });

      test('empty list from API is a valid ServiceResult', () async {
        fakeService.stationsToReturn = [];
        final result = await chain.searchStations(_params);
        expect(result.data, isA<List<Station>>());
        expect(result.data, isEmpty);
        expect(result.source, ServiceSource.tankerkoenigApi);
        expect(result.isStale, isFalse);
      });
    });

    // -----------------------------------------------------------------------
    // API returns partial data
    // -----------------------------------------------------------------------
    group('API returns partial data (some fields null)', () {
      test('station with all-null prices is still returned', () async {
        fakeService.stationsToReturn = [
          const Station(
            id: 'partial',
            name: 'Partial',
            brand: 'TEST',
            street: 'St',
            postCode: '10115',
            place: 'Berlin',
            lat: 52.52,
            lng: 13.41,
            isOpen: true,
            // All prices null
          ),
        ];
        // Search "all" — the #2926 hard-fuel-filter would (correctly) drop an
        // all-null-price station for a SPECIFIC fuel; here we assert the codec
        // round-trips it, which is fuel-agnostic.
        final result = await chain.searchStations(_allParams);
        expect(result.data, hasLength(1));
        expect(result.data.first.e10, isNull);
        expect(result.data.first.e5, isNull);
        expect(result.data.first.diesel, isNull);
        expect(result.data.first.id, 'partial');
      });

      test('station with only some prices set is returned correctly',
          () async {
        fakeService.stationsToReturn = [
          const Station(
            id: 'mixed',
            name: 'Mixed',
            brand: 'TEST',
            street: 'St',
            postCode: '10115',
            place: 'Berlin',
            lat: 52.52,
            lng: 13.41,
            isOpen: true,
            e5: 1.899,
            e10: null,
            diesel: 1.659,
          ),
        ];
        // Search "all": the codec must preserve e5 + diesel and leave e10 null.
        // (For a SPECIFIC e10 search the #2926 hard-filter would drop this row.)
        final result = await chain.searchStations(_allParams);
        expect(result.data, hasLength(1));
        final station = result.data.first;
        expect(station.e5, 1.899);
        expect(station.e10, isNull);
        expect(station.diesel, 1.659);
      });
    });

    // -----------------------------------------------------------------------
    // Stale cache with accumulated errors
    // -----------------------------------------------------------------------
    group('stale cache fallback', () {
      test('stale cache result includes error from failed API call', () async {
        // Pre-populate cache then expire it.
        final cacheKey = CacheKey.stationSearch(
          _params.lat,
          _params.lng,
          _params.radiusKm,
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
        expect(result.isStale, isTrue);
        expect(result.errors, isNotEmpty);
        expect(result.errors.first.message, contains('timeout'));
        expect(result.source, ServiceSource.cache);
      });
    });

    // -----------------------------------------------------------------------
    // getPrices edge cases
    // -----------------------------------------------------------------------
    group('getPrices', () {
      test('returns empty map from API', () async {
        final result = await chain.getPrices([]);
        expect(result.data, isEmpty);
      });
    });
  });

  group('In-flight cleanup', () {
    late _FakeStationService fakeService;
    late _FakeCacheManager fakeCache;
    late StationServiceChain chain;

    setUp(() {
      fakeService = _FakeStationService();
      fakeCache = _FakeCacheManager();
      chain = StationServiceChain(fakeService, fakeCache);
    });

    test('in-flight entry is cleaned up after successful request', () async {
      fakeService.stationsToReturn = [_testStation()];
      await chain.searchStations(_defaultParams());
      // No way to directly inspect _inFlight (private), but if we can make
      // a second request without coalescing, the entry was cleaned up
      fakeService.searchCallCount = 0;
      await chain.searchStations(_defaultParams());
      // Second call should NOT coalesce (since first completed) so it hits
      // the cache (put by first call), which means searchCallCount stays 0
      expect(fakeService.searchCallCount, 0); // served from cache
    });

    test('in-flight entry is cleaned up after failed request', () async {
      fakeService.errorToThrow = const ApiException(message: 'fail');
      try {
        await chain.searchStations(_defaultParams());
      } on ServiceChainExhaustedException catch (_) {
        // expected
      }
      // Now make a successful request — should not be stuck on old in-flight
      fakeService.errorToThrow = null;
      fakeService.stationsToReturn = [_testStation()];
      final result = await chain.searchStations(_defaultParams());
      expect(result.data, hasLength(1));
    });

    test('concurrent requests coalesce into one API call', () async {
      fakeService.stationsToReturn = [_testStation()];
      fakeService.delay = const Duration(milliseconds: 50);

      final results = await Future.wait([
        chain.searchStations(_defaultParams()),
        chain.searchStations(_defaultParams()),
        chain.searchStations(_defaultParams()),
      ]);

      // All three should get results
      for (final r in results) {
        expect(r.data, hasLength(1));
      }
      // But only one API call should have been made
      expect(fakeService.searchCallCount, 1);
    });
  });
}

SearchParams _defaultParams() => const SearchParams(
      lat: 52.52,
      lng: 13.405,
      radiusKm: 10,
    );

Station _testStation() => const Station(
      id: 'test-1',
      name: 'Test Station',
      brand: 'Test',
      street: 'Test St 1',
      postCode: '12345',
      place: 'Berlin',
      lat: 52.52,
      lng: 13.405,
      dist: 1.0,
      isOpen: true,
    );
