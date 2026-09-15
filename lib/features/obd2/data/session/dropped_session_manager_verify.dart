// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'dropped_session_manager.dart';

/// #4196 — the recovery-verification orchestration; the verdict's state
/// and rationale live in [RecoveryVerifier].
extension DroppedSessionVerify on DroppedSessionManager {
  bool get awaitingEngineData => _verifier.awaiting;

  Duration get currentRecoveryVerifyWindow => _verifier.nextWindow;

  /// The adapter came back while degraded: resume polling on it, keep
  /// recording GPS-only, and wait for the bus to prove itself.
  void _beginRecoveryVerification() {
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
