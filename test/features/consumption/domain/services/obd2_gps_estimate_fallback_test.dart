// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/services/obd2_gps_estimate_fallback.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';

/// #2431 — the OBD2 GPS-estimate fallback. When an adapter+ECU supported
/// no fuel PID (every captured sample's `fuelRateLPerHour` is null), this
/// service reconstructs the trip's consumption from the GPS-physics
/// road-load estimate and stamps a per-sample estimated fuel-rate series,
/// while leaving trips that DID get a real fuel signal untouched.

/// A steady ~90 km/h cruise of [n] samples at 1 s spacing, all with a
/// null measured fuel rate (the no-fuel-PID case).
List<TripSample> _gpsOnlyCruise(int n, {double speedKmh = 90}) => [
      for (var i = 0; i < n; i++)
        TripSample(
          timestamp: DateTime.utc(2026, 4, 22, 10).add(Duration(seconds: i)),
          speedKmh: speedKmh,
          rpm: 2000,
          latitude: 48.0 + i * 0.0001,
          longitude: 2.0 + i * 0.0001,
        ),
    ];

TripSummary _blankSummary() => TripSummary(
      distanceKm: 2.5,
      maxRpm: 3000,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: 0,
      harshAccelerations: 0,
      startedAt: DateTime.utc(2026, 4, 22, 10),
      endedAt: DateTime.utc(2026, 4, 22, 10, 1),
    );

void main() {
  const petrolCar = VehicleProfile(
    id: 'p',
    name: 'petrol',
    curbWeightKg: 1500,
    preferredFuelType: 'petrol',
  );

  group('fillWhenNoFuelPid — no fuel PID was ever seen', () {
    test('back-fills avg + litres and stamps a per-sample estimate', () {
      final filled = Obd2GpsEstimateFallback.fillWhenNoFuelPid(
        summary: _blankSummary(),
        samples: _gpsOnlyCruise(20),
        vehicle: petrolCar,
      );
      // Trip-level fields are filled from the estimate.
      expect(filled.summary.avgLPer100Km, isNotNull);
      expect(filled.summary.avgLPer100Km, greaterThan(0));
      expect(filled.summary.fuelLitersConsumed, isNotNull);
      expect(filled.summary.fuelLitersConsumed, greaterThan(0));
      // At least one sample carries the estimated series; the measured
      // field stays null (never overwritten).
      final est = filled.samples
          .where((s) => s.estimatedFuelRateLPerHour != null)
          .toList();
      expect(est, isNotEmpty);
      expect(
        filled.samples.every((s) => s.fuelRateLPerHour == null),
        isTrue,
      );
      // The estimated L/h ≈ avg L/100 km / 100 × speed.
      final s = est.first;
      final expectedLPerH =
          filled.summary.avgLPer100Km! / 100.0 * s.speedKmh;
      // Instant differs slightly from the running average; just assert
      // the series is a plausible same-order-of-magnitude L/h figure.
      expect(s.estimatedFuelRateLPerHour, greaterThan(0));
      expect(s.estimatedFuelRateLPerHour, lessThan(expectedLPerH * 5));
    });

    test('returns null estimate (originals) for a single sample', () {
      final summary = _blankSummary();
      final filled = Obd2GpsEstimateFallback.fillWhenNoFuelPid(
        summary: summary,
        samples: _gpsOnlyCruise(1),
        vehicle: petrolCar,
      );
      expect(filled.summary.avgLPer100Km, isNull);
      expect(filled.summary.fuelLitersConsumed, isNull);
    });
  });

  group('fillWhenNoFuelPid — a real fuel signal WAS seen', () {
    test('leaves a summary with measured litres untouched', () {
      final measured = _blankSummary().copyWith(
        avgLPer100Km: 6.2,
        fuelLitersConsumed: 0.155,
      );
      final filled = Obd2GpsEstimateFallback.fillWhenNoFuelPid(
        summary: measured,
        samples: _gpsOnlyCruise(20),
        vehicle: petrolCar,
      );
      expect(filled.summary.avgLPer100Km, 6.2);
      expect(filled.summary.fuelLitersConsumed, 0.155);
      // No per-sample estimate is stamped — samples are returned as-is.
      expect(
        filled.samples.every((s) => s.estimatedFuelRateLPerHour == null),
        isTrue,
      );
    });

    test('leaves samples with a measured fuel rate untouched', () {
      // Blank summary (recorder left litres null) but a sample DID carry a
      // real fuel rate → still treated as measured, no estimate override.
      final samples = [
        ..._gpsOnlyCruise(5),
        TripSample(
          timestamp: DateTime.utc(2026, 4, 22, 10, 0, 6),
          speedKmh: 90,
          rpm: 2000,
          fuelRateLPerHour: 5.5,
        ),
      ];
      final filled = Obd2GpsEstimateFallback.fillWhenNoFuelPid(
        summary: _blankSummary(),
        samples: samples,
        vehicle: petrolCar,
      );
      expect(filled.summary.avgLPer100Km, isNull);
      expect(filled.summary.fuelLitersConsumed, isNull);
      expect(
        filled.samples.every((s) => s.estimatedFuelRateLPerHour == null),
        isTrue,
      );
    });
  });

  group('E85 litres differ from petrol by the LHV factor (#2431)', () {
    test('E85 trip estimates ~25 % more litres than petrol', () {
      const e85Car = VehicleProfile(
        id: 'e',
        name: 'flex',
        curbWeightKg: 1500,
        preferredFuelType: 'E85',
      );
      final petrol = Obd2GpsEstimateFallback.estimate(
        samples: _gpsOnlyCruise(30),
        vehicle: petrolCar,
      );
      final e85 = Obd2GpsEstimateFallback.estimate(
        samples: _gpsOnlyCruise(30),
        vehicle: e85Car,
      );
      expect(petrol, isNotNull);
      expect(e85, isNotNull);
      expect(e85!.fuelLitersConsumed,
          greaterThan(petrol!.fuelLitersConsumed));
      // Same physics, same speed/distance → the litres ratio tracks the
      // LHV ratio (petrol 31.9 / E85 25.6 ≈ 1.246).
      final ratio = e85.fuelLitersConsumed / petrol.fuelLitersConsumed;
      expect(ratio, closeTo(31.9 / 25.6, 0.1));
    });
  });
}
