// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/theme/app_text.dart';
import 'package:tankstellen/core/theme/price_band_colors.dart';
import 'package:tankstellen/core/utils/price_tier.dart';
import 'package:tankstellen/features/map/presentation/widgets/price_legend.dart';

import '../../../../helpers/pump_app.dart';

/// The one gradient bar: a Container whose decoration paints a
/// LinearGradient.
Finder _gradientBar() => find.byWidgetPredicate((widget) {
      if (widget is Container && widget.decoration is BoxDecoration) {
        return (widget.decoration as BoxDecoration).gradient
            is LinearGradient;
      }
      return false;
    });

/// Any standalone circular colour swatch (the pre-#3949 legend had three).
Finder _swatchDots() => find.byWidgetPredicate((widget) {
      if (widget is Container && widget.decoration is BoxDecoration) {
        final d = widget.decoration as BoxDecoration;
        return d.shape == BoxShape.circle && d.color != null;
      }
      return false;
    });

void main() {
  group('PriceLegend — one line, one encoding (#3949)', () {
    testWidgets('renders the two end labels in the label role', (
      tester,
    ) async {
      late BuildContext ctx;
      await pumpApp(
        tester,
        Builder(
          builder: (context) {
            ctx = context;
            return const PriceLegend();
          },
        ),
      );

      expect(find.text('cheap'), findsOneWidget);
      expect(find.text('expensive'), findsOneWidget);
      final labelSize = AppText.label(ctx).fontSize;
      expect(tester.widget<Text>(find.text('cheap')).style?.fontSize, labelSize);
      expect(
        tester.widget<Text>(find.text('expensive')).style?.fontSize,
        labelSize,
      );
    });

    testWidgets('the gradient bar is the canonical 4-stop ramp (#2492)', (
      tester,
    ) async {
      await pumpApp(tester, const PriceLegend());

      final bar = _gradientBar();
      expect(bar, findsOneWidget);
      final gradient =
          (tester.widget<Container>(bar).decoration as BoxDecoration).gradient
              as LinearGradient;
      // The legend draws the exact same ramp the markers paint with, so its
      // two ends ARE the cheap and expensive colours — no separate swatches.
      expect(gradient.colors, PriceBandColors.ramp);
      expect(gradient.colors.first, PriceBandColors.cheap);
      expect(gradient.colors.last, PriceBandColors.expensive);
    });

    testWidgets('reads left to right: cheap, bar, expensive on one line', (
      tester,
    ) async {
      await pumpApp(tester, const PriceLegend());

      final cheap = find.text('cheap');
      final bar = _gradientBar();
      final expensive = find.text('expensive');
      expect(tester.getTopLeft(cheap).dx, lessThan(tester.getTopLeft(bar).dx));
      expect(
        tester.getTopLeft(bar).dx,
        lessThan(tester.getTopLeft(expensive).dx),
      );
      expect(
        tester.getCenter(bar).dy,
        closeTo(tester.getCenter(cheap).dy, 4),
      );
    });

    testWidgets('no duplicate encodings: no swatch dots, no tier arrows', (
      tester,
    ) async {
      await pumpApp(tester, const PriceLegend());

      expect(
        _swatchDots(),
        findsNothing,
        reason: 'the bar ends are the swatches; separate dots repeat them',
      );
      for (final tier in [
        PriceTier.cheap,
        PriceTier.average,
        PriceTier.expensive,
      ]) {
        expect(
          find.byIcon(iconForPriceTier(tier)),
          findsNothing,
          reason: 'the ↓ – ↑ arrow is the colour-blind reading and lives on '
              'the markers and cards, not in the legend',
        );
      }
    });

    testWidgets('survives a 320 dp surface without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpApp(tester, const PriceLegend());
      expect(tester.takeException(), isNull);
    });
  });

  group('ZoomButton', () {
    testWidgets('renders with correct icon', (tester) async {
      await pumpApp(
        tester,
        ZoomButton(icon: Icons.add, onPressed: () {}),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await pumpApp(
        tester,
        ZoomButton(icon: Icons.add, onPressed: () => pressed = true),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(pressed, isTrue);
    });

    testWidgets('renders with correct dimensions', (tester) async {
      await pumpApp(
        tester,
        ZoomButton(icon: Icons.remove, onPressed: () {}),
      );

      final container = tester.widget<Container>(
        find.byWidgetPredicate((widget) {
          if (widget is Container && widget.constraints != null) {
            return widget.constraints!.maxWidth == 40 &&
                widget.constraints!.maxHeight == 40;
          }
          return false;
        }),
      );
      expect(container, isNotNull);
    });
  });
}
