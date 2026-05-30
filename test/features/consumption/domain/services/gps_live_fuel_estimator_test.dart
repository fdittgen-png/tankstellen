// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/services/gps_fuel_estimator.dart';
import 'package:tankstellen/features/consumption/domain/services/gps_live_fuel_estimator.dart';
import 'package:tankstellen/features/vehicle/domain/entities/gps_calibration_matrix.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';

/// Drive a steady-state cruise: feed [ticks] samples at constant
/// [speedMps] and 1 s dt so acceleration settles to ~0.
GpsLiveFuelEstimator _cruise({
  VehicleProfile? vehicle,
  GpsCalibrationMatrix? matrix,
  required double speedMps,
  int ticks = 10,
}) {
  final e = GpsLiveFuelEstimator.forVehicle(vehicle, matrix);
  for (var i = 0; i < ticks; i++) {
    e.onSample(speedMps: speedMps, prevSpeedMps: speedMps, dtSeconds: 1);
  }
  return e;
}

void main() {
  group('GpsLiveFuelEstimator.forVehicle — parameter resolution', () {
    test('null vehicle + null matrix produces a moving, finite estimate', () {
      final e = _cruise(speedMps: 25); // ~90 km/h
      expect(e.instantLPer100Km, isNotNull);
      expect(e.instantLPer100Km, greaterThan(0));
      expect(e.litersSoFar, greaterThan(0));
    });

    test('a diesel profile burns less per km than petrol at the same cruise',
        () {
      // Diesel has higher LHV + efficiency + lower idle → lower L/100 km
      // for the identical road load.
      const petrolCar = VehicleProfile(
        id: 'p',
        name: 'petrol',
        curbWeightKg: 1500,
        preferredFuelType: 'petrol',
      );
      const dieselCar = VehicleProfile(
        id: 'd',
        name: 'diesel',
        curbWeightKg: 1500,
        preferredFuelType: 'diesel',
      );
      final petrol = _cruise(vehicle: petrolCar, speedMps: 25);
      final diesel = _cruise(vehicle: dieselCar, speedMps: 25);
      expect(diesel.instantLPer100Km, lessThan(petrol.instantLPer100Km!));
    });

    test('an E85 profile burns MORE per km than petrol — lower LHV (#2431)',
        () {
      // #2431 — E85's volumetric LHV (25.6 MJ/L) is ~20 % below petrol
      // (31.9 MJ/L) at the SAME efficiency, so the energy→litres step
      // needs ~25 % more litres for the identical road load. Before the
      // fix E85 fell into the petrol branch and read identical to petrol;
      // now it must read higher.
      const petrolCar = VehicleProfile(
        id: 'p',
        name: 'petrol',
        curbWeightKg: 1500,
        preferredFuelType: 'petrol',
      );
      const e85Car = VehicleProfile(
        id: 'e',
        name: 'flex',
        curbWeightKg: 1500,
        preferredFuelType: 'E85',
      );
      final petrol = _cruise(vehicle: petrolCar, speedMps: 25);
      final e85 = _cruise(vehicle: e85Car, speedMps: 25);
      expect(e85.instantLPer100Km, greaterThan(petrol.instantLPer100Km!));
      // The instant figure scales as petrolLhv / e85Lhv at equal efficiency
      // (tractive term dominates idle at cruise). Assert it lands within a
      // tolerance of that expected ratio so the fix is the LHV, not noise.
      const expectedRatio = GpsLiveFuelEstimator.petrolLhvMjPerL /
          GpsLiveFuelEstimator.e85LhvMjPerL;
      final actualRatio = e85.instantLPer100Km! / petrol.instantLPer100Km!;
      expect(actualRatio, closeTo(expectedRatio, 0.1));
    });

    test('an "ethanol" fuel string also resolves to the E85 LHV (#2431)', () {
      const petrolCar = VehicleProfile(
        id: 'p',
        name: 'petrol',
        curbWeightKg: 1500,
        preferredFuelType: 'petrol',
      );
      const ethanolCar = VehicleProfile(
        id: 'e',
        name: 'flex',
        curbWeightKg: 1500,
        preferredFuelType: 'ethanol blend',
      );
      final petrol = _cruise(vehicle: petrolCar, speedMps: 25);
      final ethanol = _cruise(vehicle: ethanolCar, speedMps: 25);
      expect(ethanol.instantLPer100Km, greaterThan(petrol.instantLPer100Km!));
    });

    test('a heavier (SUV-class) vehicle burns more than a compact at cruise',
        () {
      const compact = VehicleProfile(
        id: 'c',
        name: 'compact',
        curbWeightKg: 1250, // → compact class
        preferredFuelType: 'petrol',
      );
      const suv = VehicleProfile(
        id: 's',
        name: 'suv',
        curbWeightKg: 2000, // → SUV class (higher Cd/A/Crr too)
        preferredFuelType: 'petrol',
      );
      final small = _cruise(vehicle: compact, speedMps: 25);
      final big = _cruise(vehicle: suv, speedMps: 25);
      expect(big.instantLPer100Km, greaterThan(small.instantLPer100Km!));
    });

    test('curbWeightKg, when present, overrides the class-default mass', () {
      // Same body class (compact bucket) but very different masses → the
      // heavier explicit curb weight burns more, proving mass came from
      // the field not the table.
      const light = VehicleProfile(
        id: 'l',
        name: 'light',
        curbWeightKg: 1100,
        preferredFuelType: 'petrol',
      );
      const heavy = VehicleProfile(
        id: 'h',
        name: 'heavy',
        curbWeightKg: 1440, // still compact bucket, but 340 kg heavier
        preferredFuelType: 'petrol',
      );
      // Use an accelerating leg so the inertial mass term bites.
      final lightE = GpsLiveFuelEstimator.forVehicle(light, null);
      final heavyE = GpsLiveFuelEstimator.forVehicle(heavy, null);
      for (var i = 0; i < 5; i++) {
        lightE.onSample(
            speedMps: 10.0 + i, prevSpeedMps: 9.0 + i, dtSeconds: 1);
        heavyE.onSample(
            speedMps: 10.0 + i, prevSpeedMps: 9.0 + i, dtSeconds: 1);
      }
      expect(heavyE.instantLPer100Km, greaterThan(lightE.instantLPer100Km!));
    });
  });

  group('GpsLiveFuelEstimator.onSample — flat cruise', () {
    test('steady cruise yields a stable, plausible instant figure', () {
      // A ~1500 kg default car at 90 km/h should land in a realistic
      // band (single-digit to low-teens L/100 km), well inside clamps.
      final e = _cruise(speedMps: 25, ticks: 15);
      final v = e.instantLPer100Km!;
      expect(v, greaterThan(GpsFuelEstimator.minLPer100Km));
      expect(v, lessThan(GpsFuelEstimator.maxLPer100Km));
      expect(v, inInclusiveRange(3.0, 14.0));
    });

    test('running average tracks the litres / distance integral', () {
      final e = _cruise(speedMps: 25, ticks: 20);
      const km = 25 * 20 / 1000.0; // 0.5 km
      final expected = e.litersSoFar / km * 100.0;
      expect(e.runningAvgLPer100Km, closeTo(expected, 0.001));
    });
  });

  group('GpsLiveFuelEstimator.onSample — acceleration low-pass', () {
    test('a single GPS speed spike is tamed by the 3-sample moving average',
        () {
      // Warm to a steady 10 m/s (window settles to ~0 accel), then feed
      // ONE jittery sample 10 → 13 m/s (+3 m/s², a GPS artifact). With
      // the 3-sample low-pass the prior window is [0,0], so the smoothed
      // accel is +3/3 = +1 m/s² — the spike's inertial punch is diluted
      // to a third before it can inflate the instant figure.
      final spiked = GpsLiveFuelEstimator.forVehicle(null, null);
      for (var i = 0; i < 5; i++) {
        spiked.onSample(speedMps: 10, prevSpeedMps: 10, dtSeconds: 1);
      }
      spiked.onSample(speedMps: 13, prevSpeedMps: 10, dtSeconds: 1);
      final spikedFigure = spiked.instantLPer100Km!;

      // A reference estimator whose window is FULLY saturated at the raw
      // +3 m/s² (no smoothing benefit) — speeds 7→10→13 each a +3 jump,
      // so by the last tick the window is [3,3,3] (smoothed +3) and the
      // evaluation speed is the same 13 m/s as the lone spike.
      final naive = GpsLiveFuelEstimator.forVehicle(null, null);
      naive.onSample(speedMps: 7, prevSpeedMps: 4, dtSeconds: 1);
      naive.onSample(speedMps: 10, prevSpeedMps: 7, dtSeconds: 1);
      naive.onSample(speedMps: 13, prevSpeedMps: 10, dtSeconds: 1);
      final naiveFigure = naive.instantLPer100Km!;

      // The diluted lone spike must read markedly lower than the
      // un-smoothed value, and must stay inside the plausibility band
      // (the smoothing kept it off the max clamp).
      expect(spikedFigure, lessThan(naiveFigure));
      expect(spikedFigure, lessThan(GpsFuelEstimator.maxLPer100Km));
    });

    test('accel term is symmetric — deceleration never adds tractive fuel',
        () {
      // Coasting down (speed dropping) gives negative inertia; force/
      // power floor at 0 so only idle fuel accrues — the instant figure
      // must not exceed a steady cruise at the same speed.
      final cruise = _cruise(speedMps: 20, ticks: 6);
      final coasting = GpsLiveFuelEstimator.forVehicle(null, null);
      var prev = 26.0;
      var cur = 20.0;
      for (var i = 0; i < 6; i++) {
        coasting.onSample(speedMps: cur, prevSpeedMps: prev, dtSeconds: 1);
        prev = cur;
        cur = (cur - 1).clamp(20.0, 26.0);
      }
      expect(coasting.instantLPer100Km, lessThanOrEqualTo(cruise.instantLPer100Km!));
    });
  });

  group('GpsLiveFuelEstimator.onSample — idle / no divide-by-zero', () {
    test('stationary sample yields a null instant figure (no div-by-zero)',
        () {
      final e = GpsLiveFuelEstimator.forVehicle(null, null);
      final r = e.onSample(speedMps: 0, prevSpeedMps: 0, dtSeconds: 1);
      expect(r, isNull);
      expect(e.instantLPer100Km, isNull);
      // Idle litres still accrue while parked + running.
      expect(e.litersSoFar, greaterThan(0));
    });

    test('idle-only litres match the petrol idle draw over time', () {
      final e = GpsLiveFuelEstimator.forVehicle(null, null);
      // 3600 s stationary @ petrol idle 0.7 L/h → ~0.7 L.
      for (var i = 0; i < 3600; i++) {
        e.onSample(speedMps: 0, prevSpeedMps: 0, dtSeconds: 1);
      }
      expect(e.litersSoFar, closeTo(0.7, 0.001));
      // No distance covered → running average undefined.
      expect(e.runningAvgLPer100Km, isNull);
    });

    test('a sub-threshold crawl is treated as stopped (null instant)', () {
      final e = GpsLiveFuelEstimator.forVehicle(null, null);
      final r = e.onSample(speedMps: 0.4, prevSpeedMps: 0.4, dtSeconds: 1);
      expect(r, isNull);
    });
  });

  group('GpsLiveFuelEstimator.onSample — grade gating', () {
    test('a confident uphill grade increases the instant figure', () {
      final flat = _cruise(speedMps: 20, ticks: 5);
      final uphill = GpsLiveFuelEstimator.forVehicle(null, null);
      for (var i = 0; i < 5; i++) {
        uphill.onSample(
          speedMps: 20,
          prevSpeedMps: 20,
          dtSeconds: 1,
          gradeFraction: 0.06, // 6 % climb
          gradeConfident: true,
        );
      }
      expect(uphill.instantLPer100Km, greaterThan(flat.instantLPer100Km!));
    });

    test('the same grade is ignored when gradeConfident is false', () {
      final flat = _cruise(speedMps: 20, ticks: 5);
      final ungated = GpsLiveFuelEstimator.forVehicle(null, null);
      for (var i = 0; i < 5; i++) {
        ungated.onSample(
          speedMps: 20,
          prevSpeedMps: 20,
          dtSeconds: 1,
          gradeFraction: 0.06,
          gradeConfident: false, // gated off
        );
      }
      expect(ungated.instantLPer100Km, closeTo(flat.instantLPer100Km!, 1e-9));
    });
  });

  group('GpsLiveFuelEstimator — clamping', () {
    test('an absurd uphill load is clamped to maxLPer100Km', () {
      // Brutal grade at very low speed → huge L/100 km that must clamp.
      final e = GpsLiveFuelEstimator.forVehicle(
        const VehicleProfile(
          id: 'x',
          name: 'x',
          curbWeightKg: 2000,
          preferredFuelType: 'petrol',
        ),
        null,
      );
      for (var i = 0; i < 5; i++) {
        e.onSample(
          speedMps: 1.0, // barely moving → tiny denominator
          prevSpeedMps: 1.0,
          dtSeconds: 1,
          gradeFraction: 0.40, // 40 % wall
          gradeConfident: true,
        );
      }
      expect(e.instantLPer100Km, GpsFuelEstimator.maxLPer100Km);
    });

    test('running average is clamped to the plausibility band', () {
      // Many seconds parked then one short moving tick → the litres/
      // distance ratio explodes, but the average must clamp to max.
      final e = GpsLiveFuelEstimator.forVehicle(null, null);
      for (var i = 0; i < 600; i++) {
        e.onSample(speedMps: 0, prevSpeedMps: 0, dtSeconds: 1);
      }
      e.onSample(speedMps: 1.0, prevSpeedMps: 0, dtSeconds: 1);
      expect(e.runningAvgLPer100Km, GpsFuelEstimator.maxLPer100Km);
    });
  });

  group('GpsLiveFuelEstimator — physicsScale application', () {
    test('a scale > 1 multiplies the instant figure proportionally', () {
      final base = _cruise(speedMps: 25, ticks: 8);
      final scaled = _cruise(
        matrix: const GpsCalibrationMatrix(physicsScale: 1.5),
        speedMps: 25,
        ticks: 8,
      );
      // Both well inside clamps, so the ratio is exactly the scale.
      expect(scaled.instantLPer100Km!,
          closeTo(base.instantLPer100Km! * 1.5, 1e-6));
    });

    test('a scale < 1 dampens the instant figure proportionally', () {
      final base = _cruise(speedMps: 25, ticks: 8);
      final scaled = _cruise(
        matrix: const GpsCalibrationMatrix(physicsScale: 0.8),
        speedMps: 25,
        ticks: 8,
      );
      expect(scaled.instantLPer100Km!,
          closeTo(base.instantLPer100Km! * 0.8, 1e-6));
    });

    test('the default matrix (scale 1.0) leaves the figure unchanged', () {
      final base = _cruise(speedMps: 25, ticks: 8);
      final defaulted = _cruise(
        matrix: const GpsCalibrationMatrix(),
        speedMps: 25,
        ticks: 8,
      );
      expect(defaulted.instantLPer100Km!,
          closeTo(base.instantLPer100Km!, 1e-9));
    });
  });
}
