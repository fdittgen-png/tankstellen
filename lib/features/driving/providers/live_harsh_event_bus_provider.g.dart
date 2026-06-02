// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_harsh_event_bus_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide broadcast bus for live harsh-driving events (#2663).
///
/// The recording recorders (OBD2 via [TripRecordingController] and the
/// GPS-only pipeline) both feed their `onHarshEvent` callback into this
/// single sink the instant the [HarshEventDetector] fires a (de-noised,
/// post-#2653) event. The [DrivingCoachVoiceListener] subscribes to
/// [stream] and speaks a localised cue per qualifying event.
///
/// Decoupling the recorders from the listener through a bus avoids
/// threading a new stream out through the deeply layered
/// [TripRecording] notifier + its pipeline collaborators — each recorder
/// just `add`s, and any number of consumers can listen. `keepAlive`
/// because a trip + its event flow outlive widget rebuilds as the driver
/// navigates the app mid-trip.

@ProviderFor(LiveHarshEventBus)
final liveHarshEventBusProvider = LiveHarshEventBusProvider._();

/// App-wide broadcast bus for live harsh-driving events (#2663).
///
/// The recording recorders (OBD2 via [TripRecordingController] and the
/// GPS-only pipeline) both feed their `onHarshEvent` callback into this
/// single sink the instant the [HarshEventDetector] fires a (de-noised,
/// post-#2653) event. The [DrivingCoachVoiceListener] subscribes to
/// [stream] and speaks a localised cue per qualifying event.
///
/// Decoupling the recorders from the listener through a bus avoids
/// threading a new stream out through the deeply layered
/// [TripRecording] notifier + its pipeline collaborators — each recorder
/// just `add`s, and any number of consumers can listen. `keepAlive`
/// because a trip + its event flow outlive widget rebuilds as the driver
/// navigates the app mid-trip.
final class LiveHarshEventBusProvider
    extends $StreamNotifierProvider<LiveHarshEventBus, HarshEvent> {
  /// App-wide broadcast bus for live harsh-driving events (#2663).
  ///
  /// The recording recorders (OBD2 via [TripRecordingController] and the
  /// GPS-only pipeline) both feed their `onHarshEvent` callback into this
  /// single sink the instant the [HarshEventDetector] fires a (de-noised,
  /// post-#2653) event. The [DrivingCoachVoiceListener] subscribes to
  /// [stream] and speaks a localised cue per qualifying event.
  ///
  /// Decoupling the recorders from the listener through a bus avoids
  /// threading a new stream out through the deeply layered
  /// [TripRecording] notifier + its pipeline collaborators — each recorder
  /// just `add`s, and any number of consumers can listen. `keepAlive`
  /// because a trip + its event flow outlive widget rebuilds as the driver
  /// navigates the app mid-trip.
  LiveHarshEventBusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liveHarshEventBusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liveHarshEventBusHash();

  @$internal
  @override
  LiveHarshEventBus create() => LiveHarshEventBus();
}

String _$liveHarshEventBusHash() => r'e63ad4bcc24c3b376a8929a92339ef1211ace079';

/// App-wide broadcast bus for live harsh-driving events (#2663).
///
/// The recording recorders (OBD2 via [TripRecordingController] and the
/// GPS-only pipeline) both feed their `onHarshEvent` callback into this
/// single sink the instant the [HarshEventDetector] fires a (de-noised,
/// post-#2653) event. The [DrivingCoachVoiceListener] subscribes to
/// [stream] and speaks a localised cue per qualifying event.
///
/// Decoupling the recorders from the listener through a bus avoids
/// threading a new stream out through the deeply layered
/// [TripRecording] notifier + its pipeline collaborators — each recorder
/// just `add`s, and any number of consumers can listen. `keepAlive`
/// because a trip + its event flow outlive widget rebuilds as the driver
/// navigates the app mid-trip.

abstract class _$LiveHarshEventBus extends $StreamNotifier<HarshEvent> {
  Stream<HarshEvent> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<HarshEvent>, HarshEvent>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<HarshEvent>, HarshEvent>,
              AsyncValue<HarshEvent>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
