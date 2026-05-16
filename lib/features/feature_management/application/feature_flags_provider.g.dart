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

/// The build channel this app instance is running as (#1674).
///
/// Resolved from the compile-time `--dart-define=CHANNEL`, baked by
/// CI / fastlane. Any value other than `beta` — including an absent
/// define (a local `flutter run`) — resolves to
/// [BuildChannel.production]: production is the safe default so a
/// mis-configured build never accidentally exposes beta-only features.
/// Overridable in tests via `ProviderContainer.overrides`.

@ProviderFor(buildChannel)
final buildChannelProvider = BuildChannelProvider._();

/// The build channel this app instance is running as (#1674).
///
/// Resolved from the compile-time `--dart-define=CHANNEL`, baked by
/// CI / fastlane. Any value other than `beta` — including an absent
/// define (a local `flutter run`) — resolves to
/// [BuildChannel.production]: production is the safe default so a
/// mis-configured build never accidentally exposes beta-only features.
/// Overridable in tests via `ProviderContainer.overrides`.

final class BuildChannelProvider
    extends $FunctionalProvider<BuildChannel, BuildChannel, BuildChannel>
    with $Provider<BuildChannel> {
  /// The build channel this app instance is running as (#1674).
  ///
  /// Resolved from the compile-time `--dart-define=CHANNEL`, baked by
  /// CI / fastlane. Any value other than `beta` — including an absent
  /// define (a local `flutter run`) — resolves to
  /// [BuildChannel.production]: production is the safe default so a
  /// mis-configured build never accidentally exposes beta-only features.
  /// Overridable in tests via `ProviderContainer.overrides`.
  BuildChannelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'buildChannelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$buildChannelHash();

  @$internal
  @override
  $ProviderElement<BuildChannel> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BuildChannel create(Ref ref) {
    return buildChannel(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BuildChannel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BuildChannel>(value),
    );
  }
}

String _$buildChannelHash() => r'19d064de2926f0eb9ef2781dd22f3b5801cbb0b0';

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
///
/// ## AsyncNotifier (#1681)
///
/// `build` is an `async` `FutureOr<Set<Feature>>` so the Hive read is
/// awaited inside it — Riverpod owns the loading frame instead of the
/// old pattern of returning manifest defaults synchronously and then
/// mutating `state` from a `.then()` callback (which needed an
/// `invalid_use_of_protected_member` ignore and swallowed read errors).
/// A failed Hive read is now logged via [errorLogger] and falls back to
/// the manifest defaults rather than failing silently.
///
/// Most consumers want the resolved `Set<Feature>` and have a sensible
/// answer for the brief pre-load frame; they watch [enabledFeaturesProvider]
/// (a synchronous derived view) rather than this provider directly.

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
///
/// ## AsyncNotifier (#1681)
///
/// `build` is an `async` `FutureOr<Set<Feature>>` so the Hive read is
/// awaited inside it — Riverpod owns the loading frame instead of the
/// old pattern of returning manifest defaults synchronously and then
/// mutating `state` from a `.then()` callback (which needed an
/// `invalid_use_of_protected_member` ignore and swallowed read errors).
/// A failed Hive read is now logged via [errorLogger] and falls back to
/// the manifest defaults rather than failing silently.
///
/// Most consumers want the resolved `Set<Feature>` and have a sensible
/// answer for the brief pre-load frame; they watch [enabledFeaturesProvider]
/// (a synchronous derived view) rather than this provider directly.
final class FeatureFlagsProvider
    extends $AsyncNotifierProvider<FeatureFlags, Set<Feature>> {
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
  ///
  /// ## AsyncNotifier (#1681)
  ///
  /// `build` is an `async` `FutureOr<Set<Feature>>` so the Hive read is
  /// awaited inside it — Riverpod owns the loading frame instead of the
  /// old pattern of returning manifest defaults synchronously and then
  /// mutating `state` from a `.then()` callback (which needed an
  /// `invalid_use_of_protected_member` ignore and swallowed read errors).
  /// A failed Hive read is now logged via [errorLogger] and falls back to
  /// the manifest defaults rather than failing silently.
  ///
  /// Most consumers want the resolved `Set<Feature>` and have a sensible
  /// answer for the brief pre-load frame; they watch [enabledFeaturesProvider]
  /// (a synchronous derived view) rather than this provider directly.
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
}

