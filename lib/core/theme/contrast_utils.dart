import 'dart:math';
import 'package:flutter/material.dart';

/// WCAG 2.1 contrast ratio utilities.
///
/// Provides relative luminance and contrast ratio calculations
/// to verify that color pairs meet accessibility standards.
class ContrastUtils {
  ContrastUtils._();

  /// WCAG AA minimum contrast ratio for normal text (< 18pt / 14pt bold).
  static const double kMinContrastNormal = 4.5;

  /// WCAG AA minimum contrast ratio for large text (>= 18pt / 14pt bold).
  static const double kMinContrastLarge = 3.0;

  /// Calculates the WCAG relative luminance of a [Color].
  ///
  /// Uses the sRGB linearisation formula from WCAG 2.1:
  /// https://www.w3.org/TR/WCAG21/#dfn-relative-luminance
  static double relativeLuminance(Color color) {
    double linearize(double channel) {
      return channel <= 0.04045
          ? channel / 12.92
          : pow((channel + 0.055) / 1.055, 2.4).toDouble();
    }

    final r = linearize(color.r);
    final g = linearize(color.g);
    final b = linearize(color.b);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Calculates the WCAG contrast ratio between two colors.
  ///
  /// Returns a value between 1.0 (identical) and 21.0 (black vs white).
  static double contrastRatio(Color foreground, Color background) {
    final lumFg = relativeLuminance(foreground);
    final lumBg = relativeLuminance(background);
    final lighter = max(lumFg, lumBg);
    final darker = min(lumFg, lumBg);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Whether the color pair meets WCAG AA for normal-sized text (4.5:1).
  static bool meetsAA(Color foreground, Color background) =>
      contrastRatio(foreground, background) >= kMinContrastNormal;

  /// Whether the color pair meets WCAG AA for large text (3:1).
  static bool meetsAALarge(Color foreground, Color background) =>
      contrastRatio(foreground, background) >= kMinContrastLarge;
}
