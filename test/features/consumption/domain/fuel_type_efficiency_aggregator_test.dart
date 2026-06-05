// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/domain/entities/fuel_type_efficiency_stats.dart';
import 'package:tankstellen/features/consumption/domain/services/fuel_type_efficiency_aggregator.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// Coverage for [FuelTypeEfficiencyAggregator] (Epic #2881, child #2883).
///
/// The decision-doc worked example
/// (`docs/decisions/per-fuel-efficiency-attribution.md`) is turned into
/// assertions verbatim, plus the dominant-fuel edge cases the doc enumerates:
/// mono interval, mixed → dominant + mixedIntervalCount, single fill → null
/// metrics, correction inheritance never flipping dominance, verdict gate
/// boundary, and odometer-reset (negative delta) clamping.

FillUp _f({
  required String id,
  required DateTime date,
  required double liters,
  required double cost,
  required double odo,
  FuelType fuelType = FuelType.e10,
  bool isFullTank = true,
  bool isCorrection = false,
  String? vehicleId,
}) =>
    FillUp(
      id: id,
      date: date,
      liters: liters,
      totalCost: cost,
      odometerKm: odo,
      fuelType: fuelType,
      isFullTank: isFullTank,
      isCorrection: isCorrection,
      vehicleId: vehicleId,
    );

DateTime _d(int day) => DateTime(2026, 1, day);

FuelTypeEfficiencyStats _statsFor(
  List<FuelTypeEfficiencyStats> all,
  FuelType fuel,
) =>
    all.firstWhere((s) => s.fuelType.apiValue == fuel.apiValue);

