// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/confidence_tier_badge.dart';

import '../../../../helpers/pump_app.dart';

/// #2262 — the badge replaced the back-to-front `Confidence: A/B/C`
/// letters with a plain accuracy word + ± band:
///
///   * tier c (fill-ups + OBD2 trip)   → "Accuracy: High · ±3-7%"
///   * tier b (fill-ups, no OBD2 trip) → "Accuracy: Medium · ±10-20%"
///   * tier a (GPS-only, no fill-ups)  → "Accuracy: Low · ±40-60%"
///
/// The tier selection logic itself lives in `calibrationConfidenceTier`
/// and is covered by `calibration_confidence_tier_test.dart`; here we
/// only assert the *presentation*: word, ± band, and that the old A/B/C
/// letters are gone.
void main() {
  group('ConfidenceTierBadge — High (tier c)', () {
    testWidgets('fill-ups + OBD2 trip → "Accuracy: High · ±3-7%"',
        (tester) async {
      await pumpApp(
        tester,
        const ConfidenceTierBadge(samples: 5, hasGpsPlusObd2Trip: true),
      );

      expect(find.text('Accuracy: High · ±3-7%'), findsOneWidget);
    });
  });

  group('ConfidenceTierBadge — Medium (tier b)', () {
    testWidgets('fill-ups but no OBD2 trip → "Accuracy: Medium · ±10-20%"',
        (tester) async {
      await pumpApp(
        tester,
        const ConfidenceTierBadge(samples: 2, hasGpsPlusObd2Trip: false),
      );

      expect(find.text('Accuracy: Medium · ±10-20%'), findsOneWidget);
    });
  });

  group('ConfidenceTierBadge — Low (tier a)', () {
    testWidgets('GPS-only, no fill-ups → "Accuracy: Low · ±40-60%"',
        (tester) async {
      await pumpApp(
        tester,
        const ConfidenceTierBadge(samples: 0, hasGpsPlusObd2Trip: false),
      );

      expect(find.text('Accuracy: Low · ±40-60%'), findsOneWidget);
    });

    testWidgets(
        'OBD2 trip without a fill-up anchor stays Low (logic untouched)',
        (tester) async {
      // No fill-up samples → no anchor → tier a, regardless of OBD2.
      await pumpApp(
        tester,
        const ConfidenceTierBadge(samples: 0, hasGpsPlusObd2Trip: true),
      );

      expect(find.text('Accuracy: Low · ±40-60%'), findsOneWidget);
    });
  });

  group('ConfidenceTierBadge — no back-to-front letters', () {
    testWidgets('never renders the old "Confidence: A/B/C" letters',
        (tester) async {
      await pumpApp(
        tester,
        const ConfidenceTierBadge(samples: 5, hasGpsPlusObd2Trip: true),
      );

      expect(find.textContaining('Confidence:'), findsNothing);
      expect(find.textContaining('Accuracy:'), findsOneWidget);
    });
  });

  group('ConfidenceTierBadge — tooltip rewording', () {
    testWidgets('Medium tooltip nudges the user to record an OBD2 trip',
        (tester) async {
      await pumpApp(
        tester,
        const ConfidenceTierBadge(samples: 2, hasGpsPlusObd2Trip: false),
      );

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, contains('OBD2'));
      expect(tooltip.message, contains('High accuracy'));
    });

    testWidgets('Low tooltip nudges the user to add fill-ups', (tester) async {
      await pumpApp(
        tester,
        const ConfidenceTierBadge(samples: 0, hasGpsPlusObd2Trip: false),
      );

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, contains('fill-ups'));
    });
  });
}
