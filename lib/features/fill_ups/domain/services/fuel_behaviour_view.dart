// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:meta/meta.dart';

import '../../../../core/domain/fuel/behaviour_metric.dart';
import '../../../../core/domain/fuel/fuel_behaviour_profile.dart';
import '../../../../core/domain/fuel/fuel_context.dart';
import '../../../../core/domain/fuel/fuel_grade.dart';
import '../../../../core/domain/fuel/next_fill_candidates.dart';
import '../../../../core/domain/fuel/next_fill_decision.dart';

/// Whether a figure rests on measurement or on an estimate (#4278). The
/// third kind the surface shows — general technical information — never
/// comes from a metric; it is the facts section.
enum ProvenanceKind { measured, estimated }

/// One behaviour figure with the evidence behind it, ready to format.
@immutable
final class MetricView {
  const MetricView._(this.metric, this.basis);

  /// [metric] with its basis resolved: a `derived` figure (range, CO2e,
  /// cost per 100 km) inherits the basis of the consumption it was
  /// computed from, [root], so its label says what it actually rests on.
  factory MetricView.of(BehaviourMetric metric, {BehaviourMetric? root}) {
    final own = metric.basis;
    return MetricView._(
      metric,
      own == MetricBasis.derived ? root?.basis ?? own : own,
    );
  }

  /// [metric] credited to an explicit [basis] (a candidate's weakest
  /// evidence); an insufficient metric keeps no basis.
  factory MetricView.resolved(BehaviourMetric metric, MetricBasis? basis) =>
      MetricView._(metric, metric.isKnown ? basis : null);

  final BehaviourMetric metric;
  final MetricBasis? basis;

  bool get isKnown => metric.isKnown;

  /// Null for an insufficient metric, and for a basis with no measurement
  /// behind it at all.
  ProvenanceKind? get provenance => switch (basis) {
        MetricBasis.referenceWindows ||
        MetricBasis.measuredTrips ||
        MetricBasis.measuredResiduals =>
          ProvenanceKind.measured,
        MetricBasis.estimatedTrips ||
        MetricBasis.estimatedResiduals =>
          ProvenanceKind.estimated,
        MetricBasis.derived || null => null,
      };

  /// How far the figure may be trusted — the decision's own scale.
  DecisionConfidence? get confidence =>
      isKnown ? NextFillCandidates.confidenceOf(basis) : null;

  /// The 95 % interval ends, low first, or null when unknown.
  (double, double)? get interval {
    final lo = metric.lower, hi = metric.upper;
    return lo == null || hi == null ? null : (lo, hi);
  }
}

/// What THIS vehicle showed in one fuel context (#4278).
@immutable
final class ContextBehaviourView {
  const ContextBehaviourView._({
    required this.context,
    required this.lPer100Km,
    required this.costPerKm,
    required this.rangeKm,
    required this.co2eKgPerKm,
    required this.confounderControl,
    required this.evidenceCount,
  });

  factory ContextBehaviourView.of(FuelContextBehaviour b) {
    final root = b.lPer100Km;
    return ContextBehaviourView._(
      context: b.context,
      lPer100Km: MetricView.of(root),
      costPerKm: MetricView.of(b.costPerKm, root: root),
      rangeKm: MetricView.of(b.rangeKm, root: root),
      co2eKgPerKm: MetricView.of(b.co2eKgPerKm, root: root),
      confounderControl: b.confounderControl,
      evidenceCount: b.provenance.values.fold(0, (a, n) => a + n),
    );
  }

  /// A grade the vehicle is approved for but never learned on.
  factory ContextBehaviourView.unlearned(FuelGrade grade) {
    const none = BehaviourMetric.insufficient(InsufficientReason.noEvidence);
    return ContextBehaviourView._(
      context: FuelContext.pure(grade),
      lPer100Km: MetricView.of(none),
      costPerKm: MetricView.of(none),
      rangeKm: MetricView.of(none),
      co2eKgPerKm: MetricView.of(none),
      confounderControl: ConfounderControl.none,
      evidenceCount: 0,
    );
  }

  final FuelContext context;
  final MetricView lPer100Km;
  final MetricView costPerKm;
  final MetricView rangeKm;
  final MetricView co2eKgPerKm;
  final ConfounderControl confounderControl;

  /// Trips and fill windows attributed to this context, of any tier.
  final int evidenceCount;

  bool get hasAnyFigure =>
      lPer100Km.isKnown || costPerKm.isKnown || rangeKm.isKnown;
}

/// [a] against [b] on consumption, as the profile compares them.
@immutable
final class GradeComparisonView {
  const GradeComparisonView({
    required this.a,
    required this.b,
    required this.basis,
    required this.percentDifference,
    required this.isMaterial,
    required this.sampleCount,
  });

  factory GradeComparisonView.of(
      FuelBehaviourProfile profile, FuelGrade a, FuelGrade b) {
    final c = profile.compare(FuelContext.pure(a), FuelContext.pure(b));
    final ratio = c.ratio.value;
    return GradeComparisonView(
      a: a,
      b: b,
      basis: c.basis,
      percentDifference: ratio == null ? null : ((ratio - 1) * 100).round(),
      isMaterial: c.isMaterial,
      sampleCount: c.ratio.sampleCount,
    );
  }

  final FuelGrade a;
  final FuelGrade b;
  final ComparisonBasis basis;

  /// How much more (positive) or less (negative) [a] burns than [b], in
  /// whole percent; null when there is no ratio.
  final int? percentDifference;

  /// Whether the interval excludes "no difference"; null without a ratio.
  final bool? isMaterial;
  final int sampleCount;
}

/// The behaviour rows and comparisons of a profile, for the approved
/// grades (#4278). Pure contexts first in grade order, then mixed ones;
/// an approved grade with nothing learned still gets a row, so "not
/// enough evidence yet" is said rather than implied by absence.
({List<ContextBehaviourView> rows, List<GradeComparisonView> comparisons})
    behaviourViewsOf(
  FuelBehaviourProfile profile, {
  required Iterable<FuelGrade> approvedGrades,
  required FuelGrade? configuredGrade,
}) {
  final learned = profile.contexts.values.toList();
  final pureLearned = {
    for (final b in learned)
      if (b.context.pureGrade case final FuelGrade g) g: b,
  };
  final pureGrades = {...pureLearned.keys, ...approvedGrades}.toList()
    ..sort((x, y) => x.index.compareTo(y.index));
  final rows = [
    for (final g in pureGrades)
      pureLearned[g] == null
          ? ContextBehaviourView.unlearned(g)
          : ContextBehaviourView.of(pureLearned[g]!),
    for (final b in learned)
      if (b.context.kind == FuelContextKind.mixed) ContextBehaviourView.of(b),
  ];
  // Every learned pure grade against the reference: the configured grade
  // when it is learned, else the first learned one.
  final reference = pureLearned.containsKey(configuredGrade)
      ? configuredGrade
      : (pureLearned.keys.toList()..sort((x, y) => x.index.compareTo(y.index)))
          .firstOrNull;
  final comparisons = [
    if (reference != null)
      for (final g in pureGrades)
        if (g != reference && pureLearned.containsKey(g))
          GradeComparisonView.of(profile, g, reference),
  ];
  return (rows: rows, comparisons: comparisons);
}
