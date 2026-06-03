// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_announcement_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the platform TTS service singleton.
///
/// Kept alive for the app lifetime so the TTS engine is initialized once.
///
/// Binds the service to the app's SELECTED locale (#2762): the initial
/// language is read from [activeLanguageProvider] (the persisted/profile
/// language the rest of the app uses), and a [Ref.listen] re-applies it
/// whenever the user changes language — so both the native TTS voice and
/// the spoken sentence follow the app language rather than the device
/// default voice + hardcoded English words.
///
/// The locale binding is best-effort by design: this is an app-lifetime
/// singleton, so it MUST NOT make every transitive consumer (e.g. the active
/// driving screen) depend on the Hive-backed profile store being open. During
/// early startup — and in widget tests that don't open the profile box —
/// [activeLanguageProvider] (which watches the profile) may still be in error
/// state; reading it would otherwise poison this provider and every consumer.
/// We therefore read defensively and start on the device-default voice, then
/// let the [Ref.listen] below snap the locale to the app language the instant
/// the profile resolves (and on every later language change).

@ProviderFor(voiceAnnouncementService)
final voiceAnnouncementServiceProvider = VoiceAnnouncementServiceProvider._();

/// Provides the platform TTS service singleton.
///
/// Kept alive for the app lifetime so the TTS engine is initialized once.
///
/// Binds the service to the app's SELECTED locale (#2762): the initial
/// language is read from [activeLanguageProvider] (the persisted/profile
/// language the rest of the app uses), and a [Ref.listen] re-applies it
/// whenever the user changes language — so both the native TTS voice and
/// the spoken sentence follow the app language rather than the device
/// default voice + hardcoded English words.
///
/// The locale binding is best-effort by design: this is an app-lifetime
/// singleton, so it MUST NOT make every transitive consumer (e.g. the active
/// driving screen) depend on the Hive-backed profile store being open. During
/// early startup — and in widget tests that don't open the profile box —
/// [activeLanguageProvider] (which watches the profile) may still be in error
/// state; reading it would otherwise poison this provider and every consumer.
/// We therefore read defensively and start on the device-default voice, then
/// let the [Ref.listen] below snap the locale to the app language the instant
/// the profile resolves (and on every later language change).

final class VoiceAnnouncementServiceProvider
    extends
        $FunctionalProvider<
          VoiceAnnouncementService,
          VoiceAnnouncementService,
          VoiceAnnouncementService
        >
    with $Provider<VoiceAnnouncementService> {
  /// Provides the platform TTS service singleton.
  ///
  /// Kept alive for the app lifetime so the TTS engine is initialized once.
  ///
  /// Binds the service to the app's SELECTED locale (#2762): the initial
  /// language is read from [activeLanguageProvider] (the persisted/profile
  /// language the rest of the app uses), and a [Ref.listen] re-applies it
  /// whenever the user changes language — so both the native TTS voice and
  /// the spoken sentence follow the app language rather than the device
  /// default voice + hardcoded English words.
  ///
  /// The locale binding is best-effort by design: this is an app-lifetime
  /// singleton, so it MUST NOT make every transitive consumer (e.g. the active
  /// driving screen) depend on the Hive-backed profile store being open. During
  /// early startup — and in widget tests that don't open the profile box —
  /// [activeLanguageProvider] (which watches the profile) may still be in error
  /// state; reading it would otherwise poison this provider and every consumer.
  /// We therefore read defensively and start on the device-default voice, then
  /// let the [Ref.listen] below snap the locale to the app language the instant
  /// the profile resolves (and on every later language change).
  VoiceAnnouncementServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'voiceAnnouncementServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$voiceAnnouncementServiceHash();

  @$internal
  @override
  $ProviderElement<VoiceAnnouncementService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VoiceAnnouncementService create(Ref ref) {
    return voiceAnnouncementService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VoiceAnnouncementService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VoiceAnnouncementService>(value),
    );
  }
}

String _$voiceAnnouncementServiceHash() =>
    r'da1d9950c472a9074975e98d2951bd8b62ac3347';

/// Provides the announcement engine that evaluates nearby stations.
///
/// Kept alive so cooldown state persists across screen navigations.

@ProviderFor(announcementEngine)
final announcementEngineProvider = AnnouncementEngineProvider._();

/// Provides the announcement engine that evaluates nearby stations.
///
/// Kept alive so cooldown state persists across screen navigations.

final class AnnouncementEngineProvider
    extends
        $FunctionalProvider<
          AnnouncementEngine,
          AnnouncementEngine,
          AnnouncementEngine
        >
    with $Provider<AnnouncementEngine> {
  /// Provides the announcement engine that evaluates nearby stations.
  ///
  /// Kept alive so cooldown state persists across screen navigations.
  AnnouncementEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'announcementEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$announcementEngineHash();

  @$internal
  @override
  $ProviderElement<AnnouncementEngine> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AnnouncementEngine create(Ref ref) {
    return announcementEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnnouncementEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnnouncementEngine>(value),
    );
  }
}

String _$announcementEngineHash() =>
    r'f5295552fe2935d9a013a02b7e60bc6c8e68be61';
