// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4227 — the matrix must stay complete and unambiguous, and the
// dependency-safety claim must stay true.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/feature_management/domain/capability_ownership.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/feature_management/domain/feature_manifest.dart';
import 'package:tankstellen/features/feature_management/domain/migration_matrix.dart';
import 'package:tankstellen/features/feature_management/domain/registry_coverage.dart';

void main() {
  group('the matrix covers everything exactly once (#4227)', () {
    test('every Feature and every registry gap has a row', () {
      expect(registeredRows.length, Feature.values.length);
      expect(unregisteredRows.length, RegistryGap.values.length);
      expect(migrationMatrix.length,
          Feature.values.length + RegistryGap.values.length);
    });

    test('no item appears twice — duplicate ownership is what this '
        'issue forbids', () {
      final items = migrationMatrix.map((r) => r.item).toList();
      expect(items.toSet().length, items.length);
    });

    test('every row that enters the process model names a subprocess', () {
      for (final row in migrationMatrix) {
        final staysOutside = row.action == MigrationAction.keepInternal ||
            row.action == MigrationAction.deferToConsentModel;
        expect(row.subprocess == null, staysOutside,
            reason: '${row.item} (${row.action.name}) must name a '
                'subprocess unless it stays outside the model');
        expect(row.process, row.subprocess?.owner);
      }
    });

    test('registered rows agree with capabilityOwner — the matrix is '
        'derived, so it cannot drift', () {
      for (final row in registeredRows) {
        expect(row.subprocess, ownerOf(row.feature!));
      }
    });

    test('the backlog is exactly the promotable gaps', () {
      expect(actionableRows.map((r) => r.gap).toSet(),
          unmappedUserCapabilities.toSet());
      expect(actionableRows, hasLength(2),
          reason: 'two settings are genuine unmapped capabilities: show '
              'charge points on the map, and switch profile '
              'automatically');
    });
  });

  group('dependency safety (#4227)', () {
    const manifest = FeatureManifest.defaultManifest;

    test('the manifest graph is ONE level deep — the migrator depends '
        'on it', () {
      // `legacy_toggle_migrator` promotes a legacy toggle by writing
      // {...current, ...entry.requires, feature}. That spread is only
      // sufficient because no prerequisite has a prerequisite of its
      // own: a two-level chain would leave the grandparent disabled and
      // write exactly the inconsistent state this issue forbids.
      //
      // Measured on master: 33 entries, 11 with `requires`, 0 chains.
      final chains = <String>[];
      for (final entry in manifest.entries.values) {
        for (final parent in entry.requires) {
          final grandparents = manifest.entryFor(parent).requires;
          if (grandparents.isNotEmpty) {
            chains.add('${entry.feature.name} -> ${parent.name} -> '
                '${grandparents.map((g) => g.name).join(",")}');
          }
        }
      }
      expect(chains, isEmpty,
          reason: 'a multi-level requires chain appeared. Either flatten '
              'it, or change legacy_toggle_migrator to spread the '
              'TRANSITIVE closure — its one-level spread would now write '
              'a state with a disabled grandparent.\n${chains.join("\n")}');
    });

    test('every requires target is itself a declared capability', () {
      for (final entry in manifest.entries.values) {
        for (final r in entry.requires) {
          expect(manifest.entries.containsKey(r), isTrue,
              reason: '${entry.feature.name} requires ${r.name}, which '
                  'the manifest does not declare');
        }
      }
    });
  });
}
