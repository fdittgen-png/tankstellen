// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/domain/entities/fuel_type_efficiency_stats.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/consumption/providers/fuel_type_efficiency_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

/// Orchestration tests for [fuelTypeEfficiencyComparisonProvider] (#2884).
///
/// The grouping maths live in `FuelTypeEfficiencyAggregator` (covered by
/// `fuel_type_efficiency_aggregator_test.dart`); these tests pin the
/// provider's wiring: it watches the fill-up list + active vehicle, filters
/// to the selected vehicle's fills, and delegates to the aggregator.

/// Stub [FillUpList] returning a fixed list (no Hive).
class _FakeFillUpList extends FillUpList {
  _FakeFillUpList(this._value);
  final List<FillUp> _value;

  @override
  List<FillUp> build() => _value;
}

/// Stub [ActiveVehicleProfile] returning a fixed value (no repo).
class _StubActiveVehicle extends ActiveVehicleProfile {
  _StubActiveVehicle(this._value);
  final VehicleProfile? _value;

  @override
  VehicleProfile? build() => _value;
}

FillUp _f({
  required String id,
  required double liters,
  required double cost,
  required double odo,
  required int day,
  FuelType fuelType = FuelType.e10,
  bool isFullTank = true,
  String? vehicleId,
}) =>
    FillUp(
      id: id,
      date: DateTime(2026, 1, day),
      liters: liters,
      totalCost: cost,
      odometerKm: odo,
      fuelType: fuelType,
      isFullTank: isFullTank,
      vehicleId: vehicleId,
    );

const _v1 = VehicleProfile(
  id: 'v1',
  name: 'Peugeot 107',
  type: VehicleType.combustion,
);

ProviderContainer _container({
  required List<FillUp> fillUps,
  VehicleProfile? activeVehicle,
}) {
  final c = ProviderContainer(overrides: [
    fillUpListProvider.overrideWith(() => _FakeFillUpList(fillUps)),
    activeVehicleProfileProvider
        .overrideWith(() => _StubActiveVehicle(activeVehicle)),
  ]);
  addTearDown(c.dispose);
  return c;
}

FuelTypeEfficiencyStats _statsFor(
  List<FuelTypeEfficiencyStats> all,
  FuelType fuel,
) =>
    all.firstWhere(
      (s) => !s.isMix && s.dominant.apiValue == fuel.apiValue,
    );

void main() {
  group('fuelTypeEfficiencyComparisonProvider', () {
    test('empty fill-up list yields an empty comparison', () {
      final c = _container(fillUps: const [], activeVehicle: _v1);
      expect(c.read(fuelTypeEfficiencyComparisonProvider), isEmpty);
    });

    test('groups the active vehicle fills by fuel type', () {
      // Two E10 closed intervals + two E85 closed intervals for v1.
      final c = _container(
        activeVehicle: _v1,
        fillUps: [
          _f(id: 'a', day: 1, liters: 40, cost: 68, odo: 0,
              fuelType: FuelType.e10, vehicleId: 'v1'),
          _f(id: 'b', day: 2, liters: 30, cost: 51, odo: 600,
              fuelType: FuelType.e10, vehicleId: 'v1'),
          _f(id: 'c', day: 3, liters: 45, cost: 45, odo: 1100,
              fuelType: FuelType.e85, vehicleId: 'v1'),
          _f(id: 'd', day: 4, liters: 50, cost: 50, odo: 1700,
              fuelType: FuelType.e85, vehicleId: 'v1'),
          _f(id: 'e', day: 5, liters: 35, cost: 60, odo: 2200,
              fuelType: FuelType.e10, vehicleId: 'v1'),
        ],
      );

      final result = c.read(fuelTypeEfficiencyComparisonProvider);
      expect(result.length, 2);
      expect(_statsFor(result, FuelType.e10).attributedIntervalCount, 2);
      expect(_statsFor(result, FuelType.e85).attributedIntervalCount, 2);
      // Sorted by €/km ascending — E85 first.
      expect(result.first.dominant.apiValue, FuelType.e85.apiValue);
    });

    test('filters out fills belonging to other vehicles', () {
      final c = _container(
        activeVehicle: _v1,
        fillUps: [
          _f(id: 'v1-a', day: 1, liters: 40, cost: 60, odo: 0,
              fuelType: FuelType.e10, vehicleId: 'v1'),
          _f(id: 'v1-b', day: 2, liters: 30, cost: 45, odo: 600,
              fuelType: FuelType.e10, vehicleId: 'v1'),
          // Foreign vehicle, different fuel — must NOT appear.
          _f(id: 'other', day: 3, liters: 45, cost: 45, odo: 5000,
              fuelType: FuelType.e85, vehicleId: 'other'),
        ],
      );

      final result = c.read(fuelTypeEfficiencyComparisonProvider);
      // Only v1's E10 fills survive the vehicle filter — one pure E10 bucket.
      expect(result.length, 1);
      expect(result.single.dominant.apiValue, FuelType.e10.apiValue);
      expect(
        result.any((s) => s.dominant.apiValue == FuelType.e85.apiValue),
        isFalse,
      );
    });

    test('no active vehicle → aggregates ALL fills', () {
      // Two pure E85 intervals from v1 + two pure E10 intervals from `other`
      // — no vehicle filter, so both compositions appear as buckets.
      final c = _container(
        activeVehicle: null,
        fillUps: [
          _f(id: 'v1a', day: 1, liters: 40, cost: 40, odo: 0,
              fuelType: FuelType.e85, vehicleId: 'v1'),
          _f(id: 'v1b', day: 2, liters: 30, cost: 30, odo: 500,
              fuelType: FuelType.e85, vehicleId: 'v1'),
          _f(id: 'v1c', day: 3, liters: 30, cost: 30, odo: 1000,
              fuelType: FuelType.e85, vehicleId: 'v1'),
          _f(id: 'ot1', day: 4, liters: 40, cost: 64, odo: 1500,
              fuelType: FuelType.e10, vehicleId: 'other'),
          _f(id: 'ot2', day: 5, liters: 30, cost: 48, odo: 2000,
              fuelType: FuelType.e10, vehicleId: 'other'),
          _f(id: 'ot3', day: 6, liters: 30, cost: 48, odo: 2500,
              fuelType: FuelType.e10, vehicleId: 'other'),
        ],
      );

      final result = c.read(fuelTypeEfficiencyComparisonProvider);
      // Both pure compositions present because no vehicle filter is applied.
      expect(result.length, 2);
      expect(result.any((s) => s.label == 'E85'), isTrue);
      expect(result.any((s) => s.label == 'E10'), isTrue);
    });
  });
}
