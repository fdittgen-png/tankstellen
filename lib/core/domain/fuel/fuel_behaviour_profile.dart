// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:meta/meta.dart';

import '../consumption_estimate.dart';
import 'behaviour_metric.dart';
import 'fuel_behaviour_evidence.dart';
import 'fuel_context.dart';

/// How far a context's consumption figures are protected from hills, cold
/// starts, traffic and driving style (#4276).
enum ConfounderControl {
  /// Enough trips carry an expected figure: the context is judged on
  /// observed ÷ expected, so conditions cancel.
  residuals,

  /// Only fill windows (or raw trips) are sufficient. The figure is true
  /// for what was driven, but a hilly winter on E85 will look like E85.
  /// Lower-confidence evidence, stated as such.
  uncontrolled,

  /// Nothing sufficient to judge at all.
  none,
}

/// Why a piece of evidence was left out of a context.
enum EvidenceExclusion {
  /// No usable figure ([EvidenceTier.unknown]).
  noFigure,

  /// An estimate calibrated under another grade's pump gain.
  crossCalibrated,
}

/// Everything learned about one [FuelContext] (#4276). Every figure is a
/// [BehaviourMetric]: a value with its interval, or insufficient with the
/// reason.
@immutable
final class FuelContextBehaviour {
  FuelContextBehaviour({
    required this.context,
    required this.lPer100Km,
    required this.residualRatio,
    required this.conditionAdjustedLPer100Km,
    required this.costPerKm,
    required this.costPer100Km,
    required this.rangeKm,
    required this.co2eKgPerKm,
    required this.co2eFactor,
    required Map<EvidenceTier, int> provenance,
    required Map<EvidenceExclusion, int> exclusions,
    required this.tripDistanceKm,
    required this.windowDistanceKm,
    required this.residualCoverage,
    required Map<DrivingCondition, double> conditionShares,
  })  : provenance = Map.unmodifiable(provenance),
        exclusions = Map.unmodifiable(exclusions),
        conditionShares = Map.unmodifiable(conditionShares);

  final FuelContext context;

  /// Absolute consumption: reference windows when there are enough, else
  /// measured trips, else trips including estimates. NOT condition
  /// controlled — see [conditionAdjustedLPer100Km] for comparisons.
  final BehaviourMetric lPer100Km;

  /// Distance-weighted mean of observed ÷ expected: how this context
  /// burns relative to what the conditions predict. The quantity contexts
  /// are compared on.
  final BehaviourMetric residualRatio;

  /// [residualRatio] × the vehicle's typical expected consumption: this
  /// context's L/100 km under the conditions the car usually drives in.
  final BehaviourMetric conditionAdjustedLPer100Km;

  /// From the prices actually paid over reference windows.
  final BehaviourMetric costPerKm;
  final BehaviourMetric costPer100Km;

  /// Tank capacity ÷ [lPer100Km] — only when the capacity is known.
  final BehaviourMetric rangeKm;

  /// [lPer100Km] × the pure grade's versioned factor; never estimated for
  /// a mixed or unknown context or without a factor.
  final BehaviourMetric co2eKgPerKm;

  /// The factor [co2eKgPerKm] used, with its source and version.
  final Co2eFactor? co2eFactor;

  /// How many attributed trips/windows sat in each evidence tier.
  final Map<EvidenceTier, int> provenance;
  final Map<EvidenceExclusion, int> exclusions;
  final double tripDistanceKm;
  final double windowDistanceKm;

  /// Share of this context's trip distance that carries an expected
  /// figure — how much of it the residual comparison can speak for.
  final double residualCoverage;

  /// Share of trip distance driven under each confounding condition.
  final Map<DrivingCondition, double> conditionShares;

  /// Whether the comparison figures are condition controlled.
  ConfounderControl get confounderControl {
    if (residualRatio.isKnown) return ConfounderControl.residuals;
    if (lPer100Km.isKnown) return ConfounderControl.uncontrolled;
    return ConfounderControl.none;
  }

  Map<String, Object?> toJson() => {
        'context': context.key,
        'lPer100Km': lPer100Km.toJson(),
        'residualRatio': residualRatio.toJson(),
        'conditionAdjustedLPer100Km': conditionAdjustedLPer100Km.toJson(),
        'costPerKm': costPerKm.toJson(),
        'costPer100Km': costPer100Km.toJson(),
        'rangeKm': rangeKm.toJson(),
        'co2eKgPerKm': co2eKgPerKm.toJson(),
        'co2eFactor': co2eFactor?.toJson(),
        'provenance': {
          for (final t in EvidenceTier.values)
            if (provenance[t] case final int n) t.name: n,
        },
        'exclusions': {
          for (final e in EvidenceExclusion.values)
            if (exclusions[e] case final int n) e.name: n,
        },
        'tripDistanceKm': tripDistanceKm,
        'windowDistanceKm': windowDistanceKm,
        'residualCoverage': residualCoverage,
        'conditionShares': {
          for (final c in DrivingCondition.values)
            if (conditionShares[c] case final double s) c.name: s,
        },
        'confounderControl': confounderControl.name,
      };
}

