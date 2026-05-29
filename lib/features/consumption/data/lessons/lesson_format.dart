// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Shared coaching-grade number formatters for driving-lesson rules
/// (#2251).
///
/// Mirrors the formatters the legacy `driving_insights_card` used so the
/// migrated lessons render character-for-character identically:
///   * litres to one decimal ("0.6", not "0.6000"), negatives clamped
///     to zero so we never coach with negative waste;
///   * percent to a whole number ("12", not "12.345").
library;

/// One-decimal litres — "0.6". Negative values (impossible in
/// production, cheap to defend) clamp to zero.
String formatLessonLiters(double liters) {
  final clamped = liters < 0 ? 0.0 : liters;
  return clamped.toStringAsFixed(1);
}

/// Whole-number percent — "12".
String formatLessonPercent(double pct) => pct.toStringAsFixed(0);
