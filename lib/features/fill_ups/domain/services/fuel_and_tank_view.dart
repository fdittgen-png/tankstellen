// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:meta/meta.dart';

import '../../../../core/domain/fuel/behaviour_metric.dart';
import '../../../../core/domain/fuel/fuel_behaviour_profile.dart';
import '../../../../core/domain/fuel/fuel_grade.dart';
import '../../../../core/domain/fuel/next_fill_decision.dart';
import '../../../../core/domain/fuel/next_fill_request.dart';
import '../../../../core/domain/fuel/tank_blend_snapshot.dart';
import 'fuel_behaviour_view.dart';
import 'next_fill_offers.dart';
import 'tank_mix_view.dart';

export 'fuel_behaviour_view.dart';
export 'next_fill_offers.dart' show NextFillOfferSource;
export 'tank_mix_view.dart';

/// What the vehicle's settings approve, and what merely fits (#4278).
@immutable
final class CompatibilityView {
  const CompatibilityView({
    required this.isUnknown,
    required this.approved,
    required this.unconfirmed,
  });

  /// No approval information at all.
  final bool isUnknown;

  /// Grades the vehicle's settings vouch for, in grade order.
  final List<FuelGrade> approved;

  /// Grades that fit the filler neck but no setting confirms.
  final List<FuelGrade> unconfirmed;
}

/// One evaluated next-fill candidate with its figures resolved (#4278).
@immutable
final class CandidateView {
  CandidateView._(this.candidate)
      : resultingMix = TankMixView.of(candidate.resultingBlend),
        lPer100Km = _metric(candidate, candidate.metrics.lPer100Km),
        costPerKm = _metric(candidate, candidate.metrics.costPerKm),
        rangeKm = _metric(candidate, candidate.metrics.rangeKm),
        co2eKgPerKm = _metric(candidate, candidate.metrics.co2eKgPerKm);

  /// Every candidate figure is arithmetic over the candidate's expected
  /// consumption, so each carries that consumption's weakest basis.
  static MetricView _metric(FillCandidate c, BehaviourMetric m) =>
      MetricView.resolved(m, c.metricBasis);

  final FillCandidate candidate;
  final TankMixView resultingMix;
  final MetricView lPer100Km;
  final MetricView costPerKm;
  final MetricView rangeKm;
  final MetricView co2eKgPerKm;
}

/// A convergence plan reduced to its sentence's numbers (#4278).
@immutable
final class ConvergenceView {
  const ConvergenceView._(this.plan, this.percent, this.fills);

  /// [percent] is what the sentence may truthfully claim: the tank's
  /// current guaranteed share when already there, the share the plan's
  /// last fill guarantees when reachable, else the target itself.
  factory ConvergenceView.of(ConvergencePlan plan, TankBlendSnapshot tank) {
    int floor(double share) => (share * 100 + 1e-9).floor();
    final after = plan.minimumShareAfterFill;
    return switch (plan.status) {
      ConvergenceStatus.alreadyAtTarget => ConvergenceView._(
          plan, floor(tank.minimumShare(plan.target.grade)), 0),
      ConvergenceStatus.reachable => ConvergenceView._(plan,
          floor(after.isEmpty ? 0 : after.last), plan.fillsNeeded ?? after.length),
      ConvergenceStatus.unreachableWithinHorizon ||
      ConvergenceStatus.notComputable =>
        ConvergenceView._(
            plan, (plan.target.minimumShare * 100).round(), after.length),
    };
  }

  final ConvergencePlan plan;
  final int percent;

  /// Fills the plan needs (reachable) or looked ahead (unreachable).
  final int fills;

  /// The target share, in whole percent.
  int get targetPercent => (plan.target.minimumShare * 100).round();

  /// The plan's tolerance below the target, in whole points (#4324).
  int get tolerancePoints => (plan.tolerance * 100).round();

  /// Counted as reached although [percent] stays under the target — the
  /// sentence must then say "within [tolerancePoints] points" (#4324).
  bool get withinTolerance =>
      (plan.status == ConvergenceStatus.alreadyAtTarget ||
          plan.status == ConvergenceStatus.reachable) &&
      percent < targetPercent;
}

