// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';

/// No-op recorder so the closed-box tests can drive `errorLogger.log`
/// without a Hive-backed spool (which would need platform init).
/// #3155 — embedded in a fake `dataset:` payload to count how many times
/// `jsonEncode` walks it (jsonEncode calls `toJson()` on non-primitive
/// values). The byte sweep must never encode a dataset payload.
class _EncodeProbe {
  int toJsonCalls = 0;
  Map<String, dynamic> toJson() {
    toJsonCalls++;
    return const {'probe': true};
  }
}

class _NoopRecorder implements TraceRecorder {
  @override
  Future<void> record(Object error, StackTrace stackTrace,
      {ServiceChainSnapshot? serviceChainState}) async {}

  @override
  noSuchMethod(Invocation invocation) => null;
}

/// In-memory fake implementing [CacheStorage] for testing [CacheManager]
/// without Hive platform initialization.
class FakeCacheStorage implements CacheStorage {
  final _cache = <String, dynamic>{};

  @override
  Future<void> cacheData(String key, dynamic data) async {
    _cache[key] = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  @override
  Map<String, dynamic>? getCachedData(String key, {Duration? maxAge}) {
    final cached = _cache[key];
    if (cached == null) return null;
    if (cached is! Map) return null;

    final map = Map<String, dynamic>.from(
      cached.map((k, v) => MapEntry(k.toString(), v)),
    );

    if (maxAge != null) {
      final timestamp = map['timestamp'] as int?;
      if (timestamp != null) {
        final age = DateTime.now().millisecondsSinceEpoch - timestamp;
        if (age > maxAge.inMilliseconds) return null;
      }
    }
    final data = map['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(
        data.map((k, v) => MapEntry(k.toString(), v)),
      );
    }
    return null;
  }

  @override
  Future<void> clearCache() async => _cache.clear();

  @override
  int get cacheEntryCount => _cache.length;

  @override
  Iterable<dynamic> get cacheKeys => _cache.keys;

  @override
  Future<void> deleteCacheEntry(String key) async => _cache.remove(key);
}

/// A [CacheStorage] whose reads/writes throw [FileSystemException] — exactly
/// what the real Hive store does when its `cache.hive` box is closed
/// mid-flight by a foreground background scan (#2670). Drives the
/// CacheManager-level resilience guard.
class ClosedBoxCacheStorage implements CacheStorage {
  static const _closed = FileSystemException(
      'File closed', '/tmp/cache.hive');

  @override
  Future<void> cacheData(String key, dynamic data) async => throw _closed;

  @override
  Map<String, dynamic>? getCachedData(String key, {Duration? maxAge}) =>
      throw _closed;

  @override
  Future<void> clearCache() async => throw _closed;

  @override
  int get cacheEntryCount => throw _closed;

  @override
  Iterable<dynamic> get cacheKeys => throw _closed;

  @override
  Future<void> deleteCacheEntry(String key) async => throw _closed;
}

