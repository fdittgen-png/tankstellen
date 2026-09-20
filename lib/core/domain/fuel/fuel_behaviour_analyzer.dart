// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../consumption_estimate.dart';
import 'behaviour_metric.dart';
import 'blend_timeline.dart';
import 'fuel_behaviour_evidence.dart';
import 'fuel_behaviour_profile.dart';
import 'fuel_context.dart';
import 'tank_blend_state.dart';

/// Full-to-full windows a context needs before its pump figures count.
/// Same bar as ADR 0015's `kMinAttributedIntervalsForVerdict`: one window
/// is a data point, two start to show a spread.
const int kMinReferenceWindows = 2;

/// Trips a context needs before a trip-based L/100 km is a number. Five,
/// because a weighted spread over fewer is dominated by one drive.
const int kMinTripSamples = 5;

/// Recorded distance a context needs before a trip-based L/100 km is a
/// number. 50 km sits just above `PumpGainLearner.minRecordedKm` (40 km),
/// the smallest distance production already trusts to calibrate a grade.
const double kMinTripDistanceKm = 50;

/// Trips with an expected figure a context needs before it is compared on
/// residuals — the same five / 50 km bar as raw trips, so residual control
/// never rests on less evidence than the figure it corrects.
const int kMinResidualSamples = kMinTripSamples;

/// See [kMinResidualSamples].
const double kMinResidualDistanceKm = kMinTripDistanceKm;

/// Share of a context's trip distance whose FULL confounding-condition
/// context must have been evaluated before a CONDITION-ADJUSTED figure
/// may be claimed (#4364).
///
/// Four fifths, not all of it: a handful of unevaluated kilometres does
/// not invalidate the control, and demanding perfection would make the
/// metric unreachable forever. Below it the analyzer reports the
/// uncontrolled observation and says the adjustment is unavailable
/// rather than implying hills and traffic were accounted for.
const double kMinConditionCoverage = 0.8;

/// Share of a context's trip distance that must carry an
/// expected-consumption figure before residuals may be presented as an
/// adjustment. Same bar, same reason (#4364).
const double kMinResidualCoverage = kMinConditionCoverage;

/// Learns a [FuelBehaviourProfile] from canonical evidence (#4276).
///
/// ## No competing estimator
///
/// Nothing here computes a litre from telemetry. Trips contribute the
/// canonical figure the pipeline stamped (a `ConsumptionEstimate`'s
/// value, source class and versions); windows contribute
/// pump litres over odometer distance. The analyzer only groups, weights
/// and averages.
///
/// ## Attribution
///
/// Each trip is attributed to the blend the tank held when it started
/// ([BlendTimeline.contextAt]); each window to the blend(s) it burned
/// ([BlendTimeline.contextOverWindow]). Evidence in the unknown context is
/// counted and never learned from. Every metric of a context reads only
/// that context's evidence — the isolation guarantee — except
/// [FuelBehaviourProfile.typicalExpectedLPer100Km], which is the
/// conditions baseline (roads and weather, not fuel) and is shared on
/// purpose so every context is expressed under the same conditions.
///
/// ## Confounders
///
/// Contexts are compared on observed ÷ expected (#4206's residual), so a
/// hill-heavy set of E85 drives is judged against the hills it climbed.
/// Without enough expected figures a context falls back to absolute
/// figures and says so ([ConfounderControl.uncontrolled]).
///
/// Deterministic: evidence is de-duplicated by id and folded in canonical
/// order, so the profile is identical for any delivery order.
abstract final class FuelBehaviourAnalyzer {
  static FuelBehaviourProfile analyze({
    required BlendTimeline timeline,
    required Iterable<TripFuelEvidence> trips,
    required Iterable<FillWindowEvidence> windows,
    double? tankCapacityLitres,
    Co2eFactorLookup co2eFactors = noCo2eFactor,
  }) {
    final buckets = <FuelContext, _Bucket>{};
    final unattributed = <EvidenceTier, int>{};
    final versions = <ConsumptionModelVersion>[];
    var unversioned = 0;
    _Bucket bucket(FuelContext c) => buckets.putIfAbsent(c, _Bucket.new);
    void bump<K>(Map<K, int> m, K k) => m[k] = (m[k] ?? 0) + 1;

    for (final trip in _unique(trips, (t) => t.id, (t) => t.at)) {
      final tier = trip.tier;
      final version = trip.version;
      if (version == null) {
        unversioned++;
      } else {
        versions.add(version);
      }
      final context = timeline.contextAt(trip.at);
      if (context.kind == FuelContextKind.unknown) {
        bump(unattributed, tier);
        continue;
      }
      final b = bucket(context);
      bump(b.provenance, tier);
      final calibration = trip.calibrationGrade;
      if (tier == EvidenceTier.unknown) {
        bump(b.exclusions, EvidenceExclusion.noFigure);
      } else if (tier == EvidenceTier.estimated &&
          calibration != null &&
          !context.grades.contains(calibration)) {
        bump(b.exclusions, EvidenceExclusion.crossCalibrated);
      } else {
        b.trips.add(trip);
      }
    }
    for (final w in _unique(windows, (w) => w.id, (w) => w.closedAt)) {
      final context = timeline.contextOverWindow(w.openedAt, w.closedAt);
      if (context.kind == FuelContextKind.unknown) {
        bump(unattributed, EvidenceTier.reference);
        continue;
      }
      final b = bucket(context);
      bump(b.provenance, EvidenceTier.reference);
      b.windows.add(w);
    }

    final typical = _mean(
      [
        for (final b in buckets.values)
          for (final t in b.trips)
            if (t.expectedLPer100Km case final double e) (e, t.distanceKm),
      ],
      kMinResidualSamples,
      kMinResidualDistanceKm,
      MetricBasis.derived,
    );
    return FuelBehaviourProfile(
      contexts: {
        for (final e in buckets.entries)
          e.key: _learn(e.key, e.value, typical, tankCapacityLitres, co2eFactors),
      },
      typicalExpectedLPer100Km: typical,
      unattributed: unattributed,
      consumptionVersions: versions,
      unversionedTrips: unversioned,
      blendModelVersion: TankBlendState.currentModelVersion,
      tankCapacityLitres: tankCapacityLitres,
    );
  }

