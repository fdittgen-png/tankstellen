import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return FlexThemeData.light(
      scheme: FlexScheme.bahamaBlue,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 7,
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
      ),
      useMaterial3: true,
    );
  }

  static ThemeData dark() {
    return FlexThemeData.dark(
      scheme: FlexScheme.bahamaBlue,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 13,
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