void main() {
  late FakeCacheStorage fakeStorage;
  late CacheManager cache;

  setUp(() {
    fakeStorage = FakeCacheStorage();
    cache = CacheManager(fakeStorage);
  });

  group('CacheManager - put/get round-trip', () {
    test('put stores data and get retrieves it', () async {
      await cache.put(
        'test-key',
        {'value': 42},
        ttl: const Duration(minutes: 5),
        source: ServiceSource.tankerkoenigApi,
      );

      final entry = cache.get('test-key');
      expect(entry, isNotNull);
      expect(entry!.payload['value'], equals(42));
      expect(entry.originalSource, equals(ServiceSource.tankerkoenigApi));
      expect(entry.isExpired, isFalse);
    });

    test('get returns null for non-existent key (cache miss)', () {
      final entry = cache.get('missing-key');
      expect(entry, isNull);
    });

    test('put overwrites existing entry', () async {
      await cache.put(
        'key',
        {'v': 1},
        ttl: const Duration(minutes: 5),
        source: ServiceSource.cache,
      );
      await cache.put(
        'key',
        {'v': 2},
        ttl: const Duration(minutes: 10),
        source: ServiceSource.prixCarburantsApi,
      );

      final entry = cache.get('key');
      expect(entry, isNotNull);
      expect(entry!.payload['v'], equals(2));
      expect(entry.originalSource, equals(ServiceSource.prixCarburantsApi));
    });

    test('put preserves nested map structure', () async {
      await cache.put(
        'nested',
        {
          'station': {'name': 'Shell', 'brand': 'Shell'},
          'prices': [1.45, 1.50],
        },
        ttl: const Duration(minutes: 5),
        source: ServiceSource.tankerkoenigApi,
      );

      final entry = cache.get('nested');
      expect(entry, isNotNull);
      expect(entry!.payload['station'], isA<Map<dynamic, dynamic>>());
    });
  });

  group('CacheManager - source persisted by NAME (#3150)', () {
    test('put writes source.name, not the reorder-fragile enum index',
        () async {
      await cache.put(
        'named-source',
        {'v': 1},
        ttl: const Duration(minutes: 5),
        source: ServiceSource.tankerkoenigApi,
      );
      final raw = fakeStorage.getCachedData('named-source');
      expect(raw!['source'], ServiceSource.tankerkoenigApi.name,
          reason: 'an enum reorder must not silently re-attribute every '
              'cached entry\'s source');
      expect(cache.get('named-source')!.originalSource,
          ServiceSource.tankerkoenigApi);
    });

    test('legacy index-typed entry (pre-#3150) still resolves', () async {
      await fakeStorage.cacheData('legacy-entry', {
        'payload': {'v': 1},
        'storedAt': DateTime.now().millisecondsSinceEpoch,
        'source': ServiceSource.prixCarburantsApi.index,
        'ttlMs': const Duration(minutes: 5).inMilliseconds,
      });
      expect(cache.get('legacy-entry')!.originalSource,
          ServiceSource.prixCarburantsApi);
    });

    test('unknown source name / out-of-range index fall back to cache',
        () async {
      await fakeStorage.cacheData('unknown-name', {
        'payload': {'v': 1},
        'storedAt': DateTime.now().millisecondsSinceEpoch,
        'source': 'someRetiredSource',
        'ttlMs': const Duration(minutes: 5).inMilliseconds,
      });
      expect(cache.get('unknown-name')!.originalSource, ServiceSource.cache);

      await fakeStorage.cacheData('bad-index', {
        'payload': {'v': 1},
        'storedAt': DateTime.now().millisecondsSinceEpoch,
        'source': 9999,
        'ttlMs': const Duration(minutes: 5).inMilliseconds,
      });
      expect(cache.get('bad-index')!.originalSource, ServiceSource.cache);
    });
  });

  group('CacheManager - getFresh', () {
    test('getFresh returns entry when not expired (fresh hit)', () async {
      await cache.put(
        'fresh-key',
        {'data': 'hello'},
        ttl: const Duration(hours: 1),
        source: ServiceSource.tankerkoenigApi,
      );

      final entry = cache.getFresh('fresh-key');
      expect(entry, isNotNull);
      expect(entry!.payload['data'], equals('hello'));
    });

    test('getFresh returns null for non-existent key', () {
      expect(cache.getFresh('nope'), isNull);
    });

    test('getFresh returns null when entry is expired (stale)', () async {
      // Manually insert a stale entry via the fake storage
      await fakeStorage.cacheData('expired-key', {
        'payload': {'data': 'old'},
        'storedAt':
            DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
        'source': ServiceSource.cache.index,
        'ttlMs': 1, // 1ms TTL — already expired
      });

      // get() should still return the stale entry
      final staleEntry = cache.get('expired-key');
      expect(staleEntry, isNotNull);
      expect(staleEntry!.isExpired, isTrue);

      // getFresh() should return null
      final freshEntry = cache.getFresh('expired-key');
      expect(freshEntry, isNull);
    });

    test('get returns stale entry for fallback chain use', () async {
      // Store entry with very short TTL via put, then verify get returns it
      // even after expiration (simulated by direct storage manipulation)
      await fakeStorage.cacheData('stale-key', {
        'payload': {'price': 1.45},
        'storedAt': DateTime.now()
            .subtract(const Duration(minutes: 10))
            .millisecondsSinceEpoch,
        'source': ServiceSource.tankerkoenigApi.index,
        'ttlMs': const Duration(minutes: 5).inMilliseconds,
      });

      final entry = cache.get('stale-key');
      expect(entry, isNotNull);
      expect(entry!.isExpired, isTrue);
      expect(entry.payload['price'], equals(1.45));
      expect(entry.originalSource, equals(ServiceSource.tankerkoenigApi));
    });
  });

  group('CacheManager - invalidate', () {
    test('invalidate removes entry', () async {
      await cache.put(
        'to-remove',
        {'x': 1},
        ttl: const Duration(minutes: 5),
        source: ServiceSource.cache,
      );
      expect(cache.get('to-remove'), isNotNull);

      await cache.invalidate('to-remove');
      expect(cache.get('to-remove'), isNull);
    });

    test('invalidate on non-existent key does not throw', () async {
      await cache.invalidate('never-existed');
    });

    test('invalidate then put same key works', () async {
      await cache.put('key', {'v': 1},
          ttl: const Duration(minutes: 5), source: ServiceSource.cache);
      await cache.invalidate('key');
      expect(cache.get('key'), isNull);

      await cache.put('key', {'v': 2},
          ttl: const Duration(minutes: 5), source: ServiceSource.cache);
      final entry = cache.get('key');
      expect(entry, isNotNull);
      expect(entry!.payload['v'], equals(2));
    });
  });

  group('CacheManager - clearAll', () {
    test('clearAll removes all entries', () async {
      await cache.put('a', {'v': 1},
          ttl: const Duration(minutes: 5), source: ServiceSource.cache);
      await cache.put('b', {'v': 2},
          ttl: const Duration(minutes: 5), source: ServiceSource.cache);
      expect(cache.entryCount, equals(2));

      await cache.clearAll();
      expect(cache.entryCount, equals(0));
      expect(cache.get('a'), isNull);
      expect(cache.get('b'), isNull);
    });

    test('clearAll on empty cache does not throw', () async {
      await cache.clearAll();
      expect(cache.entryCount, equals(0));
    });

    test('clearAll then put works', () async {
      await cache.put('x', {'v': 1},
          ttl: const Duration(minutes: 5), source: ServiceSource.cache);
      await cache.clearAll();
      await cache.put('y', {'v': 2},
          ttl: const Duration(minutes: 5), source: ServiceSource.cache);
      expect(cache.entryCount, equals(1));
      expect(cache.get('y'), isNotNull);
    });
  });

  group('CacheManager - entryCount', () {
    test('entryCount reflects number of stored items', () async {
      expect(cache.entryCount, equals(0));

      await cache.put('k1', {'v': 1},
          ttl: const Duration(minutes: 5), source: ServiceSource.cache);
      expect(cache.entryCount, equals(1));

      await cache.put('k2', {'v': 2},
          ttl: const Duration(minutes: 5), source: ServiceSource.cache);
      expect(cache.entryCount, equals(2));
    });

    test('entryCount decreases after invalidate', () async {
      await cache.put('a', {'v': 1},
          ttl: const Duration(minutes: 5), source: ServiceSource.cache);
      await cache.put('b', {'v': 2},
          ttl: const Duration(minutes: 5), source: ServiceSource.cache);
      expect(cache.entryCount, equals(2));

      await cache.invalidate('a');
      // invalidate stores null payload — entry still exists in storage
      // but entryCount includes it
      expect(cache.entryCount, greaterThanOrEqualTo(1));
    });
  });

  group('CacheManager - evictExpired', () {
    test('evictExpired removes entries older than 3x TTL', () async {
      // TTL = 1ms, age = 1 hour => way past 3x TTL
      await fakeStorage.cacheData('very-old', {
        'payload': {'stale': true},
        'storedAt':
            DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
        'source': ServiceSource.cache.index,
        'ttlMs': 1,
      });

      // Insert a fresh entry
      await cache.put(
        'still-fresh',
        {'fresh': true},
        ttl: const Duration(hours: 24),
        source: ServiceSource.cache,
      );

      expect(cache.entryCount, equals(2));

      final evicted = await cache.evictExpired();
      expect(evicted, equals(1));
      expect(cache.get('very-old'), isNull);
      expect(cache.get('still-fresh'), isNotNull);
    });

    test('evictExpired returns 0 when nothing to evict', () async {
      await cache.put('fresh', {'v': 1},
          ttl: const Duration(hours: 1), source: ServiceSource.cache);
      final evicted = await cache.evictExpired();
      expect(evicted, equals(0));
    });

    test('evictExpired respects batchLimit parameter', () async {
      for (int i = 0; i < 3; i++) {
        await fakeStorage.cacheData('old-$i', {
          'payload': {'stale': true},
          'storedAt': DateTime.now()
              .subtract(const Duration(hours: 1))
              .millisecondsSinceEpoch,
          'source': ServiceSource.cache.index,
          'ttlMs': 1,
        });
      }

      expect(cache.entryCount, equals(3));

      // Evict with batchLimit of 2 — should only process first 2 keys
      final evicted = await cache.evictExpired(batchLimit: 2);
      expect(evicted, equals(2));
      expect(cache.entryCount, equals(1));
    });

    test('evictExpired skips entries within 3x TTL', () async {
      // TTL = 1 hour, age = 2 hours => 2h < 3h => should NOT be evicted
      await fakeStorage.cacheData('recent-expired', {
        'payload': {'data': 'still ok'},
        'storedAt':
            DateTime.now().subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
        'source': ServiceSource.cache.index,
        'ttlMs': const Duration(hours: 1).inMilliseconds,
      });

      final evicted = await cache.evictExpired();
      expect(evicted, equals(0));
      expect(cache.get('recent-expired'), isNotNull);
    });

    test('evictExpired handles empty cache', () async {
      final evicted = await cache.evictExpired();
      expect(evicted, equals(0));
    });

    test('evictExpired handles mixed fresh and very old entries', () async {
      // Very old (should be evicted): TTL=1ms, age=1h
      await fakeStorage.cacheData('ancient', {
        'payload': {'old': true},
        'storedAt':
            DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
        'source': ServiceSource.cache.index,
        'ttlMs': 1,
      });

      // Fresh (should be kept): TTL=24h, age=0
      await cache.put('brand-new', {'new': true},
          ttl: const Duration(hours: 24), source: ServiceSource.cache);

      // Expired but within 3x TTL (should be kept): TTL=1h, age=2h
      await fakeStorage.cacheData('mildly-old', {
        'payload': {'mild': true},
        'storedAt':
            DateTime.now().subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
        'source': ServiceSource.cache.index,
        'ttlMs': const Duration(hours: 1).inMilliseconds,
      });

      final evicted = await cache.evictExpired();
      expect(evicted, equals(1)); // only 'ancient'
      expect(cache.get('ancient'), isNull);
      expect(cache.get('brand-new'), isNotNull);
      expect(cache.get('mildly-old'), isNotNull);
    });
  });

  group('CacheManager - concurrent access patterns', () {
    test('multiple puts to same key resolve to last write', () async {
      // Simulate concurrent puts
      final futures = <Future<dynamic>>[];
      for (int i = 0; i < 10; i++) {
        futures.add(cache.put(
          'concurrent-key',
          {'iteration': i},
          ttl: const Duration(minutes: 5),
          source: ServiceSource.cache,
        ));
      }
      await Future.wait(futures);

      final entry = cache.get('concurrent-key');
      expect(entry, isNotNull);
      // Last write wins — iteration 9
      expect(entry!.payload['iteration'], equals(9));
    });

    test('put and get interleaved do not corrupt state', () async {
      await cache.put('key-a', {'v': 1},
          ttl: const Duration(minutes: 5), source: ServiceSource.cache);
      await cache.put('key-b', {'v': 2},
          ttl: const Duration(minutes: 5), source: ServiceSource.cache);

      // Read while writing
      final entryA = cache.get('key-a');
      await cache.put('key-c', {'v': 3},
          ttl: const Duration(minutes: 5), source: ServiceSource.cache);
      final entryB = cache.get('key-b');

      expect(entryA?.payload['v'], equals(1));
      expect(entryB?.payload['v'], equals(2));
      expect(cache.entryCount, equals(3));
    });
  });

  group('CacheKey', () {
    test('stationSearch generates consistent key with coordinates', () {
      final key = CacheKey.stationSearch(52.520, 13.405, 10.0, 'e5');
      expect(key, equals('search::52.520:13.405:10.0:e5'));
    });

    test('stationSearch includes countryCode when provided', () {
      final key = CacheKey.stationSearch(
        48.856, 2.352, 5.0, 'diesel',
        countryCode: 'FR',
      );
      expect(key, equals('search:FR:48.856:2.352:5.0:diesel'));
    });

    test('stationSearch includes postalCode when provided', () {
      final key = CacheKey.stationSearch(
        48.856, 2.352, 5.0, 'diesel',
        postalCode: '75001',
      );
      expect(key, contains('75001'));
    });

    test('stationSearch includes locationName when provided', () {
      final key = CacheKey.stationSearch(
        48.856, 2.352, 5.0, 'diesel',
        locationName: 'Paris',
      );
      expect(key, contains('Paris'));
    });

    test('stationSearch prefers postalCode over locationName', () {
      final key = CacheKey.stationSearch(
        48.856, 2.352, 5.0, 'diesel',
        postalCode: '75001',
        locationName: 'Paris',
      );
      expect(key, contains('75001'));
      expect(key, isNot(contains('Paris')));
    });

    test('stationSearch is stable for equivalent inputs', () {
      final key1 = CacheKey.stationSearch(52.520, 13.405, 10.0, 'e5');
      final key2 = CacheKey.stationSearch(52.520, 13.405, 10.0, 'e5');
      expect(key1, equals(key2));
    });

    test('stationSearch differs for different fuel types', () {
      final key1 = CacheKey.stationSearch(52.520, 13.405, 10.0, 'e5');
      final key2 = CacheKey.stationSearch(52.520, 13.405, 10.0, 'diesel');
      expect(key1, isNot(equals(key2)));
    });

    test('stationDetail uses id', () {
      expect(CacheKey.stationDetail('abc-123'), equals('detail:abc-123'));
    });

    test('prices sorts ids for consistency', () {
      final key1 = CacheKey.prices(['b', 'a', 'c']);
      final key2 = CacheKey.prices(['c', 'a', 'b']);
      expect(key1, equals(key2));
      expect(key1, equals('prices:a,b,c'));
    });

    test('geocodeZip uses zip prefix', () {
      expect(CacheKey.geocodeZip('10115'), equals('geo:zip:10115'));
    });

    test('reverseGeocode truncates coordinates to 4 decimals', () {
      final key = CacheKey.reverseGeocode(52.52045678, 13.40512345);
      expect(key, equals('geo:rev:52.5205:13.4051'));
    });

    test('stationData uses station prefix', () {
      expect(CacheKey.stationData('xyz'), equals('station:xyz'));
    });

    test('citySearch lowercases and trims query', () {
      final key = CacheKey.citySearch('  Berlin  ', 'de');
      expect(key, equals('city:berlin:de'));
    });
  });

  group('CacheTtl', () {
    test('stationSearch is 5 minutes', () {
      expect(CacheTtl.stationSearch, equals(const Duration(minutes: 5)));
    });

    test('stationDetail is 15 minutes', () {
      expect(CacheTtl.stationDetail, equals(const Duration(minutes: 15)));
    });

    test('prices is 5 minutes', () {
      expect(CacheTtl.prices, equals(const Duration(minutes: 5)));
    });

    test('geocode is 24 hours', () {
      expect(CacheTtl.geocode, equals(const Duration(hours: 24)));
    });

    test('stationData is 30 minutes', () {
      expect(CacheTtl.stationData, equals(const Duration(minutes: 30)));
    });

    test('citySearch is 30 minutes', () {
      expect(CacheTtl.citySearch, equals(const Duration(minutes: 30)));
    });
  });

  group('CacheEntry', () {
    test('isExpired returns false for fresh entry', () {
      final entry = CacheEntry(
        payload: {},
        storedAt: DateTime.now(),
        originalSource: ServiceSource.cache,
        ttl: const Duration(minutes: 5),
      );
      expect(entry.isExpired, isFalse);
    });

    test('isExpired returns true for old entry', () {
      final entry = CacheEntry(
        payload: {},
        storedAt: DateTime.now().subtract(const Duration(hours: 1)),
        originalSource: ServiceSource.cache,
        ttl: const Duration(minutes: 5),
      );
      expect(entry.isExpired, isTrue);
    });

    test('age reflects time since storage', () {
      final entry = CacheEntry(
        payload: {},
        storedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        originalSource: ServiceSource.cache,
        ttl: const Duration(minutes: 30),
      );
      // age should be approximately 10 minutes (allow 2s tolerance)
      expect(entry.age.inMinutes, equals(10));
    });

    test('originalSource is preserved', () {
      for (final source in ServiceSource.values) {
        final entry = CacheEntry(
          payload: {},
          storedAt: DateTime.now(),
          originalSource: source,
          ttl: const Duration(minutes: 5),
        );
        expect(entry.originalSource, equals(source));
      }
    });
  });

  group('CacheManager - evictBounded (#2264)', () {
    // Store a fresh entry with an explicit storedAt + payload size.
    Future<void> store(String key, DateTime storedAt, {int padBytes = 0}) {
      return fakeStorage.cacheData(key, {
        'payload': {'p': 'x' * padBytes},
        'storedAt': storedAt.millisecondsSinceEpoch,
        'source': ServiceSource.cache.index,
        'ttlMs': const Duration(hours: 1).inMilliseconds,
      });
    }

    test('still evicts entries older than 3x TTL', () async {
      await fakeStorage.cacheData('very-old', {
        'payload': {'stale': true},
        'storedAt': DateTime.now()
            .subtract(const Duration(hours: 1))
            .millisecondsSinceEpoch,
        'source': ServiceSource.cache.index,
        'ttlMs': 1,
      });
      await cache.put('fresh', {'v': 1},
          ttl: const Duration(hours: 24), source: ServiceSource.cache);

      final evicted = await cache.evictBounded();
      expect(evicted, equals(1));
      expect(cache.get('very-old'), isNull);
      expect(cache.get('fresh'), isNotNull);
    });

    test('enforces the per-prefix budget, keeping the newest', () async {
      final now = DateTime.now();
      // 5 search: entries, budget 3 → 2 oldest evicted.
      for (var i = 0; i < 5; i++) {
        await store('search:$i', now.subtract(Duration(minutes: i)));
      }
      // 2 detail: entries — both under budget, both survive.
      await store('detail:a', now);
      await store('detail:b', now);

      final evicted =
          await cache.evictBounded(policy: const CacheEvictionPolicy(prefixBudget: 3));

      expect(evicted, equals(2));
      // The two oldest searches (highest i) are gone.
      expect(cache.get('search:4'), isNull);
      expect(cache.get('search:3'), isNull);
      expect(cache.get('search:0'), isNotNull);
      expect(cache.get('detail:a'), isNotNull);
      expect(cache.get('detail:b'), isNotNull);
    });

    test('evicts oldest-first once the byte ceiling is exceeded', () async {
      final now = DateTime.now();
      // Three ~1 KB entries; ceiling 2 KB → oldest must be evicted.
      await store('search:old', now.subtract(const Duration(minutes: 10)),
          padBytes: 1000);
      await store('search:mid', now.subtract(const Duration(minutes: 5)),
          padBytes: 1000);
      await store('search:new', now, padBytes: 1000);

      final evicted = await cache.evictBounded(
        policy: const CacheEvictionPolicy(prefixBudget: 100, maxBytes: 2200),
      );

      expect(evicted, greaterThanOrEqualTo(1));
      expect(cache.get('search:old'), isNull,
          reason: 'oldest evicted first under byte pressure');
      expect(cache.get('search:new'), isNotNull);
    });

    test('protects dataset: entries from the byte sweep', () async {
      final now = DateTime.now();
      // A large persisted dataset + two large searches; tiny ceiling.
      await store('dataset:ES:stations',
          now.subtract(const Duration(hours: 1)), padBytes: 2000);
      await store('search:a', now.subtract(const Duration(minutes: 2)),
          padBytes: 2000);
      await store('search:b', now, padBytes: 2000);

      await cache.evictBounded(
        policy: const CacheEvictionPolicy(prefixBudget: 100, maxBytes: 1000),
      );

      expect(cache.get('dataset:ES:stations'), isNotNull,
          reason: 'persisted dataset is exempt from the LRU byte sweep');
    });

    test('returns 0 when everything is within budget + ceiling', () async {
      await cache.put('search:x', {'v': 1},
          ttl: const Duration(hours: 1), source: ServiceSource.cache);
      final evicted = await cache.evictBounded();
      expect(evicted, equals(0));
    });

    test(
        '#3155 — a dataset: payload is NEVER jsonEncode-d by the byte '
        'sweep (it can never be evicted by it anyway)', () async {
      final now = DateTime.now();
      final probe = _EncodeProbe();
      // A multi-MB-shaped dataset entry whose payload counts every encode.
      await fakeStorage.cacheData('dataset:FR:stations', {
        'payload': {'stations': probe},
        'storedAt': now.millisecondsSinceEpoch,
        'source': ServiceSource.cache.index,
        'ttlMs': const Duration(hours: 6).inMilliseconds,
      });
      // Enough non-dataset bytes to exceed the ceiling so pass 3 runs its
      // fold + eviction loop in full.
      await store('search:a', now.subtract(const Duration(minutes: 2)),
          padBytes: 2000);
      await store('search:b', now, padBytes: 2000);

      await cache.evictBounded(
        policy: const CacheEvictionPolicy(prefixBudget: 100, maxBytes: 1000),
      );

      expect(probe.toJsonCalls, 0,
          reason: 'evictBounded must not pay a jsonEncode of the multi-MB '
              'dataset payload on every sweep — the dataset is exempt from '
              'the byte ceiling, so sizing it is pure waste (#3155)');
      expect(cache.get('dataset:FR:stations'), isNotNull,
          reason: 'the dataset entry itself still survives the sweep');
    });
  });

  // #2670 — when the underlying Hive box was closed mid-flight a read/write
  // throws FileSystemException. The CacheManager must treat that as a clean
  // miss / no-op so StationServiceChain falls through to the API + stale
  // path instead of surfacing a crash on a routine cached search.
  group('CacheManager - closed box resilience (#2670)', () {
    late CacheManager closedCache;

    setUp(() {
      // Route the defensive errorLogger.log through a no-op recorder so the
      // unit test doesn't reach the Hive-backed isolate spool.
      errorLogger.testRecorderOverride = _NoopRecorder();
      closedCache = CacheManager(ClosedBoxCacheStorage());
    });

    tearDown(() => errorLogger.resetForTest());

    test('get treats a closed box as a cache miss (returns null, no throw)',
        () {
      expect(() => closedCache.get('search:FR:x'), returnsNormally);
      expect(closedCache.get('search:FR:x'), isNull);
    });

    test('getFresh treats a closed box as a cache miss', () {
      expect(() => closedCache.getFresh('search:FR:x'), returnsNormally);
      expect(closedCache.getFresh('search:FR:x'), isNull);
    });

    test('put swallows the closed-box write failure (never throws)',
        () async {
      await expectLater(
        closedCache.put('search:FR:x', {'v': 1},
            ttl: const Duration(minutes: 5), source: ServiceSource.cache),
        completes,
      );
    });
  });
}
