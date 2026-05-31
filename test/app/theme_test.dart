// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/theme.dart';
import 'package:tankstellen/core/theme/contrast_utils.dart';

void main() {
  group('AppTheme.light', () {
    final theme = AppTheme.light();

    test('uses Material 3', () {
      expect(theme.useMaterial3, isTrue);
    });

    test('has light brightness', () {
      expect(theme.brightness, Brightness.light);
    });

    test('primary colour lands in the green family (#1757 forest green)', () {
      final p = theme.colorScheme.primary;
      expect(p.g, greaterThan(p.r));
      expect(p.g, greaterThan(p.b));
    });
  });

  group('AppTheme.dark', () {
    final theme = AppTheme.dark();

    test('uses Material 3', () {
      expect(theme.useMaterial3, isTrue);
    });

    test('has dark brightness', () {
      expect(theme.brightness, Brightness.dark);
    });

    test('dark primary is also in the green family', () {
      final p = theme.colorScheme.primary;
      expect(p.g, greaterThan(p.r));
      expect(p.g, greaterThan(p.b));
    });
  });

  test('light and dark have distinct brightness values', () {
    expect(AppTheme.light().brightness, Brightness.light);
    expect(AppTheme.dark().brightness, Brightness.dark);
  });

  group('AppTheme.eco (#2244 — distinctly green, brand-green-forward)', () {
    final theme = AppTheme.eco();

    test('is a light-family theme (never dark)', () {
      expect(theme.brightness, Brightness.light);
    });

    test('primary is the brand green family', () {
      final p = theme.colorScheme.primary;
      expect(p.g, greaterThan(p.r));
      expect(p.g, greaterThan(p.b));
    });

    test('AppBar is tonal — filled with primaryContainer (#2488)', () {
      // #2488 — the eco AppBar is now a tonal `primaryContainer` rather
      // than full primary, harmonising the chrome with the PageScaffold
      // banner while still reading "eco" at a glance.
      expect(
        theme.appBarTheme.backgroundColor,
        theme.colorScheme.primaryContainer,
      );
    });

    test('AppBar foreground keeps WCAG AA contrast on the tonal bar', () {
      final bg = theme.appBarTheme.backgroundColor!;
      final fg = theme.appBarTheme.foregroundColor!;
      expect(
        ContrastUtils.meetsAA(fg, bg),
        isTrue,
        reason: 'AppBar text/icons on the tonal bar must meet AA (4.5:1); '
            'got ${ContrastUtils.contrastRatio(fg, bg).toStringAsFixed(2)}:1.',
      );
    });

    test('scaffold keeps a green tint (green channel leads)', () {
      // #2488 de-inverts the ramp: the scaffold is now the *lowest* surface
      // (near-white, like light) so green content reads on it again, but it
      // still carries a green hint — the green channel leads.
      final bg = theme.scaffoldBackgroundColor;
      expect(bg.g, greaterThan(bg.r));
      expect(bg.g, greaterThan(bg.b));
    });

    test('eco is clearly greener than light — now in the CARDS, not scaffold',
        () {
      // #2244's "recognisably green" mandate is preserved through the #2488
      // de-inversion, but the deeper green now lives in the card/container
      // surfaces (blendLevel 20 vs light's 8) rather than an over-green
      // scaffold. Both the scaffold tint and the card tint exceed light's.
      final lightTheme = AppTheme.light();
      final ecoScaffold = theme.scaffoldBackgroundColor;
      final lightScaffold = lightTheme.scaffoldBackgroundColor;
      expect(
        (ecoScaffold.g - ecoScaffold.r),
        greaterThan(lightScaffold.g - lightScaffold.r),
        reason: 'eco scaffold must read greener than light.',
      );
      final ecoCard = theme.colorScheme.surfaceContainerLow;
      final lightCard = lightTheme.colorScheme.surfaceContainerLow;
      expect(
        (ecoCard.g - ecoCard.r),
        greaterThan(lightCard.g - lightCard.r),
        reason: 'eco cards must read greener than light cards.',
      );
    });

    test('surface ramp is de-inverted — runs the same way as light (#2488)', () {
      // The #2244 bug was an *inverted* ramp: the scaffold was a deep green
      // sitting ABOVE the cards in green-intensity, killing the contrast of
      // green content on the page. With levelSurfacesLowScaffold (the light
      // family) the scaffold is the lightest surface and cards carry the
      // green tint — the SAME direction as light. Verify eco's ramp matches
      // light's sign: card is darker (greener) than the scaffold.
      double lum(Color c) => ContrastUtils.relativeLuminance(c);
      final ecoDelta = lum(theme.scaffoldBackgroundColor) -
          lum(theme.colorScheme.surfaceContainerLow);
      final light = AppTheme.light();
      final lightDelta = lum(light.scaffoldBackgroundColor) -
          lum(light.colorScheme.surfaceContainerLow);
      expect(
        ecoDelta,
        greaterThan(0),
        reason: 'scaffold must be lighter than the card (ramp not inverted).',
      );
      expect(
        lightDelta,
        greaterThan(0),
        reason: 'light has the canonical ramp direction eco now matches.',
      );
    });

    test('eco gives cards a 1 dp elevation for a real card↔scaffold delta', () {
      expect(theme.cardTheme.elevation, 1.0);
    });
  });

  group('Floating SnackBar theme (#2488)', () {
    for (final entry in {
      'light': AppTheme.light(),
      'dark': AppTheme.dark(),
      'eco': AppTheme.eco(),
    }.entries) {
      test('${entry.key} SnackBar floats clear of the nav bar', () {
        final snack = entry.value.snackBarTheme;
        expect(snack.behavior, SnackBarBehavior.floating);
        expect(snack.elevation, 6.0);
        // Radius 12 is applied via a RoundedRectangleBorder shape.
        final shape = snack.shape as RoundedRectangleBorder;
        final radius = shape.borderRadius.resolve(TextDirection.ltr).topLeft;
        expect(radius.x, 12.0);
      });
    }
  });
}
