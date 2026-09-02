// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3917 — the inventory a fill establishes, built from the learner's
// outcome and persisted as JSON until the next fill.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_inventory.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/domain/services/pump_gain_learner.dart';
import 'package:tankstellen/features/fill_ups/domain/services/tank_report.dart';

final _t0 = DateTime(2026, 9, 1, 9);

FillUp _fill(String id, double odo, {bool full = true}) => FillUp(
      id: id,
      date: _t0,
      vehicleId: 'car',
      liters: 35.7,
      totalCost: 30,
      odometerKm: odo,
      fuelType: FuelType.e85,
      isFullTank: full,
    );

void main() {
  final opening = _fill('f1', 100000);
  final closing = _fill('f2', 100559);
  final period = TankPeriod(
    opening: opening,
    closing: closing,
    distanceKm: 559,
    liters: 35.7,
    pumpedCost: 30,
  );

  test('fromOutcome — calibrated', () {
    final outcome = PumpGainOutcome(
      fuelKey: 'e85',
      period: period,
      coverageShare: 0.81,
      recordedKm: 453,
      rawRecordedLPer100Km: 10.5,
      result: const PumpGainResult(
        vehicleId: 'car',
        previousGain: 0.93,
        newGain: 0.72,
        pumpLPer100Km: 6.39,
        rawRecordedLPer100Km: 10.5,
        coverageShare: 0.81,
        sampleCount: 2,
        proposedEta: 0.5,
      ),
    );
    final inv = FillInventory.fromOutcome(closing, outcome);
    expect(inv.vehicleId, 'car');
    expect(inv.fillId, 'f2');
    expect(inv.isFullTank, isTrue);
    expect(inv.kmSinceLastFull, 559);
    expect(inv.pumpLiters, 35.7);
    expect(inv.pumpLPer100Km, closeTo(6.39, 0.01));
    expect(inv.coverageShare, 0.81);
    expect(inv.rawRecordedLPer100Km, 10.5);
    expect(inv.calibrated, isTrue);
    expect(inv.changePercent, -23);
    expect(inv.skipReason, isNull);
  });

  test('fromOutcome — skipped, no window: the fill\'s own litres', () {
    final inv = FillInventory.fromOutcome(
      closing,
      const PumpGainOutcome(
          fuelKey: 'e85', skipReason: PumpGainSkipReason.noWindow),
    );
    expect(inv.kmSinceLastFull, isNull);
    expect(inv.pumpLPer100Km, isNull);
    expect(inv.pumpLiters, 35.7);
    expect(inv.calibrated, isFalse);
    expect(inv.changePercent, isNull);
    expect(inv.skipReason, PumpGainSkipReason.noWindow);
  });

  test('JSON round-trip, both shapes', () {
    final full = FillInventory(
      vehicleId: 'car',
      fillId: 'f2',
      fillDate: _t0,
      fuelKey: 'e85',
      isFullTank: true,
      pumpLiters: 35.7,
      kmSinceLastFull: 559,
      pumpLPer100Km: 6.39,
      coverageShare: 0.81,
      recordedKm: 453,
      rawRecordedLPer100Km: 10.5,
      previousGain: 0.93,
      newGain: 0.72,
    );
    final back = FillInventory.fromJson(full.toJson())!;
    expect(back.fillId, 'f2');
    expect(back.fillDate, _t0);
    expect(back.kmSinceLastFull, 559);
    expect(back.newGain, 0.72);
    expect(back.skipReason, isNull);

    final skipped = FillInventory(
      vehicleId: 'car',
      fillId: 'f3',
      fillDate: _t0,
      fuelKey: 'e10',
      isFullTank: false,
      pumpLiters: 12,
      skipReason: PumpGainSkipReason.notFullTank,
    );
    final back2 = FillInventory.fromJson(skipped.toJson())!;
    expect(back2.skipReason, PumpGainSkipReason.notFullTank);
    expect(back2.kmSinceLastFull, isNull);
    expect(back2.isFullTank, isFalse);
  });

  test('malformed payload → null, unknown skip reason → null reason', () {
    expect(FillInventory.fromJson(const {}), isNull);
    expect(FillInventory.fromJson(const {'vehicleId': 'v', 'fillId': 'f'}), isNull);
    final inv = FillInventory.fromJson({
      'vehicleId': 'v',
      'fillId': 'f',
      'fillDate': _t0.toIso8601String(),
      'skipReason': 'fromTheFuture',
    })!;
    expect(inv.skipReason, isNull);
    expect(inv.pumpLiters, 0.0);
  });
}
