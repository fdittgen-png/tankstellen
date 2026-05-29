// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/services/mixins/cached_dataset_mixin.dart';
import 'package:tankstellen/core/services/persistent_dataset.dart';
import 'package:tankstellen/core/services/service_result.dart';

class _TestCached with CachedDatasetMixin {}

/// Tiny in-memory CacheStrategy for the persistence tests.
class _MemCache implements CacheStrategy {
  final Map<String, CacheEntry> _store = {};

  @override
  Future<void> put(String key, Map<String, dynamic> data,
      {required Duration ttl, required ServiceSource source}) async {
    _store[key] = CacheEntry(
        payload: data, storedAt: DateTime.now(), originalSource: source, ttl: ttl);
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

PersistentDataset<List<int>> _intDataset(CacheStrategy cache) =>
    PersistentDataset<List<int>>(
      cache: cache,
      countryCode: 'XX',
      datasetName: 'nums',
      source: ServiceSource.cache,
      serialize: (v) => {'v': v},
      deserialize: (j) => (j['v'] as List).cast<int>(),
    );

void main() {
  late _TestCached cached;

  setUp(() => cached = _TestCached());

  group('CachedDatasetMixin', () {
    test('isDatasetFresh returns false initially', () {
      expect(cached.isDatasetFresh(const Duration(minutes: 5)), false);
    });

    test('isDatasetFresh returns true after marking refreshed', () {
      cached.markDatasetRefreshed();
      expect(cached.isDatasetFresh(const Duration(minutes: 5)), true);
    });

    test('isDatasetFresh returns false after TTL expires', () {
      cached.markDatasetRefreshed();
      // Duration.zero means the data is always stale immediately
      expect(cached.isDatasetFresh(Duration.zero), false);
    });

    test('markDatasetRefreshed can be called multiple times', () {
      cached.markDatasetRefreshed();
      expect(cached.isDatasetFresh(const Duration(minutes: 5)), true);
      cached.markDatasetRefreshed();
      expect(cached.isDatasetFresh(const Duration(minutes: 5)), true);
    });

    test('isDatasetFresh with very large TTL returns true after mark', () {
      cached.markDatasetRefreshed();
      expect(cached.isDatasetFresh(const Duration(days: 365)), true);
    });

    test('separate instances have independent state', () {
      final other = _TestCached();
      cached.markDatasetRefreshed();
      expect(cached.isDatasetFresh(const Duration(minutes: 5)), true);
      expect(other.isDatasetFresh(const Duration(minutes: 5)), false);
    });
  });

  group('CachedDatasetMixin.loadDataset', () {
    test('returns cached without fetching when fresh', () async {
      var fetchCalls = 0;
      var storeCalls = 0;
      // Stamp the cache as fresh first.
      cached.markDatasetRefreshed();

      final result = await cached.loadDataset<List<int>>(
        cached: const [1, 2, 3],
        ttl: const Duration(minutes: 5),
        fetch: () async {
          fetchCalls++;
          return const [9, 9, 9];
        },
        store: (_) => storeCalls++,
      );

      expect(result, const [1, 2, 3]);
      expect(fetchCalls, 0, reason: 'fresh cache must not trigger a fetch');
      expect(storeCalls, 0, reason: 'fresh cache must not re-store');
    });

    test('fetches, stores and marks fresh when stale', () async {
      var fetchCalls = 0;
      int? stored;
      // Marked, but TTL of zero makes it immediately stale.
      cached.markDatasetRefreshed();
      expect(cached.isDatasetFresh(Duration.zero), false);

      final result = await cached.loadDataset<int>(
        cached: 1,
        ttl: Duration.zero,
        fetch: () async {
          fetchCalls++;
          return 42;
        },
        store: (value) => stored = value,
      );

      expect(result, 42);
      expect(fetchCalls, 1);
      expect(stored, 42);
      // markDatasetRefreshed was called, so a positive TTL is now fresh.
      expect(cached.isDatasetFresh(const Duration(minutes: 5)), true);
    });

    test('fetches when cached is null even within TTL', () async {
      var fetchCalls = 0;
      String? stored;
      // Fresh by time, but no cached value yet.
      cached.markDatasetRefreshed();

      final result = await cached.loadDataset<String>(
        cached: null,
        ttl: const Duration(minutes: 5),
        fetch: () async {
          fetchCalls++;
          return 'loaded';
        },
        store: (value) => stored = value,
      );

      expect(result, 'loaded');
      expect(fetchCalls, 1, reason: 'null cache must fetch regardless of TTL');
      expect(stored, 'loaded');
    });
  });

  group('CachedDatasetMixin.loadPersistentDataset (#2264)', () {
    test('fetches + persists when nothing is cached', () async {
      final cache = _MemCache();
      final persistent = _intDataset(cache);
      var fetchCalls = 0;

      final result = await cached.loadPersistentDataset<List<int>>(
        cached: null,
        softTtl: const Duration(hours: 1),
        hardTtl: const Duration(hours: 6),
        persistent: persistent,
        fetch: () async {
          fetchCalls++;
          return [1, 2, 3];
        },
        store: (_) {},
      );

      expect(result, [1, 2, 3]);
      expect(fetchCalls, 1);
      expect(persistent.read()?.value, [1, 2, 3],
          reason: 'fetched dataset must be persisted');
    });

    test('reads through from disk without fetching when persisted + fresh',
        () async {
      final cache = _MemCache();
      final persistent = _intDataset(cache);
      await persistent.write([9, 9], hardTtl: const Duration(hours: 6));

      var fetchCalls = 0;
      List<int>? stored;
      final result = await cached.loadPersistentDataset<List<int>>(
        cached: null,
        softTtl: const Duration(hours: 1),
        hardTtl: const Duration(hours: 6),
        persistent: persistent,
        fetch: () async {
          fetchCalls++;
          return [0];
        },
        store: (v) => stored = v,
      );

      expect(result, [9, 9]);
      expect(fetchCalls, 0, reason: 'fresh disk copy must skip the network');
      expect(stored, [9, 9], reason: 'disk copy is rehydrated into memory');
    });

    test('falls back to persisted copy when fetch throws (offline)', () async {
      final cache = _MemCache();
      final persistent = _intDataset(cache);
      await persistent.write([7], hardTtl: const Duration(hours: 6));

      // Force a refresh attempt by leaving no in-memory copy and a soft TTL
      // that the disk copy is already inside — but make fetch throw anyway by
      // expiring it past soft via a zero soft TTL.
      final result = await cached.loadPersistentDataset<List<int>>(
        cached: null,
        softTtl: Duration.zero,
        hardTtl: const Duration(hours: 6),
        persistent: persistent,
        fetch: () async => throw Exception('offline'),
        store: (_) {},
      );

      expect(result, [7], reason: 'offline must serve the persisted copy');
    });

    test('rethrows when fetch fails and nothing is persisted', () async {
      final persistent = _intDataset(_MemCache());
      expect(
        () => cached.loadPersistentDataset<List<int>>(
          cached: null,
          softTtl: const Duration(hours: 1),
          hardTtl: const Duration(hours: 6),
          persistent: persistent,
          fetch: () async => throw Exception('boom'),
          store: (_) {},
        ),
        throwsException,
      );
    });
  });

  group('concurrent-fetch guard (#2313)', () {
    test('loadDataset: two simultaneous cold calls issue ONE fetch', () async {
      var fetchCalls = 0;
      var storeCalls = 0;
      final gate = Completer<void>();

      Future<int> slowFetch() async {
        fetchCalls++;
        await gate.future; // hold the download open until both callers wait
        return 42;
      }

      // Both calls start while the cache is cold — they must share one fetch.
      final a = cached.loadDataset<int>(
        cached: null,
        ttl: const Duration(minutes: 5),
        fetch: slowFetch,
        store: (_) => storeCalls++,
      );
      final b = cached.loadDataset<int>(
        cached: null,
        ttl: const Duration(minutes: 5),
        fetch: slowFetch,
        store: (_) => storeCalls++,
      );

      gate.complete();
      final results = await Future.wait([a, b]);

      expect(results, [42, 42]);
      expect(fetchCalls, 1,
          reason: 'concurrent cold searches must download the dataset once');
      // Both callers still get a result; only the in-flight fetch is shared.
      expect(storeCalls, greaterThanOrEqualTo(1));
    });

    test('loadDataset: a later call after completion refetches', () async {
      var fetchCalls = 0;
      // Zero TTL → always stale, so each *sequential* call must refetch.
      cached.markDatasetRefreshed();

      await cached.loadDataset<int>(
        cached: 1,
        ttl: Duration.zero,
        fetch: () async {
          fetchCalls++;
          return 1;
        },
        store: (_) {},
      );
      await cached.loadDataset<int>(
        cached: 1,
        ttl: Duration.zero,
        fetch: () async {
          fetchCalls++;
          return 1;
        },
        store: (_) {},
      );

      expect(fetchCalls, 2,
          reason: 'the in-flight slot clears on completion → later call '
              'refetches (no permanent dedupe)');
    });

    test('loadPersistentDataset: two simultaneous cold calls issue ONE '
        'fetch + ONE persist', () async {
      final cache = _MemCache();
      final persistent = _intDataset(cache);
      var fetchCalls = 0;
      final gate = Completer<void>();

      Future<List<int>> slowFetch() async {
        fetchCalls++;
        await gate.future;
        return [5, 5];
      }

      final a = cached.loadPersistentDataset<List<int>>(
        cached: null,
        softTtl: const Duration(hours: 1),
        hardTtl: const Duration(hours: 6),
        persistent: persistent,
        fetch: slowFetch,
        store: (_) {},
      );
      final b = cached.loadPersistentDataset<List<int>>(
        cached: null,
        softTtl: const Duration(hours: 1),
        hardTtl: const Duration(hours: 6),
        persistent: persistent,
        fetch: slowFetch,
        store: (_) {},
      );

      gate.complete();
      final results = await Future.wait([a, b]);

      expect(results, [
        [5, 5],
        [5, 5],
      ]);
      expect(fetchCalls, 1,
          reason: 'concurrent cold searches must download the CSV once');
      expect(persistent.read()?.value, [5, 5]);
    });
  });
}
