// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/receipts_ocr/data/ereceipt/ereceipt_text_parser.dart';
import 'package:tankstellen/features/receipts_ocr/data/receipt_parser/receipt_fiscal_extractors.dart';

/// #4215 (F5) — the FISCAL half of a fuel receipt: VAT amount and rate,
/// the ISO currency, the masked payment reference and the odometer.
///
/// Driven through the REAL stack (`EReceiptTextParser` → `ReceiptParser`
/// → the shipped extractors + the new fiscal pass) against the shipped
/// fixtures plus two new fleet receipts that carry a VAT line, a fuel
/// card and an odometer. No second OCR engine is introduced and no
/// existing field changes: every consumption assertion below is the one
/// the pre-#4215 tests already make.
void main() {
  const parser = EReceiptTextParser();

  String fixture(String name) => File(
        'test/features/receipts_ocr/data/ereceipt/fixtures/$name',
      ).readAsStringSync();

  group('existing fixtures gain the fiscal fields without losing any', () {
    test('Aral Köln: MwSt 19 % / 12,38 EUR read beside the unchanged '
        'litres, price and total', () {
      final r = parser.parse(fixture('aral_koeln_2026-05-28.txt'),
          countryCode: 'DE');

      expect(r.liters, closeTo(44.07, 0.01));
      expect(r.pricePerLiter, closeTo(1.759, 0.001));
      expect(r.totalCost, closeTo(77.52, 0.01));

      expect(r.vatRate, closeTo(19.0, 0.001));
      expect(r.vatAmount, closeTo(12.38, 0.001));
      expect(r.currency, 'EUR');
      expect(r.paymentReference, isNull,
          reason: 'the Steuernummer is a tax id, not a payment reference');
      expect(r.odometerKm, isNull);
    });

    test('Intermarché Nantes: TVA 20 % / 13,05 € off a French receipt', () {
      final r = parser.parse(fixture('intermarche_nantes_2026-05-22.txt'),
          countryCode: 'FR');

      expect(r.vatRate, closeTo(20.0, 0.001));
      expect(r.vatAmount, closeTo(13.05, 0.001));
      expect(r.currency, 'EUR');
      expect(r.paymentReference, isNull,
          reason: '"Recu 22/05/2026" names the day, not the transaction');
    });

    test('Shell Berlin: a rate with NO amount stays a rate — nothing is '
        'derived to fill the hole', () {
      final r = parser.parse(fixture('shell_berlin_2026-05-20.txt'),
          countryCode: 'DE');

      expect(r.vatRate, closeTo(19.0, 0.001));
      expect(r.vatAmount, isNull,
          reason: '"MwSt 19,00 % enthalten" prints no amount, and the '
              'extractor must not compute one');
      expect(r.paymentReference, '0042-115');
    });

    test('Eni Milano: the P.IVA tax-id line is not a VAT amount', () {
      final r = parser.parse(fixture('eni_milano_2026-05-12.txt'),
          countryCode: 'IT');

      expect(r.vatAmount, isNull);
      expect(r.vatRate, isNull);
      expect(r.currency, 'EUR');
    });
  });

  group('new fleet fixtures', () {
    test('TotalEnergies fleet Toulouse: TVA, fuel-card reference and '
        'odometer, with the card number masked', () {
      final r = parser.parse(fixture('totalfleet_toulouse_2026-06-08.txt'),
          countryCode: 'FR');

      expect(r.liters, closeTo(62.40, 0.01));
      expect(r.pricePerLiter, closeTo(1.749, 0.001));
      expect(r.totalCost, closeTo(109.14, 0.01));

      expect(r.vatRate, closeTo(20.0, 0.001));
      expect(r.vatAmount, closeTo(18.19, 0.001),
          reason: 'the Net HT line must not be read as the VAT amount');
      expect(r.currency, 'EUR');
      expect(r.paymentReference, '****4417');
      expect(r.odometerKm, closeTo(128450, 0.5));
    });

    test('BP London: a GBP receipt yields the ISO code, not the symbol', () {
      final r = parser.parse(fixture('bp_london_2026-06-15.txt'),
          countryCode: 'GB');

      expect(r.currency, 'GBP');
      expect(r.vatRate, closeTo(20.0, 0.001));
      expect(r.vatAmount, closeTo(9.85, 0.001));
      expect(r.paymentReference, '88213');
      expect(r.odometerKm, closeTo(54120, 0.5));
    });
  });

  group('the units, directly', () {
    test('a currency is always an ISO code — never the symbol printed', () {
      expect(extractReceiptCurrency('TOTAL 42,10 €'), 'EUR');
      expect(extractReceiptCurrency('TOTAL 42.10 £'), 'GBP');
      expect(extractReceiptCurrency(r'TOTAL 42.10 $'), 'USD');
      for (final symbol in ['€', r'$', '£']) {
        expect(extractReceiptCurrency('TOTAL 42,10 $symbol'),
            isNot(contains(symbol)),
            reason: 'a symbol can never be summed, grouped or exported');
      }
    });

    test('an ambiguous "kr" resolves only from the threaded profile, never '
        'by guessing between DKK, SEK and NOK', () {
      expect(extractReceiptCurrency('TOTAL 412,50 kr'), isNull);
    });

    test('a full card number never leaves the extractor', () {
      const pan = 'CARTE 4539 1488 0343 6467';
      final reference = extractPaymentReference([pan]);
      expect(reference, '****6467');
      expect(reference, isNot(contains('4539')));
      expect(reference, isNot(contains('1488')));
    });

    test('a phone number is not an odometer and an odometer is not a '
        'postcode', () {
      expect(extractOdometerKm('Tel 04.67.77.29.10'), isNull);
      expect(extractOdometerKm('50931 Köln'), isNull);
      expect(extractOdometerKm('Kilometerstand: 98 312 km'),
          closeTo(98312, 0.5));
    });

    test('extractReceiptFiscalFields reports "nothing fiscal" honestly', () {
      final none = extractReceiptFiscalFields(const ['MERCI', 'A BIENTOT']);
      expect(none.hasData, isFalse);
      expect(ReceiptFiscalFields.none.hasData, isFalse);
    });
  });
}
