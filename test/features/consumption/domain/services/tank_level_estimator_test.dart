import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/domain/services/tank_level_estimator.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';

/// Pure unit tests for [estimateTankLevel] (#1195).
///
/// Synthetic fixtures only — no test/fixtures import — so the
/// estimator's contract stays self-contained and obvious. Each test
/// pins one branch of the consumption / clamping / method-derivation
/// logic.
void main() {
  // 50 L combustion vehicle with no calibrated avg L/100 km — the
  // estimator falls back to its hard-coded 7.0 L/100 km default.
  const vehicle = VehicleProfile(
    id: 'v1',
    name: 'Test Car',
    type: VehicleType.combustion,
    tankCapacityL: 50,
  );

  final lastFillUp = FillUp(
    id: 'f1',
    date: DateTime(2026, 4, 1, 8),
    liters: 45,
    totalCost: 80,
    odometerKm: 100000,
    fuelType: FuelType.diesel,
    vehicleId: 'v1',
  );

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

  group('estimateTankLevel — bookkeeping', () {
    test('no fill-ups returns the unknown sentinel', () {
      final result = estimateTankLevel(
        vehicle: vehicle,
        fillUps: const [],
        trips: const [],
      );

      expect(result.hasFillUp, isFalse);
      expect(result.lastFillUpDate, isNull);
      expect(result.levelL, 0);
    });

    test('one fill-up + zero trips → level == capacity, method = obd2', () {
      final result = estimateTankLevel(
        vehicle: vehicle,
        fillUps: [lastFillUp],
        trips: const [],
      );

      expect(result.levelL, 50);
      expect(result.capacityL, 50);
      expect(result.tripsSince, 0);
      // Vacuously OBD2 — no fallback was invoked.
      expect(result.method, TankLevelEstimationMethod.obd2);
    });

    test('lastFillUpDate echoes the head fill-up', () {
      final result = estimateTankLevel(
        vehicle: vehicle,
        fillUps: [lastFillUp],
        trips: const [],
      );

      expect(result.lastFillUpDate, lastFillUp.date);
    });
  });

  group('estimateTankLevel — OBD2 path', () {
    test('subtracts fuelLitersConsumed exactly when every trip carries it', () {
      final trips = [
        trip(
          id: 't1',
          startedAt: DateTime(2026, 4, 1, 9),
          distanceKm: 30,
          fuelLitersConsumed: 2.5,
        ),
        trip(
          id: 't2',
          startedAt: DateTime(2026, 4, 1, 10),
          distanceKm: 40,
          fuelLitersConsumed: 3.0,
        ),
      ];

      final result = estimateTankLevel(
        vehicle: vehicle,
        fillUps: [lastFillUp],
        trips: trips,
      );

      // 50 - 2.5 - 3.0 = 44.5
      expect(result.levelL, closeTo(44.5, 0.001));
      expect(result.method, TankLevelEstimationMethod.obd2);
      expect(result.tripsSince, 2);
    });
  });

  group('estimateTankLevel — distance fallback', () {
    test('uses distanceKm × 7.0 / 100 when fuelLitersConsumed is null', () {
      // 50 km × 7.0 / 100 = 3.5 L
      final trips = [
        trip(
          id: 't1',
          startedAt: DateTime(2026, 4, 1, 9),
          distanceKm: 50,
        ),
      ];

      final result = estimateTankLevel(
        vehicle: vehicle,
        fillUps: [lastFillUp],
        trips: trips,
      );

      expect(result.levelL, closeTo(46.5, 0.001));
      expect(result.method, TankLevelEstimationMethod.distanceFallback);
      expect(result.tripsSince, 1);
    });

    test('all distance-only trips → method = distanceFallback', () {
      final trips = [
        trip(
          id: 't1',
          startedAt: DateTime(2026, 4, 1, 9),
          distanceKm: 20,
        ),
        trip(
          id: 't2',
          startedAt: DateTime(2026, 4, 1, 10),
          distanceKm: 30,
        ),
      ];

      final result = estimateTankLevel(
        vehicle: vehicle,
        fillUps: [lastFillUp],
        trips: trips,
      );

      // (20 + 30) × 7.0 / 100 = 3.5 L consumed
      expect(result.levelL, closeTo(46.5, 0.001));
      expect(result.method, TankLevelEstimationMethod.distanceFallback);
    });
  });

  group('estimateTankLevel — mixed', () {
    test('one OBD2 + one fallback → method = mixed', () {
      final trips = [
        trip(
          id: 't1',
          startedAt: DateTime(2026, 4, 1, 9),
          distanceKm: 30,
          fuelLitersConsumed: 2.5,
        ),
        trip(
          id: 't2',
          startedAt: DateTime(2026, 4, 1, 10),
          distanceKm: 40,
        ),
      ];

      final result = estimateTankLevel(
        vehicle: vehicle,
        fillUps: [lastFillUp],
        trips: trips,
      );

      // 50 - 2.5 - (40 × 7.0 / 100) = 50 - 2.5 - 2.8 = 44.7
      expect(result.levelL, closeTo(44.7, 0.001));
      expect(result.method, TankLevelEstimationMethod.mixed);
    });
  });

  group('estimateTankLevel — filtering', () {
    test('trips before lastFillUp are excluded', () {
      final trips = [
        trip(
          id: 't-old',
          startedAt: DateTime(2026, 3, 28),
          distanceKm: 100,
          fuelLitersConsumed: 8,
        ),
        trip(
          id: 't-new',
          startedAt: DateTime(2026, 4, 1, 12),
          distanceKm: 30,
          fuelLitersConsumed: 2,
        ),
      ];

      final result = estimateTankLevel(
        vehicle: vehicle,
        fillUps: [lastFillUp],
        trips: trips,
      );

      // Only the new trip counts: 50 - 2 = 48.
      expect(result.levelL, closeTo(48, 0.001));
      expect(result.tripsSince, 1);
    });

    test('trips with startedAt == null are excluded', () {
      const tripWithoutStart = TripHistoryEntry(
        id: 't-null',
        vehicleId: 'v1',
        summary: TripSummary(
          distanceKm: 50,
          maxRpm: 0,
          highRpmSeconds: 0,
          idleSeconds: 0,
          harshBrakes: 0,
          harshAccelerations: 0,
          fuelLitersConsumed: 5,
          // startedAt intentionally omitted.
        ),
      );

      final result = estimateTankLevel(
        vehicle: vehicle,
        fillUps: [lastFillUp],
        trips: [tripWithoutStart],
      );

      expect(result.levelL, 50);
      expect(result.tripsSince, 0);
    });
  });

  group('estimateTankLevel — clamping', () {
    test('level clamps to 0 when consumption exceeds capacity', () {
      // 1000 km × 7.0 / 100 = 70 L → would be 50 - 70 = -20 without clamp.
      final trips = [
        trip(
          id: 't1',
          startedAt: DateTime(2026, 4, 1, 9),
          distanceKm: 1000,
        ),
      ];

      final result = estimateTankLevel(
        vehicle: vehicle,
        fillUps: [lastFillUp],
        trips: trips,
      );

      expect(result.levelL, 0);
    });

    test('level clamps to capacity when consumption is negative', () {
      // Defensive: negative fuelLitersConsumed shouldn't happen, but
      // would otherwise leave the level above capacity. Clamping kicks
      // in to keep the answer honest.
      final trips = [
        trip(
          id: 't1',
          startedAt: DateTime(2026, 4, 1, 9),
          distanceKm: 10,
          fuelLitersConsumed: -5,
        ),
      ];

      final result = estimateTankLevel(
        vehicle: vehicle,
        fillUps: [lastFillUp],
        trips: trips,
      );

      expect(result.levelL, 50);
    });
  });

  group('estimateTankLevel — range', () {
    test('rangeKm equals levelL / 7.0 × 100 with the default avg', () {
      final result = estimateTankLevel(
        vehicle: vehicle,
        fillUps: [lastFillUp],
        trips: const [],
      );

      // levelL = 50, avg = 7.0 → 50 / 7.0 × 100 ≈ 714.3 km
      expect(result.rangeKm, closeTo(714.2857, 0.01));
    });

    test('rangeKm responds to consumption — half tank = ~half range', () {
      final trips = [
        trip(
          id: 't1',
          startedAt: DateTime(2026, 4, 1, 9),
          distanceKm: 100,
          fuelLitersConsumed: 25,
        ),
      ];

      final result = estimateTankLevel(
        vehicle: vehicle,
        fillUps: [lastFillUp],
        trips: trips,
      );

      // levelL = 25 → 25 / 7.0 × 100 ≈ 357.1 km
      expect(result.rangeKm, closeTo(357.142, 0.01));
    });
  });

  group('estimateTankLevel — vehicle without tankCapacityL', () {
    test('falls back to lastFillUp.liters as start level', () {
      const vehicleNoCap = VehicleProfile(
        id: 'v2',
        name: 'No-cap',
        type: VehicleType.combustion,
      );

      final result = estimateTankLevel(
        vehicle: vehicleNoCap,
        fillUps: [lastFillUp],
        trips: const [],
      );

      // Last fill-up's liters (45) becomes the start level when no
      // capacity is configured.
      expect(result.levelL, 45);
      expect(result.capacityL, isNull);
    });

    test('upper clamp is infinite — negative consumption keeps adding up', () {
      const vehicleNoCap = VehicleProfile(
        id: 'v2',
        name: 'No-cap',
        type: VehicleType.combustion,
      );
      final trips = [
        trip(
          id: 't1',
          startedAt: DateTime(2026, 4, 1, 9),
          distanceKm: 1,
          fuelLitersConsumed: -10, // defensive negative
        ),
      ];

      final result = estimateTankLevel(
        vehicle: vehicleNoCap,
        fillUps: [lastFillUp],
        trips: trips,
      );

      // Without a capacity ceiling, the level rises above the start.
      // 45 - (-10) = 55. Honest given the lack of a known ceiling.
      expect(result.levelL, 55);
    });
  });
}
