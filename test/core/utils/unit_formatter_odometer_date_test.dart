// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';
import 'package:tankstellen/core/utils/unit_formatter.dart';

/// #3903 — odometer readings render as grouped whole units and list-row
/// dates as the locale's medium date.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
    await initializeDateFormatting('de_DE');
    await initializeDateFormatting('en_US');
  });
  tearDown(() => PriceFormatter.setCountry('FR'));

  String groupSep(String locale) =>
      NumberFormat.decimalPattern(locale).symbols.GROUP_SEP;

  group('formatOdometer', () {
    test('null renders the placeholder', () {
      expect(UnitFormatter.formatOdometer(null), '--');
    });

    test('FR groups thousands with the French separator, no decimals', () {
      PriceFormatter.setCountry('FR');
      expect(
        UnitFormatter.formatOdometer(122700.0),
        '122${groupSep('fr_FR')}700 km',
      );
    });

    test('DE groups thousands with a dot', () {
      PriceFormatter.setCountry('DE');
      expect(UnitFormatter.formatOdometer(122700.4), '122.700 km');
    });

    test('an English-locale metric country groups with a comma', () {
      PriceFormatter.setCountry('AU');
      expect(UnitFormatter.formatOdometer(122700), '122,700 km');
    });

    test('rounds to the nearest whole kilometre', () {
      PriceFormatter.setCountry('DE');
      expect(UnitFormatter.formatOdometer(999.6), '1.000 km');
    });

    test('imperial-distance countries convert to grouped miles', () {
      PriceFormatter.setCountry('GB');
      expect(UnitFormatter.formatOdometer(122700), '76,242 mi');
    });

    test('countryCode override keeps the unit of the origin country', () {
      PriceFormatter.setCountry('FR');
      expect(UnitFormatter.formatOdometer(10, countryCode: 'GB'), endsWith('mi'));
    });
  });

  group('formatMediumDate', () {
    final date = DateTime(2026, 8, 21);

    test('en_US → Aug 21, 2026', () {
      expect(UnitFormatter.formatMediumDate(date, locale: 'en_US'),
          'Aug 21, 2026');
    });

    test('fr_FR → 21 août 2026', () {
      expect(UnitFormatter.formatMediumDate(date, locale: 'fr_FR'),
          '21 août 2026');
    });

    test('de_DE → 21. Aug. 2026', () {
      expect(UnitFormatter.formatMediumDate(date, locale: 'de_DE'),
          '21. Aug. 2026');
    });
  });
}
