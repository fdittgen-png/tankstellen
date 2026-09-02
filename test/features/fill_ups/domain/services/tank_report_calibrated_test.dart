// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3918 — the tank report's recorded figure re-expressed at the current
// gain, and the residual that remains after that calibration.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/pump_gain_entry.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/domain/services/tank_report.dart';
import 'package:tankstellen/features/trips/domain/trip_summary.dart';

final _t0 = DateTime(2026, 8, 1, 8);

FillUp _fill(String id, int day, double odo, {List<String> trips = const []}) =>
    FillUp(
      id: id,
      date: _t0.add(Duration(days: day)),
      vehicleId: 'car',
      liters: 35.7,
      totalCost: 30,
      odometerKm: odo,
      fuelType: FuelType.e85,
      linkedTripIds: trips,
    );

TripSummary _trip(double km, double liters, {String? dominant, double? veUsed}) =>
    TripSummary(
      distanceKm: km,
      maxRpm: 3000,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: 0,
      harshAccelerations: 0,
      fuelLitersConsumed: liters,
      avgLPer100Km: liters / km * 100,
      startedAt: _t0,
      dominantFuelSource: dominant,
      volumetricEfficiencyUsed: veUsed,
    );

void main() {
  final period = TankPeriod(
    opening: _fill('f1', 0, 100000),
    closing: _fill('f2', 10, 100559, trips: ['a', 'b', 'ghost']),
    distanceKm: 559,
    liters: 35.7,
    pumpedCost: 30,
  );
  // Pump 6.39 L/100 km; recordings 10.5 raw over 453 km.
  final trips = {
    'a': _trip(300, 31.5, veUsed: 0.85),
    'b': _trip(153, 16.07, veUsed: 0.85),
  };

  test('uncalibrated vehicle: the stored figure, residual +64 %', () {
    final r = calibratedTankRecording(
        period, trips, const VehicleProfile(id: 'car', name: 'x'))!;
    expect(r.recordedLPer100Km, closeTo(10.5, 0.01));
    expect(r.residualPct, closeTo(64, 1));
  });

  test('after the pump gain landed the residual collapses to ~0', () {
    const v = VehicleProfile(
        id: 'car', name: 'x', pumpGain: 0.608, pumpGainSamples: 1);
    final r = calibratedTankRecording(period, trips, v)!;
    expect(r.recordedLPer100Km, closeTo(6.39, 0.02));
    expect(r.residualPct.abs(), lessThan(1));
  });

  test('the closing fill\'s fuel picks the per-fuel gain', () {
    const flex = VehicleProfile(
      id: 'car',
      name: 'Flex',
      multiFuelCapable: true,
      pumpGain: 1.0,
      pumpGainByFuel: {'e85': PumpGainEntry(gain: 0.5, samples: 1)},
    );
    final r = calibratedTankRecording(period, trips, flex)!;
    expect(r.recordedLPer100Km, closeTo(5.25, 0.01));
  });

  test('measured trips are not rescaled; no fuel → null', () {
    const v = VehicleProfile(
        id: 'car', name: 'x', pumpGain: 0.5, pumpGainSamples: 1);
    final measured = {'a': _trip(453, 47.6, dominant: 'pid5E')};
    expect(calibratedTankRecording(period, measured, v)!.recordedLPer100Km,
        closeTo(10.5, 0.01));
    expect(calibratedTankRecording(period, const {}, v), isNull);
  });
}
