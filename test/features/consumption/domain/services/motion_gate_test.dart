// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/services/motion_gate.dart';

/// #3319 — the pure stop-detection state machine that backs the recording
/// GPS receiver off (fine → coarse) once the device has been stationary,
/// using only the GPS speed (+ optional IMU) signals the recorder already has.
void main() {
  group('MotionGate', () {
    test('starts fine so a trip records at full rate immediately', () {
      expect(MotionGate().profile, GpsProfile.fine);
    });

    test('a clearly-moving fix keeps it fine', () {
      final g = MotionGate();
      expect(
        g.onFix(speedKmh: 50, elapsed: const Duration(seconds: 1)),
        GpsProfile.fine,
      );
    });

    test('sustained slow+still for >= stationaryAfter → coarse', () {
      final g = MotionGate(stationaryAfter: const Duration(seconds: 20));
      // First slow fix arms the timer but does not yet flip.
      expect(g.onFix(speedKmh: 0, elapsed: const Duration(seconds: 1)),
          GpsProfile.fine);
      // Still slow at +10 s — not long enough.
      expect(g.onFix(speedKmh: 0.5, elapsed: const Duration(seconds: 11)),
          GpsProfile.fine);
      // Slow through the full window → coarse.
      expect(g.onFix(speedKmh: 0, elapsed: const Duration(seconds: 22)),
          GpsProfile.coarse);
    });

    test('a moving fix re-fines immediately from coarse and re-arms', () {
      final g = MotionGate(stationaryAfter: const Duration(seconds: 20));
      g.onFix(speedKmh: 0, elapsed: const Duration(seconds: 0));
      g.onFix(speedKmh: 0, elapsed: const Duration(seconds: 25));
      expect(g.profile, GpsProfile.coarse);
      // Pulling away — back to fine at once.
      expect(g.onFix(speedKmh: 30, elapsed: const Duration(seconds: 26)),
          GpsProfile.fine);
      // And the stillness timer was reset: one slow fix doesn't re-coarse.
      expect(g.onFix(speedKmh: 0, elapsed: const Duration(seconds: 27)),
          GpsProfile.fine);
    });

    test('a single stray slow fix in motion does not flip to coarse', () {
      final g = MotionGate(stationaryAfter: const Duration(seconds: 20));
      g.onFix(speedKmh: 40, elapsed: const Duration(seconds: 0));
      // One slow fix (traffic light tap) then moving again, well within window.
      g.onFix(speedKmh: 1, elapsed: const Duration(seconds: 2));
      expect(g.onFix(speedKmh: 45, elapsed: const Duration(seconds: 3)),
          GpsProfile.fine);
    });

    test('intermediate (rolling) speed holds the current profile and breaks '
        'the stillness timer', () {
      final g = MotionGate(
        stationarySpeedKmh: 3,
        movingSpeedKmh: 8,
        stationaryAfter: const Duration(seconds: 10),
      );
      g.onFix(speedKmh: 0, elapsed: const Duration(seconds: 0)); // arm
      // Rolling at 5 km/h (between thresholds) breaks the timer...
      expect(g.onFix(speedKmh: 5, elapsed: const Duration(seconds: 5)),
          GpsProfile.fine);
      // ...so being slow again only now restarts the clock — not coarse yet.
      expect(g.onFix(speedKmh: 0, elapsed: const Duration(seconds: 12)),
          GpsProfile.fine);
    });

    group('IMU fusion (GPS-only trips)', () {
      test('IMU stillness is required to coarse — a still IMU + slow speed '
          'coarsens', () {
        final g = MotionGate(stationaryAfter: const Duration(seconds: 10));
        g.onFix(
            speedKmh: 0, imuMagnitude: 0.1, elapsed: const Duration(seconds: 0));
        expect(
          g.onFix(
              speedKmh: 0,
              imuMagnitude: 0.1,
              elapsed: const Duration(seconds: 11)),
          GpsProfile.coarse,
        );
      });

      test('a busy IMU keeps it fine even when GPS speed reads ~0 '
          '(GPS drift while the car shakes)', () {
        final g = MotionGate(stationaryAfter: const Duration(seconds: 10));
        g.onFix(
            speedKmh: 0, imuMagnitude: 2.0, elapsed: const Duration(seconds: 0));
        expect(
          g.onFix(
              speedKmh: 0,
              imuMagnitude: 2.0,
              elapsed: const Duration(seconds: 11)),
          GpsProfile.fine,
          reason: 'IMU above the moving threshold → never stationary',
        );
      });

      test('an IMU spike re-fines from coarse immediately', () {
        final g = MotionGate(stationaryAfter: const Duration(seconds: 10));
        g.onFix(
            speedKmh: 0, imuMagnitude: 0.1, elapsed: const Duration(seconds: 0));
        g.onFix(
            speedKmh: 0,
            imuMagnitude: 0.1,
            elapsed: const Duration(seconds: 11));
        expect(g.profile, GpsProfile.coarse);
        expect(
          g.onFix(
              speedKmh: 0, imuMagnitude: 3.0, elapsed: const Duration(seconds: 12)),
          GpsProfile.fine,
        );
      });
    });

    test('reset returns to the initial fine profile', () {
      final g = MotionGate(stationaryAfter: const Duration(seconds: 5));
      g.onFix(speedKmh: 0, elapsed: const Duration(seconds: 0));
      g.onFix(speedKmh: 0, elapsed: const Duration(seconds: 6));
      expect(g.profile, GpsProfile.coarse);
      g.reset();
      expect(g.profile, GpsProfile.fine);
    });
  });
}
