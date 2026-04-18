import '../entities/eco_score.dart';
import '../entities/fill_up.dart';

/// Computes a per-fill-up [EcoScore] from the user's fill-up history.
///
/// Pure, free of I/O. The caller supplies the full fill-up list and
/// picks the "current" entry; the calculator finds the preceding
/// same-fuel-type fill-ups to build a rolling L/100 km baseline and
/// decides how the current tank compares.
///
/// This is the computational half of issue #676 — the UI badge that
/// answers "did I drive more economically than usual?" for every new
/// fill-up. It is the feature most directly aligned with the product
/// leitmotiv (see README): once the user sees their consumption
/// drifting up or down at a glance, they can actually act on it.
class EcoScoreCalculator {
  EcoScoreCalculator._();

  /// How many previous fill-ups of the same fuel type to average.
  /// Three is enough to smooth out a single bad tank (winter mix,
  /// short-trip week) but short enough to show a real trend rather
  /// than regress to a year-old baseline.
  static const int rollingWindow = 3;

  /// Compute the eco-score for [current], comparing it against the
  /// [rollingWindow] most recent preceding fill-ups of the same fuel
  /// type in [history].
  ///
  /// [history] must include [current]; the calculator finds it by id
  /// (not by reference equality) so callers can pass freshly-loaded
  /// lists without worrying about identity. Order within [history]
  /// is not assumed — entries are sorted by date internally.
  ///
  /// Returns `null` when the score cannot be meaningfully produced:
  ///
  /// - [current] is not found in [history]
  /// - [current] is the first-ever fill-up (no preceding same-fuel entry)
  /// - Any of the preceding fill-ups (or [current] itself) has a
  ///   non-positive odometer delta — indicates a data-entry error
  ///   (odometer reset, typo) and a negative-or-zero delta would
  ///   produce a meaningless or infinite L/100 km.
  /// - Fewer than 1 valid preceding same-fuel-type entry.
  ///
  /// Callers are expected to render nothing when the return is `null`.
  static EcoScore? compute({
    required FillUp current,
    required List<FillUp> history,
  }) {
    // Sort chronologically so "previous" is well-defined regardless of
    // insertion order.
    final sorted = [...history]..sort((a, b) => a.date.compareTo(b.date));

    final idx = sorted.indexWhere((f) => f.id == current.id);
    if (idx <= 0) return null; // not found or is the very first entry

    // Previous fill-ups of the same fuel type, strictly before current.
    final sameFuelPrev = <FillUp>[];
    for (var i = idx - 1; i >= 0 && sameFuelPrev.length < rollingWindow; i--) {
      if (sorted[i].fuelType == current.fuelType) {
        sameFuelPrev.insert(0, sorted[i]);
      }
    }
    if (sameFuelPrev.isEmpty) return null;

    // Current fill-up's L/100 km = liters / distance * 100, where
    // distance = odometer(current) - odometer(last same-fuel fill-up).
    // Using the last same-fuel fill-up (not the immediate previous of
    // any fuel) is debatable but matches how the rolling baseline is
    // built, so the two numbers compare apples to apples.
    final referencePrev = sameFuelPrev.last;
    final currentDistance = current.odometerKm - referencePrev.odometerKm;
    if (currentDistance <= 0) return null; // odometer rollback / typo
    final currentLp100 = current.liters / currentDistance * 100;

    // Baseline: pair each previous with the one immediately before it
    // (same fuel type), same formula, then average.
    final baselineSamples = <double>[];
    for (var i = 0; i < sameFuelPrev.length; i++) {
      // The entry before `sameFuelPrev[i]` of the SAME fuel type.
      final entry = sameFuelPrev[i];
      final entryIndex = sorted.indexOf(entry);
      FillUp? predecessor;
      for (var j = entryIndex - 1; j >= 0; j--) {
        if (sorted[j].fuelType == current.fuelType) {
          predecessor = sorted[j];
          break;
        }
      }
      if (predecessor == null) continue;
      final d = entry.odometerKm - predecessor.odometerKm;
      if (d <= 0) continue;
      baselineSamples.add(entry.liters / d * 100);
    }
    if (baselineSamples.isEmpty) return null;

    final baseline =
        baselineSamples.reduce((a, b) => a + b) / baselineSamples.length;
    if (baseline <= 0) return null;

    final deltaPercent = (currentLp100 - baseline) / baseline * 100;
    final direction = _directionFor(deltaPercent);

    return EcoScore(
      litersPer100Km: currentLp100,
      rollingAverage: baseline,
      deltaPercent: deltaPercent,
      direction: direction,
    );
  }

  static EcoScoreDirection _directionFor(double deltaPercent) {
    if (deltaPercent <= -EcoScore.threshold) return EcoScoreDirection.improving;
    if (deltaPercent >= EcoScore.threshold) return EcoScoreDirection.worsening;
    return EcoScoreDirection.stable;
  }
}
