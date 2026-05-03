import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/feature_flags_repository.dart';
import '../domain/feature.dart';
import '../domain/feature_dependency_graph.dart';
import '../domain/feature_manifest.dart';

part 'feature_flags_provider.g.dart';

/// Default Hive-backed repository (#1373 phase 1).
///
/// Returns `null` when the [FeatureFlagsRepository.boxName] box has not
/// been opened. Tests that don't initialise Hive get a no-op that falls
/// back to manifest defaults; production opens the box in
/// [HiveBoxes.init].
@Riverpod(keepAlive: true)
FeatureFlagsRepository? featureFlagsRepository(Ref ref) {
  if (!Hive.isBoxOpen(FeatureFlagsRepository.boxName)) return null;
  return FeatureFlagsRepository(
    box: Hive.box<dynamic>(FeatureFlagsRepository.boxName),
  );
}

/// Active manifest. Overridable in tests via `ProviderContainer.overrides`
/// to inject a synthetic manifest (e.g. for cycle-rejection coverage).
@Riverpod(keepAlive: true)
FeatureManifest featureManifest(Ref ref) => FeatureManifest.defaultManifest;

/// Central feature-flag store (#1373 phase 1).
///
/// State is the set of currently-enabled features. The provider validates
/// the manifest for cycles on construction, loads the persisted set (or
/// manifest defaults on first launch), and gates [enable] / [disable]
/// transitions on the dependency graph.
///
/// This phase ships the system in PARALLEL with the existing scattered
/// toggles — no consumer is migrated yet. Phase 3 of #1373 will route
/// `autoRecord`, `gamificationEnabled`, `hapticEcoCoachEnabled`, etc.
/// through this provider one feature at a time.
@Riverpod(keepAlive: true)
class FeatureFlags extends _$FeatureFlags {
  @override
  Set<Feature> build() {
    final manifest = ref.watch(featureManifestProvider);
    assertNoCycles(manifest);
    final repo = ref.watch(featureFlagsRepositoryProvider);
    if (repo == null) {
      return manifest.defaultEnabledSet();
    }
    // First-frame state: manifest defaults so synchronous reads have a
    // sensible answer. The async load below replaces it once Hive
    // returns — the persisted set wins on every subsequent read.
    final initial = manifest.defaultEnabledSet();
    repo.loadEnabled().then((persisted) {
      // ignore: invalid_use_of_protected_member
      state = persisted;
    });
    return initial;
  }

  /// Enables [feature], throwing [StateError] when a prerequisite is
  /// disabled. The error message names the missing prerequisites so the
  /// Phase 2 UI can surface a tooltip without a second lookup.
  Future<void> enable(Feature feature) async {
    final manifest = ref.read(featureManifestProvider);
    if (state.contains(feature)) return;
    if (!canEnable(feature, manifest, state)) {
      final entry = manifest.entryFor(feature);
      final missing = entry.requires
          .where((f) => !state.contains(f))
          .map((f) => f.name)
          .join(', ');
      throw StateError(
        'Cannot enable ${feature.name}: requires $missing which is disabled',
      );
    }
    final next = {...state, feature};
    await _persist(next);
    state = next;
  }

  /// Disables [feature], throwing [StateError] when one or more enabled
  /// features depend on it. The error message names the dependents so
  /// the Phase 2 UI can prompt the user to disable them first.
  Future<void> disable(Feature feature) async {
    final manifest = ref.read(featureManifestProvider);
    if (!state.contains(feature)) return;
    final blockers = blockingDisable(feature, manifest, state);
    if (blockers.isNotEmpty) {
      final names = blockers.map((f) => f.name).join(', ');
      throw StateError(
        'Cannot disable ${feature.name}: $names depend on it',
      );
    }
    final next = {...state}..remove(feature);
    await _persist(next);
    state = next;
  }

  /// True when [feature] is currently enabled.
  bool isEnabled(Feature feature) => state.contains(feature);

  Future<void> _persist(Set<Feature> next) async {
    final repo = ref.read(featureFlagsRepositoryProvider);
    if (repo == null) return;
    await repo.saveEnabled(next);
  }
}
