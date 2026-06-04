// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/direct_fuel_rate_detector.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

/// Unit tests for the #2837 direct-fuel-rate detector — distinguishes a
/// car whose ECU streams FuelRateLPerHour (PID 5E / MAF) from one whose
/// consumption is modelled via the speed-density (η_v) path.
void main() {
  TripHistoryEntry trip(
    String id, {
    required String vehicleId,
    double? fuelLiters,
    double? veUsed,
  }) =>
      TripHistoryEntry(
        id: id,
        vehicleId: vehicleId,
        summary: TripSummary(
          distanceKm: 50,
          maxRpm: 3000,
          highRpmSeconds: 0,
          idleSeconds: 0,
          harshBrakes: 0,
          harshAccelerations: 0,
          fuelLitersConsumed: fuelLiters,
          volumetricEfficiencyUsed: veUsed,
        ),
      );

  test('two PID-5E trips (fuel, no η_v stamp) → reports direct fuel rate',
      () {
    final trips = [
      trip('a', vehicleId: 'v1', fuelLiters: 3.3),
      trip('b', vehicleId: 'v1', fuelLiters: 3.5),
    ];
    expect(
      vehicleReportsDirectFuelRate(trips, vehicleId: 'v1'),
      isTrue,
    );
  });

  test('speed-density trips (η_v stamped) → NOT direct fuel rate', () {
    final trips = [
      trip('a', vehicleId: 'v1', fuelLiters: 3.3, veUsed: 0.85),
      trip('b', vehicleId: 'v1', fuelLiters: 3.5, veUsed: 0.86),
    ];
    expect(
      vehicleReportsDirectFuelRate(trips, vehicleId: 'v1'),
      isFalse,
    );
  });

  test('a single direct trip is not enough (fluke guard)', () {
    final trips = [
      trip('a', vehicleId: 'v1', fuelLiters: 3.3), // direct
      trip('b', vehicleId: 'v1', fuelLiters: 3.5, veUsed: 0.85), // modelled
    ];
    expect(
      vehicleReportsDirectFuelRate(trips, vehicleId: 'v1'),
      isFalse,
    );
  });

  test('fuel-less trips (GPS-only / no PID) never count as direct', () {
    final trips = [
      trip('a', vehicleId: 'v1', fuelLiters: null),
      trip('b', vehicleId: 'v1', fuelLiters: null),
    ];
    expect(
      vehicleReportsDirectFuelRate(trips, vehicleId: 'v1'),
      isFalse,
    );
  });

  test('only the named vehicle\'s trips count', () {
    final trips = [
      trip('a', vehicleId: 'other', fuelLiters: 3.3),
      trip('b', vehicleId: 'other', fuelLiters: 3.5),
      trip('c', vehicleId: 'v1', fuelLiters: 3.4),
    ];
    expect(
      vehicleReportsDirectFuelRate(trips, vehicleId: 'v1'),
      isFalse,
      reason: 'v1 has only one direct trip; the other vehicle\'s do not count',
    );
  });
}
