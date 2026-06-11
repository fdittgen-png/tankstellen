// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'glide_coach_enabled_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the glide-coach feature is enabled (#1824).
///
/// Migrated off the compile-time `kGlideCoachEnabled` const onto the
/// central feature-flag set keyed by [Feature.glideCoach] — the
/// `FeatureFlags` system (#1373) the old TODO was waiting on.
///
/// The manifest defaults [Feature.glideCoach] off and declares
/// `obd2TripRecording` as a prerequisite, so production behaviour is
/// unchanged (off by default) — but the toggle in the Feature
/// management screen is now the single source of truth instead of a
/// dead switch shadowed by a build-time constant.
///
/// `keepAlive` because consumers (`glideCoachEvaluatorProvider`, the
/// settings notifier, the trip GPS stream controller) span the app
/// lifecycle. Reads route through `isEffectivelyEnabled` for symmetry
/// with the other feature shims (`showFuelEnabledProvider` etc.).

@ProviderFor(glideCoachEnabled)
final glideCoachEnabledProvider = GlideCoachEnabledProvider._();

/// Whether the glide-coach feature is enabled (#1824).
///
/// Migrated off the compile-time `kGlideCoachEnabled` const onto the
/// central feature-flag set keyed by [Feature.glideCoach] — the
/// `FeatureFlags` system (#1373) the old TODO was waiting on.
///
/// The manifest defaults [Feature.glideCoach] off and declares
/// `obd2TripRecording` as a prerequisite, so production behaviour is
/// unchanged (off by default) — but the toggle in the Feature
/// management screen is now the single source of truth instead of a
/// dead switch shadowed by a build-time constant.
///
/// `keepAlive` because consumers (`glideCoachEvaluatorProvider`, the
/// settings notifier, the trip GPS stream controller) span the app
/// lifecycle. Reads route through `isEffectivelyEnabled` for symmetry
/// with the other feature shims (`showFuelEnabledProvider` etc.).

final class GlideCoachEnabledProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the glide-coach feature is enabled (#1824).
  ///
  /// Migrated off the compile-time `kGlideCoachEnabled` const onto the
  /// central feature-flag set keyed by [Feature.glideCoach] — the
  /// `FeatureFlags` system (#1373) the old TODO was waiting on.
  ///
  /// The manifest defaults [Feature.glideCoach] off and declares
  /// `obd2TripRecording` as a prerequisite, so production behaviour is
  /// unchanged (off by default) — but the toggle in the Feature
  /// management screen is now the single source of truth instead of a
  /// dead switch shadowed by a build-time constant.
  ///
  /// `keepAlive` because consumers (`glideCoachEvaluatorProvider`, the
  /// settings notifier, the trip GPS stream controller) span the app
  /// lifecycle. Reads route through `isEffectivelyEnabled` for symmetry
  /// with the other feature shims (`showFuelEnabledProvider` etc.).
  GlideCoachEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'glideCoachEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$glideCoachEnabledHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return glideCoachEnabled(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$glideCoachEnabledHash() => r'dcdd3f68792d41b04d3ed482d266b36e7a780a03';
