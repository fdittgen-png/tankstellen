// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_announcements_enabled_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Master gate for spoken voice announcements while driving (#2569).
///
/// Thin shim over [featureFlagsProvider], keyed by
/// [Feature.voiceAnnouncements] (default-OFF; `requires`
/// [Feature.approachOverlay], so it is effectively-enabled only when the
/// overlay it piggybacks on is also on). Mirrors
/// [approachOverlayEnabledProvider] / `glideCoachEnabledProvider`.
///
/// The live announcement listener (`voiceAnnouncementListenerProvider`)
/// and the persisted settings notifier both watch this so a stale config
/// can never speak once the feature is disabled — the engine is fed only
/// while the gate is true.

@ProviderFor(voiceAnnouncementsEnabled)
final voiceAnnouncementsEnabledProvider = VoiceAnnouncementsEnabledProvider._();

/// Master gate for spoken voice announcements while driving (#2569).
///
/// Thin shim over [featureFlagsProvider], keyed by
/// [Feature.voiceAnnouncements] (default-OFF; `requires`
/// [Feature.approachOverlay], so it is effectively-enabled only when the
/// overlay it piggybacks on is also on). Mirrors
/// [approachOverlayEnabledProvider] / `glideCoachEnabledProvider`.
///
/// The live announcement listener (`voiceAnnouncementListenerProvider`)
/// and the persisted settings notifier both watch this so a stale config
/// can never speak once the feature is disabled — the engine is fed only
/// while the gate is true.

final class VoiceAnnouncementsEnabledProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Master gate for spoken voice announcements while driving (#2569).
  ///
  /// Thin shim over [featureFlagsProvider], keyed by
  /// [Feature.voiceAnnouncements] (default-OFF; `requires`
  /// [Feature.approachOverlay], so it is effectively-enabled only when the
  /// overlay it piggybacks on is also on). Mirrors
  /// [approachOverlayEnabledProvider] / `glideCoachEnabledProvider`.
  ///
  /// The live announcement listener (`voiceAnnouncementListenerProvider`)
  /// and the persisted settings notifier both watch this so a stale config
  /// can never speak once the feature is disabled — the engine is fed only
  /// while the gate is true.
  VoiceAnnouncementsEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'voiceAnnouncementsEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$voiceAnnouncementsEnabledHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return voiceAnnouncementsEnabled(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$voiceAnnouncementsEnabledHash() =>
    r'b927d7d17bbf64becb7e7b9eda99b9e41160e7fc';
