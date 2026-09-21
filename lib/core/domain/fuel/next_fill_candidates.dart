// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:math' as math;

import '../refuel_economics.dart';
import 'behaviour_metric.dart';
import 'fuel_behaviour_profile.dart';
import 'fuel_context.dart';
import 'fuel_grade.dart';
import 'next_fill_decision.dart';
import 'next_fill_request.dart';
import 'tank_blend_engine.dart';
import 'tank_blend_event.dart';
import 'tank_blend_snapshot.dart';

/// A hypothetical fill's instant. The engine orders a log by time but
/// `apply` does not read it, and a hypothetical snapshot is never
/// persisted — so a fixed instant keeps the decision free of any clock.
final DateTime kHypotheticalFillInstant = DateTime.utc(2000);

/// One candidate's expected consumption, before prices (#4277).
typedef CandidateExpectation = ({
  BehaviourMetric lPer100Km,
  ExpectationBasis basis,
  MetricBasis? evidenceBasis,
});

/// Evaluates candidate fills against a [FuelBehaviourProfile] (#4277).
///
/// Pure arithmetic over learned behaviour: the resulting blend comes from
/// the #4275 engine, consumption from the profile, cost from the prices
/// through [RefuelEconomics]. Nothing here learns or estimates a litre.
final class NextFillCandidates {
  NextFillCandidates({required this.tank, required this.profile})
      : engine = TankBlendEngine(tankCapacityLitres: tank.tankCapacityLitres);

  final TankBlendSnapshot tank;
  final FuelBehaviourProfile profile;
  final TankBlendEngine engine;

  /// The blend after [litres] of [grade] enter [tank] — no level reading,
  /// so an uncertain residual lands in the unknown share.
  TankBlendSnapshot resultingBlend(FuelGrade grade, double litres) =>
      engine.apply(
          tank,
          TankFillEvent(
            id: 'next-fill:${grade.key}',
            at: kHypotheticalFillInstant,
            grade: grade,
            litres: litres,
          ));

  /// Expected L/100 km for [blend], condition-adjusted when [adjusted].
  ///
  /// A pure context reads its own behaviour. A mixed context is expressed
  /// through its guaranteed shares of the two learned pure grades when
  /// both are known — the candidate's shares are specific, the mixed
  /// bucket averages whatever mixes were driven — with the unattributed
  /// slack spanning the pure grades' interval; else the mixed bucket's own
  /// learned figure. Nothing learned → unknown.
  CandidateExpectation expectation(TankBlendSnapshot blend, {required bool adjusted}) {
    BehaviourMetric pick(FuelContextBehaviour b) =>
        adjusted ? b.conditionAdjustedLPer100Km : b.lPer100Km;
    MetricBasis? basisOf(FuelContextBehaviour b) =>
        adjusted ? b.residualRatio.basis : b.lPer100Km.basis;
    const none = (
      lPer100Km: BehaviourMetric.insufficient(InsufficientReason.noEvidence),
      basis: ExpectationBasis.none,
      evidenceBasis: null,
    );
    final context = FuelContext.classify(blend);
    if (context.kind == FuelContextKind.unknown) return none;
    if (context.kind == FuelContextKind.mixed) {
      final pure = {
        for (final g in context.grades)
          g: profile.behaviourOf(FuelContext.pure(g)),
      };
      if (pure.values.every((b) => b != null && pick(b).isKnown)) {
        return (
          lPer100Km: _interpolate(blend, {
            for (final e in pure.entries) e.key: pick(e.value!),
          }),
          basis: ExpectationBasis.interpolated,
          evidenceBasis: _weakest([for (final b in pure.values) basisOf(b!)]),
        );
      }
    }
    final own = profile.behaviourOf(context);
    if (own == null || !pick(own).isKnown) return none;
    return (
      lPer100Km: pick(own),
      basis: ExpectationBasis.learned,
      evidenceBasis: basisOf(own),
    );
  }

  /// Pump price, or the effective price with the detour when the offer
  /// names a station and the current tank's consumption is known.
  ({double price, DecisionReason? reason}) effectivePrice(
      FuelOffer offer, double litres) {
    final station = offer.station;
    if (station == null) return (price: offer.pricePerLitre, reason: null);
    final current = profile
        .behaviourOf(FuelContext.classify(tank))
        ?.lPer100Km
        .value;
    final candidate = RefuelCandidate(
      stationId: station.stationId,
      oneWayKm: station.oneWayKm,
      pricePerLitre: offer.pricePerLitre,
      isRoadDistance: station.isRoadDistance,
      openState: station.openState,
      priceAge: station.priceAge,
    );
    final quote = RefuelQuote(
      candidate: candidate,
      cost: RefuelEconomics.cost(candidate,
          RefuelProfile(consumptionLPer100km: current, litresIntended: litres)),
    );
    final effective = quote.effectivePricePerLitre;
    return effective == null
        ? (price: offer.pricePerLitre, reason: DecisionReason.detourNotPriced)
        : (price: effective, reason: DecisionReason.detourIncluded);
  }

