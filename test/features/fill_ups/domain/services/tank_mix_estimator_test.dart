// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/domain/services/tank_mix_estimator.dart';

/// Pure unit tests for [estimateTankMix] (#3652).
///
/// The maintainer directive: adding E10 to a part-full E85 tank makes
/// the content a percentage of both, weighted by the litres involved —
/// a full-flagged fill pins both the level and the mix exactly; the
/// pre-pump sensor level, the odometer-based burn estimate and the
/// midpoint fallback ground the blend otherwise.
void main() {
  const vehicle = VehicleProfile(
    id: 'v1',
    name: 'Flex 107',
    type: VehicleType.combustion,
    tankCapacityL: 35,
    multiFuelCapable: true,
  );

  var idCounter = 0;
  FillUp fill({
    required DateTime date,
    required double liters,
    FuelType fuelType = FuelType.e85,
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
      totalCost: liters * 1.0,
      odometerKm: odometerKm,
      fuelType: fuelType,
      vehicleId: 'v1',
      isFullTank: isFullTank,
      isCorrection: isCorrection,
      fuelLevelBeforeL: fuelLevelBeforeL,
      fuelLevelAfterL: fuelLevelAfterL,
    );
  }

  double shareOf(TankMixEstimate mix, FuelType fuel) => mix.shares
      .firstWhere((s) => s.fuel == fuel,
          orElse: () => const TankMixShare(fuel: FuelType.e5, share: 0))
      .share;

  group('sentinels', () {
    test('no fills → null', () {
      expect(estimateTankMix(vehicle: vehicle, fillUps: const []), isNull);
    });

    test('corrections-only history → null (synthetic, not fuel)', () {
      final mix = estimateTankMix(
        vehicle: vehicle,
        fillUps: [
          fill(
            date: DateTime(2026, 7, 1),
            liters: 5,
            isFullTank: false,
            isCorrection: true,
          ),
        ],
      );
      expect(mix, isNull);
    });
  });

  group('acceptance case from #3652', () {
    test('20 L E10 full fill onto a 15 L E85 remainder in the 35 L tank '
        '→ ≈57 % E10 / 43 % E85', () {
      final mix = estimateTankMix(
        vehicle: vehicle,
        fillUps: [
          // Establish a pure-E85 tank with a full fill.
          fill(date: DateTime(2026, 7, 1), liters: 30, odometerKm: 1000),
          // Full E10 fill of 20 L → 15 L residual E85 pinned by the flag.
          fill(
            date: DateTime(2026, 7, 10),
            liters: 20,
            fuelType: FuelType.e10,
            odometerKm: 1300,
          ),
        ],
      );
      expect(mix, isNotNull);
      expect(shareOf(mix!, FuelType.e10), closeTo(20 / 35, 1e-9));
      expect(shareOf(mix, FuelType.e85), closeTo(15 / 35, 1e-9));
      expect(mix.isBlend(), isTrue);
      expect(mix.asOf, DateTime(2026, 7, 10));
      // Dominant grade first.
      expect(mix.shares.first.fuel, FuelType.e10);
    });
  });

  group('prior-content chain', () {
    test('a pre-pump sensor level grounds a PARTIAL fill blend', () {
      final mix = estimateTankMix(
        vehicle: vehicle,
        fillUps: [
          fill(date: DateTime(2026, 7, 1), liters: 35), // full E85
          fill(
            date: DateTime(2026, 7, 8),
            liters: 10,
            fuelType: FuelType.e10,
            isFullTank: false,
            fuelLevelBeforeL: 10, // OBD2 said 10 L E85 remained
          ),
        ],
      );
      // 10 L E85 + 10 L E10 → 50/50.
      expect(shareOf(mix!, FuelType.e10), closeTo(0.5, 1e-9));
      expect(shareOf(mix, FuelType.e85), closeTo(0.5, 1e-9));
    });

    test('without sensor data the odometer-delta burn estimate grounds '
        'the partial blend', () {
      // History gives one valid tank-to-tank window: 30 L / 300 km
      // → 10 L/100 km.
      final mix = estimateTankMix(
        vehicle: vehicle,
        fillUps: [
          fill(date: DateTime(2026, 6, 1), liters: 30, odometerKm: 1000),
          fill(date: DateTime(2026, 6, 10), liters: 30, odometerKm: 1300),
          // 100 km later → 10 L burned → 25 L E85 remain; +10 L E10.
          fill(
            date: DateTime(2026, 6, 15),
            liters: 10,
            fuelType: FuelType.e10,
            isFullTank: false,
            odometerKm: 1400,
          ),
        ],
      );
      expect(shareOf(mix!, FuelType.e85), closeTo(25 / 35, 1e-9));
      expect(shareOf(mix, FuelType.e10), closeTo(10 / 35, 1e-9));
    });

    test('nothing known → midpoint of [0, previous level] weights the '
        'blend (documented least-worst guess)', () {
      final mix = estimateTankMix(
        vehicle: vehicle,
        fillUps: [
          // Full fill without odometer data (odometerKm 0 = not captured).
          fill(date: DateTime(2026, 7, 1), liters: 35),
          // Partial with no sensor level and no odometer: prior =
          // 35 / 2 = 17.5 L E85 + 10 L E10.
          fill(
            date: DateTime(2026, 7, 8),
            liters: 10,
            fuelType: FuelType.e10,
            isFullTank: false,
          ),
        ],
      );
      expect(shareOf(mix!, FuelType.e85), closeTo(17.5 / 27.5, 1e-9));
      expect(shareOf(mix, FuelType.e10), closeTo(10 / 27.5, 1e-9));
    });

    test('a later FULL fill re-pins the mix exactly, washing out earlier '
        'guesses', () {
      final mix = estimateTankMix(
        vehicle: vehicle,
        fillUps: [
          fill(date: DateTime(2026, 7, 1), liters: 35),
          fill(
            date: DateTime(2026, 7, 8),
            liters: 10,
            fuelType: FuelType.e10,
            isFullTank: false,
          ),
          // Full E85 fill of 28 L → residual 7 L of the previous blend
          // (17.5 E85 + 10 E10 → 63.6 % / 36.4 %).
          fill(date: DateTime(2026, 7, 15), liters: 28),
        ],
      );
      const residual = 7.0;
      const e85Residual = residual * (17.5 / 27.5);
      const e10Residual = residual * (10 / 27.5);
      expect(
        shareOf(mix!, FuelType.e85),
        closeTo((28 + e85Residual) / 35, 1e-9),
      );
      expect(shareOf(mix, FuelType.e10), closeTo(e10Residual / 35, 1e-9));
    });
  });

  group('single-fuel and trace handling', () {
    test('a pure-grade history returns 100 % and is NOT a blend', () {
      final mix = estimateTankMix(
        vehicle: vehicle,
        fillUps: [
          fill(date: DateTime(2026, 7, 1), liters: 30),
          fill(date: DateTime(2026, 7, 10), liters: 20, odometerKm: 300),
        ],
      );
      expect(mix!.shares, hasLength(1));
      expect(mix.shares.single.share, closeTo(1.0, 1e-9));
      expect(mix.isBlend(), isFalse);
    });

    test('a trace share below 1 % does not count as a blend', () {
      final mix = estimateTankMix(
        vehicle: vehicle,
        fillUps: [
          fill(date: DateTime(2026, 7, 1), liters: 35),
          // 0.2 L of E10 into a full tank — a trace.
          fill(
            date: DateTime(2026, 7, 2),
            liters: 0.2,
            fuelType: FuelType.e10,
            isFullTank: false,
            fuelLevelBeforeL: 34.8,
          ),
        ],
      );
      expect(mix!.isBlend(), isFalse);
    });

    test('corrections never move the mix', () {
      final mix = estimateTankMix(
        vehicle: vehicle,
        fillUps: [
          fill(date: DateTime(2026, 7, 1), liters: 35),
          fill(
            date: DateTime(2026, 7, 5),
            liters: 8,
            fuelType: FuelType.e10,
            isFullTank: false,
            isCorrection: true,
          ),
        ],
      );
      expect(mix!.shares.single.fuel, FuelType.e85);
    });
  });

  group('capacity-less vehicles', () {
    const noCapacity = VehicleProfile(
      id: 'v1',
      name: 'No capacity',
      type: VehicleType.combustion,
      multiFuelCapable: true,
    );

    test('full flag without a capacity cannot pin the residual — the '
        'sensor level still can', () {
      final mix = estimateTankMix(
        vehicle: noCapacity,
        fillUps: [
          fill(date: DateTime(2026, 7, 1), liters: 30),
          fill(
            date: DateTime(2026, 7, 8),
            liters: 20,
            fuelType: FuelType.e10,
            fuelLevelBeforeL: 10,
          ),
        ],
      );
      expect(shareOf(mix!, FuelType.e10), closeTo(20 / 30, 1e-9));
      expect(shareOf(mix, FuelType.e85), closeTo(10 / 30, 1e-9));
    });
  });
}
