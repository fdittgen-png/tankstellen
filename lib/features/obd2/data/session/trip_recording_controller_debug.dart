// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'trip_recording_controller.dart';

/// @visibleForTesting seams of [TripRecordingController], extracted
/// from the controller file as a `part` mixin so they keep
/// private-member access while the controller stays under the #1680
/// file-length cap (sanctioned #3760 decomposition — move-only,
/// behaviour preserved). Every member here is a thin test-only
/// pass-through into the private recording internals.
mixin _TripRecordingDebugSeams
    on _TripRecordingEmit, _TripRecordingTransportGuard {
  /// Exposed for tests: append a sample to the captured-samples buffer
  /// without going through the scheduler / debounced emit timer
  /// (#1040). Tests use this to populate a deterministic buffer + then
  /// drive [TripRecording.stop] end-to-end.
  @visibleForTesting
  void debugCaptureSample(TripSample sample) {
    _sampleBuffer.debugCaptureSample(sample);
  }

  /// Exposed for tests: force an emit immediately instead of waiting
  /// for the debounced timer. Useful when a test injects a tiny
  /// scheduler tickRate but wants deterministic TripLiveReading
  /// emission on demand.
  @visibleForTesting
  void debugEmitNow() => _emit();

  /// Exposed for tests: the last sample timestamp pushed to
  /// [TripRecorder]. Null until the first emit with non-null speed
  /// or RPM.
  @visibleForTesting
  DateTime? get debugLastSampleAt => _lastSampleAt;

  /// Exposed for tests: trigger the drop-handling path directly, so
  /// tests that can't easily convince a fake transport to throw three
  /// times in a row still exercise the state transition. [reason]
  /// defaults to a transport drop; pass [TripDropReason.silentFailure]
  /// to exercise the dead-ECU path.
  @visibleForTesting
  void debugTriggerDrop({
    TripDropReason reason = TripDropReason.transportError,
  }) {
    _droppedSession.handleDrop(reason: reason);
  }

  /// Exposed for tests: whether the controller is inside the #1904
  /// invisible reconnect window (a transport drop the scanner is
  /// trying to clear before it ever reaches the pause banner).
  @visibleForTesting
  bool get debugSilentlyReconnecting => _droppedSession.silentlyReconnecting;

  /// Exposed for tests: run one command through the retrying transport
  /// path so the #1904 single-retry-on-transient-error behaviour can
  /// be unit-tested without driving the whole PID scheduler.
  @visibleForTesting
  Future<String> debugRunTransport(String command) =>
      _runTransport(command);

  /// Exposed for tests: drive the silent-failure observer with a
  /// hand-built parse outcome so tests don't have to spin up a fake
  /// service that returns null forever (#1330 phase 3). Pass `null`
  /// to increment the counter, any non-null value to reset it.
  @visibleForTesting
  void debugObserveHighPriorityParse(Object? parsedValue) {
    _observeHighPriorityParse(parsedValue);
  }

  /// Exposed for tests: current consecutive-null count. Lets the
  /// silent-failure tests assert "49 nulls did NOT trigger" before
  /// the 50th lands (#1330 phase 3).
  @visibleForTesting
  int get debugConsecutiveNullReads => _dropDetector.consecutiveNullReads;

  /// Exposed for tests: whether the silent-failure handler has fired
  /// for this recording session. Resets on resume() / stop().
  @visibleForTesting
  bool get debugSilentFailureFired => _dropDetector.silentFailureFired;

  /// Exposed for tests: synchronously drive the grace-window
  /// finalisation path. Useful with fake-async patterns where
  /// elapsing real wall-clock time is awkward.
  @visibleForTesting
  Future<void> debugExpireGraceWindow() =>
      _droppedSession.expireGraceWindowNow();

  /// Exposed for tests: the auto-reconnect scanner instance created
  /// by the drop-recovery state machine (#797 phase 3 / #2188). Null
  /// when no scanner factory is wired in or no pinned MAC is known —
  /// also null again after a successful reconnect or a stop(), because
  /// the manager releases the reference as soon as it's no longer
  /// needed.
  @visibleForTesting
  Obd2ReattachSource? get debugReconnectScanner =>
      _droppedSession.reconnectScanner;

  /// Exposed for tests: inject a hand-crafted [TripSample] directly
  /// into the underlying [TripRecorder]. Used by the #797 phase 1
  /// tests to accumulate captured data deterministically without
  /// driving the scheduler + parsers end-to-end.
  @visibleForTesting
  void debugInjectSample({
    required double speedKmh,
    double? rpm,
    required DateTime at,
    double? fuelRateLPerHour,
  }) {
    _recorder.onSample(TripSample(
      timestamp: at,
      speedKmh: speedKmh,
      rpm: rpm,
      fuelRateLPerHour: fuelRateLPerHour,
    ));
  }

  /// Exposed for tests: append a speed sample to the virtual-odometer
  /// buffer without going through the scheduler (#800). Tests use
  /// this to pre-populate samples + call [currentDistanceKm] /
  /// [distanceSource] deterministically.
  @visibleForTesting
  void debugRecordSpeedSample({
    required double speedKmh,
    required DateTime at,
  }) {
    _distance.debugAddSpeedSample(speedKmh: speedKmh, at: at);
  }

  /// Exposed for tests: override the trip's start/latest odometer
  /// readings without driving a fake transport through
  /// [refreshOdometer] (#800). Useful when the test just needs to
  /// assert that a `'real'` delta wins over the virtual path.
  @visibleForTesting
  void debugSetOdometerReadings({double? startKm, double? latestKm}) {
    if (startKm != null) _odometerStartKm = startKm;
    if (latestKm != null) _odometerLatestKm = latestKm;
  }

  /// Exposed for tests: read-only view of the captured speed samples.
  @visibleForTesting
  List<VirtualOdometerSample> get debugSpeedSamples =>
      _distance.debugSpeedSamples;

  /// Exposed for tests: append a GPS fix to the #1979 track buffer
  /// without a live Geolocator stream, so tests can drive the
  /// GPS-distance path of [currentDistanceKm] / [distanceSource]
  /// deterministically. Optional [hAccuracyM] / [at] are forwarded onto the
  /// buffered point (matching production [updateGpsFix]) so a test can drive
  /// the #2963 gates and the #3004 ~1 Hz decimation; null `at` = controller
  /// clock.
  @visibleForTesting
  void debugAppendGpsFix({
    required double latitude,
    required double longitude,
    double? hAccuracyM,
    DateTime? at,
  }) {
    _distance.debugAddGpsFix(
      latitude: latitude,
      longitude: longitude,
      hAccuracyM: hAccuracyM,
      at: at,
    );
  }
}
