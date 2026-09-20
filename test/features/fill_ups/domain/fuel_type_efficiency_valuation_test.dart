// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/comparison_eligibility.dart';
import 'package:tankstellen/core/domain/fuel/fuel_quantity_unit.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/money_tally.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fuel_type_efficiency_stats.dart';
import 'package:tankstellen/features/fill_ups/domain/services/fuel_type_efficiency_aggregator.dart';
import 'package:tankstellen/features/fill_ups/providers/consumption_providers.dart';
import 'package:tankstellen/features/fill_ups/providers/fuel_type_efficiency_provider.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

/// #4364 — defect 2 (spend vs valuation, later prices rewriting an
/// earlier report), defect 1 (currency) and defect 4 (units), on the
/// NAMED aggregation path `FuelTypeEfficiencyAggregator.byFuelType` and
/// on the provider that ships it (acceptance boxes 5, 7, 10).
FillUp _f({
  required String id,
  required DateTime date,
  required double liters,
  required double cost,
  required double odo,
  FuelType fuel = FuelType.e10,
  String? currency = 'EUR',
  bool full = true,
}) =>
    FillUp(
      id: id,
      date: date,
      liters: liters,
      totalCost: cost,
      odometerKm: odo,
      fuelType: fuel,
      isFullTank: full,
      currency: currency,
    );

/// Three closed E10 windows at a steady 1.50 EUR/L.
List<FillUp> _steadyE10() => [
      _f(id: '1', date: DateTime(2026, 1, 1), liters: 40, cost: 60, odo: 1000),
      _f(id: '2', date: DateTime(2026, 2, 1), liters: 40, cost: 60, odo: 1500),
      _f(id: '3', date: DateTime(2026, 3, 1), liters: 40, cost: 60, odo: 2000),
    ];

FuelTypeEfficiencyStats _bucketOf(
        List<FuelTypeEfficiencyStats> stats, FuelType fuel) =>
    stats.firstWhere((s) => s.bucket.dominant == fuel && !s.isMix);

class _FakeFillUpList extends FillUpList {
  _FakeFillUpList(this._value);
  final List<FillUp> _value;
  @override
  List<FillUp> build() => _value;
}

class _NoVehicles extends VehicleProfileList {
  @override
  List<VehicleProfile> build() => const [];
}

class _NoActiveVehicle extends ActiveVehicleProfile {
  @override
  VehicleProfile? build() => null;
}

