import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/domain/entities/reference_vehicle.dart';

/// Verifies the diesel-sibling entries added in #1396.
///
/// Distinct from `reference_vehicle_catalog_asset_test.dart`, which
/// enforces catalog-wide invariants (>=30 entries, no duplicates,
/// known PID strategies). This file asserts the specific diesel rows
/// shipped with the Dacia Duster split are present and have the
/// engineering values used by the OBD-II fuel-rate pipeline:
///
///   * `fuelType: "diesel"`     — drives diesel AFR / density in
///                                 `obd2_service`.
///   * `displacementCc`         — drives speed-density math.
///   * `volumetricEfficiency`   — modern turbo diesels run hotter than
///                                 NA petrol (~0.95 vs ~0.85); the
///                                 reference value lands here.
///
/// If a future refactor renames a generation label the asserts below
/// fail loudly with the offending entry — easier to chase than a
/// silent fuel-economy regression on the user's phone.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<List<ReferenceVehicle>> loadCatalog() async {
    final raw = await rootBundle
        .loadString('assets/reference_vehicles/vehicles.json');
    return (json.decode(raw) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ReferenceVehicle.fromJson)
        .toList();
  }

  ReferenceVehicle? findEntry(
    List<ReferenceVehicle> catalog, {
    required String make,
    required String model,
    required String generation,
  }) {
    for (final entry in catalog) {
      if (entry.make.toLowerCase() == make.toLowerCase() &&
          entry.model.toLowerCase() == model.toLowerCase() &&
          entry.generation == generation) {
        return entry;
      }
    }
    return null;
  }

  group('#1396 diesel-sibling entries', () {
    test('Dacia Duster II dCi 115 entry parses with diesel fuel type',
        () async {
      final catalog = await loadCatalog();
      final entry = findEntry(
        catalog,
        make: 'Dacia',
        model: 'Duster',
        generation: 'II dCi 115 (2017-2024)',
      );
      expect(entry, isNotNull,
          reason: 'Dacia Duster II dCi 115 must ship in catalog');
      expect(entry!.fuelType, 'diesel');
      expect(entry.displacementCc, 1461,
          reason: '1.5 dCi K9K is 1461 cc, not the petrol 1332');
      expect(entry.volumetricEfficiency, closeTo(0.95, 1e-9));
      expect(entry.coversYear(2020), isTrue);
      expect(entry.coversYear(2017), isTrue);
      expect(entry.coversYear(2024), isTrue);
    });

    test('Dacia Sandero II dCi 90 entry parses with diesel fuel type',
        () async {
      final catalog = await loadCatalog();
      final entry = findEntry(
        catalog,
        make: 'Dacia',
        model: 'Sandero',
        generation: 'II dCi 90 (2014-2020)',
      );
      expect(entry, isNotNull);
      expect(entry!.fuelType, 'diesel');
      expect(entry.displacementCc, 1461);
      expect(entry.volumetricEfficiency, closeTo(0.95, 1e-9));
      expect(entry.coversYear(2017), isTrue);
    });

    test('Renault Clio IV dCi 90 entry parses with diesel fuel type',
        () async {
      final catalog = await loadCatalog();
      final entry = findEntry(
        catalog,
        make: 'Renault',
        model: 'Clio',
        generation: 'IV dCi 90 (2012-2019)',
      );
      expect(entry, isNotNull);
      expect(entry!.fuelType, 'diesel');
      expect(entry.displacementCc, 1461);
    });

    test('Renault Captur I dCi 90 entry parses with diesel fuel type',
        () async {
      final catalog = await loadCatalog();
      final entry = findEntry(
        catalog,
        make: 'Renault',
        model: 'Captur',
        generation: 'I dCi 90 (2013-2019)',
      );
      expect(entry, isNotNull);
      expect(entry!.fuelType, 'diesel');
      expect(entry.displacementCc, 1461);
    });

    test('Citroen C3 III BlueHDi 100 entry parses with diesel fuel type',
        () async {
      final catalog = await loadCatalog();
      final entry = findEntry(
        catalog,
        make: 'Citroen',
        model: 'C3',
        generation: 'III BlueHDi 100 (2017-2024)',
      );
      expect(entry, isNotNull);
      expect(entry!.fuelType, 'diesel');
      expect(entry.displacementCc, 1499);
      expect(entry.odometerPidStrategy, 'psaUds');
    });

    test('Peugeot 2008 I BlueHDi 100 entry parses with diesel fuel type',
        () async {
      final catalog = await loadCatalog();
      final entry = findEntry(
        catalog,
        make: 'Peugeot',
        model: '2008',
        generation: 'I BlueHDi 100 (2013-2019)',
      );
      expect(entry, isNotNull);
      expect(entry!.fuelType, 'diesel');
      expect(entry.displacementCc, 1499);
      expect(entry.odometerPidStrategy, 'psaUds');
    });

    test('Volkswagen Polo VI TDI entry parses with diesel fuel type',
        () async {
      final catalog = await loadCatalog();
      final entry = findEntry(
        catalog,
        make: 'Volkswagen',
        model: 'Polo',
        generation: 'VI TDI (2017-)',
      );
      expect(entry, isNotNull);
      expect(entry!.fuelType, 'diesel');
      expect(entry.odometerPidStrategy, 'vwUds');
    });

    test('every #1396 diesel sibling co-exists with its petrol catalog row',
        () async {
      // Verifies the split actually happened: for each new diesel
      // row, the catalog still contains the original petrol entry
      // for the same make/model. A regression here would mean we
      // accidentally rewrote a petrol entry to diesel instead of
      // adding a sibling.
      final catalog = await loadCatalog();
      final pairs = <(String, String)>[
        ('Dacia', 'Duster'),
        ('Dacia', 'Sandero'),
        ('Renault', 'Clio'),
        ('Renault', 'Captur'),
        ('Citroen', 'C3'),
        ('Volkswagen', 'Polo'),
      ];
      for (final (make, model) in pairs) {
        final entries = catalog
            .where((e) =>
                e.make.toLowerCase() == make.toLowerCase() &&
                e.model.toLowerCase() == model.toLowerCase())
            .toList();
        final hasPetrol =
            entries.any((e) => e.fuelType.toLowerCase() == 'petrol');
        final hasDiesel =
            entries.any((e) => e.fuelType.toLowerCase() == 'diesel');
        expect(hasPetrol, isTrue,
            reason:
                '$make $model lost its petrol sibling in the diesel split');
        expect(hasDiesel, isTrue,
            reason:
                '$make $model is missing the new diesel catalog row');
      }
    });
  });
}
