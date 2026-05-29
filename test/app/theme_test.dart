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

    test('AppBar is filled with the brand primary (the eco chrome cue)', () {
      expect(theme.appBarTheme.backgroundColor, theme.colorScheme.primary);
    });

    test('AppBar foreground keeps WCAG AA contrast on the green bar', () {
      final bg = theme.appBarTheme.backgroundColor!;
      final fg = theme.appBarTheme.foregroundColor!;
      expect(
        ContrastUtils.meetsAA(fg, bg),
        isTrue,
        reason: 'AppBar text/icons on the green bar must meet AA (4.5:1); '
            'got ${ContrastUtils.contrastRatio(fg, bg).toStringAsFixed(2)}:1.',
      );
    });

    test('scaffold background is clearly green-tinted, not off-white', () {
      // The high-scaffold blend pushes a visible green into the background:
      // green channel must lead, and it must not be near-white (every
      // channel >= 0xF0), which is what the old faint-variant eco produced.
      final bg = theme.scaffoldBackgroundColor;
      expect(bg.g, greaterThan(bg.r));
      expect(bg.g, greaterThan(bg.b));
      final nearWhite = bg.r >= 0.94 && bg.g >= 0.94 && bg.b >= 0.94;
      expect(
        nearWhite,
        isFalse,
        reason: 'eco scaffold must read as green, not near-white off-white.',
      );
    });

    test('eco scaffold is visibly greener than the light theme scaffold', () {
      // Quantify "distinctly different from light": the green-minus-red
      // lead in eco must exceed light's, proving the stronger green tint.
      final eco = theme.scaffoldBackgroundColor;
      final lightBg = AppTheme.light().scaffoldBackgroundColor;
      expect((eco.g - eco.r), greaterThan(lightBg.g - lightBg.r));
    });
  });
}
