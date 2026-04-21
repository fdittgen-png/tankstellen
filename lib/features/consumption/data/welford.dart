import 'dart:math' as math;

/// Online running-mean + running-variance accumulator via Welford's
/// algorithm (#769).
///
/// Numerically stable, O(1) per sample, no sample-history stored.
/// This is how we learn per-vehicle per-situation baselines for the
/// consumption banner without having to buffer every trip's samples.
///
/// State fits in three doubles — `n`, `mean`, `m2` — so a full
/// baseline set for 6 situations × any number of vehicles is < 1 kB
/// on disk.
class WelfordAccumulator {
  int n;
  double mean;

  /// Sum of squared deviations from the mean. Divided by `n-1` on
  /// read to get the sample variance. Kept as a separate term so the
  /// update math stays numerically stable — subtracting squared
  /// means directly loses precision for small variances.
  double m2;

  WelfordAccumulator({this.n = 0, this.mean = 0, this.m2 = 0});

  /// Reset to the zero state. Used when a vehicle's baseline is
  /// explicitly cleared (e.g. after a major engine service).
  void reset() {
    n = 0;
    mean = 0;
    m2 = 0;
  }

  /// Feed one sample. Classic Welford:
  ///
  /// ```
  /// n' = n + 1
  /// delta = x - mean
  /// mean' = mean + delta / n'
  /// m2' = m2 + delta * (x - mean')
  /// ```
  ///
  /// Update order matters — the second delta has to use the NEW
  /// mean, not the old one, or the variance drifts.
  void update(double x) {
    n += 1;
    final delta = x - mean;
    mean += delta / n;
    final delta2 = x - mean;
    m2 += delta * delta2;
  }

  /// Sample variance. Requires at least 2 samples — returns 0 with
  /// a single sample (zero spread by definition) rather than NaN
  /// from the 0/0 division.
  double get variance => n < 2 ? 0.0 : m2 / (n - 1);

  /// Sample standard deviation.
  double get stddev => math.sqrt(variance);

  Map<String, dynamic> toJson() => {
        'n': n,
        'mean': mean,
        'm2': m2,
      };

  factory WelfordAccumulator.fromJson(Map<String, dynamic> json) {
    return WelfordAccumulator(
      n: (json['n'] as num?)?.toInt() ?? 0,
      mean: (json['mean'] as num?)?.toDouble() ?? 0.0,
      m2: (json['m2'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
