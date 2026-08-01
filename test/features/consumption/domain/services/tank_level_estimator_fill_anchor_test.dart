// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/domain/services/tank_level_estimator.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

/// #3645 — the estimator prefers the fill-anchored (tank-to-tank)
/// average over the trip aggregate, and a partial fill anchors on the
/// OBD2-measured after-level when the sensor captured one.
///
/// Fixture idiom mirrors tank_level_estimator_test.dart.
void main() {
  const vehicle = VehicleProfile(
    id: 'v1',
    name: 'Test Car',
    type: VehicleType.combustion,
    tankCapacityL: 50,
  );

  var idCounter = 0;
  FillUp fill({
    required DateTime date,
    required double liters,
    required double odometerKm,
    bool isFullTank = true,
    double? fuelLevelAfterL,
  }) {
    return FillUp(
      id: 'f${idCounter++}',
      date: date,
      liters: liters,
      totalCost: liters * 1.8,
      odometerKm: odometerKm,
      fuelType: FuelType.diesel,
      vehicleId: 'v1',
      isFullTank: isFullTank,
      fuelLevelAfterL: fuelLevelAfterL,
    );
  }

  TripHistoryEntry trip({
    required String id,
    required DateTime startedAt,
    required double distanceKm,
    double? fuelLitersConsumed,
  }) {
    return TripHistoryEntry(
      id: id,
      vehicleId: 'v1',
      summary: TripSummary(
        distanceKm: distanceKm,
        maxRpm: 0,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        fuelLitersConsumed: fuelLitersConsumed,
        startedAt: startedAt,
      ),
    );
  }

  group('#3645 — fill-anchored average preferred for decay and range', () {
    test(
      'tank-to-tank truth (6.0) beats the recorded-trip aggregate (12.0): '
      'unmeasured-trip decay and range both use the pump-derived figure',
      () {
        // History: two full fills 500 km apart, 30 L pumped → TRUE 6.0.
        // Trips paint a very different picture (12.0 measured) — e.g. the
        // adapter only ever recorded the city errands, never the commute.
        final fillUps = [
          // newest first, like the provider hands them over
          fill(date: DateTime(2026, 4, 10), liters: 30, odometerKm: 100500),
          fill(date: DateTime(2026, 4, 1), liters: 45, odometerKm: 100000),
        ];
        final trips = [
          // Before the last fill: feeds ONLY the trip aggregate.
          trip(
            id: 't-old',
            startedAt: DateTime(2026, 4, 5),
            distanceKm: 50,
            fuelLitersConsumed: 6, // 12.0 L/100 km recorded average
          ),
          // After the last fill: unmeasured → decays via the avg.
          trip(
            id: 't-new',
            startedAt: DateTime(2026, 4, 11),
            distanceKm: 100,
          ),
        ];

        final estimate = estimateTankLevel(
          vehicle: vehicle,
          fillUps: fillUps,
          trips: trips,
        );

        // Decay for the 100 unmeasured km must use 6.0 (tank-to-tank),
        // not 12.0 (trip aggregate): 50 - 6 = 44 L.
        expect(estimate.levelL, closeTo(44.0, 0.01));
        // Range from the same physically-derived figure.
        expect(estimate.rangeKm, closeTo(44.0 / 6.0 * 100.0, 0.1));
      },
    );

    test(
      'no valid tank-to-tank window (odometer never moved) → falls back '
      'to the trip aggregate exactly as before',
      () {
        final fillUps = [
          fill(date: DateTime(2026, 4, 10), liters: 30, odometerKm: 100000),
          fill(date: DateTime(2026, 4, 1), liters: 45, odometerKm: 100000),
        ];
        final trips = [
          trip(
            id: 't-old',
            startedAt: DateTime(2026, 4, 5),
            distanceKm: 50,
            fuelLitersConsumed: 5, // 10.0 recorded average
          ),
          trip(id: 't-new', startedAt: DateTime(2026, 4, 11), distanceKm: 100),
        ];

        final estimate = estimateTankLevel(
          vehicle: vehicle,
          fillUps: fillUps,
          trips: trips,
        );

        // 50 - (100 km × 10.0/100) = 40 L — unchanged legacy behaviour.
        expect(estimate.levelL, closeTo(40.0, 0.01));
      },
    );

    test('measured OBD2 trip litres still win over ANY average', () {
      final fillUps = [
        fill(date: DateTime(2026, 4, 10), liters: 30, odometerKm: 100500),
        fill(date: DateTime(2026, 4, 1), liters: 45, odometerKm: 100000),
      ];
      final trips = [
        trip(
          id: 't-measured',
          startedAt: DateTime(2026, 4, 11),
          distanceKm: 100,
          fuelLitersConsumed: 9.5, // the integrator's own figure
        ),
      ];

      final estimate = estimateTankLevel(
        vehicle: vehicle,
        fillUps: fillUps,
        trips: trips,
      );

      expect(estimate.levelL, closeTo(50.0 - 9.5, 0.01));
    });
  });

  group('#3645 — partial fill anchors on the OBD2-measured after-level', () {
    test(
      'partial with a sensor reading: the car\'s own gauge beats the '
      'walk-back simulation',
      () {
        // Walk-back would say: full 50 − 7 L trip + 10 L partial = 53 → 50.
        // The sensor read 41 L after the pump — trust the car.
        final fillUps = [
          fill(
            date: DateTime(2026, 4, 8),
            liters: 10,
            odometerKm: 100300,
            isFullTank: false,
            fuelLevelAfterL: 41,
          ),
          fill(date: DateTime(2026, 4, 1), liters: 45, odometerKm: 100000),
        ];
        final trips = [
          trip(
            id: 't-between',
            startedAt: DateTime(2026, 4, 4),
            distanceKm: 100,
            fuelLitersConsumed: 7,
          ),
        ];

        final estimate = estimateTankLevel(
          vehicle: vehicle,
          fillUps: fillUps,
          trips: trips,
        );

        expect(estimate.levelL, closeTo(41.0, 0.01));
      },
    );

    test('a sensor reading above capacity is clamped, never advertised', () {
      final fillUps = [
        fill(
          date: DateTime(2026, 4, 8),
          liters: 10,
          odometerKm: 100300,
          isFullTank: false,
          fuelLevelAfterL: 55, // sensor glitch above the 50 L tank
        ),
        fill(date: DateTime(2026, 4, 1), liters: 45, odometerKm: 100000),
      ];

      final estimate = estimateTankLevel(
        vehicle: vehicle,
        fillUps: fillUps,
        trips: const [],
      );

      expect(estimate.levelL, closeTo(50.0, 0.01));
    });

    test('partial WITHOUT a sensor reading keeps the #1360 walk-back', () {
      final fillUps = [
        fill(
          date: DateTime(2026, 4, 8),
          liters: 10,
          odometerKm: 100300,
          isFullTank: false,
        ),
        fill(date: DateTime(2026, 4, 1), liters: 45, odometerKm: 100000),
      ];
      final trips = [
        trip(
          id: 't-between',
          startedAt: DateTime(2026, 4, 4),
          distanceKm: 100,
          fuelLitersConsumed: 7,
        ),
      ];

      final estimate = estimateTankLevel(
        vehicle: vehicle,
        fillUps: fillUps,
        trips: trips,
      );

      // 50 − 7 + 10 clamped to capacity = 50 (legacy behaviour).
      expect(estimate.levelL, closeTo(50.0, 0.01));
    });

    test('a FULL fill keeps the capacity convention even with a sensor '
        'reading present', () {
      final fillUps = [
        fill(
          date: DateTime(2026, 4, 8),
          liters: 42,
          odometerKm: 100500,
          fuelLevelAfterL: 46, // percent-derived sensor under-reads
        ),
        fill(date: DateTime(2026, 4, 1), liters: 45, odometerKm: 100000),
      ];

      final estimate = estimateTankLevel(
        vehicle: vehicle,
        fillUps: fillUps,
        trips: const [],
      );

      // "Full" is the user's physical statement at the pump — capacity
      // wins over a percent-derived sensor estimate.
      expect(estimate.levelL, closeTo(50.0, 0.01));
    });
  });
}
