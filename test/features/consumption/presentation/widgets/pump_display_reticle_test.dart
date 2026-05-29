// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/pump_display_reticle.dart';

/// Tests for the #1868 pump-display capture reticle overlay.
void main() {
  testWidgets('renders a centred wide framed box', (tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: PumpDisplayReticle(),
    ));

    expect(find.byType(PumpDisplayReticle), findsOneWidget);

    // 86% of the width — leaves a margin so the frame reads as a target.
    final fsb = tester.widget<FractionallySizedBox>(
      find.descendant(
        of: find.byType(PumpDisplayReticle),
        matching: find.byType(FractionallySizedBox),
      ),
    );
    expect(fsb.widthFactor, 0.86);

    // A wide three-number readout shape.
    final aspect = tester.widget<AspectRatio>(
      find.descendant(
        of: find.byType(PumpDisplayReticle),
        matching: find.byType(AspectRatio),
      ),
    );
    expect(aspect.aspectRatio, closeTo(16 / 5, 1e-9));

    // The frame has a visible border.
    final decoration = tester
        .widget<DecoratedBox>(
          find.descendant(
            of: find.byType(PumpDisplayReticle),
            matching: find.byType(DecoratedBox),
          ),
        )
        .decoration as BoxDecoration;
    expect(decoration.border, isNotNull);
  });

  testWidgets('is decorative — ignores pointer events', (tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: PumpDisplayReticle(),
    ));
    // Wrapped in IgnorePointer so taps fall through to the capture
    // button beneath the overlay.
    expect(
      find.descendant(
        of: find.byType(PumpDisplayReticle),
        matching: find.byType(IgnorePointer),
      ),
      findsOneWidget,
    );
  });

  group('normalizedRect (#2275 — OCR crops to the framed reticle)', () {
    test('is centred and matches the drawn widthFactor', () {
      // On a square preview the 86%-wide, 16:5 reticle occupies a
      // proportionally smaller height — and is centred in both axes.
      final r = PumpDisplayReticle.normalizedRect(1.0);
      expect(r.width, closeTo(0.86, 1e-9));
      expect(r.left, closeTo((1 - 0.86) / 2, 1e-9));
      // height = widthFactor * previewAspect / reticleAspect.
      expect(r.height, closeTo(0.86 * 1.0 / (16 / 5), 1e-9));
      expect(r.top, closeTo((1 - r.height) / 2, 1e-9));
    });

    test('stays inside the 0..1 box for a typical portrait preview', () {
      final r = PumpDisplayReticle.normalizedRect(3 / 4);
      expect(r.left, greaterThanOrEqualTo(0));
      expect(r.top, greaterThanOrEqualTo(0));
      expect(r.right, lessThanOrEqualTo(1.0001));
      expect(r.bottom, lessThanOrEqualTo(1.0001));
    });

    test('degenerate aspect ratio falls back to the full frame', () {
      expect(PumpDisplayReticle.normalizedRect(0).width, 1.0);
      expect(PumpDisplayReticle.normalizedRect(-1).height, 1.0);
    });
  });
}
