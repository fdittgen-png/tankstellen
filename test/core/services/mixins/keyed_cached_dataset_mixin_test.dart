// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3156 — KeyedCachedDatasetMixin: the CachedDatasetMixin state machine with
// per-key freshness clocks + in-flight fetch slots, for bulk feeds that are a
// FAMILY of datasets (ES MITECO: one row set per province). Also covers the
// two host-shaped deltas vs the unkeyed mixin: a nullable [persistent] (the
// pure in-memory parser tests) and the stale-in-memory last-resort fallback
// when a fetch fails with no disk copy.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/services/mixins/cached_dataset_mixin.dart';
import 'package:tankstellen/core/services/persistent_dataset.dart';
import 'package:tankstellen/core/services/service_result.dart';

class _TestKeyed with KeyedCachedDatasetMixin {}

/// Tiny in-memory CacheStrategy for the persistence tests.
class _MemCache implements CacheStrategy {
  final Map<String, CacheEntry> _store = {};

  @override
  Future<void> put(String key, Map<String, dynamic> data,
      {required Duration ttl, required ServiceSource source}) async {
    _store[key] = CacheEntry(
        payload: data,
        storedAt: DateTime.now(),
        originalSource: source,
        ttl: ttl);
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

PersistentDataset<List<int>> _intDataset(CacheStrategy cache, String name) =>
    PersistentDataset<List<int>>(
      cache: cache,
      countryCode: 'XX',
      datasetName: name,
      source: ServiceSource.cache,
      serialize: (v) => {'v': v},
      deserialize: (j) => (j['v'] as List).cast<int>(),
    );

void main() {
  late _TestKeyed keyed;

  setUp(() => keyed = _TestKeyed());

  group('per-key freshness clocks', () {
    test('keys are independent: refreshing A leaves B stale', () {
      keyed.markKeyedDatasetRefreshed('A');
      expect(keyed.isKeyedDatasetFresh('A', const Duration(minutes: 5)), true);
      expect(keyed.isKeyedDatasetFresh('B', const Duration(minutes: 5)), false);
    });

    test('markKeyedDatasetRefreshedAt pre-ages a single key', () {
      keyed.markKeyedDatasetRefreshedAt('A', const Duration(hours: 2));
      expect(keyed.isKeyedDatasetFresh('A', const Duration(hours: 1)), false);
      expect(keyed.isKeyedDatasetFresh('A', const Duration(hours: 3)), true);
    });
  });

  group('loadKeyedPersistentDataset', () {
    test('returns the fresh in-memory copy without fetching', () async {
      var fetchCalls = 0;
      keyed.markKeyedDatasetRefreshed('28');

      final result = await keyed.loadKeyedPersistentDataset<List<int>>(
        key: '28',
        cached: const [1, 2],
        softTtl: const Duration(hours: 6),
        hardTtl: const Duration(hours: 24),
        persistent: null,
        fetch: () async {
          fetchCalls++;
          return const [9];
        },
        store: (_) {},
      );

      expect(result, const [1, 2]);
      expect(fetchCalls, 0);
    });

    test('a fresh key A does not satisfy a cold key B', () async {
      var fetchCalls = 0;
      keyed.markKeyedDatasetRefreshed('28');

      final result = await keyed.loadKeyedPersistentDataset<List<int>>(
        key: '08',
        cached: null, // B has no in-memory copy
        softTtl: const Duration(hours: 6),
        hardTtl: const Duration(hours: 24),
        persistent: null,
        fetch: () async {
          fetchCalls++;
          return const [8];
        },
        store: (_) {},
      );

      expect(result, const [8]);
      expect(fetchCalls, 1,
          reason: "province A's freshness must never be served for B (#2264)");
    });

    test('fetches + persists + marks the key fresh when cold', () async {
      final cache = _MemCache();
      final persistent = _intDataset(cache, 'province-28');
      List<int>? stored;

      final result = await keyed.loadKeyedPersistentDataset<List<int>>(
        key: '28',
        cached: null,
        softTtl: const Duration(hours: 6),
        hardTtl: const Duration(hours: 24),
        persistent: persistent,
        fetch: () async => const [1, 2, 3],
        store: (v) => stored = v,
      );

      expect(result, const [1, 2, 3]);
      expect(stored, const [1, 2, 3]);
      expect(persistent.read()?.value, const [1, 2, 3]);
      expect(keyed.isKeyedDatasetFresh('28', const Duration(hours: 6)), true);
    });

    test('reads through from disk without fetching when persisted + fresh',
        () async {
      final cache = _MemCache();
      final persistent = _intDataset(cache, 'province-28');
      await persistent.write(const [9, 9], hardTtl: const Duration(hours: 24));

      var fetchCalls = 0;
      List<int>? stored;
      final result = await keyed.loadKeyedPersistentDataset<List<int>>(
        key: '28',
        cached: null,
        softTtl: const Duration(hours: 6),
        hardTtl: const Duration(hours: 24),
        persistent: persistent,
        fetch: () async {
          fetchCalls++;
          return const [0];
        },
        store: (v) => stored = v,
      );

      expect(result, const [9, 9]);
      expect(fetchCalls, 0, reason: 'fresh disk copy must skip the network');
      expect(stored, const [9, 9], reason: 'disk copy rehydrates into memory');
    });

    test('falls back to the persisted copy when fetch throws (offline)',
        () async {
      final cache = _MemCache();
      final persistent = _intDataset(cache, 'province-28');
      await persistent.write(const [7], hardTtl: const Duration(hours: 24));

      final result = await keyed.loadKeyedPersistentDataset<List<int>>(
        key: '28',
        cached: null,
        softTtl: Duration.zero, // force a refresh attempt
        hardTtl: const Duration(hours: 24),
        persistent: persistent,
        fetch: () async => throw Exception('offline'),
        store: (_) {},
      );

      expect(result, const [7]);
    });

    test(
        'falls back to the STALE in-memory copy when fetch fails with no '
        'disk (pre-#3156 MITECO offline behaviour)', () async {
      keyed.markKeyedDatasetRefreshedAt('28', const Duration(hours: 12));

      final result = await keyed.loadKeyedPersistentDataset<List<int>>(
        key: '28',
        cached: const [4, 4], // stale (12 h > 6 h soft TTL) but present
        softTtl: const Duration(hours: 6),
        hardTtl: const Duration(hours: 24),
        persistent: null,
        fetch: () async => throw Exception('offline'),
        store: (_) {},
      );

      expect(result, const [4, 4],
          reason: 'hours-stale rows beat failing the whole search');
    });

    test('rethrows when fetch fails and nothing at all is cached', () async {
      expect(
        () => keyed.loadKeyedPersistentDataset<List<int>>(
          key: '28',
          cached: null,
          softTtl: const Duration(hours: 6),
          hardTtl: const Duration(hours: 24),
          persistent: _intDataset(_MemCache(), 'province-28'),
          fetch: () async => throw Exception('boom'),
          store: (_) {},
        ),
        throwsException,
      );
    });
  });

  group('per-key concurrent-fetch dedupe (#2313)', () {
    test('two simultaneous cold calls for the SAME key issue ONE fetch',
        () async {
      var fetchCalls = 0;
      final gate = Completer<void>();

      Future<List<int>> slowFetch() async {
        fetchCalls++;
        await gate.future;
        return const [5];
      }

      Future<List<int>> load() => keyed.loadKeyedPersistentDataset<List<int>>(
            key: '28',
            cached: null,
            softTtl: const Duration(hours: 6),
            hardTtl: const Duration(hours: 24),
            persistent: null,
            fetch: slowFetch,
            store: (_) {},
          );

      final a = load();
      final b = load();
      gate.complete();
      expect(await Future.wait([a, b]), [
        const [5],
        const [5],
      ]);
      expect(fetchCalls, 1);
    });

    test('simultaneous cold calls for DIFFERENT keys fetch independently',
        () async {
      final fetched = <String>[];
      final gate = Completer<void>();

      Future<List<int>> load(String key) =>
          keyed.loadKeyedPersistentDataset<List<int>>(
            key: key,
            cached: null,
            softTtl: const Duration(hours: 6),
            hardTtl: const Duration(hours: 24),
            persistent: null,
            fetch: () async {
              fetched.add(key);
              await gate.future;
              return const [1];
            },
            store: (_) {},
          );

      final a = load('28');
      final b = load('08');
      gate.complete();
      await Future.wait([a, b]);
      expect(fetched, unorderedEquals(['28', '08']),
          reason: 'the in-flight slot is per key, not global');
    });
  });
}
