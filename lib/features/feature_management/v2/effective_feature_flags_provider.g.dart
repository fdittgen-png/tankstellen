// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'effective_feature_flags_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(effectiveFeatureFlags)
final effectiveFeatureFlagsProvider = EffectiveFeatureFlagsProvider._();

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

final class EffectiveFeatureFlagsProvider
    extends
        $FunctionalProvider<
          Map<String, bool>,
          Map<String, bool>,
          Map<String, bool>
        >
    with $Provider<Map<String, bool>> {
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
  EffectiveFeatureFlagsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'effectiveFeatureFlagsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$effectiveFeatureFlagsHash();

  @$internal
  @override
  $ProviderElement<Map<String, bool>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, bool> create(Ref ref) {
    return effectiveFeatureFlags(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, bool> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, bool>>(value),
    );
  }
}

String _$effectiveFeatureFlagsHash() =>
    r'06cb2e03fb733b44dea3b5d0ecabf8c8bf73b285';
