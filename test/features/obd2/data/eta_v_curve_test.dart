// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/fuel_rate_estimator.dart';
import 'package:tankstellen/features/vehicle/domain/entities/reference_vehicle.dart';

/// Tests for the #1625 per-RPM volumetric-efficiency curve: the
/// `etaVCurveFor` per-class resolver, `interpolateEtaV`, and the
/// estimator's use of the curve (with the flat-η_v fallback).
void main() {
  ReferenceVehicle vehicle({
    InductionType induction = InductionType.naturallyAspirated,
    bool di = false,
    bool atkinson = false,
  }) =>
      ReferenceVehicle(
        make: 'Make',
        model: 'Model',
        generation: 'I',
        yearStart: 2020,
        displacementCc: 1600,
        fuelType: 'petrol',
        transmission: 'manual',
        inductionType: induction,
        directInjection: di,
        atkinsonCycle: atkinson,
      );

  group('etaVCurveFor', () {
    test('returns a 3-point curve anchored on the class cruise η_v', () {
      final v = vehicle(); // NA, port injection → cruise 0.85
      final curve = etaVCurveFor(v);

      expect(curve, hasLength(3));
      expect(curve.map((p) => p.rpm), [1000, 2500, 5000]);
      // The 2500-rpm anchor equals the flat #1422 cruise default.
      expect(curve[1].etaV, closeTo(defaultVolumetricEfficiency(v), 1e-9));
      // Low rpm tapers down, high rpm tapers slightly down.
      expect(curve[0].etaV, lessThan(curve[1].etaV));
      expect(curve[2].etaV, lessThan(curve[1].etaV));
      expect(curve[0].etaV, closeTo(0.85 * 0.92, 1e-9));
      expect(curve[2].etaV, closeTo(0.85 * 0.96, 1e-9));
    });

    test('the cruise anchor is per engine class', () {
      // Each class anchors on its own defaultVolumetricEfficiency.
      for (final v in [
        vehicle(), // 0.85
        vehicle(di: true), // NA + DI → 0.88
        vehicle(induction: InductionType.turbocharged, di: true), // 0.93
        vehicle(induction: InductionType.vnt), // 0.95
        vehicle(atkinson: true), // 0.70
      ]) {
        expect(etaVCurveFor(v)[1].etaV,
            closeTo(defaultVolumetricEfficiency(v), 1e-9));
      }
    });
  });

  group('interpolateEtaV', () {
    final curve = etaVCurveFor(vehicle()); // [1000:0.782, 2500:0.85, 5000:0.816]

    test('an empty curve returns null (caller falls back to flat η_v)', () {
      expect(interpolateEtaV(const [], 2000), isNull);
    });

    test('clamps below the first point and above the last', () {
      expect(interpolateEtaV(curve, 500), closeTo(curve.first.etaV, 1e-9));
      expect(interpolateEtaV(curve, 9000), closeTo(curve.last.etaV, 1e-9));
    });

    test('returns the exact value at an exact point', () {
      expect(interpolateEtaV(curve, 2500), closeTo(0.85, 1e-9));
    });

    test('linearly interpolates between two points', () {
      // Midway between 1000 rpm (0.782) and 2500 rpm (0.85).
      expect(interpolateEtaV(curve, 1750),
          closeTo((0.782 + 0.85) / 2, 1e-9));
    });
  });

  group('estimateFuelRateLPerHourFromMap with an η_v curve', () {
    const args = (
      mapKpa: 60.0,
      iatCelsius: 25.0,
      engineDisplacementCc: 1600,
      volumetricEfficiency: 0.85,
    );

    test('at the cruise anchor RPM the curve matches the flat call', () {
      final curve = etaVCurveFor(vehicle()); // 2500-rpm point == 0.85
      final flat = estimateFuelRateLPerHourFromMap(
        mapKpa: args.mapKpa,
        iatCelsius: args.iatCelsius,
        rpm: 2500,
        engineDisplacementCc: args.engineDisplacementCc,
        volumetricEfficiency: args.volumetricEfficiency,
      );
      final shaped = estimateFuelRateLPerHourFromMap(
        mapKpa: args.mapKpa,
        iatCelsius: args.iatCelsius,
        rpm: 2500,
        engineDisplacementCc: args.engineDisplacementCc,
        volumetricEfficiency: args.volumetricEfficiency,
        etaVCurve: curve,
      );
      expect(shaped, closeTo(flat!, 1e-9));
    });

    test('at low RPM the curve lowers the rate vs the flat η_v', () {
      final flat = estimateFuelRateLPerHourFromMap(
        mapKpa: args.mapKpa,
        iatCelsius: args.iatCelsius,
        rpm: 1000,
        engineDisplacementCc: args.engineDisplacementCc,
        volumetricEfficiency: args.volumetricEfficiency,
      )!;
      final shaped = estimateFuelRateLPerHourFromMap(
        mapKpa: args.mapKpa,
        iatCelsius: args.iatCelsius,
        rpm: 1000,
        engineDisplacementCc: args.engineDisplacementCc,
        volumetricEfficiency: args.volumetricEfficiency,
        etaVCurve: etaVCurveFor(vehicle()),
      )!;
      // 1000-rpm η_v is 0.92× the flat value → proportionally lower.
      expect(shaped, closeTo(flat * 0.92, 1e-9));
    });

    test('an empty curve is identical to the no-curve call', () {
      final flat = estimateFuelRateLPerHourFromMap(
        mapKpa: args.mapKpa,
        iatCelsius: args.iatCelsius,
        rpm: 3000,
        engineDisplacementCc: args.engineDisplacementCc,
        volumetricEfficiency: args.volumetricEfficiency,
      );
      final empty = estimateFuelRateLPerHourFromMap(
        mapKpa: args.mapKpa,
        iatCelsius: args.iatCelsius,
        rpm: 3000,
        engineDisplacementCc: args.engineDisplacementCc,
        volumetricEfficiency: args.volumetricEfficiency,
        etaVCurve: const [],
      );
      expect(empty, equals(flat));
    });
  });
}