/// On what a comparison of two contexts rests.
enum ComparisonBasis { residuals, uncontrolled, insufficient }

/// `a` relative to `b`: the ratio of their consumption, with the interval.
@immutable
final class FuelContextComparison {
  const FuelContextComparison({
    required this.a,
    required this.b,
    required this.ratio,
    required this.basis,
  });

  final FuelContext a;
  final FuelContext b;

  /// L/100 km of [a] ÷ that of [b] (1.3 = [a] burns 30 % more).
  final BehaviourMetric ratio;
  final ComparisonBasis basis;

  /// Whether the 95 % interval excludes "no difference". Null when there
  /// is no ratio.
  bool? get isMaterial => !ratio.isKnown
      ? null
      : ratio.lower! > 1 || ratio.upper! < 1;
}

/// How THIS vehicle behaves per fuel context (#4276) — the reusable
/// result the UI (#4278) and the next-fill decision (#4277) read without
/// recomputing anything.
@immutable
final class FuelBehaviourProfile {
  FuelBehaviourProfile({
    required Map<FuelContext, FuelContextBehaviour> contexts,
    required this.typicalExpectedLPer100Km,
    required Map<EvidenceTier, int> unattributed,
    required Iterable<ConsumptionModelVersion> consumptionVersions,
    required this.blendModelVersion,
    this.unversionedTrips = 0,
    this.tankCapacityLitres,
  })  : contexts = Map.unmodifiable(
            Map.fromEntries(contexts.entries.toList()
              ..sort((x, y) => x.key.compareTo(y.key)))),
        unattributed = Map.unmodifiable(unattributed),
        consumptionVersions = List.unmodifiable(
            consumptionVersions.toSet().toList()
              ..sort((x, y) => x.toString().compareTo(y.toString())));

  /// The profile's own algorithm version. Bump when a threshold, the
  /// attribution rule or a metric formula changes, so a persisted or
  /// replayed profile is recognisably from another model.
  static const int currentModelVersion = 1;
  int get modelVersion => currentModelVersion;

  /// Learned contexts, in [FuelContext.key] order. The unknown context is
  /// never learned — its evidence is counted in [unattributed].
  final Map<FuelContext, FuelContextBehaviour> contexts;

  /// Distance-weighted expected consumption over every attributed trip
  /// that carries one — the conditions the car usually drives in. Shared
  /// by design: it describes roads and weather, not fuel.
  final BehaviourMetric typicalExpectedLPer100Km;

  /// Evidence whose blend could not be classified, by tier.
  final Map<EvidenceTier, int> unattributed;

  /// Every consumption model version the evidence was produced under.
  final List<ConsumptionModelVersion> consumptionVersions;

  /// Trips whose figure predates consumption versioning.
  final int unversionedTrips;

  /// The tank blend model the attribution replayed.
  final int blendModelVersion;
  final double? tankCapacityLitres;

  FuelContextBehaviour? behaviourOf(FuelContext context) => contexts[context];

  /// [a] against [b], condition-controlled when both have residuals, else
  /// on absolute L/100 km marked [ComparisonBasis.uncontrolled].
  FuelContextComparison compare(FuelContext a, FuelContext b) {
    final ba = contexts[a], bb = contexts[b];
    if (ba == null || bb == null) {
      return FuelContextComparison(
          a: a,
          b: b,
          ratio: const BehaviourMetric.insufficient(
              InsufficientReason.noEvidence),
          basis: ComparisonBasis.insufficient);
    }
    if (ba.residualRatio.isKnown && bb.residualRatio.isKnown) {
      return FuelContextComparison(
          a: a,
          b: b,
          ratio: ba.residualRatio.over(bb.residualRatio),
          basis: ComparisonBasis.residuals);
    }
    final ratio = ba.lPer100Km.over(bb.lPer100Km);
    return FuelContextComparison(
        a: a,
        b: b,
        ratio: ratio,
        basis: ratio.isKnown
            ? ComparisonBasis.uncontrolled
            : ComparisonBasis.insufficient);
  }

  Map<String, Object?> toJson() => {
        'modelVersion': modelVersion,
        'blendModelVersion': blendModelVersion,
        'consumptionVersions': [
          for (final v in consumptionVersions) v.toJson(),
        ],
        'unversionedTrips': unversionedTrips,
        'tankCapacityLitres': tankCapacityLitres,
        'typicalExpectedLPer100Km': typicalExpectedLPer100Km.toJson(),
        'unattributed': {
          for (final t in EvidenceTier.values)
            if (unattributed[t] case final int n) t.name: n,
        },
        'contexts': [for (final c in contexts.values) c.toJson()],
      };
}
