// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_announcement_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Persisted user settings for voice announcements while driving (#2569).
///
/// Backs the four tunables the dormant [AnnouncementEngine] already reads
/// — enable, price threshold, proximity radius, repeat cooldown — onto
/// `SharedPreferences`. The shape mirrors `GlideCoachSettingsNotifier`
/// (#1125 phase 3b): a device-local preference (not profile-bound), read
/// on startup, write-through on every setter. The value type IS the
/// engine's own [AnnouncementConfig] so the live call site
/// (`voiceAnnouncementListenerProvider`) can hand it to the engine
/// without an adapter layer.
///
/// ### Layered gate (master flag + user toggle)
///
/// Two independent off-switches must both be true before a word is
/// spoken:
///
///   1. The central [Feature.voiceAnnouncements] flag, read via
///      [voiceAnnouncementsEnabledProvider] (default-off; requires the
///      approach overlay). When the flag is off, the resolved config's
///      `enabled` is forced `false` even if the persisted toggle is
///      `true` — exactly the glide-coach contract.
///   2. The user-facing `enabled` toggle persisted here.
///
/// `setEnabled(true)` still WRITES `true` so a later flag flip restores
/// the user's historical opt-in, but the in-memory `enabled` stays gated.

@ProviderFor(VoiceAnnouncementSettings)
final voiceAnnouncementSettingsProvider = VoiceAnnouncementSettingsProvider._();

/// Persisted user settings for voice announcements while driving (#2569).
///
/// Backs the four tunables the dormant [AnnouncementEngine] already reads
/// — enable, price threshold, proximity radius, repeat cooldown — onto
/// `SharedPreferences`. The shape mirrors `GlideCoachSettingsNotifier`
/// (#1125 phase 3b): a device-local preference (not profile-bound), read
/// on startup, write-through on every setter. The value type IS the
/// engine's own [AnnouncementConfig] so the live call site
/// (`voiceAnnouncementListenerProvider`) can hand it to the engine
/// without an adapter layer.
///
/// ### Layered gate (master flag + user toggle)
///
/// Two independent off-switches must both be true before a word is
/// spoken:
///
///   1. The central [Feature.voiceAnnouncements] flag, read via
///      [voiceAnnouncementsEnabledProvider] (default-off; requires the
///      approach overlay). When the flag is off, the resolved config's
///      `enabled` is forced `false` even if the persisted toggle is
///      `true` — exactly the glide-coach contract.
///   2. The user-facing `enabled` toggle persisted here.
///
/// `setEnabled(true)` still WRITES `true` so a later flag flip restores
/// the user's historical opt-in, but the in-memory `enabled` stays gated.
final class VoiceAnnouncementSettingsProvider
    extends $NotifierProvider<VoiceAnnouncementSettings, AnnouncementConfig> {
  /// Persisted user settings for voice announcements while driving (#2569).
  ///
  /// Backs the four tunables the dormant [AnnouncementEngine] already reads
  /// — enable, price threshold, proximity radius, repeat cooldown — onto
  /// `SharedPreferences`. The shape mirrors `GlideCoachSettingsNotifier`
  /// (#1125 phase 3b): a device-local preference (not profile-bound), read
  /// on startup, write-through on every setter. The value type IS the
  /// engine's own [AnnouncementConfig] so the live call site
  /// (`voiceAnnouncementListenerProvider`) can hand it to the engine
  /// without an adapter layer.
  ///
  /// ### Layered gate (master flag + user toggle)
  ///
  /// Two independent off-switches must both be true before a word is
  /// spoken:
  ///
  ///   1. The central [Feature.voiceAnnouncements] flag, read via
  ///      [voiceAnnouncementsEnabledProvider] (default-off; requires the
  ///      approach overlay). When the flag is off, the resolved config's
  ///      `enabled` is forced `false` even if the persisted toggle is
  ///      `true` — exactly the glide-coach contract.
  ///   2. The user-facing `enabled` toggle persisted here.
  ///
  /// `setEnabled(true)` still WRITES `true` so a later flag flip restores
  /// the user's historical opt-in, but the in-memory `enabled` stays gated.
  VoiceAnnouncementSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'voiceAnnouncementSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$voiceAnnouncementSettingsHash();

  @$internal
  @override
  VoiceAnnouncementSettings create() => VoiceAnnouncementSettings();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnnouncementConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnnouncementConfig>(value),
    );
  }
}

String _$voiceAnnouncementSettingsHash() =>
    r'8c2f48be1713a522129b2351b510dcde58556d28';

/// Persisted user settings for voice announcements while driving (#2569).
///
/// Backs the four tunables the dormant [AnnouncementEngine] already reads
/// — enable, price threshold, proximity radius, repeat cooldown — onto
/// `SharedPreferences`. The shape mirrors `GlideCoachSettingsNotifier`
/// (#1125 phase 3b): a device-local preference (not profile-bound), read
/// on startup, write-through on every setter. The value type IS the
/// engine's own [AnnouncementConfig] so the live call site
/// (`voiceAnnouncementListenerProvider`) can hand it to the engine
/// without an adapter layer.
///
/// ### Layered gate (master flag + user toggle)
///
/// Two independent off-switches must both be true before a word is
/// spoken:
///
///   1. The central [Feature.voiceAnnouncements] flag, read via
///      [voiceAnnouncementsEnabledProvider] (default-off; requires the
///      approach overlay). When the flag is off, the resolved config's
///      `enabled` is forced `false` even if the persisted toggle is
///      `true` — exactly the glide-coach contract.
///   2. The user-facing `enabled` toggle persisted here.
///
/// `setEnabled(true)` still WRITES `true` so a later flag flip restores
/// the user's historical opt-in, but the in-memory `enabled` stays gated.

abstract class _$VoiceAnnouncementSettings
    extends $Notifier<AnnouncementConfig> {
  AnnouncementConfig build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AnnouncementConfig, AnnouncementConfig>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AnnouncementConfig, AnnouncementConfig>,
              AnnouncementConfig,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
