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
          return [_station('A', lat, lng)];
        },
      );

      // Seed at the SW of a tile (48.0,2.0 = origin of tile 96:4).
      await cache.stationsNear(48.0, 2.0);
      final seedCount = fetched.length;

      // Now sit near the NORTH edge of the same tile heading north (0°).
      // 48.0 + 0.49 = 48.49 → still tile 96 (origin 48.0), fracLat 0.98 > 0.75.
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
          return [_station('A', lat, lng)];
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
}
