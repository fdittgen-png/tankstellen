// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/domain/services/fill_up_vehicle_scope.dart';

/// #3945 — whose fill is a fill with no `vehicleId`?
///
/// One profile: it can only be that car's, so it counts. Two or more:
/// ambiguous, excluded (an unassigned fill of the other car must never move
/// this car's number).

FillUp _f(String id, String? vehicleId) => FillUp(
  id: id,
  date: DateTime.utc(2026, 1, 1),
  liters: 40,
  totalCost: 70,
  odometerKm: 1000,
  fuelType: FuelType.e10,
  isFullTank: true,
  vehicleId: vehicleId,
);

const _v1 = VehicleProfile(id: 'v1', name: 'Peugeot 107');

void main() {
  final fills = [_f('own', 'v1'), _f('other', 'v2'), _f('unassigned', null)];

  test('no active vehicle keeps every fill', () {
    expect(
      scopeFillUpsToVehicle(fills, vehicle: null, vehicleCount: 0),
      fills,
    );
  });

  test('a single-vehicle user gets their unassigned history back', () {
    final scoped = scopeFillUpsToVehicle(fills, vehicle: _v1, vehicleCount: 1);
    expect(scoped.map((f) => f.id), ['own', 'unassigned']);
  });

  test('with two or more vehicles unassigned fills stay excluded', () {
    final scoped = scopeFillUpsToVehicle(fills, vehicle: _v1, vehicleCount: 2);
    expect(scoped.map((f) => f.id), ['own']);
  });

  test("another vehicle's fills never count, whatever the profile count", () {
    for (final count in [1, 2, 5]) {
      final scoped = scopeFillUpsToVehicle(
        fills,
        vehicle: _v1,
        vehicleCount: count,
      );
      expect(scoped.any((f) => f.id == 'other'), isFalse, reason: '$count');
    }
  });
}
