import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/obd2/obd2_service.dart';
import '../data/obd2/trip_recording_controller.dart';
import '../domain/trip_recorder.dart';

part 'trip_recording_provider.g.dart';

/// Lifecycle phase of the app-wide OBD2 trip recording (#726).
enum TripRecordingPhase { idle, recording, paused, finished }

/// Immutable snapshot the UI observes.
@immutable
class TripRecordingState {
  final TripRecordingPhase phase;
  final TripLiveReading? live;

  const TripRecordingState({
    this.phase = TripRecordingPhase.idle,
    this.live,
  });

  TripRecordingState copyWith({
    TripRecordingPhase? phase,
    TripLiveReading? live,
  }) =>
      TripRecordingState(
        phase: phase ?? this.phase,
        live: live ?? this.live,
      );

  bool get isActive =>
      phase == TripRecordingPhase.recording ||
      phase == TripRecordingPhase.paused;
}

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
@Riverpod(keepAlive: true)
class TripRecording extends _$TripRecording {
  Obd2Service? _service;
  TripRecordingController? _controller;
  StreamSubscription<TripLiveReading>? _liveSub;

  @override
  TripRecordingState build() {
    return const TripRecordingState();
  }

  /// Begin a recording session backed by [service]. The provider
  /// takes ownership of the service — don't disconnect it from the
  /// caller; [stop] handles the full teardown.
  Future<void> start(Obd2Service service) async {
    if (state.isActive) return;
    _service = service;
    final ctl = TripRecordingController(service: service);
    _controller = ctl;
    await ctl.start();
    _liveSub = ctl.live.listen((reading) {
      state = state.copyWith(
        phase: ctl.isPaused
            ? TripRecordingPhase.paused
            : TripRecordingPhase.recording,
        live: reading,
      );
    });
    state = state.copyWith(phase: TripRecordingPhase.recording);
  }

  void pause() {
    final ctl = _controller;
    if (ctl == null || !state.isActive) return;
    ctl.pause();
    state = state.copyWith(phase: TripRecordingPhase.paused);
  }

  void resume() {
    final ctl = _controller;
    if (ctl == null || state.phase != TripRecordingPhase.paused) return;
    ctl.resume();
    state = state.copyWith(phase: TripRecordingPhase.recording);
  }

  /// Stop the polling loop, refresh the odometer one last time,
  /// release the service, and return the accumulated [TripSummary].
  /// Safe to call when no trip is active — returns a default empty
  /// summary so callers don't have to null-check.
  Future<StoppedTripResult> stop() async {
    final ctl = _controller;
    final svc = _service;
    if (ctl == null || svc == null) {
      state = const TripRecordingState();
      return const StoppedTripResult.empty();
    }
    try {
      await ctl.refreshOdometer();
    } catch (e) {
      debugPrint('TripRecording.stop: refreshOdometer failed: $e');
    }
    final summary = await ctl.stop();
    final odometerStartKm = ctl.odometerStartKm;
    final odometerLatestKm = ctl.odometerLatestKm;
    await _liveSub?.cancel();
    _liveSub = null;
    _controller = null;
    try {
      await svc.disconnect();
    } catch (e) {
      debugPrint('TripRecording.stop: service disconnect failed: $e');
    }
    _service = null;
    state = state.copyWith(phase: TripRecordingPhase.finished);
    return StoppedTripResult(
      summary: summary,
      odometerStartKm: odometerStartKm,
      odometerLatestKm: odometerLatestKm,
    );
  }

  /// Return to idle — used after the caller consumes the
  /// [StoppedTripResult] (saves as fill-up or discards).
  void reset() {
    state = const TripRecordingState();
  }
}

/// Returned by [TripRecording.stop]. Bundles the summary with the
/// raw odometer reads so the save-as-fill-up flow can pre-fill the
/// form.
class StoppedTripResult {
  final TripSummary summary;
  final double? odometerStartKm;
  final double? odometerLatestKm;

  const StoppedTripResult({
    required this.summary,
    required this.odometerStartKm,
    required this.odometerLatestKm,
  });

  const StoppedTripResult.empty()
      : summary = const TripSummary(
          distanceKm: 0,
          maxRpm: 0,
          highRpmSeconds: 0,
          idleSeconds: 0,
          harshBrakes: 0,
          harshAccelerations: 0,
        ),
        odometerStartKm = null,
        odometerLatestKm = null;

  /// End-of-trip km, derived: latest odometer read if we have one,
  /// otherwise start + integrated distance. Null when neither
  /// odometer read ever succeeded.
  double? get endOdometerKm =>
      odometerLatestKm ??
      (odometerStartKm == null
          ? null
          : odometerStartKm! + summary.distanceKm);
}
