// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/money.dart';
import 'package:tankstellen/core/domain/money_tally.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';
import 'package:tankstellen/core/utils/unit_formatter.dart';

/// #4437 A — a record renders in the money it was paid in, whatever the
/// profile's currency is.
void main() {
  tearDown(() => PriceFormatter.setCountry('FR'));

  group('PriceFormatter.symbolForCurrency', () {
    test('an unambiguous foreign symbol is used, others by ISO code', () {
      PriceFormatter.setCountry('DE');
      expect(PriceFormatter.symbolForCurrency('EUR'), '€');
      expect(PriceFormatter.symbolForCurrency('gbp'), '£');
      expect(PriceFormatter.symbolForCurrency('CHF'), 'CHF');
      // `kr` names three currencies, so a foreign DKK reads as DKK.
      expect(PriceFormatter.symbolForCurrency('DKK'), 'DKK');
    });

    test('the ACTIVE currency keeps the profile symbol (regression)', () {
      PriceFormatter.setCountry('DK');
      expect(PriceFormatter.symbolForCurrency('DKK'), 'kr');
      expect(PriceFormatter.symbolForCurrency('EUR'), '€');
    });
  });

  group('PriceFormatter.formatTotalIn', () {
    test('the Gandria receipt reads CHF, never the profile symbol', () {
      PriceFormatter.setCountry('DE');
      final s = PriceFormatter.formatTotalIn(51.73, 'CHF');
      expect(s, '51,73 CHF');
      expect(s, isNot(contains('€')));
    });

    test('a home record is byte-identical to formatTotal', () {
      PriceFormatter.setCountry('FR');
      expect(PriceFormatter.formatTotalIn(62.4, 'EUR'),
          PriceFormatter.formatTotal(62.4));
    });

    test('an unrecorded currency keeps the pre-#4437 rendering', () {
      PriceFormatter.setCountry('FR');
      expect(PriceFormatter.formatTotalIn(62.4, null),
          PriceFormatter.formatTotal(62.4));
    });

    test('decimals follow the RECORD currency (HUF is whole forints)', () {
      PriceFormatter.setCountry('DE');
      expect(PriceFormatter.formatTotalIn(24990, 'HUF'), contains('24.990'));
      expect(PriceFormatter.formatTotalIn(24990, 'HUF'), endsWith(' HUF'));
      expect(PriceFormatter.formatTotalIn(24990, 'HUF'),
          isNot(contains(',00')));
    });
  });

  group('PriceFormatter.formatTallyTotal', () {
    test('a single foreign denomination prints in its own currency', () {
      PriceFormatter.setCountry('DE');
      final tally = MoneyTally.of([(51.73, 'CHF'), (10, 'CHF')]);
      expect(PriceFormatter.formatTallyTotal(tally), '61,73 CHF');
    });

    test('a mixed tally has no total to print', () {
      final tally = MoneyTally.of([(51.73, 'CHF'), (60, 'EUR')]);
      expect(PriceFormatter.formatTallyTotal(tally), isNull);
    });

    test('an all-unknown history keeps the active symbol', () {
      PriceFormatter.setCountry('FR');
      final tally = MoneyTally.of([(10, null), (20, null)]);
      expect(PriceFormatter.formatTallyTotal(tally),
          PriceFormatter.formatTotal(30));
    });
  });

  test('formatRate reads base on the left, four decimals', () {
    PriceFormatter.setCountry('DE');
    final rate = ExchangeRate(
      baseCurrency: 'CHF',
      quoteCurrency: 'EUR',
      rate: 55.12 / 51.73,
      source: 'card settlement',
      capturedAt: DateTime(2026, 9, 20),
    );
    expect(PriceFormatter.formatRate(rate), '1 CHF = 1,0655 €');
  });

  group('UnitFormatter.formatPricePerUnit(currencyCode:)', () {
    test('CHF/L under an EUR profile — the Gandria 2,020 CHF/L', () {
      PriceFormatter.setCountry('DE');
      expect(
        UnitFormatter.formatPricePerUnit(2.020,
            currencyCode: 'CHF', fuelType: FuelType.e5),
        '2,020 CHF/L',
      );
    });

    test('null or the home currency changes nothing', () {
      PriceFormatter.setCountry('FR');
      final plain = UnitFormatter.formatPricePerUnit(1.849);
      expect(UnitFormatter.formatPricePerUnit(1.849, currencyCode: 'EUR'),
          plain);
      expect(UnitFormatter.formatPricePerUnit(1.849, currencyCode: null),
          plain);
    });

    test('a GBP record keeps the forecourt pence convention', () {
      PriceFormatter.setCountry('FR');
      final s = UnitFormatter.formatPricePerUnit(1.559, currencyCode: 'GBP');
      expect(s, endsWith('p/L'));
      expect(s, startsWith('155'));
    });

    test('the per-fuel quantity rule survives (AR GNC stays per m³)', () {
      PriceFormatter.setCountry('AR');
      final s = UnitFormatter.formatPricePerUnit(450,
          countryCode: 'AR', fuelType: FuelType.cng, currencyCode: 'CHF');
      expect(s, endsWith('CHF/m³'));
    });
  });
}
