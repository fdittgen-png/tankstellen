// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../../../../core/domain/fuel/behaviour_metric.dart';
import '../../../../../core/domain/fuel/fuel_context.dart';
import '../../../../../core/domain/fuel/fuel_grade.dart';
import '../../../../../core/domain/fuel/next_fill_decision.dart';
import '../../../../../core/domain/fuel/next_fill_request.dart';
import '../../../../../core/domain/fuel_type.dart';
import '../../../../../core/utils/localized_fuel_name.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/services/fuel_and_tank_view.dart';

/// Every domain code the Fuel & Tank surface shows, mapped to ARB copy
/// (#4278). Each switch is exhaustive on purpose: a new enum value is a
/// compile error here, never a silently blank line on screen.
abstract final class FuelAndTankLabels {
  /// The localized name of a liquid [grade] (never `FuelType.displayName`).
  static String grade(AppLocalizations l, FuelGrade grade) =>
      localizedFuelName(l, FuelType.fromString(grade.key));

  static String context(AppLocalizations l, FuelContext context) =>
      switch (context.kind) {
        FuelContextKind.pure => grade(l, context.grades.single),
        FuelContextKind.mixed => l.fuelAndTankMixedContext(
            grade(l, context.grades[0]), grade(l, context.grades[1])),
        FuelContextKind.unknown => l.fuelAndTankMixUnknownTitle,
      };

  static String objective(AppLocalizations l, FillObjective objective) =>
      switch (objective) {
        FillObjective.lowestCostPerKm => l.fuelAndTankObjectiveCost,
        FillObjective.lowestConsumption => l.fuelAndTankObjectiveConsumption,
        FillObjective.lowestCo2ePerKm => l.fuelAndTankObjectiveCo2e,
        FillObjective.balancedCostCo2e => l.fuelAndTankObjectiveBalanced,
        FillObjective.maxRange => l.fuelAndTankObjectiveRange,
      };

  static String outcome(AppLocalizations l, NextFillDecision decision) =>
      switch (decision.outcome) {
        NextFillOutcome.recommend => l.fuelAndTankOutcomeRecommend(
            grade(l, decision.recommended ?? decision.candidates.first.grade)),
        NextFillOutcome.noMaterialAdvantage => l.fuelAndTankOutcomeNoAdvantage,
        NextFillOutcome.insufficientEvidence =>
          l.fuelAndTankOutcomeInsufficient,
        NextFillOutcome.tradeOff => l.fuelAndTankOutcomeTradeOff,
        NextFillOutcome.noCompatibleFuel => l.fuelAndTankOutcomeNoCompatible,
        NextFillOutcome.compatibilityUnknown =>
          l.fuelAndTankOutcomeCompatibilityUnknown,
      };

  static String reason(AppLocalizations l, DecisionReason reason) =>
      switch (reason) {
        DecisionReason.capabilityUnknown =>
          l.fuelAndTankReasonCapabilityUnknown,
        DecisionReason.gradeNotApproved => l.fuelAndTankReasonGradeNotApproved,
        DecisionReason.fillVolumeUnknown =>
          l.fuelAndTankReasonFillVolumeUnknown,
        DecisionReason.resultingBlendUnknown =>
          l.fuelAndTankReasonResultingBlendUnknown,
        DecisionReason.noBehaviourEvidence =>
          l.fuelAndTankReasonNoBehaviourEvidence,
        DecisionReason.interpolatedFromPureContexts =>
          l.fuelAndTankReasonInterpolated,
        DecisionReason.confoundersUncontrolled =>
          l.fuelAndTankReasonConfoundersUncontrolled,
        DecisionReason.noCo2eFactor => l.fuelAndTankReasonNoCo2eFactor,
        DecisionReason.capacityUnknown => l.fuelAndTankReasonCapacityUnknown,
        DecisionReason.detourNotPriced => l.fuelAndTankReasonDetourNotPriced,
        DecisionReason.detourIncluded => l.fuelAndTankReasonDetourIncluded,
        DecisionReason.onlyOneCandidate =>
          l.fuelAndTankReasonOnlyOneCandidate,
        DecisionReason.unevaluatedAlternatives =>
          l.fuelAndTankReasonUnevaluatedAlternatives,
        DecisionReason.uncertaintyDominates =>
          l.fuelAndTankReasonUncertaintyDominates,
        DecisionReason.belowMaterialThreshold =>
          l.fuelAndTankReasonBelowMaterialThreshold,
      };

