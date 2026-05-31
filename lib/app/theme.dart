// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_radius.dart';

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

  /// Floating-SnackBar geometry shared by all three themes (#2488).
  ///
  /// FlexColorScheme's `snackBarRadius` / `snackBarElevation` flow through
  /// `subThemesData`, but it never sets [SnackBarThemeData.behavior] — so
  /// SnackBars default to the docked (fixed) style, which clips against the
  /// bottom navigation bar on full-screen routes. We overlay
  /// [SnackBarBehavior.floating] on the generated `snackBarTheme` (preserving
  /// Flex's colour/shape) so every SnackBar floats clear of the nav bar.
  static ThemeData _floatingSnackBars(ThemeData theme) => theme.copyWith(
        snackBarTheme: theme.snackBarTheme.copyWith(
          behavior: SnackBarBehavior.floating,
        ),
      );

  /// Default light theme (#1757, retuned #1887, de-greyed #2375) — clean
  /// forest-green accent on a near-white surface.
  ///
  /// #2375 — #1887 had raised `blendLevel` 14 → 26 to make every surface a
  /// "soft sage-green-tinted off-white". In practice, blending the *dark,
  /// semi-desaturated* brand green `#2E7D32` into white at level 26 reads as
  /// muddy **grey-green** — on the scaffold and on every `surfaceContainer`
  /// card — not soft green. Repeated user feedback called the background
  /// "grey". So the surface blend is cut back hard (`blendLevel` 26 → 8,
  /// `blendOnLevel` 18 → 10): surfaces are now a clean, light off-white with
  /// only a faint green hint, while the forest-green *accent* (buttons,
  /// chrome, icons) is unchanged and now reads crisply against the clean
  /// background instead of being muddied into it. The deliberately
  /// green-forward look lives in [eco]; [light] is the clean default.
  static ThemeData light() {
    return _floatingSnackBars(FlexThemeData.light(
      colors: _forestGreen,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 8,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 10,
        blendOnColors: false,
        useMaterial3Typography: true,
        useM2StyleDividerInM3: true,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorRadius: 12.0,
        cardRadius: 12.0,
        filledButtonRadius: 12.0,
        outlinedButtonRadius: 12.0,
        // #2494 — every Material Chip shares the canonical pill corner
        // (AppRadius.xl = 16), matching the bespoke SelectablePill/AppPill
        // shapes so chips read as one family across the app.
        chipRadius: AppRadius.radiusXl,
        // #2488 — light keeps its tint-only card separation: the near-white
        // scaffold (blendLevel 8) and `surfaceContainerLow` cards already
        // read apart, so no shadow (the M3 elevated-card default would be
        // 1 dp). [SectionCard]'s hairline outline reinforces it.
        cardElevation: 0.0,
        // Floating SnackBar geometry (#2488) — radius + elevation; the
        // floating behaviour itself is overlaid by [_floatingSnackBars].
        snackBarRadius: 12.0,
        snackBarElevation: 6.0,
      ),
      useMaterial3: true,
    ));
  }

  /// Dark theme — the forest-green palette adjusted for a dark surface,
  /// kept coherent with [light] (#1757, retuned #1887).
  ///
  /// #1887 — the surface green-tint is lifted (`blendLevel` 16 → 22)
  /// in step with [light], so the dark surfaces carry the same
  /// deliberate green identity rather than reading as neutral charcoal.
  static ThemeData dark() {
    return _floatingSnackBars(FlexThemeData.dark(
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
        // #2494 — shared canonical chip corner (AppRadius.xl = 16).
        chipRadius: AppRadius.radiusXl,
        // #2488 — a 1 dp shadow is faint on a dark surface, so dark relies
        // on the hairline `surfaceContainerHighest` outline drawn by
        // [SectionCard] for card↔scaffold separation.
        cardElevation: 1.0,
        snackBarRadius: 12.0,
        snackBarElevation: 6.0,
      ),
      useMaterial3: true,
    ));
  }

  /// The green **Eco** theme (#1712, redesigned #2244, de-inverted #2488) —
  /// the app's signature look, named for the fuel-savings identity in the
  /// app icon.
  ///
  /// It is a light-family theme (never dark — no harsh green-on-black) and
  /// remains *unmistakably* green (per #2244), but #2488 fixes the inverted
  /// surface ramp that the #2244 redesign introduced:
  ///
  ///   * It is built on the same brand [_forestGreen] palette as [light]
  ///     and [dark] — not the generic `FlexScheme.money` — so the identity
  ///     green is the literal `#2E7D32` from the app icon.
  ///   * **#2488 — de-inverted surface ramp.** The #2244 redesign used
  ///     [FlexSurfaceMode.highScaffoldLevelSurface] with `blendLevel: 40`,
  ///     which made the *scaffold more green than the cards on it* (scaffold
  ///     `#9dc29f`, cards `#d8e5d9`) — the ramp ran backwards, so green
  ///     content (cheap-price text, status dots) lost contrast against the
  ///     over-green page and [SectionCard]'s tint-only separation left cards
  ///     with no delta. Eco now uses the same
  ///     [FlexSurfaceMode.levelSurfacesLowScaffold] family as [light] and
  ///     [dark]: the scaffold is the *lightest* (near-white) base surface so
  ///     green content reads on it again, and the green tint lives in the
  ///     card/container surfaces instead — the canonical Material direction.
  ///   * `blendLevel` drops 40 → 20 — half the old blend, but the cards (and
  ///     the scaffold) stay clearly greener than [light]'s 8 (the #2244
  ///     "recognisably green" mandate is preserved), with a 1 dp
  ///     `cardElevation` plus [SectionCard]'s hairline outline adding a real
  ///     card↔scaffold delta on top of the tonal step.
  ///   * **#2488 — tonal AppBar.** The AppBar is filled with the brand
  ///     `primaryContainer` (`appBarBackgroundSchemeColor: primaryContainer`)
  ///     rather than full primary, harmonising the chrome with the
  ///     `PageScaffold` banner while still reading "eco" at a glance.
  ///   * `blendOnLevel` (24) keeps primary containers and accents carrying
  ///     brand green throughout the app.
  ///
  /// Scope: this brand-green-forward push is intentionally contained to
  /// eco. [light] and [dark] keep their surface-coloured app bars; a
  /// green-app-bar repaint of the default themes is a separate change.
  static ThemeData eco() {
    return _floatingSnackBars(FlexThemeData.light(
      colors: _forestGreen,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 20,
      appBarStyle: FlexAppBarStyle.primary,
      appBarElevation: 0.0,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 24,
        blendOnColors: false,
        appBarBackgroundSchemeColor: SchemeColor.primaryContainer,
        useMaterial3Typography: true,
        useM2StyleDividerInM3: true,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorRadius: 12.0,
        cardRadius: 12.0,
        filledButtonRadius: 12.0,
        outlinedButtonRadius: 12.0,
        // #2494 — shared canonical chip corner (AppRadius.xl = 16).
        chipRadius: AppRadius.radiusXl,
        // #2488 — a real card↔scaffold delta on top of the lightness step.
        cardElevation: 1.0,
        snackBarRadius: 12.0,
        snackBarElevation: 6.0,
      ),
      useMaterial3: true,
    ));
  }
}
