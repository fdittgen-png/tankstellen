import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/pump_display_parse_result.dart';

/// Focused unit tests for [PumpDisplayParseResult] (#561 coverage).
///
/// The production parser owns end-to-end coverage; these tests
/// exercise the DTO's contract directly so construction defaults,
/// `hasUsableData`, and `isConsistent` are pinned regardless of how
/// the parser behaves.
void main() {
  group('PumpDisplayParseResult — construction defaults', () {
    test('empty constructor fills every field with null and 0 confidence',
        () {
      const r = PumpDisplayParseResult();
      expect(r.liters, isNull);
      expect(r.totalCost, isNull);
      expect(r.pricePerLiter, isNull);
      expect(r.pumpNumber, isNull);
      expect(r.confidence, 0);
    });

    test('named arguments land in the matching fields', () {
      const r = PumpDisplayParseResult(
        liters: 31.65,
        totalCost: 58.43,
        pricePerLiter: 1.846,
        pumpNumber: 3,
        confidence: 0.95,
      );
      expect(r.liters, 31.65);
      expect(r.totalCost, 58.43);
      expect(r.pricePerLiter, 1.846);
      expect(r.pumpNumber, 3);
      expect(r.confidence, 0.95);
    });
  });

  group('PumpDisplayParseResult — hasUsableData', () {
    test('false when no fields are present', () {
      const r = PumpDisplayParseResult();
      expect(r.hasUsableData, isFalse);
    });

    test('false when only one of the three primary fields is present', () {
      const onlyTotal = PumpDisplayParseResult(totalCost: 58.43);
      const onlyLiters = PumpDisplayParseResult(liters: 31.65);
      const onlyPrice = PumpDisplayParseResult(pricePerLiter: 1.846);
      expect(onlyTotal.hasUsableData, isFalse);
      expect(onlyLiters.hasUsableData, isFalse);
      expect(onlyPrice.hasUsableData, isFalse);
    });

    test('true when any two of the three primary fields are present', () {
      const totalLiters = PumpDisplayParseResult(
        totalCost: 58.43,
        liters: 31.65,
      );
      const totalPrice = PumpDisplayParseResult(
        totalCost: 58.43,
        pricePerLiter: 1.846,
      );
      const litersPrice = PumpDisplayParseResult(
        liters: 31.65,
        pricePerLiter: 1.846,
      );
      expect(totalLiters.hasUsableData, isTrue);
      expect(totalPrice.hasUsableData, isTrue);
      expect(litersPrice.hasUsableData, isTrue);
    });

    test('true when all three primary fields are present', () {
      const r = PumpDisplayParseResult(
        totalCost: 58.43,
        liters: 31.65,
        pricePerLiter: 1.846,
      );
      expect(r.hasUsableData, isTrue);
    });

    test('pump number alone does NOT qualify as usable data', () {
      // pumpNumber is a convenience — it should never unlock auto-fill.
      const r = PumpDisplayParseResult(pumpNumber: 3);
      expect(r.hasUsableData, isFalse);
    });
  });

  group('PumpDisplayParseResult — isConsistent', () {
    test('false when any primary field is null', () {
      const missingPrice = PumpDisplayParseResult(
        totalCost: 58.43,
        liters: 31.65,
      );
      const missingLiters = PumpDisplayParseResult(
        totalCost: 58.43,
        pricePerLiter: 1.846,
      );
      const missingTotal = PumpDisplayParseResult(
        liters: 31.65,
        pricePerLiter: 1.846,
      );
      expect(missingPrice.isConsistent, isFalse);
      expect(missingLiters.isConsistent, isFalse);
      expect(missingTotal.isConsistent, isFalse);
    });

    test('true when liters * price equals total exactly', () {
      const r = PumpDisplayParseResult(
        liters: 10,
        pricePerLiter: 1.5,
        totalCost: 15,
      );
      expect(r.isConsistent, isTrue);
    });

    test('true when delta is within 2 cents (pump rounding)', () {
      // 31.65 * 1.846 = 58.4259 — pump rounds to 58.43 or 58.42;
      // either must read as consistent.
      const a = PumpDisplayParseResult(
        liters: 31.65,
        pricePerLiter: 1.846,
        totalCost: 58.43,
      );
      const b = PumpDisplayParseResult(
        liters: 31.65,
        pricePerLiter: 1.846,
        totalCost: 58.42,
      );
      expect(a.isConsistent, isTrue);
      expect(b.isConsistent, isTrue);
    });

    test('true exactly at the 2-cent tolerance boundary', () {
      // Predicted 10.00, actual 10.02 — delta == 0.02 must still be
      // consistent (the comparison is `<= 0.02`).
      const r = PumpDisplayParseResult(
        liters: 5,
        pricePerLiter: 2.0,
        totalCost: 10.02,
      );
      expect(r.isConsistent, isTrue);
    });

    test('false when delta exceeds the 2-cent tolerance', () {
      // 10 * 1.5 = 15 — total 15.03 is 3c off -> not consistent.
      const r = PumpDisplayParseResult(
        liters: 10,
        pricePerLiter: 1.5,
        totalCost: 15.03,
      );
      expect(r.isConsistent, isFalse);
    });

    test('false when the triple disagrees wildly (OCR swap)', () {
      // 10 * 1.5 = 15 but displayed total is 30 — strong signal that
      // OCR misread one of the fields.
      const r = PumpDisplayParseResult(
        liters: 10,
        pricePerLiter: 1.5,
        totalCost: 30,
      );
      expect(r.isConsistent, isFalse);
    });

    test('handles tiny positive floating-point error without drama', () {
      // 31.65 * 1.846 = 58.4259 — assigning the exact product as total
      // must still read as consistent.
      const r = PumpDisplayParseResult(
        liters: 31.65,
        pricePerLiter: 1.846,
        totalCost: 58.4259,
      );
      expect(r.isConsistent, isTrue);
    });
  });
}
