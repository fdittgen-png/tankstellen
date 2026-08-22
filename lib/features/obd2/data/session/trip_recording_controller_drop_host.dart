// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'trip_recording_controller.dart';

/// Adapts [TripRecordingController]'s recording loop to the narrow
/// [DroppedSessionHost] seam the drop-recovery state machine needs
/// (#2188). Lives in the same library as the controller so it can
/// delegate to its private lifecycle flags + collaborators without
/// widening the controller's public API.
///
/// Every method here is a thin pass-through; the behaviour-preserving
/// extraction lives in [DroppedSessionManager]. The adapter exists only
/// so the manager stays unit-testable against a fake host while
/// production wires the real controller.
class _DroppedSessionHostAdapter implements DroppedSessionHost {
  _DroppedSessionHostAdapter(this._c);

  final TripRecordingController _c;

  @override
  void stopScheduler() => _c._scheduler?.stop();

  @override
  void pauseScheduler() => _c._scheduler?.pause();

  @override
  void resumeScheduler() => _c._scheduler?.resume();

  @override
  void disconnectDroppedService() {
    // #2524 — fail the dead transport's stranded `_pending` + close its
    // channel off the hot path. Best-effort; the link is already gone.
    final svc = _c._service;
    unawaited(() async {
      try {
        await svc.disconnect();
      } catch (e, st) {
        debugPrint('TripRecordingController: dropped-service disconnect '
            'failed (already dead) — $e\n$st');
      }
    }());
  }

  @override
  void startScheduler() => _c._scheduler?.start();

  @override
  void resetDropDetector() => _c._dropDetector.reset();

  @override
  void clearDropDetectorErrorWindow() => _c._dropDetector.clearErrorWindow();

  @override
  void emitState() => _c._emitState();

  @override
  void resumeFromReconnect() => _c.resume();

  @override
  TripSummary buildInProgressSummary() => _c._recorder.buildSummary();

  @override
  TripSummary buildFinalSummary() => _c._finaliseSummary();

  @override
  bool get pausedDueToDrop => _c._pausedDueToDrop;
  @override
  set pausedDueToDrop(bool value) => _c._pausedDueToDrop = value;

  @override
  bool get degradedGpsOnly => _c._degradedGpsOnly;
  @override
  set degradedGpsOnly(bool value) => _c._degradedGpsOnly = value;

  @override
  bool get gpsAlive => GpsOnlySampleBuilder.gpsAlive(
        lastGpsFixAt: _c._gpsEndedAt,
        now: _c._now(),
        window: TripRecordingController._gpsAliveWindow,
      );

  @override
  bool get stopped => _c._stopped;
  @override
  set stopped(bool value) => _c._stopped = value;

  @override
  bool get started => _c._started;
  @override
  set started(bool value) => _c._started = value;

  @override
  bool get paused => _c._paused;

  @override
  String? get sessionId => _c._sessionId;

  @override
  String? get vehicleId => _c._vehicleId;

  @override
  String? get vin => _c._vin;

  @override
  double? get odometerStartKm => _c._odometerStartKm;

  @override
  double? get odometerLatestKm => _c._odometerLatestKm;

  @override
  bool get automatic => _c._automatic;

  @override
  List<TripSample> get capturedSamples => _c._sampleBuffer.capturedSamples;

  @override
  List<GpsSampleDiagnostic> get capturedGpsSampleDiagnostics =>
      _c._sampleBuffer.capturedGpsSampleDiagnostics;
}
