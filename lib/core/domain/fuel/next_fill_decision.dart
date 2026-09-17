// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:meta/meta.dart';

import 'behaviour_metric.dart';
import 'fuel_context.dart';
import 'fuel_grade.dart';
import 'next_fill_request.dart';
import 'tank_blend_snapshot.dart';

/// What the next-fill decision concluded (#4277).
enum NextFillOutcome {
  /// One candidate is materially better on the objective, beyond the
  /// uncertainty of the evidence.
  recommend,

  /// The candidates differ by less than the material threshold.
  noMaterialAdvantage,

  /// The difference might be real, but the uncertainty (or missing
  /// evidence) is at least as large. No recommendation.
  insufficientEvidence,

  /// Balanced objective only: one fuel wins on cost, another on CO2e.
  tradeOff,

  /// No offered fuel is approved for the vehicle.
  noCompatibleFuel,

  /// The vehicle's approvals are unknown — nothing may be recommended.
  compatibilityUnknown,
}

/// Structured explanation codes. No user-facing text lives in the domain;
/// the surface (#4278) maps each code to ARB copy.
enum DecisionReason {
  capabilityUnknown,
  gradeNotApproved,
  fillVolumeUnknown,
  resultingBlendUnknown,
  noBehaviourEvidence,
  interpolatedFromPureContexts,
  confoundersUncontrolled,
  noCo2eFactor,
  capacityUnknown,
  detourNotPriced,
  detourIncluded,
  onlyOneCandidate,
  unevaluatedAlternatives,
  uncertaintyDominates,
  belowMaterialThreshold,
}

/// Where a candidate's expected consumption comes from.
enum ExpectationBasis {
  /// The resulting context's own learned behaviour.
  learned,

  /// A mixed tank expressed as its guaranteed shares of learned pure
  /// grades, with the unattributed slack widening the interval.
  interpolated,

  /// No usable behaviour.
  none,
}

/// How much the decision may be trusted.
enum DecisionConfidence { low, medium, high }

/// The expected metrics after filling one candidate.
@immutable
final class CandidateMetrics {
  const CandidateMetrics({
    required this.lPer100Km,
    required this.costPerKm,
    required this.co2eKgPerKm,
    required this.rangeKm,
  });

  final BehaviourMetric lPer100Km;
  final BehaviourMetric costPerKm;
  final BehaviourMetric co2eKgPerKm;
  final BehaviourMetric rangeKm;

  /// The metric an objective ranks on (balanced ranks two — see the decider).
  BehaviourMetric of(FillObjective objective) => switch (objective) {
        FillObjective.lowestCostPerKm ||
        FillObjective.balancedCostCo2e =>
          costPerKm,
        FillObjective.lowestConsumption => lPer100Km,
        FillObjective.lowestCo2ePerKm => co2eKgPerKm,
        FillObjective.maxRange => rangeKm,
      };

  Map<String, Object?> toJson() => {
        'lPer100Km': lPer100Km.toJson(),
        'costPerKm': costPerKm.toJson(),
        'co2eKgPerKm': co2eKgPerKm.toJson(),
        'rangeKm': rangeKm.toJson(),
      };
}

/// One compatible fuel, evaluated.
@immutable
final class FillCandidate {
  FillCandidate({
    required this.grade,
    required this.pricePerLitre,
    required this.effectivePricePerLitre,
    required this.fillLitres,
    required this.resultingBlend,
    required this.resultingContext,
    required this.metrics,
    required this.basis,
    required this.metricBasis,
    required Iterable<DecisionReason> reasons,
  }) : reasons = List.unmodifiable(reasons);

  final FuelGrade grade;
  final double pricePerLitre;

  /// Pump price plus the detour per litre bought (`RefuelEconomics`).
  final double effectivePricePerLitre;
  final double fillLitres;

  /// The #4275 engine's blend after this fill.
  final TankBlendSnapshot resultingBlend;
  final FuelContext resultingContext;
  final CandidateMetrics metrics;
  final ExpectationBasis basis;

  /// The weakest basis behind [metrics.lPer100Km] (null when unknown).
  final MetricBasis? metricBasis;
  final List<DecisionReason> reasons;

  Map<String, Object?> toJson() => {
        'grade': grade.key,
        'pricePerLitre': pricePerLitre,
        'effectivePricePerLitre': effectivePricePerLitre,
        'fillLitres': fillLitres,
        'resultingShares': resultingBlend.toJson()['gradeShares'],
        'resultingContext': resultingContext.key,
        'metrics': metrics.toJson(),
        'basis': basis.name,
        'metricBasis': metricBasis?.name,
        'reasons': [for (final r in reasons) r.name],
      };
}

/// A fuel left out, and why.
@immutable
final class ExcludedFuel {
  const ExcludedFuel(this.grade, this.reason);
  final FuelGrade grade;
  final DecisionReason reason;

  Map<String, Object?> toJson() => {'grade': grade.key, 'reason': reason.name};
}

/// The recommended fuel against one alternative: the metric deltas and,
/// for cost, where the decision would flip (spec §2's break-even, per km).
@immutable
final class FillTradeOff {
  const FillTradeOff({
    required this.chosen,
    required this.alternative,
    required this.costPerKmDelta,
    required this.co2eKgPerKmDelta,
    required this.lPer100KmDelta,
    required this.breakEvenPricePerLitre,
    required this.breakEvenLPer100Km,
  });

  final FuelGrade chosen;
  final FuelGrade alternative;

  /// chosen − alternative; negative = chosen is lower. Null when unknown.
  final double? costPerKmDelta;
  final double? co2eKgPerKmDelta;
  final double? lPer100KmDelta;

