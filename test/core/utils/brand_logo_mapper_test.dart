import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/brand_logo_mapper.dart';

void main() {
  group('BrandLogoMapper', () {
    group('logoUrl', () {
      test('returns URL for known brand (exact case)', () {
        final url = BrandLogoMapper.logoUrl('Shell');
        expect(url, 'https://logo.clearbit.com/shell.com?size=128');
      });

      test('returns URL for known brand (uppercase)', () {
        final url = BrandLogoMapper.logoUrl('ARAL');
        expect(url, 'https://logo.clearbit.com/aral.de?size=128');
      });

      test('returns URL for known brand (mixed case)', () {
        final url = BrandLogoMapper.logoUrl('TotalEnergies');
        expect(url, 'https://logo.clearbit.com/totalenergies.com?size=128');
      });

      test('returns URL for brand with accents', () {
        final url = BrandLogoMapper.logoUrl('Intermarché');
        expect(url, 'https://logo.clearbit.com/intermarche.com?size=128');
      });

      test('returns null for unknown brand', () {
        expect(BrandLogoMapper.logoUrl('UnknownBrand123'), isNull);
      });

      test('returns null for empty string', () {
        expect(BrandLogoMapper.logoUrl(''), isNull);
      });

      test('returns null for generic "Station"', () {
        // "Station" is not a brand — should not map
        expect(BrandLogoMapper.logoUrl('Station'), isNull);
      });

      test('trims whitespace from brand name', () {
        final url = BrandLogoMapper.logoUrl('  Shell  ');
        expect(url, 'https://logo.clearbit.com/shell.com?size=128');
      });

      test('maps French supermarket brands', () {
        expect(BrandLogoMapper.logoUrl('E.Leclerc'), isNotNull);
        expect(BrandLogoMapper.logoUrl('Carrefour'), isNotNull);
        expect(BrandLogoMapper.logoUrl('Auchan'), isNotNull);
        expect(BrandLogoMapper.logoUrl('Super U'), isNotNull);
      });

      test('maps German brands', () {
        expect(BrandLogoMapper.logoUrl('ARAL'), isNotNull);
        expect(BrandLogoMapper.logoUrl('JET'), isNotNull);
        expect(BrandLogoMapper.logoUrl('HEM'), isNotNull);
        expect(BrandLogoMapper.logoUrl('STAR'), isNotNull);
      });

      test('maps Spanish brands', () {
        expect(BrandLogoMapper.logoUrl('Repsol'), isNotNull);
        expect(BrandLogoMapper.logoUrl('Cepsa'), isNotNull);
        expect(BrandLogoMapper.logoUrl('Galp'), isNotNull);
      });

      test('maps international brands', () {
        expect(BrandLogoMapper.logoUrl('BP'), isNotNull);
        expect(BrandLogoMapper.logoUrl('Esso'), isNotNull);
        expect(BrandLogoMapper.logoUrl('AVIA'), isNotNull);
        expect(BrandLogoMapper.logoUrl('OMV'), isNotNull);
      });
    });

    group('hasLogo', () {
      test('returns true for known brand', () {
        expect(BrandLogoMapper.hasLogo('Shell'), isTrue);
      });

      test('returns false for unknown brand', () {
        expect(BrandLogoMapper.hasLogo('NoSuchBrand'), isFalse);
      });

      test('returns false for empty string', () {
        expect(BrandLogoMapper.hasLogo(''), isFalse);
      });
    });
  });
}
