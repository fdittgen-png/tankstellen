// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'fuzzy_consumption_engine.dart';
import 'production_fuzzy_engine.dart';

export 'fuzzy_consumption_input.dart'
    show FuzzyConsumptionInput, FuzzyPhysicsBasis, FuzzyReading;
export 'production_fuzzy_engine.dart' show kProductionFuzzyEngine;

/// The per-sample fuzzy stage every production **estimated** fuel rate
/// passes through (#4233, Epic #4222, ADR 0024).
///
/// A producer computes its physics estimate (MAF, speed-density or the GPS
/// road-load balance) exactly as before and hands it here with whatever
/// context it has. The stage runs the production engine once and returns
/// the refined L/h.
///
/// ## The per-sample validation gate
///
/// The **original double** comes back — not a recomputed equal — whenever
///
///  * the engine declines: an input it rejects as invalid (a physics rate
///    above 100 L/h, negative or non-finite) makes the result `unavailable`,
///    and today's figure for that sample is kept rather than dropped; or
///  * its output `==` its input, which the neutral rule base guarantees for
///    every in-range rate (`-0.0` and `+0.0` compare equal, so the sign
///    survives too).
///
/// So with neutral rules the stage is the identity **bit for bit**, which
/// `consumption_identity_goldens_test.dart` pins. A fitted rule base moves
/// a figure only where it has something to say.
///
/// ## Measured never comes here
///
/// A native ECU reading (PID 9D / A2 / 5E) is measured provenance and is
/// never refined, scaled or replaced (Epic #4222 *Source semantics*). The
/// producers return it before reaching this stage; the input asserts it
/// carries no native reading.
///
/// Pure: no clock (ages are the caller's), no I/O, no state.
double refinedFuelRateLPerHour(
  double physicsLPerHour,
  FuzzyPhysicsBasis basis, {
  FuzzyConsumptionInput context = const FuzzyConsumptionInput(),
  FuzzyConsumptionEngine engine = kProductionFuzzyEngine,
}) {
  assert(
    context.physicsFuelRateLPerHour == null &&
        context.physicsBasis == null &&
        context.nativeFuelRateLPerHour == null &&
        context.nativeSource == null,
    'the stage owns the physics input, and measured rates never reach it',
  );
  final result = engine.infer(FuzzyConsumptionInput(
    physicsFuelRateLPerHour: FuzzyReading(physicsLPerHour),
    physicsBasis: basis,
    speedKmh: context.speedKmh,
    accelMps2: context.accelMps2,
    gradePercent: context.gradePercent,
    yawRateRadPerS: context.yawRateRadPerS,
    stopsPerMinute: context.stopsPerMinute,
    rpm: context.rpm,
    engineLoadPercent: context.engineLoadPercent,
    throttlePercent: context.throttlePercent,
    coolantTempC: context.coolantTempC,
    oilTempC: context.oilTempC,
    vehicleMassKg: context.vehicleMassKg,
  ));
  final refined = result.kind == FuzzyOutputKind.estimated
      ? result.fuelRateLPerHour
      : null;
  if (refined == null || refined == physicsLPerHour) return physicsLPerHour;
  return refined;
}

/// [refinedFuelRateLPerHour] with the per-fuel pump gain applied — **the
/// only place in `lib/` a pump gain multiplies an estimate** (ADR 0024,
/// enforced by `single_consumption_estimator_test.dart`).
///
/// The engine sees the physics rate *before* the gain and the gain is
/// applied once, after it, so a fitted rule base can never compound with
/// the calibration. Only engine air-mass bases take a gain: a GPS
/// road-load figure is never pump-gain rescaled (ADR 0022 §2) and uses
/// [refinedFuelRateLPerHour] directly.
double estimatedFuelRateLPerHour(
  double physicsLPerHour,
  FuzzyPhysicsBasis basis, {
  required double pumpGain,
  FuzzyConsumptionInput context = const FuzzyConsumptionInput(),
  FuzzyConsumptionEngine engine = kProductionFuzzyEngine,
}) {
  assert(basis != FuzzyPhysicsBasis.gpsRoadLoad,
      'a GPS road-load figure never carries a pump gain (ADR 0022 §2)');
  return refinedFuelRateLPerHour(physicsLPerHour, basis,
          context: context, engine: engine) *
      pumpGain;
}
