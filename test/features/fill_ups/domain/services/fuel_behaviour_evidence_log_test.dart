// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/consumption_estimate.dart';
import 'package:tankstellen/core/domain/fuel/behaviour_metric.dart';
import 'package:tankstellen/core/domain/fuel/fuel_behaviour_evidence.dart';
import 'package:tankstellen/core/domain/fuel/fuel_behaviour_profile.dart';
import 'package:tankstellen/core/domain/fuel/fuel_context.dart';
import 'package:tankstellen/core/domain/fuel/fuel_grade.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/domain/services/fuel_behaviour_evidence_log.dart';
import 'package:tankstellen/features/trips/api.dart';

/// #4276 — the recorded history read as behaviour evidence, through the
/// real blend adapter (#4279), engine (#4275) and analyzer. Synthetic
/// records; this pins the wiring, not any real car's consumption.
void main() {
  const vehicle = VehicleProfile(
    id: 'v1',
    name: 'Flex',
    type: VehicleType.combustion,
    tankCapacityL: 50,
    multiFuelCapable: true,
  );
  final t0 = DateTime.utc(2026, 3, 1, 8);
  DateTime day(num n) =>
      t0.add(Duration(minutes: (n * Duration.minutesPerDay).round()));
  final e10 = FuelContext.pure(FuelGrade.e10);
  final e85 = FuelContext.pure(FuelGrade.e85);

  FillUp fill(String id, num d, FuelType fuel, double litres, double odo,
          {bool full = true, double price = 1.5, String vehicleId = 'v1'}) =>
      FillUp(
        id: id,
        date: day(d),
        liters: litres,
        totalCost: litres * price,
        odometerKm: odo,
        fuelType: fuel,
        vehicleId: vehicleId,
        isFullTank: full,
      );

  TripHistoryEntry trip(String id, num d, double lPer100,
          {String source = 'pid5E',
          String? gainKey,
          bool virtual = false,
          bool cold = false}) =>
      TripHistoryEntry(
        id: id,
        vehicleId: 'v1',
        summary: TripSummary(
          distanceKm: 20,
          maxRpm: 3000,
          highRpmSeconds: 0,
          idleSeconds: 0,
          harshBrakes: 0,
          harshAccelerations: 0,
          fuelLitersConsumed: lPer100 / 100 * 20,
          avgLPer100Km: lPer100,
          startedAt: day(d),
          endedAt: day(d).add(const Duration(minutes: 30)),
          dominantFuelSource: source,
          pumpGainFuelKey: gainKey,
          isVirtual: virtual,
          coldStartSurcharge: cold,
        ),
      );

  final fills = [
    fill('f0', 0, FuelType.e10, 50, 0),
    fill('f1', 5, FuelType.e10, 30, 500),
    fill('f2', 10, FuelType.e10, 31, 1000),
    fill('f3', 15, FuelType.e85, 50, 1800), // run dry → pure E85
    fill('f4', 20, FuelType.e85, 40, 2300),
    fill('f5', 25, FuelType.e85, 41, 2800, price: 1.0),
  ];
  final trips = [
    for (var i = 0; i < 5; i++) trip('a$i', 1 + i * 0.5, 6.0 + i * 0.1),
    for (var i = 0; i < 5; i++)
      trip('b$i', 16 + i * 0.5, 8.0 + i * 0.1, cold: i == 0),
  ];

  FuelBehaviourProfile derive(List<FillUp> f, List<TripHistoryEntry> t,
          {VehicleProfile? profile = vehicle}) =>
      deriveFuelBehaviourProfile(
          vehicleId: 'v1', vehicle: profile, fillUps: f, trips: t);

  test('fills and trips land in the grade the tank held', () {
    final p = derive(fills, trips);
    expect(p.contexts.keys, [e10, e85]);
    final b10 = p.behaviourOf(e10)!;
    expect(b10.provenance,
        {EvidenceTier.measured: 5, EvidenceTier.reference: 3});
    expect(b10.lPer100Km.basis, MetricBasis.referenceWindows);
    final b85 = p.behaviourOf(e85)!;
    expect(b85.provenance,
        {EvidenceTier.measured: 5, EvidenceTier.reference: 2});
    expect(b85.lPer100Km.value, closeTo(81 / 1000 * 100, 1e-9));
    expect(b85.conditionShares, {DrivingCondition.coldStart: 0.2});
  });

  test('cost comes from the prices paid; range from the capacity', () {
    final b85 = derive(fills, trips).behaviourOf(e85)!;
    // f4: 40 L × 1.5 over 500 km; f5: 41 L × 1.0 over 500 km.
    expect(b85.costPerKm.value, closeTo((60 / 500 + 41 / 500) / 2, 1e-12));
    expect(b85.rangeKm.value, closeTo(50 * 100 / 8.1, 1e-9));
  });

  test('no production expectation exists yet → uncontrolled, stated', () {
    final b = derive(fills, trips).behaviourOf(e85)!;
    expect(b.residualRatio.insufficientReason, InsufficientReason.noEvidence);
    expect(b.confounderControl, ConfounderControl.uncontrolled);
    expect(b.residualCoverage, 0);
  });

  test('CO2e uses the shipped ADEME factor, stamped with its version', () {
    // #4392 — E85 is 1.11 kg CO2e/L well-to-wheel (ADEME Base Carbone
    // v23.6 element 25766). It was 1.40 under a JEC label that no JEC
    // table publishes per litre.
    final b = derive(fills, trips).behaviourOf(e85)!;
    expect(b.co2eFactor!.kgCo2ePerLitre, 1.11);
    expect(b.co2eFactor!.source, 'ADEME Base Carbone');
    expect(b.co2eFactor!.version, 'v23.6-2026');
    expect(b.co2eFactor!.boundary, Co2eBoundary.wellToWheel);
    expect(b.co2eKgPerKm.value, closeTo(8.1 / 100 * 1.11, 1e-12));
    expect(ademeWtwCo2eFactor(FuelGrade.electric), isNull);
    expect(ademeWtwCo2eFactor(FuelGrade.unknown), isNull);
  });

  test('an estimate calibrated on the E10 gain never teaches E85', () {
    final p = derive(fills, [
      ...trips,
      trip('leak', 18, 30, source: 'maf', gainKey: 'e10'),
    ]);
    expect(p.behaviourOf(e85)!.exclusions,
        {EvidenceExclusion.crossCalibrated: 1});
  });

  test('virtual trips, other vehicles and figure-less trips are handled', () {
    final ev = tripFuelEvidenceFor(vehicleId: 'v1', vehicle: vehicle, trips: [
      trip('virtual', 1, 6, virtual: true),
      TripHistoryEntry(
          id: 'other', vehicleId: 'v2', summary: trips.first.summary),
      trip('ok', 1, 6),
      trip('ok', 1, 6), // duplicate delivery
    ]);
    expect(ev.map((e) => e.id), ['ok']);
    expect(ev.single.sourceClass, ConsumptionSourceClass.measured);
    expect(ev.single.version, isNull, reason: 'legacy figures are unversioned');
  });

  test('a window opening on a partial fill is not reference evidence', () {
    final w = fillWindowEvidenceFor(vehicleId: 'v1', fillUps: [
      fill('p0', 0, FuelType.e10, 20, 0, full: false),
      fill('p1', 5, FuelType.e10, 30, 500),
      fill('p2', 10, FuelType.e10, 30, 1000),
    ]);
    expect(w.map((e) => e.id), ['p2']);
  });

  test('a window with an unpriced fill has no cost, only litres', () {
    final w = fillWindowEvidenceFor(vehicleId: 'v1', fillUps: [
      fill('p0', 0, FuelType.e10, 50, 0),
      fill('p1', 3, FuelType.e10, 10, 200, full: false, price: 0),
      fill('p2', 5, FuelType.e10, 20, 500),
    ]);
    expect(w.single.litres, 30);
    expect(w.single.pumpedCost, isNull);
  });

  test('no history: an empty, versioned profile', () {
    final p = derive(const [], const [], profile: null);
    expect(p.contexts, isEmpty);
    expect(p.tankCapacityLitres, isNull);
    expect(p.modelVersion, FuelBehaviourProfile.currentModelVersion);
  });
}
