// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/fill_ups/api.dart';
import 'package:tankstellen/features/search/providers/all_prices_table_provider.dart';
import 'package:tankstellen/features/vehicle/api.dart';

/// #3933 / #3934 — the per-fuel consumption the all-prices table turns into
/// a cost per 100 km.
///
/// Since #3934 the numbers are NOT computed here: `allPricesFuelCostModel`
/// reads `fuelTypeEfficiencyComparisonProvider` (ADR 0015), so the table and
/// the consumption screen cannot state two different L/100 km for the same
/// history. These tests pin the WIRING — that pure buckets reach the table,
/// that mix buckets do not become a per-grade number, and the documented
/// degradation (no vehicle / no usable history ⇒ no cost column).
///
/// The bucketing maths themselves are covered by
/// `test/features/fill_ups/domain/fuel_type_efficiency_aggregator_test.dart`.

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

void main() {
  FillUp fill({
    required String id,
    required int day,
    required double liters,
    required double odometerKm,
    required FuelType fuelType,
    bool isFullTank = true,
    bool isCorrection = false,
  }) => FillUp(
    id: id,
    date: DateTime.utc(2026, 1, day),
    liters: liters,
    totalCost: liters * 1.8,
    odometerKm: odometerKm,
    fuelType: fuelType,
    isFullTank: isFullTank,
    isCorrection: isCorrection,
    vehicleId: 'v1',
  );

  VehicleProfile vehicle({
    String? preferredFuelType,
    bool multiFuelCapable = false,
    double? tankCapacityL,
  }) => VehicleProfile(
    id: 'v1',
    name: 'Peugeot 107',
    preferredFuelType: preferredFuelType,
    multiFuelCapable: multiFuelCapable,
    tankCapacityL: tankCapacityL,
  );

  ProviderContainer container({
    required List<FillUp> fillUps,
    VehicleProfile? activeVehicle,
  }) {
    final c = ProviderContainer(
      overrides: [
        fillUpListProvider.overrideWith(() => _FakeFillUpList(fillUps)),
        activeVehicleProfileProvider
            .overrideWith(() => _StubActiveVehicle(activeVehicle)),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('allPricesFuelCostModelProvider — degradation', () {
    test('no active vehicle means no cost model at all', () {
      final c = container(
        activeVehicle: null,
        fillUps: [
          fill(id: '1', day: 1, liters: 40, odometerKm: 1000,
              fuelType: FuelType.e10),
          fill(id: '2', day: 10, liters: 30, odometerKm: 1500,
              fuelType: FuelType.e10),
        ],
      );

      final model = c.read(allPricesFuelCostModelProvider);
      expect(model.hasConsumption, isFalse);
      expect(model.usableFuels, isEmpty);
    });

    test('a vehicle with no history keeps its fuels but has no number', () {
      final c = container(
        activeVehicle: vehicle(preferredFuelType: 'e10'),
        fillUps: const [],
      );

      final model = c.read(allPricesFuelCostModelProvider);
      expect(model.hasConsumption, isFalse);
      expect(model.usableFuels, {FuelType.e10});
    });

    test('a single fill yields nothing — one tank is not a measurement', () {
      final c = container(
        activeVehicle: vehicle(preferredFuelType: 'e10'),
        fillUps: [
          fill(id: '1', day: 1, liters: 40, odometerKm: 1000,
              fuelType: FuelType.e10),
        ],
      );

      expect(c.read(allPricesFuelCostModelProvider).hasConsumption, isFalse);
    });

    test('an odometer that never moved produces no number', () {
      final c = container(
        activeVehicle: vehicle(preferredFuelType: 'e10'),
        fillUps: [
          fill(id: '1', day: 1, liters: 40, odometerKm: 1000,
              fuelType: FuelType.e10),
          fill(id: '2', day: 5, liters: 30, odometerKm: 1000,
              fuelType: FuelType.e10),
        ],
      );

      expect(c.read(allPricesFuelCostModelProvider).hasConsumption, isFalse);
    });

    test('a multi-fuel vehicle offers every compatible grade', () {
      final c = container(
        activeVehicle:
            vehicle(preferredFuelType: 'e85', multiFuelCapable: true),
        fillUps: const [],
      );

      final usable = c.read(allPricesFuelCostModelProvider).usableFuels;
      expect(usable, contains(FuelType.e85));
      expect(usable.length, greaterThan(1));
    });
  });

  group('allPricesFuelCostModelProvider — the shared aggregator', () {
    test('one closed single-fuel window gives litres per 100 km', () {
      // 30 L over 500 km = 6,0 L/100 km — the aggregator's pure E85 bucket.
      final c = container(
        activeVehicle: vehicle(preferredFuelType: 'e85'),
        fillUps: [
          fill(id: '1', day: 1, liters: 40, odometerKm: 1000,
              fuelType: FuelType.e85),
          fill(id: '2', day: 10, liters: 30, odometerKm: 1500,
              fuelType: FuelType.e85),
        ],
      );

      final model = c.read(allPricesFuelCostModelProvider);
      expect(model.litersPer100kmByFuel[FuelType.e85], closeTo(6.0, 1e-9));
    });

    test('two fuels are measured independently', () {
      // #3934 — this is the fixture where the deleted private helper and the
      // shared aggregator disagree, and the aggregator now wins.
      //
      // Windows: [1→2] 30 L E85 / 500 km; [2→3] 35 L E10 / 500 km (a grade
      // CROSSOVER — the window opened on an E85 plein); [3→4] 23 L E10 /
      // 500 km. The old helper compared the opening fill's grade with the
      // contributing fills' and DROPPED the crossover, leaving E10 at
      // 4,6 L/100 km. Without a known tank capacity the aggregator falls
      // back to ADR 0015's v2 tally — contributing fills only, so the
      // crossover window is a pure E10 tank at 7,0 — and folds it in:
      // (35 + 23) L / 1000 km = 5,8 L/100 km. Same rule as the consumption
      // screen, which is the point.
      final c = container(
        activeVehicle:
            vehicle(preferredFuelType: 'e85', multiFuelCapable: true),
        fillUps: [
          fill(id: '1', day: 1, liters: 40, odometerKm: 1000,
              fuelType: FuelType.e85),
          fill(id: '2', day: 5, liters: 30, odometerKm: 1500,
              fuelType: FuelType.e85),
          fill(id: '3', day: 9, liters: 35, odometerKm: 2000,
              fuelType: FuelType.e10),
          fill(id: '4', day: 14, liters: 23, odometerKm: 2500,
              fuelType: FuelType.e10),
        ],
      );

      final byFuel = c.read(allPricesFuelCostModelProvider)
          .litersPer100kmByFuel;
      expect(byFuel[FuelType.e85], closeTo(6.0, 1e-9));
      expect(byFuel[FuelType.e10], closeTo(5.8, 1e-9));
    });

    test('a known tank capacity re-buckets the crossover window', () {
      // The same history with the vehicle's 50 L capacity known: ADR 0015 v3
      // classifies every window by what the tank HELD while it was burned —
      // the closing plein belongs to the NEXT tank — so the crossover window
      // is a pure E85 burn (50 L carried E85, no fill strictly inside) and
      // E85 becomes (30 + 35) L / 1000 km = 6,5. The last window then opens
      // on a tank still carrying E85 under its 35 L of E10, so it is an
      // E10/E85 MIX and E10 gets no column at all. Neither answer is
      // reachable from the deleted helper; the point is that the table now
      // moves with the consumption screen.
      final c = container(
        activeVehicle: vehicle(
          preferredFuelType: 'e85',
          multiFuelCapable: true,
          tankCapacityL: 50,
        ),
        fillUps: [
          fill(id: '1', day: 1, liters: 40, odometerKm: 1000,
              fuelType: FuelType.e85),
          fill(id: '2', day: 5, liters: 30, odometerKm: 1500,
              fuelType: FuelType.e85),
          fill(id: '3', day: 9, liters: 35, odometerKm: 2000,
              fuelType: FuelType.e10),
          fill(id: '4', day: 14, liters: 23, odometerKm: 2500,
              fuelType: FuelType.e10),
        ],
      );

      final byFuel = c.read(allPricesFuelCostModelProvider)
          .litersPer100kmByFuel;
      expect(byFuel[FuelType.e85], closeTo(6.5, 1e-9));
      expect(byFuel.containsKey(FuelType.e10), isFalse);
    });

    test(
      'a blended tank stays a mix bucket and becomes no per-grade number',
      () {
        // #3934, ADR 0015 v3: with a known tank capacity, the 50 L of E10
        // carried into the window plus the 20 L of E85 splashed in make a
        // ~71/29 blend — a MIX bucket. A blend is not a grade you can buy,
        // so it credits no column rather than inflating E85's.
        final c = container(
          activeVehicle: vehicle(
            preferredFuelType: 'e85',
            multiFuelCapable: true,
            tankCapacityL: 50,
          ),
          fillUps: [
            fill(id: '1', day: 1, liters: 40, odometerKm: 1000,
                fuelType: FuelType.e10),
            fill(id: '2', day: 5, liters: 20, odometerKm: 1300,
                fuelType: FuelType.e85, isFullTank: false),
            fill(id: '3', day: 9, liters: 20, odometerKm: 1500,
                fuelType: FuelType.e85),
          ],
        );

        final byFuel = c.read(allPricesFuelCostModelProvider)
            .litersPer100kmByFuel;
        expect(byFuel.containsKey(FuelType.e85), isFalse);
        expect(byFuel.containsKey(FuelType.e10), isFalse);
      },
    );

    test('a correction entry does not create a bucket of its own', () {
      // 2 + 28 = 30 L over 500 km; the E85 correction inherits the E10
      // bucket and never enters the composition tally.
      final c = container(
        activeVehicle:
            vehicle(preferredFuelType: 'e10', multiFuelCapable: true),
        fillUps: [
          fill(id: '1', day: 1, liters: 40, odometerKm: 1000,
              fuelType: FuelType.e10),
          fill(id: '2', day: 3, liters: 2, odometerKm: 1200,
              fuelType: FuelType.e85, isFullTank: false, isCorrection: true),
          fill(id: '3', day: 5, liters: 28, odometerKm: 1500,
              fuelType: FuelType.e10),
        ],
      );

      final byFuel = c.read(allPricesFuelCostModelProvider)
          .litersPer100kmByFuel;
      expect(byFuel[FuelType.e10], closeTo(6.0, 1e-9));
      expect(byFuel.containsKey(FuelType.e85), isFalse);
    });
  });

  group('FuelCostModel', () {
    test('the empty model reports no consumption and dims nothing', () {
      expect(FuelCostModel.empty.hasConsumption, isFalse);
      expect(FuelCostModel.empty.usableFuels, isEmpty);
    });
  });
}
