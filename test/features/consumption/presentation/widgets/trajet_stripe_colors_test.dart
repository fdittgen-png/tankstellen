// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Pins the trajet-stripe colour binding so a future theme rework
// can't silently collapse the two hues onto the same olive/brown —
// the regression that prompted #2108.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart'
    show TripKind;
import 'package:tankstellen/features/consumption/presentation/widgets/trajet_stripe_colors.dart';

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
        TrajetStripeColors.forKind(TripKind.gpsPlusObd2, Brightness.light),
        TrajetStripeColors.obd2Light,
      );
      expect(
        TrajetStripeColors.forKind(TripKind.gpsOnly, Brightness.light),
        TrajetStripeColors.gpsOnlyLight,
      );

      // Dark brightness.
      expect(
        TrajetStripeColors.forKind(TripKind.gpsPlusObd2, Brightness.dark),
        TrajetStripeColors.obd2Dark,
      );
      expect(
        TrajetStripeColors.forKind(TripKind.gpsOnly, Brightness.dark),
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
}
