import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/entities/consumption_stats.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

FillUp _f({
  required String id,
  required DateTime date,
  required double liters,
  required double cost,
  required double odo,
  FuelType fuelType = FuelType.e10,
}) =>
    FillUp(
      id: id,
      date: date,
      liters: liters,
      totalCost: cost,
      odometerKm: odo,
      fuelType: fuelType,
    );

void main() {
  group('ConsumptionStats.fromFillUps', () {
    test('empty list returns empty stats', () {
      final stats = ConsumptionStats.fromFillUps(const []);
      expect(stats.fillUpCount, 0);
      expect(stats.totalLiters, 0);
      expect(stats.totalSpent, 0);
      expect(stats.avgConsumptionL100km, isNull);
      expect(stats.avgCostPerKm, isNull);
    });

    test('single fill-up reports totals but no consumption', () {
      final stats = ConsumptionStats.fromFillUps([
        _f(
          id: '1',
          date: DateTime(2026, 1, 1),
          liters: 50,
          cost: 80,
          odo: 10000,
        ),
      ]);
      expect(stats.fillUpCount, 1);
      expect(stats.totalLiters, 50);
      expect(stats.totalSpent, 80);
      expect(stats.totalDistanceKm, 0);
      expect(stats.avgConsumptionL100km, isNull);
      expect(stats.avgCostPerKm, isNull);
      expect(stats.avgPricePerLiter, closeTo(1.6, 0.0001));
    });

    test('two fill-ups compute L/100km from distance between', () {
      // First tank: odo 10000, ignored for consumption
      // Second tank: 50 L over 1000 km => 5.0 L/100km, 80€ over 1000km = 0.08/km
      final stats = ConsumptionStats.fromFillUps([
        _f(
          id: '1',
          date: DateTime(2026, 1, 1),
          liters: 40,
          cost: 60,
          odo: 10000,
        ),
        _f(
          id: '2',
          date: DateTime(2026, 1, 15),
          liters: 50,
          cost: 80,
          odo: 11000,
        ),
      ]);
      expect(stats.fillUpCount, 2);
      expect(stats.totalLiters, 90);
      expect(stats.totalSpent, 140);
      expect(stats.totalDistanceKm, 1000);
      expect(stats.avgConsumptionL100km, closeTo(5.0, 0.0001));
      expect(stats.avgCostPerKm, closeTo(0.08, 0.0001));
    });

    test('accepts fill-ups in any order — sorts by date', () {
      final stats = ConsumptionStats.fromFillUps([
        _f(
          id: '2',
          date: DateTime(2026, 1, 15),
          liters: 50,
          cost: 80,
          odo: 11000,
        ),
        _f(
          id: '1',
          date: DateTime(2026, 1, 1),
          liters: 40,
          cost: 60,
          odo: 10000,
        ),
      ]);
      expect(stats.totalDistanceKm, 1000);
      expect(stats.avgConsumptionL100km, closeTo(5.0, 0.0001));
      expect(stats.periodStart, DateTime(2026, 1, 1));
      expect(stats.periodEnd, DateTime(2026, 1, 15));
    });

    test('zero distance returns null consumption without dividing by zero',
        () {
      final stats = ConsumptionStats.fromFillUps([
        _f(
          id: '1',
          date: DateTime(2026, 1, 1),
          liters: 10,
          cost: 15,
          odo: 10000,
        ),
        _f(
          id: '2',
          date: DateTime(2026, 1, 2),
          liters: 10,
          cost: 15,
          odo: 10000,
        ),
      ]);
      expect(stats.totalDistanceKm, 0);
      expect(stats.avgConsumptionL100km, isNull);
      expect(stats.avgCostPerKm, isNull);
      expect(stats.totalLiters, 20);
    });

    test('three fill-ups: excludes first tank from L/100km', () {
      // tank 1 (odo 10000) ignored
      // tank 2: 40 L over 500 km
      // tank 3: 40 L over 500 km
      // total: 80 L / 1000 km = 8 L/100km
      final stats = ConsumptionStats.fromFillUps([
        _f(
          id: '1',
          date: DateTime(2026, 1, 1),
          liters: 30,
          cost: 45,
          odo: 10000,
        ),
        _f(
          id: '2',
          date: DateTime(2026, 1, 10),
          liters: 40,
          cost: 60,
          odo: 10500,
        ),
        _f(
          id: '3',
          date: DateTime(2026, 1, 20),
          liters: 40,
          cost: 60,
          odo: 11000,
        ),
      ]);
      expect(stats.totalDistanceKm, 1000);
      expect(stats.avgConsumptionL100km, closeTo(8.0, 0.0001));
    });
  });

  group('FillUpX', () {
    test('pricePerLiter computes correctly', () {
      final f = _f(
        id: '1',
        date: DateTime(2026, 1, 1),
        liters: 40,
        cost: 60,
        odo: 1000,
      );
      expect(f.pricePerLiter, closeTo(1.5, 0.0001));
    });

    test('pricePerLiter returns 0 for zero liters (no divide-by-zero)', () {
      final f = _f(
        id: '1',
        date: DateTime(2026, 1, 1),
        liters: 0,
        cost: 0,
        odo: 1000,
      );
      expect(f.pricePerLiter, 0);
    });
  });

  group('FillUp JSON round-trip', () {
    test('preserves all fields', () {
      final original = FillUp(
        id: 'abc',
        date: DateTime(2026, 3, 15, 10, 30),
        liters: 42.5,
        totalCost: 67.89,
        odometerKm: 15432,
        fuelType: FuelType.diesel,
        stationId: 'station-xyz',
        stationName: 'Shell Berlin',
        notes: 'After vacation trip',
      );
      final json = original.toJson();
      final restored = FillUp.fromJson(json);
      expect(restored, original);
    });

    test('handles optional fields being null', () {
      final original = FillUp(
        id: 'abc',
        date: DateTime(2026, 3, 15),
        liters: 40,
        totalCost: 60,
        odometerKm: 10000,
        fuelType: FuelType.e10,
      );
      final json = original.toJson();
      final restored = FillUp.fromJson(json);
      expect(restored.stationId, isNull);
      expect(restored.stationName, isNull);
      expect(restored.notes, isNull);
    });
  });
}
