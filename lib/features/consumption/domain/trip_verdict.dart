// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The driver's own post-trip verdict (#3501, epic #3498) — the calibration
/// signal the drivingAnalysis export used to beg for in a free-text comment
/// ("YOUR VERDICT HERE → smooth / moderate / aggressive"). Captured by a
/// 3-tap prompt on the trip detail, persisted on the trip entry, and joined
/// with the trip's RPA/PKE/VAPOS/coasting + event counts by the #3503
/// calibration store so the thresholds can be tuned against how trips
/// actually FELT instead of guessed cutoffs.
enum TripVerdict {
  smooth,
  moderate,
  aggressive,

  /// The driver dismissed the prompt for this trip ("Not now") — persisted
  /// so the prompt never nags twice for the same trip; excluded from
  /// calibration.
  skipped;

  /// Wire/persistence name (`name`), kept explicit for grep-ability.
  String get wireName => name;

  /// Parse a persisted name; null on unknown/legacy values (forward compat).
  static TripVerdict? tryParse(String? raw) {
    for (final v in values) {
      if (v.name == raw) return v;
    }
    return null;
  }
}
