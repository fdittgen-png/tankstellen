// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/radar_closeness.dart';

/// #2984 — unit pins for the shared Fuel Station Radar closeness helper. The
/// real radar list-card surface is exercised in `radar_closeness_bar_test.dart`
/// (the regression lock) and `radar_closeness_absolute_test.dart` (the absolute
/// stability lock); this file pins the arithmetic + the never-throws contract
/// the helper documents.

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

  group('RadarCloseness.listScaleMeters — the ABSOLUTE list scale (#2984)', () {
    test('is the search radius, clamped to the tunable cap', () {
      // Below the cap → the radius itself.
      expect(RadarCloseness.listScaleMeters(10000), 10000);
      // At / above the cap → the cap (a wide radius does not stretch the scale).
      expect(RadarCloseness.listScaleMeters(15000),
          kRadarClosenessScaleCapMeters);
      expect(RadarCloseness.listScaleMeters(25000),
          kRadarClosenessScaleCapMeters);
      expect(RadarCloseness.listScaleMeters(25000),
          math.min(25000.0, kRadarClosenessScaleCapMeters));
    });

    test('the cap defaults to 15 km and is the maintainer-tunable knob', () {
      expect(kRadarClosenessScaleCapMeters, 15000);
    });

    test('the worked examples on a 15 km scale (radius ≥ cap): '
        '2.5≈0.83, 7.2≈0.52, 10.3≈0.31, 13≈0.13', () {
      final scale = RadarCloseness.listScaleMeters(20000)!; // → 15 km cap
      expect(RadarCloseness.fillFor(2500, scale), closeTo(0.8333, 1e-3));
      expect(RadarCloseness.fillFor(7200, scale), closeTo(0.52, 1e-3));
      expect(RadarCloseness.fillFor(10300, scale), closeTo(0.3133, 1e-3));
      expect(RadarCloseness.fillFor(13000, scale), closeTo(0.1333, 1e-3));
    });

    test('null for a degenerate radius (collapses the bar)', () {
      expect(RadarCloseness.listScaleMeters(0), isNull);
      expect(RadarCloseness.listScaleMeters(-1), isNull);
      expect(RadarCloseness.listScaleMeters(double.nan), isNull);
      expect(RadarCloseness.listScaleMeters(double.infinity), isNull);
    });
  });

  // The helper documents "Never throws" — pin the fault paths so a degenerate
  // input (the kind that produced the recurring divide-by-zero / NaN scaling
  // bugs) returns normally instead of blowing up the card build (#2984).
  group('RadarCloseness — never-throws contract (#2984)', () {
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

    test('listScaleMeters returns normally on a degenerate radius', () {
      expect(() => RadarCloseness.listScaleMeters(0), returnsNormally);
      expect(() => RadarCloseness.listScaleMeters(double.nan), returnsNormally);
    });
  });
}
