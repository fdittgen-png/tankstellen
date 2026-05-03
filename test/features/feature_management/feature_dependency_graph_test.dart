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
        Feature.gamification: FeatureManifestEntry(
          feature: Feature.gamification,
          defaultEnabled: false,
          requires: {Feature.hapticEcoCoach},
          displayName: 'gamification',
          description: 'cycle test',
        ),
        Feature.hapticEcoCoach: FeatureManifestEntry(
          feature: Feature.hapticEcoCoach,
          defaultEnabled: false,
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
