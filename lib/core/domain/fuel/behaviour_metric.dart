// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:meta/meta.dart';

/// What a behaviour metric rests on (#4276), so a consumer can say
/// "measured", "from your fill-ups" or "estimated" without guessing.
enum MetricBasis {
  /// Full-to-full fill windows — aggregate pump truth.
  referenceWindows,

  /// Native ECU readings only.
  measuredTrips,

  /// Trips including canonical estimates.
  estimatedTrips,

  /// Observed ÷ expected over measured trips — confounders controlled.
  measuredResiduals,

  /// Observed ÷ expected including estimated trips.
  estimatedResiduals,

  /// Arithmetic over other metrics (cost/100 km, range, CO2e, adjusted
  /// L/100 km). The inputs' own bases are stated where it is built.
  derived,
}

/// Why a metric is not a number.
enum InsufficientReason {
  /// No evidence of the needed kind at all.
  noEvidence,

  /// Fewer samples than the named minimum.
  tooFewSamples,

  /// Less distance than the named minimum.
  tooLittleDistance,

  /// Range needs the tank capacity.
  capacityUnknown,

  /// CO2e needs a versioned factor (#4219); none is on record.
  noCo2eFactor,

  /// A mixed or unknown context has no single factor.
  contextNotPure,

  /// The interval reaches a physically meaningless value.
  uncertaintyTooWide,
}

/// A learned value with its uncertainty, or an explicit "insufficient"
/// (#4276). Never a bare number: below the minimum-evidence thresholds
/// there is no [value] at all.
///
/// [lower]/[upper] are a 95 % Student-t interval on a distance-weighted
/// mean (see [BehaviourMetric.weightedMean]). They describe sampling
/// spread between drives or windows — NOT the accuracy of the underlying
/// consumption pipeline, which only the #4231 corpus can measure.
@immutable
final class BehaviourMetric {
  /// A known value.
  const BehaviourMetric.known({
    required double this.value,
    required double this.standardError,
    required double this.lower,
    required double this.upper,
    required this.sampleCount,
    required MetricBasis this.basis,
  }) : insufficientReason = null;

  /// Not a number, with the reason stated.
  const BehaviourMetric.insufficient(InsufficientReason this.insufficientReason,
      {this.sampleCount = 0})
      : value = null,
        standardError = null,
        lower = null,
        upper = null,
        basis = null;

  final double? value;
  final double? standardError;
  final double? lower;
  final double? upper;
  final int sampleCount;
  final MetricBasis? basis;
  final InsufficientReason? insufficientReason;

  bool get isKnown => value != null;

  /// Distance-weighted mean of `(value, weight)` pairs with a 95 % t
  /// interval. Weighted variance uses the reliability correction
  /// `n / (n − 1)` and the Kish effective sample size
  /// `(Σw)² / Σw²`, so one long drive does not pose as many short ones.
  /// Needs at least two samples — one sample has no spread to report.
  static BehaviourMetric weightedMean(
      List<(double, double)> samples, MetricBasis basis) {
    final n = samples.length;
    if (n < 2) {
      return BehaviourMetric.insufficient(InsufficientReason.tooFewSamples,
          sampleCount: n);
    }
    var sw = 0.0, sw2 = 0.0, swx = 0.0;
    for (final (x, w) in samples) {
      sw += w;
      sw2 += w * w;
      swx += w * x;
    }
    final mean = swx / sw;
    var ss = 0.0;
    for (final (x, w) in samples) {
      ss += w * (x - mean) * (x - mean);
    }
    final variance = ss / sw * n / (n - 1);
    final nEff = sw * sw / sw2;
    final se = math.sqrt(variance / nEff);
    final half = t95(n - 1) * se;
    return BehaviourMetric.known(
      value: mean,
      standardError: se,
      lower: mean - half,
      upper: mean + half,
      sampleCount: n,
      basis: basis,
    );
  }

  /// This metric times [k] (k > 0) — cost/100 km, CO2e/km.
  BehaviourMetric scaled(double k) => !isKnown
      ? this
      : BehaviourMetric.known(
          value: value! * k,
          standardError: standardError! * k,
          lower: lower! * k,
          upper: upper! * k,
          sampleCount: sampleCount,
          basis: MetricBasis.derived,
        );

  /// `k / this` (k > 0) — L/100 km into range. The interval inverts, and
  /// an interval touching zero is [InsufficientReason.uncertaintyTooWide].
  BehaviourMetric reciprocal(double k) {
    if (!isKnown) return this;
    if (lower! <= 0) {
      return BehaviourMetric.insufficient(InsufficientReason.uncertaintyTooWide,
          sampleCount: sampleCount);
    }
    return BehaviourMetric.known(
      value: k / value!,
      standardError: standardError! * k / (value! * value!),
      lower: k / upper!,
      upper: k / lower!,
      sampleCount: sampleCount,
      basis: MetricBasis.derived,
    );
  }

  /// `this × other` for independent metrics (delta method on relative
  /// errors); the interval uses the smaller of the two sample counts.
  BehaviourMetric times(BehaviourMetric other) =>
      _combine(other, (a, b) => a * b);

  /// `this ÷ other` for independent metrics (delta method).
  BehaviourMetric over(BehaviourMetric other) =>
      _combine(other, (a, b) => a / b);

  BehaviourMetric _combine(
      BehaviourMetric other, double Function(double, double) op) {
    if (!isKnown) return this;
    if (!other.isKnown) return other;
    if (other.value! == 0 || value! == 0) {
      return BehaviourMetric.insufficient(InsufficientReason.uncertaintyTooWide,
          sampleCount: math.min(sampleCount, other.sampleCount));
    }
    final v = op(value!, other.value!);
    final rel = math.sqrt(math.pow(standardError! / value!, 2) +
        math.pow(other.standardError! / other.value!, 2));
    final se = v.abs() * rel;
    final n = math.min(sampleCount, other.sampleCount);
    final half = t95(math.max(1, n - 1)) * se;
    return BehaviourMetric.known(
      value: v,
      standardError: se,
      lower: v - half,
      upper: v + half,
      sampleCount: n,
      basis: MetricBasis.derived,
    );
  }

  Map<String, Object?> toJson() => {
        'value': value,
        'standardError': standardError,
        'lower': lower,
        'upper': upper,
        'sampleCount': sampleCount,
        'basis': basis?.name,
        'insufficientReason': insufficientReason?.name,
      };

  /// Two-sided 95 % Student-t critical value for [df] degrees of freedom;
  /// 1.96 beyond 30.
  static double t95(int df) {
    if (df < 1) throw ArgumentError.value(df, 'df');
    return df <= _t95Table.length ? _t95Table[df - 1] : 1.96;
  }

  static const List<double> _t95Table = [
    12.706, 4.303, 3.182, 2.776, 2.571, 2.447, 2.365, 2.306, 2.262, 2.228, //
    2.201, 2.179, 2.160, 2.145, 2.131, 2.120, 2.110, 2.101, 2.093, 2.086,
    2.080, 2.074, 2.069, 2.064, 2.060, 2.056, 2.052, 2.048, 2.045, 2.042,
  ];

  @override
  String toString() => isKnown
      ? 'BehaviourMetric($value ± $standardError, n=$sampleCount, ${basis!.name})'
      : 'BehaviourMetric(insufficient: ${insufficientReason!.name})';
}
