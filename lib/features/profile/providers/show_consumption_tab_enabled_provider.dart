import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../feature_management/application/feature_flags_provider.dart';
import '../../feature_management/domain/feature.dart';

part 'show_consumption_tab_enabled_provider.g.dart';

/// Visibility gate for the consumption analytics tab in the bottom
/// navigation (#1373 phase 3c).
///
/// Thin shim over [featureFlagsProvider] — the canonical state lives in
/// the central feature-flag set keyed by [Feature.showConsumptionTab].
/// The legacy `UserProfile.showConsumptionTab` field is read once by
/// `legacyToggleMigrationProvider` on first launch after upgrade
/// (gated on a `showConsumptionTabMigratedKey` flag in the settings
/// box) and promoted into the central set; subsequent reads/writes go
/// through here.
///
/// The manifest defaults [Feature.showConsumptionTab] to `true` with
/// `requires: {Feature.obd2TripRecording}`. Because `obd2TripRecording`
/// defaults to `false`, the consumption tab is effectively hidden on
/// fresh installs until the user enables trip recording — matching
/// the original user-facing shape where the legacy field defaulted to
/// `false`.
///
/// Consumers wrap their consumption-tab UI with:
/// ```dart
/// if (!ref.watch(showConsumptionTabEnabledProvider)) {
///   // hide the bottom-nav tab, route entry, etc.
/// }
/// ```
@Riverpod(keepAlive: true)
class ShowConsumptionTabEnabled extends _$ShowConsumptionTabEnabled {
  @override
  bool build() {
    return ref
        .watch(featureFlagsProvider)
        .contains(Feature.showConsumptionTab);
  }

  /// Delegate to [featureFlagsProvider]'s `enable` / `disable`. The
  /// central provider enforces the manifest dependency graph
  /// ([Feature.showConsumptionTab] requires [Feature.obd2TripRecording])
  /// and throws [StateError] when a prerequisite is missing.
  ///
  /// A [StateError] from a dependency-violation is intentionally
  /// swallowed and the toggle stays at its prior state — see the
  /// gamification shim's catch block for the full rationale.
  Future<void> set(bool value) async {
    final notifier = ref.read(featureFlagsProvider.notifier);
    try {
      if (value) {
        await notifier.enable(Feature.showConsumptionTab);
      } else {
        await notifier.disable(Feature.showConsumptionTab);
      }
      // ignore: avoid_catching_errors
    } on StateError {
      // Phase 2 settings UI canEnable / blockingDisable pre-check
      // already guards this setter at the UI layer, so a dependency-
      // violation here is a defensive-only catch — the UI path can't
      // currently reach it. We swallow rather than rethrow so a
      // programmatic caller (e.g. a test or a future call site) sees
      // the toggle stay at its prior state instead of crashing the
      // widget tree.
    }
  }
}
