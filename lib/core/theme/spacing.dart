// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

/// Standardized spacing constants to replace hardcoded EdgeInsets values.
///
/// Use these instead of `const EdgeInsets.all(16)` or `const SizedBox(height: 8)`.
///
/// The visual grammar (#3948, Epic #3947) adds the tokens every
/// surface-level widget shares — [surfaceMargin] and the tightened
/// [chipPadding] — so `PrimaryCard`, `PanelCard`, the theme's
/// `cardTheme` / `chipTheme` and any screen laying out against them all
/// read from one place.
abstract class Spacing {
  // Base sizes
  static const double xs = 2.0;
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  // Common padding patterns
  static const screenPadding = EdgeInsets.all(xl);
  static const cardPadding = EdgeInsets.all(xl);
  static const cardMargin = EdgeInsets.symmetric(horizontal: md, vertical: xs);
  static const listItemPadding = EdgeInsets.symmetric(horizontal: lg, vertical: md);
  static const sectionGap = SizedBox(height: md);
  static const cardGap = SizedBox(height: md);

  /// Chip padding — horizontal [md] (8) / vertical [sm] (4). #3948 tightened
  /// the horizontal side from [lg] so a 320 dp criteria row holds one more
  /// chip before wrapping; the theme's `chipTheme.padding` carries it to
  /// every Material chip.
  static const chipPadding = EdgeInsets.symmetric(horizontal: md, vertical: sm);

  /// Outer margin of every surface-level card (`PrimaryCard`, `PanelCard`,
  /// `StationCardShell`, the theme's `cardTheme`): [lg] (12) horizontal /
  /// [md] (8) vertical. The 12 dp gutter separates content from the page
  /// edge; the 8 dp rhythm separates one card from the next (#3948).
  static const surfaceMargin = EdgeInsets.symmetric(horizontal: lg, vertical: md);
}
