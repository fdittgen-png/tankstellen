// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/radar/geo_tile.dart';

void main() {
  group('GeoTile.fromLatLng + bounds', () {
    test('buckets a point into the floor-indexed cell', () {
      // 0.5° step → 48.7 floors to index 97 (48.5), 2.3 floors to 4 (2.0).
      final t = GeoTile.fromLatLng(48.7, 2.3, stepDegrees: 0.5);
      expect(t.latIndex, 97);
      expect(t.lngIndex, 4);
      expect(t.originLat, closeTo(48.5, 1e-9));
      expect(t.originLng, closeTo(2.0, 1e-9));
      expect(t.centerLat, closeTo(48.75, 1e-9));
    });

    test('contains is true inside the cell, false just outside', () {
      // Cell 97:4 spans lat [48.5, 49.0) × lng [2.0, 2.5).
      final t = GeoTile.fromLatLng(48.7, 2.3, stepDegrees: 0.5);
      expect(t.contains(48.6, 2.1), isTrue);
      expect(t.contains(49.01, 2.4), isFalse); // next lat cell (≥ 49.0)
      expect(t.contains(48.6, 2.6), isFalse); // next lng cell (≥ 2.5)
    });

    test('id encodes step + indices and is stable', () {
      const a = GeoTile(latIndex: 97, lngIndex: 4, stepDegrees: 0.5);
      final b = GeoTile.fromLatLng(48.7, 2.3, stepDegrees: 0.5);
      expect(a.id, b.id);
      expect(a.id, 't:0.5/97:4');
      // Different step → different id even at same indices (no collision).
      expect(const GeoTile(latIndex: 97, lngIndex: 4, stepDegrees: 1.0).id,
          isNot(a.id));
    });

    test('equality + hashCode key a Set correctly', () {
      final set = <GeoTile>{
        GeoTile.fromLatLng(48.7, 2.3, stepDegrees: 0.5),
        GeoTile.fromLatLng(48.7, 2.3, stepDegrees: 0.5),
      };
      expect(set.length, 1);
    });
  });

  group('GeoTile.tilesForBox', () {
    test('covers the rectangle of tiles a corridor box spans', () {
      // ~1° lat × ~1° lng box at 0.5° step → 3×3 = up to 9 cells
      // (boundaries inclusive on the floor).
      final tiles = GeoTile.tilesForBox(
        minLat: 48.1,
        minLng: 2.1,
        maxLat: 49.1,
        maxLng: 3.1,
        stepDegrees: 0.5,
      );
      // lat floors: 48.1→96, 49.1→98 → indices 96,97,98 (3)
      // lng floors: 2.1→4, 3.1→6 → indices 4,5,6 (3)
      expect(tiles.length, 9);
      expect(
        tiles.contains(const GeoTile(latIndex: 96, lngIndex: 4, stepDegrees: 0.5)),
        isTrue,
      );
      expect(
        tiles.contains(const GeoTile(latIndex: 98, lngIndex: 6, stepDegrees: 0.5)),
        isTrue,
      );
    });

    test('tolerates swapped min/max', () {
      final a = GeoTile.tilesForBox(
        minLat: 49.1, minLng: 3.1, maxLat: 48.1, maxLng: 2.1, stepDegrees: 0.5,
      );
      final b = GeoTile.tilesForBox(
        minLat: 48.1, minLng: 2.1, maxLat: 49.1, maxLng: 3.1, stepDegrees: 0.5,
      );
      expect(a, b);
    });
  });

  group('GeoTile neighbours + tileAhead', () {
    test('neighbours returns the 8 Moore cells', () {
      const t = GeoTile(latIndex: 10, lngIndex: 10, stepDegrees: 0.5);
      final n = t.neighbours();
      expect(n.length, 8);
      expect(n.contains(t), isFalse); // excludes self
      expect(
        n.contains(const GeoTile(latIndex: 11, lngIndex: 11, stepDegrees: 0.5)),
        isTrue,
      );
    });

    test('tileAhead steps north for heading 0', () {
      const t = GeoTile(latIndex: 10, lngIndex: 10, stepDegrees: 0.5);
      final ahead = t.tileAhead(0);
      expect(ahead.latIndex, 11); // +lat = north
      expect(ahead.lngIndex, 10);
    });

    test('tileAhead steps east for heading 90', () {
      const t = GeoTile(latIndex: 10, lngIndex: 10, stepDegrees: 0.5);
      final ahead = t.tileAhead(90);
      expect(ahead.latIndex, 10);
      expect(ahead.lngIndex, 11); // +lng = east
    });

    test('tileAhead steps the diagonal for heading 45', () {
      const t = GeoTile(latIndex: 10, lngIndex: 10, stepDegrees: 0.5);
      final ahead = t.tileAhead(45);
      expect(ahead.latIndex, 11);
      expect(ahead.lngIndex, 11);
    });

    test('tileAhead returns self for non-finite heading', () {
      const t = GeoTile(latIndex: 10, lngIndex: 10, stepDegrees: 0.5);
      expect(t.tileAhead(double.nan), t);
    });
  });
}
