// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4206 — a valid full-to-full window validates the whole consumption
// pipeline: pump truth vs raw and calibrated recordings, coverage, residual,
// the fuel sources behind it, what is missing, and a confidence that drops
// instead of manufacturing precision.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/pump_gain_entry.dart';
import 'package:tankstellen/core/domain/pump_gain_resolution.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/domain/services/fill_up_validation.dart';
import 'package:tankstellen/features/fill_ups/domain/services/tank_report.dart';
import 'package:tankstellen/features/trips/domain/trip_fuel_source.dart';
import 'package:tankstellen/features/trips/domain/trip_summary.dart';

final _t0 = DateTime(2026, 8, 1, 8);

FillUp _fill(String id, int day, double odo,
        {List<String> trips = const [], FuelType fuel = FuelType.e85}) =>
    FillUp(
      id: id,
      date: _t0.add(Duration(days: day)),
      vehicleId: 'car',
      liters: 35.7,
      totalCost: 30,
      odometerKm: odo,
      fuelType: fuel,
      linkedTripIds: trips,
    );

TripSummary _trip(double km, double liters,
        {double? gain, String? dominant = 'maf', String? fuelKey}) =>
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
      pumpGainApplied: gain,
      pumpGainFuelKey: fuelKey,
      dominantFuelSource: dominant,
    );

TankPeriod _window({List<String> trips = const ['a', 'b']}) => TankPeriod(
      opening: _fill('f1', 0, 100000),
      closing: _fill('f2', 10, 100559, trips: trips),
      distanceKm: 559,
      liters: 35.7,
      pumpedCost: 30,
    );

void main() {
  // Pump 6.39 L/100 km; recordings 10.5 raw over 453 km (81 % coverage).
  final trips = {
    'a': _trip(300, 31.5, fuelKey: 'e85'),
    'b': _trip(153, 16.07, fuelKey: 'e85'),
  };

  test('an uncalibrated vehicle: the residual IS the gap the pump exposes',
      () {
    final v = FillUpValidation.of(
        _window(), trips, const VehicleProfile(id: 'car', name: 'x'));
    expect(v.pumpLPer100Km, closeTo(6.39, 0.01));
    expect(v.rawRecordedLPer100Km, closeTo(10.5, 0.01));
    expect(v.calibratedRecordedLPer100Km, closeTo(10.5, 0.01));
    expect(v.residualLPer100Km, closeTo(4.11, 0.02));
    expect(v.residualPct, closeTo(64, 1));
    expect(v.coverageShare, closeTo(0.81, 0.01));
    expect(v.uncoveredKm, closeTo(106, 1));
    expect(v.distanceSource, 'odometer');
    expect(v.fuelKey, 'e85');
    expect(v.gainSource, PumpGainSource.uncalibrated);
    expect(v.missingSignals, contains('uncalibrated'));
    expect(v.confidence, ValidationConfidence.medium);
    expect(v.sourceMix[TripFuelSourceKind.estimated], 2);
  });

  test('after calibration the residual collapses and confidence rises', () {
    const v = VehicleProfile(
        id: 'car',
        name: 'x',
        multiFuelCapable: true,
        pumpGainByFuel: {'e85': PumpGainEntry(gain: 0.608, samples: 3)});
    final full = {
      'a': _trip(400, 42.0, fuelKey: 'e85'),
      'b': _trip(150, 15.75, fuelKey: 'e85'),
    };
    final val = FillUpValidation.of(_window(), full, v);
    expect(val.calibratedRecordedLPer100Km, closeTo(6.39, 0.05));
    expect(val.residualPct!.abs(), lessThan(2));
    expect(val.gain, closeTo(0.608, 1e-9));
    expect(val.gainSamples, 3);
    expect(val.confidence, ValidationConfidence.high);
  });

  test('a measured trip is never rescaled and shows as measured', () {
    const v = VehicleProfile(
        id: 'car', name: 'x', pumpGain: 0.5, pumpGainSamples: 2);
    final measured = {'a': _trip(453, 47.6, dominant: 'pid5E', fuelKey: 'e85')};
    final val = FillUpValidation.of(_window(trips: ['a']), measured, v);
    expect(val.calibratedRecordedLPer100Km, closeTo(10.5, 0.01));
    expect(val.sourceMix[TripFuelSourceKind.measured], 1);
  });

  // #4321 — the recorder stamps `pumpGainApplied` on measured trips too,
  // though no measured branch ever multiplied by it.
  test('#4321 — a measured trip stamped pg 0.8 contributes its RAW litres',
      () {
    const v = VehicleProfile(
        id: 'car', name: 'x', pumpGain: 0.8, pumpGainSamples: 2);
    final measured = {
      'a': _trip(453, 47.6, gain: 0.8, dominant: 'pid9D', fuelKey: 'e85'),
    };
    final val = FillUpValidation.of(_window(trips: ['a']), measured, v);
    expect(val.rawRecordedLPer100Km, closeTo(10.5, 0.01),
        reason: '13.13 means the unapplied gain was divided back out');
    expect(val.calibratedRecordedLPer100Km, closeTo(10.5, 0.01));
  });

  test('#4321 — an estimated trip has its gain removed exactly once', () {
    const v = VehicleProfile(
        id: 'car', name: 'x', pumpGain: 0.6, pumpGainSamples: 2);
    // 10.5 L/100 raw, recorded at 0.6 → 6.3 L/100 stored.
    final estimated = {
      'a': _trip(453, 28.539, gain: 0.6, dominant: 'speedDensity',
          fuelKey: 'e85'),
    };
    final val = FillUpValidation.of(_window(trips: ['a']), estimated, v);
    expect(val.rawRecordedLPer100Km, closeTo(10.5, 0.01));
    expect(val.calibratedRecordedLPer100Km, closeTo(6.3, 0.01));
  });

  test('thin evidence says so: low coverage, mixed grades, no recordings',
      () {
    const v = VehicleProfile(
        id: 'car', name: 'x', pumpGain: 0.6, pumpGainSamples: 2);
    final thin = FillUpValidation.of(
        _window(trips: ['a']), {'a': _trip(50, 5, fuelKey: 'e85')}, v);
    expect(thin.missingSignals, contains('lowCoverage'));
    expect(thin.confidence, ValidationConfidence.low);

    final mixed = FillUpValidation.of(_window(), {
      'a': _trip(300, 31.5, fuelKey: 'e85'),
      'b': _trip(153, 16.07, fuelKey: 'e10'),
    }, v);
    expect(mixed.missingSignals, contains('mixedGrades'));
    expect(mixed.confidence, ValidationConfidence.low);

    final none = FillUpValidation.of(_window(trips: const []), const {}, v);
    expect(none.missingSignals, containsAll(['noRecordings', 'noRecordedFuel']));
    expect(none.calibratedRecordedLPer100Km, isNull);
    expect(none.residualPct, isNull);
    expect(none.confidence, ValidationConfidence.low);
  });

  test('the trace carries every figure and its provenance', () {
    final t = FillUpValidation.of(
            _window(), trips, const VehicleProfile(id: 'car', name: 'x'))
        .toTrace();
    expect(t.keys, containsAll([
      'fuelKey',
      'distanceSource',
      'pumpLPer100Km',
      'rawRecordedLPer100Km',
      'calibratedRecordedLPer100Km',
      'residualPct',
      'coverageShare',
      'uncoveredKm',
      'gain',
      'gainSource',
      'sourceMix',
      'missingSignals',
      'confidence',
    ]));
  });
}
