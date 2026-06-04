// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/add_fill_up_warnings.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';

/// Unit tests for the #2836 fill-up data-quality warnings — reproduces the
/// exact failure modes a real backup surfaced: an e10 (petrol) fill-up
/// logged on a diesel vehicle, and an odometer that went backwards.
void main() {
  const dieselCar = VehicleProfile(
    id: 'diesel-1',
    name: 'Diesel Car',
    type: VehicleType.combustion,
    preferredFuelType: 'diesel',
  );
  const petrolCar = VehicleProfile(
    id: 'petrol-1',
    name: 'Petrol Car',
    type: VehicleType.combustion,
    preferredFuelType: 'e10',
  );
  const unconfiguredCar = VehicleProfile(
    id: 'blank-1',
    name: 'Unknown Car',
    type: VehicleType.combustion,
  );

  FillUp fill(String id, DateTime date, double odo,
          {bool correction = false}) =>
      FillUp(
        id: id,
        date: date,
        liters: 40,
        totalCost: 60,
        odometerKm: odo,
        fuelType: FuelType.diesel,
        vehicleId: 'diesel-1',
        isCorrection: correction,
      );

  group('computeFillUpWarnings (#2836)', () {
    test('e10 on a diesel vehicle warns about the engine mismatch', () {
      final warnings = computeFillUpWarnings(
        vehicle: dieselCar,
        chosenFuel: FuelType.e10,
        enteredOdometerKm: 90000,
      );
      expect(warnings, contains(FillUpWarning.fuelEngineMismatch));
    });

    test('diesel on a diesel vehicle does not warn', () {
      final warnings = computeFillUpWarnings(
        vehicle: dieselCar,
        chosenFuel: FuelType.diesel,
        enteredOdometerKm: 90000,
      );
      expect(warnings, isEmpty);
    });

    test('diesel-premium on a diesel vehicle does NOT warn (same family)',
        () {
      final warnings = computeFillUpWarnings(
        vehicle: dieselCar,
        chosenFuel: FuelType.dieselPremium,
        enteredOdometerKm: 90000,
      );
      expect(warnings, isEmpty);
    });

    test('e5 on a petrol (e10) vehicle does NOT warn (same family)', () {
      final warnings = computeFillUpWarnings(
        vehicle: petrolCar,
        chosenFuel: FuelType.e5,
        enteredOdometerKm: 90000,
      );
      expect(warnings, isEmpty);
    });

    test('diesel on a petrol vehicle warns', () {
      final warnings = computeFillUpWarnings(
        vehicle: petrolCar,
        chosenFuel: FuelType.diesel,
        enteredOdometerKm: 90000,
      );
      expect(warnings, contains(FillUpWarning.fuelEngineMismatch));
    });

    test('an unconfigured vehicle never trips the fuel-mismatch warning', () {
      final warnings = computeFillUpWarnings(
        vehicle: unconfiguredCar,
        chosenFuel: FuelType.diesel,
        enteredOdometerKm: 90000,
      );
      expect(warnings, isNot(contains(FillUpWarning.fuelEngineMismatch)));
    });

    test('odometer below the previous reading warns (the −307 km case)', () {
      // Field backup: a later diesel fill at 83178 after an earlier fill
      // at 83485 km.
      final warnings = computeFillUpWarnings(
        vehicle: dieselCar,
        chosenFuel: FuelType.diesel,
        enteredOdometerKm: 83178,
        previousOdometerKm: 83485,
      );
      expect(warnings, contains(FillUpWarning.odometerBelowPrevious));
    });

    test('odometer above the previous reading does not warn', () {
      final warnings = computeFillUpWarnings(
        vehicle: dieselCar,
        chosenFuel: FuelType.diesel,
        enteredOdometerKm: 84000,
        previousOdometerKm: 83485,
      );
      expect(warnings, isEmpty);
    });

    test('equal odometer (rounding) does not warn', () {
      final warnings = computeFillUpWarnings(
        vehicle: dieselCar,
        chosenFuel: FuelType.diesel,
        enteredOdometerKm: 83485,
        previousOdometerKm: 83485,
      );
      expect(warnings, isEmpty);
    });

    test('both failure modes fire together (the exact field entry)', () {
      final warnings = computeFillUpWarnings(
        vehicle: dieselCar,
        chosenFuel: FuelType.e10,
        enteredOdometerKm: 83178,
        previousOdometerKm: 83485,
      );
      expect(
        warnings,
        containsAll([
          FillUpWarning.fuelEngineMismatch,
          FillUpWarning.odometerBelowPrevious,
        ]),
      );
    });
  });

  group('previousFillUpOdometerKm (#2836)', () {
    final older = fill('a', DateTime(2026, 4, 1), 83000);
    final newer = fill('b', DateTime(2026, 5, 1), 83485);
    final correction = fill('c', DateTime(2026, 4, 15), 99999, correction: true);

    test('returns the most recent prior real fill-up odometer', () {
      final odo = previousFillUpOdometerKm(
        vehicleId: 'diesel-1',
        date: DateTime(2026, 6, 1),
        allFillUps: [older, newer],
      );
      expect(odo, 83485);
    });

    test('excludes correction fill-ups', () {
      final odo = previousFillUpOdometerKm(
        vehicleId: 'diesel-1',
        date: DateTime(2026, 6, 1),
        allFillUps: [older, correction],
      );
      expect(odo, 83000, reason: 'the orange correction entry is skipped');
    });

    test('ignores other vehicles', () {
      final otherVehicle = FillUp(
        id: 'x',
        date: DateTime(2026, 5, 20),
        liters: 40,
        totalCost: 60,
        odometerKm: 99999,
        fuelType: FuelType.e10,
        vehicleId: 'some-other-car',
      );
      final odo = previousFillUpOdometerKm(
        vehicleId: 'diesel-1',
        date: DateTime(2026, 6, 1),
        allFillUps: [older, otherVehicle],
      );
      expect(odo, 83000);
    });

    test('returns null when there is no prior fill-up for the vehicle', () {
      final odo = previousFillUpOdometerKm(
        vehicleId: 'diesel-1',
        date: DateTime(2026, 3, 1),
        allFillUps: [newer], // dated after the query date
      );
      expect(odo, isNull);
    });

    test('returns null for a null vehicleId', () {
      final odo = previousFillUpOdometerKm(
        vehicleId: null,
        date: DateTime(2026, 6, 1),
        allFillUps: [older, newer],
      );
      expect(odo, isNull);
    });
  });
}
