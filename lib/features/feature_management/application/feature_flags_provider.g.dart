// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feature_flags_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Default Hive-backed repository (#1373 phase 1).
///
/// Returns `null` when the [FeatureFlagsRepository.boxName] box has not
/// been opened. Tests that don't initialise Hive get a no-op that falls
/// back to manifest defaults; production opens the box in
/// [HiveBoxes.init].

@ProviderFor(featureFlagsRepository)
final featureFlagsRepositoryProvider = FeatureFlagsRepositoryProvider._();

/// Default Hive-backed repository (#1373 phase 1).
///
/// Returns `null` when the [FeatureFlagsRepository.boxName] box has not
/// been opened. Tests that don't initialise Hive get a no-op that falls
/// back to manifest defaults; production opens the box in
/// [HiveBoxes.init].

final class FeatureFlagsRepositoryProvider
    extends
        $FunctionalProvider<
          FeatureFlagsRepository?,
          FeatureFlagsRepository?,
          FeatureFlagsRepository?
        >
    with $Provider<FeatureFlagsRepository?> {
  /// Default Hive-backed repository (#1373 phase 1).
  ///
  /// Returns `null` when the [FeatureFlagsRepository.boxName] box has not
  /// been opened. Tests that don't initialise Hive get a no-op that falls
  /// back to manifest defaults; production opens the box in
  /// [HiveBoxes.init].
  FeatureFlagsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'featureFlagsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$featureFlagsRepositoryHash();

  @$internal
  @override
  $ProviderElement<FeatureFlagsRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FeatureFlagsRepository? create(Ref ref) {
    return featureFlagsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FeatureFlagsRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FeatureFlagsRepository?>(value),
    );
  }
}

String _$featureFlagsRepositoryHash() =>
    r'd80a2b5ab1391191e896d176fbd40e3adba624a7';

/// Active manifest. Overridable in tests via `ProviderContainer.overrides`
/// to inject a synthetic manifest (e.g. for cycle-rejection coverage).

@ProviderFor(featureManifest)
final featureManifestProvider = FeatureManifestProvider._();

/// Active manifest. Overridable in tests via `ProviderContainer.overrides`
/// to inject a synthetic manifest (e.g. for cycle-rejection coverage).

final class FeatureManifestProvider
    extends
        $FunctionalProvider<FeatureManifest, FeatureManifest, FeatureManifest>
    with $Provider<FeatureManifest> {
  /// Active manifest. Overridable in tests via `ProviderContainer.overrides`
  /// to inject a synthetic manifest (e.g. for cycle-rejection coverage).
  FeatureManifestProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'featureManifestProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$featureManifestHash();

  @$internal
  @override
  $ProviderElement<FeatureManifest> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FeatureManifest create(Ref ref) {
    return featureManifest(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FeatureManifest value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FeatureManifest>(value),
    );
  }
}

String _$featureManifestHash() => r'7b67cbf211fcf268808f6c329950be1d4ba91881';

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

@ProviderFor(FeatureFlags)
final featureFlagsProvider = FeatureFlagsProvider._();

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
final class FeatureFlagsProvider
    extends $NotifierProvider<FeatureFlags, Set<Feature>> {
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
  FeatureFlagsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'featureFlagsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$featureFlagsHash();

  @$internal
  @override
  FeatureFlags create() => FeatureFlags();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<Feature> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<Feature>>(value),
    );
  }
}

String _$featureFlagsHash() => r'686570bb567ddffea95eccad14c7aca01253915c';

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

abstract class _$FeatureFlags extends $Notifier<Set<Feature>> {
  Set<Feature> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<Feature>, Set<Feature>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<Feature>, Set<Feature>>,
              Set<Feature>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