String _$featureFlagsHash() => r'afce31debe12158b3852c03faaf6e39e62781934';

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
///
/// ## AsyncNotifier (#1681)
///
/// `build` is an `async` `FutureOr<Set<Feature>>` so the Hive read is
/// awaited inside it — Riverpod owns the loading frame instead of the
/// old pattern of returning manifest defaults synchronously and then
/// mutating `state` from a `.then()` callback (which needed an
/// `invalid_use_of_protected_member` ignore and swallowed read errors).
/// A failed Hive read is now logged via [errorLogger] and falls back to
/// the manifest defaults rather than failing silently.
///
/// Most consumers want the resolved `Set<Feature>` and have a sensible
/// answer for the brief pre-load frame; they watch [enabledFeaturesProvider]
/// (a synchronous derived view) rather than this provider directly.

abstract class _$FeatureFlags extends $AsyncNotifier<Set<Feature>> {
  FutureOr<Set<Feature>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Set<Feature>>, Set<Feature>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Set<Feature>>, Set<Feature>>,
              AsyncValue<Set<Feature>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Synchronous view of the enabled-feature set (#1681).
///
/// [featureFlagsProvider] is an `AsyncNotifier`, so watching it directly
/// yields an `AsyncValue<Set<Feature>>`. Almost every consumer only
/// needs the resolved `Set<Feature>` and has a sensible answer for the
/// brief pre-Hive-load frame: the manifest defaults. This derived
/// provider encapsulates that — during the load frame (or on an
/// `AsyncError` fallback) it resolves to `defaultEnabledSet()`, matching
/// the pre-#1681 synchronous-`build()` behaviour bit-for-bit.
///
/// Callers that mutate flags still go through
/// `featureFlagsProvider.notifier` (`enable` / `disable` / `isEnabled`).

@ProviderFor(enabledFeatures)
final enabledFeaturesProvider = EnabledFeaturesProvider._();

/// Synchronous view of the enabled-feature set (#1681).
///
/// [featureFlagsProvider] is an `AsyncNotifier`, so watching it directly
/// yields an `AsyncValue<Set<Feature>>`. Almost every consumer only
/// needs the resolved `Set<Feature>` and has a sensible answer for the
/// brief pre-Hive-load frame: the manifest defaults. This derived
/// provider encapsulates that — during the load frame (or on an
/// `AsyncError` fallback) it resolves to `defaultEnabledSet()`, matching
/// the pre-#1681 synchronous-`build()` behaviour bit-for-bit.
///
/// Callers that mutate flags still go through
/// `featureFlagsProvider.notifier` (`enable` / `disable` / `isEnabled`).

final class EnabledFeaturesProvider
    extends $FunctionalProvider<Set<Feature>, Set<Feature>, Set<Feature>>
    with $Provider<Set<Feature>> {
  /// Synchronous view of the enabled-feature set (#1681).
  ///
  /// [featureFlagsProvider] is an `AsyncNotifier`, so watching it directly
  /// yields an `AsyncValue<Set<Feature>>`. Almost every consumer only
  /// needs the resolved `Set<Feature>` and has a sensible answer for the
  /// brief pre-Hive-load frame: the manifest defaults. This derived
  /// provider encapsulates that — during the load frame (or on an
  /// `AsyncError` fallback) it resolves to `defaultEnabledSet()`, matching
  /// the pre-#1681 synchronous-`build()` behaviour bit-for-bit.
  ///
  /// Callers that mutate flags still go through
  /// `featureFlagsProvider.notifier` (`enable` / `disable` / `isEnabled`).
  EnabledFeaturesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'enabledFeaturesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$enabledFeaturesHash();

  @$internal
  @override
  $ProviderElement<Set<Feature>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Set<Feature> create(Ref ref) {
    return enabledFeatures(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<Feature> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<Feature>>(value),
    );
  }
}

String _$enabledFeaturesHash() => r'3e7e23a57bfd783ee094a9291b9a6f081f1515a8';
