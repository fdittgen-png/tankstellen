// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fuel_type_efficiency_stats.dart';
import 'package:tankstellen/features/fill_ups/domain/services/fuel_type_efficiency_aggregator.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';

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

    test('v2 tests above pass NO tankCapacityL — v3 (#3764) is opt-in, so '
        'every legacy assertion is unchanged and each interval is marked '
        'legacy-attributed', () {
      final fills = [
        _f(id: 'a', date: _d(1), liters: 40, cost: 60, odo: 0,
            fuelType: FuelType.e85),
        _f(id: 'b', date: _d(2), liters: 30, cost: 45, odo: 600,
            fuelType: FuelType.e85),
      ];
      final result = FuelTypeEfficiencyAggregator.byFuelType(fills);
      expect(result.single.attributedIntervalCount, 1);
      expect(result.single.legacyAttributedIntervalCount, 1,
          reason: 'no capacity → contributing-fills-only fallback, marked');
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

  // ── v3 (#3764, ADR 0015 v3 amendment) — carried-content composition ──
  //
  // With a known tank capacity, each interval opening on a physical plein is
  // classified by the tank content it actually burned: capacity × the #3652
  // mix-chain shares as of the opening fill, plus the non-correction fills
  // strictly inside the interval (the closing plein is excluded — its fuel
  // enters the NEXT interval's tank). All v2 tests above pass no capacity
  // and were reviewed: none needed changes, because v3 is capacity-opt-in.
  group('FuelTypeEfficiencyAggregator.byFuelType — v3 carried content', () {
    const capacity = 35.0;

    test('the reporting user\'s case: 14 L E5 in the tank + 21 L E85 to '
        'full → the next interval buckets as the 40/60 E85/E5 MIX', () {
      final fills = [
        // Opening plein: pure E5 full tank (35 L).
        _f(id: 'f0', date: _d(1), liters: 35, cost: 60, odo: 0,
            fuelType: FuelType.e5),
        // 14 L E5 left, +21 L E85 to full → tank = 40 % E5 / 60 % E85.
        // Closes interval A (which burned the pure-E5 tank).
        _f(id: 'f1', date: _d(2), liters: 21, cost: 17, odo: 300,
            fuelType: FuelType.e85),
        // Next plein closes interval B — the one that burned the blend.
        _f(id: 'f2', date: _d(3), liters: 30, cost: 24, odo: 700,
            fuelType: FuelType.e85),
      ];
      final result = FuelTypeEfficiencyAggregator.byFuelType(
        fills,
        tankCapacityL: capacity,
      );

      // Interval A burned the pure-E5 opening tank — pure E5, even though
      // its closing plein pumped E85 (v2 called this interval pure E85).
      final e5 = _byLabel(result, 'E5');
      expect(e5.isMix, isFalse);
      expect(e5.attributedIntervalCount, 1);
      expect(e5.legacyAttributedIntervalCount, 0);
      // Metric folding unchanged: interval A = 21 L over 300 km, €17.
      expect(e5.avgL100km, closeTo(21 / 300 * 100, 1e-9));
      // #3846: the money follows the fuel BURNED, not the cash handed over
      // at the close. This interval burned 21 L of the pure-E5 tank, so it
      // is charged E5's own price (60/35), NOT the 17 EUR paid for the E85
      // that refilled it. Charging the 17 EUR here is what made the E5
      // bucket report E85's cheap per-litre rate on the user's screen.
      expect(e5.avgCostPerKm, closeTo(21 * (60 / 35) / 300, 1e-9));

      // Interval B burned the 14/21 = 40/60 blend — MIX, dominant E85.
      final blend = _byLabel(result, 'E85/E5');
      expect(blend.isMix, isTrue);
      expect(blend.dominant.apiValue, FuelType.e85.apiValue);
      expect(blend.secondary?.apiValue, FuelType.e5.apiValue);
      expect(blend.attributedIntervalCount, 1);
      expect(blend.legacyAttributedIntervalCount, 0);
      // Metric folding unchanged: interval B = 30 L over 400 km.
      expect(blend.avgL100km, closeTo(30 / 400 * 100, 1e-9));

      // No pure-E85 bucket exists — v2's misattribution is gone.
      expect(_has(result, 'E85'), isFalse);
    });

    test('truly run dry before the switch → the new tank stays PURE '
        '(prior content 0 pins the mix to the new grade)', () {
      final fills = [
        _f(id: 'f0', date: _d(1), liters: 35, cost: 60, odo: 0,
            fuelType: FuelType.e5),
        // Ran the E5 tank dry: a full 35 L E85 fill → prior = 35 − 35 = 0.
        _f(id: 'f1', date: _d(2), liters: 35, cost: 28, odo: 500,
            fuelType: FuelType.e85),
        _f(id: 'f2', date: _d(3), liters: 30, cost: 24, odo: 900,
            fuelType: FuelType.e85),
      ];
      final result = FuelTypeEfficiencyAggregator.byFuelType(
        fills,
        tankCapacityL: capacity,
      );

      // Interval A burned pure E5; interval B burned pure E85. No blend.
      expect(_byLabel(result, 'E5').isMix, isFalse);
      final e85 = _byLabel(result, 'E85');
      expect(e85.isMix, isFalse);
      expect(e85.attributedIntervalCount, 1);
      expect(e85.legacyAttributedIntervalCount, 0);
      expect(_has(result, 'E85/E5'), isFalse);
      expect(_has(result, 'E5/E85'), isFalse);
    });

    test('capacity unknown → EXACT v2 fallback (contributing fills only), '
        'every interval marked legacy-attributed', () {
      // Same fills as the user's case, but no capacity: both closed
      // intervals tally only their contributing E85 pleins → one pure E85
      // bucket, no E5 anywhere — bit-for-bit the v2 outcome.
      final fills = [
        _f(id: 'f0', date: _d(1), liters: 35, cost: 60, odo: 0,
            fuelType: FuelType.e5),
        _f(id: 'f1', date: _d(2), liters: 21, cost: 17, odo: 300,
            fuelType: FuelType.e85),
        _f(id: 'f2', date: _d(3), liters: 30, cost: 24, odo: 700,
            fuelType: FuelType.e85),
      ];
      final result = FuelTypeEfficiencyAggregator.byFuelType(fills);
      expect(result.length, 1);
      final e85 = result.single;
      expect(e85.label, 'E85');
      expect(e85.attributedIntervalCount, 2);
      expect(e85.legacyAttributedIntervalCount, 2);
      expect(_has(result, 'E5'), isFalse);
      expect(_has(result, 'E85/E5'), isFalse);
    });

    test('interval opening on a NON-plein first fill is legacy-attributed '
        'even with capacity; later plein-anchored intervals are not', () {
      final fills = [
        // First fill is PARTIAL → interval A's opening content unknowable.
        _f(id: 'f0', date: _d(1), liters: 20, cost: 34, odo: 0,
            fuelType: FuelType.e5, isFullTank: false),
        _f(id: 'f1', date: _d(2), liters: 30, cost: 24, odo: 400,
            fuelType: FuelType.e85), // closes A (legacy: pure E85)
        _f(id: 'f2', date: _d(3), liters: 30, cost: 24, odo: 800,
            fuelType: FuelType.e85), // closes B (v3: content 30 E85 + 5 E5
        //                              → 85.7 % dominant → still pure E85)
      ];
      final result = FuelTypeEfficiencyAggregator.byFuelType(
        fills,
        tankCapacityL: capacity,
      );
      final e85 = _byLabel(result, 'E85');
      expect(e85.attributedIntervalCount, 2);
      expect(e85.legacyAttributedIntervalCount, 1,
          reason: 'only the non-plein-opened interval fell back to v2');
    });

    test('partial fill inside the interval joins the burned-tank tally '
        'alongside the carried content; folding still counts the close', () {
      final fills = [
        _f(id: 'f0', date: _d(1), liters: 35, cost: 30, odo: 0,
            fuelType: FuelType.e85),
        // Mid-interval E10 splash: burned tank = 35 E85 + 14 E10 (28.6 %).
        _f(id: 'f1', date: _d(2), liters: 14, cost: 22, odo: 300,
            fuelType: FuelType.e10, isFullTank: false),
        _f(id: 'f2', date: _d(3), liters: 25, cost: 20, odo: 600,
            fuelType: FuelType.e85), // closes
      ];
      final result = FuelTypeEfficiencyAggregator.byFuelType(
        fills,
        tankCapacityL: capacity,
      );
      final blend = _byLabel(result, 'E85/E10');
      expect(blend.isMix, isTrue);
      expect(blend.legacyAttributedIntervalCount, 0);
      // Folding unchanged: contributing fills incl. the closing plein.
      expect(blend.avgL100km, closeTo((14 + 25) / 600 * 100, 1e-9));
      // #3846: 39 L burned from a 71.4 % E85 / 28.6 % E10 tank, each share
      // at its own observed price (E85 = 50/60, E10 = 22/14) — not the
      // 42 EUR of cash that happened to change hands in the window.
      expect(
          blend.avgCostPerKm,
          closeTo(
              39 * (35 / 49 * (50 / 60) + 14 / 49 * (22 / 14)) / 600, 1e-9));
    });
  });

  group('#3846 money follows the fuel BURNED, not the next tank', () {
    // The reporting user's actual fill-ups. Before this fix the aggregator
    // charged each interval with the cost of the fill that CLOSED it — the
    // NEXT tank — so E5 was priced with E85's cheap money (0,90 EUR/L) and
    // the E85 bucket swallowed the 78,03 EUR E5 fill (showing an impossible
    // 1,27 EUR/L for a fuel never bought above 0,90). The screen therefore
    // recommended E5, which is backwards.
    //
    // The capacity MATTERS: it is what puts the bug on screen. Without it
    // the v2 fallback attributes each interval to its own closing fill, so
    // E5 already prices itself right and these tests would pass on master —
    // false green. With a 45 L tank the v3 walker attributes the 559 km
    // interval to the E5 tank content while the fill that CLOSES it is the
    // 35,7 L E85 one, reproducing the screenshot exactly (E5 shown as
    // 35,7 L / 32,12 EUR / 0,90 EUR/L).
    const capacityL = 45.0;
    final fills = [
      _f(id: 'a', date: DateTime(2026, 7, 24), liters: 27.7, cost: 22.69,
          odo: 120696, fuelType: FuelType.e85),
      _f(id: 'b', date: DateTime(2026, 8, 1), liters: 35.5, cost: 29.37,
          odo: 121645, fuelType: FuelType.e85),
      _f(id: 'c', date: DateTime(2026, 8, 10), liters: 39.2, cost: 78.03,
          odo: 122141, fuelType: FuelType.e5),
      _f(id: 'd', date: DateTime(2026, 8, 21), liters: 35.7, cost: 32.12,
          odo: 122700, fuelType: FuelType.e85),
    ];

    FuelTypeEfficiencyStats? bucketFor(
        List<FuelTypeEfficiencyStats> stats, FuelType fuel) {
      for (final s in stats) {
        if (!s.isMix && s.bucket.dominant == fuel) return s;
      }
      return null;
    }

    test('E5 is priced at what E5 cost, not at the next E85 fill', () {
      final stats = FuelTypeEfficiencyAggregator.byFuelType(fills, tankCapacityL: capacityL);
      final e5 = bucketFor(stats, FuelType.e5);
      expect(e5, isNotNull, reason: 'the E5 interval must be attributed');
      // E5 itself was bought at 78.03 / 39.2 = 1.99 EUR/L. The bucket lands
      // slightly under that on purpose: the tank it burned was 39.2 L of
      // fresh E5 on top of 5.8 L of E85 carried over, so 12.9 % of the
      // litres are honestly priced at E85's rate:
      //   39.2/45 * 1.9906 + 5.8/45 * 0.8512 = 1.844
      // Pinning 1.99 here would mean pricing carried-over E85 as if it were
      // E5 — the same class of lie as the bug, pointing the other way.
      expect(e5!.avgPricePerLitre, isNotNull);
      expect(e5.avgPricePerLitre!, closeTo(1.844, 0.02),
          reason: 'showing 0.90 here means the closing E85 fill is still '
              'paying for the E5 tank');
      // Whatever the blend arithmetic, it can never land in E85 territory.
      expect(e5.avgPricePerLitre!, greaterThan(1.5),
          reason: 'no reading near E85 prices is defensible for a tank that '
              'is 87 % E5 bought at 1.99 EUR/L');
    });

    test('E85 is not charged the 78 EUR E5 fill', () {
      final stats = FuelTypeEfficiencyAggregator.byFuelType(fills, tankCapacityL: capacityL);
      final e85 = bucketFor(stats, FuelType.e85);
      expect(e85, isNotNull);
      // Every E85 fill here is under 0.90 EUR/L, so any figure above that
      // is money borrowed from the E5 fill (the old code showed 1.27).
      expect(e85!.avgPricePerLitre, isNotNull);
      expect(e85.avgPricePerLitre!, lessThan(0.95),
          reason: 'no E85 fill was above 0.90 EUR/L; a higher average means '
              'the E5 fill leaked into this bucket');
    });

    test('THE VERDICT: E5 costs MORE per km than E85, not less', () {
      // This is what the user sees. The old code produced the opposite and
      // told them "E5 est votre carburant le moins cher a l'usage".
      final stats = FuelTypeEfficiencyAggregator.byFuelType(fills, tankCapacityL: capacityL);
      final e5 = bucketFor(stats, FuelType.e5)!;
      final e85 = bucketFor(stats, FuelType.e85)!;
      expect(e5.avgCostPerKm, isNotNull);
      expect(e85.avgCostPerKm, isNotNull);
      expect(e5.avgCostPerKm!, greaterThan(e85.avgCostPerKm!),
          reason: 'E5 at ~1.99 EUR/L cannot be cheaper to drive on than E85 '
              'at ~0.85 EUR/L when the two consume comparably');
    });

    test('consumption is untouched — only the money moved', () {
      // The plein-to-plein litres/distance are correct and must stay so:
      // 122700 - 122141 = 559 km on the 35.7 L refill => 6.4 L/100km.
      final stats = FuelTypeEfficiencyAggregator.byFuelType(fills, tankCapacityL: capacityL);
      final e5 = bucketFor(stats, FuelType.e5)!;
      expect(e5.totalDistanceKm, closeTo(559, 0.5));
      expect(e5.avgL100km, isNotNull);
      expect(e5.avgL100km!, closeTo(6.4, 0.2));
    });
  });
}
