// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel/fuel_behaviour_analyzer.dart';
import 'package:tankstellen/core/domain/fuel/fuel_behaviour_evidence.dart';
import 'package:tankstellen/core/domain/fuel/fuel_behaviour_profile.dart';
import 'package:tankstellen/core/domain/fuel/fuel_grade.dart';
import 'package:tankstellen/core/domain/fuel/next_fill_decider.dart';
import 'package:tankstellen/core/domain/fuel/next_fill_decision.dart';
import 'package:tankstellen/core/domain/fuel/next_fill_request.dart';
import 'package:tankstellen/core/domain/fuel/tank_blend_engine.dart';
import 'package:tankstellen/core/domain/fuel/tank_blend_event.dart';
import 'package:tankstellen/core/domain/fuel/tank_blend_snapshot.dart';
import 'package:tankstellen/core/domain/refuel_economics.dart';

import 'fuel_behaviour_fixtures.dart';

/// #4277 — the next-fill decision over SYNTHETIC profiles (E85 set to burn
/// 1.3 × E10). Pins the decision rules; says nothing about real cars.
void main() {
  final flex = VehicleFuelCapability(
      approvedGrades: {FuelGrade.e5, FuelGrade.e10, FuelGrade.e85},
      provenance: 'test');
  final factors = <FuelGrade, Co2eFactor>{
    FuelGrade.e10: Co2eFactor(
        kgCo2ePerLitre: 2.27,
        source: 'test',
        version: 't1',
        boundary: Co2eBoundary.wellToWheel),
    FuelGrade.e85: Co2eFactor(
        kgCo2ePerLitre: 1.40,
        source: 'test',
        version: 't1',
        boundary: Co2eBoundary.wellToWheel),
  };

  /// E10 ×1.0 and E85 ×1.3, ten flat trips each, residual-controlled.
  FuelBehaviourProfile profile({double e85 = 1.3, bool co2 = true}) =>
      FuelBehaviourAnalyzer.analyze(
        timeline: referenceTimeline(),
        trips: [
          ...tripsOn('e10-', 0.5, 10, factor: 1.0),
          ...tripsOn('e85-', 11.5, 10, factor: e85),
        ],
        windows: const [],
        tankCapacityLitres: kCapacity,
        co2eFactors: co2 ? (g) => factors[g] : noCo2eFactor,
      );

  final engine = TankBlendEngine(tankCapacityLitres: kCapacity);

  /// Pinned full of [grades] in turn (half each after the first), then
  /// [burn] litres driven.
  TankBlendSnapshot tank(List<FuelGrade> grades,
      {double burn = 30, TankBlendEngine? using}) {
    final e = using ?? engine;
    final events = <TankBlendEvent>[
      for (var i = 0; i < grades.length; i++)
        fill('t$i', i, grades[i], i == 0 ? kCapacity : kCapacity / 2),
      if (burn > 0) TankConsumptionEvent.exact(id: 'burn', at: day(9), litres: burn),
    ];
    return e.replay(events);
  }

  /// Empty, known pure E85 — but no capacity: a level reading pins it.
  TankBlendSnapshot emptyWithoutCapacity() => TankBlendEngine().replay([
        TankFillEvent(
            id: 'lvl',
            at: day(0),
            grade: FuelGrade.e85,
            litres: 40,
            levelBeforeLitres: 0),
        TankConsumptionEvent.exact(id: 'burn', at: day(1), litres: 40),
      ]);

  NextFillDecision decide(TankBlendSnapshot t, FuelBehaviourProfile p,
          {FillObjective objective = FillObjective.lowestCostPerKm,
          double e10 = 1.80,
          double e85 = 1.10,
          VehicleFuelCapability? capability,
          double? litres = 30,
          TargetBlend? target,
          RefuelCandidate? station}) =>
      NextFillDecider.decide(
        tank: t,
        profile: p,
        request: NextFillRequest(
          objective: objective,
          capability: capability ?? flex,
          offers: [
            FuelOffer(grade: FuelGrade.e10, pricePerLitre: e10, station: station),
            FuelOffer(grade: FuelGrade.e85, pricePerLitre: e85, station: station),
          ],
          expectedFillLitres: litres,
          target: target,
        ),
      );

  group('E10/E85 mixed tank with changing prices', () {
    final mixed = tank([FuelGrade.e85, FuelGrade.e10]); // 20 L at 50/50
    final p = profile();

    test('cheap E85 wins on cost per km — and says what it rests on', () {
      final d = decide(mixed, p);
      expect(d.outcome, NextFillOutcome.recommend);
      expect(d.recommended, FuelGrade.e85);
      final e85 = d.candidates.first;
      expect(e85.resultingBlend.exactShare(FuelGrade.e85), closeTo(0.8, 1e-12));
      expect(e85.basis, ExpectationBasis.interpolated);
      expect(e85.reasons, contains(DecisionReason.interpolatedFromPureContexts));
      expect(e85.metrics.lPer100Km.value, closeTo(0.8 * 7.78 + 0.2 * 5.99, 0.02));
      expect(d.confidence, DecisionConfidence.medium);
    });

    test('a price delta flips the decision while the response stays fixed',
        () {
      final cheap = decide(mixed, p, e85: 1.10);
      final dear = decide(mixed, p, e85: 1.60);
      expect(cheap.recommended, FuelGrade.e85);
      expect(dear.recommended, FuelGrade.e10);
      expect(
          dear.candidates
              .firstWhere((c) => c.grade == FuelGrade.e85)
              .metrics
              .lPer100Km
              .toJson(),
          cheap.candidates.first.metrics.lPer100Km.toJson());
    });

    test('nearly equal cost per km is no material advantage', () {
      // E10 fill ≈ 6.35 L × 1.80; E85 fill ≈ 7.42 L × p → tie near 1.54.
      final d = decide(mixed, p, e85: 1.545);
      expect(d.outcome, NextFillOutcome.noMaterialAdvantage);
      expect(d.recommended, isNull);
      expect(d.reasons, contains(DecisionReason.belowMaterialThreshold));
    });

    test('never on price alone: without E85 evidence nothing is recommended',
        () {
      final e10Only = FuelBehaviourAnalyzer.analyze(
          timeline: referenceTimeline(),
          trips: tripsOn('e10-', 0.5, 10, factor: 1.0),
          windows: const []);
      final d = decide(tank([FuelGrade.e85], burn: 50), e10Only, e85: 0.50);
      expect(d.outcome, NextFillOutcome.insufficientEvidence);
      expect(d.recommended, isNull);
      expect(
          d.candidates.firstWhere((c) => c.grade == FuelGrade.e85).reasons,
          contains(DecisionReason.noBehaviourEvidence));
    });

    test('uncertainty dominating a real-looking gap → insufficient evidence',
        () {
      final noisy = FuelBehaviourAnalyzer.analyze(
        timeline: referenceTimeline(),
        trips: [
          for (var i = 0; i < 5; i++)
            trip('n10-$i', 0.5 + i * 0.5,
                observed: 6 * (i.isEven ? 0.7 : 1.3), expected: 6),
          for (var i = 0; i < 5; i++)
            trip('n85-$i', 11.5 + i * 0.5,
                observed: 7.8 * (i.isEven ? 0.7 : 1.3), expected: 6),
        ],
        windows: const [],
      );
      final d = decide(tank([FuelGrade.e85], burn: 50), noisy,
          litres: 50, e10: 1.80, e85: 1.30);
      expect(d.outcome, NextFillOutcome.insufficientEvidence);
      expect(d.reasons, contains(DecisionReason.uncertaintyDominates));
    });
  });

  group('convergence toward a target blend', () {
    final p = profile();

    test('a mix already near the target needs no fill', () {
      // 41 L E85 topped with 9 L E10 → 82 % E85, within 5 points of 85 %.
      final near = engine.replay([
        fill('a', 0, FuelGrade.e85, 50),
        TankConsumptionEvent.exact(id: 'burn', at: day(1), litres: 9),
        fill('b', 2, FuelGrade.e10, 9),
      ]);
      expect(near.exactShare(FuelGrade.e85), closeTo(0.82, 1e-12));
      final d = decide(near, p, target: TargetBlend(grade: FuelGrade.e85));
      expect(d.convergence!.status, ConvergenceStatus.alreadyAtTarget);
      expect(d.convergence!.fillsNeeded, 0);
      expect(d.convergence!.minimumShareAfterFill, isEmpty);
    });

    test('one fill cannot reach the target; the plan says how many can', () {
      final d = decide(tank([FuelGrade.e10], burn: 30), p,
          target: TargetBlend(grade: FuelGrade.e85));
      final plan = d.convergence!;
      expect(plan.status, ConvergenceStatus.reachable);
      expect(plan.fillsNeeded, 2);
      expect(plan.minimumShareAfterFill[0], closeTo(0.6, 1e-12));
      expect(plan.minimumShareAfterFill[1], closeTo(0.84, 1e-12));
    });

    test('beyond the horizon it is unreachable, never extrapolated', () {
      final d = NextFillDecider.decide(
        tank: tank([FuelGrade.e10], burn: 30),
        profile: p,
        request: NextFillRequest(
          objective: FillObjective.lowestConsumption,
          capability: flex,
          offers: [FuelOffer(grade: FuelGrade.e85, pricePerLitre: 1)],
          expectedFillLitres: 30,
          target: TargetBlend(grade: FuelGrade.e85),
          maxConvergenceFills: 1,
        ),
      );
      expect(d.convergence!.status, ConvergenceStatus.unreachableWithinHorizon);
      expect(d.convergence!.fillsNeeded, isNull);
    });

    test('without a capacity the plan is not computable', () {
      final unbounded = TankBlendEngine();
      final d = decide(tank([FuelGrade.e10], burn: 0, using: unbounded), p,
          target: TargetBlend(grade: FuelGrade.e85));
      expect(d.convergence!.status, ConvergenceStatus.notComputable);
      expect(d.convergence!.reason, DecisionReason.capacityUnknown);
    });
  });

  group('compatibility', () {
    final p = profile();
    final t = tank([FuelGrade.e10], burn: 30);

    test('an unapproved fuel is excluded, however cheap', () {
      final d = decide(t, p,
          e85: 0.10,
          capability: VehicleFuelCapability(
              approvedGrades: {FuelGrade.e10}, provenance: 'test'));
      expect(d.excluded.single.grade, FuelGrade.e85);
      expect(d.excluded.single.reason, DecisionReason.gradeNotApproved);
      expect(d.candidates.map((c) => c.grade), [FuelGrade.e10]);
      expect(d.recommended, isNot(FuelGrade.e85));
      expect(d.reasons, contains(DecisionReason.onlyOneCandidate));
    });

    test('an unknown capability recommends nothing at all', () {
      final d = decide(t, p, capability: const VehicleFuelCapability.unknown());
      expect(d.outcome, NextFillOutcome.compatibilityUnknown);
      expect(d.candidates, isEmpty);
    });

    test('no approved offer → no compatible fuel', () {
      final d = decide(t, p,
          capability: VehicleFuelCapability(
              approvedGrades: {FuelGrade.diesel}, provenance: 'test'));
      expect(d.outcome, NextFillOutcome.noCompatibleFuel);
    });
  });

  group('no factor / no evidence → no unsupported claim', () {
    test('without a CO2e factor the CO2e objective makes no claim', () {
      final d = decide(tank([FuelGrade.e85], burn: 50), profile(co2: false),
          objective: FillObjective.lowestCo2ePerKm, litres: 50);
      expect(d.outcome, NextFillOutcome.insufficientEvidence);
      expect(d.reasons, contains(DecisionReason.noCo2eFactor));
      for (final c in d.candidates) {
        expect(c.metrics.co2eKgPerKm.value, isNull);
      }
    });

    test('a mixed resulting tank never gets a CO2e figure', () {
      final d = decide(tank([FuelGrade.e85, FuelGrade.e10]), profile(),
          objective: FillObjective.lowestCo2ePerKm);
      for (final c in d.candidates) {
        expect(c.metrics.co2eKgPerKm.value, isNull);
      }
    });

    test('without a capacity there is no range claim', () {
      final d = decide(emptyWithoutCapacity(), profile(),
          objective: FillObjective.maxRange);
      expect(d.outcome, NextFillOutcome.insufficientEvidence);
      expect(d.reasons, contains(DecisionReason.capacityUnknown));
      expect(d.candidates.every((c) => c.metrics.rangeKm.value == null), isTrue);
    });

    test('an unknown fill volume is stated, not assumed', () {
      final d = decide(emptyWithoutCapacity(), profile(), litres: null);
      expect(d.outcome, NextFillOutcome.insufficientEvidence);
      expect(d.reasons, [DecisionReason.fillVolumeUnknown]);
    });
  });

  group('balanced cost + CO2e', () {
    final empty = tank([FuelGrade.e85], burn: 50); // pure outcomes

    test('cheaper AND cleaner is recommended', () {
      final d = decide(empty, profile(),
          objective: FillObjective.balancedCostCo2e, litres: 50);
      expect(d.outcome, NextFillOutcome.recommend);
      expect(d.recommended, FuelGrade.e85);
      expect(d.confidence, DecisionConfidence.high);
    });

    test('dearer but cleaner is a stated trade-off, not a verdict', () {
      final d = decide(empty, profile(),
          objective: FillObjective.balancedCostCo2e, litres: 50, e85: 1.60);
      expect(d.outcome, NextFillOutcome.tradeOff);
      expect(d.recommended, isNull);
      final t = d.tradeOffs.single;
      expect(t.costPerKmDelta! * t.co2eKgPerKmDelta!, isNegative);
      expect(t.costPerKgCo2e, isNotNull);
    });
  });

  group('break-even and replay', () {
    final t = tank([FuelGrade.e85], burn: 50);
    final p = profile();

    test('break-even price ties the cost per km exactly', () {
      final d = decide(t, p, litres: 50);
      final lead = d.candidates.first;
      final alt = d.candidates[1];
      final trade = d.tradeOffs.single;
      expect(trade.chosen, lead.grade);
      expect(
          trade.breakEvenPricePerLitre! * lead.metrics.lPer100Km.value! / 100,
          closeTo(alt.metrics.costPerKm.value!, 1e-12));
      expect(
          lead.effectivePricePerLitre * trade.breakEvenLPer100Km! / 100,
          closeTo(alt.metrics.costPerKm.value!, 1e-12));
    });

    test('a detour is priced through RefuelEconomics', () {
      const station = RefuelCandidate(stationId: 's', oneWayKm: 5);
      final d = decide(t, p, litres: 50, station: station);
      final c = d.candidates.first;
      expect(c.effectivePricePerLitre, greaterThan(c.pricePerLitre));
      expect(c.reasons, contains(DecisionReason.detourIncluded));
    });

    test('same inputs in any order → the identical, versioned decision', () {
      NextFillDecision run(List<FuelOffer> offers) => NextFillDecider.decide(
            tank: t,
            profile: p,
            request: NextFillRequest(
              objective: FillObjective.lowestCostPerKm,
              capability: flex,
              offers: offers,
              expectedFillLitres: 50,
            ),
          );
      final offers = [
        FuelOffer(grade: FuelGrade.e10, pricePerLitre: 1.8),
        FuelOffer(grade: FuelGrade.e85, pricePerLitre: 1.1),
        FuelOffer(grade: FuelGrade.e85, pricePerLitre: 1.3),
      ];
      final a = run(offers);
      final b = run(offers.reversed.toList());
      expect(jsonEncode(b.toJson()), jsonEncode(a.toJson()));
      expect(a.toJson()['modelVersion'], NextFillDecision.currentModelVersion);
      expect(a.candidates.first.pricePerLitre, 1.1,
          reason: 'the best offer per grade is kept');
    });

    test('the request is value-equal, so it can key a provider family', () {
      NextFillRequest r() => NextFillRequest(
            objective: FillObjective.lowestCostPerKm,
            capability: VehicleFuelCapability(
                approvedGrades: {FuelGrade.e85, FuelGrade.e10},
                provenance: 'test'),
            offers: [FuelOffer(grade: FuelGrade.e10, pricePerLitre: 1.8)],
          );
      expect(r(), r());
      expect(r().hashCode, r().hashCode);
    });

    test('the thresholds are the documented constants', () {
      expect(kMinMaterialAdvantage, 0.02);
      expect(kTargetShareTolerance, 0.05);
      expect(kMaxConvergenceFills, 5);
    });
  });
}
