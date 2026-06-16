// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sensors/compass_heading.dart';

/// #3364 — the tilt-compensated compass azimuth math + circular smoother.
/// Phone held flat (gravity on +Z); the magnetometer's horizontal component
/// points toward magnetic north (with a downward dip in the N hemisphere).
void main() {
  const g = 9.81;

  group('azimuthFromVectors', () {
    test('flat phone, field toward +Y (top) → ~0° (north)', () {
      final az = azimuthFromVectors(0, 0, g, 0, 30, -40);
      expect(az, isNotNull);
      expect(CompassSmoother.delta(az!, 0), lessThan(1));
    });

    test('flat phone rotated so the top faces east → ~90°', () {
      // North is now to the device's left (−X).
      final az = azimuthFromVectors(0, 0, g, -30, 0, -40);
      expect(CompassSmoother.delta(az!, 90), lessThan(1));
    });

    test('flat phone, top faces south → ~180°', () {
      final az = azimuthFromVectors(0, 0, g, 0, -30, -40);
      expect(CompassSmoother.delta(az!, 180), lessThan(1));
    });

    test('flat phone, top faces west → ~270°', () {
      final az = azimuthFromVectors(0, 0, g, 30, 0, -40);
      expect(CompassSmoother.delta(az!, 270), lessThan(1));
    });

    test('degenerate gravity → null', () {
      expect(azimuthFromVectors(0, 0, 0, 0, 30, -40), isNull);
    });

    test('always in [0,360)', () {
      final az = azimuthFromVectors(0, 0, g, 0, -1, -40);
      expect(az, inInclusiveRange(0, 360));
      expect(az, lessThan(360));
    });
  });

  group('CompassSmoother', () {
    test('converges toward a constant heading', () {
      final s = CompassSmoother(alpha: 0.5);
      double out = 0;
      for (var i = 0; i < 40; i++) {
        out = s.add(120);
      }
      expect(CompassSmoother.delta(out, 120), lessThan(0.5));
    });

    test('handles the 360→0 wrap (averages 350 & 10 near 0, not 180)', () {
      final s = CompassSmoother(alpha: 0.5);
      s.add(350);
      final out = s.add(10);
      // Must be near 0/360, never near 180.
      expect(CompassSmoother.delta(out, 0), lessThan(20));
    });

    test('delta is the shortest circular distance', () {
      expect(CompassSmoother.delta(350, 10), closeTo(20, 0.001));
      expect(CompassSmoother.delta(10, 350), closeTo(20, 0.001));
      expect(CompassSmoother.delta(0, 180), closeTo(180, 0.001));
      expect(CompassSmoother.delta(90, 90), 0);
    });
  });
}
