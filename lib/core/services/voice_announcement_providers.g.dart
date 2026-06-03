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
    r'63837cec11699ecb41ee0563b8bfb0b0900283a5';

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
