// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'trip_recording_controller.dart';

/// Epic #3855 — the per-tick vehicle-power bookkeeping of
/// [TripRecordingController]: the #3857 `ATRV` voltage watch, the #3859
/// engine transition out of the engine-off wait, and the #3862 parked
/// prompt / auto-record auto-stop.
///
/// #4034 (epic #4032) — the state behind two of those three now belongs
/// to owned collaborators ([TripVoltageWatch], [TripParkedPromptWatch]);
/// this part drives them and keeps the link-state preconditions, which
/// are the controller's own.
mixin _TripRecordingPowerWatch
    on _TripRecordingTelemetryIngest, _TripRecordingTransportGuard {
  /// #3857 / #3859 / #3862 — the per-tick vehicle-power bookkeeping.
  void _powerTick() {
    final now = _now();
    final power = Obd2VehiclePower.instance;
    if (_service.isConnected &&
        !_protocolWorkInFlight &&
        _voltageWatch.isDue(now)) {
      _voltageWatch.markRead(now);
      unawaited(_service.readBatteryVoltageV().then((v) {
        if (v != null) _voltageWatch.stamp(v);
      }));
    }
    // #3877 — re-read the odometer every few minutes while the engine
    // runs, only on a car that answered at trip start (no stalls on an
    // unsupported car) and never over protocol work.
    final lastRefresh = _odometer.lastRefreshReference;
    if (_odometer.everAnswered &&
        _service.isConnected &&
        !_protocolWorkInFlight &&
        !_run.degradedGpsOnly &&
        power.engineRunning &&
        (lastRefresh == null ||
            now.difference(lastRefresh) >=
                TripRecordingController.odometerRefreshInterval) &&
        _odometer.claimPeriodicRefresh()) {
      unawaited(
          refreshOdometer().whenComplete(_odometer.endPeriodicRefresh));
    }
    power.tick();
    final engineOffWait = _run.degradedGpsOnly &&
        _droppedSession.dropReason == TripDropReason.engineOff;
    if (!engineOffWait) {
      if (_parkedWatch.onEngineOffWaitEnded()) _emitState();
      return;
    }
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
    final decision = _parkedWatch.tick(
      now: now,
      gpsSpeedKmh: _latestGpsSpeedKmh,
      automatic: _automatic,
      promptAfter: TripRecordingController.parkedPromptAfter,
    );
    final parkedMinutes = _parkedWatch.parkedFor(now).inMinutes;
    switch (decision) {
      case ParkedPromptDecision.none:
        return;
      case ParkedPromptDecision.finalise:
        // An auto-record trip ends itself: it started on its own, it
        // ends on its own — once, and only when nothing is left to
        // record.
        BreadcrumbCollector.add(
          'OBD2 recording: parked $parkedMinutes min with the '
          'engine off — auto-record trip finalised (#3862)',
        );
        unawaited(_droppedSession.finaliseParked());
      case ParkedPromptDecision.prompt:
        _sessionJournal.add(RecordingSessionEventKind.linkEngineOff,
            detail: 'parked $parkedMinutes min — prompting');
        _emitState();
    }
  }
}
