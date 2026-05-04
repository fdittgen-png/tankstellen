import 'dart:math' as math;

/// Online running-mean + running-variance accumulator via Welford's
/// algorithm (#769), extended in #1426 to support weighted samples
/// for the fuzzy calibration path (#894 wiring).
///
/// Numerically stable, O(1) per sample, no sample-history stored.
/// This is how we learn per-vehicle per-situation baselines for the
/// consumption banner without having to buffer every trip's samples.
///
/// State fits in five doubles — `n`, `mean`, `m2`, `sumWeight`,
/// `sumWeightSq` — so a full baseline set for 6 situations × any
/// number of vehicles is < 1 kB on disk.
///
/// ## Effective sample count (#1426)
///
/// Under unweighted updates [effectiveSampleCount] equals [n], so
/// existing #779 callers see no behaviour change. Under weighted
/// updates (the fuzzy path) it follows Kish's formula:
///
/// ```
/// effectiveN = (Σw)² / Σw²
/// ```
///
/// which is what the [BaselineStore] cold-start blend should use —
/// 30 samples weighted at 0.05 each give an effective N of
/// (30·0.05)² / (30·0.05²) = 1.5, not 30. This stops fuzzy mode
/// reporting `100 % learned` from boundary samples whose votes were
/// near-zero.
class WelfordAccumulator {
  /// Raw count of [update] / [updateWeighted] calls. Kept for
  /// backward-compatible JSON read paths and for the existing
  /// `sampleCount` UI hook (#779). For confidence math, use
  /// [effectiveSampleCount] instead.
  int n;
  double mean;

  /// Sum of squared deviations from the mean, weighted by sample
  /// weight under the weighted path. Divided by `(sumWeight − 1)` on
  /// read to get the sample variance. Kept as a separate term so the
  /// update math stays numerically stable — subtracting squared
  /// means directly loses precision for small variances.
  double m2;

  /// Σw — total weight applied across [updateWeighted] / [update]
  /// calls. For unweighted callers (`weight = 1`) this equals [n];
  /// the weighted path lets it diverge.
  double sumWeight;

  /// Σw² — sum of squared weights. Combined with [sumWeight] gives
  /// Kish's effective sample count via `(sumWeight)² / sumWeightSq`.
  double sumWeightSq;

  WelfordAccumulator({
    this.n = 0,
    this.mean = 0,
    this.m2 = 0,
    this.sumWeight = 0,
    this.sumWeightSq = 0,
  });

  /// Reset to the zero state. Used when a vehicle's baseline is
  /// explicitly cleared (e.g. after a major engine service).
  void reset() {
    n = 0;
    mean = 0;
    m2 = 0;
    sumWeight = 0;
    sumWeightSq = 0;
  }

  /// Feed one sample with implicit weight 1.0. Equivalent to the
  /// classic Welford update from #779; preserved as an entry point so
  /// the rule-mode call sites in [BaselineStore.record] keep their
  /// existing semantics with no behavioural change.
  void update(double x) => updateWeighted(x, 1.0);

  /// Feed one sample at [weight]. Weighted Welford:
  ///
  /// ```
  /// W' = W + w
  /// delta = x - mean
  /// mean' = mean + delta * (w / W')
  /// delta2 = x - mean'
  /// m2' = m2 + w * delta * delta2
  /// ```
  ///
  /// Update order matters — the second delta has to use the NEW
  /// mean, not the old one, or the variance drifts. Zero or negative
  /// weights are a no-op (a fuzzy classifier producing exactly 0
  /// membership for a bucket should not perturb that bucket's
  /// accumulator).
  void updateWeighted(double x, double weight) {
    if (weight <= 0) return;
    n += 1;
    sumWeight += weight;
    sumWeightSq += weight * weight;
    final delta = x - mean;
    mean += delta * (weight / sumWeight);
    final delta2 = x - mean;
    m2 += weight * delta * delta2;
  }

  /// Effective sample count for confidence-blend math.
  ///
  /// * Unweighted callers (`weight = 1`): equals [n] (because
  ///   sumWeight = sumWeightSq = n, so (n)²/n = n).
  /// * Weighted callers: Kish's effective-N formula. A bucket fed by
  ///   30 samples × 0.05 weight reports 1.5, not 30.
  /// * Empty: returns 0.
  double get effectiveSampleCount {
    if (sumWeightSq <= 0) return 0;
    return (sumWeight * sumWeight) / sumWeightSq;
  }

  /// Sample variance. Requires at least 2 effective samples — returns
  /// 0 with a single (effective) sample (zero spread by definition)
  /// rather than NaN from the 0/0 division.
  double get variance {
    if (sumWeight < 2) return 0.0;
    return m2 / (sumWeight - 1);
  }

  /// Sample standard deviation.
  double get stddev => math.sqrt(variance);

  Map<String, dynamic> toJson() => {
        'n': n,
        'mean': mean,
        'm2': m2,
        'sumWeight': sumWeight,
        'sumWeightSq': sumWeightSq,
      };

  /// Deserialize. Pre-#1426 baselines persisted only `n` / `mean` /
  /// `m2` — for those, [sumWeight] is back-filled to `n` and
  /// [sumWeightSq] to `n` as well, which makes
  /// [effectiveSampleCount] equal `n` (matches the legacy
  /// unweighted-path semantics exactly). Callers that subsequently
  /// run [updateWeighted] continue to accumulate from there.
  factory WelfordAccumulator.fromJson(Map<String, dynamic> json) {
    final n = (json['n'] as num?)?.toInt() ?? 0;
    final sumWeightFromJson = (json['sumWeight'] as num?)?.toDouble();
    final sumWeightSqFromJson = (json['sumWeightSq'] as num?)?.toDouble();
    return WelfordAccumulator(
      n: n,
      mean: (json['mean'] as num?)?.toDouble() ?? 0.0,
      m2: (json['m2'] as num?)?.toDouble() ?? 0.0,
      sumWeight: sumWeightFromJson ?? n.toDouble(),
      sumWeightSq: sumWeightSqFromJson ?? n.toDouble(),
    );
  }
}
