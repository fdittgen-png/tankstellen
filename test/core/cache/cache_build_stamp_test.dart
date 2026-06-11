// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/constants/app_constants.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/services/service_result.dart';

/// #3219 follow-up — the cross-build cache-freshness gate.
///
/// Cached payloads are PARSED output, so an entry written by an older app
/// build embeds that build's parser bugs. The field shape: the #3224 FR
/// per-day-hours fix shipped, the maintainer updated, and the phone STILL
/// showed only 24/7 hours — because the pre-fix build's hour-less parse
/// output sat fresh (FR `searchResultTtl` = 6 h) under the same search key
/// and `getFresh` happily served it. The gate: `getFresh` refuses an entry
/// stamped by a different build (or carrying no stamp at all — every
/// pre-stamp build), forcing one re-fetch + re-parse with the current code,
/// while `get` keeps serving it to the stale/offline fallback.
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

  group('CacheManager cross-build freshness gate (#3219 follow-up)', () {
    test('an entry written by THIS build is served fresh (no regression)',
        () async {
      AppConstants.setRuntimeVersion('6.0.0+TEST_BUILD_A');
      await cache.put('k', {'v': 1},
          ttl: const Duration(hours: 6),
          source: ServiceSource.prixCarburantsApi);

      final entry = cache.getFresh('k');
      expect(entry, isNotNull);
      expect(entry!.payload['v'], 1);
      expect(entry.appBuild, '6.0.0+TEST_BUILD_A');
    });

    test(
        'an unexpired entry written by a DIFFERENT build is a fresh-miss '
        'but still serves the stale/offline fallback', () async {
      AppConstants.setRuntimeVersion('6.0.0+TEST_BUILD_A');
      await cache.put('k', {'v': 1},
          ttl: const Duration(hours: 6),
          source: ServiceSource.prixCarburantsApi);

      // The app updates: same cache file, new build.
      AppConstants.setRuntimeVersion('6.0.0+TEST_BUILD_B');

      expect(cache.getFresh('k'), isNull,
          reason: 'a cross-build entry may embed the parser bug the update '
              'just fixed — it must force a re-fetch');
      final stale = cache.get('k');
      expect(stale, isNotNull,
          reason: 'the stale/offline fallback must keep working across '
              'an update');
      expect(stale!.payload['v'], 1);
    });

    test(
        'a legacy UNSTAMPED envelope (written by a pre-stamp build) is a '
        'fresh-miss but keeps its stale fallback', () async {
      AppConstants.setRuntimeVersion('6.0.0+TEST_BUILD_B');
      // Byte-shape of what every pre-#3219-follow-up build persisted: no
      // `appBuild` key at all — exactly the envelopes on a field device the
      // moment it updates onto this code.
      storage.store['legacy'] = {
        'payload': {'v': 42},
        'storedAt': DateTime.now().millisecondsSinceEpoch,
        'source': ServiceSource.prixCarburantsApi.name,
        'ttlMs': const Duration(hours: 6).inMilliseconds,
      };

      expect(cache.getFresh('legacy'), isNull);
      final stale = cache.get('legacy');
      expect(stale, isNotNull);
      expect(stale!.payload['v'], 42);
      expect(stale.appBuild, isNull);
    });

    test('the stamp round-trips through the persisted envelope', () async {
      AppConstants.setRuntimeVersion('6.0.0+TEST_BUILD_C');
      await cache.put('k', {'v': 1},
          ttl: const Duration(minutes: 5), source: ServiceSource.cache);
      expect(
        (storage.store['k'] as Map)['appBuild'],
        '6.0.0+TEST_BUILD_C',
      );
    });
  });
}
