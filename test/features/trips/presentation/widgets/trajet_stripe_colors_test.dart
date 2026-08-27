// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Pins the trajet-stripe colour binding so a future theme rework
// can't silently collapse the two hues onto the same olive/brown —
// the regression that prompted #2108.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/trips/domain/obd2_engine_coverage.dart';
import 'package:tankstellen/features/trips/domain/trajet_data_quality.dart';
import 'package:tankstellen/features/trips/domain/trip_recorder.dart'
    show TripKind;
import 'package:tankstellen/features/trips/presentation/widgets/trajet_stripe_colors.dart';

void main() {
  group('TrajetStripeColors (#2108)', () {
    test('OBD2 light + dark are visibly distinct from GPS-only light + dark',
        () {
      // Pin the exact values so a future "let me tweak the green a bit"
      // doesn't accidentally converge them again.
      expect(TrajetStripeColors.obd2Light, const Color(0xFF2E7D32));
      expect(TrajetStripeColors.obd2Dark, const Color(0xFF66BB6A));
      expect(TrajetStripeColors.gpsOnlyLight, const Color(0xFF3A6EA5));
      expect(TrajetStripeColors.gpsOnlyDark, const Color(0xFF7BAEDF));
    });

    test('forKind routes gpsPlusObd2 → green and any other kind → blue', () {
      // Light brightness.
      expect(
        TrajetStripeColors.forQuality(TrajetDataQuality.obd2Healthy, Brightness.light),
        TrajetStripeColors.obd2Light,
      );
      expect(
        TrajetStripeColors.forQuality(TrajetDataQuality.gpsOnly, Brightness.light),
        TrajetStripeColors.gpsOnlyLight,
      );

      // Dark brightness.
      expect(
        TrajetStripeColors.forQuality(TrajetDataQuality.obd2Healthy, Brightness.dark),
        TrajetStripeColors.obd2Dark,
      );
      expect(
        TrajetStripeColors.forQuality(TrajetDataQuality.gpsOnly, Brightness.dark),
        TrajetStripeColors.gpsOnlyDark,
      );
    });

    test(
        'green family and blue family have meaningfully different hues — RGB '
        'distance > 100 at both brightnesses', () {
      // Cheap proxy for "visibly distinct" — Manhattan distance in
      // RGB space. The pre-#2108 bug had both stripes resolving to
      // shades of the same forest green where the Manhattan distance
      // was ~20–40. Anything > 100 is comfortably distinguishable at
      // 4 dp width on a phone screen.
      int dist(Color a, Color b) =>
          ((a.r * 255 - b.r * 255).abs() +
                  (a.g * 255 - b.g * 255).abs() +
                  (a.b * 255 - b.b * 255).abs())
              .round();
      expect(
        dist(TrajetStripeColors.obd2Light, TrajetStripeColors.gpsOnlyLight),
        greaterThan(100),
        reason: 'OBD2 light + GPS-only light must be visibly distinct.',
      );
      expect(
        dist(TrajetStripeColors.obd2Dark, TrajetStripeColors.gpsOnlyDark),
        greaterThan(100),
        reason: 'OBD2 dark + GPS-only dark must be visibly distinct.',
      );
    });
  });

  group('#3835 the degraded state is visually distinct from both', () {
    test('red is not confusable with the healthy green or the GPS blue', () {
      for (final b in [Brightness.light, Brightness.dark]) {
        final red = TrajetStripeColors.forQuality(
            TrajetDataQuality.obd2Degraded, b);
        final green =
            TrajetStripeColors.forQuality(TrajetDataQuality.obd2Healthy, b);
        final blue =
            TrajetStripeColors.forQuality(TrajetDataQuality.gpsOnly, b);
        expect(red, isNot(green));
        expect(red, isNot(blue));
        // Red must actually be red-dominant, or the "something went wrong"
        // signal is carried by nothing but position in an enum.
        expect(red.r, greaterThan(red.g));
        expect(red.r, greaterThan(red.b));
      }
    });
  });

  group('#3835 classifier — what the trip DELIVERED, not what it promised', () {
    test('a trip with no adapter and no OBD2 kind is plain GPS, not a fault',
        () {
      expect(
        classifyTrajetQuality(kind: TripKind.gpsOnly, hadAdapter: false),
        TrajetDataQuality.gpsOnly,
      );
    });

    test('adapter present and engine data throughout is healthy', () {
      expect(
        classifyTrajetQuality(
            kind: TripKind.gpsPlusObd2, hadAdapter: true, engineShare: 0.997),
        TrajetDataQuality.obd2Healthy,
      );
    });

    test('THE case this exists for: started on OBD2, delivered mostly GPS',
        () {
      // Previously indistinguishable from a clean recording.
      expect(
        classifyTrajetQuality(
            kind: TripKind.gpsPlusObd2, hadAdapter: true, engineShare: 0.04),
        TrajetDataQuality.obd2Degraded,
      );
      // Adapter present, not one engine sample — the drop-at-start signature.
      expect(
        classifyTrajetQuality(
            kind: TripKind.gpsOnly, hadAdapter: true, engineShare: 0.0),
        TrajetDataQuality.obd2Degraded,
      );
    });

    test('the healthy floor matches Obd2EngineCoverage, not a second opinion',
        () {
      expect(kObd2HealthyShareFloor, Obd2EngineCoverage.fullShareFloor);
      expect(
        classifyTrajetQuality(
            kind: TripKind.gpsPlusObd2,
            hadAdapter: true,
            engineShare: kObd2HealthyShareFloor),
        TrajetDataQuality.obd2Healthy,
      );
    });

    test('a legacy row without the persisted share falls back to RPM', () {
      // Reporting "degraded" on every pre-#3835 trip would be worse than
      // the green-for-everything it replaces, so RPM (which can only come
      // from the adapter) stands in.
      expect(
        classifyTrajetQuality(
            kind: TripKind.gpsPlusObd2, hadAdapter: true, maxRpm: 3200),
        TrajetDataQuality.obd2Healthy,
      );
      expect(
        classifyTrajetQuality(
            kind: TripKind.gpsPlusObd2, hadAdapter: true, maxRpm: 0),
        TrajetDataQuality.obd2Degraded,
      );
    });
  });
}
