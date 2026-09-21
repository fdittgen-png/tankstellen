// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/trips/domain/fuzzy_consumption/fuzzy_consumption_engine.dart';

import 'fuzzy_test_inputs.dart';

/// #4232 acceptance invariants: determinism, output bounds under hostile
/// input, and confidence monotone in coverage and freshness.
void main() {
  const engine = FuzzyConsumptionEngine();
  const maf = FuzzyPhysicsBasis.maf;

  const hostile = <double>[
    double.nan,
    double.infinity,
    double.negativeInfinity,
    -1e308,
    -1,
    0,
    1e-300,
    1e308,
  ];

  /// A rule base whose consequents try to escape every bound.
  const extreme = FuzzyRuleBase(rulesVersion: 99, rules: [
    FuzzyRule(
      id: 'huge',
      antecedents: [FuzzyAntecedent(FuzzyVariable.speed, FuzzyTerm.highway)],
      consequent: FuzzyConsequent(multiplier: 1e9, residualLPerHour: 1e9),
    ),
    FuzzyRule(
      id: 'negative',
      antecedents: [FuzzyAntecedent(FuzzyVariable.speed, FuzzyTerm.urban)],
      consequent: FuzzyConsequent(multiplier: -5, residualLPerHour: -1e9),
    ),
    FuzzyRule(
      id: 'nan',
      antecedents: [FuzzyAntecedent(FuzzyVariable.speed, FuzzyTerm.rural)],
      consequent: FuzzyConsequent(multiplier: double.nan),
    ),
  ]);

  void expectBounded(FuzzyInferenceResult r, String why) {
    final rate = r.fuelRateLPerHour;
    if (rate != null) {
      expect(rate.isFinite, isTrue, reason: why);
      expect(rate, inInclusiveRange(0, FuzzyOutputBounds.maxFuelRateLPerHour),
          reason: why);
    }
    final c = r.confidence;
    if (c != null) expect(c, inInclusiveRange(0, 1), reason: why);
    final per100 = r.litresPer100Km;
    if (per100 != null) expect(per100.isFinite, isTrue, reason: why);
    expect(r.evidence.coverage, inInclusiveRange(0, 1), reason: why);
    expect(r.evidence.multiplier.isFinite, isTrue, reason: why);
    expect(r.evidence.residualLPerHour.isFinite, isTrue, reason: why);
  }

  group('determinism', () {
    test('identical input and version give an identical result', () {
      final input = inputWith(
          {...fullCruise(ageSeconds: 1.2), FuzzyVariable.grade: const FuzzyReading(3.3)},
          physics: const FuzzyReading(7.77, ageSeconds: 0.4), basis: maf);
      final a = engine.infer(input), b = engine.infer(input);
      expect(b.kind, a.kind);
      expect(b.fuelRateLPerHour, a.fuelRateLPerHour);
      expect(b.confidence, a.confidence);
      expect(b.version, a.version);
      expect(b.evidence.firedRules, a.evidence.firedRules);
      expect(b.evidence.inputs, a.evidence.inputs);
      expect(b.evidence.unevaluableRuleIds, a.evidence.unevaluableRuleIds);
      expect(b.evidence.multiplier, a.evidence.multiplier);
      expect(b.evidence.coverage, a.evidence.coverage);
    });

    test('a fresh engine instance agrees with a reused one', () {
      final input = inputWith(fullCruise(),
          physics: const FuzzyReading(5), basis: maf);
      final reused = engine.infer(input);
      for (var i = 0; i < 50; i++) {
        engine.infer(inputWith({}, physics: FuzzyReading(i.toDouble()),
            basis: maf));
      }
      expect(const FuzzyConsumptionEngine().infer(input).fuelRateLPerHour,
          reused.fuelRateLPerHour,
          reason: 'no state may leak between samples');
    });
  });

  group('output bounds under hostile input', () {
    for (final ruleBase in [FuzzyRuleBase.neutral, extreme]) {
      test('rules v${ruleBase.rulesVersion}: every input slot', () {
        final e = FuzzyConsumptionEngine(ruleBase: ruleBase);
        for (final v in FuzzyVariable.values) {
          for (final x in hostile) {
            for (final physics in hostile) {
              final values = {...fullCruise(), v: FuzzyReading(x)};
              final r = e.infer(inputWith(values,
                  physics: FuzzyReading(physics), basis: maf));
              expectBounded(r, '${v.name}=$x physics=$physics');
              if (!x.isFinite || x < v.min || x > v.max) {
                expect(r.evidence.inputs[v], FuzzyInputStatus.invalid,
                    reason: '${v.name}=$x must be rejected, not clamped');
              }
            }
          }
        }
      });

      test('rules v${ruleBase.rulesVersion}: hostile ages', () {
        final e = FuzzyConsumptionEngine(ruleBase: ruleBase);
        for (final age in hostile) {
          final r = e.infer(inputWith(fullCruise(ageSeconds: age),
              physics: FuzzyReading(5, ageSeconds: age), basis: maf));
          expectBounded(r, 'age=$age');
        }
      });

      test('rules v${ruleBase.rulesVersion}: every speed band', () {
        final e = FuzzyConsumptionEngine(ruleBase: ruleBase);
        for (var speed = 0.0; speed <= 400; speed += 2.5) {
          final r = e.infer(inputWith(
              {...fullCruise(), FuzzyVariable.speed: FuzzyReading(speed)},
              physics: const FuzzyReading(100), basis: maf));
          expectBounded(r, 'speed=$speed');
          expect(r.kind, FuzzyOutputKind.estimated);
        }
      });
    }

    test('a hostile native reading is never passed through', () {
      for (final x in hostile.where((x) => !x.isFinite || x < 0 || x > 100)) {
        final r = engine.infer(FuzzyConsumptionInput(
            nativeFuelRateLPerHour: FuzzyReading(x),
            nativeSource: NativeFuelRateSource.pid9D));
        expect(r.kind, isNot(FuzzyOutputKind.measured), reason: '$x');
      }
    });
  });

  group('confidence reflects coverage and freshness', () {
    double? confidenceWith(Map<FuzzyVariable, FuzzyReading> context,
            {double physicsAge = 0, FuzzyPhysicsBasis basis = maf}) =>
        engine
            .infer(inputWith(context,
                physics: FuzzyReading(5, ageSeconds: physicsAge),
                basis: basis))
            .confidence;

    test('adding inputs one by one never lowers confidence', () {
      final full = fullCruise();
      final context = <FuzzyVariable, FuzzyReading>{};
      var previous = confidenceWith(context)!;
      expect(previous, closeTo(FuzzyConfidencePriors.coverageFloor, 1e-12));
      for (final v in FuzzyVariable.values) {
        context[v] = full[v]!;
        final now = confidenceWith(context)!;
        expect(now, greaterThan(previous), reason: 'adding ${v.name}');
        previous = now;
      }
      expect(previous, closeTo(1, 1e-12));
    });

    test('ageing context inputs never raises confidence', () {
      var previous = 2.0;
      for (var age = 0.0; age <= 70; age += 0.5) {
        final now = confidenceWith(fullCruise(ageSeconds: age))!;
        expect(now, lessThanOrEqualTo(previous + 1e-12), reason: 'age $age');
        previous = now;
      }
    });

    test('ageing the physics input never raises confidence', () {
      var previous = 2.0;
      for (var age = 0.0; age <= 3; age += 0.25) {
        final now = confidenceWith(fullCruise(), physicsAge: age)!;
        expect(now, lessThanOrEqualTo(previous + 1e-12), reason: 'age $age');
        previous = now;
      }
    });

    test('invalid and stale inputs count as absent, not as present', () {
      final withNaN = {...fullCruise(), FuzzyVariable.rpm: const FuzzyReading(double.nan)};
      final withStale = {...fullCruise(), FuzzyVariable.rpm: const FuzzyReading(2000, ageSeconds: 99)};
      final without = {...fullCruise()}..remove(FuzzyVariable.rpm);
      expect(confidenceWith(withNaN), confidenceWith(without));
      expect(confidenceWith(withStale), confidenceWith(without));
    });

    test('the basis ceiling orders air mass above GPS road-load', () {
      final c = {
        for (final b in FuzzyPhysicsBasis.values)
          b: confidenceWith(fullCruise(), basis: b)!,
      };
      expect(c[FuzzyPhysicsBasis.maf]!,
          greaterThan(c[FuzzyPhysicsBasis.speedDensity]!));
      expect(c[FuzzyPhysicsBasis.speedDensity]!,
          greaterThan(c[FuzzyPhysicsBasis.gpsRoadLoad]!));
      expect(c.values.reduce(math.min), greaterThan(0));
    });
  });
}
