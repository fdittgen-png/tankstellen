// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/services/radar/radar_in_radius_cache.dart';

/// #3254 — the movement+time gate that stops the radar's direct in-radius merge
/// from flooding the rate-limit queue. Driven against injected fetch/clock
/// seams so the gate logic is pinned deterministically, no container/real GPS.
Station _s(String id, double lat, double lng) => Station(
      id: id,
      name: id,
      brand: 'TEST',
      street: 'Teststr.',
      postCode: '00000',
      place: 'Test',
      lat: lat,
      lng: lng,
      e10: 1.5,
      isOpen: true,
    );

void main() {
  group('RadarInRadiusCache gate', () {
    late int calls;
    late DateTime clock;
    late RadarInRadiusCache cache;

    RadarInRadiusCache build({Duration minInterval = const Duration(minutes: 5)}) {
      calls = 0;
      clock = DateTime(2026, 1, 1, 12);
      return RadarInRadiusCache(
        fetch: (lat, lng, r) async {
          calls++;
          return [_s('S', lat, lng)];
        },
        minInterval: () => minInterval,
        now: () => clock,
      );
    }

    setUp(() => cache = build());

    test('first call always fetches', () async {
      final out = await cache.stationsNear(48.0, 2.0, 10);
      expect(calls, 1);
      expect(out, hasLength(1));
    });

    test('a standstill (same cell) never re-fetches, even past minInterval',
        () async {
      await cache.stationsNear(48.0, 2.0, 10);
      clock = clock.add(const Duration(minutes: 30));
      await cache.stationsNear(48.0001, 2.0, 10); // rounds to the same cell
      expect(calls, 1, reason: 'same ~111 m cell reuses the cached merge');
    });

    test('moving to a new cell before minInterval reuses (no flood)', () async {
      await cache.stationsNear(48.0, 2.0, 10);
      clock = clock.add(const Duration(minutes: 1)); // < 5 min
      await cache.stationsNear(48.05, 2.0, 10); // new cell, too soon
      expect(calls, 1, reason: 'gate holds until minInterval elapses');
    });

    test('refetches only after moving to a new cell AND minInterval elapsed',
        () async {
      await cache.stationsNear(48.0, 2.0, 10);
      clock = clock.add(const Duration(minutes: 6)); // >= 5 min
      final out = await cache.stationsNear(48.05, 2.0, 10); // new cell
      expect(calls, 2, reason: 'moved beyond the cell AND past minInterval');
      expect(out.single.lat, 48.05, reason: 'fresh fetch around the new fix');
    });

    test('a moving drive issues at most one fetch per minInterval window',
        () async {
      // Simulate a steady drive: a new cell every "minute", minInterval 5 min.
      cache = build(minInterval: const Duration(minutes: 5));
      for (var i = 0; i < 12; i++) {
        clock = clock.add(const Duration(minutes: 1));
        await cache.stationsNear(48.0 + i * 0.01, 2.0, 10);
      }
      // 12 min of driving (+ the initial fetch) ⇒ initial + 2 windows ≈ 3.
      expect(calls, lessThanOrEqualTo(3),
          reason: 'bounded: ~1 chain search per minInterval, not per fix');
    });

    test('degrades to the last good merge on a fetch failure', () async {
      var fail = false;
      clock = DateTime(2026, 1, 1, 12);
      final c = RadarInRadiusCache(
        fetch: (lat, lng, r) async {
          if (fail) throw StateError('offline');
          return [_s('OK', lat, lng)];
        },
        minInterval: () => const Duration(minutes: 5),
        now: () => clock,
      );
      final first = await c.stationsNear(48.0, 2.0, 10);
      expect(first.single.id, 'OK');
      fail = true;
      clock = clock.add(const Duration(minutes: 10));
      final second = await c.stationsNear(48.5, 2.0, 10); // new cell + elapsed
      expect(second.single.id, 'OK',
          reason: 'a failed refetch keeps the last good merge, never empties');
    });

    test('reuses the cache when the minInterval resolver throws', () async {
      clock = DateTime(2026, 1, 1, 12);
      final c = RadarInRadiusCache(
        fetch: (lat, lng, r) async => [_s('S', lat, lng)],
        minInterval: () => throw StateError('no country graph'),
        now: () => clock,
      );
      await c.stationsNear(48.0, 2.0, 10); // first call fetches (no gate yet)
      clock = clock.add(const Duration(hours: 1));
      final out = await c.stationsNear(48.5, 2.0, 10); // gate can't resolve
      expect(out, hasLength(1),
          reason: 'unknown cadence ⇒ conservative reuse, never throws');
    });
  });
}
