// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/mixins/cached_dataset_mixin.dart';

class _TestCached with CachedDatasetMixin {}

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
}
