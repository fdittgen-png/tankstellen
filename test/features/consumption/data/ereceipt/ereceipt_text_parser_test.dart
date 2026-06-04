// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/ereceipt/ereceipt_text_parser.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

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
