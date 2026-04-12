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
    });
  });
}
