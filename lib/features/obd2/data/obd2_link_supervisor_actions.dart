// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'obd2_link_supervisor.dart';

/// #3676 / #3035 — the supervisor's user-facing link ACTIONS (hard
/// reset, engine-off park, wake), split out of
/// `obd2_link_supervisor.dart` as a `part` extension to keep that file
/// under the #1680 length ratchet. Same library, so the extension
/// reaches the class's private state directly.
extension Obd2LinkSupervisorActions on Obd2LinkSupervisor {
  /// #3676 — user-initiated HARD reset of the whole link.
  ///
  /// 1. Best-effort `ATZ` on the live adapter — a full ELM327 chip
  ///    reset, the closest software equivalent to power-cycling the
  ///    dongle. Bounded and swallowed: a wedged/dead link cannot take
  ///    the command, and the fresh init after the redial begins with
  ///    ATZ anyway, so the recycle below is never blocked on it.
  /// 2. A fresh [connect]: clears the user park + the #3603 stand-down
  ///    escalation, recycles whatever half-dead service is still held
  ///    (full close, fresh socket — research rule 8) and dials anew
  ///    through the single-flight machinery.
  Future<Obd2Service?> resetLink() async {
    if (_disposed) return null;
    final live = _service;
    if (live != null) {
      try {
        await live
            .sendCommand('ATZ')
            .timeout(const Duration(seconds: 4));
        BreadcrumbCollector.add('obd2: adapter chip reset (ATZ) sent');
      } catch (e, st) {
        // Best-effort by contract — the recycle below is the real reset;
        // breadcrumb (not ERROR) since a wedged link failing ATZ is the
        // very condition the reset exists for.
        debugPrint('Obd2LinkSupervisor.resetLink: ATZ not deliverable: '
            '$e\n$st');
        BreadcrumbCollector.add(
          'obd2: adapter chip reset (ATZ) not deliverable',
          detail: e.runtimeType.toString(),
        );
      }
    }
    return connect();
  }

  /// Park the loop for a classified-silent bus (#3035). The next
  /// [wake] or [connect] re-arms.
  void noteEngineOff() {
    if (_disposed || _state.value == Obd2LinkState.userDisconnected) return;
    _cancelBackoffTimer();
    _service = null;
    _attemptCount = 0;
    _standDown.reset(); // #3603 — the park itself is the stand-down
    // #3534 — the checklist's "engine-off parks the loop" line item.
    BreadcrumbCollector.add('OBD2 link parked', detail: 'engine off');
    _setState(Obd2LinkState.engineOff);
  }

  /// Exit [Obd2LinkState.engineOff] (movement detected / app resumed)
  /// and dial. A no-op in every other state — waking a user-parked or
  /// already-live link must do nothing.
  /// #3642 — it ALSO breaks an active stand-down hold: the escalated
  /// holds (5 → 15 → 60 min) exist for a parked car, and this positive
  /// signal must dial now, not wait out a 60-minute timer.
  void wake() {
    if (_disposed) return;
    if (_state.value == Obd2LinkState.engineOff) {
      _standDown.reset(); // #3603 — movement is a positive signal
      _backoff.reset();
      _setState(Obd2LinkState.reconnecting);
      unawaited(_attempt(userInitiated: false));
      return;
    }
    if (_state.value == Obd2LinkState.reconnecting && _standDown.active) {
      _standDown.reset(); // #3642 — movement exits the escalated hold
      _backoff.reset();
      if (_attemptInFlight == null) {
        _cancelBackoffTimer();
        unawaited(_attempt(userInitiated: false));
      }
    }
  }
}
