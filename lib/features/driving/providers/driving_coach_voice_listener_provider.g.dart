// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driving_coach_voice_listener_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The dead-link fix (#2663): wires the driving coach into TTS.
///
/// Before this provider, every driving cue dead-ended — OBD2/GPS coaching
/// hints rendered as silent tiles, GlideCoach lift fired only haptics, and
/// harsh events surfaced only at trip-stop. The ONE TTS listener
/// ([VoiceAnnouncementListener]) watched only the station approach stream.
/// This listener is the missing event→coach→speak wire, mirroring that
/// sibling but driven by driving events instead of station proximity.
///
/// In [build] it:
///   * returns early (no subscription, guaranteed silence) when the
///     [voiceCoachingEnabledProvider] toggle is off;
///   * warms the shared TTS engine;
///   * subscribes to the live harsh-event bus ([liveHarshEventBusProvider])
///     — fed by both the OBD2 and GPS-only recorders the instant the
///     de-noised [HarshEventDetector] fires — and speaks a localised cue;
///   * listens to [tripRecordingProvider] for OBD2/GPS coaching-hint
///     *transitions* (shift up/down, ease pedal, GlideCoach lift, …) and
///     speaks those too.
///
/// A per-cue cooldown (keyed on the event's own wall clock, so it elapses
/// with the trip rather than a never-advancing test clock) prevents spam.
///
/// `keepAlive: true` because a trip + its event flow outlive widget
/// rebuilds as the driver navigates the app mid-trip.

@ProviderFor(DrivingCoachVoiceListener)
final drivingCoachVoiceListenerProvider = DrivingCoachVoiceListenerProvider._();

/// The dead-link fix (#2663): wires the driving coach into TTS.
///
/// Before this provider, every driving cue dead-ended — OBD2/GPS coaching
/// hints rendered as silent tiles, GlideCoach lift fired only haptics, and
/// harsh events surfaced only at trip-stop. The ONE TTS listener
/// ([VoiceAnnouncementListener]) watched only the station approach stream.
/// This listener is the missing event→coach→speak wire, mirroring that
/// sibling but driven by driving events instead of station proximity.
///
/// In [build] it:
///   * returns early (no subscription, guaranteed silence) when the
///     [voiceCoachingEnabledProvider] toggle is off;
///   * warms the shared TTS engine;
///   * subscribes to the live harsh-event bus ([liveHarshEventBusProvider])
///     — fed by both the OBD2 and GPS-only recorders the instant the
///     de-noised [HarshEventDetector] fires — and speaks a localised cue;
///   * listens to [tripRecordingProvider] for OBD2/GPS coaching-hint
///     *transitions* (shift up/down, ease pedal, GlideCoach lift, …) and
///     speaks those too.
///
/// A per-cue cooldown (keyed on the event's own wall clock, so it elapses
/// with the trip rather than a never-advancing test clock) prevents spam.
///
/// `keepAlive: true` because a trip + its event flow outlive widget
/// rebuilds as the driver navigates the app mid-trip.
final class DrivingCoachVoiceListenerProvider
    extends $NotifierProvider<DrivingCoachVoiceListener, void> {
  /// The dead-link fix (#2663): wires the driving coach into TTS.
  ///
  /// Before this provider, every driving cue dead-ended — OBD2/GPS coaching
  /// hints rendered as silent tiles, GlideCoach lift fired only haptics, and
  /// harsh events surfaced only at trip-stop. The ONE TTS listener
  /// ([VoiceAnnouncementListener]) watched only the station approach stream.
  /// This listener is the missing event→coach→speak wire, mirroring that
  /// sibling but driven by driving events instead of station proximity.
  ///
  /// In [build] it:
  ///   * returns early (no subscription, guaranteed silence) when the
  ///     [voiceCoachingEnabledProvider] toggle is off;
  ///   * warms the shared TTS engine;
  ///   * subscribes to the live harsh-event bus ([liveHarshEventBusProvider])
  ///     — fed by both the OBD2 and GPS-only recorders the instant the
  ///     de-noised [HarshEventDetector] fires — and speaks a localised cue;
  ///   * listens to [tripRecordingProvider] for OBD2/GPS coaching-hint
  ///     *transitions* (shift up/down, ease pedal, GlideCoach lift, …) and
  ///     speaks those too.
  ///
  /// A per-cue cooldown (keyed on the event's own wall clock, so it elapses
  /// with the trip rather than a never-advancing test clock) prevents spam.
  ///
  /// `keepAlive: true` because a trip + its event flow outlive widget
  /// rebuilds as the driver navigates the app mid-trip.
  DrivingCoachVoiceListenerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'drivingCoachVoiceListenerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$drivingCoachVoiceListenerHash();

  @$internal
  @override
  DrivingCoachVoiceListener create() => DrivingCoachVoiceListener();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$drivingCoachVoiceListenerHash() =>
    r'13c0702391c2e18d1c64fa3f29e0f52c0b7a34be';

/// The dead-link fix (#2663): wires the driving coach into TTS.
///
/// Before this provider, every driving cue dead-ended — OBD2/GPS coaching
/// hints rendered as silent tiles, GlideCoach lift fired only haptics, and
/// harsh events surfaced only at trip-stop. The ONE TTS listener
/// ([VoiceAnnouncementListener]) watched only the station approach stream.
/// This listener is the missing event→coach→speak wire, mirroring that
/// sibling but driven by driving events instead of station proximity.
///
/// In [build] it:
///   * returns early (no subscription, guaranteed silence) when the
///     [voiceCoachingEnabledProvider] toggle is off;
///   * warms the shared TTS engine;
///   * subscribes to the live harsh-event bus ([liveHarshEventBusProvider])
///     — fed by both the OBD2 and GPS-only recorders the instant the
///     de-noised [HarshEventDetector] fires — and speaks a localised cue;
///   * listens to [tripRecordingProvider] for OBD2/GPS coaching-hint
///     *transitions* (shift up/down, ease pedal, GlideCoach lift, …) and
///     speaks those too.
///
/// A per-cue cooldown (keyed on the event's own wall clock, so it elapses
/// with the trip rather than a never-advancing test clock) prevents spam.
///
/// `keepAlive: true` because a trip + its event flow outlive widget
/// rebuilds as the driver navigates the app mid-trip.

abstract class _$DrivingCoachVoiceListener extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
