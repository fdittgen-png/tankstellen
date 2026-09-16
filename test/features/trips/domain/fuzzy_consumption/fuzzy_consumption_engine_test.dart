// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/consumption_estimate.dart';
import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/features/trips/domain/fuzzy_consumption/fuzzy_consumption_engine.dart';

import 'fuzzy_test_inputs.dart';

/// The fuzzy consumption engine's inference semantics (#4232).
void main() {
  const engine = FuzzyConsumptionEngine();
  const maf = FuzzyPhysicsBasis.maf;

  /// A deliberately NON-neutral rule base, used only to prove the
  /// arithmetic moves when consequents do. Its numbers are arbitrary test
  /// values, not a model of any car.
  const skewed = FuzzyRuleBase(rulesVersion: 7, rules: [
    FuzzyRule(
      id: 'uphill',
      antecedents: [FuzzyAntecedent(FuzzyVariable.grade, FuzzyTerm.uphill)],
      consequent: FuzzyConsequent(multiplier: 1.5, residualLPerHour: 1),
    ),
  ]);

  group('rule firing', () {
    test('a cold idle fires idle and cold-engine, and nothing degraded', () {
      final r = engine.infer(inputWith({
        FuzzyVariable.speed: const FuzzyReading(0),
        FuzzyVariable.rpm: const FuzzyReading(800),
        FuzzyVariable.coolantTemp: const FuzzyReading(20),
      }, physics: const FuzzyReading(0.8), basis: maf));
      final ids = r.evidence.firedRules.map((f) => f.id).toList();
      expect(ids, containsAllInOrder(['idle', 'cold-engine']));
      expect(ids, isNot(contains('idle-d')),
          reason: 'RPM is present, so the degraded idle stays closed');
      expect(ids, isNot(contains('cold-engine-oil-d')));
    });

    test('without RPM, idle is recognised by its degraded rule', () {
      final r = engine.infer(inputWith(
          {FuzzyVariable.speed: const FuzzyReading(0)},
          physics: const FuzzyReading(0.8), basis: maf));
      final idle = r.evidence.firedRules.singleWhere((f) => f.id == 'idle-d');
      expect(idle.degraded, isTrue);
      expect(idle.strength, 1);
      expect(r.evidence.unevaluableRuleIds, contains('idle'));
      expect(r.evidence.inputs[FuzzyVariable.rpm], FuzzyInputStatus.missing);
    });

    test('a stale input closes its rule exactly like a missing one', () {
      final r = engine.infer(inputWith({
        FuzzyVariable.speed: const FuzzyReading(0),
        FuzzyVariable.rpm: const FuzzyReading(800, ageSeconds: 30),
      }, physics: const FuzzyReading(0.8), basis: maf));
      expect(r.evidence.inputs[FuzzyVariable.rpm], FuzzyInputStatus.stale);
      expect(r.evidence.firedRules.map((f) => f.id), contains('idle-d'));
    });

    test('strength is the min over antecedents, NOT is 1 − μ', () {
      // urban 30 km/h (μ 1), steady (μ 1), stops 1/min: flowing μ 0.5.
      final r = engine.infer(inputWith({
        FuzzyVariable.speed: const FuzzyReading(30),
        FuzzyVariable.accel: const FuzzyReading(0),
        FuzzyVariable.stops: const FuzzyReading(1),
      }, physics: const FuzzyReading(4), basis: maf));
      final byId = {for (final f in r.evidence.firedRules) f.id: f.strength};
      expect(byId['urban-cruise'], closeTo(0.5, 1e-12));
      expect(byId['stop-and-go'], closeTo(0.5, 1e-12));
      expect(r.evidence.defaultRuleStrength, closeTo(0.5, 1e-12));
    });
  });

  group('defuzzification', () {
    test('the neutral rule base returns the physics estimate unchanged', () {
      for (final physics in [0.0, 0.7, 5.3, 42.0, 100.0]) {
        final r = engine.infer(inputWith(fullCruise(),
            physics: FuzzyReading(physics), basis: maf));
        expect(r.kind, FuzzyOutputKind.estimated);
        expect(r.fuelRateLPerHour, closeTo(physics, 1e-12));
        expect(r.evidence.multiplier, closeTo(1, 1e-12));
        expect(r.evidence.residualLPerHour, 0);
      }
    });

    test('a non-neutral consequent moves the figure by the weighted mean',
        () {
      const e = FuzzyConsumptionEngine(ruleBase: skewed);
      // grade 4 %: uphill μ 0.5 → default 0.5.
      // multiplier = (0.5·1 + 0.5·1.5) / 1 = 1.25; residual = 0.5.
      final r = e.infer(inputWith({FuzzyVariable.grade: const FuzzyReading(4)},
          physics: const FuzzyReading(8), basis: maf));
      expect(r.evidence.multiplier, closeTo(1.25, 1e-12));
      expect(r.evidence.residualLPerHour, closeTo(0.5, 1e-12));
      expect(r.fuelRateLPerHour, closeTo(8 * 1.25 + 0.5, 1e-12));
      expect(r.version, const ConsumptionModelVersion(model: 1, rules: 7));
    });
  });

  group('native ECU fuel rate is never overridden', () {
    for (final ruleBase in [FuzzyRuleBase.neutral, skewed]) {
      test('rules v${ruleBase.rulesVersion}: measured passes through', () {
        final e = FuzzyConsumptionEngine(ruleBase: ruleBase);
        final r = e.infer(inputWith(
          {...fullCruise(), FuzzyVariable.grade: const FuzzyReading(8)},
          physics: const FuzzyReading(9),
          basis: maf,
          native: const FuzzyReading(6.25),
          nativeSource: NativeFuelRateSource.pid9D,
        ));
        expect(r.kind, FuzzyOutputKind.measured);
        expect(r.fuelRateLPerHour, 6.25);
        expect(r.sourceClass, ConsumptionSourceClass.measured);
        expect(r.fuelRateValue, const DataValue<double>.measured(6.25));
        expect(r.confidence, isNull,
            reason: 'ADR 0022: a measured read is not a probability');
        expect(r.nativeSource, NativeFuelRateSource.pid9D);
        // The estimate travels beside it as evidence only.
        expect(r.inferredFuelRateLPerHour, isNotNull);
        expect(r.evidence.nativeAgreementRatio,
            closeTo(r.inferredFuelRateLPerHour! / 6.25, 1e-12));
      });
    }

    test('a native reading without physics is still measured', () {
      final r = engine.infer(const FuzzyConsumptionInput(
        nativeFuelRateLPerHour: FuzzyReading(3),
        nativeSource: NativeFuelRateSource.pid5E,
      ));
      expect(r.kind, FuzzyOutputKind.measured);
      expect(r.fuelRateLPerHour, 3);
      expect(r.inferredFuelRateLPerHour, isNull);
      expect(r.evidence.nativeAgreementRatio, isNull);
    });

    test('a stale or invalid native reading falls to the estimate', () {
      for (final bad in [
        const FuzzyReading(3, ageSeconds: 10),
        const FuzzyReading(double.nan),
        const FuzzyReading(-2),
      ]) {
        final r = engine.infer(FuzzyConsumptionInput(
          nativeFuelRateLPerHour: bad,
          nativeSource: NativeFuelRateSource.pidA2,
          physicsFuelRateLPerHour: const FuzzyReading(4),
          physicsBasis: FuzzyPhysicsBasis.speedDensity,
        ));
        expect(r.kind, FuzzyOutputKind.estimated, reason: '$bad');
        expect(r.fuelRateLPerHour, 4);
        expect(r.evidence.nativeStatus, isNot(FuzzyInputStatus.fresh));
      }
    });
  });

  group('absence is stated, never a zero', () {
    test('no physics input → unavailable with a reason', () {
      final r = engine.infer(inputWith(fullCruise()));
      expect(r.kind, FuzzyOutputKind.unavailable);
      expect(r.fuelRateLPerHour, isNull);
      expect(r.litresPer100Km, isNull);
      expect(r.unavailableReason, FuzzyUnavailableReason.noPhysicsInput);
      expect(r.sourceClass, ConsumptionSourceClass.none);
      expect(r.fuelRateValue, isA<Unknown<double>>());
    });

    test('a physics reading without its basis is not usable', () {
      final r = engine.infer(
          const FuzzyConsumptionInput(physicsFuelRateLPerHour: FuzzyReading(4)));
      expect(r.unavailableReason, FuzzyUnavailableReason.noPhysicsInput);
    });

    test('stale and invalid physics carry their own reasons', () {
      FuzzyInferenceResult with_(FuzzyReading p) => engine.infer(
          FuzzyConsumptionInput(physicsFuelRateLPerHour: p, physicsBasis: maf));
      expect(with_(const FuzzyReading(4, ageSeconds: 5)).unavailableReason,
          FuzzyUnavailableReason.physicsStale);
      final invalid = with_(const FuzzyReading(1e6));
      expect(invalid.unavailableReason, FuzzyUnavailableReason.physicsInvalid);
      expect(invalid.fuelRateValue,
          const DataValue<double>.unknown(reason: DataUnknownReason.unreadable));
    });
  });

  group('provenance', () {
    test('air-mass physics is estimated, GPS road-load is gpsOnly', () {
      final air = engine.infer(const FuzzyConsumptionInput(
          physicsFuelRateLPerHour: FuzzyReading(4), physicsBasis: maf));
      expect(air.sourceClass, ConsumptionSourceClass.estimated);
      expect(air.fuelRateValue,
          const DataValue<double>.estimated(4, basis: DataBasis.derived));
      final gps = engine.infer(const FuzzyConsumptionInput(
          physicsFuelRateLPerHour: FuzzyReading(4),
          physicsBasis: FuzzyPhysicsBasis.gpsRoadLoad));
      expect(gps.sourceClass, ConsumptionSourceClass.gpsOnly);
      expect(gps.kind, FuzzyOutputKind.estimated);
    });

    test('the shipped version is model 1, rules 1, uncalibrated', () {
      expect(engine.version,
          const ConsumptionModelVersion(model: 1, rules: 1));
      expect(engine.infer(const FuzzyConsumptionInput()).version,
          engine.version);
    });

    test('L/100 km divides by the fresh speed, undefined near standstill', () {
      final moving = engine.infer(const FuzzyConsumptionInput(
          physicsFuelRateLPerHour: FuzzyReading(6),
          physicsBasis: maf,
          speedKmh: FuzzyReading(100)));
      expect(moving.litresPer100Km, closeTo(6, 1e-12));
      final crawling = engine.infer(const FuzzyConsumptionInput(
          physicsFuelRateLPerHour: FuzzyReading(1),
          physicsBasis: maf,
          speedKmh: FuzzyReading(3)));
      expect(crawling.litresPer100Km, isNull);
    });
  });
}
