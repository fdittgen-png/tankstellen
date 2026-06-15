// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/utils/geo_utils.dart';
import 'package:tankstellen/features/search/presentation/widgets/radar_scope_geometry.dart';

/// Pins the pure polar mapping behind the PPI radar-scope view (#3342):
/// a station's distance becomes the radial fraction (clamped to the rim at
/// the search radius) and its bearing becomes the on-scope angle (North up).
void main() {
  Station station(String id, double lat, double lng) => Station(
        id: id,
        name: 'Station $id',
        brand: 'TEST',
        street: 'Teststr.',
        postCode: '00000',
        place: 'Test',
        lat: lat,
        lng: lng,
        dist: 1,
        isOpen: true,
      );

  group('bearingDegrees', () {
    const lat = 52.0;
    const lng = 13.0;

    test('due north → ~0°', () {
      expect(bearingDegrees(lat, lng, lat + 0.1, lng), closeTo(0, 0.5));
    });

    test('due east → ~90°', () {
      expect(bearingDegrees(lat, lng, lat, lng + 0.1), closeTo(90, 0.5));
    });

    test('due south → ~180°', () {
      expect(bearingDegrees(lat, lng, lat - 0.1, lng), closeTo(180, 0.5));
    });

    test('due west → ~270°', () {
      expect(bearingDegrees(lat, lng, lat, lng - 0.1), closeTo(270, 0.5));
    });

    test('identical point → 0 (no NaN)', () {
      expect(bearingDegrees(lat, lng, lat, lng), 0);
    });
  });

  group('radarScopeBlips', () {
    test('non-positive range or unusable centre → empty', () {
      expect(radarScopeBlips([station('a', 52.1, 13.0)], 52.0, 13.0, 0),
          isEmpty);
      expect(radarScopeBlips([station('a', 52.1, 13.0)], 0, 0, 10), isEmpty);
    });

    test('a station at the centre maps to fraction 0', () {
      final blips = radarScopeBlips([station('a', 52.0, 13.0)], 52.0, 13.0, 10);
      expect(blips, hasLength(1));
      expect(blips.single.fraction, closeTo(0, 0.001));
    });

    test('an in-range station maps to its distance fraction', () {
      // ~11.1 km north of the centre, range 20 km → fraction ≈ 0.56.
      final blips =
          radarScopeBlips([station('a', 52.1, 13.0)], 52.0, 13.0, 20);
      expect(blips.single.beyondRange, isFalse);
      expect(blips.single.fraction, closeTo(0.556, 0.05));
      expect(blips.single.bearingDeg, closeTo(0, 0.5));
    });

    test('a beyond-range station clamps to the rim and is flagged', () {
      // ~11 km away but range only 5 km → clamped to fraction 1, beyond=true.
      final blips = radarScopeBlips([station('a', 52.1, 13.0)], 52.0, 13.0, 5);
      expect(blips.single.beyondRange, isTrue);
      expect(blips.single.fraction, 1.0);
    });

    test('unusable station coordinates are skipped', () {
      final blips = radarScopeBlips(
        [station('a', 0, 0), station('b', 52.1, 13.0)],
        52.0,
        13.0,
        20,
      );
      expect(blips, hasLength(1));
      expect(blips.single.station.id, 'b');
    });

    test('unit vector places a north blip straight up (−y)', () {
      final blip =
          radarScopeBlips([station('a', 52.1, 13.0)], 52.0, 13.0, 20).single;
      expect(blip.unitDx, closeTo(0, 0.02));
      expect(blip.unitDy, lessThan(0)); // North = up = negative y
    });

    test('#3354 — priceOf stamps each blip with its fuel price', () {
      final blips = radarScopeBlips(
        [station('a', 52.1, 13.0)],
        52.0,
        13.0,
        20,
        priceOf: (s) => 1.799,
      );
      expect(blips.single.price, 1.799);
    });
  });

  group('#3354 — heading-up rotation', () {
    test('driving north keeps a due-north blip at the top (−y)', () {
      final blip =
          radarScopeBlips([station('a', 52.1, 13.0)], 52.0, 13.0, 20).single;
      final o = blip.unitOffset(headingDeg: 0);
      expect(o.dx, closeTo(0, 0.02));
      expect(o.dy, lessThan(0));
    });

    test('driving east rotates a due-north blip to the LEFT (−x)', () {
      final blip =
          radarScopeBlips([station('a', 52.1, 13.0)], 52.0, 13.0, 20).single;
      final o = blip.unitOffset(headingDeg: 90);
      expect(o.dx, lessThan(0)); // North is now to the driver's left
      expect(o.dy, closeTo(0, 0.02));
    });
  });

  group('#3354 — aggregateOverlapping (lowest price wins)', () {
    test('overlapping blips collapse to the cheapest, with a count', () {
      final blips = radarScopeBlips(
        [
          station('pricey', 52.100, 13.0),
          station('cheap', 52.1005, 13.0001), // ~essentially the same spot
        ],
        52.0,
        13.0,
        20,
        priceOf: (s) => s.id == 'cheap' ? 1.599 : 1.899,
      );
      final agg = aggregateOverlapping(blips, minSeparation: 0.2);
      expect(agg, hasLength(1));
      expect(agg.single.station.id, 'cheap');
      expect(agg.single.price, 1.599);
      expect(agg.single.aggregatedCount, 2);
    });

    test('well-separated blips are NOT merged', () {
      final blips = radarScopeBlips(
        [station('n', 52.15, 13.0), station('s', 51.85, 13.0)],
        52.0,
        13.0,
        40,
        priceOf: (s) => 1.7,
      );
      final agg = aggregateOverlapping(blips, minSeparation: 0.16);
      expect(agg, hasLength(2));
      expect(agg.every((b) => b.aggregatedCount == 1), isTrue);
    });
  });
}