  /// The full metrics for one offer, given its [expected] consumption.
  FillCandidate evaluate(FuelOffer offer, double litres,
      TankBlendSnapshot blend, CandidateExpectation expected) {
    final context = FuelContext.classify(blend);
    final price = effectivePrice(offer, litres);
    final l = expected.lPer100Km;
    final factor = context.pureGrade == null
        ? null
        : profile.behaviourOf(context)?.co2eFactor;
    final capacity = tank.tankCapacityLitres;
    final reasons = <DecisionReason>[
      if (price.reason case final DecisionReason r) r,
      if (context.kind == FuelContextKind.unknown)
        DecisionReason.resultingBlendUnknown,
      if (expected.basis == ExpectationBasis.none)
        DecisionReason.noBehaviourEvidence,
      if (expected.basis == ExpectationBasis.interpolated)
        DecisionReason.interpolatedFromPureContexts,
      if (factor == null) DecisionReason.noCo2eFactor,
      if (capacity == null) DecisionReason.capacityUnknown,
    ];
    return FillCandidate(
      grade: offer.grade,
      pricePerLitre: offer.pricePerLitre,
      effectivePricePerLitre: price.price,
      fillLitres: litres,
      resultingBlend: blend,
      resultingContext: context,
      metrics: CandidateMetrics(
        lPer100Km: l,
        costPerKm: l.scaled(price.price / 100),
        co2eKgPerKm: factor == null
            ? BehaviourMetric.insufficient(context.pureGrade == null
                ? InsufficientReason.contextNotPure
                : InsufficientReason.noCo2eFactor)
            : l.scaled(factor.kgCo2ePerLitre / 100),
        rangeKm: capacity == null
            ? const BehaviourMetric.insufficient(
                InsufficientReason.capacityUnknown)
            : l.reciprocal(capacity * 100),
      ),
      basis: expected.basis,
      metricBasis: expected.evidenceBasis,
      reasons: reasons,
    );
  }

  /// Share-weighted pure metrics; the slack (unknown and trace grades)
  /// may be any of them, so it spans their joint interval.
  static BehaviourMetric _interpolate(
      TankBlendSnapshot blend, Map<FuelGrade, BehaviourMetric> pure) {
    var known = 0.0, value = 0.0, lower = 0.0, upper = 0.0, variance = 0.0;
    var lo = double.infinity, hi = double.negativeInfinity;
    var n = 1 << 30;
    for (final e in pure.entries) {
      final s = blend.minimumShare(e.key);
      final m = e.value;
      known += s;
      value += s * m.value!;
      lower += s * m.lower!;
      upper += s * m.upper!;
      variance += math.pow(s * m.standardError!, 2);
      lo = math.min(lo, m.lower!);
      hi = math.max(hi, m.upper!);
      n = math.min(n, m.sampleCount);
    }
    final slack = (1 - known).clamp(0.0, 1.0);
    final point = known > 0 ? value / known : 0.0;
    return BehaviourMetric.known(
      value: value + slack * point,
      standardError: math.sqrt(variance) + slack * (hi - lo) / 2,
      lower: lower + slack * lo,
      upper: upper + slack * hi,
      sampleCount: n,
      basis: MetricBasis.derived,
    );
  }

  /// The weakest evidence basis (see [confidenceOf]).
  static MetricBasis? _weakest(Iterable<MetricBasis?> bases) {
    MetricBasis? weakest;
    for (final b in bases) {
      if (b == null) return null;
      if (weakest == null || confidenceOf(b).index < confidenceOf(weakest).index) {
        weakest = b;
      }
    }
    return weakest;
  }

  /// What an evidence basis supports: residual-controlled measurements are
  /// high; pump windows and raw measurements are true but confounded —
  /// medium; anything resting on estimates is low.
  static DecisionConfidence confidenceOf(MetricBasis? basis) => switch (basis) {
        MetricBasis.measuredResiduals => DecisionConfidence.high,
        MetricBasis.referenceWindows ||
        MetricBasis.measuredTrips =>
          DecisionConfidence.medium,
        _ => DecisionConfidence.low,
      };
}
