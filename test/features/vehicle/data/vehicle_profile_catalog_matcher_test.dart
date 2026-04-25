import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/data/vehicle_profile_catalog_matcher.dart';
import 'package:tankstellen/features/vehicle/domain/entities/reference_vehicle.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';

/// Unit tests for [VehicleProfileCatalogMatcher] (#950 phase 4).
///
/// The matcher is pure — no Hive, no network, no Riverpod. We feed it
/// hand-built [ReferenceVehicle] catalogs that mirror the asset shape
/// without depending on the bundled JSON, so the tests don't drift if
/// the canonical catalog is reordered.
void main() {
  // The first Peugeot row in the canonical catalog. Matches by year
  // window via Tier 1.
  const peugeot208II = ReferenceVehicle(
    make: 'Peugeot',
    model: '208',
    generation: 'II (2019-)',
    yearStart: 2019,
    displacementCc: 1199,
    fuelType: 'petrol',
    transmission: 'manual',
    odometerPidStrategy: 'psaUds',
  );

  // A second Peugeot model so the make-only fallback has somewhere to
  // land when the model name is unknown.
  const peugeot308 = ReferenceVehicle(
    make: 'Peugeot',
    model: '308',
    generation: 'III (2021-)',
    yearStart: 2021,
    displacementCc: 1199,
    fuelType: 'petrol',
    transmission: 'automatic',
    odometerPidStrategy: 'psaUds',
  );

  // A Renault row so we can prove cross-make queries don't accidentally
  // return Peugeot.
  const renaultClio = ReferenceVehicle(
    make: 'Renault',
    model: 'Clio',
    generation: 'V (2019-)',
    yearStart: 2019,
    displacementCc: 999,
    fuelType: 'petrol',
    transmission: 'manual',
    odometerPidStrategy: 'stdA6',
  );

  const catalog = <ReferenceVehicle>[peugeot208II, peugeot308, renaultClio];

  group('VehicleProfileCatalogMatcher.bestMatch', () {
    test('Tier 1: exact make + model + year matches catalog entry', () {
      const profile = VehicleProfile(
        id: 'p1',
        name: 'My 208',
        make: 'Peugeot',
        model: '208',
        year: 2020,
      );
      final match = VehicleProfileCatalogMatcher.bestMatch(
        profile: profile,
        catalog: catalog,
      );
      expect(match, peugeot208II);
    });

    test('Tier 1 is case-insensitive on make and model', () {
      const profile = VehicleProfile(
        id: 'p2',
        name: 'My 208',
        make: 'peugeot',
        model: '208',
        year: 2020,
      );
      final match = VehicleProfileCatalogMatcher.bestMatch(
        profile: profile,
        catalog: catalog,
      );
      expect(match, peugeot208II);
    });

    test(
        'Tier 2: out-of-window year falls back to make + model match',
        () {
      // Peugeot 208 with a year far before any catalog generation.
      const profile = VehicleProfile(
        id: 'p3',
        name: 'Old 208',
        make: 'Peugeot',
        model: '208',
        year: 1955,
      );
      final match = VehicleProfileCatalogMatcher.bestMatch(
        profile: profile,
        catalog: catalog,
      );
      expect(match, peugeot208II,
          reason:
              'Make + model wins when year is outside the catalog window');
    });

    test('Tier 2: missing year still produces make + model match', () {
      const profile = VehicleProfile(
        id: 'p4',
        name: 'My 208',
        make: 'Peugeot',
        model: '208',
      );
      final match = VehicleProfileCatalogMatcher.bestMatch(
        profile: profile,
        catalog: catalog,
      );
      expect(match, peugeot208II);
    });

    test(
        'Tier 3: unknown model with known make returns first '
        'matching make entry', () {
      const profile = VehicleProfile(
        id: 'p5',
        name: 'My Peugeot',
        make: 'Peugeot',
        model: 'Bar',
        year: 2020,
      );
      final match = VehicleProfileCatalogMatcher.bestMatch(
        profile: profile,
        catalog: catalog,
      );
      expect(match, peugeot208II,
          reason:
              'Make-only fallback returns the first catalog row for the brand');
    });

    test('returns null when make is unknown', () {
      const profile = VehicleProfile(
        id: 'p6',
        name: 'Acme',
        make: 'Acme',
        model: 'Foo',
        year: 2020,
      );
      final match = VehicleProfileCatalogMatcher.bestMatch(
        profile: profile,
        catalog: catalog,
      );
      expect(match, isNull);
    });

    test('returns null when make is empty or null', () {
      const profileNoMake = VehicleProfile(id: 'p7', name: 'X');
      expect(
        VehicleProfileCatalogMatcher.bestMatch(
          profile: profileNoMake,
          catalog: catalog,
        ),
        isNull,
      );

      const profileBlankMake =
          VehicleProfile(id: 'p8', name: 'X', make: '   ');
      expect(
        VehicleProfileCatalogMatcher.bestMatch(
          profile: profileBlankMake,
          catalog: catalog,
        ),
        isNull,
      );
    });

    test('cross-make queries do not leak between brands', () {
      const profile = VehicleProfile(
        id: 'p9',
        name: 'Clio',
        make: 'Renault',
        model: 'Clio',
        year: 2020,
      );
      final match = VehicleProfileCatalogMatcher.bestMatch(
        profile: profile,
        catalog: catalog,
      );
      expect(match, renaultClio);
    });
  });

  group('VehicleProfileCatalogMatcher.slugFor', () {
    test('produces lowercase dashed slugs for catalog entries', () {
      expect(
        VehicleProfileCatalogMatcher.slugFor(peugeot208II),
        'peugeot-208-ii-2019',
      );
    });

    test('collapses spaces and punctuation to single dashes', () {
      const c5Aircross = ReferenceVehicle(
        make: 'Citroen',
        model: 'C5 Aircross',
        generation: 'I (2018-)',
        yearStart: 2018,
        displacementCc: 1499,
        fuelType: 'diesel',
        transmission: 'automatic',
        odometerPidStrategy: 'psaUds',
      );
      expect(
        VehicleProfileCatalogMatcher.slugFor(c5Aircross),
        'citroen-c5-aircross-i-2018',
      );
    });
  });
}
