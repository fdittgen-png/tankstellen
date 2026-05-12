import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart'
    as v1;
import 'package:tankstellen/features/feature_management/domain/feature_manifest.dart';
import 'package:tankstellen/features/feature_management/v2/feature_registry.dart';
import 'package:tankstellen/features/feature_management/v2/known_features.dart';

/// Bridge-layer invariants for the v2 FeatureRegistry.
///
/// Pure functions, no Hive, no Riverpod — these tests guarantee that
/// the bridge keeps the v1 enum's persistence + manifest contract
/// intact while letting the v2 system see every feature.
void main() {
  group('featureRegistry', () {
    test('every v1 Feature enum value has a matching FeatureClass with '
        'identical id', () {
      final registryIds = featureRegistry.map((fc) => fc.id).toSet();
      for (final v in v1.Feature.values) {
        expect(registryIds, contains(v.name),
            reason: 'v1.Feature.${v.name} has no FeatureClass with id '
                '"${v.name}". Either add it to known_features.dart + '
                'feature_registry.dart, or remove the enum value.');
      }
    });

    test('every FeatureClass id is unique', () {
      // Bake the assertion into the test runner so a duplicate id
      // breaks CI loudly rather than silently merging persistence
      // state at runtime.
      expect(assertUniqueIds, returnsNormally);
    });

    test('every FeatureClass `requires` edge points at a registered feature',
        () {
      final registryIds = featureRegistry.map((fc) => fc.id).toSet();
      for (final fc in featureRegistry) {
        for (final req in fc.requires) {
          expect(registryIds, contains(req.id),
              reason: '${fc.id}.requires references ${req.id} which is '
                  'not in featureRegistry. Add it to the list.');
        }
      }
    });

    test('the requires graph has no cycles', () {
      expect(assertNoCycles, returnsNormally);
    });

    test('every FeatureClass `parent` edge points at a registered feature',
        () {
      final registry = featureRegistry.toSet();
      for (final fc in featureRegistry) {
        final p = fc.parent;
        if (p == null) continue;
        expect(registry, contains(p),
            reason: '${fc.id}.parent points at ${p.id} which is not in '
                'featureRegistry.');
      }
    });

    test(
      'defaultEnabled mirrors the v1 manifest for every bridged feature',
      () {
        // The v1 manifest is still the source of truth for the
        // existing 20 features during Phase 1. Drift between v1 and
        // v2 defaults would corrupt first-install state.
        const manifest = FeatureManifest.defaultManifest;
        for (final v in v1.Feature.values) {
          final fc = featureById(v.name);
          expect(fc, isNotNull,
              reason: 'no FeatureClass for v1 ${v.name}');
          final v1Default = manifest.entryFor(v).defaultEnabled;
          expect(fc!.defaultEnabled, v1Default,
              reason: 'defaultEnabled drift on ${v.name}: v1 manifest '
                  'says $v1Default, v2 FeatureClass says '
                  '${fc.defaultEnabled}. They MUST agree during Phase 1.');
        }
      },
    );

    test('featureById lookups round-trip every id', () {
      for (final fc in featureRegistry) {
        expect(featureById(fc.id), same(fc));
      }
    });

    test('featureById returns null for unknown ids', () {
      expect(featureById('not-a-real-feature'), isNull);
    });
  });

  group('FeatureClass equality + hashing', () {
    test('two const FeatureClass instances with the same id are equal', () {
      // Sanity check the `==` override — needed because the cached
      // effective-flags provider relies on stable hashing for
      // Set<FeatureClass> membership tests.
      expect(kFeatureObd2TripRecording, equals(kFeatureObd2TripRecording));
      expect(kFeatureObd2TripRecording.hashCode,
          kFeatureObd2TripRecording.hashCode);
    });
  });
}
