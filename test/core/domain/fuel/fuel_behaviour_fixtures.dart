// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:tankstellen/core/domain/consumption_estimate.dart';
import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/core/domain/fuel/blend_timeline.dart';
import 'package:tankstellen/core/domain/fuel/fuel_behaviour_evidence.dart';
import 'package:tankstellen/core/domain/fuel/fuel_grade.dart';
import 'package:tankstellen/core/domain/fuel/tank_blend_engine.dart';
import 'package:tankstellen/core/domain/fuel/tank_blend_event.dart';

/// Deterministic SYNTHETIC fixtures for the #4276 / #4277 domain tests.
///
/// These are NOT a corpus and prove nothing about accuracy: every
/// "observed" figure below is written as `expected × fuel factor × a fixed
/// wobble`, so the tests pin the arithmetic, attribution and isolation of
/// the domain logic — and only that. Real validation belongs to #4231's
/// replay corpus, which is still empty.

const double kCapacity = 50;

final DateTime t0 = DateTime.utc(2026, 1, 1, 8);

DateTime day(num d) =>
    t0.add(Duration(minutes: (d * Duration.minutesPerDay).round()));

const ConsumptionModelVersion v1 = ConsumptionModelVersion(model: 1, rules: 1);

/// The pipeline's expected L/100 km for a drive's conditions (synthetic).
double expectedFor(Set<DrivingCondition> conditions) {
  var e = 6.0;
  if (conditions.contains(DrivingCondition.hilly)) e += 2.0;
  if (conditions.contains(DrivingCondition.coldStart)) e += 1.0;
  if (conditions.contains(DrivingCondition.stopAndGo)) e += 1.5;
  return e;
}

/// ±2 % deterministic wobble so intervals have a width.
double wobble(int i) => 1 + 0.02 * ((i % 3) - 1);

TripFuelEvidence trip(
  String id,
  num d, {
  required double observed,
  double km = 20,
  double? expected,
  ConsumptionSourceClass source = ConsumptionSourceClass.measured,
  FuelGrade? calibrationGrade,
  Set<DrivingCondition> conditions = const {},
}) =>
    TripFuelEvidence(
      id: id,
      at: day(d),
      distanceKm: km,
      litresPer100Km: source == ConsumptionSourceClass.measured
          ? DataValue.measured(observed)
          : DataValue.estimated(observed, basis: DataBasis.derived),
      sourceClass: source,
      version: v1,
      expectedLPer100Km: expected,
      calibrationGrade: calibrationGrade,
      conditions: conditions,
    );

/// [n] trips from [startDay], one every 0.5 day, burning [factor] × the
/// expected consumption of [conditions].
List<TripFuelEvidence> tripsOn(
  String prefix,
  num startDay,
  int n, {
  required double factor,
  Set<DrivingCondition> conditions = const {},
  bool withExpected = true,
  ConsumptionSourceClass source = ConsumptionSourceClass.measured,
  FuelGrade? calibrationGrade,
  double km = 20,
}) =>
    [
      for (var i = 0; i < n; i++)
        trip(
          '$prefix$i',
          startDay + i * 0.5,
          observed: expectedFor(conditions) * factor * wobble(i),
          expected: withExpected ? expectedFor(conditions) : null,
          conditions: conditions,
          source: source,
          calibrationGrade: calibrationGrade,
          km: km,
        ),
    ];

TankFillEvent fill(String id, num d, FuelGrade grade, double litres,
        {bool full = true}) =>
    TankFillEvent(
        id: id, at: day(d), grade: grade, litres: litres, fillsTank: full);

/// The reference history: pure E10 (days 0–11), pure E85 (11–22), then a
/// mixed E10/E85 tank (22–33). Every switch is either a run-dry full fill
/// (pure) or a half-tank top-up (mixed), so the contexts are exact.
List<TankBlendEvent> referenceLog() => [
      fill('e10-a', 0, FuelGrade.e10, 50),
      fill('e10-b', 5, FuelGrade.e10, 40),
      fill('e10-c', 10, FuelGrade.e10, 40),
      fill('e85-a', 11, FuelGrade.e85, 50), // run dry → pure E85
      fill('e85-b', 16, FuelGrade.e85, 40),
      fill('e85-c', 21, FuelGrade.e85, 40),
      fill('mix-a', 22, FuelGrade.e10, 25), // 25 L E85 left → 50/50
      fill('mix-b', 27, FuelGrade.e10, 25), // → 75/25 E10/E85
      fill('mix-c', 32, FuelGrade.e85, 25), // → 37.5/62.5
      fill('mix-d', 33, FuelGrade.e85, 25),
    ];

BlendTimeline referenceTimeline({List<TankBlendEvent>? log}) =>
    BlendTimeline.fold(
        TankBlendEngine(tankCapacityLitres: kCapacity), log ?? referenceLog());

FillWindowEvidence window(String id, num open, num close,
        {required double lPer100Km,
        double km = 500,
        double? pricePerLitre = 1.5}) =>
    FillWindowEvidence(
      id: id,
      openedAt: day(open),
      closedAt: day(close),
      litres: lPer100Km * km / 100,
      distanceKm: km,
      pumpedCost:
          pricePerLitre == null ? null : lPer100Km * km / 100 * pricePerLitre,
    );
