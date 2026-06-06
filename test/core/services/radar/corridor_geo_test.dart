// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/radar/corridor_geo.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

Station _station(double lat, double lng) => Station(
      id: '$lat,$lng',
      name: 'S',
      brand: 'X',
      street: '',
      postCode: '',
      place: '',
      lat: lat,
      lng: lng,
      isOpen: true,
    );

void main() {
  group('isCorridorCorrupt (#2932)', () {
    test('an empty set is corrupt', () {
      expect(isCorridorCorrupt(const [], 48.0, 2.0, 10, 1.2), isTrue);
    });

    test('a (0,0) station marks the whole set corrupt', () {
      final set = [_station(48.0, 2.0), _station(0, 0)];
      expect(isCorridorCorrupt(set, 48.0, 2.0, 60, 1.2), isTrue);
    });

    test('nearest station within radius × tolerance is NOT corrupt', () {
      // Station ~0 m from the live GPS.
      final set = [_station(48.0, 2.0)];
      expect(isCorridorCorrupt(set, 48.0, 2.0, 10, 1.2), isFalse);
    });

    test('nearest station beyond radius × tolerance IS corrupt', () {
      // Station ~50 km north (0.45° lat) of a live GPS, 10 km corridor.
      final set = [_station(48.45, 2.0)];
      expect(isCorridorCorrupt(set, 48.0, 2.0, 10, 1.2), isTrue);
    });

    test('the tolerance factor widens the accept band', () {
      // ~11 km away with a 10 km radius: corrupt at ×1.0, valid at ×1.2.
      final set = [_station(48.1, 2.0)]; // ~11.1 km north
      expect(isCorridorCorrupt(set, 48.0, 2.0, 10, 1.0), isTrue);
      expect(isCorridorCorrupt(set, 48.0, 2.0, 10, 1.2), isFalse);
    });

    test('the NEAREST station decides — a far outlier alongside a near one '
        'is fine', () {
      final set = [_station(48.0, 2.0), _station(49.0, 2.0)]; // one near, one far
      expect(isCorridorCorrupt(set, 48.0, 2.0, 10, 1.2), isFalse);
    });
  });

  group('corridorBoundingBox (#2932)', () {
    test('encloses the centre and grows with radius', () {
      final box = corridorBoundingBox(48.0, 2.0, 60);
      expect(box.minLat, lessThan(48.0));
      expect(box.maxLat, greaterThan(48.0));
      expect(box.minLng, lessThan(2.0));
      expect(box.maxLng, greaterThan(2.0));
      // Longitude span widens with latitude (cos shrink) vs latitude span.
      final latSpan = box.maxLat - box.minLat;
      final lngSpan = box.maxLng - box.minLng;
      expect(lngSpan, greaterThan(latSpan));
    });
  });
}
