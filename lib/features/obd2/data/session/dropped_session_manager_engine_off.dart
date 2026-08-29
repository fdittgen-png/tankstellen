// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'dropped_session_manager.dart';

/// The GPS-degraded sub-states of [DroppedSessionManager]: the #2565
/// GPS-only degrade + its escalation, and the Epic #3855 engine-off wait.
/// A `part` so the manager stays under the #1680 file-length cap (same
/// library: private-member access preserved, behaviour unchanged).
extension DroppedSessionEngineOff on DroppedSessionManager {
  /// #3858 / #3859 (Epic #3855) — enter the engine-off wait: the trip
  /// keeps recording on GPS, the link is KEPT (the adapter still answers
  /// AT commands, and the controller's voltage watch reads `ATRV` on it
  /// every ~10 s), and NOTHING dials. Deliberately absent, versus
  /// [_enterDegradedGpsOnly]: the fallback-activation marker (nothing
  /// fell back), the reconnect scanner (the level-triggered reattach
  /// source would fire immediately on the still-`ready` supervised link
  /// and resume polling into a silent bus), and the service teardown.
  ///
  /// Called by [handleDrop] for a mid-trip engine-off, and by the
  /// controller's `start()` when the recording begins with the engine
  /// off (the same state, entered from the other end).
  void enterEngineOffWait() {
    if (_host.stopped) return;
    _trace(AutoRecordEventKind.dropDetected, detail: TripDropReason.engineOff.name);
    _note(RecordingSessionEventKind.linkEngineOff, 'trip: waiting for the engine');
    _host.stopScheduler();
    _host.pauseScheduler();
    _host.clearDropDetectorErrorWindow();
    _persistPausedSnapshot();
    _host.degradedGpsOnly = true;
    _note(RecordingSessionEventKind.degradedGpsOnly, TripDropReason.engineOff.name);
    _dropReason = TripDropReason.engineOff;
    _host.emitState();
  }

  /// #3859 — the engine came back (rpm > 0 / alternator voltage / a
  /// fresh dial that answered) while in the engine-off wait. With the
  /// same link still alive, resume polling on it — the protocol gate in
  /// the host's `startScheduler` runs the quiet-window `0100` now that
  /// the bus can answer. With the link gone (the adapter slept and the
  /// socket died meanwhile), fall into the ordinary GPS-degraded state
  /// whose reattach source re-binds the trip when the supervisor — woken
  /// by the same engine transition — reaches `ready`.
  void onEngineRunning({required bool linkAlive}) {
    if (_dropReason != TripDropReason.engineOff || !_host.degradedGpsOnly) {
      return;
    }
    if (_host.stopped) return;
    if (linkAlive) {
      _host.degradedGpsOnly = false;
      _note(RecordingSessionEventKind.leftDegraded, 'engine started');
      _resumePollingAfterSilentReconnect();
      return;
    }
    _note(RecordingSessionEventKind.linkReconnecting,
        'engine started — link gone, waiting for the supervisor');
    _dropReason = TripDropReason.transportError;
    _trace(AutoRecordEventKind.silentReconnectStarted);
    if (_reconnectScanner == null) _startReconnectScanner();
    _host.emitState();
  }

  /// #3862 — automatic trips (auto-record) end themselves when the car
  /// has been parked with the engine off long enough: the same finalise
  /// path the grace window uses, attributed as a parked stop.
  Future<void> finaliseParked() async {
    if (_host.stopped) return;
    await stopReconnectScanner();
    _note(RecordingSessionEventKind.ended, 'engineOffParked');
    await _repos.finaliseToHistory(_host, dropReason: _dropReason?.name);
    _host.degradedGpsOnly = false;
    _host.pausedDueToDrop = false;
    _host.stopped = true;
    _host.started = false;
    _host.emitState();
  }

  /// #2565 — enter GPS-only degraded recording: OBD2 is gone but GPS is
  /// alive, so the trip keeps capturing GPS samples. The scheduler is
  /// already stopped + the dead service disconnected (by [handleDrop]);
  /// this flips the host flag, starts the reconnect scanner so OBD2 can
  /// re-attach, and emits — but starts NO grace timer (the trip is
  /// actively recording and must never auto-finalise / discard).
  void _enterDegradedGpsOnly(TripDropReason reason) {
    _host.degradedGpsOnly = true;
    _note(RecordingSessionEventKind.degradedGpsOnly, reason.name);
    _dropReason = reason;
    // #2905 — stamp the GPS-only-fallback-activation marker the trajet omitted.
    Obd2CommDiagnostics.instance.noteFallbackActivated(detail: reason.name);
    _trace(AutoRecordEventKind.silentReconnectStarted);
    if (_reconnectScanner == null) _startReconnectScanner();
    _host.emitState();
  }

  /// #2565 — while degraded, GPS has ALSO gone silent past the gap-cap
  /// window: now BOTH sources are dead, so escalate to the visible pause
  /// banner exactly as a dead-GPS drop would. Clears the degrade flag and
  /// routes through the ordinary visible-drop path (grace timer + banner).
  void escalateDegradedToPaused() {
    if (!_host.degradedGpsOnly || _host.stopped) return;
    _host.degradedGpsOnly = false;
    _trace(AutoRecordEventKind.dropEscalatedToVisible);
    _enterVisibleDrop(_dropReason ?? TripDropReason.transportError);
  }
}
