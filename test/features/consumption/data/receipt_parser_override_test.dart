import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/receipt_override_registry.dart';
import 'package:tankstellen/features/consumption/data/receipt_parser.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

void main() {
  group('ReceiptParser + override dispatch (#759 phase 1)', () {
    test('without stationId — behaves exactly as before (backward compat)', () {
      // Sanity: same input + no override registry = same result as the
      // existing receipt_parser_test suite asserts.
      const parser = ReceiptParser();
      final result = parser.parse('TOTAL 58.42\nVOLUME 30.00 L');
      expect(result.totalCost, closeTo(58.42, 0.01));
      expect(result.liters, closeTo(30.00, 0.01));
    });

    test('with registry but no matching stationId — brand layout wins', () {
      final registry = ReceiptOverrideRegistry.fromJsonString('{}');
      final parser = ReceiptParser(overrideRegistry: registry);

      final result = parser.parse(
        'TOTAL 58.42\nVOLUME 30.00 L',
        stationId: 'some-unknown-id',
      );

      expect(result.totalCost, closeTo(58.42, 0.01));
      expect(result.liters, closeTo(30.00, 0.01));
    });

    test('override wins over brand layout for populated fields', () {
      // Synthetic receipt that has a non-standard line the brand-layout
      // parser would miss entirely ("DISP_VOL"), plus a normal TOTAL
      // line the generic parser would grab. The override should dispatch
      // volume to the custom line while leaving the total alone.
      const json = r'''
      {
        "independent-pomerols-01": {
          "liters": {"pattern": "DISP_VOL\\s+(\\d+[.,]\\d+)", "group": 1}
        }
      }
      ''';
      final registry = ReceiptOverrideRegistry.fromJsonString(json);
      final parser = ReceiptParser(overrideRegistry: registry);

      const ocr = 'DISP_VOL 25.50\nTOTAL 51.00 EUR\n';
      final withOverride =
          parser.parse(ocr, stationId: 'independent-pomerols-01');
      final withoutOverride = parser.parse(ocr);

      // Without override: the generic parser doesn't know DISP_VOL, so
      // liters stays null (no matching pattern).
      expect(withoutOverride.liters, isNull);
      expect(withoutOverride.totalCost, closeTo(51.00, 0.01));

      // With override: liters is captured via the custom regex, total
      // still matches via the brand-layout/generic pass.
      expect(withOverride.liters, closeTo(25.50, 0.01));
      expect(withOverride.totalCost, closeTo(51.00, 0.01));
    });

    test('override can force a different pricePerLiter than brand layout', () {
      const json = r'''
      {
        "weird-price-layout": {
          "pricePerLiter": {"pattern": "UNIT_EUR\\s+(\\d+[.,]\\d+)", "group": 1}
        }
      }
      ''';
      final registry = ReceiptOverrideRegistry.fromJsonString(json);
      final parser = ReceiptParser(overrideRegistry: registry);

      // Include a conventional "1.899 €/L" that the generic parser
      // would pick. The override must win and land 1.759 instead.
      const ocr = 'UNIT_EUR 1.759\n1.899 €/L\n42.35 L\nTOTAL 82.67\n';
      final result = parser.parse(ocr, stationId: 'weird-price-layout');

      expect(result.pricePerLiter, closeTo(1.759, 0.001));
    });

    test('override can set stationName from a custom header line', () {
      const json = r'''
      {
        "custom-header-01": {
          "stationName": {"pattern": "HDR:\\s*([^\\n]+)", "group": 1}
        }
      }
      ''';
      final registry = ReceiptOverrideRegistry.fromJsonString(json);
      final parser = ReceiptParser(overrideRegistry: registry);

      final result = parser.parse(
        'HDR: Garage Dupont\nTOTAL 30.00',
        stationId: 'custom-header-01',
      );

      expect(result.stationName, 'Garage Dupont');
    });

    test('override fuelType — parsed via the same fuel-type matcher', () {
      const json = r'''
      {
        "fuel-override-01": {
          "fuelType": {"pattern": "PROD:\\s*(\\S+)", "group": 1}
        }
      }
      ''';
      final registry = ReceiptOverrideRegistry.fromJsonString(json);
      final parser = ReceiptParser(overrideRegistry: registry);

      final result = parser.parse(
        'PROD: GAZOLE\nTOTAL 50.00',
        stationId: 'fuel-override-01',
      );

      expect(result.fuelType, FuelType.diesel);
    });

    test('reconciliation still runs after overrides (bad combo → recompute)', () {
      // Craft an override that forces liters=10.0 and pricePerLiter=2.0,
      // and a receipt with TOTAL clearly disagreeing (500.00). The
      // reconciliation guard should detect the 96% mismatch and
      // recompute the total from liters × pricePerLiter = 20.00.
      const json = r'''
      {
        "reconcile-test": {
          "liters": {"pattern": "VOL_FIXED\\s+(\\d+[.,]\\d+)", "group": 1},
          "pricePerLiter": {"pattern": "PPL_FIXED\\s+(\\d+[.,]\\d+)", "group": 1}
        }
      }
      ''';
      final registry = ReceiptOverrideRegistry.fromJsonString(json);
      final parser = ReceiptParser(overrideRegistry: registry);

      const ocr = 'VOL_FIXED 10.00\nPPL_FIXED 2.00\nTOTAL 500.00\n';
      final result = parser.parse(ocr, stationId: 'reconcile-test');

      expect(result.liters, closeTo(10.0, 0.01));
      expect(result.pricePerLiter, closeTo(2.0, 0.001));
      // Reconciliation caught the 25× disagreement and recomputed total.
      expect(result.totalCost, closeTo(20.0, 0.01));
    });

    test('override regex miss — brand layout value survives', () {
      // The override regex points at a label that isn't on the receipt.
      // The brand layout's liters should still come through.
      const json = r'''
      {
        "missing-regex": {
          "liters": {"pattern": "NEVER_MATCHES\\s+(\\d+)", "group": 1}
        }
      }
      ''';
      final registry = ReceiptOverrideRegistry.fromJsonString(json);
      final parser = ReceiptParser(overrideRegistry: registry);

      final result = parser.parse(
        '42.35 L\nTOTAL 80.00',
        stationId: 'missing-regex',
      );

      expect(result.liters, closeTo(42.35, 0.01));
    });

    test('override date — goes through generic date builder', () {
      const json = r'''
      {
        "date-override-01": {
          "date": {"pattern": "STAMP:\\s*(\\d{2}/\\d{2}/\\d{4})", "group": 1}
        }
      }
      ''';
      final registry = ReceiptOverrideRegistry.fromJsonString(json);
      final parser = ReceiptParser(overrideRegistry: registry);

      final result = parser.parse(
        'STAMP: 15/07/2025\nTOTAL 30.00',
        stationId: 'date-override-01',
      );

      expect(result.date, DateTime(2025, 7, 15));
    });
  });
}
