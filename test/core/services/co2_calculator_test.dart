import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/co2_calculator.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

FillUp _f({
  double liters = 50,
  FuelType fuelType = FuelType.e10,
}) =>
    FillUp(
      id: 'x',
      date: DateTime(2026, 1, 1),
      liters: liters,
      totalCost: 80,
      odometerKm: 10000,
      fuelType: fuelType,
    );

void main() {
  group('Co2Calculator.emissionFactorFor', () {
    test('returns E5 factor for E5', () {
      expect(Co2Calculator.emissionFactorFor(FuelType.e5),
          Co2Calculator.kgCo2PerLiterE5);
    });

    test('returns E10 factor for E10', () {
      expect(Co2Calculator.emissionFactorFor(FuelType.e10),
          Co2Calculator.kgCo2PerLiterE10);
    });

    test('returns E98 factor for E98', () {
      expect(Co2Calculator.emissionFactorFor(FuelType.e98),
          Co2Calculator.kgCo2PerLiterE98);
    });

    test('returns diesel factor for diesel', () {
      expect(Co2Calculator.emissionFactorFor(FuelType.diesel),
          Co2Calculator.kgCo2PerLiterDiesel);
    });

    test('returns diesel factor for diesel premium', () {
      expect(Co2Calculator.emissionFactorFor(FuelType.dieselPremium),
          Co2Calculator.kgCo2PerLiterDieselPremium);
    });

    test('returns E85 factor for E85 (lower due to ethanol)', () {
      expect(Co2Calculator.emissionFactorFor(FuelType.e85),
          Co2Calculator.kgCo2PerLiterE85);
      // Sanity: E85 should be materially lower than diesel/E5.
      expect(
          Co2Calculator.kgCo2PerLiterE85, lessThan(Co2Calculator.kgCo2PerLiterE5));
      expect(Co2Calculator.kgCo2PerLiterE85,
          lessThan(Co2Calculator.kgCo2PerLiterDiesel));
    });

    test('returns LPG factor for LPG', () {
      expect(Co2Calculator.emissionFactorFor(FuelType.lpg),
          Co2Calculator.kgCo2PerLiterLpg);
    });

    test('returns null for electric', () {
      expect(Co2Calculator.emissionFactorFor(FuelType.electric), isNull);
    });

    test('returns null for hydrogen', () {
      expect(Co2Calculator.emissionFactorFor(FuelType.hydrogen), isNull);
    });

    test('returns null for all/meta', () {
      expect(Co2Calculator.emissionFactorFor(FuelType.all), isNull);
    });
  });

  group('Co2Calculator.co2ForLiters', () {
    test('computes diesel CO2 for 50 L', () {
      expect(
        Co2Calculator.co2ForLiters(50, FuelType.diesel),
        closeTo(50 * Co2Calculator.kgCo2PerLiterDiesel, 0.0001),
      );
    });

    test('computes E10 CO2 for 40 L', () {
      expect(
        Co2Calculator.co2ForLiters(40, FuelType.e10),
        closeTo(40 * Co2Calculator.kgCo2PerLiterE10, 0.0001),
      );
    });

    test('zero liters returns zero', () {
      expect(Co2Calculator.co2ForLiters(0, FuelType.diesel), 0);
    });

    test('negative liters clamped to zero', () {
      expect(Co2Calculator.co2ForLiters(-10, FuelType.diesel), 0);
    });

    test('unsupported fuel type (electric) returns zero', () {
      expect(Co2Calculator.co2ForLiters(50, FuelType.electric), 0);
    });

    test('unsupported fuel type (hydrogen) returns zero', () {
      expect(Co2Calculator.co2ForLiters(50, FuelType.hydrogen), 0);
    });

    test('unsupported fuel type (all) returns zero', () {
      expect(Co2Calculator.co2ForLiters(50, FuelType.all), 0);
    });
  });

  group('Co2Calculator.co2ForFillUp', () {
    test('computes CO2 for a diesel fill-up', () {
      final fillUp = _f(liters: 50, fuelType: FuelType.diesel);
      expect(
        Co2Calculator.co2ForFillUp(fillUp),
        closeTo(50 * Co2Calculator.kgCo2PerLiterDiesel, 0.0001),
      );
    });

    test('FillUp.co2Kg extension matches calculator', () {
      final fillUp = _f(liters: 42, fuelType: FuelType.e5);
      expect(fillUp.co2Kg, closeTo(Co2Calculator.co2ForFillUp(fillUp), 0.0001));
    });

    test('electric fill-up has zero CO2 (no per-liter factor)', () {
      final fillUp = _f(liters: 30, fuelType: FuelType.electric);
      expect(Co2Calculator.co2ForFillUp(fillUp), 0);
      expect(fillUp.co2Kg, 0);
    });
  });

  group('Co2Calculator.cumulativeCo2', () {
    test('empty list returns 0', () {
      expect(Co2Calculator.cumulativeCo2(const []), 0);
    });

    test('sums CO2 across multiple fill-ups of same fuel type', () {
      final fills = [
        _f(liters: 50, fuelType: FuelType.diesel),
        _f(liters: 40, fuelType: FuelType.diesel),
        _f(liters: 30, fuelType: FuelType.diesel),
      ];
      expect(
        Co2Calculator.cumulativeCo2(fills),
        closeTo(120 * Co2Calculator.kgCo2PerLiterDiesel, 0.0001),
      );
    });

    test('sums CO2 across mixed fuel types', () {
      final fills = [
        _f(liters: 50, fuelType: FuelType.diesel),
        _f(liters: 40, fuelType: FuelType.e10),
        _f(liters: 30, fuelType: FuelType.e85),
      ];
      final expected = 50 * Co2Calculator.kgCo2PerLiterDiesel +
          40 * Co2Calculator.kgCo2PerLiterE10 +
          30 * Co2Calculator.kgCo2PerLiterE85;
      expect(Co2Calculator.cumulativeCo2(fills), closeTo(expected, 0.0001));
    });

    test('ignores electric entries in cumulative sum', () {
      final fills = [
        _f(liters: 50, fuelType: FuelType.diesel),
        _f(liters: 30, fuelType: FuelType.electric),
      ];
      expect(
        Co2Calculator.cumulativeCo2(fills),
        closeTo(50 * Co2Calculator.kgCo2PerLiterDiesel, 0.0001),
      );
    });
  });

  group('Co2Calculator.co2PerKm', () {
    test('computes kg CO2 per km for a known tank', () {
      // 50 L diesel @ 2.65 = 132.5 kg CO2 over 1000 km = 0.1325 kg/km
      final fillUp = _f(liters: 50, fuelType: FuelType.diesel);
      expect(
        Co2Calculator.co2PerKm(fillUp, 1000),
        closeTo(50 * Co2Calculator.kgCo2PerLiterDiesel / 1000, 0.0001),
      );
    });

    test('returns null for zero distance (no divide-by-zero)', () {
      final fillUp = _f(liters: 50, fuelType: FuelType.diesel);
      expect(Co2Calculator.co2PerKm(fillUp, 0), isNull);
    });

    test('returns null for negative distance', () {
      final fillUp = _f(liters: 50, fuelType: FuelType.diesel);
      expect(Co2Calculator.co2PerKm(fillUp, -100), isNull);
    });

    test('returns null for electric fill-up (no CO2 factor)', () {
      final fillUp = _f(liters: 30, fuelType: FuelType.electric);
      expect(Co2Calculator.co2PerKm(fillUp, 500), isNull);
    });
  });
}
