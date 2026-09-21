// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

part of 'dropped_session_manager.dart';

/// The reattach-source orchestration of [DroppedSessionManager] plus the
/// #3915 cycle-breaker hook — a `part` so the manager file stays under
/// the #1680 length cap (same library: private access preserved).
extension DroppedSessionReattach on DroppedSessionManager {
  /// Kick off the auto-reconnect scanner (#797 phase 3) if both a
  /// pinned adapter MAC AND a scanner factory are wired. No-op
  /// otherwise — the grace timer remains the sole recovery path then.
  void _startReconnectScanner() {
    final mac = _pinnedAdapterMac;
    final factory = _reconnectScannerFactory;
    if (mac == null || factory == null) return;
    final scanner = factory(mac, onScannerReconnect);
    if (scanner == null) return;
    // #2767 — re-emit on the active→passive switch so the UI can swap to the
    // calmer "passive-waiting" copy. Wired here (not via the factory
    // signature) so the `(mac, onReconnect)` factory contract stays untouched.
    scanner.onPassiveWait = _onScannerPassiveWait;
    // #4385 — what the ONE owner is doing reaches the journal and the
    // banner. Wired here for the same reason as the line above: the
    // `(mac, onReconnect)` factory contract stays untouched.
    scanner.onOwnerState = _onOwnerState;
    // #3915 — the source consults the cycle breaker before every fire
    // and reports each adoption back to it.
    scanner.adoptionGate = _adoptionGate;
    _reconnectScanner = scanner;
    // Fire-and-forget — start() is an async scheduler boot that
    // shouldn't block the drop handler. Errors inside the scanner are
    // already caught internally.
    unawaited(scanner.start());
  }

  /// #2767 — the scanner dropped to a passive autoConnect wait. Recording
  /// continues; we re-emit only so the UI can swap to the calmer copy. A pure
  /// notification: no state transition, and the scanner still re-arms.
  void _onScannerPassiveWait() {
    if (_host.stopped) return;
    _trace(AutoRecordEventKind.reconnectPassiveWaiting);
    _host.emitState();
  }

  /// #4385 (Epic #4195, invariant 8) — the owner's disposition changed
  /// while the trip records degraded. Journaled so the whole episode is
  /// reconstructible from `sessionJournal` alone, and re-emitted so the
  /// banner can stop saying "reconnecting" over a parked owner. No state
  /// transition of our own: the trip keeps recording on GPS either way.
  void _onOwnerState(Obd2RecoveryOwnerState state, String detail) {
    if (_host.stopped) return;
    final parked = state == Obd2RecoveryOwnerState.parked;
    switch (state) {
      case Obd2RecoveryOwnerState.parked:
        _note(RecordingSessionEventKind.linkEngineOff, detail);
      case Obd2RecoveryOwnerState.standingDown:
        _note(RecordingSessionEventKind.linkStandDown, detail);
      case Obd2RecoveryOwnerState.working:
        if (_ownerParked) _note(RecordingSessionEventKind.linkReconnecting, detail);
    }
    if (parked == _ownerParked) return;
    _ownerParked = parked;
    _host.emitState();
  }

  /// Tear down the in-flight reconnect scanner. Best-effort; safe to
  /// call when none is running.
  Future<void> stopReconnectScanner() async {
    final scanner = _reconnectScanner;
    if (scanner == null) return;
    _reconnectScanner = null;
    try {
      await scanner.stop();
    } catch (e, st) {
      log.error(e, st, layer: ErrorLayer.storage, context: const {
            'where': 'DroppedSessionManager stop reconnect scanner'
          });
    }
  }

  /// #3915 — the trip's adoption policy, for the controller's test seam.
  Obd2AdoptionGate get adoptionGate => _adoptionGate;

  /// #3915 — a drop verdict fired on the instance the trip most recently
  /// rebound onto. When it completes the re-adoption cycle the instance
  /// is refused: journaled + breadcrumbed here; the source refuses to
  /// fire it again and hands it back to the owner (`readoption-cycle`)
  /// if the owner still holds it. The ordinary drop path (owner seam,
  /// GPS-degrade, reattach) then runs unchanged.
  void _refuseIfReadoptionCycle(TripDropReason reason) {
    final refused = _adoptionGate.noteDrop();
    if (refused == null) return;
    final detail = '${reason.name} — same instance dropped '
        '${_adoptionGate.quickDropsToRefuse}× within '
        '${_adoptionGate.window.inSeconds}s of its rebind; waiting for '
        'a different one';
    _note(RecordingSessionEventKind.adoptionRefused, detail);
    BreadcrumbCollector.add('OBD2 recording: adoption refused', detail: detail);
  }
}
