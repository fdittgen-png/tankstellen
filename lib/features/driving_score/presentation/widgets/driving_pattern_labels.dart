// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4366 — the localized vocabulary of the driving-pattern comparison.
///
/// Kept apart from the card so the card stays about layout and this
/// stays about words. Every enum the read model can produce has exactly
/// one label here, which is also what makes the switch statements
/// exhaustive: a new measure or a new cohort axis cannot reach the UI
/// unnamed.
library;

import 'package:intl/intl.dart';

import '../../../../core/domain/comparison_eligibility.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/driving_pattern_comparison.dart';

/// Localized name of a behaviour dimension.
String measureLabel(AppLocalizations l, DrivingMeasureId id) =>
    switch (id) {
      DrivingMeasureId.hardAccelRate => l.drivingMeasureHardAccelRate,
      DrivingMeasureId.fullThrottleShare => l.drivingMeasureFullThrottleShare,
      DrivingMeasureId.hardBrakeRate => l.drivingMeasureHardBrakeRate,
      DrivingMeasureId.avoidableBrakeShare =>
        l.drivingMeasureAvoidableBrakeShare,
      DrivingMeasureId.engineIdleShare => l.drivingMeasureEngineIdleShare,
      DrivingMeasureId.highRpmShare => l.drivingMeasureHighRpmShare,
      DrivingMeasureId.sustainedHighSpeedShare =>
        l.drivingMeasureSustainedHighSpeedShare,
      DrivingMeasureId.energyOscillationRate =>
        l.drivingMeasureEnergyOscillationRate,
      DrivingMeasureId.coastingFuelCutShare =>
        l.drivingMeasureCoastingFuelCutShare,
      DrivingMeasureId.lateCurveShare => l.drivingMeasureLateCurveShare,
      DrivingMeasureId.climbFullThrottleShare =>
        l.drivingMeasureClimbFullThrottleShare,
      DrivingMeasureId.flatFullThrottleShare =>
        l.drivingMeasureFlatFullThrottleShare,
    };

/// The figure itself, in the measure's own unit.
String measureValueLabel(
    AppLocalizations l, DrivingMeasureUnit unit, double value) {
  final n = NumberFormat.decimalPatternDigits(
      locale: l.localeName, decimalDigits: 1);
  return switch (unit) {
    DrivingMeasureUnit.eventsPer100Km =>
      l.drivingMeasureEventsPer100Km(n.format(value)),
    DrivingMeasureUnit.share => l.drivingMeasureSharePercent(
        n.format(value * 100)),
  };
}

/// "12 events over 100 km · 8 trips" — the numerator and the eligible
/// denominator that produced the figure, so it can be traced.
///
/// The numerator is rendered as EVENTS or as MINUTES according to what
/// it actually counts; there is no shared "amount of evidence" phrasing
/// that could let the two be read as one quantity.
String evidenceCaption(AppLocalizations l, DrivingPatternMeasure m) {
  final events = m.eventNumerator;
  final numerator = events != null
      ? l.drivingPatternCountEvents(_int(l, events))
      : l.drivingPatternCountMinutes(_minutes(l, m.durationSeconds!));
  return l.drivingPatternEvidenceCaption(
      numerator, _denominator(l, m), m.supportingTripCount);
}

String _denominator(AppLocalizations l, DrivingPatternMeasure m) =>
    switch (m.spec.exposureBasis) {
      DrivingExposureBasis.movingDistanceKm =>
        l.drivingPatternCountKm(_int(l, m.exposure.round())),
      DrivingExposureBasis.hardBrakeEvents ||
      DrivingExposureBasis.judgedCurves =>
        l.drivingPatternCountEvents(_int(l, m.exposure.round())),
      _ => l.drivingPatternCountMinutes(_minutes(l, m.exposure)),
    };

String _int(AppLocalizations l, int value) =>
    NumberFormat.decimalPattern(l.localeName).format(value);

String _minutes(AppLocalizations l, double seconds) =>
    NumberFormat.decimalPatternDigits(locale: l.localeName, decimalDigits: 1)
        .format(seconds / 60);

/// One matching criterion, e.g. "trips of 5 to 30 km, warm start".
String cohortLabel(AppLocalizations l, DrivingPatternCohort c) =>
    l.drivingPatternCohortLabel(
      switch (c.distanceBand) {
        TripDistanceBand.short => l.drivingPatternBandShort,
        TripDistanceBand.medium => l.drivingPatternBandMedium,
        TripDistanceBand.long => l.drivingPatternBandLong,
      },
      switch (c.coldStart) {
        ColdStartEvidence.coldObserved => l.drivingPatternStartCold,
        ColdStartEvidence.warmObserved => l.drivingPatternStartWarm,
        ColdStartEvidence.unknown => l.drivingPatternStartUnknown,
      },
    );

/// The caveats a figure must never be shown without. Returns an empty
/// list for the qualifications this surface has nothing to add about
/// (money and provenance ones cannot arise here).
List<String> qualificationLabels(
    AppLocalizations l, Set<ComparisonQualification> qualifications) {
  final out = <String>[];
  for (final q in qualifications) {
    final label = switch (q) {
      ComparisonQualification.uncontrolledConditions =>
        l.drivingPatternQualUncontrolled,
      ComparisonQualification.partialConditionCoverage =>
        l.drivingPatternQualPartialConditions,
      ComparisonQualification.unequalSampleSizes =>
        l.drivingPatternQualUnequalEvidence,
      ComparisonQualification.excludedRecords => l.drivingPatternQualExcluded,
      _ => null,
    };
    if (label != null) out.add(label);
  }
  return out;
}

/// Why a dimension has no figure for one vehicle. Never "0".
String unavailableLabel(AppLocalizations l, ComparisonUnavailableReason? r) =>
    r == ComparisonUnavailableReason.tooFewSamples
        ? l.drivingPatternUnavailableTooLittle
        : l.drivingPatternUnavailableNoSignal;
