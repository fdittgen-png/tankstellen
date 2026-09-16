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

  group('grounding — which rung the mix actually rests on (#4275)', () {
    test('a full fill with a known capacity is pinned, not guessed', () {
      // 35 L into a 35 L tank: prior = capacity - pumped = 0. Tier 1, and
      // a genuine run-dry pin — nothing earlier survives to carry doubt.
      final mix = estimateTankMix(
        vehicle: vehicle,
        fillUps: [fill(date: DateTime(2026, 7, 1), liters: 35)],
      );

      expect(mix!.grounding, TankMixGrounding.pinnedByFullTank);
      expect(mix.isMeasured, isTrue);
    });

    test('a pre-pump sensor level grounds the blend on a reading', () {
      final mix = estimateTankMix(
        vehicle: vehicle,
        fillUps: [
          fill(date: DateTime(2026, 7, 1), liters: 35),
          fill(
            date: DateTime(2026, 7, 8),
            liters: 10,
            fuelType: FuelType.e10,
            isFullTank: false,
            fuelLevelBeforeL: 10,
          ),
        ],
      );

      expect(mix!.grounding, TankMixGrounding.sensorLevel);
      expect(mix.isMeasured, isTrue,
          reason: 'a tank reading is a measurement, not a reconstruction');
    });

    test('the odometer-delta burn estimate is NOT a measurement', () {
      final mix = estimateTankMix(
        vehicle: vehicle,
        fillUps: [
          fill(date: DateTime(2026, 6, 1), liters: 30, odometerKm: 1000),
          fill(date: DateTime(2026, 6, 10), liters: 30, odometerKm: 1300),
          fill(
            date: DateTime(2026, 6, 15),
            liters: 10,
            fuelType: FuelType.e10,
            isFullTank: false,
            odometerKm: 1400,
          ),
        ],
      );

      expect(mix!.grounding, TankMixGrounding.burnEstimate);
      expect(mix.isMeasured, isFalse,
          reason: 'the burn rate is an average and the odometer is the '
              "driver's — real inputs, but a reconstruction");
    });

    test('nothing known bottoms out at the midpoint guess', () {
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
        ],
      );

      expect(mix!.grounding, TankMixGrounding.midpointGuess);
      expect(mix.isMeasured, isFalse);
    });

    test('a later full fill onto a NON-empty tank does not clear the floor',
        () {
      // The estimator's own "washing out earlier guesses" history. The
      // closing 28 L plein pins prior = 7 L — but those 7 L are made of
      // the midpoint-guessed blend, so ~20 % of this "pinned" composition
      // still rests on a coin flip. Reporting it as measured would be a
      // lie dressed as arithmetic.
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
          fill(date: DateTime(2026, 7, 15), liters: 28),
        ],
      );

      expect(mix!.grounding, TankMixGrounding.midpointGuess,
          reason: 'the floor is the weakest rung across the walk, and a '
              'non-zero residual carries that weakness forward');
      expect(mix.isMeasured, isFalse);
    });

    test('a run-dry switch DOES clear the floor', () {
      // Same guessed history, but the final fill takes the whole 35 L
      // tank: prior = 0, so no earlier fuel survives and the mix is
      // pinned to that grade alone. ADR 0015 v3 names this case as
      // correctly staying pure.
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
          fill(date: DateTime(2026, 7, 15), liters: 35),
        ],
      );

      expect(mix!.grounding, TankMixGrounding.pinnedByFullTank);
      expect(mix.isMeasured, isTrue);
      expect(shareOf(mix, FuelType.e85), closeTo(1.0, 1e-9),
          reason: 'a run-dry switch really is a pure tank');
    });

    test('a capacity-less vehicle cannot pin, so the floor stays honest',
        () {
      const noCapacity = VehicleProfile(
        id: 'v2',
        name: 'No capacity',
        type: VehicleType.combustion,
        multiFuelCapable: true,
      );

      final mix = estimateTankMix(
        vehicle: noCapacity,
        fillUps: [
          fill(date: DateTime(2026, 7, 1), liters: 35),
          fill(
            date: DateTime(2026, 7, 8),
            liters: 10,
            fuelType: FuelType.e10,
            isFullTank: false,
          ),
        ],
      );

      expect(mix!.grounding, TankMixGrounding.midpointGuess,
          reason: 'the full flag cannot pin a residual without a capacity, '
              'so tier 1 never fires and the walk falls to the midpoint');
      expect(mix.isMeasured, isFalse);
    });

    test('a first fill that consults no rung has no grounding at all', () {
      // Non-full, no sensor level, no previous level: the untagged
      // first-fill branch. Its residual is attributed to this fill's own
      // grade by the documented convergence rule — not an inference about
      // a blend, so it claims no provenance rather than a weak one.
      final mix = estimateTankMix(
        vehicle: vehicle,
        fillUps: [
          fill(date: DateTime(2026, 7, 1), liters: 20, isFullTank: false),
        ],
      );

      expect(mix!.grounding, isNull);
      expect(mix.isMeasured, isFalse,
          reason: 'absence of provenance is never evidence of measurement');
    });

    test('a hand-built estimate carries no grounding', () {
      // The three tank_level_card fixtures build TankMixEstimate directly.
      // Defaulting grounding to any enum value would claim a provenance
      // such an estimate does not have.
      final built = TankMixEstimate(
        shares: const [TankMixShare(fuel: FuelType.e10, share: 1)],
        asOf: DateTime(2026, 7, 1),
      );

      expect(built.grounding, isNull);
      expect(built.isMeasured, isFalse);
    });
  });

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
