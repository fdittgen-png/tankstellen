// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:math' as math;

import 'behaviour_metric.dart';
import 'next_fill_candidates.dart';
import 'next_fill_decision.dart';
import 'next_fill_request.dart';

/// How two known metrics compare, beyond materiality and uncertainty.
enum MetricComparison { better, worse, same, uncertain }

/// The ranking half of the decision (#4277), separated so its rules are
/// testable on their own.
abstract final class NextFillRanking {
  /// [a] against [b] on [a]'s objective direction.
  static MetricComparison compare(BehaviourMetric a, BehaviourMetric b,
      {required bool higherIsBetter, required double minMaterial}) {
    final gain = higherIsBetter ? a.value! - b.value! : b.value! - a.value!;
    final scale = b.value!.abs();
    if (scale == 0 || gain.abs() / scale < minMaterial) {
      return MetricComparison.same;
    }
    final se = math.sqrt(
        math.pow(a.standardError!, 2) + math.pow(b.standardError!, 2));
    final n = math.max(1, math.min(a.sampleCount, b.sampleCount) - 1);
    if (gain.abs() <= BehaviourMetric.t95(n) * se) {
      return MetricComparison.uncertain;
    }
    return gain > 0 ? MetricComparison.better : MetricComparison.worse;
  }

  static ({
    NextFillOutcome outcome,
    List<FillCandidate> ordered,
    List<DecisionReason> reasons,
    DecisionConfidence confidence,
  }) rank(List<FillCandidate> candidates, FillObjective objective,
      double minMaterial) {
    final higher = objective == FillObjective.maxRange;
    final balanced = objective == FillObjective.balancedCostCo2e;
    bool isKnown(FillCandidate c) =>
        c.metrics.of(objective).isKnown &&
        (!balanced || c.metrics.co2eKgPerKm.isKnown);
    final known = candidates.where(isKnown).toList()
      ..sort((a, b) {
        final va = a.metrics.of(objective).value!;
        final vb = b.metrics.of(objective).value!;
        final by = higher ? vb.compareTo(va) : va.compareTo(vb);
        return by != 0 ? by : a.grade.index.compareTo(b.grade.index);
      });
    final unknown = candidates.where((c) => !isKnown(c)).toList()
      ..sort((a, b) => a.grade.index.compareTo(b.grade.index));
    final ordered = [...known, ...unknown];
    final confidence = known.isEmpty
        ? DecisionConfidence.low
        : known
            .map((c) => c.basis == ExpectationBasis.interpolated
                ? DecisionConfidence.values[math.min(
                    NextFillCandidates.confidenceOf(c.metricBasis).index,
                    DecisionConfidence.medium.index)]
                : NextFillCandidates.confidenceOf(c.metricBasis))
            .reduce((a, b) => a.index <= b.index ? a : b);
    ({
      NextFillOutcome outcome,
      List<FillCandidate> ordered,
      List<DecisionReason> reasons,
      DecisionConfidence confidence,
    }) done(NextFillOutcome o, List<DecisionReason> r) =>
        (outcome: o, ordered: ordered, reasons: r, confidence: confidence);

    final partial = [
      if (unknown.isNotEmpty && known.isNotEmpty)
        DecisionReason.unevaluatedAlternatives,
    ];
    if (candidates.length == 1) {
      return done(known.isEmpty
          ? NextFillOutcome.insufficientEvidence
          : NextFillOutcome.noMaterialAdvantage, [
        DecisionReason.onlyOneCandidate,
        if (known.isEmpty) _missing(candidates, objective),
      ]);
    }
    if (known.length < 2) {
      return done(NextFillOutcome.insufficientEvidence, [
        if (known.isEmpty) _missing(candidates, objective),
        ...partial,
      ]);
    }
    MetricComparison cmp(FillCandidate a, FillCandidate b, BehaviourMetric Function(CandidateMetrics) m,
            {bool higherIsBetter = false}) =>
        compare(m(a.metrics), m(b.metrics),
            higherIsBetter: higherIsBetter, minMaterial: minMaterial);

    if (!balanced) {
      final lead = known.first;
      final results = [
        for (final other in known.skip(1))
          cmp(lead, other, (m) => m.of(objective), higherIsBetter: higher),
      ];
      if (results.every((r) => r == MetricComparison.better)) {
        return done(NextFillOutcome.recommend, partial);
      }
      if (results.contains(MetricComparison.uncertain)) {
        return done(NextFillOutcome.insufficientEvidence,
            [DecisionReason.uncertaintyDominates, ...partial]);
      }
      return done(NextFillOutcome.noMaterialAdvantage,
          [DecisionReason.belowMaterialThreshold, ...partial]);
    }

    // Balanced: a leader must not be worse or uncertain on either axis
    // against anyone, and must be better on at least one against each.
    for (final lead in known) {
      final dominates = known.where((o) => o != lead).every((o) {
        final cost = cmp(lead, o, (m) => m.costPerKm);
        final co2 = cmp(lead, o, (m) => m.co2eKgPerKm);
        final ok = {MetricComparison.better, MetricComparison.same};
        return ok.contains(cost) &&
            ok.contains(co2) &&
            (cost == MetricComparison.better || co2 == MetricComparison.better);
      });
      if (dominates) {
        final reordered = [lead, ...ordered.where((c) => c != lead)];
        return (
          outcome: NextFillOutcome.recommend,
          ordered: reordered,
          reasons: partial,
          confidence: confidence,
        );
      }
    }
    var anyUncertain = false;
    for (final a in known) {
      for (final b in known) {
        if (a == b) continue;
        final cost = cmp(a, b, (m) => m.costPerKm);
        final co2 = cmp(a, b, (m) => m.co2eKgPerKm);
        if (cost == MetricComparison.better && co2 == MetricComparison.worse) {
          return done(NextFillOutcome.tradeOff, partial);
        }
        anyUncertain = anyUncertain ||
            cost == MetricComparison.uncertain ||
            co2 == MetricComparison.uncertain;
      }
    }
    return anyUncertain
        ? done(NextFillOutcome.insufficientEvidence,
            [DecisionReason.uncertaintyDominates, ...partial])
        : done(NextFillOutcome.noMaterialAdvantage,
            [DecisionReason.belowMaterialThreshold, ...partial]);
  }

  /// Why no candidate has the objective's metric: the first candidate's
  /// own reason, since every candidate shares the tank and the profile.
  static DecisionReason _missing(
      List<FillCandidate> candidates, FillObjective objective) {
    final metric = candidates.first.metrics.of(objective);
    if (candidates.first.basis == ExpectationBasis.none) {
      return DecisionReason.noBehaviourEvidence;
    }
    return switch (metric.insufficientReason) {
      InsufficientReason.capacityUnknown => DecisionReason.capacityUnknown,
      InsufficientReason.noCo2eFactor ||
      InsufficientReason.contextNotPure =>
        DecisionReason.noCo2eFactor,
      _ => objective == FillObjective.balancedCostCo2e
          ? DecisionReason.noCo2eFactor
          : DecisionReason.noBehaviourEvidence,
    };
  }
}
