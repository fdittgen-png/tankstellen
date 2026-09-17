// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'behaviour_metric.dart';
import 'fuel_behaviour_profile.dart';
import 'fuel_grade.dart';
import 'next_fill_candidates.dart';
import 'next_fill_convergence.dart';
import 'next_fill_decision.dart';
import 'next_fill_ranking.dart';
import 'next_fill_request.dart';
import 'tank_blend_snapshot.dart';
import 'tank_blend_state.dart';

/// Decides whether the next fill should change fuel (#4277).
///
/// ## Rules
///
///  * **Compatibility first.** An unknown capability recommends nothing;
///    a grade the vehicle is not approved for is excluded, never ranked.
///  * **Consumption, never price alone.** A candidate is ranked only on
///    learned behaviour for the blend the fill would produce. Without it
///    the candidate is listed with [DecisionReason.noBehaviourEvidence].
///  * **One basis for all.** Candidates are compared condition-adjusted
///    only when every one of them is; otherwise all on absolute figures,
///    with [DecisionReason.confoundersUncontrolled].
///  * **Uncertainty decides.** A leader must beat each alternative by at
///    least [NextFillRequest.minMaterialAdvantage] AND by more than the
///    95 % combined interval (`t · √(se_a² + se_b²)`, treating the two as
///    independent — conservative when they share evidence). Otherwise
///    [NextFillOutcome.noMaterialAdvantage] or
///    [NextFillOutcome.insufficientEvidence].
///  * **No opaque score.** Every candidate carries its metric values, and
///    the leader a [FillTradeOff] with break-even price and consumption
///    against each alternative.
///
/// Deterministic per [NextFillDecision.currentModelVersion]: no clock, and
/// every ordering has a total tie-break on the grade.
abstract final class NextFillDecider {
  static NextFillDecision decide({
    required TankBlendSnapshot tank,
    required FuelBehaviourProfile profile,
    required NextFillRequest request,
  }) {
    NextFillDecision result(NextFillOutcome outcome,
            {List<FillCandidate> candidates = const [],
            List<ExcludedFuel> excluded = const [],
            List<DecisionReason> reasons = const [],
            List<FillTradeOff> tradeOffs = const [],
            DecisionConfidence confidence = DecisionConfidence.low,
            FuelGrade? recommended,
            ConvergencePlan? convergence}) =>
        NextFillDecision(
          objective: request.objective,
          outcome: outcome,
          candidates: candidates,
          excluded: excluded,
          reasons: reasons,
          tradeOffs: tradeOffs,
          confidence: confidence,
          profileModelVersion: profile.modelVersion,
          blendModelVersion: tank.modelVersion,
          minMaterialAdvantage: request.minMaterialAdvantage,
          recommended: recommended,
          convergence: convergence,
        );

    final offers = [...request.offers]..sort((a, b) {
        final byGrade = a.grade.index.compareTo(b.grade.index);
        if (byGrade != 0) return byGrade;
        final byPrice = a.pricePerLitre.compareTo(b.pricePerLitre);
        return byPrice != 0
            ? byPrice
            : (a.station?.stationId ?? '').compareTo(b.station?.stationId ?? '');
      });
    if (request.capability.isUnknown) {
      return result(NextFillOutcome.compatibilityUnknown,
          excluded: _excludeAll(offers, DecisionReason.capabilityUnknown),
          reasons: const [DecisionReason.capabilityUnknown]);
    }
    final approved = [
      for (final o in offers)
        if (o.grade.isLiquid && request.capability.permits(o.grade)) o,
    ];
    final excluded = _excludeAll(
        offers.where((o) => !approved.contains(o)),
        DecisionReason.gradeNotApproved);
    if (approved.isEmpty) {
      return result(NextFillOutcome.noCompatibleFuel,
          excluded: excluded, reasons: const [DecisionReason.gradeNotApproved]);
    }
    final capacity = tank.tankCapacityLitres;
    final maxVolume = tank.maxLitres;
    final litres = request.expectedFillLitres ??
        (capacity != null && maxVolume != null ? capacity - maxVolume : null);
    if (tank.modelVersion != TankBlendState.currentModelVersion ||
        litres == null ||
        litres <= 1e-9) {
      return result(NextFillOutcome.insufficientEvidence,
          excluded: excluded,
          reasons: [
            tank.modelVersion != TankBlendState.currentModelVersion
                ? DecisionReason.resultingBlendUnknown
                : DecisionReason.fillVolumeUnknown,
          ]);
    }

    final eval = NextFillCandidates(tank: tank, profile: profile);
    final blends = {
      for (final g in approved.map((o) => o.grade).toSet())
        g: eval.resultingBlend(g, litres),
    };
    final adjusted = blends.values
        .every((b) => eval.expectation(b, adjusted: true).lPer100Km.isKnown);
    final byGrade = <FuelGrade, FillCandidate>{};
    for (final offer in approved) {
      final blend = blends[offer.grade]!;
      final c = eval.evaluate(offer, litres, blend,
          eval.expectation(blend, adjusted: adjusted));
      final kept = byGrade[offer.grade];
      if (kept == null || c.effectivePricePerLitre < kept.effectivePricePerLitre) {
        byGrade[offer.grade] = c;
      }
    }
    final ranking = NextFillRanking.rank(
        byGrade.values.toList(), request.objective, request.minMaterialAdvantage);
    final reasons = [
      if (!adjusted &&
          byGrade.values.any((c) => c.metrics.lPer100Km.isKnown))
        DecisionReason.confoundersUncontrolled,
      ...ranking.reasons,
    ];
    final recommended =
        ranking.outcome == NextFillOutcome.recommend ? ranking.ordered.first.grade : null;
    final target = request.target ??
        (recommended == null ? null : TargetBlend(grade: recommended));
    return result(
      ranking.outcome,
      candidates: ranking.ordered,
      excluded: excluded,
      reasons: reasons,
      tradeOffs: _tradeOffs(ranking.ordered),
      confidence: ranking.confidence,
      recommended: recommended,
      convergence: target == null
          ? null
          : NextFillConvergence.plan(
              tank: tank,
              engine: eval.engine,
              target: target,
              litres: litres,
              approved: request.capability.permits(target.grade),
              tolerance: request.targetTolerance,
              maxFills: request.maxConvergenceFills,
            ),
    );
  }

