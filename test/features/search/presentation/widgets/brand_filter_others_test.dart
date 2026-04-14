import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/brand_registry.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/presentation/widgets/brand_filter_chips.dart';

/// Regression guard for #469 — the "Others" brand filter was reported
/// to leak stations whose brand string matches a known brand in the
/// registry (Total, Esso, Dyneff, Esso Express, Intermarché). The
/// filter is supposed to return *only* stations whose canonical brand
/// is the [BrandRegistry.othersLabel] sentinel.
///
/// This test mirrors the user's actual reproduction:
///   - GPS search around Pézenas (France / Prix Carburants)
///   - 10 km radius, Super E10
///   - 10 results: 5 known-brand + 5 unbranded / generic operators
///   - Brand filter set to "Others"
///   - Expected: only the 5 unbranded stations remain.
Station _station(String id, String brand) => Station(
      id: id,
      name: id,
      brand: brand,
      street: 'Rue Test',
      houseNumber: '1',
      postCode: '34120',
      place: 'Pézenas',
      lat: 43.0,
      lng: 3.0,
      dist: 1.0,
      isOpen: true,
    );

void main() {
  group('applyBrandFilter "Others" predicate (regression #469)', () {
    final stations = <Station>[
      // 5 stations with known brands — should be filtered OUT under "Others"
      _station('total-1', 'Total'),
      _station('esso-1', 'Esso'),
      _station('dyneff-1', 'Dyneff'),
      _station('esso-express-1', 'Esso Express'),
      _station('intermarche-1', 'Intermarché'),
      // 5 stations with no brand or generic operator — should pass
      _station('pez-1', ''),
      _station('verdun-1', '   '),
      _station('captpi-1', ''),
      _station('aire-1', ''),
      _station('generic-1', 'Mystery Independent'),
    ];

    test('selecting "Others" returns only stations with no recognised brand',
        () {
      final filtered = applyBrandFilter(
        stations,
        selectedBrands: const {BrandRegistry.othersLabel},
        excludeHighway: false,
      );

      // Expectation: 5 unbranded stations only.
      expect(filtered, hasLength(5));
      // None of the 5 known brands should be present.
      final ids = filtered.map((s) => s.id).toSet();
      expect(ids, isNot(contains('total-1')));
      expect(ids, isNot(contains('esso-1')));
      expect(ids, isNot(contains('dyneff-1')));
      expect(ids, isNot(contains('esso-express-1')));
      expect(ids, isNot(contains('intermarche-1')));
      // All 5 unbranded ones should be present.
      expect(ids, containsAll(['pez-1', 'verdun-1', 'captpi-1', 'aire-1', 'generic-1']));
    });

    test('selecting "TotalEnergies" returns Total + Total Access + variants',
        () {
      final mixed = <Station>[
        _station('total', 'Total'),
        _station('total-access', 'Total Access'),
        _station('totalenergies', 'TotalEnergies'),
        _station('total-upper', 'TOTAL'),
        _station('not-total', 'Esso'),
      ];

      final filtered = applyBrandFilter(
        mixed,
        selectedBrands: const {'TotalEnergies'},
        excludeHighway: false,
      );

      expect(filtered, hasLength(4));
      expect(filtered.map((s) => s.id), isNot(contains('not-total')));
    });

    test('selecting "Esso" matches both "Esso" and "Esso Express"', () {
      final mixed = <Station>[
        _station('esso', 'Esso'),
        _station('esso-express', 'Esso Express'),
        _station('not-esso', 'Total'),
      ];

      final filtered = applyBrandFilter(
        mixed,
        selectedBrands: const {'Esso'},
        excludeHighway: false,
      );

      expect(filtered, hasLength(2));
      expect(filtered.map((s) => s.id), containsAll(['esso', 'esso-express']));
    });
  });

  group('BrandRegistry.canonicalize is stable for case + variants', () {
    test('exact case-insensitive match', () {
      expect(BrandRegistry.canonicalize('Total'), 'TotalEnergies');
      expect(BrandRegistry.canonicalize('TOTAL'), 'TotalEnergies');
      expect(BrandRegistry.canonicalize('total'), 'TotalEnergies');
    });

    test('alias families fold into the same canonical', () {
      expect(BrandRegistry.canonicalize('Total Access'), 'TotalEnergies');
      expect(BrandRegistry.canonicalize('Esso Express'), 'Esso');
      expect(BrandRegistry.canonicalize('Avanti'), 'OMV');
      expect(BrandRegistry.canonicalize('Caltex'), 'Ampol');
      expect(BrandRegistry.canonicalize('Star'), 'Orlen');
    });

    test('empty / whitespace input returns null (-> Others bucket)', () {
      expect(BrandRegistry.canonicalize(''), isNull);
      expect(BrandRegistry.canonicalize('   '), isNull);
    });

    test('unknown brand returns null (-> Others bucket)', () {
      expect(BrandRegistry.canonicalize('Mystery Independent'), isNull);
    });
  });
}
