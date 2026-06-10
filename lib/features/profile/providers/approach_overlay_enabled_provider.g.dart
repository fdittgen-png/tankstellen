// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approach_overlay_enabled_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Master gate for the in-trip approach overlay (#2382).
///
/// Thin shim over [featureFlagsProvider], keyed by
/// [Feature.approachOverlay] (default-OFF in the manifest baseline,
/// flipped ON by the `AppProfile.medium` and `AppProfile.full` presets).
///
/// The live approach detector (`approachStateProvider`) watches this so
/// that when the user turns the overlay off, the GPS subscription +
/// periodic search-chain polls never start — even mid-trip. The PiP
/// view also watches it so a stale simulator/detector value can never
/// flip the tile to the price layout once the feature is disabled.

@ProviderFor(approachOverlayEnabled)
final approachOverlayEnabledProvider = ApproachOverlayEnabledProvider._();

/// Master gate for the in-trip approach overlay (#2382).
///
/// Thin shim over [featureFlagsProvider], keyed by
/// [Feature.approachOverlay] (default-OFF in the manifest baseline,
/// flipped ON by the `AppProfile.medium` and `AppProfile.full` presets).
///
/// The live approach detector (`approachStateProvider`) watches this so
/// that when the user turns the overlay off, the GPS subscription +
/// periodic search-chain polls never start — even mid-trip. The PiP
/// view also watches it so a stale simulator/detector value can never
/// flip the tile to the price layout once the feature is disabled.

final class ApproachOverlayEnabledProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Master gate for the in-trip approach overlay (#2382).
  ///
  /// Thin shim over [featureFlagsProvider], keyed by
  /// [Feature.approachOverlay] (default-OFF in the manifest baseline,
  /// flipped ON by the `AppProfile.medium` and `AppProfile.full` presets).
  ///
  /// The live approach detector (`approachStateProvider`) watches this so
  /// that when the user turns the overlay off, the GPS subscription +
  /// periodic search-chain polls never start — even mid-trip. The PiP
  /// view also watches it so a stale simulator/detector value can never
  /// flip the tile to the price layout once the feature is disabled.
  ApproachOverlayEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'approachOverlayEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$approachOverlayEnabledHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return approachOverlayEnabled(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$approachOverlayEnabledHash() =>
    r'e8c3509f55a399ac0f5427cbb0804f7492735952';
