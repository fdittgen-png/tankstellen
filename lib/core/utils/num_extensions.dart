// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Numeric helpers shared across the app.
///
/// Replaces the hand-rolled `xs.reduce((a, b) => a + b) / xs.length` /
/// `sum / xs.length` arithmetic-mean idiom that was duplicated across many
/// call sites. Centralising it removes the easy-to-get-wrong empty-list
/// division (which yields `NaN`) — [average] returns `0` for an empty
/// iterable.
///
/// Usage:
/// ```dart
/// final mean = [1, 2, 3].average;            // 2.0
/// final speed = samples.map((s) => s.speedKmh).average;
/// ```
extension NumIterableStats on Iterable<num> {
  /// The arithmetic mean of the elements, as a [double].
  ///
  /// Returns `0` for an empty iterable instead of throwing / producing
  /// `NaN`. Call sites that need a different empty sentinel should guard
  /// emptiness themselves before calling.
  double get average =>
      isEmpty ? 0 : map((e) => e.toDouble()).reduce((a, b) => a + b) / length;
}