  static FuelContextBehaviour _learn(FuelContext context, _Bucket b,
      BehaviourMetric typical, double? capacity, Co2eFactorLookup factors) {
    List<(double, double)> figures(bool Function(TripFuelEvidence) keep) => [
          for (final t in b.trips)
            if (keep(t)) (t.litresPer100Km.valueOrNull!, t.distanceKm),
        ];
    List<(double, double)> residuals(bool Function(TripFuelEvidence) keep) => [
          for (final t in b.trips)
            if (keep(t) && t.residualRatio != null)
              (t.residualRatio!, t.distanceKm),
        ];
    bool measured(TripFuelEvidence t) => t.tier == EvidenceTier.measured;
    bool any(TripFuelEvidence t) => true;

    final lPer100Km = _firstKnown([
      _mean([for (final w in b.windows) (w.lPer100Km, w.distanceKm)],
          kMinReferenceWindows, 0, MetricBasis.referenceWindows),
      _mean(figures(measured), kMinTripSamples, kMinTripDistanceKm,
          MetricBasis.measuredTrips),
      _mean(figures(any), kMinTripSamples, kMinTripDistanceKm,
          MetricBasis.estimatedTrips),
    ]);
    final residualRatio = _firstKnown([
      _mean(residuals(measured), kMinResidualSamples, kMinResidualDistanceKm,
          MetricBasis.measuredResiduals),
      _mean(residuals(any), kMinResidualSamples, kMinResidualDistanceKm,
          MetricBasis.estimatedResiduals),
    ]);
    // #4364 — money never crosses a denomination. Windows priced in two
    // currencies produce no €/km at all; the caller shows the native
    // figures side by side.
    final priced = [for (final w in b.windows) if (w.pumpedCost != null) w];
    final currencies = {for (final w in priced) w.costCurrency};
    final costCurrency = currencies.length == 1 ? currencies.first : null;
    final costPerKm = currencies.length > 1
        ? const BehaviourMetric.insufficient(InsufficientReason.mixedCurrencies)
        : _mean([
            for (final w in priced) (w.pumpedCost! / w.distanceKm, w.distanceKm),
          ], kMinReferenceWindows, 0, MetricBasis.referenceWindows);

    final grade = context.pureGrade;
    final factor = grade == null ? null : factors(grade);
    final tripKm = b.trips.fold(0.0, (s, t) => s + t.distanceKm);
    double share(bool Function(TripFuelEvidence) keep) => tripKm <= 0
        ? 0
        : b.trips.where(keep).fold(0.0, (s, t) => s + t.distanceKm) / tripKm;
    final residualCoverage = share((t) => t.expectedLPer100Km != null);
    final conditionCoverage = share((t) => t.hasFullConditionContext);
    return FuelContextBehaviour(
      context: context,
      lPer100Km: lPer100Km,
      residualRatio: residualRatio,
      conditionAdjustedLPer100Km: _adjusted(
          residualRatio, typical, residualCoverage, conditionCoverage),
      costPerKm: costPerKm,
      costPer100Km: costPerKm.scaled(100),
      rangeKm: capacity == null
          ? const BehaviourMetric.insufficient(
              InsufficientReason.capacityUnknown)
          : lPer100Km.reciprocal(capacity * 100),
      co2eKgPerKm: grade == null
          ? const BehaviourMetric.insufficient(
              InsufficientReason.contextNotPure)
          : factor == null
              ? const BehaviourMetric.insufficient(
                  InsufficientReason.noCo2eFactor)
              : lPer100Km.scaled(factor.kgCo2ePerLitre / 100),
      co2eFactor: factor,
      provenance: b.provenance,
      exclusions: b.exclusions,
      tripDistanceKm: tripKm,
      windowDistanceKm: b.windows.fold(0.0, (s, w) => s + w.distanceKm),
      residualCoverage: residualCoverage,
      conditionCoverage: conditionCoverage,
      costCurrency: costPerKm.isKnown ? costCurrency : null,
      conditionShares: {
        for (final c in DrivingCondition.values)
          if (share((t) => t.conditions.contains(c)) case final double s
              when s > 0)
            c: s,
      },
    );
  }

