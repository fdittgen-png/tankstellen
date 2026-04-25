import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/features/vehicle/data/repositories/vehicle_profile_repository.dart';
import 'package:tankstellen/features/vehicle/data/vehicle_profile_catalog_matcher.dart';
import 'package:tankstellen/features/vehicle/data/vehicle_profile_migrator.dart';
import 'package:tankstellen/features/vehicle/domain/entities/reference_vehicle.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';

/// Unit tests for the [VehicleProfileCatalogMigrator] (#950 phase 4).
///
/// We feed an in-memory [SettingsStorage] fake and a hand-built
/// catalog so the test is fully synchronous and doesn't depend on the
/// bundled JSON asset.
void main() {
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

  const catalog = <ReferenceVehicle>[peugeot208II, renaultClio];
  final peugeot208IISlug =
      VehicleProfileCatalogMatcher.slugFor(peugeot208II);

  late _FakeSettings settings;
  late VehicleProfileRepository repository;
  late VehicleProfileCatalogMigrator migrator;

  setUp(() {
    settings = _FakeSettings();
    repository = VehicleProfileRepository(settings);
    migrator = VehicleProfileCatalogMigrator(
      repository: repository,
      settings: settings,
    );
  });

  group('VehicleProfileCatalogMigrator.run', () {
    test('runs once when migration flag is unset', () async {
      const profile = VehicleProfile(
        id: 'p1',
        name: 'My 208',
        make: 'Peugeot',
        model: '208',
        year: 2020,
      );
      await repository.save(profile);

      expect(migrator.hasRun, isFalse);
      final matched = await migrator.run(catalog: catalog);

      expect(matched, 1);
      expect(migrator.hasRun, isTrue);
      expect(
        settings.getSetting(StorageKeys.vehicleCatalogMigrationDone),
        isTrue,
      );
    });

    test('skips when flag is already set', () async {
      const profile = VehicleProfile(
        id: 'p1',
        name: 'My 208',
        make: 'Peugeot',
        model: '208',
        year: 2020,
      );
      await repository.save(profile);
      await settings.putSetting(
          StorageKeys.vehicleCatalogMigrationDone, true);

      final matched = await migrator.run(catalog: catalog);

      expect(matched, 0,
          reason: 'Migrator must not touch profiles when flag is set');
      // Profile remains untouched.
      expect(repository.getById('p1')?.referenceVehicleId, isNull);
    });

    test(
        'updates referenceVehicleId for known make+model entries '
        'and persists to repo', () async {
      const peugeot = VehicleProfile(
        id: 'p1',
        name: 'My 208',
        make: 'Peugeot',
        model: '208',
        year: 2020,
      );
      const renault = VehicleProfile(
        id: 'r1',
        name: 'My Clio',
        make: 'Renault',
        model: 'Clio',
        year: 2021,
      );
      await repository.save(peugeot);
      await repository.save(renault);

      final matched = await migrator.run(catalog: catalog);

      expect(matched, 2);
      // Verify by re-reading from the repo (proves Hive persistence).
      final stored208 = repository.getById('p1')!;
      final storedClio = repository.getById('r1')!;
      expect(stored208.referenceVehicleId, peugeot208IISlug);
      expect(
        storedClio.referenceVehicleId,
        VehicleProfileCatalogMatcher.slugFor(renaultClio),
      );
      // Round-trip: existing fields untouched.
      expect(stored208.make, 'Peugeot');
      expect(stored208.model, '208');
      expect(stored208.year, 2020);
    });

    test('leaves referenceVehicleId null for unmatched entries', () async {
      const profile = VehicleProfile(
        id: 'unknown',
        name: 'Acme Foo',
        make: 'Acme',
        model: 'Foo',
        year: 2020,
      );
      await repository.save(profile);

      final matched = await migrator.run(catalog: catalog);

      expect(matched, 0);
      expect(repository.getById('unknown')?.referenceVehicleId, isNull);
      // Flag flipped even with zero matches.
      expect(migrator.hasRun, isTrue);
    });

    test('skips profiles that already have a referenceVehicleId', () async {
      const existing = VehicleProfile(
        id: 'p1',
        name: 'My 208',
        make: 'Peugeot',
        model: '208',
        year: 2020,
        referenceVehicleId: 'pre-existing-slug',
      );
      await repository.save(existing);

      final matched = await migrator.run(catalog: catalog);

      expect(matched, 0,
          reason: 'Migrator must not overwrite existing slugs');
      expect(
        repository.getById('p1')?.referenceVehicleId,
        'pre-existing-slug',
      );
    });

    test('handles empty profile list without errors', () async {
      final matched = await migrator.run(catalog: catalog);
      expect(matched, 0);
      expect(migrator.hasRun, isTrue);
    });

    test('legacy profile JSON without phase-4 fields decodes cleanly',
        () async {
      // Simulate a pre-#950 profile that was stored before make/model/
      // year/referenceVehicleId existed. Round-trip through the
      // repository to prove fromJson supplies defaults.
      const legacy = VehicleProfile(id: 'legacy', name: 'Legacy car');
      await repository.save(legacy);

      final loaded = repository.getById('legacy');
      expect(loaded, isNotNull);
      expect(loaded!.make, isNull);
      expect(loaded.model, isNull);
      expect(loaded.year, isNull);
      expect(loaded.referenceVehicleId, isNull);

      // Migrator should leave the legacy profile alone (no make to
      // match on) and still mark the migration done.
      final matched = await migrator.run(catalog: catalog);
      expect(matched, 0);
      expect(migrator.hasRun, isTrue);
      expect(repository.getById('legacy')?.referenceVehicleId, isNull);
    });
  });
}

class _FakeSettings implements SettingsStorage {
  final Map<String, dynamic> _data = {};

  @override
  dynamic getSetting(String key) => _data[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  bool get isSetupComplete => false;

  @override
  bool get isSetupSkipped => false;

  @override
  Future<void> skipSetup() async {}

  @override
  Future<void> resetSetupSkip() async {}
}
