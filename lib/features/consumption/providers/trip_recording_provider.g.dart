// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_recording_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide owner of the trip recording (#726).
///
/// Hoisted out of [TripRecordingScreen]'s state so a trip survives
/// navigation — the user can start recording, switch to the Search
/// tab, tap a station, come back, and find the trip still running.
/// Lives for the app's lifetime (`keepAlive: true`) because dropping
/// it mid-drive would silently throw away the trip.
///
/// Owns the [Obd2Service] while a trip is active; the
/// [Obd2ConnectionService] hands ownership here on [start] and gets
/// it back on [stop].

@ProviderFor(TripRecording)
final tripRecordingProvider = TripRecordingProvider._();

/// App-wide owner of the trip recording (#726).
///
/// Hoisted out of [TripRecordingScreen]'s state so a trip survives
/// navigation — the user can start recording, switch to the Search
/// tab, tap a station, come back, and find the trip still running.
/// Lives for the app's lifetime (`keepAlive: true`) because dropping
/// it mid-drive would silently throw away the trip.
///
/// Owns the [Obd2Service] while a trip is active; the
/// [Obd2ConnectionService] hands ownership here on [start] and gets
/// it back on [stop].
final class TripRecordingProvider
    extends $NotifierProvider<TripRecording, TripRecordingState> {
  /// App-wide owner of the trip recording (#726).
  ///
  /// Hoisted out of [TripRecordingScreen]'s state so a trip survives
  /// navigation — the user can start recording, switch to the Search
  /// tab, tap a station, come back, and find the trip still running.
  /// Lives for the app's lifetime (`keepAlive: true`) because dropping
  /// it mid-drive would silently throw away the trip.
  ///
  /// Owns the [Obd2Service] while a trip is active; the
  /// [Obd2ConnectionService] hands ownership here on [start] and gets
  /// it back on [stop].
  TripRecordingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tripRecordingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripRecordingHash();

  @$internal
  @override
  TripRecording create() => TripRecording();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TripRecordingState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TripRecordingState>(value),
    );
  }
}

String _$tripRecordingHash() => r'0fad8abf73331569d18957cf11ccc55e95166909';

/// App-wide owner of the trip recording (#726).
///
/// Hoisted out of [TripRecordingScreen]'s state so a trip survives
/// navigation — the user can start recording, switch to the Search
/// tab, tap a station, come back, and find the trip still running.
/// Lives for the app's lifetime (`keepAlive: true`) because dropping
/// it mid-drive would silently throw away the trip.
///
/// Owns the [Obd2Service] while a trip is active; the
/// [Obd2ConnectionService] hands ownership here on [start] and gets
/// it back on [stop].

abstract class _$TripRecording extends $Notifier<TripRecordingState> {
  TripRecordingState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<TripRecordingState, TripRecordingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TripRecordingState, TripRecordingState>,
              TripRecordingState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
