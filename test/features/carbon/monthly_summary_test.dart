import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/carbon/domain/monthly_summary.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

FillUp _f({
  required String id,
  required DateTime date,
  double liters = 50,
  double cost = 80,
  double odometer = 10000,
  FuelType? fuelType,
}) =>
    FillUp(
      id: id,
      date: date,
      liters: liters,
      totalCost: cost,
      odometerKm: odometer,
      fuelType: fuelType ?? FuelType.e10,
    );

void main() {
  group('MonthlyAggregator.byMonth', () {
    test('returns empty for empty input', () {
      expect(MonthlyAggregator.byMonth(const []), isEmpty);
    });

    test('groups fill-ups by calendar month', () {
      final fillUps = [
        _f(id: '1', date: DateTime(2026, 1, 5), liters: 40, cost: 60),
        _f(id: '2', date: DateTime(2026, 1, 20), liters: 30, cost: 50),
        _f(id: '3', date: DateTime(2026, 2, 3), liters: 50, cost: 80),
      ];
      final summaries = MonthlyAggregator.byMonth(fillUps);
      expect(summaries.length, 2);
      expect(summaries[0].month, DateTime(2026, 1));
      expect(summaries[0].totalLiters, closeTo(70, 0.0001));
      expect(summaries[0].totalCost, closeTo(110, 0.0001));
      expect(summaries[0].fillUpCount, 2);
      expect(summaries[1].month, DateTime(2026, 2));
      expect(summaries[1].fillUpCount, 1);
    });

    test('summaries are ordered oldest first', () {
      final fillUps = [
        _f(id: '1', date: DateTime(2026, 3, 1)),
        _f(id: '2', date: DateTime(2026, 1, 1)),
        _f(id: '3', date: DateTime(2026, 2, 1)),
      ];
      final summaries = MonthlyAggregator.byMonth(fillUps);
      expect(
        summaries.map((s) => s.month.month).toList(),
        [1, 2, 3],
      );
    });

    test('computes CO2 from fuel type', () {
      final fillUps = [
        _f(
          id: '1',
          date: DateTime(2026, 1, 1),
          liters: 100,
          fuelType: FuelType.diesel,
        ),
      ];
      final summaries = MonthlyAggregator.byMonth(fillUps);
      // Diesel factor ~2.65 kg/L
      expect(summaries.single.totalCo2Kg, closeTo(265, 1));
    });
  });

  group('MonthlyAggregator.lastN', () {
    test('returns all when fewer summaries than N', () {
      final fillUps = [
        _f(id: '1', date: DateTime(2026, 1, 1)),
        _f(id: '2', date: DateTime(2026, 2, 1)),
      ];
      final summaries = MonthlyAggregator.byMonth(fillUps);
      expect(MonthlyAggregator.lastN(summaries, 12).length, 2);
    });

    test('returns last N preserving chronological order', () {
      final fillUps = [
        for (int m = 1; m <= 6; m++)
          _f(id: 'm$m', date: DateTime(2026, m, 1)),
      ];
      final summaries = MonthlyAggregator.byMonth(fillUps);
      final last3 = MonthlyAggregator.lastN(summaries, 3);
      expect(last3.length, 3);
      expect(last3.first.month.month, 4);
      expect(last3.last.month.month, 6);
    });

    test('non-positive N returns all', () {
      final fillUps = [_f(id: '1', date: DateTime(2026, 1, 1))];
      final summaries = MonthlyAggregator.byMonth(fillUps);
      expect(MonthlyAggregator.lastN(summaries, 0).length, 1);
    });
  });

  group('MonthlyAggregator totals', () {
    test('sum across summaries', () {
      final fillUps = [
        _f(
          id: '1',
          date: DateTime(2026, 1, 1),
          liters: 50,
          cost: 80,
          fuelType: FuelType.e10,
        ),
        _f(
          id: '2',
          date: DateTime(2026, 2, 1),
          liters: 40,
          cost: 70,
          fuelType: FuelType.e10,
        ),
      ];
      final summaries = MonthlyAggregator.byMonth(fillUps);
      expect(MonthlyAggregator.totalCost(summaries), closeTo(150, 0.0001));
      expect(MonthlyAggregator.totalLiters(summaries), closeTo(90, 0.0001));
      expect(MonthlyAggregator.totalCo2(summaries), greaterThan(0));
    });
  });

  test('avgPricePerLiter is zero when no liters', () {
    final s = MonthlySummary(
      month: DateTime(2026, 1),
      totalCost: 100,
      totalLiters: 0,
      totalCo2Kg: 0,
      fillUpCount: 0,
    );
    expect(s.avgPricePerLiter, 0);
  });

  test('avgPricePerLiter divides cost by liters', () {
    final s = MonthlySummary(
      month: DateTime(2026, 1),
      totalCost: 100,
      totalLiters: 50,
      totalCo2Kg: 0,
      fillUpCount: 1,
    );
    expect(s.avgPricePerLiter, closeTo(2.0, 0.0001));
  });
}
