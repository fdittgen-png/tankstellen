// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/radar/corridor_location_cache.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

Station _station(String id, double lat, double lng) => Station(
      id: id,
      name: 'Station $id',
      brand: 'X',
      street: '',
      postCode: '',
      place: '',
      lat: lat,
      lng: lng,
      isOpen: true,
    );

void main() {
  group('CorridorLocationCache — fetch + tile coverage', () {
    test('first call fetches once and covers the corridor tiles', () async {
      var calls = 0;
      final cache = CorridorLocationCache(
        corridorRadiusKm: 60,
        tileStepDegrees: 0.5,
        fetchCorridor: (lat, lng, r) async {
          calls++;
          return [_station('A', lat, lng)];
        },
      );

      expect(cache.isFresh(48.0, 2.0), isFalse);
      final stations = await cache.stationsNear(48.0, 2.0);
      expect(calls, 1);
      expect(stations, hasLength(1));
      expect(cache.isFresh(48.0, 2.0), isTrue);
      // The 60 km corridor covers a rectangle of tiles, not just one.
      expect(cache.coveredTiles.length, greaterThan(1));
    });

    test('a second nearby call inside a covered tile does NOT refetch',
        () async {
      var calls = 0;
      final cache = CorridorLocationCache(
        corridorRadiusKm: 60,
        tileStepDegrees: 0.5,
        fetchCorridor: (lat, lng, r) async {
          calls++;
          return [_station('A', lat, lng)];
        },
      );

      await cache.stationsNear(48.0, 2.0);
      await cache.stationsNear(48.02, 2.02); // same 0.5° tile — cache hit
      expect(calls, 1);
    });

    test('moving far outside the covered corridor refetches', () async {
      var calls = 0;
      final cache = CorridorLocationCache(
        corridorRadiusKm: 60,
        tileStepDegrees: 0.5,
        fetchCorridor: (lat, lng, r) async {
          calls++;
          return [_station('A', lat, lng)];
        },
      );

      await cache.stationsNear(48.0, 2.0);
      // ~330 km north — well outside the 60 km corridor + its tiles.
      await cache.stationsNear(51.0, 2.0);
      expect(calls, 2);
    });

    test('expired cache (past TTL) refetches even for the same tile',
        () async {
      var calls = 0;
      var now = DateTime(2026, 5, 29, 12, 0, 0);
      final cache = CorridorLocationCache(
        corridorRadiusKm: 60,
        tileStepDegrees: 0.5,
        ttl: const Duration(minutes: 30),
        now: () => now,
        fetchCorridor: (lat, lng, r) async {
          calls++;
          return [_station('A', lat, lng)];
        },
      );

      await cache.stationsNear(48.0, 2.0);
      expect(calls, 1);
      now = now.add(const Duration(minutes: 31)); // age past TTL
      expect(cache.isFresh(48.0, 2.0), isFalse);
      await cache.stationsNear(48.0, 2.0);
      expect(calls, 2);
    });

    test('failed fetch keeps the previous cache (geofence survives a blip)',
        () async {
      var fail = false;
      var calls = 0;
      final cache = CorridorLocationCache(
        corridorRadiusKm: 60,
        tileStepDegrees: 0.5,
        ttl: const Duration(minutes: 30),
        fetchCorridor: (lat, lng, r) async {
          calls++;
          if (fail) throw StateError('network down');
          return [_station('A', lat, lng)];
        },
      );

      await cache.stationsNear(48.0, 2.0);
      expect(cache.cachedStations, hasLength(1));

      // Force a refetch target (far away) but make it fail.
      fail = true;
      final after = await cache.stationsNear(51.0, 2.0);
      // Previous corridor still served — not wiped by the failure.
      expect(after, hasLength(1));
      expect(calls, 2);
    });

    test('concurrent samples crossing into a new tile coalesce to one fetch',
        () async {
      var calls = 0;
      final cache = CorridorLocationCache(
        corridorRadiusKm: 60,
        tileStepDegrees: 0.5,
        fetchCorridor: (lat, lng, r) async {
          calls++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return [_station('A', lat, lng)];
        },
      );

      // Two near-simultaneous first-entry calls for the same tile.
      final f1 = cache.stationsNear(48.0, 2.0);
      final f2 = cache.stationsNear(48.01, 2.01);
      await Future.wait([f1, f2]);
      expect(calls, 1);
    });
  });

  group('CorridorLocationCache — polled edge prefetch vs bulk', () {
    test('polled source prefetches the tile ahead near the edge', () async {
      final fetched = <(double, double)>[];
      final cache = CorridorLocationCache(
        isBulk: false,
        corridorRadiusKm: 10, // small so the corridor stays within ~1 tile
        tileStepDegrees: 0.5,
        fetchCorridor: (lat, lng, r) async {
          fetched.add((lat, lng));
          // Seed a forecourt at the fetch centre AND one at the north-edge GPS
          // the test then drives to, so a driver there is within range of one —
          // i.e. the set is NOT corrupt for the edge GPS, isolating the edge-
          // prefetch trigger from the #2932 proximity validator.
          return [_station('A', lat, lng), _station('B', 48.49, 2.25)];
        },
      );

      // Seed at the SW of a tile (48.0,2.0 = origin of tile 96:4).
      await cache.stationsNear(48.0, 2.0);
      final seedCount = fetched.length;

      // Now sit near the NORTH edge of the same tile heading north (0°).
      // 48.0 + 0.49 = 48.49 → still tile 96 (origin 48.0), fracLat 0.98 > 0.75.
      // Station 'B' (48.49) is right here, so the set is valid (not corrupt).
      await cache.stationsNear(48.49, 2.25, headingDegrees: 0);
      // Allow the unawaited prefetch to run.
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(fetched.length, greaterThan(seedCount),
          reason: 'edge + heading should trigger a prefetch of the tile ahead');
      // The prefetch is centred on the tile ahead (north), lat ≈ 48.75.
      expect(fetched.last.$1, greaterThan(48.5));
    });

    test('bulk source does NOT edge-prefetch (one local filter is enough)',
        () async {
      var calls = 0;
      final cache = CorridorLocationCache(
        isBulk: true,
        corridorRadiusKm: 10,
        tileStepDegrees: 0.5,
        fetchCorridor: (lat, lng, r) async {
          calls++;
          // Station at the north-edge GPS too, so the edge GPS isn't flagged
          // corrupt — isolating the "bulk skips prefetch" assertion.
          return [_station('A', lat, lng), _station('B', 48.49, 2.25)];
        },
      );

      await cache.stationsNear(48.0, 2.0);
      expect(calls, 1);
      // Near the edge with a heading — bulk skips the prefetch.
      await cache.stationsNear(48.49, 2.25, headingDegrees: 0);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(calls, 1, reason: 'bulk source must not prefetch');
    });
  });

  group('CorridorLocationCache — corrupted-cache detection (#2932)', () {
    test(
        'an empty/failed fetch does NOT poison tile coverage — next access '
        'refetches', () async {
      var calls = 0;
      var returnEmpty = true;
      final cache = CorridorLocationCache(
        corridorRadiusKm: 60,
        tileStepDegrees: 0.5,
        fetchCorridor: (lat, lng, r) async {
          calls++;
          if (returnEmpty) return const [];
          return [_station('A', lat, lng)];
        },
      );

      // First access returns an empty set — must NOT mark the tile covered.
      final first = await cache.stationsNear(48.0, 2.0);
      expect(first, isEmpty);
      expect(calls, 1);
      expect(cache.isFresh(48.0, 2.0), isFalse,
          reason: 'an empty fetch must not mark the tile covered');

      // Next access at the same tile must refetch (coverage was not poisoned).
      returnEmpty = false;
      final second = await cache.stationsNear(48.0, 2.0);
      expect(calls, 2, reason: 'empty fetch must not stick — refetch');
      expect(second, hasLength(1));
    });

    test(
        'a good fetch that later returns empty keeps the prior corridor and '
        'retries', () async {
      var calls = 0;
      var returnEmpty = false;
      final cache = CorridorLocationCache(
        corridorRadiusKm: 60,
        tileStepDegrees: 0.5,
        ttl: const Duration(minutes: 30),
        fetchCorridor: (lat, lng, r) async {
          calls++;
          if (returnEmpty) return const [];
          return [_station('A', lat, lng)];
        },
      );

      await cache.stationsNear(48.0, 2.0);
      expect(cache.cachedStations, hasLength(1));

      // Force a refetch far away that returns empty — must keep the old set
      // AND must not mark the new far tile covered (so it retries).
      returnEmpty = true;
      final after = await cache.stationsNear(51.0, 2.0);
      expect(calls, 2, reason: 'the far position triggered a (failed) fetch');
      expect(after, hasLength(1), reason: 'old corridor survives an empty fetch');
      expect(cache.isFresh(51.0, 2.0), isFalse,
          reason: 'empty far fetch must not be cached as covered');
    });

    test(
        'seeded stations ~50 km away are dropped when GPS is far — far set '
        'invalidated + refetch triggered', () async {
      var calls = 0;
      // First fetch (centred near 48.0,2.0) returns a station ~50 km away.
      // A later GPS sample in the SAME coarse 0.5° tile but far from that
      // station must NOT be served the far set — it must invalidate + refetch.
      final cache = CorridorLocationCache(
        corridorRadiusKm: 10, // tight radius so 50 km is clearly out of range
        tileStepDegrees: 0.5,
        fetchCorridor: (lat, lng, r) async {
          calls++;
          // ~50 km north of the fetch centre (0.45° lat ≈ 50 km).
          return [_station('FAR', lat + 0.45, lng)];
        },
      );

      // Seed: fetch centred at 48.0,2.0 → one station at ~48.45,2.0.
      await cache.stationsNear(48.0, 2.0);
      expect(calls, 1);
      expect(cache.cachedStations, hasLength(1));

      // Now the live GPS is at 48.0,2.0 — the cached station is ~50 km away,
      // far outside the 10 km corridor radius. The cache must treat the set as
      // corrupted/degenerate and refetch rather than serve the far station.
      await cache.stationsNear(48.0, 2.0);
      expect(calls, 2,
          reason: 'nearest cached station beyond radius ⇒ invalidate + refetch');
    });

    test('a station at (0,0) is treated as corrupt and triggers a refetch',
        () async {
      var calls = 0;
      var returnCorrupt = true;
      final cache = CorridorLocationCache(
        corridorRadiusKm: 60,
        tileStepDegrees: 0.5,
        fetchCorridor: (lat, lng, r) async {
          calls++;
          if (returnCorrupt) return [_station('NULL', 0, 0)];
          return [_station('A', lat, lng)];
        },
      );

      await cache.stationsNear(48.0, 2.0);
      expect(calls, 1);
      returnCorrupt = false;
      await cache.stationsNear(48.0, 2.0);
      expect(calls, 2, reason: '(0,0) coords are corrupt ⇒ invalidate + refetch');
    });
  });

  group('CorridorLocationCache — rate-respecting forced refetch (#2932)', () {
    test(
        'a corruption-forced refetch is suppressed when the budget gate denies '
        'it — the validated cache is served instead', () async {
      var calls = 0;
      var allowRefetch = false;
      var sinkFired = 0;
      final cache = CorridorLocationCache(
        corridorRadiusKm: 10,
        tileStepDegrees: 0.5,
        canRefetch: () => allowRefetch,
        onRefetch: () => sinkFired++,
        fetchCorridor: (lat, lng, r) async {
          calls++;
          // ~50 km away → triggers the corruption path on the next access.
          return [_station('FAR', lat + 0.45, lng)];
        },
      );

      // Seed (first-entry fetch is never gated).
      await cache.stationsNear(48.0, 2.0);
      expect(calls, 1);

      // Corruption detected but the budget gate denies → no refetch, serve
      // the (validated) cache; the record sink must NOT fire.
      final served = await cache.stationsNear(48.0, 2.0);
      expect(calls, 1, reason: 'min-interval not elapsed ⇒ no forced refetch');
      expect(sinkFired, 0);
      expect(served, hasLength(1));

      // Once the gate allows, the next access forces the refetch + stamps.
      allowRefetch = true;
      await cache.stationsNear(48.0, 2.0);
      expect(calls, 2, reason: 'gate open ⇒ forced refetch fires');
      expect(sinkFired, 1, reason: 'forced refetch stamps the budget sink');
    });

    test('a first-entry fetch and a TTL refetch are NOT gated by canRefetch',
        () async {
      var calls = 0;
      var now = DateTime(2026, 6, 6, 12, 0, 0);
      final cache = CorridorLocationCache(
        corridorRadiusKm: 60,
        tileStepDegrees: 0.5,
        ttl: const Duration(minutes: 30),
        now: () => now,
        // Gate always denies — must NOT block the normal (non-forced) fetches.
        canRefetch: () => false,
        fetchCorridor: (lat, lng, r) async {
          calls++;
          return [_station('A', lat, lng)];
        },
      );

      await cache.stationsNear(48.0, 2.0); // first entry — not gated
      expect(calls, 1);
      now = now.add(const Duration(minutes: 31)); // age past TTL
      await cache.stationsNear(48.0, 2.0); // TTL refetch — not gated
      expect(calls, 2, reason: 'TTL expiry is a normal refetch, not gated');
    });

    test(
        'a faulty gate / sink never breaks the geofence (never-throws contract, '
        '#1103)', () async {
      final cache = CorridorLocationCache(
        corridorRadiusKm: 10,
        tileStepDegrees: 0.5,
        // Both injected callbacks throw — stationsNear must still resolve and
        // serve the (validated-as-best-available) cache, never propagate.
        canRefetch: () => throw StateError('budget box closed'),
        onRefetch: () => throw StateError('tracer faulted'),
        fetchCorridor: (lat, lng, r) async => [_station('FAR', lat + 0.45, lng)],
      );

      await cache.stationsNear(48.0, 2.0); // seed (first entry, not gated)
      // Corruption detected → gate throws → must degrade to "serve cache".
      final served = await cache.stationsNear(48.0, 2.0);
      expect(served, hasLength(1),
          reason: 'a faulty gate degrades to serving the cache, never throws');
    });
  });
}
