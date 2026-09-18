// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/trips/domain/fuzzy_consumption/fuzzy_consumption_engine.dart';
import 'package:tankstellen/features/trips/domain/fuzzy_consumption/fuzzy_fuel_rate_stage.dart';

/// #4233 — the per-sample fuzzy stage: identity under the production
/// (neutral) engine, the original double whenever the engine declines,
/// and the pump gain applied exactly once, AFTER the engine.
int _bits(double x) => (ByteData(8)..setFloat64(0, x)).getUint64(0);

/// A test-only rule base whose single rule fires at full strength when the
/// car stands still, scaling the physics by 1.25.
const _standstillTimes125 = FuzzyConsumptionEngine(
  ruleBase: FuzzyRuleBase(rulesVersion: 2, rules: [
    FuzzyRule(
      id: 'standstill-x1.25',
      antecedents: [FuzzyAntecedent(FuzzyVariable.speed, FuzzyTerm.standstill)],
      consequent: FuzzyConsequent(multiplier: 1.25),
    ),
  ]),
);

const _standing = FuzzyConsumptionInput(speedKmh: FuzzyReading(0));

void main() {
  group('the production engine is the neutral one', () {
    test('kProductionFuzzyEngine carries rules version 1, all neutral', () {
      expect(identical(kProductionFuzzyEngine.ruleBase, FuzzyRuleBase.neutral),
          isTrue);
      expect(kProductionFuzzyEngine.version.model, 1);
      expect(kProductionFuzzyEngine.version.rules, 1);
    });

    test('every in-range rate comes back bit-identical, context or not', () {
      const context = FuzzyConsumptionInput(
        speedKmh: FuzzyReading(72),
        rpm: FuzzyReading(2400, ageSeconds: 1.5),
        engineLoadPercent: FuzzyReading(55),
        coolantTempC: FuzzyReading(40, ageSeconds: 30),
        vehicleMassKg: FuzzyReading(1320),
      );
      for (final basis in FuzzyPhysicsBasis.values) {
        for (final x in [0.0, -0.0, 1e-300, 0.3, 3.3977, 7.1, 42.123456789,
          99.99999999, 100.0]) {
          for (final ctx in [const FuzzyConsumptionInput(), context]) {
            expect(_bits(refinedFuelRateLPerHour(x, basis, context: ctx)),
                _bits(x),
                reason: '$basis $x');
          }
        }
      }
    });

    test('a rate the engine rejects keeps today\'s figure, not a drop', () {
      for (final x in [100.0000001, 215.8, 3190.0, -0.5, double.infinity,
        double.negativeInfinity]) {
        expect(_bits(refinedFuelRateLPerHour(x, FuzzyPhysicsBasis.maf)),
            _bits(x));
      }
      expect(refinedFuelRateLPerHour(double.nan, FuzzyPhysicsBasis.maf).isNaN,
          isTrue);
    });
  });

  group('a non-neutral rule base moves the figure (the stage is wired)', () {
    test('the engine output replaces the physics when it differs', () {
      expect(
          refinedFuelRateLPerHour(10, FuzzyPhysicsBasis.speedDensity,
              context: _standing, engine: _standstillTimes125),
          12.5);
      // Without the context the rule cannot fire: back to the physics.
      expect(
          refinedFuelRateLPerHour(10, FuzzyPhysicsBasis.speedDensity,
              engine: _standstillTimes125),
          10);
    });

    test('the pump gain is applied exactly once, after the engine', () {
      final v = estimatedFuelRateLPerHour(10, FuzzyPhysicsBasis.maf,
          pumpGain: 0.8, context: _standing, engine: _standstillTimes125);
      // 10 · 1.25 · 0.8. The gain squared reads 8.0 (10 · 1.25 · 0.64),
      // and so does feeding the engine a post-gain rate and applying the
      // gain again (8 · 1.25 · 0.8); skipping the gain reads 12.5.
      expect(v, 10.0);
    });

    test('with the production engine the gain is the only scaling', () {
      expect(_bits(estimatedFuelRateLPerHour(7.3, FuzzyPhysicsBasis.maf,
              pumpGain: 0.8)),
          _bits(7.3 * 0.8));
    });
  });

  group('contract guards', () {
    test('a GPS road-load figure never takes a pump gain', () {
      expect(
          () => estimatedFuelRateLPerHour(5, FuzzyPhysicsBasis.gpsRoadLoad,
              pumpGain: 1.1),
          throwsA(isA<AssertionError>()));
    });

    test('a native (measured) reading never reaches the stage', () {
      expect(
          () => refinedFuelRateLPerHour(5, FuzzyPhysicsBasis.maf,
              context: const FuzzyConsumptionInput(
                nativeFuelRateLPerHour: FuzzyReading(5),
                nativeSource: NativeFuelRateSource.pid5E,
              )),
          throwsA(isA<AssertionError>()));
    });
  });
}
