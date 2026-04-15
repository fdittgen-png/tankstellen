import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';

void main() {
  group('PriceFormatter', () {
    group('locale-aware formatting', () {
      test('French locale uses comma decimal separator', () {
        PriceFormatter.setCountry('FR');
        final formatted = PriceFormatter.formatPriceCompact(1.459);
        expect(formatted, contains(','));
        expect(formatted, isNot(contains('.')));
      });

      test('UK locale uses period decimal separator', () {
        PriceFormatter.setCountry('GB');
        final formatted = PriceFormatter.formatPriceCompact(1.459);
        expect(formatted, contains('.'));
      });

      test('Australian locale uses period decimal separator', () {
        PriceFormatter.setCountry('AU');
        final formatted = PriceFormatter.formatPriceCompact(1.959);
        expect(formatted, contains('.'));
      });

      test('Mexican locale uses period decimal separator', () {
        PriceFormatter.setCountry('MX');
        final formatted = PriceFormatter.formatPriceCompact(22.50);
        expect(formatted, contains('.'));
      });

      test('German locale uses comma decimal separator', () {
        PriceFormatter.setCountry('DE');
        final formatted = PriceFormatter.formatPriceCompact(1.899);
        expect(formatted, contains(','));
      });
    });

    group('currency symbols', () {
      test('EUR for France', () {
        PriceFormatter.setCountry('FR');
        expect(PriceFormatter.currency, '€');
        expect(PriceFormatter.formatPrice(1.459), contains('€'));
      });

      test('GBP for UK', () {
        PriceFormatter.setCountry('GB');
        expect(PriceFormatter.currency, '£');
        expect(PriceFormatter.formatPrice(1.459), contains('£'));
      });

      test('AUD for Australia', () {
        PriceFormatter.setCountry('AU');
        expect(PriceFormatter.currency, '\$');
      });

      test('DKK for Denmark', () {
        PriceFormatter.setCountry('DK');
        expect(PriceFormatter.currency, 'kr');
      });
    });

    group('null and zero handling', () {
      test('null price returns --', () {
        PriceFormatter.setCountry('FR');
        expect(PriceFormatter.formatPrice(null), '--');
      });

      test('zero price returns --', () {
        expect(PriceFormatter.formatPrice(0), '--');
      });

      test('negative price returns --', () {
        expect(PriceFormatter.formatPrice(-1.5), '--');
      });
    });

    group('distance formatting', () {
      test('formats km with locale separator', () {
        PriceFormatter.setCountry('FR');
        final d = PriceFormatter.formatDistance(2.3);
        expect(d, contains('km'));
      });

      test('formats meters for < 1 km', () {
        PriceFormatter.setCountry('FR');
        expect(PriceFormatter.formatDistance(0.5), '500 m');
      });

      test('null distance returns --', () {
        expect(PriceFormatter.formatDistance(null), '--');
      });
    });

    group('setCountry', () {
      test('case insensitive', () {
        PriceFormatter.setCountry('gb');
        expect(PriceFormatter.currency, '£');
      });

      test('unknown country defaults to USD-style', () {
        PriceFormatter.setCountry('ZZ');
        expect(PriceFormatter.currency, '€'); // default
      });
    });
  });

  group('currencyOverride (#514 favorites per-station currency)', () {
    test('formatPrice honours currencyOverride over the global country',
        () {
      PriceFormatter.setCountry('FR');
      expect(
        PriceFormatter.formatPrice(1.559, currencyOverride: '£'),
        contains('£'),
      );
      expect(
        PriceFormatter.formatPrice(1.559, currencyOverride: '£'),
        isNot(contains('€')),
      );
    });

    test('formatPrice without override keeps the global currency', () {
      PriceFormatter.setCountry('FR');
      expect(PriceFormatter.formatPrice(1.559), contains('€'));
    });

    test('priceTextSpan honours currencyOverride', () {
      PriceFormatter.setCountry('FR');
      final span = PriceFormatter.priceTextSpan(
        1.559,
        baseStyle: const TextStyle(fontSize: 14),
        currencyOverride: '£',
      );
      final rendered = span.toPlainText();
      expect(rendered, contains('£'));
      expect(rendered, isNot(contains('€')));
    });

    test('priceTextSpan without override falls back to global currency',
        () {
      PriceFormatter.setCountry('FR');
      final span = PriceFormatter.priceTextSpan(
        1.559,
        baseStyle: const TextStyle(fontSize: 14),
      );
      expect(span.toPlainText(), contains('€'));
    });
  });

  group('Countries.countryCodeForStationId (#514)', () {
    test('dispatches every known country-specific prefix', () {
      expect(Countries.countryCodeForStationId('pt-12345'), 'PT');
      expect(Countries.countryCodeForStationId('uk-BP1'), 'GB');
      expect(Countries.countryCodeForStationId('au-NSW001'), 'AU');
      expect(Countries.countryCodeForStationId('mx-abc'), 'MX');
      expect(Countries.countryCodeForStationId('ar-xyz'), 'AR');
      expect(Countries.countryCodeForStationId('ok-42'), 'DK');
      expect(Countries.countryCodeForStationId('shell-42'), 'DK');
    });

    test('returns null for raw numeric ids (FR / ES / IT / DE / AT)', () {
      // These services use unprefixed upstream ids — Tankerkoenig
      // UUIDs, Prix-Carburants numeric ids, MISE registry ids, etc.
      expect(Countries.countryCodeForStationId('12345'), isNull);
      expect(
        Countries.countryCodeForStationId(
            '550e8400-e29b-41d4-a716-446655440000'),
        isNull,
      );
    });

    test('returns null for unknown prefixes and empty / null input', () {
      expect(Countries.countryCodeForStationId('zz-123'), isNull);
      expect(Countries.countryCodeForStationId(''), isNull);
      expect(Countries.countryCodeForStationId(null), isNull);
    });

    test('demo ids are not mapped to a country', () {
      expect(Countries.countryCodeForStationId('demo-48.1-2.0-5'), isNull);
    });
  });

  group('Countries.countryForStationId (#514)', () {
    test('returns the CountryConfig with the origin currency symbol', () {
      expect(
        Countries.countryForStationId('uk-BP1')?.currencySymbol,
        '£',
      );
      expect(
        Countries.countryForStationId('pt-42')?.currencySymbol,
        '€',
      );
      expect(
        Countries.countryForStationId('mx-foo')?.currencySymbol,
        '\$',
      );
      expect(
        Countries.countryForStationId('au-NSW001')?.currencySymbol,
        '\$',
      );
      expect(
        Countries.countryForStationId('ar-xyz')?.currencySymbol,
        '\$',
      );
      expect(
        Countries.countryForStationId('ok-10')?.currencySymbol,
        'kr',
      );
    });

    test('returns null when no prefix matches', () {
      expect(Countries.countryForStationId('12345'), isNull);
      expect(Countries.countryForStationId(null), isNull);
    });
  });
}