  static List<ExcludedFuel> _excludeAll(
          Iterable<FuelOffer> offers, DecisionReason reason) =>
      [
        for (final g in offers.map((o) => o.grade).toSet())
          ExcludedFuel(g, reason),
      ];

  /// The leading candidate against every other one.
  static List<FillTradeOff> _tradeOffs(List<FillCandidate> ordered) {
    if (ordered.length < 2) return const [];
    final lead = ordered.first;
    double? delta(BehaviourMetric a, BehaviourMetric b) =>
        a.isKnown && b.isKnown ? a.value! - b.value! : null;
    return [
      for (final alt in ordered.skip(1))
        () {
          final lLead = lead.metrics.lPer100Km.value;
          final lAlt = alt.metrics.lPer100Km.value;
          final altCost = lAlt == null ? null : alt.effectivePricePerLitre * lAlt;
          return FillTradeOff(
            chosen: lead.grade,
            alternative: alt.grade,
            costPerKmDelta:
                delta(lead.metrics.costPerKm, alt.metrics.costPerKm),
            co2eKgPerKmDelta:
                delta(lead.metrics.co2eKgPerKm, alt.metrics.co2eKgPerKm),
            lPer100KmDelta:
                delta(lead.metrics.lPer100Km, alt.metrics.lPer100Km),
            breakEvenPricePerLitre:
                altCost == null || lLead == null ? null : altCost / lLead,
            breakEvenLPer100Km: altCost == null
                ? null
                : altCost / lead.effectivePricePerLitre,
          );
        }(),
    ];
  }
}
