import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/brand_registry.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/presentation/widgets/brand_filter_chips.dart';

/// Regression guards for #481 — the chip strip was silently dropping
/// stations with empty brand strings, which made the chip counts stop
/// matching the total station count (a 10-station search could render a
/// chip strip totalling 7, with three stations invisible in the filter
/// UI even though they still appeared in the results list).
///
/// These tests pin the fix in `BrandFilterChips.extractGroupedBrands`:
/// every station contributes to exactly one chip count, and unknown
/// brands bucket into `BrandRegistry.othersLabel` rather than showing
/// up as their own chip label.
Station _s(String id, String brand) => Station(
      id: id,
      name: id,
      brand: brand,
      street: 'Rue Test',
      houseNumber: '1',
      postCode: '34120',
      place: 'Test',
      lat: 43.0,
      lng: 3.0,
      dist: 1.0,
      isOpen: true,
    );

void main() {
  group('BrandFilterChips.extractGroupedBrands (regression #481)', () {
    test(
      'chip counts always sum to the total station count, even when some '
      'stations have empty or whitespace-only brand strings',
      () {
        final stations = <Station>[
          _s('a', 'Total'),
          _s('b', 'Esso'),
          _s('c', ''),
          _s('d', '   '),
          _s('e', 'MysteryCorp'),
        ];
        final counts = BrandFilterChips.extractGroupedBrands(stations);
        expect(
          counts.values.fold<int>(0, (a, b) => a + b),
          stations.length,
          reason: 'every station must contribute to exactly one chip count',
        );
      },
    );

    test('empty-brand stations bucket into Others, not a blank chip', () {
      final stations = <Station>[
        _s('a', ''),
        _s('b', '   '),
      ];
      final counts = BrandFilterChips.extractGroupedBrands(stations);
      expect(counts, {BrandRegistry.othersLabel: 2});
      expect(counts.keys, isNot(contains('')));
    });

    test(
      'no chip label ever appears that is not a canonical brand, Others, '
      'or the intentional Autoroute sentinel',
      () {
        final stations = <Station>[
          _s('total', 'Total'),
          _s('total-access', 'Total Access'),
          _s('esso-express', 'Esso Express'),
          _s('dyneff', 'Dyneff'),
          _s('intermarche', 'Intermarché'),
          _s('pez-1', ''),
          _s('pez-2', 'Pézenas Carburant'),
          _s('mystery', 'ff'),
          _s('mystery2', 'x'),
          _s('aire', 'AIRE DE BEZIERS'),
        ];
        final counts = BrandFilterChips.extractGroupedBrands(stations);
        final validLabels = <String>{
          ...BrandRegistry.allBrands,
          BrandRegistry.othersLabel,
          BrandRegistry.independentLabel,
          'Autoroute',
        };
        for (final label in counts.keys) {
          expect(
            validLabels,
            contains(label),
            reason: 'chip "$label" is not a canonical brand or a recognised '
                'sentinel — no raw brand strings may leak into the chip strip',
          );
        }
        expect(
          counts.values.fold<int>(0, (a, b) => a + b),
          stations.length,
        );
      },
    );

    test('Esso Express folds into Esso, TOTAL variants fold into TotalEnergies',
        () {
      final stations = <Station>[
        _s('total', 'Total'),
        _s('totalenergies', 'TotalEnergies'),
        _s('total-access', 'Total Access'),
        _s('total-upper', 'TOTAL'),
        _s('esso', 'Esso'),
        _s('esso-express', 'Esso Express'),
        _s('esso-upper', 'ESSO EXPRESS'),
      ];
      final counts = BrandFilterChips.extractGroupedBrands(stations);
      expect(counts['TotalEnergies'], 4);
      expect(counts['Esso'], 3);
      // No stray keys.
      expect(
        counts.keys.toSet(),
        {'TotalEnergies', 'Esso'},
      );
    });

    test(
      'the Independent sentinel from the Prix Carburants heuristic also '
      'buckets into Others via canonicalize (stays consistent with the '
      'filter predicate in applyBrandFilter)',
      () {
        final stations = <Station>[
          _s('a', BrandRegistry.independentLabel),
          _s('b', BrandRegistry.independentLabel),
          _s('c', 'Total'),
        ];
        final counts = BrandFilterChips.extractGroupedBrands(stations);
        // Independent isn't in the registry → canonicalize returns null
        // → buckets into Others. TotalEnergies picks up Total.
        expect(counts['TotalEnergies'], 1);
        expect(counts['Others'], 2);
      },
    );
  });
}
