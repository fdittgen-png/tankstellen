// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// #2703 — corridor over-inclusion (originally `countriesTouchingRouteExtent`).
// A southern-France route whose whole-route AABB corner clipped GB's box (even
// with NO actual GB vertex) had the flaky UK feed queried, producing field-log
// timeouts. #2741 superseded the bbox-extent helper with the genuine-entry gate
// in `corridorCountries` + a profile intersection in `buildCorridorServiceMap`,
// so this now asserts the END-TO-END corridor map: GB is dropped when no vertex
// genuinely enters it, and kept when a real GB vertex is on the polyline
// (the #2621 recovery intent is preserved).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/route_search/data/cross_border_corridor.dart';
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// Minimal [StorageRepository] stub so `buildCorridorServiceMap` can read
/// `hasApiKey()` without standing up Hive. GB/FR are keyless so the value
/// doesn't gate them.
class _NoKeyStorage implements StorageRepository {
  @override
  bool hasApiKey() => false;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

void main() {
  // A southern-France route whose whole-route AABB corner (maxLat 50.5,
  // minLng -2.0) lands INSIDE GB's box [49.5..61, -9..2] — but NEITHER vertex
  // is in GB: (50.5, 3.0) has lng 3.0 > 2.0, and (43.44, -2.0) has lat 43.44 <
  // 49.5. Both vertices ARE in FR's box [41..51.5, -5.5..10]. This is the
  // Channel-clip over-inclusion shape.
  const noGbVertexRoute = RouteInfo(
    geometry: [
      LatLng(50.5, 3.0), // NE-ish — supplies maxLat
      LatLng(43.44, -2.0), // SW-ish (southern France) — supplies minLng
    ],
    distanceKm: 900,
    durationMinutes: 540,
    samplePoints: [],
  );

  // Same route plus a REAL GB vertex (London) — GB is genuinely on the
  // polyline and must still be credited.
  const gbVertexRoute = RouteInfo(
    geometry: [
      LatLng(50.5, 3.0),
      LatLng(43.44, -2.0),
      LatLng(51.0, -0.1), // London — INSIDE GB's box
    ],
    distanceKm: 1100,
    durationMinutes: 660,
    samplePoints: [],
  );

  group('buildCorridorServiceMap — GB dropped end-to-end (#2703 / #2741)', () {
    test(
        'a GB profile does NOT enter the corridor service map for a '
        'southern-France route with no GB vertex (RED on master)', () {
      final container = ProviderContainer(overrides: [
        storageRepositoryProvider.overrideWith((ref) => _NoKeyStorage()),
      ]);
      addTearDown(container.dispose);

      late Ref capturedRef;
      final refCapture = Provider<int>((ref) {
        capturedRef = ref;
        return 0;
      });
      container.read(refCapture);

      final map = buildCorridorServiceMap(
        capturedRef,
        noGbVertexRoute,
        const {'GB': FuelType.e10, 'FR': FuelType.e10},
      );

      expect(map.keys, isNot(contains('GB')),
          reason: 'GB must not be queried for a southern-France route whose '
              'only GB touch is a synthetic AABB corner (#2703)');
      // FR genuinely touches the route, so it stays.
      expect(map.keys, contains('FR'),
          reason: 'FR is on the polyline and must be queried');
    });

    test(
        'a GB profile DOES enter the map when the route has a real GB vertex '
        '(CONTROL)', () {
      final container = ProviderContainer(overrides: [
        storageRepositoryProvider.overrideWith((ref) => _NoKeyStorage()),
      ]);
      addTearDown(container.dispose);

      late Ref capturedRef;
      final refCapture = Provider<int>((ref) {
        capturedRef = ref;
        return 0;
      });
      container.read(refCapture);

      final map = buildCorridorServiceMap(
        capturedRef,
        gbVertexRoute,
        const {'GB': FuelType.e10, 'FR': FuelType.e10},
      );

      expect(map.keys, contains('GB'),
          reason: 'a route with a real GB vertex must still query GB');
    });
  });
}
