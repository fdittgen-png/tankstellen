// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/fill_ups/domain/fill_up_currency.dart';

/// #4428 — the rule that decides which currency a fill-up is recorded
/// in. The field report: an EUR profile, a Swiss forecourt, CHF 51,73
/// on the card, and the old code stored EUR 51,73.
String? _resolve({
  String? recorded,
  String? stationId,
  String? observed,
  String profileCountry = 'DE',
  String profileCurrency = 'EUR',
}) =>
    resolveFillUpCurrency(
      recordedCurrency: recorded,
      stationId: stationId,
      observedCountryCode: observed,
      profileCountryCode: profileCountry,
      profileCurrency: profileCurrency,
    );

void main() {
  group('what the record already says wins', () {
    test('a recorded currency is never relabelled', () {
      expect(_resolve(recorded: 'CHF', stationId: 'de-42', observed: 'DE'),
          'CHF');
    });

    test('it wins even against the station it was logged at', () {
      // A CHF receipt scanned at a station the app files under GB is
      // still a CHF purchase: the paper is the transaction.
      expect(_resolve(recorded: 'CHF', stationId: 'uk-1'), 'CHF');
    });

    test('it is normalised to upper case so eur and EUR are one bucket',
        () {
      expect(_resolve(recorded: ' eur '), 'EUR');
    });

    test('an empty string is not a currency', () {
      expect(_resolve(recorded: '   '), 'EUR');
    });
  });

  group("the station's country", () {
    test('a British station on an EUR profile records GBP', () {
      expect(_resolve(stationId: 'uk-abc'), 'GBP');
    });

    test('a Danish station on an EUR profile records DKK', () {
      expect(_resolve(stationId: 'ok-77'), 'DKK');
    });

    test('a domestic station keeps the profile currency', () {
      expect(_resolve(stationId: 'de-abc'), 'EUR');
    });

    test('an unrecognised station id is no evidence either way', () {
      // Tankerkoenig / Prix-Carburants legacy favourites carry bare
      // upstream ids. Silence is not a contradiction.
      expect(_resolve(stationId: '51b3cc'), 'EUR');
    });
  });

  group('where the driver actually is', () {
    test('the Swiss case: abroad, unnameable currency, so unknown', () {
      // CH is not in the country registry, so there is no honest way
      // to name what the driver paid — and EUR is a lie.
      expect(_resolve(observed: 'CH'), isNull);
    });

    test('abroad in a foreign currency withholds rather than guesses', () {
      // DKK is *likely*, but a fill logged from a Copenhagen hotel may
      // well be last week's fill at home. A wrong label is worse than
      // a blank one.
      expect(_resolve(observed: 'DK'), isNull);
    });

    test('abroad in the same currency is no contradiction at all', () {
      expect(_resolve(observed: 'FR'), 'EUR');
    });

    test('at home, the profile currency stands', () {
      expect(_resolve(observed: 'DE'), 'EUR');
    });

    test('case and padding do not change the verdict', () {
      expect(_resolve(observed: ' de '), 'EUR');
    });

    test('no observation at all is the domestic status quo', () {
      expect(_resolve(), 'EUR');
      expect(_resolve(observed: ''), 'EUR');
    });

    test('the station outranks the observation', () {
      // Filling at a German station while the phone still thinks it is
      // in Switzerland: the station is the harder fact.
      expect(_resolve(stationId: 'de-1', observed: 'CH'), 'EUR');
    });
  });

  group('a non-EUR profile is symmetric', () {
    test('a British profile at home records GBP', () {
      expect(
        _resolve(profileCountry: 'GB', profileCurrency: 'GBP'),
        'GBP',
      );
    });

    test('a British profile at a German station records EUR', () {
      expect(
        _resolve(
          stationId: 'de-1',
          profileCountry: 'GB',
          profileCurrency: 'GBP',
        ),
        'EUR',
      );
    });

    test('a British profile observed in Switzerland records unknown', () {
      expect(
        _resolve(
          observed: 'CH',
          profileCountry: 'GB',
          profileCurrency: 'GBP',
        ),
        isNull,
      );
    });
  });
}
