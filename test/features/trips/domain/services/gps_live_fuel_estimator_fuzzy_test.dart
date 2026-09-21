// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/trips/domain/fuzzy_consumption/fuzzy_consumption_engine.dart';
import 'package:tankstellen/features/trips/domain/fuzzy_consumption/production_fuzzy_engine.dart';
import 'package:tankstellen/features/trips/domain/services/gps_live_fuel_estimator.dart';
import 'package:tankstellen/features/trips/domain/vehicle_road_load_parameters.dart';

/// #4233 — GPS road-load goes through the fuzzy stage: a test-only rule base
/// moves the litres and the instant figure, and the context it sees carries
/// this tick's speed, the grade only when confident, and the mass only when
/// it is the vehicle's own. (Bit-identity under the production engine is
/// pinned by `consumption_identity_goldens_test.dart`.)
FuzzyConsumptionEngine _times(double m, FuzzyAntecedent when) =>
    FuzzyConsumptionEngine(
      ruleBase: FuzzyRuleBase(rulesVersion: 9, rules: [
        FuzzyRule(
          id: 'test',
          antecedents: [when],
          consequent: FuzzyConsequent(multiplier: m),
        ),
      ]),
    );

({double litres, double? instant}) _drive(
  VehicleRoadLoadParameters params, {
  FuzzyConsumptionEngine? engine,
  double kmh = 120,
  double gradeFraction = 0,
  bool gradeConfident = false,
}) {
  final est = engine == null
      ? GpsLiveFuelEstimator.withParameters(params)
      : GpsLiveFuelEstimator.withParameters(params, engine: engine);
  double? instant;
  for (var i = 0; i < 10; i++) {
    instant = est.onSample(
      speedMps: kmh / 3.6,
      prevSpeedMps: kmh / 3.6,
      dtSeconds: 1,
      gradeFraction: gradeFraction,
      gradeConfident: gradeConfident,
    );
  }
  return (litres: est.litersSoFar, instant: instant);
}

void main() {
  final classPrior = VehicleRoadLoadParameters.resolve(
      curbWeightKg: null, preferredFuelType: null);
  final heavyOwn = VehicleRoadLoadParameters.resolve(
      curbWeightKg: 2100, preferredFuelType: 'diesel');

  test('a non-neutral rule base scales the road-load fuel (wired)', () {
    final base = _drive(classPrior);
    final scaled = _drive(classPrior,
        engine: _times(
            1.25, const FuzzyAntecedent(FuzzyVariable.speed, FuzzyTerm.highway)));
    expect(scaled.litres, closeTo(base.litres * 1.25, 1e-12));
    expect(scaled.instant, closeTo(base.instant! * 1.25, 1e-9));
  });

  test('the production engine leaves the figure bit-identical', () {
    final a = _drive(heavyOwn, gradeFraction: 0.05, gradeConfident: true);
    final b = _drive(heavyOwn,
        engine: kProductionFuzzyEngine,
        gradeFraction: 0.05,
        gradeConfident: true);
    expect(b.litres, a.litres);
    expect(b.instant, a.instant);
  });

  test('the grade reaches the engine only when it is confident', () {
    final climbRule =
        _times(1.5, const FuzzyAntecedent(FuzzyVariable.grade, FuzzyTerm.uphill));
    final plain = _drive(classPrior, kmh: 50, gradeFraction: 0.09,
        gradeConfident: true);
    final confident = _drive(classPrior,
        kmh: 50, gradeFraction: 0.09, gradeConfident: true, engine: climbRule);
    final unconfident = _drive(classPrior,
        kmh: 50, gradeFraction: 0.09, gradeConfident: false, engine: climbRule);
    expect(confident.litres, closeTo(plain.litres * 1.5, 1e-12));
    expect(unconfident.litres,
        _drive(classPrior, kmh: 50, gradeFraction: 0.09).litres);
  });

  test('the mass reaches the engine only when it is the vehicle\'s own', () {
    final heavyRule = _times(
        2, const FuzzyAntecedent(FuzzyVariable.vehicleMass, FuzzyTerm.heavy));
    final ownHeavy = _drive(heavyOwn);
    expect(_drive(heavyOwn, engine: heavyRule).litres,
        closeTo(ownHeavy.litres * 2, 1e-12));
    // A class-prior mass is not evidence: the rule cannot fire.
    expect(_drive(classPrior, engine: heavyRule).litres,
        _drive(classPrior).litres);
  });
}
