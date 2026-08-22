// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'trip_recording_controller.dart';

/// Scheduler wiring + drop-detection transport guard for
/// [TripRecordingController], extracted from the controller file as a
/// `part` mixin so it keeps private-member access while the controller
/// stays under the #1680 file-length cap (sanctioned #3760 decomposition
/// — move-only, behaviour preserved): the [PidScheduler] construction,
/// the #3575 quiet-window protocol recovery, the #797/#1904 retrying
/// transport wrapper, and the silent-failure parse observer.
mixin _TripRecordingTransportGuard on _TripRecordingSessionState {
  /// Swap the recording loop onto a freshly-reconnected [Obd2Service]
  /// (#2524).
  ///
  /// An in-trip auto-reconnect ([ReconnectConnector]) builds a BRAND-NEW
  /// service + transport for the recovered link. [_runTransport] and
  /// [refreshOdometer] dereference [_service] at call time, so until this
  /// runs the scheduler keeps polling the DEAD old transport — every read
  /// times out and the rest of the drive records nothing. Pointing
  /// [_service] at the live service fixes that for every subsequent poll.
  ///
  /// The OLD service is torn down ([Obd2Service.disconnect]) so its
  /// channel closes and any command stranded in its transport's `_pending`
  /// is failed cleanly via the transport's `_failPending` — otherwise the
  /// abandoned half-dead instance leaks its subscription and a stranded
  /// pending could later trip the concurrent-sendCommand guard. A no-op
  /// when [service] is already the current one (idempotent / defensive).
  /// Best-effort: a disconnect failure on the already-dead old link must
  /// never derail the just-recovered recording, so it is swallowed to a
  /// breadcrumb.
  /// #3625 — until this instant, transport errors and null parses do
  /// NOT count toward a drop. A freshly adopted reconnect session on a
  /// K-line car (ISO 9141, 10.4 kbaud) performs its slow bus init on
  /// the FIRST poll; without the grace the drop detector declared a
  /// silent failure before the #3575 quiet-window protocol recovery
  /// could run, tearing the session down and producing the field flap:
  /// dial(≈4.7 s) → adopt → first-poll fail → drop → redial, forever —
  /// a whole trip recorded with zero engine data.
  DateTime? _reconnectGraceUntil;

  // ---------------------------------------------------------------------------
  // Scheduler wiring
  // ---------------------------------------------------------------------------

  PidScheduler _buildScheduler() {
    return PidScheduler(
      transport: _runTransport,
      tickRate: _schedulerTickRate,
      clock: _now,
      onNoProtocolEpisode: () => unawaited(_recoverVehicleProtocol()),
    );
  }

  /// #3575 — quiet-window protocol recovery for the UNABLE-TO-CONNECT
  /// livelock: the scheduler signalled a sustained no-protocol reply
  /// streak (adapter connected before ignition-on → failed auto search →
  /// every command errs instantly, and the polling cadence keeps
  /// interrupting a restarted search). Pause polling so the `0100`
  /// search finally gets an uninterrupted window, re-run discovery, and
  /// resume. Throttled to one attempt per [_protocolRecoveryInterval] —
  /// the scheduler episode re-signals while the condition persists, so a
  /// car whose engine starts mid-trip recovers within a minute instead
  /// of erring for the whole drive (field log 2026-07-13, 21 min of
  /// 100% err at 0% completeness).
  bool _protocolRecoveryInFlight = false;
  DateTime? _lastProtocolRecoveryAt;
  static const Duration _protocolRecoveryInterval = Duration(seconds: 45);

  Future<void> _recoverVehicleProtocol() async {
    if (_protocolRecoveryInFlight) return;
    final now = _now();
    final last = _lastProtocolRecoveryAt;
    if (last != null && now.difference(last) < _protocolRecoveryInterval) {
      return;
    }
    _lastProtocolRecoveryAt = now;
    _protocolRecoveryInFlight = true;
    final scheduler = _scheduler;
    scheduler?.pause();
    try {
      final recovered = await _service.recoverVehicleProtocol();
      BreadcrumbCollector.add(
        'OBD2 recording: no-protocol episode (#3575)',
        detail: recovered
            ? 'recovered — polling resumes with a live protocol'
            : 'still no protocol — retrying in ${_protocolRecoveryInterval.inSeconds}s',
      );
    } finally {
      _protocolRecoveryInFlight = false;
      scheduler?.resume();
    }
  }

  /// Wrap [Obd2Service.sendCommand] with drop-detection bookkeeping
  /// (#797 phase 1). Successful reads reset the consecutive-error
  /// counter; repeated failures in a short window flip the controller
  /// into [TripRecordingControllerState.pausedDueToDrop].
  ///
  /// The scheduler itself still swallows the exception (it logs and
  /// marks `lastReadAt` to keep other PIDs from starving) — we rethrow
  /// because throwing keeps the scheduler's "something went wrong"
  /// branch in play, but we *also* short-circuit by stopping the
  /// scheduler the moment we cross the threshold.
  Future<String> _runTransport(String command) async {
    try {
      final response = await _sendOrShortCircuit(command);
      // A clean read is the only signal strong enough to clear the
      // error window; ELM327 NO DATA responses come back via the
      // response string, not an exception.
      _dropDetector.registerSuccess();
      return response;
    } catch (_) {
      // #1904 — one silent retry before a transport error counts
      // toward a drop. Bluetooth links hiccup briefly (a single lost
      // write, a momentary RF collision); retrying once after a short
      // pause absorbs that common transient case so it never reaches
      // the drop detector. Only a failure that survives the retry is
      // a real drop signal.
      await Future<void>.delayed(_transportRetryDelay);
      try {
        final response = await _sendOrShortCircuit(command);
        _dropDetector.registerSuccess();
        return response;
      // #3164 — kept: `rethrow` preserves the original stack.
      } catch (e, st) { // ignore: unused_catch_stack
        _registerTransportError(e);
        rethrow;
      }
    }
  }

  /// #2907 — never write into a DEAD transport. A drop disconnects the service
  /// (`isConnected == false`); the reconnect [replaceService]-swaps a fresh
  /// one. If a poll dereferences a service that is no longer connected — the
  /// orphaned-reconnect window, or a swap that hasn't landed — fail FAST with
  /// a recoverable typed disconnect instead of writing into a closed socket
  /// and waiting out the full per-command read timeout. Throwing here routes
  /// through [_runTransport]'s existing retry → [_registerTransportError]
  /// path unchanged, so the drop threshold + timing behaviour is identical to
  /// a real dead-link `sendCommand` throw — it just never spins the radio.
  Future<String> _sendOrShortCircuit(String command) {
    if (!_service.isConnected) {
      throw const Obd2DisconnectedException(
        'TripRecordingController: transport not connected — link is recovering',
      );
    }
    return _service.sendCommand(command);
  }

  /// #1904 — pause before the single transport retry, giving the
  /// Bluetooth link a moment to settle rather than hammering it.
  static const Duration _transportRetryDelay = Duration(milliseconds: 150);

  /// Funnel a transport error through the drop detector and react to
  /// its verdict (#797 phase 1). The lifecycle guard stays here — the
  /// detector counts, the controller owns the "are we already
  /// pausing?" state.
  void _registerTransportError(Object error) {
    if (_pausedDueToDrop || _stopped) return;
    // #3625 — inside the post-reconnect grace the fresh session is
    // still bringing the bus up; failures feed the #3575 protocol
    // episode instead of the drop verdict.
    if (_inReconnectGrace) return;
    if (_dropDetector.registerTransportError(error)) {
      _droppedSession.handleDrop();
    }
  }

  bool get _inReconnectGrace {
    final until = _reconnectGraceUntil;
    return until != null && _now().isBefore(until);
  }

  /// Bookkeeping for the silent-failure heuristic (#1330 phase 3).
  ///
  /// Called from every high-priority PID callback right after the
  /// parser returned. A null parse increments the consecutive-null
  /// counter; ANY non-null parse resets it to zero — even from a
  /// different PID, because we're trying to detect "ECU is dead",
  /// not "this specific PID is unsupported".
  ///
  /// Once the counter reaches the silent-failure threshold AND the
  /// transport-error drop hasn't already fired, [_onSilentFailure]
  /// drives the same pause-with-grace path that the drop-recovery
  /// manager runs for transport errors, but stamps a
  /// [TripDropReason.silentFailure] reason so the UI can surface a
  /// different message.
  void _observeHighPriorityParse(Object? parsedValue) {
    if (parsedValue != null) {
      // ANY successful high-priority parse clears the window — we're
      // detecting "ECU is dead", not "this one PID is unsupported".
      _lastFreshEngineParseAt = _now(); // #3602 — the staleness fence anchor
      _staleEngineEscalated = false;
      _dropDetector.observeHighPriorityParse(parsedValue);
      return;
    }
    // The transport-error drop already paused us — don't let a stretch
    // of nulls double-fire into a second drop. The lifecycle guard
    // stays here; the detector just counts.
    if (_pausedDueToDrop || _stopped) return;
    // #3625 — bus-init nulls during the post-reconnect grace are the
    // K-line waking up, not a dead ECU.
    if (_inReconnectGrace) return;
    if (_dropDetector.observeHighPriorityParse(parsedValue)) {
      _onSilentFailure();
    }
  }

  /// Silent-failure handler (#1330 phase 3). Fired exactly once per
  /// recording session when the drop detector's consecutive-null
  /// counter crosses the threshold. Drives the same pause-with-grace
  /// recovery the drop-recovery manager runs for transport errors, but
  /// tags the drop with [TripDropReason.silentFailure] so the UI
  /// surfaces "OBD2 adapter connected but not returning data" instead
  /// of "OBD2 connection lost".
  void _onSilentFailure() {
    debugPrint(
      'TripRecordingController: silent-failure detected — '
      '${_dropDetector.consecutiveNullReads} consecutive null PID parses',
    );
    _droppedSession.handleDrop(reason: TripDropReason.silentFailure);
  }
}
