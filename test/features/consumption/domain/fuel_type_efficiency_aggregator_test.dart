// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/domain/entities/fuel_type_efficiency_stats.dart';
import 'package:tankstellen/features/consumption/domain/services/fuel_type_efficiency_aggregator.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// Coverage for [FuelTypeEfficiencyAggregator] under the v2 COMPOSITION-BUCKET
/// model (Epic #2881, #2928, ADR 0015 — supersedes ADR 0014's dominant-fuel
/// collapse).
///
/// Each closed plein-to-plein interval is now classified by its fuel
/// composition: a tank ≥ 85 % one fuel is a PURE bucket (e.g. `E85`), a more
/// even blend is a `dominant/secondary` MIX bucket (`E85/E10`). Pure and mix
/// buckets are directly comparable; the verdict compares across all of them.

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

/// Find the bucket stats with the given language-neutral [label]
/// (`E85` / `E85/E10`), failing loudly if absent.
FuelTypeEfficiencyStats _byLabel(
  List<FuelTypeEfficiencyStats> all,
  String label,
) =>
    all.firstWhere(
      (s) => s.label == label,
      orElse: () => throw StateError(
        'no bucket "$label" in ${all.map((s) => s.label).toList()}',
      ),
    );

bool _has(List<FuelTypeEfficiencyStats> all, String label) =>
    all.any((s) => s.label == label);

