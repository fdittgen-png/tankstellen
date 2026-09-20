// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4366 — turning summed typed totals into stated measures, and stated
/// measures into observed differences.
///
/// Two rules are enforced here rather than trusted to callers:
///
///  1. **A measure with no eligible exposure has no value.** Not zero,
///     not "perfect" — [ComparisonUnavailableReason.noEvidence]. A
///     GPS-only history has no RPM seconds, so it cannot post a 0 %
///     high-RPM share and out-rank an OBD-equipped one.
///  2. **No measure is ever bare.** Production evaluates cold starts and
///     nothing else — no grade, no traffic, no blend-independent
///     expected consumption — so every stated figure carries
///     [ComparisonQualification.partialConditionCoverage] at minimum,
///     and an unmatched comparison adds
///     [ComparisonQualification.uncontrolledConditions].
library;

import '../../../core/domain/comparison_eligibility.dart';
import '../../../core/domain/data_value.dart';
import '../domain/driving_pattern_comparison.dart';

/// How many observed differences a surface is offered at once.
const int kMaxDrivingPatternDifferences = 3;

/// One measure per [kDrivingMeasures] entry — the unsupported ones too,
/// so a surface can say WHY a dimension is missing instead of silently
/// rendering one fewer row.
Map<DrivingMeasureId, DrivingPatternMeasure> buildMeasures({
  required DrivingPatternTotals totals,
  required ComparisonCoverage coverage,
  required Map<DrivingMeasureId, int> support,
  required Map<DrivingMeasureId, String> representatives,
  required bool matched,
  required bool excludedRecords,
}) {
  final qualifications = <ComparisonQualification>{
    // Cold starts are the ONLY confounder production records.
    ComparisonQualification.partialConditionCoverage,
    if (!matched) ComparisonQualification.uncontrolledConditions,
    if (excludedRecords) ComparisonQualification.excludedRecords,
  };
  final out = <DrivingMeasureId, DrivingPatternMeasure>{};
  for (final spec in kDrivingMeasures) {
    final exposure = totals.exposureOf(spec.exposureBasis);
    final value = measureValue(totals, spec);
    final ComparableMetric<double> metric;
    if (exposure <= 0 || value == null) {
      // The signal this measure needs was never present. Unknown.
      metric = ComparableMetric.unavailable(
          ComparisonUnavailableReason.noEvidence,
          coverage: coverage);
    } else if (exposure < spec.minimumExposure) {
      metric = ComparableMetric.unavailable(
          ComparisonUnavailableReason.tooFewSamples,
          coverage: coverage);
    } else {
      metric = ComparableMetric.qualified(DataValue.measured(value),
          qualifications: qualifications, coverage: coverage);
    }
    out[spec.id] = DrivingPatternMeasure(
      spec: spec,
      metric: metric,
      exposure: exposure,
      supportingTripCount: support[spec.id] ?? 0,
      eventNumerator: spec.eventNumerator == null
          ? null
          : totals.eventCount(spec.eventNumerator!),
      durationSeconds: spec.durationNumerator == null
          ? null
          : totals.durationSeconds(spec.durationNumerator!),
      representativeTripId: representatives[spec.id],
    );
  }
  return out;
}

/// The widest observed differences, widest first.
///
/// An entry is an OBSERVATION with its evidence. Nothing here decides
/// who drove better: a measure marked
/// [DrivingMeasureSpec.contextDependent] can differ entirely because one
/// route climbed, queued or needed the brake, and the surface must say
/// so. Two vehicles that behaved identically produce no entry at all,
/// however different their terrain.
List<DrivingPatternDifference> largestDifferences(
  List<VehicleDrivingPattern> subjects, {
  int max = kMaxDrivingPatternDifferences,
}) {
  final out = <DrivingPatternDifference>[];
  for (final spec in kDrivingMeasures) {
    final stated = [
      for (final s in subjects)
        if (s.measure(spec.id)?.metric.valueOrNull != null) s,
    ];
    if (stated.length < 2) continue;
    var high = stated.first, low = stated.first;
    for (final s in stated) {
      final v = s.measure(spec.id)!.metric.valueOrNull!;
      if (v > high.measure(spec.id)!.metric.valueOrNull!) high = s;
      if (v < low.measure(spec.id)!.metric.valueOrNull!) low = s;
    }
    final hv = high.measure(spec.id)!.metric.valueOrNull!;
    final lv = low.measure(spec.id)!.metric.valueOrNull!;
    if (hv == lv) continue;
    out.add(DrivingPatternDifference(
      id: spec.id,
      higherVehicleId: high.vehicleId,
      lowerVehicleId: low.vehicleId,
      higher: hv,
      lower: lv,
      contextDependent: spec.contextDependent,
      qualifications: {
        ...high.measure(spec.id)!.metric.qualifications,
        ...low.measure(spec.id)!.metric.qualifications,
        if (_unequalExposure(high.measure(spec.id)!, low.measure(spec.id)!))
          ComparisonQualification.unequalSampleSizes,
      },
    ));
  }
  out.sort((a, b) {
    final byRelative = b.relativeDelta.compareTo(a.relativeDelta);
    return byRelative != 0
        ? byRelative
        : b.absoluteDelta.abs().compareTo(a.absoluteDelta.abs());
  });
  return out.take(max).toList(growable: false);
}

/// True when one side rests on at least twice the exposure of the other
/// — the same rate, very different certainty (#4366 acceptance 1).
bool _unequalExposure(DrivingPatternMeasure a, DrivingPatternMeasure b) {
  final low = a.exposure < b.exposure ? a.exposure : b.exposure;
  final high = a.exposure < b.exposure ? b.exposure : a.exposure;
  return low <= 0 || high >= low * 2;
}

/// The magnitude of a measure's numerator, whichever kind it is.
///
/// Used only to rank a measure's representative trip and to divide by
/// its own exposure. It is deliberately NOT a cross-measure quantity:
/// seconds and events are different things, and the spec says which one
/// this is.
double numeratorOf(DrivingPatternTotals totals, DrivingMeasureSpec spec) =>
    spec.eventNumerator != null
        ? totals.eventCount(spec.eventNumerator!).toDouble()
        : totals.durationSeconds(spec.durationNumerator!);

/// The stated figure for [spec], or null when its eligible exposure
/// cannot support one.
double? measureValue(DrivingPatternTotals totals, DrivingMeasureSpec spec) {
  final exposure = totals.exposureOf(spec.exposureBasis);
  if (exposure <= 0) return null;
  final numerator = numeratorOf(totals, spec);
  return spec.unit == DrivingMeasureUnit.eventsPer100Km
      ? numerator / exposure * 100
      : numerator / exposure;
}
