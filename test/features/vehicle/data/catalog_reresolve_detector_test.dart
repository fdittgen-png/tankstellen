import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/data/catalog_reresolve_detector.dart';
import 'package:tankstellen/features/vehicle/data/vehicle_profile_catalog_matcher.dart';
import 'package:tankstellen/features/vehicle/domain/entities/reference_vehicle.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';

/// Unit tests for [CatalogReresolveDetector] (#1396).
///
/// Pure-logic detector — tests build hand-rolled profiles + catalog
/// rows and a `Set<String>` flag store; no Hive, no Riverpod.
void main() {
  const dusterPetrol = ReferenceVehicle(
    make: 'Dacia',
    model: 'Duster',
    generation: 'II (2017-2023)',
    yearStart: 2017,
    yearEnd: 2023,
    displacementCc: 1332,
    fuelType: 'petrol',
    transmission: 'manual',
    odometerPidStrategy: 'stdA6',
  );

  const dusterDiesel = ReferenceVehicle(
    make: 'Dacia',
    model: 'Duster',
    generation: 'II dCi 115 (2017-2024)',
    yearStart: 2017,
    yearEnd: 2024,
    displacementCc: 1461,
    fuelType: 'diesel',
    transmission: 'manual',
    volumetricEfficiency: 0.95,
    odometerPidStrategy: 'stdA6',
  );

  const peugeot208Petrol = ReferenceVehicle(
    make: 'Peugeot',
    model: '208',
    generation: 'II (2019-)',
    yearStart: 2019,
    displacementCc: 1199,
    fuelType: 'petrol',
    transmission: 'manual',
    odometerPidStrategy: 'psaUds',
  );

  final dusterPetrolSlug =
      VehicleProfileCatalogMatcher.slugFor(dusterPetrol);
  final dusterDieselSlug =
      VehicleProfileCatalogMatcher.slugFor(dusterDiesel);
  final peugeot208Slug =
      VehicleProfileCatalogMatcher.slugFor(peugeot208Petrol);

  final catalog = <ReferenceVehicle>[
    dusterPetrol,
    dusterDiesel,
    peugeot208Petrol,
  ];

  /// Test helper — closure-backed flag store.
  bool Function(String) flagsBackedBy(Set<String> set) =>
      (vehicleId) => set.contains(vehicleId);

  group('CatalogReresolveDetector.findCandidates', () {
    test(
        'flags a diesel-marked profile resolved to a petrol catalog '
        'entry', () {
      final profile = VehicleProfile(
        id: 'v1',
        name: 'My Duster',
        make: 'Dacia',
        model: 'Duster',
        year: 2020,
        preferredFuelType: 'diesel',
        referenceVehicleId: dusterPetrolSlug,
      );

      final candidates = CatalogReresolveDetector.findCandidates(
        profiles: [profile],
        catalog: catalog,
        hasFlagFor: flagsBackedBy(<String>{}),
      );

      expect(candidates, hasLength(1));
      expect(candidates.single.vehicleId, 'v1');
      expect(candidates.single.make, 'Dacia');
      expect(candidates.single.model, 'Duster');
      expect(candidates.single.resolvedReferenceVehicleId, dusterPetrolSlug);
      expect(candidates.single.resolvedFuelType, 'petrol');
    });

    test('does NOT flag a diesel profile already pinned to a diesel entry',
        () {
      final profile = VehicleProfile(
        id: 'v1',
        name: 'My Duster dCi',
        make: 'Dacia',
        model: 'Duster',
        year: 2020,
        preferredFuelType: 'diesel',
        referenceVehicleId: dusterDieselSlug,
      );

      final candidates = CatalogReresolveDetector.findCandidates(
        profiles: [profile],
        catalog: catalog,
        hasFlagFor: flagsBackedBy(<String>{}),
      );

      expect(candidates, isEmpty);
    });

    test('skips vehicles whose Hive flag is already set', () {
      final profile = VehicleProfile(
        id: 'v1',
        name: 'My Duster',
        make: 'Dacia',
        model: 'Duster',
        year: 2020,
        preferredFuelType: 'diesel',
        referenceVehicleId: dusterPetrolSlug,
      );

      final candidates = CatalogReresolveDetector.findCandidates(
        profiles: [profile],
        catalog: catalog,
        hasFlagFor: flagsBackedBy({'v1'}),
      );

      expect(candidates, isEmpty);
    });

    test('case-insensitive on diesel keyword', () {
      // "Diesel" / "DIESEL" / "diesel B7" all qualify.
      final profile1 = VehicleProfile(
        id: 'v1',
        name: 'X',
        make: 'Dacia',
        model: 'Duster',
        preferredFuelType: 'Diesel',
        referenceVehicleId: dusterPetrolSlug,
      );
      final profile2 = VehicleProfile(
        id: 'v2',
        name: 'X',
        make: 'Dacia',
        model: 'Duster',
        preferredFuelType: 'DIESEL',
        referenceVehicleId: dusterPetrolSlug,
      );
      final profile3 = VehicleProfile(
        id: 'v3',
        name: 'X',
        make: 'Dacia',
        model: 'Duster',
        preferredFuelType: 'diesel B7',
        referenceVehicleId: dusterPetrolSlug,
      );

      final candidates = CatalogReresolveDetector.findCandidates(
        profiles: [profile1, profile2, profile3],
        catalog: catalog,
        hasFlagFor: flagsBackedBy(<String>{}),
      );

      expect(
        candidates.map((c) => c.vehicleId).toList(),
        ['v1', 'v2', 'v3'],
      );
    });

    test('skips profiles with non-diesel preferredFuelType', () {
      final petrol = VehicleProfile(
        id: 'v1',
        name: 'My 208',
        make: 'Peugeot',
        model: '208',
        preferredFuelType: 'e10',
        referenceVehicleId: peugeot208Slug,
      );
      final unset = VehicleProfile(
        id: 'v2',
        name: 'X',
        make: 'Peugeot',
        model: '208',
        referenceVehicleId: peugeot208Slug,
      );

      final candidates = CatalogReresolveDetector.findCandidates(
        profiles: [petrol, unset],
        catalog: catalog,
        hasFlagFor: flagsBackedBy(<String>{}),
      );

      expect(candidates, isEmpty);
    });

    test('skips profiles without a referenceVehicleId', () {
      const profile = VehicleProfile(
        id: 'v1',
        name: 'X',
        make: 'Dacia',
        model: 'Duster',
        preferredFuelType: 'diesel',
      );

      final candidates = CatalogReresolveDetector.findCandidates(
        profiles: [profile],
        catalog: catalog,
        hasFlagFor: flagsBackedBy(<String>{}),
      );

      expect(candidates, isEmpty);
    });

    test('skips profiles with stale referenceVehicleId not in catalog', () {
      const profile = VehicleProfile(
        id: 'v1',
        name: 'X',
        make: 'Dacia',
        model: 'Duster',
        preferredFuelType: 'diesel',
        referenceVehicleId: 'something-renamed-or-removed',
      );

      final candidates = CatalogReresolveDetector.findCandidates(
        profiles: [profile],
        catalog: catalog,
        hasFlagFor: flagsBackedBy(<String>{}),
      );

      expect(candidates, isEmpty,
          reason: 'Stale slug is a follow-up migrator job, not a #1396 case');
    });

    test('preserves input profile order', () {
      final a = VehicleProfile(
        id: 'a',
        name: 'A',
        make: 'Dacia',
        model: 'Duster',
        preferredFuelType: 'diesel',
        referenceVehicleId: dusterPetrolSlug,
      );
      final b = VehicleProfile(
        id: 'b',
        name: 'B',
        make: 'Dacia',
        model: 'Duster',
        preferredFuelType: 'diesel',
        referenceVehicleId: dusterPetrolSlug,
      );
      final c = VehicleProfile(
        id: 'c',
        name: 'C',
        make: 'Dacia',
        model: 'Duster',
        preferredFuelType: 'diesel',
        referenceVehicleId: dusterPetrolSlug,
      );

      final candidates = CatalogReresolveDetector.findCandidates(
        profiles: [a, b, c],
        catalog: catalog,
        hasFlagFor: flagsBackedBy(<String>{}),
      );

      expect(
        candidates.map((c) => c.vehicleId).toList(),
        ['a', 'b', 'c'],
      );
    });
  });

  group('CatalogReresolveDetector.flagKeyFor', () {
    test('produces a stable, prefix-namespaced key', () {
      expect(
        CatalogReresolveDetector.flagKeyFor('vehicle-42'),
        'vehicle_catalog_reresolve_suggested_vehicle-42',
      );
    });
  });
}
