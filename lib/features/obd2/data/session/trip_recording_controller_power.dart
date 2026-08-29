// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'trip_recording_controller.dart';

/// Epic #3855 — the per-tick vehicle-power bookkeeping of
/// [TripRecordingController]: the #3857 `ATRV` voltage watch, the #3859
/// engine transition out of the engine-off wait, and the #3862 parked
/// prompt / auto-record auto-stop. A `part` mixin (private-member access
/// kept) so the emit part stays under the #1680 file-length cap.
mixin _TripRecordingPowerWatch
    on _TripRecordingTelemetryIngest, _TripRecordingTransportGuard {
  /// #3857 — cadence of the `ATRV` voltage watch. One AT reply per 10 s
  /// is invisible next to the ~4 Hz PID cadence, and it is the ONLY way
  /// the engine state stays measurable once the bus goes quiet.
  static const Duration _voltageWatchInterval = Duration(seconds: 10);

  /// Below this GPS speed the car counts as stationary for the prompt.
  static const double _stationaryKmh = 3.0;

  /// #3857 / #3859 / #3862 — the per-tick vehicle-power bookkeeping.
  void _powerTick() {
    final now = _now();
    final power = Obd2VehiclePower.instance;
    final last = _lastVoltageReadAt;
    if (_service.isConnected &&
        !_protocolWorkInFlight &&
        (last == null || now.difference(last) >= _voltageWatchInterval)) {
      _lastVoltageReadAt = now;
      unawaited(_service.readBatteryVoltageV().then((v) {
        if (v != null) _pendingVoltageStamp = v;
      }));
    }
    power.tick();
    final engineOffWait = _degradedGpsOnly &&
        _droppedSession.dropReason == TripDropReason.engineOff;
    if (!engineOffWait) {
      _engineOffSince = null;
      _stationarySince = null;
      if (_parkedPromptDue) {
        _parkedPromptDue = false;
        _emitState();
      }
      return;
    }
    _engineOffSince ??= now;
    // #3859 — the engine transition: the alternator came up on the
    // voltage watch, or an ACL hint says ignition just happened. Resume
    // on the live link (the protocol gate runs the quiet-window `0100`
    // now that the bus can answer); a link the adapter's sleep already
    // killed falls into the ordinary reattach path instead.
    if (power.engineRunning || power.engineStartExpected) {
      BreadcrumbCollector.add(
        'OBD2 recording: engine transition — attaching',
        detail: power.detail,
      );
      _droppedSession.onEngineRunning(linkAlive: _service.isConnected);
      return;
    }
    // #3862 — parked prompt / auto-record auto-stop.
    final gpsSpeed = _latestGpsSpeedKmh;
    final stationary = gpsSpeed == null || gpsSpeed < _stationaryKmh;
    if (!stationary) {
      _stationarySince = null;
      return;
    }
    _stationarySince ??= now;
    final parkedFor = now.difference(
        _stationarySince!.isAfter(_engineOffSince!)
            ? _stationarySince!
            : _engineOffSince!);
    if (parkedFor < TripRecordingController.parkedPromptAfter) return;
    if (_automatic) {
      // An auto-record trip ends itself: it started on its own, it
      // ends on its own — once, and only when nothing is left to
      // record.
      if (_parkedFinaliseInFlight) return;
      _parkedFinaliseInFlight = true;
      BreadcrumbCollector.add(
        'OBD2 recording: parked ${parkedFor.inMinutes} min with the '
        'engine off — auto-record trip finalised (#3862)',
      );
      unawaited(_droppedSession.finaliseParked());
      return;
    }
    if (!_parkedPromptDue && !_parkedPromptDismissed) {
      _parkedPromptDue = true;
      _sessionJournal.add(RecordingSessionEventKind.linkEngineOff,
          detail: 'parked ${parkedFor.inMinutes} min — prompting');
      _emitState();
    }
  }

  /// #3857 — hand the pending voltage stamp to exactly one sample.
  double? _takeVoltageStamp() {
    final v = _pendingVoltageStamp;
    _pendingVoltageStamp = null;
    return v;
  }
}
