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

  /// Default light theme (#1757) — calm forest green. Surfaces are a
  /// soft green-tinted off-white rather than stark white, and the
  /// accent is the icon's forest green, for a professional,
  /// low-contrast feel.
  static ThemeData light() {
    return FlexThemeData.light(
      colors: _forestGreen,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 14,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 12,
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
  /// kept coherent with [light] (#1757).
  static ThemeData dark() {
    return FlexThemeData.dark(
      colors: _forestGreen.toDark(28),
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 16,
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

  /// The green **Eco** theme (#1712) — the app's signature look, named
  /// for the fuel-savings identity in the app icon.
  ///
  /// It is a light-family theme (never dark — no harsh green-on-black),
  /// built on the green `FlexScheme.money` palette. The `blendLevel` is
  /// raised well above [light]'s 7 so surfaces are softly green-tinted
  /// rather than stark white, keeping the green/white contrast gentle
  /// while staying bright and readable.
  static ThemeData eco() {
    return FlexThemeData.light(
      scheme: FlexScheme.money,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 18,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 16,
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
}