/// The next-fill guidance, ready to format (#4278).
@immutable
final class NextFillView {
  NextFillView({
    required this.decision,
    required this.offerCount,
    required TankBlendSnapshot tank,
    this.offerSource = NextFillOfferSource.favourites,
  })  : candidates = List.unmodifiable(
            decision.candidates.map(CandidateView._)),
        convergence = decision.convergence == null
            ? null
            : ConvergenceView.of(decision.convergence!, tank);

  final NextFillDecision decision;
  final ConvergenceView? convergence;

  /// Distinct offers the decision was given; 0 = no prices to compare.
  final int offerCount;

  /// Where the prices came from (#4324): the last search's stations (with
  /// the detour priced) or the favourites' cache.
  final NextFillOfferSource offerSource;
  final List<CandidateView> candidates;

  FillObjective get objective => decision.objective;

  /// The decision's material-advantage threshold in whole percent (#4324).
  int get materialAdvantagePercent =>
      (decision.minMaterialAdvantage * 100).round();

  /// Whether the decision itself is the message. An unknown capability
  /// is said even without prices — it is the more fundamental gap; any
  /// other outcome over zero offers would only restate "no prices".
  bool get showsDecision =>
      offerCount > 0 ||
      decision.outcome == NextFillOutcome.compatibilityUnknown;
}

/// Everything the Fuel & Tank surface shows, derived once (#4278). The
/// widgets only format these values — no blend arithmetic or decision
/// logic lives below this line.
@immutable
final class FuelAndTankView {
  const FuelAndTankView({
    required this.mix,
    required this.compatibility,
    required this.rows,
    required this.comparisons,
    required this.facts,
    required this.nextFill,
    required this.profileModelVersion,
    required this.blendModelVersion,
  });

  final TankMixView mix;
  final CompatibilityView compatibility;
  final List<ContextBehaviourView> rows;
  final List<GradeComparisonView> comparisons;
  final List<GradeFactView> facts;
  final NextFillView nextFill;
  final int profileModelVersion;
  final int blendModelVersion;

  /// Whether any row is judged on figures not adjusted for conditions.
  bool get anyUncontrolled => rows.any(
      (r) => r.confounderControl == ConfounderControl.uncontrolled);
}

/// Assembles the [FuelAndTankView] from the canonical domain results.
FuelAndTankView buildFuelAndTankView({
  required TankBlendSnapshot tank,
  required FuelBehaviourProfile profile,
  required VehicleFuelCapability capability,
  required FuelGrade? configuredGrade,
  required List<FuelGrade> priceableGrades,
  required NextFillRequest request,
  required NextFillDecision decision,
}) {
  int byIndex(FuelGrade x, FuelGrade y) => x.index.compareTo(y.index);
  final approved = capability.approvedGrades.toList()..sort(byIndex);
  final unconfirmed = [
    for (final g in priceableGrades)
      if (!capability.permits(g)) g,
  ]..sort(byIndex);
  final mix = TankMixView.of(tank);
  final behaviour = behaviourViewsOf(profile,
      approvedGrades: approved, configuredGrade: configuredGrade);
  final factGrades = {
    ...approved,
    ...unconfirmed,
    for (final s in mix.shares) s.grade,
  }.where((g) => g.isLiquid).toList()
    ..sort(byIndex);
  return FuelAndTankView(
    mix: mix,
    compatibility: CompatibilityView(
      isUnknown: capability.isUnknown,
      approved: List.unmodifiable(approved),
      unconfirmed: List.unmodifiable(unconfirmed),
    ),
    rows: List.unmodifiable(behaviour.rows),
    comparisons: List.unmodifiable(behaviour.comparisons),
    facts: List.unmodifiable(factGrades.map(GradeFactView.of)),
    nextFill: NextFillView(
      decision: decision,
      offerCount: request.offers.map((o) => o.grade).toSet().length,
      offerSource: offerSourceOf(request.offers),
      tank: tank,
    ),
    profileModelVersion: profile.modelVersion,
    blendModelVersion: tank.modelVersion,
  );
}
