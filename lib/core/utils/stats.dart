// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The one home for the small order statistics the app computes (#4073).
///
/// Five private copies had grown across diagnostics, maintenance,
/// verdict calibration, gear clustering and price guidance — and they
/// had already diverged: two percentiles with different formulas, two
/// medians with different empty-list behaviour. Each formula is named
/// for what it does so a caller picks deliberately.
library;

/// The median of [values]; the mean of the two middle values for an even
/// count. [values] must be non-empty — use [medianOrNull] when it may not be.
double median(List<double> values) {
  assert(values.isNotEmpty, 'median requires non-empty input');
  final sorted = [...values]..sort();
  final n = sorted.length;
  if (n.isOdd) return sorted[n ~/ 2];
  return (sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2;
}

/// [median], or null for an empty list.
double? medianOrNull(List<double> values) =>
    values.isEmpty ? null : median(values);

/// Nearest-rank percentile: the element at `round((n - 1) * p)` of the
/// sorted copy. Coarse and monotone — the calibration-store formula.
/// [values] must be non-empty.
double percentileNearestRank(List<double> values, double p) {
  assert(values.isNotEmpty, 'percentile requires non-empty input');
  final sorted = [...values]..sort();
  final idx = ((sorted.length - 1) * p).round();
  return sorted[idx.clamp(0, sorted.length - 1)];
}

/// Linearly interpolated percentile (type 7) over an ALREADY SORTED
/// ascending list. Empty → 0.0; a single element → that element;
/// q outside [0, 1] clamps to the ends. The gear-clustering formula.
double percentileInterpolated(List<double> sortedAscending, double q) {
  if (sortedAscending.isEmpty) return 0.0;
  if (sortedAscending.length == 1) return sortedAscending[0];
  if (q <= 0) return sortedAscending.first;
  if (q >= 1) return sortedAscending.last;
  final pos = q * (sortedAscending.length - 1);
  final lo = pos.floor();
  final hi = pos.ceil();
  if (lo == hi) return sortedAscending[lo];
  final frac = pos - lo;
  return sortedAscending[lo] + (sortedAscending[hi] - sortedAscending[lo]) * frac;
}
