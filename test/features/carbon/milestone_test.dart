import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/carbon/domain/milestone.dart';
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
      fuelType: fuelType ?? FuelType.diesel,
    );

void main() {
  group('MilestoneEngine.evaluate', () {
    test('empty fill-ups: nothing is unlocked', () {
      final progress = MilestoneEngine.evaluate(const []);
      expect(progress.where((p) => p.unlocked), isEmpty);
      expect(progress.length, MilestoneEngine.catalog.length);
    });

    test('single fill-up unlocks "first fill-up"', () {
      final progress = MilestoneEngine.evaluate([
        _f(id: '1', date: DateTime(2026, 1, 1)),
      ]);
      final first = progress.firstWhere(
        (p) => p.milestone.id == 'first_fill_up',
      );
      expect(first.unlocked, isTrue);
      expect(first.fraction, 1.0);
    });

    test('ten fill-ups unlocks "ten_fill_ups"', () {
      final fillUps = [
        for (int i = 0; i < 10; i++)
          _f(id: '$i', date: DateTime(2026, 1, i + 1), odometer: 10000.0 + i),
      ];
      final progress = MilestoneEngine.evaluate(fillUps);
      final ten = progress.firstWhere(
        (p) => p.milestone.id == 'ten_fill_ups',
      );
      expect(ten.unlocked, isTrue);
      final fifty = progress.firstWhere(
        (p) => p.milestone.id == 'fifty_fill_ups',
      );
      expect(fifty.unlocked, isFalse);
      expect(fifty.fraction, closeTo(10 / 50, 0.0001));
    });

    test('hundred liters milestone tracks total liters', () {
      final fillUps = [
        _f(id: '1', date: DateTime(2026, 1, 1), liters: 60),
        _f(id: '2', date: DateTime(2026, 1, 2), liters: 60),
      ];
      final progress = MilestoneEngine.evaluate(fillUps);
      final m = progress.firstWhere(
        (p) => p.milestone.id == 'hundred_liters',
      );
      expect(m.unlocked, isTrue);
      expect(m.current, closeTo(120, 0.0001));
    });

    test('hundred kg co2 milestone tracks diesel emissions', () {
      // 40 L diesel ~ 106 kg CO2
      final fillUps = [
        _f(
          id: '1',
          date: DateTime(2026, 1, 1),
          liters: 40,
          fuelType: FuelType.diesel,
        ),
      ];
      final progress = MilestoneEngine.evaluate(fillUps);
      final m = progress.firstWhere(
        (p) => p.milestone.id == 'hundred_kg_co2',
      );
      expect(m.unlocked, isTrue);
    });

    test('distance milestone computes odometer delta', () {
      final fillUps = [
        _f(id: '1', date: DateTime(2026, 1, 1), odometer: 10000),
        _f(id: '2', date: DateTime(2026, 2, 1), odometer: 11500),
      ];
      final progress = MilestoneEngine.evaluate(fillUps);
      final m = progress.firstWhere(
        (p) => p.milestone.id == 'thousand_km',
      );
      expect(m.unlocked, isTrue);
      expect(m.current, closeTo(1500, 0.0001));
    });
  });

  group('MilestoneEngine.distanceFromOdometer', () {
    test('returns 0 for fewer than two readings', () {
      expect(
        MilestoneEngine.distanceFromOdometer([
          _f(id: '1', date: DateTime(2026, 1, 1), odometer: 10000),
        ]),
        0,
      );
    });

    test('ignores non-positive odometer values', () {
      final fillUps = [
        _f(id: '1', date: DateTime(2026, 1, 1), odometer: 0),
        _f(id: '2', date: DateTime(2026, 2, 1), odometer: 10000),
        _f(id: '3', date: DateTime(2026, 3, 1), odometer: 10500),
      ];
      expect(
        MilestoneEngine.distanceFromOdometer(fillUps),
        closeTo(500, 0.0001),
      );
    });

    test('negative delta clamps to 0', () {
      final fillUps = [
        _f(id: '1', date: DateTime(2026, 1, 1), odometer: 10000),
        _f(id: '2', date: DateTime(2026, 2, 1), odometer: 9000),
      ];
      expect(MilestoneEngine.distanceFromOdometer(fillUps), 0);
    });
  });

  group('MilestoneProgress.fraction', () {
    test('clamps to [0, 1]', () {
      const m = Milestone(
        id: 'x',
        category: MilestoneCategory.fillUpsLogged,
        target: 10,
        unit: 'fillup',
      );
      expect(
        const MilestoneProgress(milestone: m, current: 20, unlocked: true)
            .fraction,
        1.0,
      );
      expect(
        const MilestoneProgress(milestone: m, current: -5, unlocked: false)
            .fraction,
        0.0,
      );
      expect(
        const MilestoneProgress(milestone: m, current: 5, unlocked: false)
            .fraction,
        0.5,
      );
    });

    test('returns 0 when target is zero', () {
      const m = Milestone(
        id: 'x',
        category: MilestoneCategory.fillUpsLogged,
        target: 0,
        unit: 'fillup',
      );
      expect(
        const MilestoneProgress(milestone: m, current: 10, unlocked: true)
            .fraction,
        0,
      );
    });
  });

  group('MilestoneEngine.evEquivalentCo2', () {
    test('returns 0 for non-positive distance', () {
      expect(MilestoneEngine.evEquivalentCo2(0), 0);
      expect(MilestoneEngine.evEquivalentCo2(-100), 0);
    });

    test('applies kgCo2PerKmEv factor', () {
      expect(
        MilestoneEngine.evEquivalentCo2(1000),
        closeTo(1000 * MilestoneEngine.kgCo2PerKmEv, 0.0001),
      );
    });
  });
}
