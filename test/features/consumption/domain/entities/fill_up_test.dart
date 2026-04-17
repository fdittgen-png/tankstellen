import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

FillUp _makeFillUp({
  double liters = 50,
  double totalCost = 80,
  FuelType fuelType = FuelType.diesel,
}) {
  return FillUp(
    id: 'test',
    date: DateTime(2026, 3, 15),
    liters: liters,
    totalCost: totalCost,
    odometerKm: 12345,
    fuelType: fuelType,
  );
}

void main() {
  group('FillUpX.pricePerLiter', () {
    test('computes total / liters', () {
      expect(_makeFillUp(liters: 50, totalCost: 80).pricePerLiter,
          closeTo(1.600, 0.001));
    });

    test('handles 3-decimal precision without rounding artefacts', () {
      // 31.65 L at €1.846/L = 58.4259, displayed total 58.43.
      // pricePerLiter = 58.43 / 31.65 = 1.8461... — not exactly
      // 1.846 but within rounding.
      final f = _makeFillUp(liters: 31.65, totalCost: 58.43);
      expect(f.pricePerLiter, closeTo(1.846, 0.001));
    });

    test('returns 0 for a 0-litre fill-up (guards against divide-by-zero)',
        () {
      expect(_makeFillUp(liters: 0, totalCost: 0).pricePerLiter, 0);
    });

    test('returns 0 even when totalCost is non-zero but liters is 0', () {
      // Shouldn't happen in practice but guards the getter anyway.
      expect(
        _makeFillUp(liters: 0, totalCost: 50).pricePerLiter,
        0,
      );
    });
  });

  group('FillUpX.co2Kg', () {
    test('returns non-zero for diesel', () {
      final f = _makeFillUp(liters: 50, fuelType: FuelType.diesel);
      expect(f.co2Kg, greaterThan(0));
    });

    test('returns non-zero for E5 petrol', () {
      final f = _makeFillUp(liters: 40, fuelType: FuelType.e5);
      expect(f.co2Kg, greaterThan(0));
    });

    test('is proportional to litres (double the fuel → double the CO2)',
        () {
      final small = _makeFillUp(liters: 25, fuelType: FuelType.diesel);
      final big = _makeFillUp(liters: 50, fuelType: FuelType.diesel);
      expect(big.co2Kg, closeTo(small.co2Kg * 2, 0.01));
    });

    test('returns 0 for fuel types without a per-litre emission factor',
        () {
      // `FuelType.all` is a filter token, not a real fuel — Co2Calculator
      // returns 0 for it so CO2 totals don't double-count.
      final f = _makeFillUp(liters: 50, fuelType: FuelType.all);
      expect(f.co2Kg, 0);
    });
  });
}