  /// The CONDITION-ADJUSTED figure, or the precise reason there is none
  /// (#4364).
  ///
  /// "Adjusted" asserts that hills, cold starts and traffic were
  /// accounted for. That assertion needs two things the residual alone
  /// does not prove: expected-consumption inputs over most of the
  /// distance, and a producer that actually evaluated every condition.
  /// Missing either, the observation stands and the adjustment does not
  /// — an unqualified adjusted claim on partial evidence is how a
  /// heavier car driven up a hill becomes "worse driving".
  static BehaviourMetric _adjusted(BehaviourMetric residualRatio,
      BehaviourMetric typical, double residualCoverage, double conditionCoverage) {
    final combined = residualRatio.times(typical);
    if (!combined.isKnown) return combined;
    if (residualCoverage < kMinResidualCoverage ||
        conditionCoverage < kMinConditionCoverage) {
      return BehaviourMetric.insufficient(
          InsufficientReason.incompleteConditionCoverage,
          sampleCount: combined.sampleCount);
    }
    return combined;
  }

  /// A weighted mean, or the precise reason it is not one.
  static BehaviourMetric _mean(List<(double, double)> samples, int minN,
      double minWeight, MetricBasis basis) {
    if (samples.isEmpty) {
      return const BehaviourMetric.insufficient(InsufficientReason.noEvidence);
    }
    if (samples.length < minN) {
      return BehaviourMetric.insufficient(InsufficientReason.tooFewSamples,
          sampleCount: samples.length);
    }
    if (samples.fold(0.0, (s, e) => s + e.$2) < minWeight) {
      return BehaviourMetric.insufficient(InsufficientReason.tooLittleDistance,
          sampleCount: samples.length);
    }
    return BehaviourMetric.weightedMean(samples, basis);
  }

  /// The strongest known metric; else the strongest attempt that had any
  /// evidence (its reason is the informative one); else "no evidence".
  static BehaviourMetric _firstKnown(List<BehaviourMetric> ranked) =>
      ranked.firstWhere((m) => m.isKnown,
          orElse: () => ranked.firstWhere(
              (m) => m.insufficientReason != InsufficientReason.noEvidence,
              orElse: () => ranked.first));

  /// De-duplicated by id (first in canonical order), in (time, id) order.
  static List<T> _unique<T>(Iterable<T> items, String Function(T) id,
      DateTime Function(T) at) {
    final sorted = items.toList()
      ..sort((a, b) {
        final byTime = at(a).compareTo(at(b));
        return byTime != 0 ? byTime : id(a).compareTo(id(b));
      });
    final seen = <String>{};
    return [for (final item in sorted) if (seen.add(id(item))) item];
  }
}

final class _Bucket {
  final trips = <TripFuelEvidence>[];
  final windows = <FillWindowEvidence>[];
  final provenance = <EvidenceTier, int>{};
  final exclusions = <EvidenceExclusion, int>{};
}
