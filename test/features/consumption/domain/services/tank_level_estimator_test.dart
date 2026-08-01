// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/consumption/data/obd2_fuel_level_snapshot_store.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/domain/services/tank_level_estimator.dart';

/// Pure unit tests for [estimateTankLevel] — v2 contract (#3647).
///
/// ## Why this file was REWRITTEN, not amended
///
/// The v1 contract (#1195/#1360) simulated the tank by subtracting
/// per-trip consumption estimates from the last fill. The maintainer
/// directive of 2026-08-01 replaced the model wholesale:
///
///   * a FULL fill anchors the tank at 100 % (capacity),
///   * an OBD2 fuel-level reading NEWER than that fill overrides it,
///   * trip recordings are excluded from the level math entirely
///     (on the reference vehicle their estimates ran 43 % above pump
///     truth and drifted the gauge by 4–5 L per tank).
///
/// Every v1 test that pinned trip subtraction therefore pinned a
/// contract that no longer exists. The valid v1 cases (sentinel,
/// capacity conventions, clamps, the #3645 sensor anchor and range
/// preference) are carried over below in v2 form.
void main() {
  const vehicle = VehicleProfile(
    id: 'v1',
    name: 'Test Car',
    type: VehicleType.combustion,
    tankCapacityL: 50,
  );

  const noCapacityVehicle = VehicleProfile(
    id: 'v1',
    name: 'No Capacity',
    type: VehicleType.combustion,
  );

  var idCounter = 0;
  FillUp fill({
    required DateTime date,
    required double liters,
    double odometerKm = 0,
    bool isFullTank = true,
    bool isCorrection = false,
    double? fuelLevelBeforeL,
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
      isCorrection: isCorrection,
      fuelLevelBeforeL: fuelLevelBeforeL,
      fuelLevelAfterL: fuelLevelAfterL,
    );
  }

  group('sentinel', () {
    test('no fill-ups → unknown', () {
      final e = estimateTankLevel(vehicle: vehicle, fillUps: const []);
      expect(e.hasFillUp, isFalse);
      expect(e.levelL, 0);
      expect(e.rangeKm, isNull);
    });

    test('a history of ONLY correction entries is still unknown — '
        'corrections are synthetic, not physical fills', () {
      final e = estimateTankLevel(
        vehicle: vehicle,
        fillUps: [
          fill(
            date: DateTime(2026, 4, 5),
            liters: 8,
            isFullTank: false,
            isCorrection: true,
          ),
        ],
      );
      expect(e.hasFillUp, isFalse);
    });
  });

  group('fill-up anchor — "eine Tankfüllung mit Flag voll = 100 %"', () {
    test('full fill anchors at capacity, regardless of pumped litres', () {
      final e = estimateTankLevel(
        vehicle: vehicle,
        fillUps: [fill(date: DateTime(2026, 4, 1), liters: 42)],
      );
      expect(e.levelL, 50.0);
      expect(e.source, TankLevelSource.fillUp);
      expect(e.sensorReadAt, isNull);
      expect(e.lastFillUpDate, DateTime(2026, 4, 1));
    });

    test('full fill without a configured capacity falls back to the pumped '
        'litres ("the tank holds at least what was just pumped")', () {
      final e = estimateTankLevel(
        vehicle: noCapacityVehicle,
        fillUps: [fill(date: DateTime(2026, 4, 1), liters: 42)],
      );
      expect(e.levelL, 42.0);
    });

    test('a correction entry never becomes "the most recent fill" and '
        'never moves the level', () {
      final e = estimateTankLevel(
        vehicle: vehicle,
        fillUps: [
          // newest first: a synthetic correction AFTER the real plein
          fill(
            date: DateTime(2026, 4, 8),
            liters: 6,
            isFullTank: false,
            isCorrection: true,
          ),
          fill(date: DateTime(2026, 4, 1), liters: 42),
        ],
      );
      expect(e.levelL, 50.0);
      expect(e.lastFillUpDate, DateTime(2026, 4, 1));
    });
  });

  group('partial-fill anchor — best available truth, in order', () {
    test('1st choice: the OBD2-measured post-pump level', () {
      final e = estimateTankLevel(
        vehicle: vehicle,
        fillUps: [
          fill(
            date: DateTime(2026, 4, 8),
            liters: 10,
            isFullTank: false,
            fuelLevelAfterL: 41,
          ),
          fill(date: DateTime(2026, 4, 1), liters: 45),
        ],
      );
      expect(e.levelL, 41.0);
    });

    test('2nd choice: pre-pump sensor level + pumped litres', () {
      final e = estimateTankLevel(
        vehicle: vehicle,
        fillUps: [
          fill(
            date: DateTime(2026, 4, 8),
            liters: 10,
            isFullTank: false,
            fuelLevelBeforeL: 22,
          ),
          fill(date: DateTime(2026, 4, 1), liters: 45),
        ],
      );
      expect(e.levelL, 32.0);
    });

    test('3rd choice: previous fill-chain anchor + litres, clamped to '
        'capacity (an upper bound — no consumption model exists)', () {
      final e = estimateTankLevel(
        vehicle: vehicle,
        fillUps: [
          fill(date: DateTime(2026, 4, 8), liters: 10, isFullTank: false),
          fill(date: DateTime(2026, 4, 1), liters: 45), // anchor: 50
        ],
      );
      // 50 + 10 clamped to capacity.
      expect(e.levelL, 50.0);
    });

    test('partials-only history without sensor data: the pumped litres '
        'are the only thing known to be in the tank', () {
      final e = estimateTankLevel(
        vehicle: vehicle,
        fillUps: [
          fill(date: DateTime(2026, 4, 8), liters: 12, isFullTank: false),
        ],
      );
      expect(e.levelL, 12.0);
    });

    test('a glitched post-pump sensor reading above capacity is clamped', () {
      final e = estimateTankLevel(
        vehicle: vehicle,
        fillUps: [
          fill(
            date: DateTime(2026, 4, 8),
            liters: 10,
            isFullTank: false,
            fuelLevelAfterL: 55,
          ),
          fill(date: DateTime(2026, 4, 1), liters: 45),
        ],
      );
      expect(e.levelL, 50.0);
    });

    test(
      'a FULL fill keeps the capacity convention even when a sensor '
      'reading is present — "full" is the user\'s physical statement, '
      'and the percent-derived 0x2F under-reads a brimmed tank',
      () {
        final e = estimateTankLevel(
          vehicle: vehicle,
          fillUps: [
            fill(date: DateTime(2026, 4, 8), liters: 42, fuelLevelAfterL: 46),
            fill(date: DateTime(2026, 4, 1), liters: 45),
          ],
        );
        expect(e.levelL, 50.0);
      },
    );
  });

  group(
      'sensor override — "der OBD2 trackt, die Tankfüllung hat '
      'Priorität"', () {
    test('a reading NEWER than the last fill overrides the anchor', () {
      final e = estimateTankLevel(
        vehicle: vehicle,
        fillUps: [fill(date: DateTime(2026, 4, 1), liters: 45)],
        sensor: Obd2FuelLevelSnapshot(
          liters: 33.5,
          at: DateTime(2026, 4, 3),
        ),
      );
      expect(e.levelL, 33.5);
      expect(e.source, TankLevelSource.obd2Sensor);
      expect(e.sensorReadAt, DateTime(2026, 4, 3));
    });

    test('a reading OLDER than the last fill is ignored — the fill has '
        'priority (the pump changed the tank AFTER the sensor looked)', () {
      final e = estimateTankLevel(
        vehicle: vehicle,
        fillUps: [fill(date: DateTime(2026, 4, 5), liters: 45)],
        sensor: Obd2FuelLevelSnapshot(
          liters: 12.0,
          at: DateTime(2026, 4, 4),
        ),
      );
      expect(e.levelL, 50.0);
      expect(e.source, TankLevelSource.fillUp);
      expect(e.sensorReadAt, isNull);
    });

    test('a glitched sensor reading above capacity is clamped', () {
      final e = estimateTankLevel(
        vehicle: vehicle,
        fillUps: [fill(date: DateTime(2026, 4, 1), liters: 45)],
        sensor: Obd2FuelLevelSnapshot(liters: 61, at: DateTime(2026, 4, 2)),
      );
      expect(e.levelL, 50.0);
      expect(e.source, TankLevelSource.obd2Sensor);
    });

    test('the sensor also overrides a partial-fill anchor', () {
      final e = estimateTankLevel(
        vehicle: vehicle,
        fillUps: [
          fill(
            date: DateTime(2026, 4, 8),
            liters: 10,
            isFullTank: false,
            fuelLevelAfterL: 41,
          ),
        ],
        sensor: Obd2FuelLevelSnapshot(liters: 37, at: DateTime(2026, 4, 10)),
      );
      expect(e.levelL, 37.0);
      expect(e.source, TankLevelSource.obd2Sensor);
    });
  });

  group('range — recording-free (#3645 tank-to-tank, #3647)', () {
    test('uses the fill-anchored tank-to-tank average when a valid '
        'plein-to-plein window exists', () {
      // 30 L over 500 odometer-km → true 6.0 L/100 km.
      final e = estimateTankLevel(
        vehicle: vehicle,
        fillUps: [
          fill(date: DateTime(2026, 4, 10), liters: 30, odometerKm: 100500),
          fill(date: DateTime(2026, 4, 1), liters: 45, odometerKm: 100000),
        ],
      );
      // Level = capacity 50 (full anchor); range = 50 / 6.0 × 100.
      expect(e.levelL, 50.0);
      expect(e.rangeKm, closeTo(50.0 / 6.0 * 100.0, 0.1));
    });

    test('falls back to the 7.0 fleet default when no valid window exists '
        '(the trip aggregate no longer participates)', () {
      final e = estimateTankLevel(
        vehicle: vehicle,
        fillUps: [fill(date: DateTime(2026, 4, 1), liters: 45)],
      );
      expect(e.rangeKm, closeTo(50.0 / 7.0 * 100.0, 0.1));
    });

    test('range follows the sensor level when the sensor grounds it', () {
      final e = estimateTankLevel(
        vehicle: vehicle,
        fillUps: [
          fill(date: DateTime(2026, 4, 10), liters: 30, odometerKm: 100500),
          fill(date: DateTime(2026, 4, 1), liters: 45, odometerKm: 100000),
        ],
        sensor: Obd2FuelLevelSnapshot(liters: 24, at: DateTime(2026, 4, 12)),
      );
      expect(e.levelL, 24.0);
      expect(e.rangeKm, closeTo(24.0 / 6.0 * 100.0, 0.1));
    });
  });
}