void main() {
  group('a later purchase cannot revalue a closed period (box 7)', () {
    test('a 10 EUR/L top-up after the last full tank changes nothing', () {
      final before = FuelTypeEfficiencyAggregator.byFuelType(_steadyE10());

      // An unrelated, wildly expensive PARTIAL fill after every counted
      // window. Before #4364 it entered the volume-weighted pricing table
      // and retroactively revalued both closed intervals.
      final after = FuelTypeEfficiencyAggregator.byFuelType([
        ..._steadyE10(),
        _f(
          id: 'late',
          date: DateTime(2026, 4, 1),
          liters: 40,
          cost: 400,
          odo: 2200,
          full: false,
        ),
      ]);

      final a = _bucketOf(before, FuelType.e10);
      final b = _bucketOf(after, FuelType.e10);
      expect(b.avgCostPerKm, a.avgCostPerKm);
      expect(b.intervalCost, a.intervalCost);
      expect(b.avgPricePerLitre, closeTo(1.50, 1e-9));
    });

    test('the recorded purchase spend of the closed windows is unchanged',
        () {
      final before = _bucketOf(
          FuelTypeEfficiencyAggregator.byFuelType(_steadyE10()), FuelType.e10);
      final after = _bucketOf(
        FuelTypeEfficiencyAggregator.byFuelType([
          ..._steadyE10(),
          _f(
            id: 'late',
            date: DateTime(2026, 4, 1),
            liters: 40,
            cost: 400,
            odo: 2200,
            full: false,
          ),
        ]),
        FuelType.e10,
      );

      expect(before.recordedPurchaseSpend, 120);
      expect(after.recordedPurchaseSpend, 120);
    });
  });

  group('recorded spend is not the modelled valuation (box 7)', () {
    test('a fuel switch separates what was paid from what was burned', () {
      // A full tank of E10 at 1.50, then E85 at 1.00 closes the window.
      // The interval BURNED the carried E10 (valued at 60.00) while the
      // pump charged 40.00 for the E85 that refilled it.
      final stats = FuelTypeEfficiencyAggregator.byFuelType(
        [
          _f(id: '1', date: DateTime(2026, 1, 1), liters: 40, cost: 60, odo: 1000),
          _f(id: '2', date: DateTime(2026, 2, 1), liters: 40, cost: 40, odo: 1500, fuel: FuelType.e85),
          _f(id: '3', date: DateTime(2026, 3, 1), liters: 40, cost: 40, odo: 2000, fuel: FuelType.e85),
        ],
        tankCapacityL: 40,
      );

      final e10 = _bucketOf(stats, FuelType.e10);
      expect(e10.intervalCost, closeTo(60, 1e-9),
          reason: 'modelled consumed-fuel valuation');
      expect(e10.recordedPurchaseSpend, closeTo(40, 1e-9),
          reason: 'what the pump actually charged');
      expect(e10.costValuationBasis, MoneyValuationBasis.modelledConsumedFuel);
    });
  });

  group('currency segregation (boxes 1 + 2)', () {
    test('a DKK fill among EUR fills withholds every money figure', () {
      final stats = FuelTypeEfficiencyAggregator.byFuelType([
        _f(id: '1', date: DateTime(2026, 1, 1), liters: 40, cost: 60, odo: 1000),
        _f(id: '2', date: DateTime(2026, 2, 1), liters: 40, cost: 450, odo: 1500, currency: 'DKK'),
        _f(id: '3', date: DateTime(2026, 3, 1), liters: 40, cost: 60, odo: 2000),
      ]);

      final e10 = _bucketOf(stats, FuelType.e10);
      expect(e10.avgCostPerKm, isNull);
      expect(e10.intervalCost, isNull);
      expect(e10.recordedPurchaseSpend, isNull);
      expect(e10.recordedSpend.amountIn('DKK'), 450);
      expect(e10.recordedSpend.amountIn('EUR'), 60);
      // The quantities survive.
      expect(e10.avgL100km, isNotNull);
      expect(e10.totalDistanceKm, 1000);
    });

    test('unknown-currency fills stay in their own bucket', () {
      final stats = FuelTypeEfficiencyAggregator.byFuelType([
        _f(id: '1', date: DateTime(2026, 1, 1), liters: 40, cost: 60, odo: 1000, currency: null),
        _f(id: '2', date: DateTime(2026, 2, 1), liters: 40, cost: 60, odo: 1500, currency: null),
      ]);

      final e10 = _bucketOf(stats, FuelType.e10);
      expect(e10.recordedSpend.currencies, [kUnknownCurrency]);
      expect(e10.recordedSpend.soleMoney, isNull);
    });
  });

  group('units are not interchangeable (box 5)', () {
    test('a kg-priced fuel gets no L/100 km but keeps its native spend', () {
      final stats = FuelTypeEfficiencyAggregator.byFuelType([
        _f(id: '1', date: DateTime(2026, 1, 1), liters: 12, cost: 18, odo: 1000, fuel: FuelType.cng),
        _f(id: '2', date: DateTime(2026, 2, 1), liters: 12, cost: 18, odo: 1400, fuel: FuelType.cng),
      ]);

      final cng = _bucketOf(stats, FuelType.cng);
      expect(cng.quantityUnit, FuelQuantityUnit.kilogram);
      expect(cng.avgL100km, isNull, reason: 'kg is not litres');
      expect(cng.recordedPurchaseSpend, 18);
      expect(cng.avgCostPerKm, isNotNull, reason: 'money per km is still money');
    });

    test('a kWh-priced fuel likewise reports no L/100 km', () {
      final stats = FuelTypeEfficiencyAggregator.byFuelType([
        _f(id: '1', date: DateTime(2026, 1, 1), liters: 40, cost: 10, odo: 1000, fuel: FuelType.electric),
        _f(id: '2', date: DateTime(2026, 2, 1), liters: 40, cost: 10, odo: 1300, fuel: FuelType.electric),
      ]);

      expect(_bucketOf(stats, FuelType.electric).quantityUnit,
          FuelQuantityUnit.kilowattHour);
      expect(_bucketOf(stats, FuelType.electric).avgL100km, isNull);
    });

    test('a missing price withholds the money, never shrinks it (box 6)', () {
      final stats = FuelTypeEfficiencyAggregator.byFuelType([
        _f(id: '1', date: DateTime(2026, 1, 1), liters: 40, cost: 60, odo: 1000),
        _f(id: '2', date: DateTime(2026, 2, 1), liters: 40, cost: 0, odo: 1500),
        _f(id: '3', date: DateTime(2026, 3, 1), liters: 40, cost: 60, odo: 2000),
      ]);

      final e10 = _bucketOf(stats, FuelType.e10);
      expect(e10.unpricedFillCount, 1);
      expect(e10.avgCostPerKm, isNull);
      expect(e10.recordedPurchaseSpend, isNull);
    });
  });

  group('the provider path carries the correction (box 10)', () {
    ProviderContainer containerWith(List<FillUp> fills) {
      final c = ProviderContainer(overrides: [
        fillUpListProvider.overrideWith(() => _FakeFillUpList(fills)),
        vehicleProfileListProvider.overrideWith(_NoVehicles.new),
        activeVehicleProfileProvider.overrideWith(_NoActiveVehicle.new),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    test('fuelTypeEfficiencyComparisonProvider withholds mixed-currency €/km',
        () {
      final c = containerWith([
        _f(id: '1', date: DateTime(2026, 1, 1), liters: 40, cost: 60, odo: 1000),
        _f(id: '2', date: DateTime(2026, 2, 1), liters: 40, cost: 450, odo: 1500, currency: 'DKK'),
        _f(id: '3', date: DateTime(2026, 3, 1), liters: 40, cost: 60, odo: 2000),
      ]);

      final rows = c.read(fuelTypeEfficiencyComparisonProvider);
      expect(rows, isNotEmpty);
      expect(_bucketOf(rows, FuelType.e10).avgCostPerKm, isNull);
    });

    test('consumptionStatsProvider withholds the mixed-currency total', () {
      final c = containerWith([
        _f(id: '1', date: DateTime(2026, 1, 1), liters: 20, cost: 30, odo: 1000),
        _f(id: '2', date: DateTime(2026, 2, 1), liters: 30, cost: 225, odo: 1500, currency: 'DKK'),
      ]);

      final stats = c.read(consumptionStatsProvider);
      expect(stats.totalSpent, isNull);
      expect(stats.spend.amountIn('DKK'), 225);
      expect(stats.spend.amountIn('EUR'), 30);
    });
  });
}
