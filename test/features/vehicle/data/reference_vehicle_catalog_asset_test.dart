// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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

    test('ships the expanded best-sellers parc (>= 200 entries, #1640)',
        () async {
      final raw = await rootBundle
          .loadString('assets/reference_vehicles/vehicles.json');
      final entries = json.decode(raw) as List<dynamic>;

      // Epic #1640 scaled the catalog from the original ~30 to the
      // ~250 best-selling European cars of the last 25 years. The
      // floor only ratchets up — never drop below 200.
      expect(
        entries.length,
        greaterThanOrEqualTo(200),
        reason: 'Catalog must ship the >= 200-entry best-sellers parc',
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

    test(
        'every non-EV entry carries a plausible powerKw (kW/L 30–150, '
        'Epic #3015)', () async {
      final raw = await rootBundle
          .loadString('assets/reference_vehicles/vehicles.json');
      final entries = (json.decode(raw) as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(ReferenceVehicle.fromJson)
          .toList();

      var checked = 0;
      for (final v in entries) {
        // The 5 EV / placeholder rows (`displacementCc == 1`) carry no
        // powerKw — electric motor power is out of scope for the
        // combustion power-aware features that consume this field.
        if (v.displacementCc <= 1) {
          expect(
            v.powerKw,
            isNull,
            reason: '${v.make} ${v.model} ${v.generation} is an EV / '
                'placeholder row and must NOT carry powerKw',
          );
          continue;
        }

        expect(
          v.powerKw,
          isNotNull,
          reason: '${v.make} ${v.model} ${v.generation} (non-EV) must '
              'carry a researched powerKw (Epic #3015)',
        );
        expect(
          v.powerKw,
          greaterThan(0),
          reason: '${v.make} ${v.model} ${v.generation} powerKw must be > 0',
        );

        // Specific power (kW per litre) sanity band: a modern petrol /
        // diesel passenger-car engine runs roughly 30–150 kW/L. A value
        // outside this almost certainly means a unit mix-up (PS stored
        // as kW) or a transcription error.
        final kwPerL = v.powerKw! / (v.displacementCc / 1000.0);
        expect(
          kwPerL,
          inInclusiveRange(30.0, 150.0),
          reason: '${v.make} ${v.model} ${v.generation} has implausible '
              'specific power ${kwPerL.toStringAsFixed(1)} kW/L '
              '(${v.powerKw} kW / ${v.displacementCc} cc)',
        );
        checked++;
      }

      // Guard against a future refactor silently skipping every entry.
      expect(
        checked,
        greaterThanOrEqualTo(300),
        reason: 'Expected the bulk of the catalog to be non-EV with powerKw',
      );
    });

    test(
        'idx 28 (Fiat Panda 0.9 TwinAir) is turbocharged (Epic #3015 '
        'data-quality fix)', () async {
      final raw = await rootBundle
          .loadString('assets/reference_vehicles/vehicles.json');
      final entries = json.decode(raw) as List<dynamic>;
      final panda = ReferenceVehicle.fromJson(
        entries[28] as Map<String, dynamic>,
      );
      expect(panda.make, 'Fiat');
      expect(panda.model, 'Panda');
      expect(
        panda.inductionType,
        InductionType.turbocharged,
        reason: 'The 0.9 TwinAir is a turbocharged twin-cylinder',
      );
      expect(panda.powerKw, 63);
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