  /// The effective price of [chosen] at which its cost/km equals the
  /// alternative's: `p_alt · L_alt / L_chosen`.
  final double? breakEvenPricePerLitre;

  /// The consumption [chosen] would need to tie on cost at today's prices:
  /// `p_alt · L_alt / p_chosen`.
  final double? breakEvenLPer100Km;

  /// Money per kg CO2e avoided when [chosen] is dearer but cleaner (or the
  /// reverse) — the honest statement of a trade-off, not a score. The side
  /// that avoids the CO2e is [cleaner].
  double? get costPerKgCo2e {
    final c = costPerKmDelta, e = co2eKgPerKmDelta;
    if (c == null || e == null || e == 0) return null;
    return -c / e;
  }

  /// The grade with the lower CO2e per km (#4324): [chosen] when its delta
  /// is negative, [alternative] when positive, null when the delta is
  /// unknown or zero — so no caller has to read a sign to know which side
  /// is cleaner.
  FuelGrade? get cleaner {
    final e = co2eKgPerKmDelta;
    if (e == null || e == 0) return null;
    return e < 0 ? chosen : alternative;
  }

  Map<String, Object?> toJson() => {
        'chosen': chosen.key,
        'alternative': alternative.key,
        'costPerKmDelta': costPerKmDelta,
        'co2eKgPerKmDelta': co2eKgPerKmDelta,
        'lPer100KmDelta': lPer100KmDelta,
        'breakEvenPricePerLitre': breakEvenPricePerLitre,
        'breakEvenLPer100Km': breakEvenLPer100Km,
        'cleaner': cleaner?.key,
      };
}

/// Whether and how the tank reaches a target blend.
enum ConvergenceStatus {
  alreadyAtTarget,
  reachable,
  unreachableWithinHorizon,
  notComputable,
}

/// Repeated fills of one grade toward a [TargetBlend] (#4277): the
/// guaranteed share after each fill, burning the fill volume in between.
@immutable
final class ConvergencePlan {
  ConvergencePlan({
    required this.target,
    required this.tolerance,
    required this.status,
    required Iterable<double> minimumShareAfterFill,
    this.fillsNeeded,
    this.reason,
  }) : minimumShareAfterFill = List.unmodifiable(minimumShareAfterFill);

  final TargetBlend target;

  /// How far below [TargetBlend.minimumShare] still counts as reached
  /// (#4324): a plan is [ConvergenceStatus.alreadyAtTarget] or
  /// [ConvergenceStatus.reachable] from `minimumShare − tolerance` up, so a
  /// surface can say "within N points of the target" instead of implying
  /// the target itself was met.
  final double tolerance;
  final ConvergenceStatus status;
  final List<double> minimumShareAfterFill;

  /// 0 when already there; null when not reachable or not computable.
  final int? fillsNeeded;
  final DecisionReason? reason;

  Map<String, Object?> toJson() => {
        'grade': target.grade.key,
        'minimumShare': target.minimumShare,
        'tolerance': tolerance,
        'status': status.name,
        'minimumShareAfterFill': minimumShareAfterFill,
        'fillsNeeded': fillsNeeded,
        'reason': reason?.name,
      };
}

/// The deterministic next-fill decision (#4277). Every conclusion carries
/// the metric values it rests on — never an opaque score.
@immutable
final class NextFillDecision {
  NextFillDecision({
    required this.objective,
    required this.outcome,
    required Iterable<FillCandidate> candidates,
    required Iterable<ExcludedFuel> excluded,
    required Iterable<DecisionReason> reasons,
    required Iterable<FillTradeOff> tradeOffs,
    required this.confidence,
    required this.profileModelVersion,
    required this.blendModelVersion,
    required this.minMaterialAdvantage,
    this.recommended,
    this.convergence,
  })  : candidates = List.unmodifiable(candidates),
        excluded = List.unmodifiable(excluded),
        reasons = List.unmodifiable(reasons),
        tradeOffs = List.unmodifiable(tradeOffs);

  /// Bump when a threshold, rule or formula of the decision changes.
  static const int currentModelVersion = 1;
  int get modelVersion => currentModelVersion;

  final FillObjective objective;
  final NextFillOutcome outcome;

  /// The grade to fill, only when [outcome] is [NextFillOutcome.recommend].
  final FuelGrade? recommended;

  /// Evaluated candidates, best first on the objective (unknown last).
  final List<FillCandidate> candidates;
  final List<ExcludedFuel> excluded;
  final List<DecisionReason> reasons;

  /// The leading candidate against each other evaluated one.
  final List<FillTradeOff> tradeOffs;
  final DecisionConfidence confidence;
  final ConvergencePlan? convergence;
  final int profileModelVersion;
  final int blendModelVersion;

  /// The smallest relative advantage (0.02 = 2 %) this decision treated as
  /// worth a change of fuel (#4324) — what "the difference is too small"
  /// was measured against, so a surface can quote it.
  final double minMaterialAdvantage;

  Map<String, Object?> toJson() => {
        'modelVersion': modelVersion,
        'minMaterialAdvantage': minMaterialAdvantage,
        'profileModelVersion': profileModelVersion,
        'blendModelVersion': blendModelVersion,
        'objective': objective.name,
        'outcome': outcome.name,
        'recommended': recommended?.key,
        'confidence': confidence.name,
        'reasons': [for (final r in reasons) r.name],
        'candidates': [for (final c in candidates) c.toJson()],
        'excluded': [for (final e in excluded) e.toJson()],
        'tradeOffs': [for (final t in tradeOffs) t.toJson()],
        'convergence': convergence?.toJson(),
      };
}
