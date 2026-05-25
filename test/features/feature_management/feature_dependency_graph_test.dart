// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/feature_management/domain/feature_dependency_graph.dart';
import 'package:tankstellen/features/feature_management/domain/feature_manifest.dart';

void main() {
  const manifest = FeatureManifest.defaultManifest;

  group('canEnable', () {
    test('returns false when a prerequisite is disabled', () {
      // gamification requires obd2TripRecording.
      expect(
        canEnable(Feature.gamification, manifest, <Feature>{}),
        isFalse,
      );
    });

    test('returns true when all prerequisites are enabled', () {
      expect(
        canEnable(Feature.gamification, manifest, <Feature>{
          Feature.obd2TripRecording,
        }),
        isTrue,
      );
    });

    test('returns true for a feature with no prerequisites', () {
      expect(canEnable(Feature.tankSync, manifest, <Feature>{}), isTrue);
    });
  });

  group('isEffectivelyEnabled (#1447 cascading-disable)', () {
    test('returns false when the feature itself is not enabled', () {
      // Stored set empty → consumption analytics is not effectively on.
      expect(
        isEffectivelyEnabled(
          Feature.consumptionAnalytics,
          manifest,
          <Feature>{},
        ),
        isFalse,
      );
    });

    test(
        'returns false when the feature is enabled but a direct parent is off',
        () {
      // gamification stored on, but obd2TripRecording (parent) is off.
      // The user's preference is preserved (still in the set) but the
      // surface should not render.
      expect(
        isEffectivelyEnabled(
          Feature.gamification,
          manifest,
          <Feature>{Feature.gamification},
        ),
        isFalse,
        reason:
            'Stored child state with parent off is the cascading-disable '
            'sentinel — user re-enables parent to restore the surface.',
      );
    });

    test('returns true when the feature and every ancestor are enabled', () {
      expect(
        isEffectivelyEnabled(
          Feature.gamification,
          manifest,
          <Feature>{Feature.obd2TripRecording, Feature.gamification},
        ),
        isTrue,
      );
    });

    test('returns true for a root feature with no requires when enabled', () {
      expect(
        isEffectivelyEnabled(
          Feature.tankSync,
          manifest,
          <Feature>{Feature.tankSync},
        ),
        isTrue,
      );
    });

    test(
        'walks transitive ancestors — child is effectively-off when a '
        'grandparent is off', () {
      // Synthetic three-level chain to exercise the walk: g -> p -> r,
      // with the root r missing from the enabled set.
      const chain = FeatureManifest({
        Feature.priceAlerts: FeatureManifestEntry.allChannels(
          feature: Feature.priceAlerts,
          defaultOn: false,
          displayName: 'root',
          description: 'three-level chain root',
        ),
        Feature.priceHistory: FeatureManifestEntry.allChannels(
          feature: Feature.priceHistory,
          defaultOn: false,
          requires: {Feature.priceAlerts},
          displayName: 'parent',
          description: 'three-level chain parent',
        ),
        Feature.gamification: FeatureManifestEntry.allChannels(
          feature: Feature.gamification,
          defaultOn: false,
          requires: {Feature.priceHistory},
          displayName: 'leaf',
          description: 'three-level chain leaf',
        ),
      });

      expect(
        isEffectivelyEnabled(
          Feature.gamification,
          chain,
          <Feature>{Feature.priceHistory, Feature.gamification},
        ),
        isFalse,
        reason: 'Root priceAlerts is off, so the leaf is effectively-off.',
      );
      expect(
        isEffectivelyEnabled(
          Feature.gamification,
          chain,
          <Feature>{
            Feature.priceAlerts,
            Feature.priceHistory,
            Feature.gamification,
          },
        ),
        isTrue,
      );
    });
  });

  group('blockingDisable', () {
    test('returns dependents that would break', () {
      // Disabling obd2TripRecording while gamification + glideCoach are on
      // must surface BOTH dependents.
      final blockers = blockingDisable(
        Feature.obd2TripRecording,
        manifest,
        <Feature>{
          Feature.obd2TripRecording,
          Feature.gamification,
          Feature.glideCoach,
        },
      );
      expect(blockers, containsAll(<Feature>[
        Feature.gamification,
        Feature.glideCoach,
      ]));
    });

    test('returns empty when no enabled feature depends on it', () {
      final blockers = blockingDisable(
        Feature.tankSync,
        manifest,
        <Feature>{Feature.tankSync},
      );
      expect(blockers, isEmpty);
    });

    test('does not list the feature itself', () {
      final blockers = blockingDisable(
        Feature.obd2TripRecording,
        manifest,
        <Feature>{Feature.obd2TripRecording},
      );
      expect(blockers, isNot(contains(Feature.obd2TripRecording)));
    });
  });

  group('assertNoCycles', () {
    test('does not throw on the default manifest', () {
      expect(() => assertNoCycles(manifest), returnsNormally);
    });

    test('throws on a synthetic cycle', () {
      // a -> b -> a — pick two arbitrary Feature values to wire as a
      // direct two-node cycle.
      const cyclic = FeatureManifest({
        Feature.gamification: FeatureManifestEntry.allChannels(
          feature: Feature.gamification,
          defaultOn: false,
          requires: {Feature.hapticEcoCoach},
          displayName: 'gamification',
          description: 'cycle test',
        ),
        Feature.hapticEcoCoach: FeatureManifestEntry.allChannels(
          feature: Feature.hapticEcoCoach,
          defaultOn: false,
          requires: {Feature.gamification},
          displayName: 'hapticEcoCoach',
          description: 'cycle test',
        ),
      });
      expect(
        () => assertNoCycles(cyclic),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Feature dependency cycle'),
        )),
      );
    });
  });
}
