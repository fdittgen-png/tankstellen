// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'glide_coach_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Persisted user toggle for the glide-coach feature (#1125 phase 3b).
///
/// Stored as a single boolean in `SharedPreferences` rather than Hive —
/// the value is device-local (not profile-bound), tiny, and read on
/// startup before any feature-bound Hive box is open. The pattern
/// mirrors `themeModeSettingProvider` (#752) — the closest sibling
/// notifier in this repo that backs a single device-local preference
/// onto SharedPreferences via async load + write-through `set`.
///
/// ### Layered gate (master flag + user toggle)
///
/// The feature has TWO independent off-switches that must both be true
/// before any haptic fires:
///
///   1. The central feature flag [Feature.glideCoach], read via
///      [glideCoachEnabledProvider] — default-off in the manifest
///      (#1824 migrated this off the old `kGlideCoachEnabled` const).
///   2. The user-facing toggle, surfaced as
///      [`GlideCoachSettings.enabled`] and persisted by this notifier.
///
/// This notifier respects the feature flag: when [Feature.glideCoach]
/// is disabled, the resulting `enabled` value is forced to `false`
/// even if the persisted user toggle is `true`. The user toggle is
/// layered on top of the feature flag — never below it.
///
/// `setEnabled(true)` will still WRITE to SharedPreferences when the
/// feature is disabled (the value is preserved so a later flag flip
/// does not silently lose the user's historical opt-in), but the
/// in-memory state stays gated.
///
/// `setThrottleThreshold` and `setCooldown` are deliberately
/// out-of-scope for this PR — the only UI surface in phase 3b is the
/// `enabled` toggle. The fields stay on the value type so future
/// phases can grow the notifier without a schema rewrite.

@ProviderFor(GlideCoachSettingsNotifier)
final glideCoachSettingsProvider = GlideCoachSettingsNotifierProvider._();

/// Persisted user toggle for the glide-coach feature (#1125 phase 3b).
///
/// Stored as a single boolean in `SharedPreferences` rather than Hive —
/// the value is device-local (not profile-bound), tiny, and read on
/// startup before any feature-bound Hive box is open. The pattern
/// mirrors `themeModeSettingProvider` (#752) — the closest sibling
/// notifier in this repo that backs a single device-local preference
/// onto SharedPreferences via async load + write-through `set`.
///
/// ### Layered gate (master flag + user toggle)
///
/// The feature has TWO independent off-switches that must both be true
/// before any haptic fires:
///
///   1. The central feature flag [Feature.glideCoach], read via
///      [glideCoachEnabledProvider] — default-off in the manifest
///      (#1824 migrated this off the old `kGlideCoachEnabled` const).
///   2. The user-facing toggle, surfaced as
///      [`GlideCoachSettings.enabled`] and persisted by this notifier.
///
/// This notifier respects the feature flag: when [Feature.glideCoach]
/// is disabled, the resulting `enabled` value is forced to `false`
/// even if the persisted user toggle is `true`. The user toggle is
/// layered on top of the feature flag — never below it.
///
/// `setEnabled(true)` will still WRITE to SharedPreferences when the
/// feature is disabled (the value is preserved so a later flag flip
/// does not silently lose the user's historical opt-in), but the
/// in-memory state stays gated.
///
/// `setThrottleThreshold` and `setCooldown` are deliberately
/// out-of-scope for this PR — the only UI surface in phase 3b is the
/// `enabled` toggle. The fields stay on the value type so future
/// phases can grow the notifier without a schema rewrite.
final class GlideCoachSettingsNotifierProvider
    extends $NotifierProvider<GlideCoachSettingsNotifier, GlideCoachSettings> {
  /// Persisted user toggle for the glide-coach feature (#1125 phase 3b).
  ///
  /// Stored as a single boolean in `SharedPreferences` rather than Hive —
  /// the value is device-local (not profile-bound), tiny, and read on
  /// startup before any feature-bound Hive box is open. The pattern
  /// mirrors `themeModeSettingProvider` (#752) — the closest sibling
  /// notifier in this repo that backs a single device-local preference
  /// onto SharedPreferences via async load + write-through `set`.
  ///
  /// ### Layered gate (master flag + user toggle)
  ///
  /// The feature has TWO independent off-switches that must both be true
  /// before any haptic fires:
  ///
  ///   1. The central feature flag [Feature.glideCoach], read via
  ///      [glideCoachEnabledProvider] — default-off in the manifest
  ///      (#1824 migrated this off the old `kGlideCoachEnabled` const).
  ///   2. The user-facing toggle, surfaced as
  ///      [`GlideCoachSettings.enabled`] and persisted by this notifier.
  ///
  /// This notifier respects the feature flag: when [Feature.glideCoach]
  /// is disabled, the resulting `enabled` value is forced to `false`
  /// even if the persisted user toggle is `true`. The user toggle is
  /// layered on top of the feature flag — never below it.
  ///
  /// `setEnabled(true)` will still WRITE to SharedPreferences when the
  /// feature is disabled (the value is preserved so a later flag flip
  /// does not silently lose the user's historical opt-in), but the
  /// in-memory state stays gated.
  ///
  /// `setThrottleThreshold` and `setCooldown` are deliberately
  /// out-of-scope for this PR — the only UI surface in phase 3b is the
  /// `enabled` toggle. The fields stay on the value type so future
  /// phases can grow the notifier without a schema rewrite.
  GlideCoachSettingsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'glideCoachSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$glideCoachSettingsNotifierHash();

  @$internal
  @override
  GlideCoachSettingsNotifier create() => GlideCoachSettingsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GlideCoachSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GlideCoachSettings>(value),
    );
  }
}

