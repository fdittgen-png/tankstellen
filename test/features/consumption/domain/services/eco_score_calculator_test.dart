import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/entities/eco_score.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/domain/services/eco_score_calculator.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

FillUp _f({
  required String id,
  required int daysAgo,
  required double odo,
  required double liters,
  FuelType fuel = FuelType.diesel,
}) {
  return FillUp(
    id: id,
    date: DateTime(2026, 4, 1).subtract(Duration(days: daysAgo)),
    liters: liters,
    totalCost: liters * 1.8,
    odometerKm: odo,
    fuelType: fuel,
  );
}

void main() {
  group('EcoScoreCalculator.compute — null cases', () {
    test('current not in history → null', () {
      final current = _f(id: 'x', daysAgo: 0, odo: 10000, liters: 50);
      expect(
        EcoScoreCalculator.compute(current: current, history: const []),
        isNull,
      );
    });

    test('first-ever fill-up → null (no baseline to compare against)', () {
      final first = _f(id: 'a', daysAgo: 0, odo: 10000, liters: 50);
      expect(
        EcoScoreCalculator.compute(current: first, history: [first]),
        isNull,
      );
    });

    test('current has no same-fuel-type predecessor → null', () {
      final petrol = _f(
          id: 'p', daysAgo: 10, odo: 10000, liters: 40, fuel: FuelType.e10);
      final diesel = _f(id: 'd', daysAgo: 0, odo: 10800, liters: 50);
      expect(
        EcoScoreCalculator.compute(current: diesel, history: [petrol, diesel]),
        isNull,
        reason: 'diesel with only e10 history has no baseline',
      );
    });

    test('non-positive odometer delta on current → null', () {
      final prev = _f(id: 'a', daysAgo: 10, odo: 20000, liters: 40);
      final rolledBack = _f(id: 'b', daysAgo: 0, odo: 19000, liters: 40);
      expect(
        EcoScoreCalculator.compute(
            current: rolledBack, history: [prev, rolledBack]),
        isNull,
      );
    });
  });

  group('EcoScoreCalculator.compute — happy path', () {
    test('single previous fill-up produces a comparison even with window-of-1',
        () {
      // Two fill-ups, both diesel, exactly 800 km apart, both 40 L →
      // 5.0 L/100km each. Current matches baseline exactly → delta = 0.
      final a = _f(id: 'a', daysAgo: 20, odo: 10000, liters: 40);
      final b = _f(id: 'b', daysAgo: 10, odo: 10800, liters: 40);
      final c = _f(id: 'c', daysAgo: 0, odo: 11600, liters: 40);

      final score = EcoScoreCalculator.compute(
        current: c,
        history: [a, b, c],
      );
      expect(score, isNotNull);
      expect(score!.litersPer100Km, closeTo(5.0, 0.0001));
      expect(score.rollingAverage, closeTo(5.0, 0.0001));
      expect(score.deltaPercent.abs(), lessThan(0.001));
      expect(score.direction, EcoScoreDirection.stable);
    });

    test('improving → 10% lower than baseline', () {
      // Baseline = 6.0 L/100km (from two 6-L/100km fills), current =
      // 5.4 L/100km (a 10% reduction, 30% better than threshold).
      final a = _f(id: 'a', daysAgo: 30, odo: 10000, liters: 48);
      final b = _f(id: 'b', daysAgo: 20, odo: 10800, liters: 48);
      final c = _f(id: 'c', daysAgo: 10, odo: 11600, liters: 48);
      final current = _f(id: 'd', daysAgo: 0, odo: 12400, liters: 43.2);

      final score = EcoScoreCalculator.compute(
        current: current,
        history: [a, b, c, current],
      );
      expect(score, isNotNull);
      expect(score!.direction, EcoScoreDirection.improving);
      expect(score.deltaPercent, lessThan(-EcoScore.threshold));
    });

    test('worsening → 10% higher than baseline', () {
      final a = _f(id: 'a', daysAgo: 30, odo: 10000, liters: 48);
      final b = _f(id: 'b', daysAgo: 20, odo: 10800, liters: 48);
      final c = _f(id: 'c', daysAgo: 10, odo: 11600, liters: 48);
      final current = _f(id: 'd', daysAgo: 0, odo: 12400, liters: 52.8);

      final score = EcoScoreCalculator.compute(
        current: current,
        history: [a, b, c, current],
      );
      expect(score, isNotNull);
      expect(score!.direction, EcoScoreDirection.worsening);
      expect(score.deltaPercent, greaterThan(EcoScore.threshold));
    });

    test('small 2% swing stays in the stable band', () {
      // Threshold is 3% — so a 2% change must not flip direction.
      // Baseline 6.0, current 6.12 (2% worse).
      final a = _f(id: 'a', daysAgo: 30, odo: 10000, liters: 48);
      final b = _f(id: 'b', daysAgo: 20, odo: 10800, liters: 48);
      final c = _f(id: 'c', daysAgo: 10, odo: 11600, liters: 48);
      final current =
          _f(id: 'd', daysAgo: 0, odo: 12400, liters: 48 * 1.02);

      final score = EcoScoreCalculator.compute(
        current: current,
        history: [a, b, c, current],
      );
      expect(score, isNotNull);
      expect(score!.direction, EcoScoreDirection.stable);
      expect(score.deltaPercent.abs(), lessThan(EcoScore.threshold));
    });

    test('just past the positive threshold counts as worsening', () {
      // Baseline 6.0. 3.01% higher to clear floating-point noise at
      // exactly 3%.
      final a = _f(id: 'a', daysAgo: 30, odo: 10000, liters: 48);
      final b = _f(id: 'b', daysAgo: 20, odo: 10800, liters: 48);
      final c = _f(id: 'c', daysAgo: 10, odo: 11600, liters: 48);
      final current =
          _f(id: 'd', daysAgo: 0, odo: 12400, liters: 48 * 1.031);

      final score = EcoScoreCalculator.compute(
        current: current,
        history: [a, b, c, current],
      );
      expect(score!.direction, EcoScoreDirection.worsening);
    });

    test('just past the negative threshold counts as improving', () {
      final a = _f(id: 'a', daysAgo: 30, odo: 10000, liters: 48);
      final b = _f(id: 'b', daysAgo: 20, odo: 10800, liters: 48);
      final c = _f(id: 'c', daysAgo: 10, odo: 11600, liters: 48);
      final current =
          _f(id: 'd', daysAgo: 0, odo: 12400, liters: 48 * 0.969);

      final score = EcoScoreCalculator.compute(
        current: current,
        history: [a, b, c, current],
      );
      expect(score!.direction, EcoScoreDirection.improving);
    });
  });

  group('EcoScoreCalculator — same-fuel-type filtering', () {
    test('interleaved e10 entries do not pollute a diesel baseline', () {
      // Diesel fills alternate with e10 fills. The diesel baseline must
      // use ONLY the preceding diesel entries, not average the two.
      final d1 = _f(id: 'd1', daysAgo: 50, odo: 10000, liters: 48);
      final p1 = _f(
          id: 'p1',
          daysAgo: 45,
          odo: 10400,
          liters: 30,
          fuel: FuelType.e10);
      final d2 = _f(id: 'd2', daysAgo: 30, odo: 10800, liters: 48);
      final p2 = _f(
          id: 'p2',
          daysAgo: 25,
          odo: 11000,
          liters: 25,
          fuel: FuelType.e10);
      final d3 = _f(id: 'd3', daysAgo: 10, odo: 11600, liters: 48);
      final current = _f(id: 'dc', daysAgo: 0, odo: 12400, liters: 48);

      final score = EcoScoreCalculator.compute(
        current: current,
        history: [d1, p1, d2, p2, d3, current],
      );
      expect(score, isNotNull);
      // Diesel distance current = 12400 - 11600 = 800; liters 48 →
      // 6.0 L/100km. Baseline uses d1→d2 and d2→d3 deltas (800 km
      // each, 48 L each → 6.0). Score should be stable.
      expect(score!.direction, EcoScoreDirection.stable);
      expect(score.rollingAverage, closeTo(6.0, 0.0001));
    });
  });

  group('EcoScoreCalculator — data-entry defences', () {
    test('baseline pair with non-positive odometer delta is dropped', () {
      // d1→d2 has a RESET odometer (800 → 400), d2→d3 is clean.
      // Only the clean pair should form the baseline.
      final d1 = _f(id: 'd1', daysAgo: 40, odo: 10800, liters: 48);
      final d2 = _f(id: 'd2', daysAgo: 30, odo: 10400, liters: 48);
      final d3 = _f(id: 'd3', daysAgo: 10, odo: 11200, liters: 48);
      final current = _f(id: 'dc', daysAgo: 0, odo: 12000, liters: 48);

      final score = EcoScoreCalculator.compute(
        current: current,
        history: [d1, d2, d3, current],
      );
      expect(score, isNotNull);
      // Only d2→d3 (800 km, 48 L → 6.0) should feed the baseline.
      expect(score!.rollingAverage, closeTo(6.0, 0.0001));
    });

    test('history order (unsorted input) does not affect the result', () {
      final a = _f(id: 'a', daysAgo: 30, odo: 10000, liters: 48);
      final b = _f(id: 'b', daysAgo: 20, odo: 10800, liters: 48);
      final c = _f(id: 'c', daysAgo: 10, odo: 11600, liters: 48);
      final current = _f(id: 'd', daysAgo: 0, odo: 12400, liters: 48);

      final sortedScore = EcoScoreCalculator.compute(
          current: current, history: [a, b, c, current]);
      final shuffledScore = EcoScoreCalculator.compute(
          current: current, history: [current, c, a, b]);

      expect(sortedScore, isNotNull);
      expect(shuffledScore, isNotNull);
      expect(shuffledScore!.litersPer100Km,
          closeTo(sortedScore!.litersPer100Km, 0.0001));
      expect(shuffledScore.rollingAverage,
          closeTo(sortedScore.rollingAverage, 0.0001));
    });
  });

  group('EcoScore.threshold', () {
    test('is 3% — chosen to absorb short-trip / weather noise', () {
      // Pinned as a project decision. Raising it would let bad
      // driving slip by; lowering it would punish a single hot week.
      expect(EcoScore.threshold, 3.0);
    });
  });

  group('EcoScoreCalculator.rollingWindow', () {
    test('is 3 — matches the issue spec and the README tagline', () {
      expect(EcoScoreCalculator.rollingWindow, 3);
    });
  });
}
