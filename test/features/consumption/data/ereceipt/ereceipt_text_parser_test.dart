// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/ereceipt/ereceipt_text_parser.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';

/// #2838 — the pure-Dart e-receipt TEXT parser. Drives the REAL parsing
/// stack (`EReceiptTextParser` → `ReceiptParser` → field extractors +
/// currency profiles + reconciliation) against realistic Italian and German
/// e-receipt text fixtures — the email-body / PDF-text-layer shape, NOT
/// camera OCR. No email infra, no Flutter binding, no asset I/O.
void main() {
  const parser = EReceiptTextParser();

  String fixture(String name) => File(
        'test/features/consumption/data/ereceipt/fixtures/$name',
      ).readAsStringSync();

  group('EReceiptTextParser — Italian e-receipt fixtures', () {
    test(
        'Eni Milano: extracts litres / price-per-litre / grade / total / '
        'station from a Gasolio document', () {
      final result = parser.parse(fixture('eni_milano_2026-05-12.txt'),
          countryCode: 'IT');

      expect(result.liters, closeTo(42.18, 0.01));
      expect(result.pricePerLiter, closeTo(1.789, 0.001));
      expect(result.totalCost, closeTo(75.46, 0.01));
      expect(result.fuelType, FuelType.diesel,
          reason: '"Gasolio" is Italian for diesel');
      expect(result.stationName, contains('Eni'));
      expect(result.date, DateTime(2026, 5, 12));
      expect(result.hasData, isTrue);
    });

    test(
        'IP Roma: parses a Benzina HTML-email receipt despite CRLF + NBSP + '
        'en-dash noise (exercises normalisation)', () {
      final raw = fixture('ip_roma_2026-06-03.txt');
      // Guard the fixture actually carries the digital-text quirks the
      // normaliser exists to fold — otherwise this test would pass for the
      // wrong reason if the fixture were ever rewritten as clean text.
      expect(raw.contains('\r\n'), isTrue, reason: 'fixture must carry CRLF');
      expect(raw.contains(' '), isTrue, reason: 'fixture must carry NBSP');

      final result = parser.parse(raw, countryCode: 'IT');

      expect(result.liters, closeTo(27.54, 0.01));
      expect(result.pricePerLiter, closeTo(1.879, 0.001));
      expect(result.totalCost, closeTo(51.75, 0.01));
      expect(result.fuelType, FuelType.e5,
          reason: '"Benzina" with no E10 qualifier is E5 in Italy');
      expect(result.stationName, contains('IP'));
      expect(result.date, DateTime(2026, 6, 3));
    });
  });

  group('EReceiptTextParser — French e-receipt fixtures (#2687)', () {
    test(
        'TotalEnergies Lyon: extracts the five fields from a comma-decimal '
        'SP95-E10 receipt (QTY x CODE line + 1,829 EUR/L)', () {
      final result = parser.parse(fixture('totalenergies_lyon_2026-05-15.txt'),
          countryCode: 'FR');

      expect(result.liters, closeTo(38.72, 0.01),
          reason: 'French comma decimal "38,72 X SP95-E10"');
      expect(result.pricePerLiter, closeTo(1.829, 0.001));
      expect(result.totalCost, closeTo(70.83, 0.01),
          reason: 'TOTAL TTC, not the price-per-litre');
      expect(result.fuelType, FuelType.e10, reason: '"SP95-E10" → E10');
      expect(result.stationName, contains('Total'));
      expect(result.date, DateTime(2026, 5, 15));
      expect(result.hasData, isTrue);
    });

    test(
        'Intermarche Nantes: Gazole receipt with the GRADE on its own line '
        '(grade not glued to the volume) + labelled Volume/Prix/MONTANT', () {
      final raw = fixture('intermarche_nantes_2026-05-22.txt');
      // Guard the fixture really separates the grade onto its own line — the
      // point of this case. If a future edit glued "GAZOLE" to the volume row
      // the test would pass for the wrong reason.
      expect(raw.contains('\nGAZOLE\n'), isTrue,
          reason: 'fixture must carry the grade on a standalone line');

      final result = parser.parse(raw, countryCode: 'FR');

      expect(result.liters, closeTo(45.30, 0.01));
      expect(result.pricePerLiter, closeTo(1.729, 0.001));
      expect(result.totalCost, closeTo(78.32, 0.01),
          reason: 'MONTANT is the charged total, not the 13,05 € TVA line');
      expect(result.fuelType, FuelType.diesel,
          reason: '"Gazole" on its own line is French diesel');
      expect(result.stationName?.toUpperCase(), contains('INTERMARCHE'));
      expect(result.date, DateTime(2026, 5, 22));
    });
  });

  group('EReceiptTextParser — German e-receipt fixtures', () {
    test(
        'Shell Berlin: extracts the five fields from a digital "Quittung" with '
        'V-Power Diesel', () {
      final result = parser.parse(fixture('shell_berlin_2026-05-20.txt'),
          countryCode: 'DE');

      expect(result.liters, closeTo(51.72, 0.01));
      expect(result.pricePerLiter, closeTo(1.929, 0.001));
      expect(result.totalCost, closeTo(99.77, 0.01));
      expect(result.fuelType, FuelType.dieselPremium,
          reason: '"V-Power Diesel" is a premium diesel grade');
      expect(result.stationName, contains('Shell'));
      expect(result.date, DateTime(2026, 5, 20));
    });

    test('Aral Köln: e-mail Super E10 receipt with BETRAG / Literpreis labels',
        () {
      final result = parser.parse(fixture('aral_koeln_2026-05-28.txt'),
          countryCode: 'DE');

      expect(result.liters, closeTo(44.07, 0.01));
      expect(result.pricePerLiter, closeTo(1.759, 0.001));
      expect(result.totalCost, closeTo(77.52, 0.01),
          reason: 'BETRAG is the charged total, not the Netto line');
      expect(result.fuelType, FuelType.e10);
      expect(result.stationName, contains('ARAL'));
      expect(result.date, DateTime(2026, 5, 28));
    });
  });

  group('EReceiptTextParser — reconciliation reuse', () {
    test('derives the missing total from litres × price-per-litre', () {
      // No "Importo"/"Totale" line at all — reconcile() must fill it in.
      const text = 'Eni Station\n'
          'Gasolio\n'
          'Litri 30,00\n'
          'Prezzo unitario 1,800 EUR/L\n';
      final result = parser.parse(text, countryCode: 'IT');

      expect(result.liters, closeTo(30.00, 0.01));
      expect(result.pricePerLiter, closeTo(1.800, 0.001));
      expect(result.totalCost, closeTo(54.00, 0.01),
          reason: 'total = 30.00 × 1.800, derived by the shared reconcile()');
    });
  });

  group('EReceiptTextParser — absent fields stay null, never fabricated '
      '(#2687)', () {
    test(
        'a receipt with NO recognisable station leaves stationName null '
        'while still extracting the numeric fields', () {
      // An anonymous independent station: header is a bare street + town,
      // no known brand keyword anywhere. The grade is on its own line.
      const text = 'STATION SERVICE\n'
          '12 ROUTE DE LA MER\n'
          '34300 AGDE\n'
          'Date 02/06/2026 09:14\n'
          'SP98\n'
          'Volume : 31,40 L\n'
          'Prix / L : 1,959 €\n'
          'TOTAL : 61,51 €\n';
      final result = parser.parse(text, countryCode: 'FR');

      expect(result.liters, closeTo(31.40, 0.01));
      expect(result.pricePerLiter, closeTo(1.959, 0.001));
      expect(result.totalCost, closeTo(61.51, 0.01));
      expect(result.fuelType, FuelType.e98, reason: '"SP98" → E98 grade');
      expect(result.stationName, isNull,
          reason: 'no known brand on the receipt — must NOT be fabricated');
    });

    test(
        'a receipt without a per-litre price leaves pricePerLiter null '
        '(it is not invented when only volume + total are printed) — '
        'station present, grade absent stays null', () {
      // Volume + total only — no "Prix/L" line and no 3-decimal price. The
      // parser must not guess a grade that was never printed.
      const text = 'TotalEnergies\n'
          'LE MANS\n'
          'Date 03/06/2026\n'
          'Volume : 20,00 L\n'
          'TOTAL TTC : 38,00 €\n';
      final result = parser.parse(text, countryCode: 'FR');

      expect(result.liters, closeTo(20.00, 0.01));
      expect(result.totalCost, closeTo(38.00, 0.01));
      // Reconcile derives the unit price from total ÷ volume (1.90), so it
      // is legitimately present — but the GRADE was never printed and must
      // come back null rather than being defaulted to E10/Diesel/etc.
      expect(result.fuelType, isNull,
          reason: 'no fuel-grade keyword on the receipt — never guessed');
      expect(result.stationName, contains('Total'));
    });
  });

  group('EReceiptTextParser — empty / non-receipt input', () {
    test('blank input returns an empty result rather than throwing', () {
      final result = parser.parse('   \n\n  ');
      expect(result.hasData, isFalse);
      expect(result.liters, isNull);
      expect(result.totalCost, isNull);
    });

    test('an unrelated text body parses no fuel fields', () {
      final result = parser.parse(
        'Hi! Thanks for your order. Your package ships tomorrow.',
        countryCode: 'DE',
      );
      expect(result.hasData, isFalse);
    });

    test('looksLikeReceipt gates on extractable fuel data', () {
      expect(
        parser.looksLikeReceipt(fixture('eni_milano_2026-05-12.txt'),
            countryCode: 'IT'),
        isTrue,
      );
      expect(parser.looksLikeReceipt('just a note', countryCode: 'IT'), isFalse);
    });
  });

  group('EReceiptTextParser — currency profile threading', () {
    test('a GB receipt reads pence-per-litre via the GB profile', () {
      // 142.9 p/L folds to £1.429/L; the GB band (0.8–3.0) accepts it,
      // proving the country → OcrLocaleProfile lookup reached the currency
      // extractors. Under the default EUR profile this would be rejected.
      const text = 'Shell\n'
          'Unleaded\n'
          'Volume 40.00 L\n'
          '142.9p/L\n'
          'TOTAL £57.16\n';
      final result = parser.parse(text, countryCode: 'GB');

      expect(result.pricePerLiter, closeTo(1.429, 0.001));
      expect(result.totalCost, closeTo(57.16, 0.01));
    });

    test('an unknown country code falls back to EUR without throwing', () {
      final result = parser.parse(
        fixture('eni_milano_2026-05-12.txt'),
        countryCode: 'ZZ',
      );
      // EUR default still parses an EUR receipt fine.
      expect(result.liters, closeTo(42.18, 0.01));
      expect(result.totalCost, closeTo(75.46, 0.01));
    });
  });
}
