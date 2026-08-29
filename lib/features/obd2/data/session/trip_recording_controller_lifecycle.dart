// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'trip_recording_controller.dart';

/// Public lifecycle surface of [TripRecordingController], extracted
/// from the controller file as a `part` mixin so it keeps
/// private-member access while the controller stays under the #1680
/// file-length cap (sanctioned #3760 decomposition — move-only,
/// behaviour preserved): the live / state streams, [currentState],
/// [pause] / [resume], the #2524 [replaceService] swap, [start] and
/// [stop].
mixin _TripRecordingLifecycle
    on _TripRecordingTransportGuard, _TripRecordingEmit, _TripRecordingSummary {
  /// Live metrics stream — subscribe to update the recording UI.
  Stream<TripLiveReading> get live => _liveController.stream;

  /// State-transition stream (#797 phase 1). Emits the new state on
  /// every controller-driven transition (start → recording, pause →
  /// paused, drop → pausedDueToDrop, resume → recording, grace →
  /// stopped, manual stop → stopped). Phase 2 binds this to the UI
  /// reaction; phase 1 just needs it observable.
  Stream<TripRecordingControllerState> get stateChanges =>
      _stateController.stream;

  /// Current logical state. Mirrors [stateChanges] for callers that
  /// want a pull-style read (widget tests, initial value).
  TripRecordingControllerState get currentState {
    // Check stopped first: an auto-finalised drop sets both
    // `_stopped = true` AND `_started = false`, so the order matters.
    if (_stopped) return TripRecordingControllerState.stopped;
    if (!_started) return TripRecordingControllerState.idle;
    if (_pausedDueToDrop) return TripRecordingControllerState.pausedDueToDrop;
    if (_paused) return TripRecordingControllerState.paused;
    // #2565 — degraded GPS-only: checked after the true-pause states but
    // is still an ACTIVE, recording state.
    if (_degradedGpsOnly) return TripRecordingControllerState.degradedGpsOnly;
    return TripRecordingControllerState.recording;
  }

  bool get isRecording =>
      (_started && !_paused && !_pausedDueToDrop) || _degradedGpsOnly;
  bool get isPaused => _paused || _pausedDueToDrop;
  bool get isPausedDueToDrop => _pausedDueToDrop;
  bool get isActive => _started;

  /// Pause the polling loop without tearing down the recorder. The
  /// scheduler is stopped (no wasted Bluetooth chatter while the user
  /// is looking at another screen) but the emit timer keeps ticking so
  /// a frozen `TripLiveReading` still flushes if UI subscribed late.
  /// [resume] restarts the scheduler. Safe to call when not recording
  /// — no-op.
  void pause() {
    if (!_started) return;
    if (_paused || _pausedDueToDrop) return;
    _paused = true;
    _scheduler?.stop();
    _emitState();
  }

  /// Resume a paused recording. Works from both user-pause and
  /// drop-pause states. Idempotent; no-op if not paused.
  void resume() {
    if (!_paused && !_pausedDueToDrop) return;
    if (_pausedDueToDrop) {
      // Cancel the grace timer + clear the drop-reaction reason.
      _droppedSession.cancelGrace();
      _pausedDueToDrop = false;
      // #1330 phase 3 — clear the silent-failure latch so a
      // post-resume stretch of nulls can fire again. Without this,
      // a user who resumes after a silent-failure drop and then hits
      // a fresh silent failure would never get a second snackbar.
      _dropDetector.reset();
      // Also tear down the auto-reconnect scanner (#797 phase 3) —
      // either we got here because the scanner fired its callback
      // (in which case it already stopped itself), or the user
      // tapped "Resume" manually on the pause banner before the
      // scanner reconnected. Either way, no scanner should survive
      // the resume transition.
      unawaited(_droppedSession.stopReconnectScanner());
      _droppedSession.clearPausedTripRow();
      // #2671 — a drop-pause gated the scheduler's dispatch (pauseScheduler);
      // the link is back, so re-open it + reset the per-PID failure streaks
      // before the timer resumes ticking.
      _scheduler?.resume();
    }
    _paused = false;
    // #3783 — a drop-resume runs on a freshly-redialed link whose
    // session may lack a negotiated protocol (warm cache ⇒ no 0100 at
    // connect); gate the cadence behind the quiet-window establishment.
    _startSchedulerWithProtocolGate('resume');
    _emitState();
  }

  /// Generous vs the ~2.5 s ISO 9141 5-baud init plus one #3575
  /// recovery pass.
  static const Duration _reconnectGrace = Duration(seconds: 8);

  void replaceService(Obd2Service service) {
    final old = _service;
    _service = service;
    // #3784 — the snapshot layer holds its own reference; without the
    // rebind its support gates kept evaluating the dead original.
    _liveSampleSnapshot.rebindService(service);
    // #3776 — arm the grace + clear the detector even on an IDENTICAL
    // swap: the old early-return skipped both, so a reattach that fired
    // on the same instance resumed polling with no reconnect grace and a
    // dirty error window — the first post-resume poll re-tripped a drop.
    _reconnectGraceUntil = _now().add(_reconnectGrace);
    // #2907 — the reconnected link is healthy: clear the drop detector's
    // error window (incl. any dead-transport short-circuits the [_runTransport]
    // gate logged against the OLD service) so the first poll on the new live
    // transport starts clean instead of re-tripping a drop. The scanner resume
    // path also resets it, but doing it AT the swap makes recovery robust to
    // swap-vs-resume call ordering.
    _dropDetector.reset();
    // #3776 — re-arm the #3602 staleness fence with a fresh window: the
    // latch only clears on a real parse, so a reconnect onto a link that
    // ALSO stays silent could never fire a second drop (the trip froze
    // unhandled). Anchoring "fresh" at the swap gives the new link the
    // full staleness window, after which the fence fires again and the
    // recovery cycle re-runs — bounded, convergent.
    _lastFreshEngineParseAt = _now();
    _staleEngineEscalated = false;
    _sessionJournal.add(
      RecordingSessionEventKind.serviceRebound,
      detail: identical(old, service) ? 'same instance' : null,
    );
    if (identical(old, service)) return;
    // #3776 — never close a supervisor-owned link (the owner keeps
    // supervising it; a deliberate close here would be invisible to it).
    if (_isLinkSupervised?.call(old) ?? false) return;
    // Tear down the abandoned link off the hot path. `disconnect()` is
    // idempotent and never throws for the typed-closed states, but guard
    // anyway — the old transport is already dead, so any error here is
    // expected and must not reach the user error log.
    unawaited(() async {
      try {
        await old.disconnect();
      } catch (e, st) {
        debugPrint('TripRecordingController.replaceService: '
            'old service disconnect failed (already dead) — $e\n$st');
      }
    }());
  }

  /// Start polling. Reads the odometer and VIN ONCE to pin trip
  /// identity; subsequent ticks are scheduled per-PID by
  /// [PidScheduler]. Safe to call multiple times — no-op when already
  /// recording.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    _stopped = false;
    _startedAt = _now();
    _sessionId = _startedAt!.toIso8601String();
    // #3797 — anchor the lifecycle timeline at t=0 BEFORE any OBD work,
    // so a session that dies during protocol establishment or the
    // identity reads still exports a timeline that shows how far it got.
    // (the auto-vs-manual flag rides the entry + the export's session
    // block, so the timeline needn't repeat it)
    _sessionJournal.start(at: _startedAt);
    // #3858 (Epic #3855) — the vehicle's power state decides how a
    // recording begins. EVs have no rpm to trust; tell the model.
    final power = Obd2VehiclePower.instance;
    power.evMode = _vehicle?.type == VehicleType.ev;
    if (_service.busProbe == Obd2BusProbeResult.probedSilent) {
      power.noteBusSilent();
      await _service.readBatteryVoltageV();
    }
    if (_service.busProbe == Obd2BusProbeResult.probedSilent &&
        !power.engineRunning) {
      // Engine off at start: GPS-first. NO `0100` (the quiet-window
      // establishment would re-send it into a silent bus — the #3575
      // livelock trigger), no odometer / VIN / fuel-type reads (they are
      // bus traffic too and would only time out). The scheduler is built
      // and wired but NOT started; the emit loop records GPS samples and
      // watches the adapter's voltage, and the engine transition runs
      // the whole deferred start — protocol, identity, polling.
      BreadcrumbCollector.add(
        'OBD2 recording: engine off at start — GPS-first, waiting for '
        'the engine (#3858)',
        detail: power.detail,
      );
      _scheduler = _schedulerOverride ?? _buildScheduler();
      _liveSampleSnapshot.subscribeAllTiers(_scheduler!);
      _engineOffSince = _startedAt;
      _droppedSession.enterEngineOffWait();
      _emitTimer = Timer.periodic(_pollInterval, (_) => _emit());
      _emitState();
      return;
    }
    // #3783 — establish the vehicle protocol BEFORE any OBD read: with a
    // warm supported-PID cache the connect ran no `0100`, so the session
    // may have NO negotiated protocol — the odometer/VIN reads below
    // would then trigger the ELM auto-search, time out, burn ElmSession
    // timeout strikes, and the poll cadence would livelock the search
    // (#3577) for the rest of the trip. One quiet window here fixes all
    // of them at once. No-op when the bus is already confirmed.
    await _ensureVehicleProtocol(where: 'trip-start');
    await _readTripIdentity();

    _scheduler = _schedulerOverride ?? _buildScheduler();
    _liveSampleSnapshot.subscribeAllTiers(_scheduler!);
    _scheduler!.start();

    _emitTimer = Timer.periodic(_pollInterval, (_) => _emit());
    _emitState();
  }

  /// #3382 — odometer + VIN (#814) reads time-bounded
  /// (obd2_trip_start_budgets) so a slow/silent adapter degrades them to
  /// null and the trip still starts. #3858 — runs once per session, at
  /// start on a live bus or at the engine transition of a recording that
  /// began with the engine off.
  @override
  Future<void> _readTripIdentity() async {
    if (_identityRead) return;
    _identityRead = true;
    _odometerStartKm = await boundedStartRead(
        _service.readOdometerKm(), kObd2TripStartOdometerBudget);
    _odometerLatestKm = _odometerStartKm;
    if (_odometerStartKm != null) {
      _odometerLatestAt = _now(); // #3877
      _distanceKmAtOdometerLatest = 0;
    }
    _vin = await boundedStartRead(
        readTripVinOnce(_service), kObd2TripStartVinBudget);
    // #3429 — one-shot ECU fuel-type read (PID 0x51), promoted from the
    // VIN auto-population flow: runtime truth beating the free-text profile
    // fuel key for this session's AFR/density (manual overrides still win).
    // Fire-and-forget: trip start never waits on this nicety — a silent
    // adapter degrades it to null after its bounded budget.
    unawaited(boundedStartRead(_service.readFuelType(),
            kObd2TripStartFuelTypeBudget)
        .then((k) => _liveSampleSnapshot.sessionFuelTypeKey = k));
  }

  /// #3862 — the driver answered "Keep" on the parked prompt: stay
  /// recording, do not ask again this session.
  void dismissParkedPrompt() {
    _parkedPromptDismissed = true;
    _parkedPromptDue = false;
    _emitState();
  }

  /// Stop the polling loop and return the accumulated summary.
  /// Idempotent — calling twice returns the same summary.
  ///
  /// The returned [TripSummary] carries the final [currentDistanceKm]
  /// (#800) — which prefers the real odometer delta over the recorder's
  /// integrated-speed number — and a [TripSummary.distanceSource] flag
  /// distinguishing the two. This lets the fill-up flow and analytics
  /// decide whether the km figure is ground truth or an estimate.
  /// #3795/#3797 — record HOW this session ended, before [stop] tears the
  /// controller down. Idempotent-by-first-writer: the first attribution
  /// wins, so a specific cause (a grace expiry, a watchdog abort) is never
  /// overwritten by the generic user-stop that may follow it.
  void noteTermination(TripTermination termination) {
    if (_termination != null) return;
    _termination = termination;
    _sessionJournal.add(
      RecordingSessionEventKind.ended,
      detail: termination.detail == null
          ? termination.reason.name
          : '${termination.reason.name}: ${termination.detail}',
    );
  }

  /// The recorded end of this session, or null while it is still running
  /// (or if it ended without any site attributing a cause).
  TripTermination? get termination => _termination;

  Future<TripSummary> stop({List<TripSample>? allSamples}) async {
    _allSamplesForFinalise = allSamples;
    // #1925 — finalise the opt-in OBD2 debug session so its summary
    // (duration, reconnects, data gaps) is complete for export.
    Obd2DebugSessionRecorder.endSession();
    _scheduler?.stop();
    _emitTimer?.cancel();
    _emitTimer = null;
    // #1904 / #2188 — tear down the grace timer + the pending silent-
    // reconnect window so neither can fire after the trip has stopped,
    // and stop the reconnect scanner.
    _droppedSession.cancelAllTimers();
    await _droppedSession.stopReconnectScanner();
    _started = false;
    _stopped = true;
    _pausedDueToDrop = false;
    // #2565 — clear the degrade flag so a stop while degraded finalises
    // cleanly (the drop-window GPS samples persist in the mixed trip).
    _degradedGpsOnly = false;
    _dropDetector.reset();
    _emitState();
    if (!_stateController.isClosed) {
      await _stateController.close();
    }
    if (!_liveController.isClosed) {
      await _liveController.close();
    }
    _distance.publishGateRejectionTally(); // #3253 — once-per-trip tally
    return _finaliseSummary();
  }

  @override
  void _emitState() {
    if (_stateController.isClosed) return;
    _stateController.add(currentState);
  }
}