void main() {
  group('FuelTypeEfficiencyAggregator.byFuelType', () {
    test('empty list returns empty list', () {
      expect(FuelTypeEfficiencyAggregator.byFuelType(const []), isEmpty);
    });

    test('decision-doc worked example — frozen per-fuel numbers', () {
      // F0..F5 from per-fuel-efficiency-attribution.md.
      final fills = [
        _f(id: 'F0', date: _d(1), liters: 40, cost: 68.00, odo: 0,
            fuelType: FuelType.e10),
        _f(id: 'F1', date: _d(2), liters: 30, cost: 51.00, odo: 600,
            fuelType: FuelType.e10),
        _f(id: 'F2', date: _d(3), liters: 45, cost: 45.00, odo: 1100,
            fuelType: FuelType.e85),
        _f(id: 'F3', date: _d(4), liters: 20, cost: 20.00, odo: 1400,
            fuelType: FuelType.e85, isFullTank: false),
        _f(id: 'F4', date: _d(5), liters: 35, cost: 59.50, odo: 1700,
            fuelType: FuelType.e10),
        _f(id: 'F5', date: _d(6), liters: 50, cost: 50.00, odo: 2300,
            fuelType: FuelType.e85),
      ];

      final result = FuelTypeEfficiencyAggregator.byFuelType(fills);
      expect(result.length, 2);

      // Sorted by €/km ascending — E85 (cheaper per km) first.
      expect(result.first.fuelType.apiValue, FuelType.e85.apiValue);
      expect(result.last.fuelType.apiValue, FuelType.e10.apiValue);

      final e10 = _statsFor(result, FuelType.e10);
      expect(e10.avgL100km, closeTo(7.0833, 1e-3)); // 85 / 1200 * 100
      expect(e10.avgCostPerKm, closeTo(0.108750, 1e-6)); // 130.50 / 1200
      expect(e10.totalSpent, closeTo(178.50, 1e-9)); // 68 + 51 + 59.50
      expect(e10.fillCount, 3); // F0, F1, F4
      expect(e10.attributedIntervalCount, 2); // A + C
      expect(e10.mixedIntervalCount, 1); // C

      final e85 = _statsFor(result, FuelType.e85);
      expect(e85.avgL100km, closeTo(8.6364, 1e-3)); // 95 / 1100 * 100
      expect(e85.avgCostPerKm, closeTo(0.086364, 1e-6)); // 95 / 1100
      expect(e85.totalSpent, closeTo(115.00, 1e-9)); // 45 + 20 + 50
      expect(e85.fillCount, 3); // F2, F3, F5
      expect(e85.attributedIntervalCount, 2); // B + D
      expect(e85.mixedIntervalCount, 0);

      // Verdict: both clear the gate; E85 wins per km despite more L/100km.
      expect(
        FuelTypeEfficiencyAggregator.cheapestPerKm(result)?.apiValue,
        FuelType.e85.apiValue,
      );
    });

    test('mono-fuel intervals attribute correctly (no mixing)', () {
      final fills = [
        _f(id: 'a', date: _d(1), liters: 40, cost: 60, odo: 0),
        _f(id: 'b', date: _d(2), liters: 30, cost: 45, odo: 600), // closes
        _f(id: 'c', date: _d(3), liters: 25, cost: 40, odo: 1100), // closes
      ];

      final result = FuelTypeEfficiencyAggregator.byFuelType(fills);
      expect(result.length, 1);
      final e10 = result.single;
      // Two closed intervals, distance 600 + 500 = 1100, litres 30 + 25 = 55.
      expect(e10.attributedIntervalCount, 2);
      expect(e10.mixedIntervalCount, 0);
      expect(e10.avgL100km, closeTo(55 / 1100 * 100, 1e-9));
      expect(e10.avgCostPerKm, closeTo((45 + 40) / 1100, 1e-9));
      expect(e10.fillCount, 3);
    });

    test('mixed interval → dominant fuel, mixedIntervalCount increments', () {
      // One closed interval containing E85 (60 L) + E10 (20 L). E85 dominates.
      final fills = [
        _f(id: 'a', date: _d(1), liters: 40, cost: 40, odo: 0,
            fuelType: FuelType.e85),
        _f(id: 'b', date: _d(2), liters: 60, cost: 60, odo: 500,
            fuelType: FuelType.e85, isFullTank: false),
        _f(id: 'c', date: _d(3), liters: 20, cost: 34, odo: 1000,
            fuelType: FuelType.e10), // closes
      ];

      final result = FuelTypeEfficiencyAggregator.byFuelType(fills);
      final e85 = _statsFor(result, FuelType.e85);
      // Whole interval (litres 60+20=80, distance 1000, cost 60+34=94)
      // attributed to E85 (60 L > 20 L).
      expect(e85.attributedIntervalCount, 1);
      expect(e85.mixedIntervalCount, 1);
      expect(e85.avgL100km, closeTo(80 / 1000 * 100, 1e-9));
      expect(e85.avgCostPerKm, closeTo(94 / 1000, 1e-9));

      // E10 was a minority → it appears (has a fill) but with null metrics.
      final e10 = _statsFor(result, FuelType.e10);
      expect(e10.attributedIntervalCount, 0);
      expect(e10.avgL100km, isNull);
      expect(e10.avgCostPerKm, isNull);
      expect(e10.fillCount, 1);
      expect(e10.totalSpent, closeTo(34, 1e-9));
    });

    test('single fill → null per-km metrics (no closed interval)', () {
      final result = FuelTypeEfficiencyAggregator.byFuelType([
        _f(id: 'only', date: _d(1), liters: 40, cost: 60, odo: 100),
      ]);
      expect(result.length, 1);
      final s = result.single;
      expect(s.attributedIntervalCount, 0);
      expect(s.avgL100km, isNull);
      expect(s.avgCostPerKm, isNull);
      expect(s.fillCount, 1);
      expect(s.totalSpent, closeTo(60, 1e-9));
      expect(s.mixedIntervalCount, 0);
    });

    test('correction in interval inherits dominant fuel, never flips it', () {
      // E10 opens + closes; a large E85-typed CORRECTION sits inside. The
      // correction must NOT win dominance even though its litres exceed the
      // real E10 fill — corrections never enter the tally.
      final fills = [
        _f(id: 'a', date: _d(1), liters: 40, cost: 60, odo: 0,
            fuelType: FuelType.e10),
        _f(id: 'corr', date: _d(2), liters: 999, cost: 0, odo: 300,
            fuelType: FuelType.e85, isFullTank: false, isCorrection: true),
        _f(id: 'b', date: _d(3), liters: 30, cost: 45, odo: 600,
            fuelType: FuelType.e10), // closes
      ];

      final result = FuelTypeEfficiencyAggregator.byFuelType(fills);
      // E85 must NOT appear at all — the correction is its only "fill" and
      // corrections are excluded from per-fill facts too.
      expect(
        result.any((s) => s.fuelType.apiValue == FuelType.e85.apiValue),
        isFalse,
      );
      final e10 = _statsFor(result, FuelType.e10);
      expect(e10.attributedIntervalCount, 1);
      // Interval litres include the correction (inherits E10): 30 + 999.
      expect(e10.avgL100km, closeTo((30 + 999) / 600 * 100, 1e-9));
      // Cost excludes the zero-cost correction: just the 45.
      expect(e10.avgCostPerKm, closeTo(45 / 600, 1e-9));
      // mixedIntervalCount counts >1 NON-correction fuel — here only E10.
      expect(e10.mixedIntervalCount, 0);
      // Per-fill facts ignore the correction.
      expect(e10.fillCount, 2);
      expect(e10.totalSpent, closeTo(105, 1e-9)); // 60 + 45
    });

    test('verdict gate returns null below the threshold', () {
      // Two fuels, but E85 has only ONE attributed interval (< 2).
      final fills = [
        _f(id: 'a', date: _d(1), liters: 40, cost: 60, odo: 0,
            fuelType: FuelType.e10),
        _f(id: 'b', date: _d(2), liters: 30, cost: 45, odo: 600,
            fuelType: FuelType.e10), // closes E10 interval 1
        _f(id: 'c', date: _d(3), liters: 25, cost: 38, odo: 1100,
            fuelType: FuelType.e10), // closes E10 interval 2
        _f(id: 'd', date: _d(4), liters: 45, cost: 45, odo: 1600,
            fuelType: FuelType.e85), // closes E85 interval 1 only
      ];

      final result = FuelTypeEfficiencyAggregator.byFuelType(fills);
      final e85 = _statsFor(result, FuelType.e85);
      expect(e85.attributedIntervalCount, 1); // below threshold
      expect(FuelTypeEfficiencyAggregator.cheapestPerKm(result), isNull);
    });

    test('verdict gate returns the right winner at/above the threshold', () {
      // E10: 2 intervals @ pricey per km. E85: 2 intervals @ cheaper per km.
      final fills = [
        // E10 interval 1
        _f(id: 'a', date: _d(1), liters: 40, cost: 68, odo: 0,
            fuelType: FuelType.e10),
        _f(id: 'b', date: _d(2), liters: 30, cost: 51, odo: 600,
            fuelType: FuelType.e10),
        // E85 interval 1
        _f(id: 'c', date: _d(3), liters: 45, cost: 45, odo: 1100,
            fuelType: FuelType.e85),
        // E85 interval 2
        _f(id: 'd', date: _d(4), liters: 50, cost: 50, odo: 1700,
            fuelType: FuelType.e85),
        // E10 interval 2
        _f(id: 'e', date: _d(5), liters: 35, cost: 60, odo: 2200,
            fuelType: FuelType.e10),
      ];

      final result = FuelTypeEfficiencyAggregator.byFuelType(fills);
      expect(_statsFor(result, FuelType.e10).attributedIntervalCount, 2);
      expect(_statsFor(result, FuelType.e85).attributedIntervalCount, 2);
      expect(
        FuelTypeEfficiencyAggregator.cheapestPerKm(result)?.apiValue,
        FuelType.e85.apiValue,
      );
    });

    test('odometer-reset (negative delta) clamps to 0 without crashing', () {
      // The closing fill's odometer is LOWER than the opening — a reset or
      // bad import. Distance clamps to 0 → that interval contributes no
      // distance, so per-km metrics stay null (no division by zero).
      final fills = [
        _f(id: 'a', date: _d(1), liters: 40, cost: 60, odo: 5000),
        _f(id: 'b', date: _d(2), liters: 30, cost: 45, odo: 100), // reset
      ];

      late List<FuelTypeEfficiencyStats> result;
      expect(
        () => result = FuelTypeEfficiencyAggregator.byFuelType(fills),
        returnsNormally,
      );
      final e10 = result.single;
      expect(e10.attributedIntervalCount, 1); // interval closed
      expect(e10.avgL100km, isNull); // zero distance → null
      expect(e10.avgCostPerKm, isNull);
      expect(e10.fillCount, 2);
      expect(e10.totalSpent, closeTo(105, 1e-9));
    });

    test('tie on litres → closing plein fuel wins', () {
      // Interval contributes E10 30 L + E85 30 L (tie). Closing fill is E85.
      final fills = [
        _f(id: 'a', date: _d(1), liters: 40, cost: 40, odo: 0,
            fuelType: FuelType.e10),
        _f(id: 'b', date: _d(2), liters: 30, cost: 51, odo: 400,
            fuelType: FuelType.e10, isFullTank: false),
        _f(id: 'c', date: _d(3), liters: 30, cost: 30, odo: 1000,
            fuelType: FuelType.e85), // closing plein E85
      ];

      final result = FuelTypeEfficiencyAggregator.byFuelType(fills);
      final e85 = _statsFor(result, FuelType.e85);
      expect(e85.attributedIntervalCount, 1); // tie → closing E85 wins
      expect(e85.mixedIntervalCount, 1);
      final e10 = _statsFor(result, FuelType.e10);
      expect(e10.attributedIntervalCount, 0);
    });

    test('unsorted input is handled (sorts chronologically first)', () {
      final fills = [
        _f(id: 'b', date: _d(2), liters: 30, cost: 45, odo: 600),
        _f(id: 'a', date: _d(1), liters: 40, cost: 60, odo: 0),
      ];
      final result = FuelTypeEfficiencyAggregator.byFuelType(fills);
      final e10 = result.single;
      expect(e10.attributedIntervalCount, 1);
      expect(e10.avgL100km, closeTo(30 / 600 * 100, 1e-9));
    });
  });
}
