import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/price_sanity.dart';

void main() {
  group('PriceSanity', () {
    group('check (EUR countries)', () {
      test('normal diesel price is ok', () {
        expect(
          PriceSanity.check(1.75, countryCode: 'FR'),
          PriceSanityResult.ok,
        );
      });

      test('normal E10 price is ok', () {
        expect(
          PriceSanity.check(1.89, countryCode: 'DE'),
          PriceSanityResult.ok,
        );
      });

      test('price below 0.80 EUR is suspicious', () {
        expect(
          PriceSanity.check(0.50, countryCode: 'FR'),
          PriceSanityResult.suspiciousLow,
        );
      });

      test('price above 2.50 EUR is suspicious', () {
        expect(
          PriceSanity.check(2.60, countryCode: 'FR'),
          PriceSanityResult.suspiciousHigh,
        );
      });

      test('Mèze diesel at 2.429 is below threshold (ok)', () {
        // 2.429 < 2.50 so it's within range, but should flag vs average
        expect(
          PriceSanity.check(2.429, countryCode: 'FR', searchAverage: 1.75),
          PriceSanityResult.aboveAverage,
        );
      });

      test('null price returns ok', () {
        expect(
          PriceSanity.check(null, countryCode: 'FR'),
          PriceSanityResult.ok,
        );
      });

      test('zero price returns ok', () {
        expect(
          PriceSanity.check(0, countryCode: 'FR'),
          PriceSanityResult.ok,
        );
      });
    });

    group('check (non-EUR countries)', () {
      test('UK price in GBP normal range', () {
        expect(
          PriceSanity.check(1.45, countryCode: 'GB'),
          PriceSanityResult.ok,
        );
      });

      test('UK price above 2.00 GBP is suspicious', () {
        expect(
          PriceSanity.check(2.10, countryCode: 'GB'),
          PriceSanityResult.suspiciousHigh,
        );
      });

      test('Danish price in DKK normal range', () {
        expect(
          PriceSanity.check(13.50, countryCode: 'DK'),
          PriceSanityResult.ok,
        );
      });

      test('Mexican price in MXN normal range', () {
        expect(
          PriceSanity.check(22.50, countryCode: 'MX'),
          PriceSanityResult.ok,
        );
      });

      test('Australian price in AUD normal range', () {
        expect(
          PriceSanity.check(1.95, countryCode: 'AU'),
          PriceSanityResult.ok,
        );
      });

      test('Argentine price in ARS normal range', () {
        expect(
          PriceSanity.check(800, countryCode: 'AR'),
          PriceSanityResult.ok,
        );
      });
    });

    group('relative deviation', () {
      test('price 31% above average flags aboveAverage', () {
        expect(
          PriceSanity.check(1.97, countryCode: 'FR', searchAverage: 1.50),
          PriceSanityResult.aboveAverage,
        );
      });

      test('price 25% above average is ok', () {
        expect(
          PriceSanity.check(1.875, countryCode: 'FR', searchAverage: 1.50),
          PriceSanityResult.ok,
        );
      });

      test('no average provided skips relative check', () {
        expect(
          PriceSanity.check(2.40, countryCode: 'FR'),
          PriceSanityResult.ok,
        );
      });
    });

    group('average', () {
      test('calculates average of valid prices', () {
        expect(
          PriceSanity.average([1.50, 1.60, 1.70]),
          closeTo(1.60, 0.01),
        );
      });

      test('skips null prices', () {
        expect(
          PriceSanity.average([1.50, null, 1.70]),
          closeTo(1.60, 0.01),
        );
      });

      test('returns null for empty list', () {
        expect(PriceSanity.average([]), isNull);
      });

      test('returns null for all-null list', () {
        expect(PriceSanity.average([null, null]), isNull);
      });
    });

    group('thresholdFor', () {
      test('returns EUR thresholds for France', () {
        final t = PriceSanity.thresholdFor('FR');
        expect(t.low, 0.80);
        expect(t.high, 2.50);
      });

      test('returns GBP thresholds for UK', () {
        final t = PriceSanity.thresholdFor('GB');
        expect(t.low, 0.80);
        expect(t.high, 2.00);
      });

      test('returns default for unknown country', () {
        final t = PriceSanity.thresholdFor('ZZ');
        expect(t.low, 0.50);
        expect(t.high, 3.00);
      });

      test('case insensitive', () {
        expect(PriceSanity.thresholdFor('fr').high, 2.50);
        expect(PriceSanity.thresholdFor('FR').high, 2.50);
      });
    });
  });
}