void main() {
  group('FuelTypeEfficiencyAggregator.byFuelType — composition buckets', () {
    test('empty list returns empty list', () {
      expect(FuelTypeEfficiencyAggregator.byFuelType(const []), isEmpty);
    });

    test('mono-fuel interval → a single PURE bucket (not a mix)', () {
      final fills = [
        _f(id: 'a', date: _d(1), liters: 40, cost: 60, odo: 0,
            fuelType: FuelType.e85),
        _f(id: 'b', date: _d(2), liters: 30, cost: 45, odo: 600,
            fuelType: FuelType.e85), // closes
      ];
      final result = FuelTypeEfficiencyAggregator.byFuelType(fills);
      expect(result.length, 1);
      final e85 = result.single;
      expect(e85.label, 'E85');
      expect(e85.isMix, isFalse);
      expect(e85.dominant.apiValue, FuelType.e85.apiValue);
      expect(e85.secondary, isNull);
      expect(e85.attributedIntervalCount, 1);
      expect(e85.avgL100km, closeTo(30 / 600 * 100, 1e-9));
    });

    test('90% E85 + 10% E10 (minority ≤ 15%) → PURE "E85" bucket', () {
      // One closed interval: contributing fills E85=45, E10=5 (10% minority).
      final fills = [
        _f(id: 'open', date: _d(1), liters: 40, cost: 40, odo: 0,
            fuelType: FuelType.e85),
        _f(id: 'top', date: _d(2), liters: 5, cost: 8, odo: 200,
            fuelType: FuelType.e10, isFullTank: false), // 10% minority
        _f(id: 'close', date: _d(3), liters: 45, cost: 45, odo: 1000,
            fuelType: FuelType.e85), // closes; E85 90%
      ];
      final result = FuelTypeEfficiencyAggregator.byFuelType(fills);
      // 45+5 = 50 L, E85 share 45/50 = 90% ≥ 85% → PURE E85, NOT a mix.
      expect(result.length, 1);
      final e85 = result.single;
      expect(e85.label, 'E85');
      expect(e85.isMix, isFalse);
      expect(e85.secondary, isNull);
      expect(e85.attributedIntervalCount, 1);
      // No "E85/E10" mix bucket exists.
      expect(_has(result, 'E85/E10'), isFalse);
    });

    test('exactly 15% minority → PURE (inclusive boundary)', () {
      // E85 = 85 L, E10 = 15 L → minority exactly 15% → pure E85.
      final fills = [
        _f(id: 'open', date: _d(1), liters: 40, cost: 40, odo: 0,
            fuelType: FuelType.e85),
        _f(id: 'top', date: _d(2), liters: 15, cost: 24, odo: 200,
            fuelType: FuelType.e10, isFullTank: false), // 15% minority
        _f(id: 'close', date: _d(3), liters: 85, cost: 85, odo: 1000,
            fuelType: FuelType.e85), // closes; E85 = 85 / 100 = 85%
      ];
      final result = FuelTypeEfficiencyAggregator.byFuelType(fills);
      expect(result.length, 1);
      expect(result.single.label, 'E85');
      expect(result.single.isMix, isFalse);
      expect(_has(result, 'E85/E10'), isFalse);
    });

    test('70% E85 + 30% E10 (E85 major) → MIX "E85/E10"', () {
      // E85 = 70 L, E10 = 30 L → 30% minority > 15% → mix, E85 dominant.
      final fills = [
        _f(id: 'open', date: _d(1), liters: 40, cost: 40, odo: 0,
            fuelType: FuelType.e85),
        _f(id: 'top', date: _d(2), liters: 30, cost: 48, odo: 300,
            fuelType: FuelType.e10, isFullTank: false), // 30% minority
        _f(id: 'close', date: _d(3), liters: 70, cost: 70, odo: 1000,
            fuelType: FuelType.e85), // closes; E85 = 70 / 100 = 70%
      ];
      final result = FuelTypeEfficiencyAggregator.byFuelType(fills);
      expect(result.length, 1);
      final mix = result.single;
      expect(mix.label, 'E85/E10'); // dominant first
      expect(mix.isMix, isTrue);
      expect(mix.dominant.apiValue, FuelType.e85.apiValue);
      expect(mix.secondary?.apiValue, FuelType.e10.apiValue);
      // No pure buckets for this interval.
      expect(_has(result, 'E85'), isFalse);
      expect(_has(result, 'E10'), isFalse);
    });

    test('70% E10 + 30% E85 (E10 major) → MIX "E10/E85"', () {
      // E10 = 70 L, E85 = 30 L → 30% minority > 15% → mix, E10 dominant.
      final fills = [
        _f(id: 'open', date: _d(1), liters: 40, cost: 40, odo: 0,
            fuelType: FuelType.e10),
        _f(id: 'top', date: _d(2), liters: 30, cost: 30, odo: 300,
            fuelType: FuelType.e85, isFullTank: false), // 30% minority
        _f(id: 'close', date: _d(3), liters: 70, cost: 112, odo: 1000,
            fuelType: FuelType.e10), // closes; E10 = 70%
      ];
      final result = FuelTypeEfficiencyAggregator.byFuelType(fills);
      expect(result.length, 1);
      final mix = result.single;
      expect(mix.label, 'E10/E85'); // dominant (E10) first
      expect(mix.isMix, isTrue);
      expect(mix.dominant.apiValue, FuelType.e10.apiValue);
      expect(mix.secondary?.apiValue, FuelType.e85.apiValue);
    });

    test(
        'pure E85 + an E85/E10 mix both present → BOTH appear, cheapestPerKm '
        'compares across them', () {
      // Two pure-E85 closed intervals + two E85/E10 mix intervals. Make the
      // mix CHEAPER per km so the verdict crowns the mix across buckets.
      final fills = [
        // ── Pure E85 interval 1: 50 L over 500 km, €50 → 0.10 €/km ──
        _f(id: 'p0', date: _d(1), liters: 40, cost: 40, odo: 0,
            fuelType: FuelType.e85),
        _f(id: 'p1', date: _d(2), liters: 50, cost: 50, odo: 500,
            fuelType: FuelType.e85),
        // ── Pure E85 interval 2: 50 L over 500 km, €50 → 0.10 €/km ──
        _f(id: 'p2', date: _d(3), liters: 50, cost: 50, odo: 1000,
            fuelType: FuelType.e85),
        // ── Mix E85/E10 interval 1: E85 35 + E10 15 = 50 L (E10 30%),
        //     800 km, €40 → 0.05 €/km ──
        _f(id: 'm1a', date: _d(4), liters: 15, cost: 12, odo: 1300,
            fuelType: FuelType.e10, isFullTank: false),
        _f(id: 'm1b', date: _d(5), liters: 35, cost: 28, odo: 1800,
            fuelType: FuelType.e85), // closes; E85 70% dominant
        // ── Mix E85/E10 interval 2: same shape, 800 km, €40 → 0.05 €/km ──
        _f(id: 'm2a', date: _d(6), liters: 15, cost: 12, odo: 2100,
            fuelType: FuelType.e10, isFullTank: false),
        _f(id: 'm2b', date: _d(7), liters: 35, cost: 28, odo: 2600,
            fuelType: FuelType.e85), // closes; E85 70% dominant
      ];

      final result = FuelTypeEfficiencyAggregator.byFuelType(fills);
      // BOTH buckets exist, distinct and comparable.
      expect(_has(result, 'E85'), isTrue);
      expect(_has(result, 'E85/E10'), isTrue);
      final pure = _byLabel(result, 'E85');
      final mix = _byLabel(result, 'E85/E10');
      expect(pure.isMix, isFalse);
      expect(mix.isMix, isTrue);
      expect(pure.attributedIntervalCount, 2);
      expect(mix.attributedIntervalCount, 2);

      // Both clear the verdict gate → cheapest compares ACROSS pure + mix.
      final crowned = FuelTypeEfficiencyAggregator.cheapestPerKm(result);
      expect(crowned, isNotNull);
      expect(crowned!.label, 'E85/E10',
          reason: 'the cheaper-per-km mix wins across pure + mix buckets');
    });

    test('only-used: a fuel never used produces no bucket', () {
      // Only E85 logged → E10/Diesel/etc never appear.
      final fills = [
        _f(id: 'a', date: _d(1), liters: 40, cost: 40, odo: 0,
            fuelType: FuelType.e85),
        _f(id: 'b', date: _d(2), liters: 30, cost: 30, odo: 600,
            fuelType: FuelType.e85),
      ];
      final result = FuelTypeEfficiencyAggregator.byFuelType(fills);
      expect(result.length, 1);
      expect(result.single.label, 'E85');
      expect(_has(result, 'E10'), isFalse);
      expect(_has(result, 'Diesel'), isFalse);
      expect(_has(result, 'E85/E10'), isFalse);
    });

    test('3-way blend folds into the TWO-LARGEST mix label, all litres kept',
        () {
      // E85 50 + E10 30 + E5 20 = 100 L (E85 dominant 50%, E10 second 30%).
      // Label = E85/E10; the E5 litres still fold into that bucket.
      final fills = [
        _f(id: 'open', date: _d(1), liters: 30, cost: 30, odo: 0,
            fuelType: FuelType.e85),
        _f(id: 't1', date: _d(2), liters: 30, cost: 48, odo: 200,
            fuelType: FuelType.e10, isFullTank: false),
        _f(id: 't2', date: _d(3), liters: 20, cost: 34, odo: 400,
            fuelType: FuelType.e5, isFullTank: false),
        _f(id: 'close', date: _d(4), liters: 50, cost: 50, odo: 1000,
            fuelType: FuelType.e85), // closes
      ];
      final result = FuelTypeEfficiencyAggregator.byFuelType(fills);
      expect(result.length, 1);
      final mix = result.single;
      expect(mix.label, 'E85/E10'); // two largest, dominant first
      expect(mix.isMix, isTrue);
      // All litres folded: 50 + 30 + 20 = 100 over 1000 km.
      expect(mix.avgL100km, closeTo(100 / 1000 * 100, 1e-9));
    });

    test('correction in interval inherits the bucket, never enters tally', () {
      // Pure E85 interval with a large E10-typed CORRECTION. The correction
      // must NOT create a mix and NOT enter the composition tally.
      final fills = [
        _f(id: 'a', date: _d(1), liters: 40, cost: 60, odo: 0,
            fuelType: FuelType.e85),
        _f(id: 'corr', date: _d(2), liters: 999, cost: 0, odo: 300,
            fuelType: FuelType.e10, isFullTank: false, isCorrection: true),
        _f(id: 'b', date: _d(3), liters: 30, cost: 45, odo: 600,
            fuelType: FuelType.e85), // closes
      ];
      final result = FuelTypeEfficiencyAggregator.byFuelType(fills);
      expect(result.length, 1);
      final e85 = result.single;
      expect(e85.label, 'E85'); // pure, no mix despite the E10 correction
      expect(e85.isMix, isFalse);
      // Interval litres include the correction (inherits the bucket).
      expect(e85.avgL100km, closeTo((30 + 999) / 600 * 100, 1e-9));
      // Cost excludes the zero-cost correction.
      expect(e85.avgCostPerKm, closeTo(45 / 600, 1e-9));
      // fillCount counts only the non-correction fill (just the closing).
      expect(e85.fillCount, 1);
    });

    test('single fill → no closed interval → empty', () {
      final result = FuelTypeEfficiencyAggregator.byFuelType([
        _f(id: 'only', date: _d(1), liters: 40, cost: 60, odo: 100),
      ]);
      // The opening fill anchors no closed interval, so no bucket emerges.
      expect(result, isEmpty);
    });

    test('verdict gate returns null below the threshold', () {
      // Pure E85 has 2 intervals, pure E10 has only 1 → gate stays shut.
      final fills = [
        _f(id: 'a', date: _d(1), liters: 40, cost: 60, odo: 0,
            fuelType: FuelType.e85),
        _f(id: 'b', date: _d(2), liters: 30, cost: 45, odo: 600,
            fuelType: FuelType.e85), // E85 interval 1
        _f(id: 'c', date: _d(3), liters: 25, cost: 38, odo: 1100,
            fuelType: FuelType.e85), // E85 interval 2
        _f(id: 'd', date: _d(4), liters: 45, cost: 76, odo: 1600,
            fuelType: FuelType.e10), // E10 interval 1 only
      ];
      final result = FuelTypeEfficiencyAggregator.byFuelType(fills);
      expect(_byLabel(result, 'E10').attributedIntervalCount, 1);
      expect(FuelTypeEfficiencyAggregator.cheapestPerKm(result), isNull);
    });

    test('odometer-reset (negative delta) clamps to 0 without crashing', () {
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
      expect(e10.label, 'E10');
      expect(e10.attributedIntervalCount, 1); // interval closed
      expect(e10.avgL100km, isNull); // zero distance → null
      expect(e10.avgCostPerKm, isNull);
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

    test('result is sorted by €/km ascending across buckets', () {
      // Pure E85 @ 0.10 €/km, pure E10 @ ~0.13 €/km → E85 sorts first.
      final fills = [
        _f(id: 'e85a', date: _d(1), liters: 40, cost: 40, odo: 0,
            fuelType: FuelType.e85),
        _f(id: 'e85b', date: _d(2), liters: 50, cost: 50, odo: 500,
            fuelType: FuelType.e85), // 0.10 €/km
        _f(id: 'e10a', date: _d(3), liters: 50, cost: 80, odo: 600,
            fuelType: FuelType.e10),
        _f(id: 'e10b', date: _d(4), liters: 40, cost: 64, odo: 1100,
            fuelType: FuelType.e10), // 64/500 = 0.128 €/km
      ];
      final result = FuelTypeEfficiencyAggregator.byFuelType(fills);
      expect(result.first.label, 'E85');
      expect(result.last.label, 'E10');
    });
  });
}
