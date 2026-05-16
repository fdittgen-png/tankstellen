import 'dart:async';

import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/error_logger.dart';
import '../data/feature_flags_repository.dart';
import '../domain/build_channel.dart';
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

/// The build channel this app instance is running as (#1674).
///
/// Resolved from the compile-time `--dart-define=CHANNEL`, baked by
/// CI / fastlane. Any value other than `beta` — including an absent
/// define (a local `flutter run`) — resolves to
/// [BuildChannel.production]: production is the safe default so a
/// mis-configured build never accidentally exposes beta-only features.
/// Overridable in tests via `ProviderContainer.overrides`.
@Riverpod(keepAlive: true)
BuildChannel buildChannel(Ref ref) {
  const raw = String.fromEnvironment('CHANNEL');
  return raw == 'beta' ? BuildChannel.beta : BuildChannel.production;
}

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
@Riverpod(keepAlive: true)
class FeatureFlags extends _$FeatureFlags {
  @override
  FutureOr<Set<Feature>> build() async {
    final manifest = ref.watch(featureManifestProvider);
    assertNoCycles(manifest);
    final channel = ref.watch(buildChannelProvider);
    final repo = ref.watch(featureFlagsRepositoryProvider);
    if (repo == null) {
      return manifest.defaultEnabledSet(channel);
    }
    try {
      // First launch resolves to the channel's opt-in/opt-out defaults;
      // a populated box returns its persisted set (#1674).
      final loaded = await repo.loadEnabled(channel);
      // #1674 — force-off any persisted feature that is not available
      // in this build channel (e.g. a beta-only feature in a
      // production build).
      return _availableInChannel(loaded, manifest, channel);
    } catch (e, st) {
      // #1681 — a Hive read failure must not be silent. Log it through
      // the central pipeline, then fall back to manifest defaults so
      // the app stays usable rather than stuck on an error state.
      await errorLogger.log(
        ErrorLayer.storage,
        e,
        st,
        context: {'op': 'FeatureFlags.loadEnabled'},
      );
      return manifest.defaultEnabledSet(channel);
    }
  }

  /// Drops every feature not available in [channel] — the channel gate
  /// applied to a persisted set (#1674).
  static Set<Feature> _availableInChannel(
    Set<Feature> features,
    FeatureManifest manifest,
    BuildChannel channel,
  ) =>
      features
          .where((f) => manifest.entries[f]?.isAvailableIn(channel) ?? false)
          .toSet();

  /// Enables [feature], throwing [StateError] when a prerequisite is
  /// disabled. The error message names the missing prerequisites so the
  /// Phase 2 UI can surface a tooltip without a second lookup.
  Future<void> enable(Feature feature) async {
    final manifest = ref.read(featureManifestProvider);
    final channel = ref.read(buildChannelProvider);
    // Await the in-flight (or resolved) build so a flip during the
    // initial Hive load operates on the persisted set, not stale state.
    final current = await future;
    if (current.contains(feature)) return;
    // #1674 — a feature not available in this build channel can never
    // be enabled, regardless of its prerequisites.
    if (!manifest.entryFor(feature).isAvailableIn(channel)) {
      throw StateError(
        'Cannot enable ${feature.name}: not available in the '
        '${channel.name} build channel',
      );
    }
    if (!canEnable(feature, manifest, current)) {
      final entry = manifest.entryFor(feature);
      final missing = entry.requires
          .where((f) => !current.contains(f))
          .map((f) => f.name)
          .join(', ');
      throw StateError(
        'Cannot enable ${feature.name}: requires $missing which is disabled',
      );
    }
    final next = {...current, feature};
    await _persist(next);
    state = AsyncData(next);
  }

  /// Disables [feature]. Always succeeds — children that `requires` this
  /// feature stay in the stored set (their preferences are preserved) but
  /// become **effectively** disabled via [isEffectivelyEnabled], so every
  /// UI surface that gates on the helper hides them without prompting the
  /// user (#1447).
  ///
  /// Re-enabling [feature] later restores those children to their previous
  /// user-visible state, no manual re-toggling required.
  Future<void> disable(Feature feature) async {
    final current = await future;
    if (!current.contains(feature)) return;
    final next = {...current}..remove(feature);
    await _persist(next);
    state = AsyncData(next);
  }

  /// Replaces the entire enabled set with [bundle] — used to apply a
  /// preset profile bundle atomically (#1517 / #1765).
  ///
  /// Unlike [enable], this does NOT run the per-feature prerequisite
  /// guard: a preset bundle is a complete, intentional set, and a
  /// preset deliberately includes dependents (e.g. `showConsumptionTab`
  /// in the Medium bundle) whose manifest `requires` edge is satisfied
  /// at the reachability layer, not the dependency graph. Routing a
  /// bundle through [enable] crashed the moment a dependent's
  /// prerequisite was absent from the bundle (#1765).
  ///
  /// Channel-unavailable features are dropped (#1674); the result is
  /// exactly [bundle] minus those, so no stale-on flags survive a
  /// profile switch.
  Future<void> applyBundle(Set<Feature> bundle) async {
    final manifest = ref.read(featureManifestProvider);
    final channel = ref.read(buildChannelProvider);
    // Await the in-flight build so the apply replaces the resolved set.
    await future;
    final next = _availableInChannel(bundle, manifest, channel);
    await _persist(next);
    state = AsyncData(next);
  }

  /// True when [feature] is currently in the stored enabled set. Does NOT
  /// walk the dependency chain — when the manifest declares prerequisites
  /// for [feature] and the caller wants the user-visible "is this surface
  /// reachable right now" answer, use the pure helper
  /// `isEffectivelyEnabled` from `feature_dependency_graph.dart` (#1447).
  ///
  /// Returns `false` while the initial Hive load is still in flight —
  /// the same answer a not-yet-enabled feature gives, so a caller racing
  /// the first frame degrades safely.
  bool isEnabled(Feature feature) =>
      state.asData?.value.contains(feature) ?? false;

  Future<void> _persist(Set<Feature> next) async {
    final repo = ref.read(featureFlagsRepositoryProvider);
    if (repo == null) return;
    await repo.saveEnabled(next);
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
@Riverpod(keepAlive: true)
Set<Feature> enabledFeatures(Ref ref) {
  return ref.watch(featureFlagsProvider).asData?.value ??
      ref
          .watch(featureManifestProvider)
          .defaultEnabledSet(ref.watch(buildChannelProvider));
}
