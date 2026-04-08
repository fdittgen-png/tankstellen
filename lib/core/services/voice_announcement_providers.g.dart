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

@ProviderFor(voiceAnnouncementService)
final voiceAnnouncementServiceProvider = VoiceAnnouncementServiceProvider._();

/// Provides the platform TTS service singleton.
///
/// Kept alive for the app lifetime so the TTS engine is initialized once.

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
    r'3b79a24d1173eb979132dd6be801e98ba462dd3c';

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
