// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

part of 'dropped_session_manager.dart';

/// #4196 — the recovery-verification orchestration; the verdict's state
/// and rationale live in [RecoveryVerifier].
extension DroppedSessionVerify on DroppedSessionManager {
  bool get awaitingEngineData => _verifier.awaiting;
  Duration get currentRecoveryVerifyWindow => _verifier.nextWindow;

  /// #4386 — automatic recovery has said everything it can: every
  /// adoption since the drop proved the adapter and none proved the car.
  /// GPS recording is untouched; the UI swaps to the honest terminal
  /// copy and the one manual action (#3676/#3678).
  bool get recoveryExhausted => _recoveryExhausted;

  /// The adapter came back while degraded: resume polling on it, keep
  /// recording GPS-only, and wait for the bus to prove itself.
  void _beginRecoveryVerification() {
    if (_verifier.awaiting) return; // #4237 — single-flight
    final window = _verifier.begin(_onRecoveryUnverified);
    _note(RecordingSessionEventKind.recoveryVerifying,
        'link adopted — waiting up to ${window.inSeconds}s for engine data');
    _host.resetDropDetector();
    clearPausedTripRow();
    _host.resumeScheduler();
    if (!_host.paused && !_host.stopped) _host.startScheduler();
    _host.emitState();
  }

  /// A fresh engine parse (called on every parse; cheap when idle).
  void onEngineData() {
    if (!_verifier.verify() || _host.stopped || !_host.degradedGpsOnly) {
      return;
    }
    _host.degradedGpsOnly = false;
    _note(RecordingSessionEventKind.leftDegraded, 'engine data verified');
    _recoveryExhausted = false; // #4386 — a verified parse clears it
    _dropReason = null;
    _host.resetDropDetector();
    _trace(AutoRecordEventKind.silentReconnectSucceeded);
    _host.emitState();
  }

  /// No engine data in the window: the link reaches the adapter but not
  /// the car. Hand it back and wait for another.
  void _onRecoveryUnverified() {
    if (_host.stopped || !_host.degradedGpsOnly) return;
    final detail = 'no engine data — handing the link back '
        '(unverified ${_verifier.unverifiedStreak}× in a row)';
    _note(RecordingSessionEventKind.recoveryUnverified, detail);
    BreadcrumbCollector.add('OBD2 recording: recovery unverified',
        detail: detail);
    // #4386 — the cap: the window has stopped stretching and four
    // adapters in a row proved themselves and not the car. Say so once.
    // Nothing else changes: the ladder below still runs at its capped
    // cadence and GPS recording never stops — this only stops the UI
    // promising a reconnect that is not coming.
    if (_verifier.exhausted && !_recoveryExhausted) {
      _recoveryExhausted = true;
      final terminal = 'automatic recovery exhausted after '
          '${_verifier.unverifiedStreak} unverified adoptions — '
          'the adapter answers, the vehicle bus does not';
      _note(RecordingSessionEventKind.recoveryExhausted, terminal);
      BreadcrumbCollector.add('OBD2 recording: adapter not responding',
          detail: terminal);
    }
    // A silent adoption is a quick re-drop for the #3915 cycle breaker.
    _refuseIfReadoptionCycle(TripDropReason.silentFailure);
    _host.stopScheduler();
    _host.pauseScheduler();
    _host.disconnectDroppedService();
    _host.clearDropDetectorErrorWindow();
    if (_reconnectScanner == null) _startReconnectScanner();
    _host.emitState();
  }
}
