import 'package:flutter_test/flutter_test.dart';
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
}
