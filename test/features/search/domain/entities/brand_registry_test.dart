import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/brand_registry.dart';

void main() {
  group('BrandRegistry', () {
    group('canonicalize', () {
      test('maps TotalEnergies variations', () {
        expect(BrandRegistry.canonicalize('TotalEnergies'), 'TotalEnergies');
        expect(BrandRegistry.canonicalize('Total'), 'TotalEnergies');
        expect(BrandRegistry.canonicalize('TOTAL'), 'TotalEnergies');
        expect(BrandRegistry.canonicalize('Total Access'), 'TotalEnergies');
      });

      test('maps E.Leclerc variations', () {
        expect(BrandRegistry.canonicalize('E.Leclerc'), 'E.Leclerc');
        expect(BrandRegistry.canonicalize('Leclerc'), 'E.Leclerc');
        expect(BrandRegistry.canonicalize('LECLERC'), 'E.Leclerc');
      });

      test('maps Intermarché variations', () {
        expect(BrandRegistry.canonicalize('Intermarché'), 'Intermarché');
        expect(BrandRegistry.canonicalize('INTERMARCHE'), 'Intermarché');
      });

      test('maps Système U variations', () {
        expect(BrandRegistry.canonicalize('Super U'), 'Système U');
        expect(BrandRegistry.canonicalize('Hyper U'), 'Système U');
        expect(BrandRegistry.canonicalize('U Express'), 'Système U');
      });

      test('maps German brands', () {
        expect(BrandRegistry.canonicalize('Aral'), 'Aral');
        expect(BrandRegistry.canonicalize('JET'), 'JET');
        expect(BrandRegistry.canonicalize('HEM'), 'HEM');
      });

      test('maps Spanish brands', () {
        expect(BrandRegistry.canonicalize('Repsol'), 'Repsol');
        expect(BrandRegistry.canonicalize('Cepsa'), 'Cepsa');
      });

      test('returns null for unknown brand', () {
        expect(BrandRegistry.canonicalize('Unknown Station'), isNull);
        expect(BrandRegistry.canonicalize('My Local Gas'), isNull);
      });

      test('returns null for empty string', () {
        expect(BrandRegistry.canonicalize(''), isNull);
      });

      test('case insensitive matching', () {
        expect(BrandRegistry.canonicalize('shell'), 'Shell');
        expect(BrandRegistry.canonicalize('SHELL'), 'Shell');
        expect(BrandRegistry.canonicalize('bp'), 'BP');
      });
    });

    group('countByBrand', () {
      test('groups known brands', () {
        final counts = BrandRegistry.countByBrand([
          'Total', 'TotalEnergies', 'Total Access',
          'Shell', 'Shell',
          'Unknown Station',
        ]);
        expect(counts['TotalEnergies'], 3);
        expect(counts['Shell'], 2);
        expect(counts[BrandRegistry.othersLabel], 1);
      });

      test('empty list returns empty map', () {
        expect(BrandRegistry.countByBrand([]), isEmpty);
      });
    });

    group('allBrands', () {
      test('returns sorted list', () {
        final brands = BrandRegistry.allBrands;
        expect(brands, isNotEmpty);
        // Check sorted
        for (int i = 1; i < brands.length; i++) {
          expect(brands[i].compareTo(brands[i - 1]) >= 0, isTrue,
              reason: '${brands[i]} should come after ${brands[i - 1]}');
        }
      });

      test('includes major international brands', () {
        final brands = BrandRegistry.allBrands;
        expect(brands, contains('TotalEnergies'));
        expect(brands, contains('Shell'));
        expect(brands, contains('BP'));
        expect(brands, contains('Esso'));
      });

      test('includes French supermarket brands', () {
        final brands = BrandRegistry.allBrands;
        expect(brands, contains('E.Leclerc'));
        expect(brands, contains('Carrefour'));
        expect(brands, contains('Intermarché'));
      });

      test('includes German brands', () {
        final brands = BrandRegistry.allBrands;
        expect(brands, contains('Aral'));
        expect(brands, contains('Orlen'));
        expect(brands, contains('HEM'));
      });

      test('includes UK supermarket brands', () {
        final brands = BrandRegistry.allBrands;
        expect(brands, contains('Tesco'));
        expect(brands, contains('Asda'));
        expect(brands, contains('Morrisons'));
      });

      test('includes Australian brands', () {
        final brands = BrandRegistry.allBrands;
        expect(brands, contains('Ampol'));
        expect(brands, contains('7-Eleven'));
      });

      test('includes Mexican brands', () {
        final brands = BrandRegistry.allBrands;
        expect(brands, contains('Pemex'));
        expect(brands, contains('Oxxo Gas'));
      });

      test('includes Argentine brands', () {
        final brands = BrandRegistry.allBrands;
        expect(brands, contains('YPF'));
        expect(brands, contains('Axion Energy'));
      });
    });

    group('regrouping', () {
      test('Star maps to Orlen (rebranded)', () {
        expect(BrandRegistry.canonicalize('Star'), 'Orlen');
        expect(BrandRegistry.canonicalize('STAR'), 'Orlen');
      });

      test('Avanti maps to OMV (discount sub-brand)', () {
        expect(BrandRegistry.canonicalize('Avanti'), 'OMV');
      });

      test('Ingo maps to Circle K (discount brand)', () {
        expect(BrandRegistry.canonicalize('Ingo'), 'Circle K');
      });

      test('Statoil maps to Circle K (legacy name)', () {
        expect(BrandRegistry.canonicalize('Statoil'), 'Circle K');
      });

      test('Caltex maps to Ampol (rebranded)', () {
        expect(BrandRegistry.canonicalize('Caltex'), 'Ampol');
      });

      test('TotalErg maps to TotalEnergies', () {
        expect(BrandRegistry.canonicalize('TotalErg'), 'TotalEnergies');
      });

      test('Esso Express maps to Esso', () {
        expect(BrandRegistry.canonicalize('Esso Express'), 'Esso');
      });

      test('Moeve maps to Cepsa (rebrand in Portugal)', () {
        expect(BrandRegistry.canonicalize('Moeve'), 'Cepsa');
      });

      test('Agip maps to ENI', () {
        expect(BrandRegistry.canonicalize('Agip'), 'ENI');
      });

      test('API maps to IP (merged)', () {
        expect(BrandRegistry.canonicalize('API'), 'IP');
      });
    });
  });
}
