import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/brand_registry.dart';

/// Regression guards for #482 — the `Independent` sentinel that signals
/// "station has no brand, and that's intentional, not a bug".
void main() {
  group('BrandRegistry.independentLabel (regression #482)', () {
    test('is defined as a const string', () {
      expect(BrandRegistry.independentLabel, isA<String>());
      expect(BrandRegistry.independentLabel, isNotEmpty);
    });

    test(
      'is NOT in the canonical registry — sentinels are display-only, '
      'they must not leak into `allBrands` or the alias tables',
      () {
        expect(
          BrandRegistry.allBrands,
          isNot(contains(BrandRegistry.independentLabel)),
        );
        for (final aliases in BrandRegistry.brandAliases.values) {
          expect(aliases, isNot(contains(BrandRegistry.independentLabel)));
        }
      },
    );

    test(
      'canonicalize returns null for the sentinel, so it buckets into '
      'Others in the chip strip (not a separate chip label)',
      () {
        expect(
          BrandRegistry.canonicalize(BrandRegistry.independentLabel),
          isNull,
        );
      },
    );

    test(
      'countByBrand routes the sentinel through the Others bucket, '
      'matching applyBrandFilter behaviour',
      () {
        final counts = BrandRegistry.countByBrand([
          BrandRegistry.independentLabel,
          BrandRegistry.independentLabel,
          'Total',
        ]);
        expect(counts['TotalEnergies'], 1);
        expect(counts[BrandRegistry.othersLabel], 2);
        // No key ever equals the sentinel.
        expect(counts.keys, isNot(contains(BrandRegistry.independentLabel)));
      },
    );
  });
}
