// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/constants/app_constants.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/services/service_result.dart';

/// #3219 → #3619 — the cache-freshness gate, schema edition.
///
/// Cached payloads are PARSED output, so a payload whose serialized shape
/// changed can embed the parser bug an update just fixed (#3219's field
/// shape: the #3224 FR hours fix invisible behind a fresh pre-fix entry).
/// The original gate busted on ANY appBuild mismatch — cold-booting every
/// cache, multi-MB country datasets included, on every release. #3619
/// narrows it: `getFresh` requires the entry's stamped [CacheSchema]
/// version to match the CURRENT registry — a cross-build entry with the
/// same schema serves fresh; only a schema bump (enforced by the
/// shape-pinning test) or a pre-stamp legacy envelope forces the one
/// re-fetch. `get` keeps serving everything to the stale/offline fallback.
class _FakeCacheStorage implements CacheStorage {
  final Map<String, dynamic> store = {};

  @override
  Future<void> cacheData(String key, dynamic data) async {
    if (data == null) {
      store.remove(key);
    } else {
      store[key] = data;
    }
  }

  @override
  Map<String, dynamic>? getCachedData(String key, {Duration? maxAge}) {
    final raw = store[key];
    if (raw is! Map) return null;
    return Map<String, dynamic>.from(raw);
  }

  @override
  Future<void> clearCache() async => store.clear();

  @override
  int get cacheEntryCount => store.length;

  @override
  Iterable<dynamic> get cacheKeys => store.keys;

  @override
  Future<void> deleteCacheEntry(String key) async => store.remove(key);
}

void main() {
  late _FakeCacheStorage storage;
  late CacheManager cache;

  setUp(() {
    storage = _FakeCacheStorage();
    cache = CacheManager(storage);
  });

  group('CacheManager schema freshness gate (#3619)', () {
    test('an entry written by THIS build is served fresh (no regression)',
        () async {
      AppConstants.setRuntimeVersion('6.0.0+TEST_BUILD_A');
      await cache.put('search:k', {'v': 1},
          ttl: const Duration(hours: 6),
          source: ServiceSource.prixCarburantsApi);

      final entry = cache.getFresh('search:k');
      expect(entry, isNotNull);
      expect(entry!.payload['v'], 1);
      expect(entry.appBuild, '6.0.0+TEST_BUILD_A');
      expect(entry.schemaVersion, CacheSchema.forKey('search:k'));
    });

    test(
        'an unexpired CROSS-BUILD entry with the CURRENT schema stays '
        'fresh — the #3619 point: updates no longer cold-boot the cache',
        () async {
      AppConstants.setRuntimeVersion('6.0.0+TEST_BUILD_A');
      await cache.put('dataset:AR:stations', {'v': 1},
          ttl: const Duration(days: 30),
          source: ServiceSource.prixCarburantsApi);

      // The app updates: same cache file, new build, SAME schema.
      AppConstants.setRuntimeVersion('6.0.0+TEST_BUILD_B');

      final entry = cache.getFresh('dataset:AR:stations');
      expect(entry, isNotNull,
          reason: 'same shape ⇒ the multi-MB dataset must survive the '
              'update instead of refetching on first launch');
      expect(entry!.appBuild, '6.0.0+TEST_BUILD_A');
    });

    test(
        'a STALE-SCHEMA entry is a fresh-miss but still serves the '
        'stale/offline fallback', () async {
      // Byte-shape of an envelope stamped by a build whose codec shape
      // predates a registry bump.
      storage.store['search:k'] = {
        'payload': {'v': 1},
        'storedAt': DateTime.now().millisecondsSinceEpoch,
        'source': ServiceSource.prixCarburantsApi.name,
        'ttlMs': const Duration(hours: 6).inMilliseconds,
        'appBuild': '6.0.0+TEST_BUILD_A',
        'schema': CacheSchema.forKey('search:k') + 1,
      };

      expect(cache.getFresh('search:k'), isNull,
          reason: 'a different schema version may embed the parser bug '
              'the bump documented — it must force a re-fetch');
      final stale = cache.get('search:k');
      expect(stale, isNotNull,
          reason: 'the stale/offline fallback must keep working across '
              'a schema bump');
      expect(stale!.payload['v'], 1);
    });

    test(
        'a legacy UNSTAMPED envelope (pre-#3619 build) is a fresh-miss '
        'but keeps its stale fallback', () async {
      AppConstants.setRuntimeVersion('6.0.0+TEST_BUILD_B');
      // What every pre-schema build persisted: no `schema` key at all —
      // exactly the envelopes on a field device the moment it updates
      // onto this code.
      storage.store['legacy'] = {
        'payload': {'v': 42},
        'storedAt': DateTime.now().millisecondsSinceEpoch,
        'source': ServiceSource.prixCarburantsApi.name,
        'ttlMs': const Duration(hours: 6).inMilliseconds,
        'appBuild': '6.0.0+TEST_BUILD_A',
      };

      expect(cache.getFresh('legacy'), isNull);
      final stale = cache.get('legacy');
      expect(stale, isNotNull);
      expect(stale!.payload['v'], 42);
      expect(stale.schemaVersion, isNull);
    });

    test('both stamps round-trip through the persisted envelope', () async {
      AppConstants.setRuntimeVersion('6.0.0+TEST_BUILD_C');
      await cache.put('city:berlin:de', {'v': 1},
          ttl: const Duration(minutes: 5), source: ServiceSource.cache);
      final raw = storage.store['city:berlin:de'] as Map;
      expect(raw['appBuild'], '6.0.0+TEST_BUILD_C');
      expect(raw['schema'], CacheSchema.forKey('city:berlin:de'));
    });
  });
}
