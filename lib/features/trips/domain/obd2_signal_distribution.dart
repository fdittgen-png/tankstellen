// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// Distribution of stored values. Coverage is the share of trip samples
/// carrying a value, not ECU polling success or time coverage. Sparse capture
/// and carried-forward readings must not be confused with sensor availability.
class Obd2SignalDistribution {
  final double? mean, p95, min, max;
  final double coverage;
  final int count;

  const Obd2SignalDistribution({
    this.mean,
    this.p95,
    this.min,
    this.max,
    required this.coverage,
    this.count = 0,
  });

  factory Obd2SignalDistribution.from(
    List<double> values, {
    int? totalSamples,
  }) {
    final valid = values.where((v) => v.isFinite).toList()..sort();
    if (valid.isEmpty) return const Obd2SignalDistribution(coverage: 0);
    return Obd2SignalDistribution(
      mean: valid.reduce((a, b) => a + b) / valid.length,
      p95: valid[((valid.length - 1) * 0.95).ceil()],
      min: valid.first,
      max: valid.last,
      count: valid.length,
      coverage: totalSamples == null ? 1 : valid.length / totalSamples,
    );
  }

  Map<String, dynamic> toJson() => {
    'mean': _r(mean),
    'p95': _r(p95),
    'min': _r(min),
    'max': _r(max),
    'count': count,
    'coverage': (coverage * 1000).round() / 1000,
    'coverageBasis': 'storedTripSamples',
  };

  static double? _r(double? v) => v == null ? null : (v * 1000).round() / 1000;
}
