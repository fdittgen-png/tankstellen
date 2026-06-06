// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/radar_closeness.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

/// #2956 — unit pins for the shared Fuel Station Radar closeness helper. The
/// real radar list-card surface is exercised in `radar_closeness_bar_test.dart`
/// (the regression lock); this file pins the arithmetic + the never-throws
/// contract the helper documents.

Station _at(double distKm) => Station(
      id: 'd-$distKm',
      name: 'n',
      brand: '',
      street: '',
      postCode: '',
      place: '',
      lat: 0,
      lng: 0,
      dist: distKm,
      isOpen: true,
    );

void main() {
  group('RadarCloseness.fillFor — the canonical fill fraction', () {
    test('full at the station, empty at/beyond the radius', () {
      expect(RadarCloseness.fillFor(0, 10000), 1.0);
      expect(RadarCloseness.fillFor(10000, 10000), 0.0);
      expect(RadarCloseness.fillFor(25000, 10000), 0.0); // clamped, no negative
    });

    test('the worked example: radius 10 km → 0.25 km≈0.975, 5 km=0.5, '
        '9.9 km≈0.01', () {
      expect(RadarCloseness.fillFor(250, 10000), closeTo(0.975, 1e-9));
      expect(RadarCloseness.fillFor(5000, 10000), closeTo(0.5, 1e-9));
      expect(RadarCloseness.fillFor(9900, 10000), closeTo(0.01, 1e-9));
    });

    test('clamps to 1 at/under the station (no overflow)', () {
      expect(RadarCloseness.fillFor(-50, 10000), 1.0);
    });
  });

  group('RadarCloseness.spanRadiusMeters — scale to the result span', () {
    test('is the farthest surfaced station distance, in metres', () {
      final stations = [_at(0.265), _at(9.3), _at(9.9), _at(10.0)];
      expect(RadarCloseness.spanRadiusMeters(stations), closeTo(10000, 1e-6));
    });

    test('null for an empty or unlocated set (collapses the bar)', () {
      expect(RadarCloseness.spanRadiusMeters(const []), isNull);
      expect(RadarCloseness.spanRadiusMeters([_at(0)]), isNull);
    });
  });

  // The helper documents "Never throws" — pin the fault paths so a degenerate
  // input (the kind that produced the recurring divide-by-zero / NaN scaling
  // bugs) returns normally instead of blowing up the card build (#2956).
  group('RadarCloseness — never-throws contract (#2956)', () {
    test('fillFor returns normally on a degenerate / non-finite radius', () {
      expect(() => RadarCloseness.fillFor(100, 0), returnsNormally);
      expect(() => RadarCloseness.fillFor(100, -1), returnsNormally);
      expect(() => RadarCloseness.fillFor(100, double.nan), returnsNormally);
      expect(() => RadarCloseness.fillFor(100, double.infinity), returnsNormally);
      // …and the value is the safe "empty" sentinel, not a NaN/negative.
      expect(RadarCloseness.fillFor(100, 0), 0.0);
      expect(RadarCloseness.fillFor(100, double.nan), 0.0);
      expect(RadarCloseness.fillFor(100, double.infinity), 0.0);
    });

    test('spanRadiusMeters returns normally on an empty set', () {
      expect(() => RadarCloseness.spanRadiusMeters(const []), returnsNormally);
    });
  });
}
