import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/feedback/github_issue_reporter.dart';
import 'package:tankstellen/features/consumption/data/pump_display_parse_result.dart';
import 'package:tankstellen/features/consumption/data/receipt_parser.dart';
import 'package:tankstellen/features/consumption/data/receipt_scan_service.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/bad_scan_report_formatters.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// Unit tests for the pure formatting helpers in
/// [bad_scan_report_formatters.dart]. These functions must stay pure
/// — no `BuildContext`, no provider reads — so a plain `flutter_test`
/// without `pumpWidget` is the right fixture.
void main() {
  // ── Fixtures ────────────────────────────────────────────────────────

  ReceiptScanOutcome buildReceiptOutcome({
    double? liters = 32.5,
    double? totalCost = 55.12,
    double? pricePerLiter = 1.695,
    String? stationName = 'Shell',
    FuelType? fuelType,
    DateTime? date,
    String brandLayout = 'generic',
  }) {
    return ReceiptScanOutcome(
      parse: ReceiptParseResult(
        liters: liters,
        totalCost: totalCost,
        pricePerLiter: pricePerLiter,
        stationName: stationName,
        fuelType: fuelType,
        date: date,
        brandLayout: brandLayout,
      ),
      ocrText: 'TOTAL 55,12\n32,5 L\nSP95',
      imagePath: '/tmp/fake.jpg',
    );
  }

  PumpDisplayScanOutcome buildPumpOutcome({
    double? liters = 40.0,
    double? totalCost = 70.0,
    double? pricePerLiter = 1.75,
    int? pumpNumber = 3,
    double confidence = 0.9,
  }) {
    return PumpDisplayScanOutcome(
      parse: PumpDisplayParseResult(
        liters: liters,
        totalCost: totalCost,
        pricePerLiter: pricePerLiter,
        pumpNumber: pumpNumber,
        confidence: confidence,
      ),
      ocrText: 'Betrag 70.00\nAbgabe 40.00\nPreis/L 1.75',
      imagePath: '/tmp/fake-pump.jpg',
    );
  }

  // ── buildBadScanDiffRows — receipt ─────────────────────────────────

  group('buildBadScanDiffRows (receipt)', () {
    test('returns 7 rows in canonical order with all values populated', () {
      final rows = buildBadScanDiffRows(
        kind: ScanKind.receipt,
        receiptScan: buildReceiptOutcome(
          fuelType: FuelType.e10,
          date: DateTime.utc(2026, 4, 23, 10, 30),
          brandLayout: 'super_u',
        ),
        pumpScan: null,
        enteredLiters: 32.4,
        enteredTotalCost: 55.20,
        l: null,
      );

      expect(rows, hasLength(7));

      // Row 0: brand layout — scanned and "real" both echo p.brandLayout.
      expect(rows[0].label, 'Brand layout');
      expect(rows[0].scanned, 'super_u');
      expect(rows[0].real, 'super_u');

      // Row 1: liters — 2-decimal formatted on both sides.
      expect(rows[1].label, 'Liters');
      expect(rows[1].scanned, '32.50');
      expect(rows[1].real, '32.40');

      // Row 2: total — 2-decimal formatted.
      expect(rows[2].label, 'Total');
      expect(rows[2].scanned, '55.12');
      expect(rows[2].real, '55.20');

      // Row 3: price/L — 3-decimal formatted on scan, dash on user side.
      expect(rows[3].label, 'Price/L');
      expect(rows[3].scanned, '1.695');
      expect(rows[3].real, '—');

      // Row 4: station name passes through verbatim.
      expect(rows[4].label, 'Station');
      expect(rows[4].scanned, 'Shell');
      expect(rows[4].real, '—');

      // Row 5: fuel uses displayName, not apiValue.
      expect(rows[5].label, 'Fuel');
      expect(rows[5].scanned, 'Super E10');
      expect(rows[5].real, '—');

      // Row 6: date is the YYYY-MM-DD prefix of toIso8601String.
      expect(rows[6].label, 'Date');
      expect(rows[6].scanned, '2026-04-23');
      expect(rows[6].real, '—');
    });

    test('renders em-dash placeholders when every numeric field is null', () {
      final rows = buildBadScanDiffRows(
        kind: ScanKind.receipt,
        receiptScan: buildReceiptOutcome(
          liters: null,
          totalCost: null,
          pricePerLiter: null,
          stationName: null,
          fuelType: null,
          date: null,
        ),
        pumpScan: null,
        enteredLiters: null,
        enteredTotalCost: null,
        l: null,
      );

      // Liters / Total / Price/L scanned-side dashes.
      expect(rows[1].scanned, '—');
      expect(rows[2].scanned, '—');
      expect(rows[3].scanned, '—');

      // User-typed sides default to dash when null.
      expect(rows[1].real, '—');
      expect(rows[2].real, '—');

      // Optional metadata fields also collapse to dash.
      expect(rows[4].scanned, '—'); // Station
      expect(rows[5].scanned, '—'); // Fuel
      expect(rows[6].scanned, '—'); // Date
    });

    test('formats liters and total to 2 decimals, price to 3 decimals', () {
      final rows = buildBadScanDiffRows(
        kind: ScanKind.receipt,
        receiptScan: buildReceiptOutcome(
          liters: 12,
          totalCost: 24.5,
          pricePerLiter: 1.7,
        ),
        pumpScan: null,
        enteredLiters: 12.345,
        enteredTotalCost: 24,
        l: null,
      );

      expect(rows[1].scanned, '12.00');
      expect(rows[1].real, '12.35'); // toStringAsFixed rounds half-up
      expect(rows[2].scanned, '24.50');
      expect(rows[2].real, '24.00');
      expect(rows[3].scanned, '1.700');
    });
  });

  // ── buildBadScanDiffRows — pump display ────────────────────────────

  group('buildBadScanDiffRows (pumpDisplay)', () {
    test('returns 3 rows: liters, total, price/L (no pump-number row)', () {
      final rows = buildBadScanDiffRows(
        kind: ScanKind.pumpDisplay,
        receiptScan: null,
        pumpScan: buildPumpOutcome(),
        enteredLiters: 39.9,
        enteredTotalCost: 69.85,
        l: null,
      );

      expect(rows, hasLength(3));

      expect(rows[0].label, 'Liters');
      expect(rows[0].scanned, '40.00');
      expect(rows[0].real, '39.90');

      expect(rows[1].label, 'Total');
      expect(rows[1].scanned, '70.00');
      expect(rows[1].real, '69.85');

      expect(rows[2].label, 'Price/L');
      expect(rows[2].scanned, '1.750');
      expect(rows[2].real, '—');
    });

    test('em-dashes every value when pump-display fields are null', () {
      final rows = buildBadScanDiffRows(
        kind: ScanKind.pumpDisplay,
        receiptScan: null,
        pumpScan: buildPumpOutcome(
          liters: null,
          totalCost: null,
          pricePerLiter: null,
          pumpNumber: null,
        ),
        enteredLiters: null,
        enteredTotalCost: null,
        l: null,
      );

      for (final row in rows) {
        expect(row.scanned, '—');
        expect(row.real, '—');
      }
    });
  });

  // ── buildBadScanShareBody ───────────────────────────────────────────

  group('buildBadScanShareBody', () {
    test('receipt body contains header, every field, and OCR text', () {
      final body = buildBadScanShareBody(
        kind: ScanKind.receipt,
        receiptScan: buildReceiptOutcome(
          fuelType: FuelType.e10,
          date: DateTime.utc(2026, 4, 23, 10, 30),
        ),
        pumpScan: null,
        enteredLiters: 32.4,
        enteredTotalCost: 55.20,
        appVersion: '4.3.0+1234',
        ocrText: 'RAW OCR PAYLOAD',
      );

      expect(body, contains('Tankstellen receipt scan report'));
      expect(body, contains('App version: 4.3.0+1234'));
      expect(body, contains('Brand layout: generic'));
      expect(body, contains('Liters:   32.50   →   32.40'));
      expect(body, contains('Total:    55.12   →   55.20'));
      expect(body, contains('Price/L:  1.695'));
      expect(body, contains('Station:  Shell'));
      // Receipt body uses fuelType.apiValue, NOT displayName.
      expect(body, contains('Fuel:     e10'));
      // Receipt body keeps the full ISO-8601 timestamp (not the date prefix).
      expect(body, contains('Date:     2026-04-23T10:30:00.000Z'));
      expect(body, contains('Raw OCR text'));
      expect(body, contains('RAW OCR PAYLOAD'));
    });

    test('receipt body uses "(please fill)" when user values are null', () {
      final body = buildBadScanShareBody(
        kind: ScanKind.receipt,
        receiptScan: buildReceiptOutcome(),
        pumpScan: null,
        enteredLiters: null,
        enteredTotalCost: null,
        appVersion: '4.3.0+1234',
        ocrText: '',
      );

      expect(body, contains('Liters:   32.50   →   (please fill)'));
      expect(body, contains('Total:    55.12   →   (please fill)'));
    });

    test('pump-display body has its own header and confidence row', () {
      final body = buildBadScanShareBody(
        kind: ScanKind.pumpDisplay,
        receiptScan: null,
        pumpScan: buildPumpOutcome(),
        enteredLiters: 39.9,
        enteredTotalCost: 69.85,
        appVersion: '4.3.0+1234',
        ocrText: 'PUMP OCR',
      );

      expect(body, contains('Tankstellen pump-display scan report'));
      // No "Brand layout" line on pump-display.
      expect(body, isNot(contains('Brand layout:')));
      expect(body, contains('Liters:   40.00   →   39.90'));
      expect(body, contains('Total:    70.00   →   69.85'));
      expect(body, contains('Price/L:  1.750'));
      expect(body, contains('Pump #:   3'));
      expect(body, contains('Confidence: 0.90'));
      expect(body, contains('PUMP OCR'));
    });

    test('pump-display body em-dashes Pump # when number is missing', () {
      final body = buildBadScanShareBody(
        kind: ScanKind.pumpDisplay,
        receiptScan: null,
        pumpScan: buildPumpOutcome(pumpNumber: null),
        enteredLiters: 0,
        enteredTotalCost: 0,
        appVersion: '4.3.0',
        ocrText: '',
      );

      expect(body, contains('Pump #:   —'));
    });
  });

  // ── buildBadScanParsedFields ────────────────────────────────────────

  group('buildBadScanParsedFields', () {
    test('receipt map ships the seven receipt-specific keys', () {
      final fields = buildBadScanParsedFields(
        kind: ScanKind.receipt,
        receiptScan: buildReceiptOutcome(
          fuelType: FuelType.diesel,
          date: DateTime.utc(2026, 1, 5),
          brandLayout: 'carrefour',
        ),
        pumpScan: null,
      );

      expect(fields.keys, containsAll(<String>[
        'brandLayout',
        'liters',
        'totalCost',
        'pricePerLiter',
        'stationName',
        'fuelType',
        'date',
      ]));
      expect(fields['brandLayout'], 'carrefour');
      expect(fields['liters'], '32.50');
      expect(fields['totalCost'], '55.12');
      expect(fields['pricePerLiter'], '1.695');
      expect(fields['stationName'], 'Shell');
      // The parsed-fields map encodes fuel as apiValue, not displayName.
      expect(fields['fuelType'], 'diesel');
      expect(fields['date'], '2026-01-05T00:00:00.000Z');
    });

    test('pump-display map ships the five pump-specific keys', () {
      final fields = buildBadScanParsedFields(
        kind: ScanKind.pumpDisplay,
        receiptScan: null,
        pumpScan: buildPumpOutcome(),
      );

      expect(fields.keys, <String>[
        'liters',
        'totalCost',
        'pricePerLiter',
        'pumpNumber',
        'confidence',
      ]);
      expect(fields['liters'], '40.00');
      expect(fields['totalCost'], '70.00');
      expect(fields['pricePerLiter'], '1.750');
      expect(fields['pumpNumber'], '3');
      expect(fields['confidence'], '0.90');
    });

    test('null numeric fields surface as null in the parsed-fields map', () {
      final fields = buildBadScanParsedFields(
        kind: ScanKind.pumpDisplay,
        receiptScan: null,
        pumpScan: buildPumpOutcome(
          liters: null,
          totalCost: null,
          pricePerLiter: null,
          pumpNumber: null,
          confidence: 0,
        ),
      );

      expect(fields['liters'], isNull);
      expect(fields['totalCost'], isNull);
      expect(fields['pricePerLiter'], isNull);
      expect(fields['pumpNumber'], isNull);
      // Confidence is non-nullable on the parse result, so it always
      // round-trips as a 2-decimal string.
      expect(fields['confidence'], '0.00');
    });
  });

  // ── buildBadScanUserCorrections ─────────────────────────────────────

  group('buildBadScanUserCorrections', () {
    test('formats both numeric values to 2 decimals when set', () {
      final map = buildBadScanUserCorrections(
        enteredLiters: 41.234,
        enteredTotalCost: 71.5,
      );
      expect(map, <String, String?>{
        'liters': '41.23',
        'totalCost': '71.50',
      });
    });

    test('preserves null values on either field', () {
      final mapBoth = buildBadScanUserCorrections(
        enteredLiters: null,
        enteredTotalCost: null,
      );
      expect(mapBoth, <String, String?>{
        'liters': null,
        'totalCost': null,
      });

      final mapPartial = buildBadScanUserCorrections(
        enteredLiters: 32,
        enteredTotalCost: null,
      );
      expect(mapPartial, <String, String?>{
        'liters': '32.00',
        'totalCost': null,
      });
    });
  });

  // ── resolveBadScanTitle ─────────────────────────────────────────────

  group('resolveBadScanTitle', () {
    test('receipt falls back to the kind-specific English string when l is null',
        () {
      expect(
        resolveBadScanTitle(ScanKind.receipt, null),
        'Report a scan error — Receipt',
      );
    });

    test('pumpDisplay falls back to its own English string when l is null',
        () {
      expect(
        resolveBadScanTitle(ScanKind.pumpDisplay, null),
        'Report a scan error — Pump display',
      );
    });
  });
}
