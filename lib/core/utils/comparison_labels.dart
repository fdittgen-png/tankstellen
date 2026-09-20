// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The one place a #4364 eligibility vocabulary value becomes words.
///
/// Lives in core beside `data_value_labels.dart` (#4367): the
/// vocabulary is core's, and both the #4365 history comparison and the
/// #4367 same-trip comparison render it. A second table in the second
/// surface would drift, and a caveat that drifts is a caveat that goes
/// missing.
///
/// Both switches are exhaustive on purpose: a new
/// [ComparisonUnavailableReason] or [ComparisonQualification] must be
/// given a sentence here or the analyzer says so. A caveat that
/// silently renders as nothing is exactly how a qualified figure turns
/// into a confident one.
library;

import '../../l10n/app_localizations.dart';
import '../domain/comparison_eligibility.dart';

/// Why a metric has no comparable number, in the user's language.
String comparisonReasonLabel(
        AppLocalizations l, ComparisonUnavailableReason reason) =>
    switch (reason) {
      ComparisonUnavailableReason.noEvidence => l.vehCompareReasonNoEvidence,
      ComparisonUnavailableReason.tooFewSamples =>
        l.vehCompareReasonTooFewSamples,
      ComparisonUnavailableReason.noMatchedDistance =>
        l.vehCompareReasonNoMatchedDistance,
      ComparisonUnavailableReason.mixedCurrencies =>
        l.vehCompareReasonMixedCurrencies,
      ComparisonUnavailableReason.unknownCurrency =>
        l.vehCompareReasonUnknownCurrency,
      ComparisonUnavailableReason.exchangeRateUnavailable =>
        l.vehCompareReasonExchangeRateUnavailable,
      ComparisonUnavailableReason.exchangeRateStale =>
        l.vehCompareReasonExchangeRateStale,
      ComparisonUnavailableReason.incompatibleUnits =>
        l.vehCompareReasonIncompatibleUnits,
      ComparisonUnavailableReason.unsupportedUnit =>
        l.vehCompareReasonUnsupportedUnit,
      ComparisonUnavailableReason.ambiguousAttribution =>
        l.vehCompareReasonAmbiguousAttribution,
      ComparisonUnavailableReason.missingPrices =>
        l.vehCompareReasonMissingPrices,
      ComparisonUnavailableReason.noExpectedConsumption =>
        l.vehCompareReasonNoExpectedConsumption,
      ComparisonUnavailableReason.incompleteConditionCoverage =>
        l.vehCompareReasonIncompleteConditionCoverage,
    };

/// A caveat that must travel with the figure it qualifies.
String comparisonQualificationLabel(
        AppLocalizations l, ComparisonQualification qualification) =>
    switch (qualification) {
      ComparisonQualification.uncontrolledConditions =>
        l.vehCompareQualUncontrolledConditions,
      ComparisonQualification.partialConditionCoverage =>
        l.vehCompareQualPartialConditionCoverage,
      ComparisonQualification.unequalSampleSizes =>
        l.vehCompareQualUnequalSampleSizes,
      ComparisonQualification.estimatedBasis =>
        l.vehCompareQualEstimatedBasis,
      ComparisonQualification.staleBasis => l.vehCompareQualStaleBasis,
      ComparisonQualification.mixedProvenance =>
        l.vehCompareQualMixedProvenance,
      ComparisonQualification.convertedCurrency =>
        l.vehCompareQualConvertedCurrency,
      ComparisonQualification.excludedRecords =>
        l.vehCompareQualExcludedRecords,
      ComparisonQualification.openWindowExcluded =>
        l.vehCompareQualOpenWindowExcluded,
      ComparisonQualification.unknownBlendShare =>
        l.vehCompareQualUnknownBlendShare,
      ComparisonQualification.reconstructedValuation =>
        l.vehCompareQualReconstructedValuation,
    };

/// Every caveat on [metric], in a stable order so two columns read
/// alike.
List<String> comparisonQualificationLabels(
    AppLocalizations l, ComparableMetric<Object> metric) {
  final out = <String>[
    for (final q in ComparisonQualification.values)
      if (metric.qualifications.contains(q))
        comparisonQualificationLabel(l, q),
  ];
  return out;
}
