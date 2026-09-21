// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// #4227 — the matrix must stay complete and unambiguous, and the
// dependency-safety claim must stay true.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/feature_management/domain/capability_ownership.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/feature_management/domain/feature_dependency_graph.dart';
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

    test('promoting any feature with its TRANSITIVE closure writes a '
        'consistent state', () {
      // `legacy_toggle_migrator` promotes a legacy toggle by writing
      // {...current, ...requiredClosure(feature, manifest), feature}.
      // It used to spread `entry.requires` alone, which was sufficient
      // only while the graph was one level deep; #4212's fleet chain
      // (fleetManagerTools -> fleetMode -> tankSync) ended that, and a
      // one-level spread would now persist a dependent whose
      // GRANDparent is disabled — exactly the inconsistent state this
      // issue forbids. The closure is what makes the promotion safe at
      // any depth, so that is what is pinned here.
      final broken = <String>[];
      for (final feature in Feature.values) {
        final promoted = <Feature>{
          ...requiredClosure(feature, manifest),
          feature,
        };
        for (final enabled in promoted) {
          if (!canEnable(enabled, manifest, promoted)) {
            broken.add('${feature.name}: ${enabled.name} unsatisfied in '
                '{${promoted.map((f) => f.name).join(",")}}');
          }
        }
      }
      expect(broken, isEmpty,
          reason: 'requiredClosure must return EVERY transitive '
              'prerequisite — the migrator writes that set verbatim.\n'
              '${broken.join("\n")}');
    });

    test('#4212 — the fleet chain is genuinely two levels deep, so the '
        'closure is not vacuous', () {
      expect(manifest.entryFor(Feature.fleetManagerTools).requires,
          {Feature.fleetMode});
      expect(manifest.entryFor(Feature.fleetMode).requires,
          {Feature.tankSync});
      expect(requiredClosure(Feature.fleetManagerTools, manifest),
          {Feature.fleetMode, Feature.tankSync});
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
