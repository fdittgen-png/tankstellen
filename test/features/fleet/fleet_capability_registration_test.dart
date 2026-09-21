// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// #4212 — the two fleet capabilities enter through the existing
// registry, not through a parallel one. What is pinned here is the part
// a later slice could quietly get wrong: the prerequisite edges, the
// beta-only availability (a capability the app cannot yet deliver must
// not be offerable in production), and the fact that `canEnable`
// enforces both edges rather than only the nearest one.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/feature_management/domain/build_channel.dart';
import 'package:tankstellen/features/feature_management/domain/capability_ownership.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/feature_management/domain/feature_category.dart';
import 'package:tankstellen/features/feature_management/domain/feature_dependency_graph.dart';
import 'package:tankstellen/features/feature_management/domain/feature_manifest.dart';
import 'package:tankstellen/features/feature_management/domain/process_taxonomy.dart';

void main() {
  const manifest = FeatureManifest.defaultManifest;

  group('registration', () {
    test('both capabilities are declared, default-off, and BETA-ONLY '
        'until the manager dashboard ships', () {
      for (final f in [Feature.fleetMode, Feature.fleetManagerTools]) {
        final entry = manifest.entryFor(f);
        expect(entry.isAvailableIn(BuildChannel.production), isFalse,
            reason: '$f must not be offerable in production before the '
                'manager dashboard and the single privacy-policy bump '
                '(ADR 0025 D6)');
        expect(entry.isAvailableIn(BuildChannel.beta), isTrue);
        expect(entry.defaultEnabledIn(BuildChannel.beta), isFalse,
            reason: 'opt-in even in beta');
        expect(entry.displayName.trim(), isNotEmpty);
        expect(entry.description.trim(), isNotEmpty);
      }
    });

    test('neither is in the production default-enabled set', () {
      final production = manifest.defaultEnabledSet(BuildChannel.production);
      expect(production, isNot(contains(Feature.fleetMode)));
      expect(production, isNot(contains(Feature.fleetManagerTools)));
    });

    test('the enum append is at the END — reordering would rewrite the '
        'Hive persistence keys of every other flag', () {
      expect(Feature.values.last, Feature.fleetManagerTools);
      expect(Feature.values[Feature.values.length - 2], Feature.fleetMode);
    });

    test('they render under their own Fleet section, just before '
        'Developer', () {
      expect(categoryOf(Feature.fleetMode), FeatureCategory.fleet);
      expect(categoryOf(Feature.fleetManagerTools), FeatureCategory.fleet);
      expect(categoryOrder.indexOf(FeatureCategory.fleet),
          categoryOrder.indexOf(FeatureCategory.developer) - 1);
    });

    test('process ownership uses the reserved slots', () {
      expect(ownerOf(Feature.fleetMode),
          SparkiloSubprocess.switchCurrentVehicle);
      expect(ownerOf(Feature.fleetManagerTools),
          SparkiloSubprocess.monitorAggregateCosts);
      expect(processOf(Feature.fleetManagerTools),
          SparkiloProcess.manageFleet);
    });
  });

  group('the requires edges are enforced by the existing canEnable', () {
    test('fleet mode needs TankSync — a fleet with no backend is a '
        'contradiction (ADR 0025 D3)', () {
      expect(manifest.entryFor(Feature.fleetMode).requires,
          {Feature.tankSync});
      expect(canEnable(Feature.fleetMode, manifest, const {}), isFalse);
      expect(canEnable(Feature.fleetMode, manifest, {Feature.tankSync}),
          isTrue);
    });

    test('manager tools need fleet mode, and fleet mode alone is not '
        'enough — the grandparent must be on too', () {
      expect(manifest.entryFor(Feature.fleetManagerTools).requires,
          {Feature.fleetMode});
      expect(
          canEnable(Feature.fleetManagerTools, manifest, {Feature.fleetMode}),
          isTrue,
          reason: 'canEnable checks the direct edge…');
      expect(
        isEffectivelyEnabled(Feature.fleetManagerTools, manifest,
            {Feature.fleetManagerTools, Feature.fleetMode}),
        isFalse,
        reason: '…and the effective gate walks the whole chain, so '
            'manager tools stay off while TankSync is off',
      );
      expect(
        isEffectivelyEnabled(Feature.fleetManagerTools, manifest, {
          Feature.fleetManagerTools,
          Feature.fleetMode,
          Feature.tankSync,
        }),
        isTrue,
      );
    });

    test('turning TankSync off takes the whole fleet chain with it', () {
      const enabled = {Feature.fleetManagerTools, Feature.fleetMode};
      expect(isEffectivelyEnabled(Feature.fleetMode, manifest, enabled),
          isFalse);
      expect(blockingDisable(Feature.fleetMode, manifest, enabled),
          {Feature.fleetManagerTools});
    });

    test('the manifest stays acyclic with the new chain', () {
      expect(() => assertNoCycles(manifest), returnsNormally);
    });
  });
}
