// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../domain/trip_recorder.dart';
import 'gps_only_sample_builder.dart';
import 'trip_live_reading.dart';
import 'trip_sample_buffer.dart';

/// #2565 — owns one emit tick of the `degradedGpsOnly` phase (OBD2
/// dropped mid-trip but GPS is alive), extracted from the conflict-magnet
/// god-class `TripRecordingController` so the controller stays at its
/// grandfathered file-length snapshot.
///
/// OBD2 is gone (the PID snapshot is stale) but GPS keeps latching a live
/// ground speed, so the trip must keep recording instead of freezing.
/// This builds a GPS-only [TripSample] exactly like
/// `GpsOnlyRecordingPipeline._onPosition` (speed from the GPS latch,
/// `rpm: 0`, lat/lon/alt from the snapshot, `fuelRateLPerHour: null`),
/// feeds it to the same recorder + sample buffer the OBD2 path uses, then
/// publishes a live reading whose GPS-physics estimate + coaching overlay
/// runs (fuelRate null) so the L/100 km figure flows continuously.
///
/// Every dependency is injected (the clock, the recorder + buffer, the
/// shared estimate-overlay seam, the distance/odometer/elapsed reads, the
/// escalate + last-sample callbacks) so the emitter carries no controller
/// lifecycle state of its own and is unit-testable in isolation.
class DegradedGpsEmitter {
  DegradedGpsEmitter({
    required DateTime Function() now,
    required TripRecorder recorder,
    required TripSampleBuffer sampleBuffer,
    required Duration gpsAliveWindow,
    required void Function() onEscalate,
    required void Function(DateTime at) onSampleAt,
    required TripLiveReading Function(
      TripLiveReading reading, {
      required DateTime nowTs,
      required double? effectiveSpeedKmh,
      required double? altitudeM,
    }) overlayEstimate,
  })  : _now = now,
        _recorder = recorder,
        _sampleBuffer = sampleBuffer,
        _gpsAliveWindow = gpsAliveWindow,
        _onEscalate = onEscalate,
        _onSampleAt = onSampleAt,
        _overlayEstimate = overlayEstimate;

  final DateTime Function() _now;
  final TripRecorder _recorder;
  final TripSampleBuffer _sampleBuffer;
  final Duration _gpsAliveWindow;
  final void Function() _onEscalate;
  final void Function(DateTime at) _onSampleAt;
  final TripLiveReading Function(
    TripLiveReading reading, {
    required DateTime nowTs,
    required double? effectiveSpeedKmh,
    required double? altitudeM,
  }) _overlayEstimate;

  /// Run one degraded emit tick. Returns the live reading to publish, or
  /// null when GPS has ALSO gone silent past [gpsAliveWindow] — both
  /// sources dead → the caller's escalate-to-paused callback has fired
  /// and nothing should be published this tick.
  TripLiveReading? emitTick({
    required double? latestGpsSpeedKmh,
    required double? latitude,
    required double? longitude,
    required double? altitudeM,
    // #2648 — most recent GPS horizontal accuracy + bearing, forwarded
    // into the GPS-only sample so the degraded path stops dropping them.
    double? hAccuracyM,
    double? bearingDeg,
    required DateTime? lastGpsFixAt,
    required DateTime? startedAt,
    required double resolverDistanceKm,
    required double? odometerStartKm,
    required double? odometerLatestKm,
  }) {
    final nowTs = _now();
    // GPS also gone? Both sources dead → escalate to the visible pause.
    if (!GpsOnlySampleBuilder.gpsAlive(
      lastGpsFixAt: lastGpsFixAt,
      now: nowTs,
      window: _gpsAliveWindow,
    )) {
      _onEscalate();
      return null;
    }
    if (latestGpsSpeedKmh != null) {
      final sample = GpsOnlySampleBuilder.build(
        timestamp: nowTs,
        speedKmh: latestGpsSpeedKmh,
        latitude: latitude,
        longitude: longitude,
        altitudeM: altitudeM,
        // #2648 — carry accuracy + bearing into the degraded GPS-only
        // sample so they aren't dropped when OBD2 falls away mid-trip.
        hAccuracyM: hAccuracyM,
        bearingDeg: bearingDeg,
      );
      _recorder.onSample(sample);
      _onSampleAt(nowTs);
      _sampleBuffer.maybeCapture(sample);
    }
    final summary = _recorder.buildSummary();
    final effectiveDistanceKm = resolverDistanceKm > summary.distanceKm
        ? resolverDistanceKm
        : summary.distanceKm;
    final reading = TripLiveReading(
      speedKmh: latestGpsSpeedKmh,
      altitudeM: altitudeM,
      distanceKmSoFar: effectiveDistanceKm,
      elapsed: nowTs.difference(startedAt ?? nowTs),
      odometerStartKm: odometerStartKm,
      odometerNowKm: odometerLatestKm,
    );
    return _overlayEstimate(
      reading,
      nowTs: nowTs,
      effectiveSpeedKmh: latestGpsSpeedKmh,
      altitudeM: altitudeM,
    );
  }
}
