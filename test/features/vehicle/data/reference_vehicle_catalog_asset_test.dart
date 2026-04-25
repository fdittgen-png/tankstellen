import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/domain/entities/reference_vehicle.dart';

/// Asset-level smoke test for the reference vehicle catalog (#950 phase 3).
///
/// Distinct from `reference_vehicle_catalog_provider_test.dart`, which
/// drives the riverpod provider end-to-end. This test loads the actual
/// asset directly via [rootBundle] and validates the on-disk JSON the
/// app ships, so a malformed entry fails CI before it can break the
/// provider's startup load in production.
///
/// Acceptance criteria from #950 enforced here:
///   - parses cleanly,
///   - contains >= 30 entries,
///   - every entry round-trips through `ReferenceVehicle.fromJson`,
///   - no duplicate `(make, model, generation)` triples,
///   - every `odometerPidStrategy` is a known enum value.
void main() {
  // Required so rootBundle can resolve declared assets in tests.
  TestWidgetsFlutterBinding.ensureInitialized();

  // Source of truth for the strategy enum lives in the docstring on
  // `ReferenceVehicle.odometerPidStrategy`. Keep this set in sync
  // with that docstring (and with the provider test).
  const knownOdometerStrategies = {
    'stdA6',
    'psaUds',
    'bmwCan',
    'vwUds',
    'unknown',
  };

  group('assets/reference_vehicles/vehicles.json', () {
    test('parses cleanly as a JSON list', () async {
      final raw = await rootBundle
          .loadString('assets/reference_vehicles/vehicles.json');

      final decoded = json.decode(raw);
      expect(
        decoded,
        isA<List<dynamic>>(),
        reason: 'Catalog must be a top-level JSON array',
      );
    });

    test('ships at least 30 entries (acceptance criterion from #950)',
        () async {
      final raw = await rootBundle
          .loadString('assets/reference_vehicles/vehicles.json');
      final entries = json.decode(raw) as List<dynamic>;

      expect(
        entries.length,
        greaterThanOrEqualTo(30),
        reason: 'Catalog should ship the initial >= 30 popular EU cars',
      );
    });

    test('every entry round-trips through ReferenceVehicle.fromJson',
        () async {
      final raw = await rootBundle
          .loadString('assets/reference_vehicles/vehicles.json');
      final entries = json.decode(raw) as List<dynamic>;

      for (var i = 0; i < entries.length; i++) {
        final entry = entries[i];
        expect(
          entry,
          isA<Map<String, dynamic>>(),
          reason: 'Entry $i must be a JSON object',
        );

        // Should not throw — failure here means a required field is
        // missing or has the wrong type.
        final parsed = ReferenceVehicle.fromJson(
          entry as Map<String, dynamic>,
        );

        // Sanity-check that the parsed entity is well-formed. These
        // duplicate the provider test's invariants but at the asset
        // layer so a CI failure points straight at the JSON.
        expect(parsed.make, isNotEmpty,
            reason: 'Entry $i (${parsed.make} ${parsed.model}) needs make');
        expect(parsed.model, isNotEmpty,
            reason: 'Entry $i (${parsed.make} ${parsed.model}) needs model');
        expect(parsed.generation, isNotEmpty,
            reason:
                'Entry $i (${parsed.make} ${parsed.model}) needs generation');
        expect(parsed.yearStart, greaterThan(1900),
            reason:
                'Entry $i (${parsed.make} ${parsed.model}) yearStart out of range');
        expect(parsed.displacementCc, greaterThan(0),
            reason:
                'Entry $i (${parsed.make} ${parsed.model}) displacementCc must be > 0');
        expect(parsed.volumetricEfficiency, greaterThan(0.5));
        expect(parsed.volumetricEfficiency, lessThanOrEqualTo(1.0));
      }
    });

    test('contains no duplicate (make, model, generation) triples',
        () async {
      final raw = await rootBundle
          .loadString('assets/reference_vehicles/vehicles.json');
      final entries = (json.decode(raw) as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(ReferenceVehicle.fromJson)
          .toList();

      final seen = <String>{};
      final duplicates = <String>[];
      for (final v in entries) {
        // Lower-case the key so a "Peugeot" / "peugeot" mistake is
        // also caught.
        final key =
            '${v.make.toLowerCase()}|${v.model.toLowerCase()}|${v.generation.toLowerCase()}';
        if (!seen.add(key)) {
          duplicates.add('${v.make} ${v.model} ${v.generation}');
        }
      }

      expect(
        duplicates,
        isEmpty,
        reason: 'Duplicate catalog entries: $duplicates',
      );
    });

    test('every odometerPidStrategy is a known enum value', () async {
      final raw = await rootBundle
          .loadString('assets/reference_vehicles/vehicles.json');
      final entries = (json.decode(raw) as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(ReferenceVehicle.fromJson)
          .toList();

      for (final v in entries) {
        expect(
          knownOdometerStrategies.contains(v.odometerPidStrategy),
          isTrue,
          reason:
              '${v.make} ${v.model} ${v.generation} has unknown '
              'odometerPidStrategy "${v.odometerPidStrategy}". '
              'Add it to ReferenceVehicle\'s docstring and to this '
              'test\'s allowlist if you intend to support it.',
        );
      }
    });
  });
}
