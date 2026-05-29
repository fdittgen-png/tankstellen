// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/radar/jit_price_cache.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

Station _station(String id, {double? e10}) => Station(
      id: id,
      name: 'Station $id',
      brand: 'X',
      street: '',
      postCode: '',
      place: '',
      lat: 48.0,
      lng: 2.0,
      e10: e10,
      isOpen: true,
    );

void main() {
  group('JitPriceCache — JIT fetch + dedup', () {
    test('fetches a fresh price and returns the priced station', () async {
      var calls = 0;
      final cache = JitPriceCache(
        fetchPrice: (s) async {
          calls++;
          return s.copyWith(e10: 1.799);
        },
      );

      final priced = await cache.priceFor(_station('A'));
      expect(calls, 1);
      expect(priced.e10, 1.799);
      expect(cache.isFresh('A'), isTrue);
    });

    test('a second approach within TTL does NOT refetch (dedup)', () async {
      var calls = 0;
      final cache = JitPriceCache(
        ttl: const Duration(minutes: 5),
        fetchPrice: (s) async {
          calls++;
          return s.copyWith(e10: 1.799 + calls * 0.01);
        },
      );

      final first = await cache.priceFor(_station('A'));
      final second = await cache.priceFor(_station('A'));
      expect(calls, 1, reason: 'within TTL the price is served from cache');
      expect(second.e10, first.e10);
    });

    test('refetches once the TTL has elapsed', () async {
      var calls = 0;
      var now = DateTime(2026, 5, 29, 12, 0, 0);
      final cache = JitPriceCache(
        ttl: const Duration(minutes: 5),
        now: () => now,
        fetchPrice: (s) async {
          calls++;
          return s.copyWith(e10: 1.700 + calls * 0.01);
        },
      );

      await cache.priceFor(_station('A'));
      expect(calls, 1);
      now = now.add(const Duration(minutes: 6));
      expect(cache.isFresh('A'), isFalse);
      await cache.priceFor(_station('A'));
      expect(calls, 2);
    });

    test('different stations are fetched independently', () async {
      final fetched = <String>[];
      final cache = JitPriceCache(
        fetchPrice: (s) async {
          fetched.add(s.id);
          return s.copyWith(e10: 1.5);
        },
      );

      await cache.priceFor(_station('A'));
      await cache.priceFor(_station('B'));
      expect(fetched, ['A', 'B']);
    });

    test('concurrent approaches to the same station coalesce to one fetch',
        () async {
      var calls = 0;
      final cache = JitPriceCache(
        fetchPrice: (s) async {
          calls++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return s.copyWith(e10: 1.6);
        },
      );

      final results = await Future.wait([
        cache.priceFor(_station('A')),
        cache.priceFor(_station('A')),
      ]);
      expect(calls, 1);
      expect(results[0].e10, 1.6);
      expect(results[1].e10, 1.6);
    });

    test('failed fetch returns the location-only station, no caching',
        () async {
      var calls = 0;
      final cache = JitPriceCache(
        fetchPrice: (s) async {
          calls++;
          throw StateError('rate limited');
        },
      );

      final result = await cache.priceFor(_station('A', e10: null));
      expect(result.e10, isNull); // unchanged location-only station
      expect(cache.isFresh('A'), isFalse); // not cached on failure
      // A retry actually re-attempts (failure was not cached).
      await cache.priceFor(_station('A'));
      expect(calls, 2);
    });

    test('null fetch (station not in upstream) returns location-only station',
        () async {
      final cache = JitPriceCache(fetchPrice: (s) async => null);
      final result = await cache.priceFor(_station('A', e10: null));
      expect(result.e10, isNull);
      expect(cache.isFresh('A'), isFalse);
    });
  });
}
