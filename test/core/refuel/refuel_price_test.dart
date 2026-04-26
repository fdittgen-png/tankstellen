import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/refuel/refuel_price.dart';

void main() {
  group('RefuelPrice', () {
    test('freezed equality compares all fields', () {
      final ts = DateTime.utc(2026, 4, 26, 12);
      final a = RefuelPrice(
        value: 174.5,
        unit: RefuelPriceUnit.centsPerLiter,
        lastUpdated: ts,
      );
      final b = RefuelPrice(
        value: 174.5,
        unit: RefuelPriceUnit.centsPerLiter,
        lastUpdated: ts,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different value breaks equality', () {
      const a =
          RefuelPrice(value: 1.0, unit: RefuelPriceUnit.centsPerLiter);
      const b =
          RefuelPrice(value: 2.0, unit: RefuelPriceUnit.centsPerLiter);
      expect(a, isNot(equals(b)));
    });

    test('different unit breaks equality even with same value', () {
      const a =
          RefuelPrice(value: 30.0, unit: RefuelPriceUnit.centsPerLiter);
      const b =
          RefuelPrice(value: 30.0, unit: RefuelPriceUnit.centsPerKwh);
      expect(a, isNot(equals(b)));
    });

    test('lastUpdated is optional and defaults to null', () {
      const p =
          RefuelPrice(value: 50.0, unit: RefuelPriceUnit.perSession);
      expect(p.lastUpdated, isNull);
    });

    test('copyWith updates a single field', () {
      const original =
          RefuelPrice(value: 174.5, unit: RefuelPriceUnit.centsPerLiter);
      final updated = original.copyWith(value: 180.0);

      expect(updated.value, 180.0);
      expect(updated.unit, RefuelPriceUnit.centsPerLiter);
      expect(updated.lastUpdated, isNull);
      expect(original.value, 174.5,
          reason: 'copyWith must not mutate the original');
    });

    test('all RefuelPriceUnit cases are exhausted', () {
      // Same forcing-function pattern as the provider test — adding a
      // new unit without updating consumers will trip this gate.
      expect(RefuelPriceUnit.values, hasLength(3));
      expect(
        RefuelPriceUnit.values,
        containsAll(<RefuelPriceUnit>[
          RefuelPriceUnit.centsPerLiter,
          RefuelPriceUnit.centsPerKwh,
          RefuelPriceUnit.perSession,
        ]),
      );
    });
  });
}
