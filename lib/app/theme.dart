// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

/// Calm forest-green palette (#1757) — the app's professional default
/// look, drawn from the green-shield app icon (`#2E7D32`).
///
/// Muted, natural greens with no electric blue; the old bright
/// `bahamaBlue` scheme read as far too intense. Surfaces are softly
/// green-tinted off-white (see [AppTheme.light]'s `blendLevel`) so the
/// app feels calm and low-contrast while staying legible.
const FlexSchemeColor _forestGreen = FlexSchemeColor(
  primary: Color(0xFF2E7D32),
  primaryContainer: Color(0xFFB4D6B6),
  secondary: Color(0xFF4E6B52),
  secondaryContainer: Color(0xFFD6E4D7),
  tertiary: Color(0xFF3C6E63),
  tertiaryContainer: Color(0xFFCFE3DC),
  appBarColor: Color(0xFFD6E4D7),
  error: Color(0xFFB3261E),
);

class AppTheme {
  AppTheme._();

  /// Default light theme (#1757, retuned #1887) — calm forest green.
  ///
  /// #1887 — the previous tuning still read as a generic bright-day
  /// light theme with a stark dark-green accent. The surface
  /// green-tint is raised well up (`blendLevel` 14 → 26) so every
  /// surface — scaffold, cards, chrome — is a deliberate soft
  /// sage-green-tinted off-white. That carries the brand identity
  /// across the whole app *and* narrows the jarring gap between the
  /// forest-green filled surfaces and their background, so the accent
  /// reads as part of a green family rather than a high-contrast
  /// stamp on white. The forest-green accent itself is unchanged.
  static ThemeData light() {
    return FlexThemeData.light(
      colors: _forestGreen,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 26,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 18,
        blendOnColors: false,
        useMaterial3Typography: true,
        useM2StyleDividerInM3: true,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorRadius: 12.0,
        cardRadius: 12.0,
        filledButtonRadius: 12.0,
        outlinedButtonRadius: 12.0,
      ),
      useMaterial3: true,
    );
  }

  /// Dark theme — the forest-green palette adjusted for a dark surface,
  /// kept coherent with [light] (#1757, retuned #1887).
  ///
  /// #1887 — the surface green-tint is lifted (`blendLevel` 16 → 22)
  /// in step with [light], so the dark surfaces carry the same
  /// deliberate green identity rather than reading as neutral charcoal.
  static ThemeData dark() {
    return FlexThemeData.dark(
      colors: _forestGreen.toDark(28),
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 22,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 20,
        useMaterial3Typography: true,
        useM2StyleDividerInM3: true,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorRadius: 12.0,
        cardRadius: 12.0,
        filledButtonRadius: 12.0,
        outlinedButtonRadius: 12.0,
      ),
      useMaterial3: true,
    );
  }

  /// The green **Eco** theme (#1712, redesigned #2244) — the app's
  /// signature look, named for the fuel-savings identity in the app icon.
  ///
  /// It is a light-family theme (never dark — no harsh green-on-black),
  /// but it is now an *unmistakably* green theme rather than the faint
  /// off-white variant of [light] it used to be (#2244). The user feedback
  /// was that eco "is a very slight variation of light"; this redesign
  /// makes it deliberately, recognisably green and pushes the brand
  /// identity colour (the icon's `#2E7D32`) front and centre:
  ///
  ///   * It is built on the same brand [_forestGreen] palette as [light]
  ///     and [dark] — not the generic `FlexScheme.money` — so the identity
  ///     green is the literal `#2E7D32` from the app icon.
  ///   * `surfaceMode` is [FlexSurfaceMode.highScaffoldLevelSurface] with a
  ///     high `blendLevel` (40): the scaffold background gets a 3× green
  ///     blend so the *background* reads as a clear soft green, while
  ///     cards/dialogs (level surfaces, 1×) keep a gentler tint so text and
  ///     content stay legible on them.
  ///   * The AppBar is filled with the brand green
  ///     (`appBarStyle: primary` + `appBarBackgroundSchemeColor: primary`)
  ///     so the chrome reads "eco" at a glance. Foreground defaults to the
  ///     onPrimary complement (white); `#2E7D32` vs white is 5.13:1,
  ///     comfortably past the WCAG AA 4.5:1 floor (see
  ///     `core/theme/contrast_utils.dart`).
  ///   * `blendOnLevel` is lifted (16 → 24) so primary containers and
  ///     accents carry more brand green throughout the app.
  ///
  /// Scope: this brand-green-forward push is intentionally contained to
  /// eco. [light] and [dark] keep their surface-coloured app bars; a
  /// green-app-bar repaint of the default themes is a separate change.
  static ThemeData eco() {
    return FlexThemeData.light(
      colors: _forestGreen,
      surfaceMode: FlexSurfaceMode.highScaffoldLevelSurface,
      blendLevel: 40,
      appBarStyle: FlexAppBarStyle.primary,
      appBarElevation: 0.0,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 24,
        blendOnColors: false,
        appBarBackgroundSchemeColor: SchemeColor.primary,
        useMaterial3Typography: true,
        useM2StyleDividerInM3: true,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorRadius: 12.0,
        cardRadius: 12.0,
        filledButtonRadius: 12.0,
        outlinedButtonRadius: 12.0,
      ),
      useMaterial3: true,
    );
  }
}
