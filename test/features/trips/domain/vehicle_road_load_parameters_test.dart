// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4209 — the road-load parameter set: its fallback hierarchy and
// provenance, the shipped values (unchanged by the extraction), and the
// estimator's sensitivity to mass, drag, rolling resistance, grade and
// acceleration.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/trips/domain/services/gps_live_fuel_estimator.dart';
import 'package:tankstellen/features/trips/domain/vehicle_road_load_parameters.dart';

void main() {
  group('fallback hierarchy and provenance', () {
    test('no curb weight → generic default, low confidence', () {
      final p = VehicleRoadLoadParameters.resolve();
      expect(
          [p.massKg, p.dragCoefficient, p.frontalAreaM2, p.rollingResistance],
          [1500, 0.32, 2.30, 0.012]);
      expect(p.massSource, RoadLoadParameterSource.genericDefault);
      expect(p.bodySource, RoadLoadParameterSource.genericDefault);
      expect(p.confidence, RoadLoadConfidence.low);
    });

    test('a curb weight is the vehicle mass; body terms stay a class prior',
        () {
      final p = VehicleRoadLoadParameters.resolve(curbWeightKg: 1200);
      expect(p.massKg, 1200);
      expect(p.massSource, RoadLoadParameterSource.vehicle);
      expect(p.bodySource, RoadLoadParameterSource.vehicleClassPrior,
          reason: 'no Cd/Crr is ever claimed as measured');
      expect(p.confidence, RoadLoadConfidence.medium);
    });

    test('class buckets and their bounds', () {
      VehicleRoadLoadParameters at(int kg) =>
          VehicleRoadLoadParameters.resolve(curbWeightKg: kg);
      expect(at(1450).frontalAreaM2, 2.15, reason: 'compact up to 1450');
      expect(at(1451).frontalAreaM2, 2.25, reason: 'midsize above');
      expect(at(1750).frontalAreaM2, 2.25);
      final suv = at(1751);
      expect([suv.dragCoefficient, suv.frontalAreaM2, suv.rollingResistance],
          [0.38, 2.80, 0.013]);
    });

    test('fuel basis', () {
      String basis(String? f) =>
          VehicleRoadLoadParameters.resolve(preferredFuelType: f).fuelBasis;
      expect(basis('dieselPremium'), 'diesel');
      expect(basis('E85'), 'e85');
      expect(basis('Autogas'), 'lpg');
      expect(basis('super'), 'petrol');
      expect(basis(null), 'petrol');
      final diesel =
          VehicleRoadLoadParameters.resolve(preferredFuelType: 'diesel');
      expect([diesel.lowerHeatingValueMjPerL, diesel.engineEfficiency,
          diesel.idleLitersPerHour], [35.8, 0.34, 0.5]);
    });

    test('the trace carries every value with provenance and version', () {
      final t = VehicleRoadLoadParameters.resolve(curbWeightKg: 1200).toTrace();
      expect(t['version'], VehicleRoadLoadParameters.version);
      expect(t['massSource'], 'vehicle');
      expect(t['bodySource'], 'vehicleClassPrior');
      expect(t['confidence'], 'medium');
      expect(VehicleRoadLoadParameters.resolve().cdA, closeTo(0.32 * 2.30, 1e-12));
    });
  });

  group('the estimator uses exactly this set', () {
    test('forVehicle == withParameters(resolve(...)) — no behaviour change',
        () {
      const v = VehicleProfile(
          id: 'v', name: 'x', curbWeightKg: 1600, preferredFuelType: 'diesel');
      final a = GpsLiveFuelEstimator.forVehicle(v, null);
      final b = GpsLiveFuelEstimator.withParameters(
          VehicleRoadLoadParameters.resolve(
              curbWeightKg: 1600, preferredFuelType: 'diesel'));
      for (final e in [a, b]) {
        var prev = 20.0;
        for (var i = 0; i < 30; i++) {
          e.onSample(speedMps: 20, prevSpeedMps: prev, dtSeconds: 1);
          prev = 20;
        }
      }
      expect(a.litersSoFar, b.litersSoFar);
      expect(a.parameters.fuelBasis, 'diesel');
    });
  });

  group('sensitivity', () {
    final base = VehicleRoadLoadParameters.resolve(curbWeightKg: 1500);

    double litres(VehicleRoadLoadParameters p,
        {double speed = 25,
        double accelPerS = 0,
        double grade = 0,
        bool confident = false}) {
      final e = GpsLiveFuelEstimator.withParameters(p);
      var prev = speed;
      for (var i = 0; i < 60; i++) {
        final v = speed + accelPerS * i;
        e.onSample(
            speedMps: v,
            prevSpeedMps: prev,
            dtSeconds: 1,
            gradeFraction: grade,
            gradeConfident: confident);
        prev = v;
      }
      return e.litersSoFar;
    }

    test('more mass costs more fuel', () {
      expect(litres(base.copyWith(massKg: 2000)), greaterThan(litres(base)));
    });

    test('more drag costs more, and the cost grows with speed', () {
      double extra(double speed) =>
          litres(base.copyWith(dragCoefficient: 0.40), speed: speed) -
          litres(base, speed: speed);
      expect(extra(10), greaterThan(0));
      expect(extra(35), greaterThan(extra(10)));
    });

    test('more rolling resistance costs more fuel', () {
      expect(litres(base.copyWith(rollingResistance: 0.015)),
          greaterThan(litres(base)));
    });

    test('a climb costs fuel only when the grade is confident', () {
      expect(litres(base, grade: 0.05, confident: true),
          greaterThan(litres(base)));
      expect(litres(base, grade: 0.05), litres(base),
          reason: 'an unconfident grade is not a condition input');
    });

    test('accelerating costs more than cruising at the start speed', () {
      expect(litres(base, speed: 10, accelPerS: 0.3),
          greaterThan(litres(base, speed: 10)));
    });
  });
}
