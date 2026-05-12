import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../application/feature_flags_provider.dart';
import '../domain/feature.dart' as v1;
import 'feature_class.dart';
import 'feature_registry.dart';

part 'effective_feature_flags_provider.g.dart';

/// Map from `FeatureClass.id` → `isEffectivelyEnabled` boolean.
///
/// Computed once whenever the underlying [featureFlagsProvider] flag
/// set changes (i.e. only when the user toggles in Settings — rare).
/// Widgets read individual flags via `select((m) => m[id])` so they
/// rebuild only when *their* flag flips, not on unrelated toggles.
///
/// This is the cache that solves the "must not impact performance"
/// requirement: per-widget reads are a single map lookup, not a
/// requires-DAG walk.
///
/// Bridges to the v1 system: the input flag set is `Set<v1.Feature>`,
/// and we translate via `Feature.x.name == FeatureClass.id`. Phase 2
/// migrations don't break this bridge — as long as the IDs match the
/// enum names, both APIs read the same persistence record.
@Riverpod(keepAlive: true)
Map<String, bool> effectiveFeatureFlags(Ref ref) {
  final v1Enabled = ref.watch(featureFlagsProvider);
  final enabledIds = v1Enabled.map((f) => f.name).toSet();
  return {
    for (final fc in featureRegistry)
      fc.id: _isEffectivelyEnabledV2(fc, enabledIds),
  };
}

/// True when `feature` is in [enabledIds] AND every feature reachable
/// via `requires` from it is also in [enabledIds]. Pure function so
/// it can be reused outside the provider (tests, future migrations).
///
/// Acyclic per `assertNoCycles()` — visited tracking is belt-and-
/// braces in case a future const slips a cycle in.
bool _isEffectivelyEnabledV2(
  FeatureClass feature,
  Set<String> enabledIds,
) {
  if (!enabledIds.contains(feature.id)) return false;
  final visited = <FeatureClass>{feature};
  bool walk(FeatureClass node) {
    for (final req in node.requires) {
      if (!enabledIds.contains(req.id)) return false;
      if (visited.add(req) && !walk(req)) return false;
    }
    return true;
  }

  return walk(feature);
}

/// Test-friendly export of the v2 effective-enabled walk. Used by
/// unit tests; production code should `ref.watch` the provider
/// instead so it benefits from the cache.
bool isEffectivelyEnabledV2({
  required FeatureClass feature,
  required Set<String> enabledIds,
}) =>
    _isEffectivelyEnabledV2(feature, enabledIds);

/// Convenience: same shape as the v1 enum-keyed helper. Maps a v1
/// [v1.Feature] to its v2 FeatureClass and asks the cached provider.
/// Lets call sites migrate the data type at their own pace without
/// rewriting the lookup pattern.
extension EffectiveFeatureFlagsCompat on Map<String, bool> {
  /// Returns the effective-enabled state for a v1 enum feature.
  /// Falls back to `false` for ids the registry doesn't know about
  /// (i.e. v1 enum values that were never given a v2 FeatureClass).
  bool isOn(v1.Feature legacy) => this[legacy.name] ?? false;

  /// Returns the effective-enabled state for a v2 FeatureClass.
  bool isOnV2(FeatureClass fc) => this[fc.id] ?? false;
}
