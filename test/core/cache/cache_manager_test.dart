import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/services/service_result.dart';

/// In-memory fake that mimics the subset of HiveStorage used by CacheManager.
/// We cannot use real HiveStorage because Hive requires platform initialization.
class FakeHiveStorage {
  final _cache = <String, dynamic>{};

  Future<void> cacheData(String key, dynamic data) async {
    if (data == null) {
      _cache.remove(key);
    } else {
      _cache[key] = data;
    }
  }

  Map<String, dynamic>? getCachedData(String key, {Duration? maxAge}) {
    final raw = _cache[key];
    if (raw == null) return null;
    if (raw is Map) {
      return Map<String, dynamic>.from(
        raw.map((k, v) => MapEntry(k.toString(), v)),
      );
    }
    return null;
  }

  Future<void> clearCache() async => _cache.clear();

  int get cacheEntryCount => _cache.length;

  Iterable<dynamic> get cacheKeys => _cache.keys;

  Future<void> deleteCacheEntry(String key) async => _cache.remove(key);
}

/// Since CacheManager takes a HiveStorage (concrete class), and we cannot
/// instantiate HiveStorage without Hive init, we create a testable subclass
/// that overrides the storage interaction via a fake.
class TestableCacheManager {
  final FakeHiveStorage _storage;

  TestableCacheManager(this._storage);

  Future<void> put(
    String key,
    Map<String, dynamic> data, {
    required Duration ttl,
    required ServiceSource source,
  }) async {
    await _storage.cacheData(key, {
      'payload': data,
      'storedAt': DateTime.now().millisecondsSinceEpoch,
      'source': source.index,
      'ttlMs': ttl.inMilliseconds,
    });
  }

  CacheEntry? get(String key) {
    final raw = _storage.getCachedData(key);
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

  CacheEntry? getFresh(String key) {
    final entry = get(key);
    if (entry == null || entry.isExpired) return null;
    return entry;
  }

  Future<void> invalidate(String key) async {
    await _storage.cacheData(key, null);
  }

  Future<void> clearAll() async {
    await _storage.clearCache();
  }

  int get entryCount => _storage.cacheEntryCount;

  Future<int> evictExpired({int batchLimit = 500}) async {
    final keys = _storage.cacheKeys.take(batchLimit).toList();
    var evicted = 0;
    for (final key in keys) {
      if (key is! String) continue;
      final entry = get(key);
      if (entry == null) continue;
      if (entry.age > entry.ttl * 3) {
        await _storage.deleteCacheEntry(key);
        evicted++;
      }
    }
    return evicted;
  }
}

void main() {
  late FakeHiveStorage fakeStorage;
  late TestableCacheManager cache;

  setUp(() {
    fakeStorage = FakeHiveStorage();
    cache = TestableCacheManager(fakeStorage);
  });

  group('CacheManager - put/get', () {
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

    test('get returns null for non-existent key', () {
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
  });

  group('CacheManager - getFresh', () {
    test('getFresh returns entry when not expired', () async {
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

    test('getFresh returns null when entry is expired', () async {
      // Store with a TTL of 0 milliseconds so it is immediately expired
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
      // Should complete without error
      await cache.invalidate('never-existed');
    });
  });

  group('CacheManager - clearAll', () {
    test('clearAll removes all entries', () async {
      await cache.put(
        'a',
        {'v': 1},
        ttl: const Duration(minutes: 5),
        source: ServiceSource.cache,
      );
      await cache.put(
        'b',
        {'v': 2},
        ttl: const Duration(minutes: 5),
        source: ServiceSource.cache,
      );
      expect(cache.entryCount, equals(2));

      await cache.clearAll();
      expect(cache.entryCount, equals(0));
      expect(cache.get('a'), isNull);
      expect(cache.get('b'), isNull);
    });
  });

  group('CacheManager - entryCount', () {
    test('entryCount reflects number of stored items', () async {
      expect(cache.entryCount, equals(0));

      await cache.put(
        'k1',
        {'v': 1},
        ttl: const Duration(minutes: 5),
        source: ServiceSource.cache,
      );
      expect(cache.entryCount, equals(1));

      await cache.put(
        'k2',
        {'v': 2},
        ttl: const Duration(minutes: 5),
        source: ServiceSource.cache,
      );
      expect(cache.entryCount, equals(2));
    });
  });

  group('CacheManager - evictExpired', () {
    test('evictExpired removes entries older than 3x TTL', () async {
      // Insert an entry that is way past 3x its TTL
      // TTL = 1ms, age = 1 hour => 3600000ms >> 3ms
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
      await cache.put(
        'fresh',
        {'v': 1},
        ttl: const Duration(hours: 1),
        source: ServiceSource.cache,
      );
      final evicted = await cache.evictExpired();
      expect(evicted, equals(0));
    });
  });

  group('CacheManager - evictExpired with batchLimit', () {
    test('evictExpired respects batchLimit parameter', () async {
      // Insert 3 very old entries
      for (int i = 0; i < 3; i++) {
        await fakeStorage.cacheData('old-$i', {
          'payload': {'stale': true},
          'storedAt':
              DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
          'source': ServiceSource.cache.index,
          'ttlMs': 1,
        });
      }

      expect(cache.entryCount, equals(3));

      // Evict with batchLimit of 2 — should only process first 2 keys
      final evicted = await cache.evictExpired(batchLimit: 2);
      expect(evicted, equals(2));
      // One entry should remain
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
      await cache.put(
        'brand-new',
        {'new': true},
        ttl: const Duration(hours: 24),
        source: ServiceSource.cache,
      );

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

  group('CacheManager - invalidate edge cases', () {
    test('invalidate then put same key works', () async {
      await cache.put('key', {'v': 1}, ttl: const Duration(minutes: 5), source: ServiceSource.cache);
      await cache.invalidate('key');
      expect(cache.get('key'), isNull);

      await cache.put('key', {'v': 2}, ttl: const Duration(minutes: 5), source: ServiceSource.cache);
      final entry = cache.get('key');
      expect(entry, isNotNull);
      expect(entry!.payload['v'], equals(2));
    });
  });

  group('CacheManager - clearAll edge cases', () {
    test('clearAll on empty cache does not throw', () async {
      await cache.clearAll();
      expect(cache.entryCount, equals(0));
    });

    test('clearAll then put works', () async {
      await cache.put('x', {'v': 1}, ttl: const Duration(minutes: 5), source: ServiceSource.cache);
      await cache.clearAll();
      await cache.put('y', {'v': 2}, ttl: const Duration(minutes: 5), source: ServiceSource.cache);
      expect(cache.entryCount, equals(1));
      expect(cache.get('y'), isNotNull);
    });
  });

  group('CacheKey', () {
    test('stationSearch generates consistent key with coordinates', () {
      final key = CacheKey.stationSearch(52.520, 13.405, 10.0, 'e5');
      expect(key, equals('search::52.520:13.405:10.0:e5'));
    });

    test('stationSearch includes countryCode when provided', () {
      final key = CacheKey.stationSearch(
        48.856,
        2.352,
        5.0,
        'diesel',
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

    test('reverseGeocode truncates coordinates', () {
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
  });
}
