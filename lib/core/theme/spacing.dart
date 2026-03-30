import 'package:flutter/material.dart';

/// Standardized spacing constants to replace hardcoded EdgeInsets values.
///
/// Use these instead of `const EdgeInsets.all(16)` or `const SizedBox(height: 8)`.
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
  static const chipPadding = EdgeInsets.symmetric(horizontal: lg, vertical: sm);
  static const sectionGap = SizedBox(height: md);
  static const cardGap = SizedBox(height: md);
}
