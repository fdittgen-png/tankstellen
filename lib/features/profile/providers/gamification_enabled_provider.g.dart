// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gamification_enabled_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Master gate for gamification surfaces (#1194).
///
/// Reads the [UserProfile.gamificationEnabled] flag from the active
/// profile. Returns `true` when no profile is loaded yet so the very
/// first frame on a cold launch keeps the existing behaviour — the
/// underlying flag itself defaults to `true` for both freshly-created
/// and migrated profiles, so this fall-back only applies before the
/// active profile is resolved.
///
/// Consumers wrap their gamification UI with:
/// ```dart
/// if (!ref.watch(gamificationEnabledProvider)) {
///   return const SizedBox.shrink();
/// }
/// ```
///
/// The achievement-engine itself is intentionally NOT gated — it keeps
/// running so that toggling back on instantly restores any badges
/// earned during the opt-out window.

@ProviderFor(gamificationEnabled)
final gamificationEnabledProvider = GamificationEnabledProvider._();

/// Master gate for gamification surfaces (#1194).
///
/// Reads the [UserProfile.gamificationEnabled] flag from the active
/// profile. Returns `true` when no profile is loaded yet so the very
/// first frame on a cold launch keeps the existing behaviour — the
/// underlying flag itself defaults to `true` for both freshly-created
/// and migrated profiles, so this fall-back only applies before the
/// active profile is resolved.
///
/// Consumers wrap their gamification UI with:
/// ```dart
/// if (!ref.watch(gamificationEnabledProvider)) {
///   return const SizedBox.shrink();
/// }
/// ```
///
/// The achievement-engine itself is intentionally NOT gated — it keeps
/// running so that toggling back on instantly restores any badges
/// earned during the opt-out window.

final class GamificationEnabledProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Master gate for gamification surfaces (#1194).
  ///
  /// Reads the [UserProfile.gamificationEnabled] flag from the active
  /// profile. Returns `true` when no profile is loaded yet so the very
  /// first frame on a cold launch keeps the existing behaviour — the
  /// underlying flag itself defaults to `true` for both freshly-created
  /// and migrated profiles, so this fall-back only applies before the
  /// active profile is resolved.
  ///
  /// Consumers wrap their gamification UI with:
  /// ```dart
  /// if (!ref.watch(gamificationEnabledProvider)) {
  ///   return const SizedBox.shrink();
  /// }
  /// ```
  ///
  /// The achievement-engine itself is intentionally NOT gated — it keeps
  /// running so that toggling back on instantly restores any badges
  /// earned during the opt-out window.
  GamificationEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gamificationEnabledProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gamificationEnabledHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return gamificationEnabled(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$gamificationEnabledHash() =>
    r'e530fcd44461d673e10b3326825cbcaf94d0f3b4';
