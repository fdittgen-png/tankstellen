// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:tankstellen/features/trips/domain/fuzzy_consumption/fuzzy_consumption_engine.dart';

/// Test helpers for the fuzzy engine suites (#4232). These build inputs
/// that exercise the inference arithmetic — they are **not** traces and
/// validate nothing about accuracy (the corpus is #4231's).

/// A fresh reading for every context variable, set by [values].
FuzzyConsumptionInput inputWith(
  Map<FuzzyVariable, FuzzyReading> values, {
  FuzzyReading? physics,
  FuzzyPhysicsBasis? basis,
  FuzzyReading? native,
  NativeFuelRateSource? nativeSource,
}) =>
    FuzzyConsumptionInput(
      physicsFuelRateLPerHour: physics,
      physicsBasis: basis,
      nativeFuelRateLPerHour: native,
      nativeSource: nativeSource,
      speedKmh: values[FuzzyVariable.speed],
      accelMps2: values[FuzzyVariable.accel],
      gradePercent: values[FuzzyVariable.grade],
      yawRateRadPerS: values[FuzzyVariable.curvature],
      stopsPerMinute: values[FuzzyVariable.stops],
      rpm: values[FuzzyVariable.rpm],
      engineLoadPercent: values[FuzzyVariable.load],
      throttlePercent: values[FuzzyVariable.throttle],
      coolantTempC: values[FuzzyVariable.coolantTemp],
      oilTempC: values[FuzzyVariable.oilTemp],
      vehicleMassKg: values[FuzzyVariable.vehicleMass],
    );

/// The point of [variable]'s domain where [term] is highest (or, with
/// [lowest], lowest) — found by sweeping, so it follows the breakpoints.
double peakOf(FuzzyVariable variable, FuzzyTerm term, {bool lowest = false}) {
  const steps = 8000;
  var best = variable.min;
  var bestMu = lowest ? 2.0 : -1.0;
  for (var i = 0; i <= steps; i++) {
    final x = variable.min + (variable.max - variable.min) * i / steps;
    final mu = variable.membership(term, x);
    if (lowest ? mu < bestMu : mu > bestMu) {
      best = x;
      bestMu = mu;
    }
  }
  return best;
}

/// An input under which [rule] fires at (near) full strength: each
/// antecedent at its term's peak (or trough, when negated), every gated
/// variable left missing, a fresh MAF physics input of 5 L/h.
FuzzyConsumptionInput inputFiring(FuzzyRule rule) => inputWith(
      {
        for (final a in rule.antecedents)
          a.variable: FuzzyReading(
              peakOf(a.variable, a.term, lowest: a.negated)),
      },
      physics: const FuzzyReading(5),
      basis: FuzzyPhysicsBasis.maf,
    );

/// Every context variable fresh at a mid-domain cruise.
Map<FuzzyVariable, FuzzyReading> fullCruise({double ageSeconds = 0}) => {
      FuzzyVariable.speed: FuzzyReading(100, ageSeconds: ageSeconds),
      FuzzyVariable.accel: FuzzyReading(0, ageSeconds: ageSeconds),
      FuzzyVariable.grade: FuzzyReading(0, ageSeconds: ageSeconds),
      FuzzyVariable.curvature: FuzzyReading(0, ageSeconds: ageSeconds),
      FuzzyVariable.stops: FuzzyReading(0, ageSeconds: ageSeconds),
      FuzzyVariable.rpm: FuzzyReading(2500, ageSeconds: ageSeconds),
      FuzzyVariable.load: FuzzyReading(40, ageSeconds: ageSeconds),
      FuzzyVariable.throttle: FuzzyReading(20, ageSeconds: ageSeconds),
      FuzzyVariable.coolantTemp: FuzzyReading(90, ageSeconds: ageSeconds),
      FuzzyVariable.oilTemp: FuzzyReading(95, ageSeconds: ageSeconds),
      FuzzyVariable.vehicleMass: const FuzzyReading(1400),
    };
