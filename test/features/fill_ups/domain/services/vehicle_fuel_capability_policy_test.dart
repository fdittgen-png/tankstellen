// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel/fuel_grade.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/fill_ups/domain/services/vehicle_fuel_capability_policy.dart';

/// #4278 — what a vehicle profile may honestly vouch for. The rule that
/// matters most: a fuel that physically fits (#713) is never an approval.
void main() {
  VehicleProfile car(String? fuel,
          {bool multi = false, VehicleType type = VehicleType.combustion}) =>
      VehicleProfile(
          id: 'v',
          name: 'Car',
          type: type,
          preferredFuelType: fuel,
          multiFuelCapable: multi);

  group('vehicleFuelCapabilityOf', () {
    test('no vehicle, an EV, or no configured fuel → unknown', () {
      expect(vehicleFuelCapabilityOf(null).isUnknown, isTrue);
      expect(
          vehicleFuelCapabilityOf(car('e10', type: VehicleType.ev)).isUnknown,
          isTrue);
      expect(vehicleFuelCapabilityOf(car(null)).isUnknown, isTrue);
      expect(vehicleFuelCapabilityOf(car('')).isUnknown, isTrue);
      expect(vehicleFuelCapabilityOf(car('all')).isUnknown, isTrue);
      expect(vehicleFuelCapabilityOf(car('electric')).isUnknown, isTrue);
    });

    test('an E10 car approves E10 only — E85 fits but is not approved', () {
      final c = vehicleFuelCapabilityOf(car('e10'));
      expect(c.approvedGrades, {FuelGrade.e10});
      expect(c.permits(FuelGrade.e85), isFalse);
      expect(c.permits(FuelGrade.e5), isFalse);
      expect(c.provenance, kCapabilityProvenanceConfiguredFuel);
    });

    test('a multi-fuel E10 car gains the E5-class grades, never E85', () {
      final c = vehicleFuelCapabilityOf(car('e10', multi: true));
      expect(c.approvedGrades, {FuelGrade.e5, FuelGrade.e10, FuelGrade.e98});
      expect(c.permits(FuelGrade.e85), isFalse);
      expect(c.provenance, kCapabilityProvenanceMultiFuelPetrol);
    });

    test('a multi-fuel E85 car is flex-fuel: E5, E10, E98 and E85', () {
      final c = vehicleFuelCapabilityOf(car('e85', multi: true));
      expect(c.approvedGrades,
          {FuelGrade.e5, FuelGrade.e10, FuelGrade.e98, FuelGrade.e85});
      expect(c.provenance, kCapabilityProvenanceFlexFuel);
    });

    test('an E85 car not declared multi-fuel approves E85 alone', () {
      expect(vehicleFuelCapabilityOf(car('e85')).approvedGrades,
          {FuelGrade.e85});
    });

    test('diesel and LPG approve their configured grade', () {
      expect(vehicleFuelCapabilityOf(car('diesel')).approvedGrades,
          {FuelGrade.diesel});
      expect(vehicleFuelCapabilityOf(car('lpg', multi: true)).approvedGrades,
          {FuelGrade.lpg});
    });
  });

  group('burnsLiquidFuel', () {
    test('combustion and hybrid qualify, EVs and gas-only cars do not', () {
      expect(burnsLiquidFuel(car('e10')), isTrue);
      expect(burnsLiquidFuel(car(null)), isTrue);
      expect(burnsLiquidFuel(car('e10', type: VehicleType.hybrid)), isTrue);
      expect(burnsLiquidFuel(car(null, type: VehicleType.ev)), isFalse);
      expect(burnsLiquidFuel(car('cng')), isFalse);
      expect(burnsLiquidFuel(null), isFalse);
    });
  });

  // #4324 — the persisted declaration.
  group('declared approved grades', () {
    test('an E10 car declared flex-fuel is offered E85', () {
      final c = vehicleFuelCapabilityOf(car('e10')
          .copyWith(approvedFuelGrades: const ['e5', 'e10', 'e98', 'e85']));
      expect(c.approvedGrades,
          {FuelGrade.e5, FuelGrade.e10, FuelGrade.e98, FuelGrade.e85});
      expect(c.permits(FuelGrade.e85), isTrue);
      expect(c.provenance, kCapabilityProvenanceDeclared);
    });

    test('declarations EXTEND the derivation; unknown keys are dropped', () {
      final c = vehicleFuelCapabilityOf(car('diesel')
          .copyWith(approvedFuelGrades: const ['E85', 'b100', 'electric']));
      expect(c.approvedGrades, {FuelGrade.diesel, FuelGrade.e85});
    });

    test('nothing declared (every old profile) resolves exactly as before',
        () {
      for (final v in [
        car('e10'),
        car('e10', multi: true),
        car('e85', multi: true),
        car('e85'),
        car('diesel'),
        car(null),
      ]) {
        final c = vehicleFuelCapabilityOf(v);
        expect(v.approvedFuelGrades, isEmpty);
        expect(c.provenance, isNot(kCapabilityProvenanceDeclared));
      }
      // An old JSON blob without the field decodes to nothing declared.
      final old = VehicleProfile.fromJson(const {
        'id': 'v',
        'name': 'Old',
        'preferredFuelType': 'e10',
      });
      expect(old.approvedFuelGrades, isEmpty);
      expect(vehicleFuelCapabilityOf(old).approvedGrades, {FuelGrade.e10});
    });

    test('an EV stays unknown whatever it declares', () {
      expect(
          vehicleFuelCapabilityOf(car('e10', type: VehicleType.ev)
                  .copyWith(approvedFuelGrades: const ['e85']))
              .isUnknown,
          isTrue);
    });
  });

  group('priceableGradesOf', () {
    test('the physical family, in grade order', () {
      expect(priceableGradesOf(car('e85')),
          [FuelGrade.e5, FuelGrade.e10, FuelGrade.e98, FuelGrade.e85]);
      expect(priceableGradesOf(car('diesel')),
          [FuelGrade.diesel, FuelGrade.dieselPremium]);
      expect(priceableGradesOf(car('lpg')), [FuelGrade.lpg]);
    });

    test('an unknown fuel prices every liquid grade', () {
      expect(priceableGradesOf(car(null)), [
        FuelGrade.e5,
        FuelGrade.e10,
        FuelGrade.e98,
        FuelGrade.e85,
        FuelGrade.diesel,
        FuelGrade.dieselPremium,
        FuelGrade.lpg,
      ]);
    });
  });
}
