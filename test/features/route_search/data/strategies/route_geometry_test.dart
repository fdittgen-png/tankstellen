// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/features/route_search/data/strategies/route_geometry.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';

void main() {
  // #2197 — these pin the hoisted route-search geometry helpers so the
  // three strategies (cheapest/balanced/eco) and the provider keep
  // bit-identical behaviour after de-duplication.

  group('kSamplePointSpacingKm', () {
    test('is the 15 km sampling approximation the strategies used', () {
      expect(kSamplePointSpacingKm, 15.0);
    });
  });

  group('segmentIndexFor', () {
    test('floors nearestSampleIdx * 15 / segmentKm against a known spacing', () {
      // With a 50 km segment width and 15 km sample spacing, sample
      // indices 0..3 (0,15,30,45 km) all fall in bucket 0, index 4
      // (60 km) crosses into bucket 1, index 7 (105 km) into bucket 2.
      const segmentKm = 50.0;
      expect(segmentIndexFor(0, segmentKm), 0);
      expect(segmentIndexFor(1, segmentKm), 0); // 15/50  -> 0.30
      expect(segmentIndexFor(3, segmentKm), 0); // 45/50  -> 0.90
      expect(segmentIndexFor(4, segmentKm), 1); // 60/50  -> 1.20
      expect(segmentIndexFor(6, segmentKm), 1); // 90/50  -> 1.80
      expect(segmentIndexFor(7, segmentKm), 2); // 105/50 -> 2.10
    });

    test('exact bucket boundary lands in the upper bucket', () {
      // 10 km segments: index 2 -> 30 km -> exactly 3.0 -> bucket 3.
      expect(segmentIndexFor(2, 10.0), 3);
      // index 0 always bucket 0 regardless of segment width.
      expect(segmentIndexFor(0, 10.0), 0);
    });

    test('is identical to the original inlined expression', () {
      for (final idx in [0, 1, 5, 12, 37]) {
        for (final seg in [10.0, 25.0, 50.0, 80.0]) {
          expect(
            segmentIndexFor(idx, seg),
            (idx * 15 / seg).floor(),
            reason: 'idx=$idx seg=$seg',
          );
        }
      }
    });
  });

  group('minDistanceToPolyline', () {
    test('returns infinity for an empty polyline', () {
      expect(minDistanceToPolyline(48.0, 2.0, const []), double.infinity);
    });

    test('returns 0 when the point sits on a vertex', () {
      final line = [const LatLng(48.0, 2.0), const LatLng(48.1, 2.1)];
      expect(minDistanceToPolyline(48.0, 2.0, line), 0);
    });

    test('finds the nearest vertex, not the first', () {
      final line = [
        const LatLng(48.0, 2.0),
        const LatLng(49.0, 3.0),
        const LatLng(48.5, 2.5),
      ];
      // Query right next to the middle/last vertices.
      final d = minDistanceToPolyline(48.5, 2.5, line);
      expect(d, lessThan(1.0));
    });
  });

  group('sortByItineraryOrder', () {
    Station makeStation(String id, double lat, double lng) => Station(
          id: id,
          name: 'Station $id',
          brand: 'Brand $id',
          street: 'Street $id',
          postCode: '75000',
          place: 'Paris',
          lat: lat,
          lng: lng,
          dist: 1.0,
          isOpen: true,
        );

    test('orders results by position along the route, start first', () {
      final geometry = [
        const LatLng(48.0, 2.0),
        const LatLng(48.1, 2.1),
        const LatLng(48.2, 2.2),
      ];
      final near = FuelStationResult(makeStation('start', 48.01, 2.01));
      final far = FuelStationResult(makeStation('end', 48.19, 2.19));

      final items = <SearchResultItem>[far, near];
      sortByItineraryOrder(items, geometry);

      expect(items.first.id, 'start');
      expect(items.last.id, 'end');
    });
  });
}