  static String confidence(AppLocalizations l, DecisionConfidence c) =>
      switch (c) {
        DecisionConfidence.low => l.fuelAndTankConfidenceLow,
        DecisionConfidence.medium => l.fuelAndTankConfidenceMedium,
        DecisionConfidence.high => l.fuelAndTankConfidenceHigh,
      };

  static String provenance(AppLocalizations l, ProvenanceKind kind) =>
      switch (kind) {
        ProvenanceKind.measured => l.fuelAndTankProvenanceMeasured,
        ProvenanceKind.estimated => l.fuelAndTankProvenanceEstimated,
      };

  static String basis(AppLocalizations l, MetricBasis basis) =>
      switch (basis) {
        MetricBasis.referenceWindows => l.fuelAndTankBasisReferenceWindows,
        MetricBasis.measuredTrips => l.fuelAndTankBasisMeasuredTrips,
        MetricBasis.estimatedTrips => l.fuelAndTankBasisEstimatedTrips,
        MetricBasis.measuredResiduals => l.fuelAndTankBasisMeasuredResiduals,
        MetricBasis.estimatedResiduals =>
          l.fuelAndTankBasisEstimatedResiduals,
        MetricBasis.derived => l.fuelAndTankBasisDerived,
      };

  static String insufficient(AppLocalizations l, InsufficientReason? r) =>
      switch (r) {
        InsufficientReason.noEvidence ||
        null =>
          l.fuelAndTankInsufficientNoEvidence,
        InsufficientReason.tooFewSamples =>
          l.fuelAndTankInsufficientTooFewSamples,
        InsufficientReason.tooLittleDistance =>
          l.fuelAndTankInsufficientTooLittleDistance,
        InsufficientReason.capacityUnknown =>
          l.fuelAndTankInsufficientCapacityUnknown,
        InsufficientReason.noCo2eFactor =>
          l.fuelAndTankInsufficientNoCo2eFactor,
        InsufficientReason.contextNotPure =>
          l.fuelAndTankInsufficientContextNotPure,
        InsufficientReason.uncertaintyTooWide =>
          l.fuelAndTankInsufficientTooUncertain,
        // #4364 — an adjusted figure claims conditions were controlled;
        // production evaluates cold starts alone, so it says so instead.
        InsufficientReason.incompleteConditionCoverage =>
          l.fuelAndTankInsufficientConditionCoverage,
        InsufficientReason.mixedCurrencies =>
          l.fuelAndTankInsufficientMixedCurrencies,
      };

  /// The general technical fact for one grade, or null when the standard
  /// guarantees nothing worth stating.
  static String? fact(AppLocalizations l, GradeFactView f) {
    final name = grade(l, f.grade);
    String pct(int v) => v.toString();
    return switch (f.grade) {
      FuelGrade.e5 || FuelGrade.e10 => l.fuelAndTankFactPetrol(
          name, pct(f.petrolPercent), pct(f.openPercent)),
      FuelGrade.e98 => '${l.fuelAndTankFactPetrol(name, pct(f.petrolPercent), pct(f.openPercent))} '
          '${l.fuelAndTankFactOctane(name)}',
      FuelGrade.e85 => l.fuelAndTankFactEthanol(name, pct(f.ethanolPercent)),
      FuelGrade.diesel ||
      FuelGrade.dieselPremium =>
        l.fuelAndTankFactDiesel(name, pct(f.dieselPercent), pct(f.openPercent)),
      FuelGrade.lpg => l.fuelAndTankFactLpg(name),
      FuelGrade.cng ||
      FuelGrade.hydrogen ||
      FuelGrade.electric ||
      FuelGrade.wildcard ||
      FuelGrade.unknown =>
        null,
    };
  }

  /// "≥ 62 % E85 · ≥ 30 % E10 · 8 % unknown" — separators only between
  /// ARB-owned fragments.
  static String mixLine(AppLocalizations l, TankMixView mix) => [
        for (final s in mix.shares)
          mix.isExact
              ? l.fuelAndTankMixShareExact(s.percent.toString(), grade(l, s.grade))
              : l.fuelAndTankMixShareAtLeast(
                  s.percent.toString(), grade(l, s.grade)),
        if (mix.unknownPercent > 0)
          l.fuelAndTankMixUnknownShare(mix.unknownPercent.toString()),
      ].join(' · ');
}
