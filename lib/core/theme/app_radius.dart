import 'package:flutter/material.dart';

/// Standardised corner-radius values for cards, chips, dialogs, etc.
/// Use these instead of ad-hoc `BorderRadius.circular(12)` calls so
/// the app's roundness scales consistently when the design system
/// tokens are tweaked (#591).
abstract class AppRadius {
  AppRadius._();

  /// 4 px — tight corners for small chips and dense inputs.
  static const double sm = 4;

  /// 8 px — default card corner, matches Material 3 "filled card".
  static const double md = 8;

  /// 12 px — prominent card / sheet corner (help banner, bad-scan
  /// sheet). Matches Material 3's "elevated card" rounding.
  static const double lg = 12;

  /// 16 px — dialog + bottom-sheet corner.
  static const double xl = 16;

  /// 24 px — hero surfaces (onboarding cards, splash tiles).
  static const double xxl = 24;

  // Pre-built BorderRadius values for the most common use cases.
  static const radiusSm = BorderRadius.all(Radius.circular(sm));
  static const radiusMd = BorderRadius.all(Radius.circular(md));
  static const radiusLg = BorderRadius.all(Radius.circular(lg));
  static const radiusXl = BorderRadius.all(Radius.circular(xl));
  static const radiusXxl = BorderRadius.all(Radius.circular(xxl));
}
