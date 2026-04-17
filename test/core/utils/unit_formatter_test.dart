import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';
import 'package:tankstellen/core/utils/unit_formatter.dart';

void main() {
  // Ensure every test starts from the default "France" context that
  // PriceFormatter uses. Tests that override the active country
  // restore it in `tearDown`.
  setUp(() => PriceFormatter.setCountry('FR'));
  tearDown(() => PriceFormatter.setCountry('FR'));

  group('formatDistance', () {
    test('null returns placeholder', () {
      expect(UnitFormatter.formatDistance(null), '--');
    });

    test('metric countries render km with one decimal', () {
      // FR locale uses comma as decimal separator.
      expect(UnitFormatter.formatDistance(12.34), '12,3 km');
    });

    test('sub-kilometre metric falls back to metres', () {
      expect(UnitFormatter.formatDistance(0.45), '450 m');
    });

    test('UK renders miles rather than km', () {
      // 10 km ≈ 6.21 mi. Active country stays FR (comma), but the
      // explicit GB override governs the unit suffix — numbers still
      // reflect the active country's decimal convention.
      expect(UnitFormatter.formatDistance(10, countryCode: 'GB'),
          contains('mi'));
    });

    test('sub-mile UK distance falls back to yards', () {
      // 1 km ≈ 1094 yd
      expect(UnitFormatter.formatDistance(0.5, countryCode: 'GB'),
          endsWith(' yd'));
    });

    test('active country governs when no override is passed', () {
      PriceFormatter.setCountry('GB');
      // English locale uses dot as decimal separator.
      expect(UnitFormatter.formatDistance(10), '6.2 mi');
    });

    test('unknown country code falls back to active country', () {
      PriceFormatter.setCountry('DE');
      expect(UnitFormatter.formatDistance(5, countryCode: 'ZZ'), '5,0 km');
    });
  });

  group('formatVolume', () {
    test('null returns placeholder', () {
      expect(UnitFormatter.formatVolume(null), '--');
    });

    test('every supported country renders litres today', () {
      for (final code in ['FR', 'DE', 'GB', 'AU', 'MX', 'AR']) {
        // Active locale is FR (setUp), so "42,5 L" regardless of
        // the override — cross-country volume override only switches
        // the UNIT (L vs gal), not the decimal separator.
        expect(UnitFormatter.formatVolume(42.5, countryCode: code),
            '42,5 L', reason: '$code should use L today');
      }
    });
  });

  group('formatPricePerUnit', () {
    test('null / non-positive returns placeholder', () {
      expect(UnitFormatter.formatPricePerUnit(null), '--');
      expect(UnitFormatter.formatPricePerUnit(0), '--');
      expect(UnitFormatter.formatPricePerUnit(-1), '--');
    });

    test('Euro countries render €/L with 3 decimals', () {
      // Active locale is FR (setUp) → comma decimal.
      expect(UnitFormatter.formatPricePerUnit(1.849, countryCode: 'FR'),
          '1,849 \u20ac/L');
      expect(UnitFormatter.formatPricePerUnit(1.649, countryCode: 'DE'),
          '1,649 \u20ac/L');
    });

    test('UK scales to pence-per-litre (p/L) with one decimal', () {
      // £1.559 → 155.9 p/L (UK forecourt convention). Active locale
      // FR means the number part is "155,9" (comma); the unit
      // convention (scale-to-pence, "p/L" suffix) is what the
      // country override sets.
      expect(UnitFormatter.formatPricePerUnit(1.559, countryCode: 'GB'),
          '155,9 p/L');
    });

    test('AU scales to cents-per-litre (c/L) with one decimal', () {
      // $1.859 → 185.9 c/L
      expect(UnitFormatter.formatPricePerUnit(1.859, countryCode: 'AU'),
          '185,9 c/L');
    });

    test('Denmark uses kr/L suffix', () {
      final formatted =
          UnitFormatter.formatPricePerUnit(14.5, countryCode: 'DK');
      expect(formatted, endsWith('kr/L'));
      expect(formatted, contains('14'));
      expect(formatted, contains('500'));
    });

    test('Mexico / Argentina use \$/L suffix', () {
      expect(UnitFormatter.formatPricePerUnit(25.0, countryCode: 'MX'),
          endsWith('\$/L'));
      expect(UnitFormatter.formatPricePerUnit(900.0, countryCode: 'AR'),
          endsWith('\$/L'));
    });

    test('cross-country rendering uses origin-country suffix', () {
      // User is in FR (setUp), looking at a UK station — suffix and
      // scale follow GB convention.
      expect(UnitFormatter.formatPricePerUnit(1.559, countryCode: 'GB'),
          '155,9 p/L');
      // Symmetric case: user in GB, looking at a FR station, should
      // get €/L not p/L, and number follows en_GB locale (dot).
      PriceFormatter.setCountry('GB');
      expect(UnitFormatter.formatPricePerUnit(1.849, countryCode: 'FR'),
          '1.849 \u20ac/L');
    });
  });

  group('pricePerUnitSuffix', () {
    test('returns the suffix string only', () {
      expect(UnitFormatter.pricePerUnitSuffix(countryCode: 'FR'), '\u20ac/L');
      expect(UnitFormatter.pricePerUnitSuffix(countryCode: 'GB'), 'p/L');
      expect(UnitFormatter.pricePerUnitSuffix(countryCode: 'AU'), 'c/L');
      expect(UnitFormatter.pricePerUnitSuffix(countryCode: 'DK'), 'kr/L');
    });
  });
}
