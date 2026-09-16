// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

/// The fuzzy membership-function primitives shared by the driving-situation
/// classifier (`FuzzyClassifier`, #894 / #2515) and the fuzzy consumption
/// engine (#4232, Epic #4222).
///
/// Extracted from `FuzzyClassifier`'s private helpers so the engine reuses
/// the same shapes rather than re-deriving them (#4232: "reuse, don't
/// redesign"). The arithmetic is byte-for-byte the classifier's; it lives in
/// `core/domain` because the two callers sit in different features and
/// `feature_boundary_test` forbids one reaching into the other.
///
/// Every function maps a finite input to `[0, 1]`. They do not sanitise
/// non-finite input — a caller that can receive NaN (a sensor) must reject
/// it before asking for a membership, the way the engine records such a
/// reading as `invalid` instead of evaluating it.
abstract final class FuzzyMembership {
  /// Trapezoid: rises 0→1 across [a, b], holds 1 across [b, c], falls 1→0
  /// across [c, d]; 0 outside `(a, d)`. `a ≤ b ≤ c ≤ d`; `b == c` is a
  /// triangle.
  static double trapezoid(double x, double a, double b, double c, double d) {
    assert(a <= b && b <= c && c <= d,
        'trapezoid parameters must satisfy a ≤ b ≤ c ≤ d');
    if (x <= a || x >= d) return 0;
    if (x >= b && x <= c) return 1;
    if (x < b) return (x - a) / math.max(b - a, 1e-9);
    return (d - x) / math.max(d - c, 1e-9);
  }

  /// Left shoulder: 1 at or below [lo], 0 at or above [hi], linear between.
  static double rampDown(double x, double lo, double hi) {
    assert(lo < hi, 'ramp bounds must satisfy lo < hi');
    if (x <= lo) return 1;
    if (x >= hi) return 0;
    return (hi - x) / (hi - lo);
  }

  /// Right shoulder: 0 at or below [lo], 1 at or above [hi], linear between.
  static double rampUp(double x, double lo, double hi) {
    assert(lo < hi, 'ramp bounds must satisfy lo < hi');
    if (x <= lo) return 0;
    if (x >= hi) return 1;
    return (x - lo) / (hi - lo);
  }
}
