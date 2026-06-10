// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/feature.dart';
import '../domain/feature_dependency_graph.dart';
import 'feature_flags_provider.dart';

/// Effective enabled-state of [feature], reactive on the central
/// feature-flag set (#3175).
///
/// THE single shared `build` body behind every per-feature toggle shim
/// (`gamificationEnabledProvider`, `showFuelEnabledProvider`,
/// `glideCoachEnabledProvider`, …). Gates on the **effective** state
/// (#1447): if any ancestor on the manifest's `requires` chain is
/// disabled, this surfaces as `false` regardless of the stored value —
/// the user's own preference is preserved, so re-enabling the parent
/// restores it. For a feature with no prerequisites the helper
/// short-circuits to a plain `contains` check.
bool watchEffectiveFeature(Ref ref, Feature feature) {
  final enabled = ref.watch(enabledFeaturesProvider);
  final manifest = ref.watch(featureManifestProvider);
  return isEffectivelyEnabled(feature, manifest, enabled);
}

/// Shared implementation for the per-feature toggle notifiers (#3175).
///
/// Nine near-identical ~80-line shims (the profile show-toggles,
/// gamification, baseline-sync, haptic-eco-coach, …) carried copies of
/// the same `build` + `set` logic; this mixin is now the single home
/// for both. Each shim keeps its public provider name (so no call site,
/// override, or fake changes) and shrinks to a `feature` getter plus a
/// one-line `build`.
///
/// ## Setter semantics — dependency violations are swallowed
///
/// [featureFlagsProvider]'s `enable` / `disable` throw [StateError] when
/// a prerequisite is missing or a dependent blocks disabling. The shims
/// historically disagreed on what to do with it: most swallowed it
/// (gamification, baseline-sync, the show-toggles), while the
/// haptic-eco-coach shim let it surface (#1608). Unified here on the
/// **swallow** variant as the safest: every settings UI already
/// pre-checks `canEnable` / `blockingDisable` before invoking the
/// setter, so a violation can only be reached programmatically — and a
/// programmatic caller (a test, a future call site) then sees the toggle
/// stay at its prior state instead of an uncaught Error crashing the
/// widget tree. The central provider throws *before* mutating, so the
/// flag set is never left half-applied.
mixin FeatureToggleNotifier {
  /// Provided by the generated notifier base class.
  Ref get ref;

  /// The manifest key this toggle reads and writes.
  Feature get feature;

  /// Shared `build` body — see [watchEffectiveFeature].
  bool buildFromFeatureFlags() => watchEffectiveFeature(ref, feature);

  /// Delegate to [featureFlagsProvider]'s `enable` / `disable`, which
  /// enforce the manifest dependency graph.
  ///
  /// A [StateError] from a dependency violation is intentionally
  /// swallowed and the toggle stays at its prior state — see the mixin
  /// doc for the full rationale.
  Future<void> set(bool value) async {
    final notifier = ref.read(featureFlagsProvider.notifier);
    try {
      if (value) {
        await notifier.enable(feature);
      } else {
        await notifier.disable(feature);
      }
      // The central provider throws a StateError specifically for
      // dependency-violation; we want to swallow ONLY that. The lint
      // deliberately discourages catching Error subclasses, but the
      // central API's contract documents this exact StateError as the
      // dependency-violation signal, so the catch is intentional and
      // narrow.
      // ignore: avoid_catching_errors
    } on StateError {
      // Dependency violation — the settings UI's canEnable /
      // blockingDisable pre-check guards this setter, so this branch is
      // a defensive backstop for programmatic callers. Swallowing keeps
      // the toggle at its prior state instead of crashing the caller.
    }
  }
}
