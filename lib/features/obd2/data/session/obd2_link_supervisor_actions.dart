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

  /// A drop or session death reported from below (channels via
  /// [Obd2LinkDropSignal], the ElmSession dead event via the provider
  /// wiring). Starts the reconnect loop unless the user or the engine
  /// parked the supervisor.
  void notifyDrop(String reason) {
    if (_disposed) return;
    // #3756 — read the dying session's traffic BEFORE releasing it: a
    // link that completed real OBD commands is proof the link works,
    // not the zero-traffic corpse-adopt shape the flap counter targets.
    final trafficked = (_service?.sessionSuccessfulObdSends ?? 0) >=
        ReconnectStandDown.traffickedSendThreshold;
    _service = null;
    _dropTail(reason, trafficked: trafficked);
  }

  /// #3776 (Epic #3775) — a DELIBERATE death of a supervisor-owned link,
  /// reported by the layer that decided it (the trip's drop verdict, the
  /// self-test, a reset). Deliberate closes are suppressed from the
  /// transport drop signal by design (`_closing` latches, the ElmSession
  /// detach), so without this seam the supervisor keeps believing a dead
  /// socket is `ready` — the 2026-08-25 zero-engine-data field trip.
  ///
  /// Returns false when [service] is not the supervised link: the caller
  /// owns it and must close it itself. When it IS the supervised link:
  /// takes it out of circulation synchronously (state leaves `ready`
  /// before the first await, so no consumer adopts the corpse), closes
  /// the socket FIRST (frees the adapter's single RFCOMM channel before
  /// any redial), then runs the normal drop path.
  bool reportServiceDead(Obd2Service service, {required String reason}) {
    if (_disposed) return false;
    if (!identical(_service, service)) return false;
    final trafficked = service.sessionSuccessfulObdSends >=
        ReconnectStandDown.traffickedSendThreshold;
    _service = null;
    if (_mayAutoDial) _setState(Obd2LinkState.reconnecting);
    unawaited(() async {
      await _release(service, 'reportServiceDead');
      if (_disposed) return;
      _dropTail('external:$reason', trafficked: trafficked);
    }());
    return true;
  }

  /// #3777 (Epic #3775) — level-triggered corpse self-heal: the state
  /// says `ready` but the held service's transport is dead (a deliberate
  /// close that bypassed [reportServiceDead], or a suppressed platform
  /// teardown). Any consumer that finds itself dataless may call this at
  /// any time; a genuinely live link is a no-op.
  void ensureLive({String reason = 'ensureLive'}) {
    if (_disposed || _state.value != Obd2LinkState.ready) return;
    final svc = _service;
    if (svc == null) {
      // `ready` with no service is itself a corpse state — recycle.
      _dropTail('external:$reason-null-service', trafficked: false);
      return;
    }
    if (svc.isConnected) return;
    reportServiceDead(svc, reason: reason);
  }

  /// Shared tail of every drop path: stand-down bookkeeping, the #3534
  /// timeline breadcrumb, and the dial/backoff arming. The caller has
  /// already nulled `_service` (and captured its trafficked flag).
  void _dropTail(String reason, {required bool trafficked}) {
    if (!_mayAutoDial) {
      debugPrint('Obd2LinkSupervisor: drop ($reason) while parked '
          '(${_state.value}) — not dialing');
      return;
    }
    // #3859 (Epic #3855) — the car is ASLEEP (alternator voltage gone,
    // bus silent): this drop is the adapter going to sleep behind a
    // parked car, not a link to recover. Dialing now is what the field
    // storms were made of — 23 s RFCOMM timeouts against a dongle at
    // 3 mA, feeding the stand-down with failures that were never
    // failures. Park; the engine transition (rpm / voltage / ACL hint /
    // movement / resume) wakes the loop exactly as an engine-off
    // classification always did. This costs nothing on the reliability
    // floor: with no evidence the model is `unknown`, not `asleep`.
    if (_vehiclePower.asleep) {
      BreadcrumbCollector.add(
        'OBD2 link drop',
        detail: '$reason — car asleep (${_vehiclePower.detail}), '
            'parking without a dial (#3859)',
      );
      noteEngineOff();
      return;
    }
    _standDown.noteDrop(trafficked: trafficked); // #3603/#3756
    // #3534 — the per-drop timeline starts here (detect → dial →
    // recovered); the field-validation checklist reads this chain out
    // of the breadcrumb export after an induced-drop drive.
    BreadcrumbCollector.add('OBD2 link drop', detail: reason);
    _setState(Obd2LinkState.reconnecting);
    // Dial immediately on the first drop; backoff grows only on misses.
    if (_attemptInFlight == null && _backoffTimer == null) {
      if (_standDown.active && !inStandDown) {
        // #3756 — the streaks WOULD stand down, but fresh engine
        // evidence overrides: keep the fast ladder. One breadcrumb so
        // field exports show the suppression working.
        BreadcrumbCollector.add(
          'OBD2 stand-down suppressed',
          detail: 'engine evidence fresh — ${_standDown.detail}',
        );
      }
      if (inStandDown) {
        // #3603 — success-flap stand-down: the instant redial is what
        // burned 20 dial→adopt→drop cycles in the field. Hold the
        // storm cadence until a ready survives or the user acts.
        _armBackoffTimer();
        return;
      }
      _backoff.reset();
      unawaited(_attempt(userInitiated: false));
    }
  }
}