String _$glideCoachSettingsNotifierHash() =>
    r'047aa18bb08487db2c21a3c8e4e589ce862fa20e';

/// Persisted user toggle for the glide-coach feature (#1125 phase 3b).
///
/// Stored as a single boolean in `SharedPreferences` rather than Hive —
/// the value is device-local (not profile-bound), tiny, and read on
/// startup before any feature-bound Hive box is open. The pattern
/// mirrors `themeModeSettingProvider` (#752) — the closest sibling
/// notifier in this repo that backs a single device-local preference
/// onto SharedPreferences via async load + write-through `set`.
///
/// ### Layered gate (master flag + user toggle)
///
/// The feature has TWO independent off-switches that must both be true
/// before any haptic fires:
///
///   1. The central feature flag [Feature.glideCoach], read via
///      [glideCoachEnabledProvider] — default-off in the manifest
///      (#1824 migrated this off the old `kGlideCoachEnabled` const).
///   2. The user-facing toggle, surfaced as
///      [`GlideCoachSettings.enabled`] and persisted by this notifier.
///
/// This notifier respects the feature flag: when [Feature.glideCoach]
/// is disabled, the resulting `enabled` value is forced to `false`
/// even if the persisted user toggle is `true`. The user toggle is
/// layered on top of the feature flag — never below it.
///
/// `setEnabled(true)` will still WRITE to SharedPreferences when the
/// feature is disabled (the value is preserved so a later flag flip
/// does not silently lose the user's historical opt-in), but the
/// in-memory state stays gated.
///
/// `setThrottleThreshold` and `setCooldown` are deliberately
/// out-of-scope for this PR — the only UI surface in phase 3b is the
/// `enabled` toggle. The fields stay on the value type so future
/// phases can grow the notifier without a schema rewrite.

abstract class _$GlideCoachSettingsNotifier
    extends $Notifier<GlideCoachSettings> {
  GlideCoachSettings build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<GlideCoachSettings, GlideCoachSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GlideCoachSettings, GlideCoachSettings>,
              GlideCoachSettings,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
