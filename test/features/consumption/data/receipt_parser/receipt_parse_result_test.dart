import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/receipt_parser/receipt_parse_result.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

void main() {
  group('ReceiptParseResult constructor defaults', () {
    test('all fields default to null except brandLayout which is "generic"',
        () {
      const r = ReceiptParseResult();

      expect(r.liters, isNull);
      expect(r.totalCost, isNull);
      expect(r.pricePerLiter, isNull);
      expect(r.date, isNull);
      expect(r.stationName, isNull);
      expect(r.fuelType, isNull);
      expect(r.brandLayout, 'generic');
    });

    test('named fields round-trip through the constructor', () {
      final date = DateTime(2026, 4, 19);
      final r = ReceiptParseResult(
        liters: 42.35,
        totalCost: 84.70,
        pricePerLiter: 1.999,
        date: date,
        stationName: 'SUPER U VERDUN',
        fuelType: FuelType.e10,
        brandLayout: 'super_u',
      );

      expect(r.liters, 42.35);
      expect(r.totalCost, 84.70);
      expect(r.pricePerLiter, 1.999);
      expect(r.date, date);
      expect(r.stationName, 'SUPER U VERDUN');
      expect(r.fuelType, FuelType.e10);
      expect(r.brandLayout, 'super_u');
    });
  });

  group('ReceiptParseResult.hasData', () {
    test('returns false when both liters and totalCost are null', () {
      const r = ReceiptParseResult();
      expect(r.hasData, isFalse);
    });

    test('returns false when only unrelated fields are populated', () {
      final r = ReceiptParseResult(
        pricePerLiter: 1.999,
        date: DateTime(2026, 4, 19),
        stationName: 'SUPER U',
        fuelType: FuelType.e10,
      );
      expect(r.hasData, isFalse);
    });

    test('returns true when only liters is populated', () {
      const r = ReceiptParseResult(liters: 42.35);
      expect(r.hasData, isTrue);
    });

    test('returns true when only totalCost is populated', () {
      const r = ReceiptParseResult(totalCost: 84.70);
      expect(r.hasData, isTrue);
    });

    test('returns true when both liters and totalCost are populated', () {
      const r = ReceiptParseResult(liters: 42.35, totalCost: 84.70);
      expect(r.hasData, isTrue);
    });
  });
}
