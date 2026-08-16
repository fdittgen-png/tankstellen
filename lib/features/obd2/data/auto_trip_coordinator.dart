// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/logging/error_logger.dart';
import 'auto_record_trace_log.dart';
import 'auto_trip_contracts.dart';
import 'auto_trip_disconnect_debouncer.dart';
import 'auto_trip_session_opener.dart';
import 'background_adapter_listener.dart';
import 'obd2_link_supervisor.dart';
import 'obd2_service.dart';
import 'obd2_speed_stream.dart';

// #3727 — `AutoRecordConfig` and the opener/factory typedefs moved to
// `auto_trip_contracts.dart`; re-exported here so existing call sites
// keep compiling unchanged.
export 'auto_trip_contracts.dart';

/// Coordinates the hands-free auto-record state machine: BLE connect
/// → OBD2 session opens → speed PID polled → start trip on
/// threshold-cross → BLE disconnect (debounced) → stop and save
/// (#1004 phases 3+4).
///
/// ## State machine (high level)
///
/// ```
///   ┌─────────┐  AdapterConnected(matching mac)  ┌────────────────┐
///   │  Idle   │ ───────────────────────────────► │ Watching speed │
///   └─────────┘  + open OBD2 session             └────────┬───────┘
///         ▲                                               │
///         │ stopAndSaveAutomatic                          │ N consecutive
///         │ (timer fired)                                 │ supra-threshold
///         │                                               ▼ samples
///   ┌──────────────┐  AdapterDisconnected           ┌────────────┐
///   │ Awaiting save│ ◄──────────────────────────── │ Recording   │
///   │  (timer)     │                                │             │
///   └──────────────┘                                └────────────┘
///       │  AdapterConnected (within window) → cancel timer, back to Recording
/// ```
///
/// ## Speed source (#1004 phase 2b-3)
///
/// Phase 2b-3 swaps the GPS source for OBD2 PID 0x0D. On every
/// `AdapterConnected` the coordinator opens an [Obd2Service] via the
/// injected [Obd2SessionOpener] and wraps it in an [Obd2SpeedStream].
/// On threshold-cross we hand the live session to
/// `TripRecording.start(service)` — the recorder then owns the
/// session and does its own per-PID polling. Closing the loop here
/// means the auto-record flow no longer falls back to GPS for the
/// "did the car start moving?" decision and no longer leaves the
/// trip in the `needsPicker` outcome state.
///
/// ## Why this is a separate class
///
/// The trip-recording provider already owns the OBD2 session lifecycle
/// (start, pause, resume, stop). The coordinator does NOT replace any
/// of that — it just observes adapter / movement signals, holds the
/// open OBD2 session pre-trip, and forwards `startTrip` /
/// `stopAndSaveAutomatic` calls into the existing provider. Keeping
/// it as a thin orchestrator means the manual flow (the user
/// explicitly tapping "Start trip") stays the simple, well-tested
/// code path; the auto path is purely additive.
///
/// ## Decomposition (#3727)
///
/// The session-open/watch/hand-off tail lives in
/// [AutoTripSessionOpener] (which owns the held session + speed
/// subscription); the disconnect-debounce/save tail lives in
/// [AutoTripDisconnectDebouncer] (which owns the timer). This class
/// keeps the state machine flags and the adapter-event plumbing.
class AutoTripCoordinator {
  /// Source of BLE connect / disconnect transitions. In production a
  /// native-bridge implementation; in tests the
  /// [FakeBackgroundAdapterListener].
  final BackgroundAdapterListener listener;

  /// Bridge to `TripRecording.start(service, automatic: true)`. The
  /// coordinator transfers ownership of the open [Obd2Service] into
  /// this call on threshold-cross — the recorder's `stop()` is then
  /// responsible for closing the session.
  ///
  /// Typed as `Future<Object?>` because `StartTripOutcome` lives in
  /// the providers layer and pulling it into
  /// `lib/features/obd2/data/` would invert the data →
  /// providers dependency direction. The coordinator classifies the
  /// outcome string-form to distinguish "started" from
  /// "alreadyActive" / "needsPicker".
  final Future<Object?> Function(Obd2Service service) startTrip;

  /// Bridge to [TripRecording.stopAndSaveAutomatic]. The thin wrapper
  /// added in phase 2a guarantees the `automatic: true` flag reaches
  /// `_saveToHistory`, which in turn bumps the launcher-icon badge so
  /// the user sees "something happened while I was driving" without
  /// opening the app.
  final Future<void> Function() stopAndSaveAutomatic;

  /// Opens an OBD2 session for the configured MAC on connect (#1004
  /// phase 2b-3). When null the coordinator runs in legacy "no
  /// session" mode — useful for tests that only care about adapter
  /// events, not the speed source. Production callers always inject
  /// one.
  final Obd2SessionOpener? sessionOpener;

  /// Direct-connect opener for the foreground-active arming fallback
  /// (#2282 concern 1). Used by [armForegroundActive] to wake the
  /// paired adapter from the live engine while the app is in front,
  /// independent of the (currently-disabled) foreground service. Falls
  /// back to [sessionOpener] when null so existing wiring/tests behave
  /// unchanged.
  final Obd2ForegroundSessionOpener? foregroundSessionOpener;

  /// Wraps an open service in an [Obd2SpeedStream]. Defaults to
  /// `Obd2SpeedStream.new` with the production poll period; tests
  /// inject a factory that returns a stream with a much shorter
  /// period so assertions run in microseconds.
  /// #3527 — the one link supervisor. When present, the movement-watch
  /// session REUSES its live service (a manual recording shares the same
  /// link — no second RFCOMM session, the #3415 war's second front) and
  /// dials through its single-flight machinery otherwise. Optional so
  /// event-only tests keep constructing the coordinator bare.
  final Obd2LinkSupervisor? linkSupervisor;

  final Obd2SpeedStreamFactory speedStreamFactory;

  /// Snapshot of the auto-record fields off the active vehicle
  /// profile. Captured by value at construction time so a profile edit
  /// during a drive does not mutate the rule the in-flight state
  /// machine is following. Phase 2b will rebuild the coordinator on
  /// profile changes.
  final AutoRecordConfig config;

  /// Number of consecutive supra-threshold samples required to
  /// transition into "actually started driving". 3 is the default —
  /// noisy enough to filter a single-tick speed spike, fast enough to
  /// catch a real pull-out within a second of speed.
  final int consecutiveSamplesWindow;

  /// Test seam for `DateTime.now()` reads. The coordinator itself uses
  /// this only for diagnostic logging; the disconnect-save delay is
  /// driven by `Timer`, not by wall-clock arithmetic, so production
  /// timing is unaffected by injecting a fake clock.
  final DateTime Function() _now;

  StreamSubscription<BackgroundAdapterEvent>? _adapterSub;
  int _consecutiveSupraThreshold = 0;
  bool _started = false;
  bool _tripActive = false;

  /// Session-open/watch tail (#3727) — owns the held OBD2 session and
  /// the 1 Hz speed subscription between `AdapterConnected` and either
  /// threshold-cross (handed to the recorder) or disconnect.
  late final AutoTripSessionOpener _watch = AutoTripSessionOpener(
    mac: config.mac,
    linkSupervisor: linkSupervisor,
    speedStreamFactory: speedStreamFactory,
    startTrip: startTrip,
    onSpeedSample: _onSpeedSample,
    onLinkDrop: _onDisconnected,
    shouldAbandonOpen: () => !_started || _tripActive,
    clearTripActive: () => _tripActive = false,
  );

  /// Disconnect-debounce/save tail (#3727) — owns the disconnect-save
  /// timer and the automatic stop-and-save invocation.
  late final AutoTripDisconnectDebouncer _debouncer =
      AutoTripDisconnectDebouncer(
    mac: config.mac,
    disconnectSaveDelay: config.disconnectSaveDelay,
    stopAndSaveAutomatic: stopAndSaveAutomatic,
    now: _now,
    isTripActive: () => _tripActive,
    clearTripActive: () => _tripActive = false,
  );

  AutoTripCoordinator({
    required this.listener,
    required this.startTrip,
    required this.stopAndSaveAutomatic,
    required this.config,
    this.sessionOpener,
    this.foregroundSessionOpener,
    this.linkSupervisor,
    Obd2SpeedStreamFactory? speedStreamFactory,
    int? consecutiveSamplesWindow,
    DateTime Function()? now,
  })  : speedStreamFactory = speedStreamFactory ??
            ((Obd2Service service, {String? mac}) =>
                Obd2SpeedStream(service, mac: mac)),
        consecutiveSamplesWindow = consecutiveSamplesWindow ?? 3,
        _now = now ?? DateTime.now;

  /// Whether the coordinator is currently running. Mostly a test seam
  /// — the production flow always pairs `start` with a matching
  /// `stop` on tear-down, so the flag is invariant.
  @visibleForTesting
  bool get isStarted => _started;

  /// Whether a disconnect-save timer is currently armed. Exposed for
  /// tests that want to assert "reconnect cancelled the timer" without
  /// reaching into private state.
  @visibleForTesting
  bool get hasPendingDisconnectTimer => _debouncer.isPending;

  /// Whether the coordinator currently holds an open OBD2 session.
  /// Test seam — flips to `false` after threshold-cross hand-off and
  /// after disconnect-without-trip teardown.
  @visibleForTesting
  bool get hasOpenSession => _watch.hasOpenSession;

  /// Begin watching for BLE transitions. Idempotent — calling `start`
  /// while already started is a no-op (does not double-subscribe to
  /// `listener.events`, does not arm the bridge twice). The native
  /// bridge is armed via [BackgroundAdapterListener.start] before the
  /// stream subscription so any back-pressured replay of the most
  /// recent state lands on a live subscriber.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    AutoRecordTraceLog.add(
      AutoRecordEventKind.coordinatorStarted,
      mac: config.mac,
      detail: 'thresholdKmh=${config.movementStartThresholdKmh} '
          'delaySec=${config.disconnectSaveDelay.inSeconds} '
          'window=$consecutiveSamplesWindow',
    );
    try {
      await listener.start(mac: config.mac);
    } catch (e, st) {
      // The native bridge throwing here is a developer error in
      // production (see [UnimplementedBackgroundAdapterListener]); log
      // and bail so the coordinator stays in a clean idle state and
      // the next start attempt can re-arm.
      _started = false;
      AutoRecordTraceLog.add(
        AutoRecordEventKind.error,
        mac: config.mac,
        detail: 'start failed: $e',
      );
      await errorLogger.log(
        ErrorLayer.background,
        e,
        st,
        context: <String, Object?>{
          'phase': 'AutoTripCoordinator.start',
          'mac': config.mac,
        },
      );
      return;
    }
    _adapterSub = listener.events.listen(_onAdapterEvent);
  }

  /// Stop watching, cancel any pending disconnect timer, close any
  /// held OBD2 session, and unwind every subscription. Safe to call
  /// when not started; safe to call twice. Does NOT save an in-flight
  /// trip — if one is running the caller (the manual flow's stop
  /// button, or the timer) is responsible for that, otherwise a
  /// developer-initiated tear-down (test, lifecycle reset) would
  /// silently auto-save.
  Future<void> stop() async {
    if (!_started) {
      // Defensive: still unwind any timer/subs in case a test reaches
      // in directly. The flags below all start in the "nothing to do"
      // state on a fresh instance.
    }
    AutoRecordTraceLog.add(
      AutoRecordEventKind.coordinatorStopped,
      mac: config.mac,
    );
    _started = false;
    _debouncer.cancel();
    _consecutiveSupraThreshold = 0;
    await _adapterSub?.cancel();
    _adapterSub = null;
    await _watch.stopWatching();
    // Idempotent — when the held session is already null (e.g. handed
    // off to the recorder, or never opened) this is a no-op.
    await _watch.closeSessionIfHeld();
    try {
      await listener.stop();
    } catch (e, st) {
      // Native bridge teardown failure shouldn't propagate — the
      // coordinator is already idle from the Dart side's perspective.
      AutoRecordTraceLog.add(
        AutoRecordEventKind.error,
        mac: config.mac,
        detail: 'stop failed: $e',
      );
      await errorLogger.log(
        ErrorLayer.background,
        e,
        st,
        context: <String, Object?>{
          'phase': 'AutoTripCoordinator.stop',
          'mac': config.mac,
        },
      );
    }
  }

  void _onAdapterEvent(BackgroundAdapterEvent event) {
    // MAC filter — multi-vehicle support. A second paired car sharing
    // the same listener (phase 2b may centralise the bridge) would
    // emit events for an unrelated MAC; we drop them silently rather
    // than risk auto-recording the wrong car's drive.
    if (event.mac != config.mac) {
      AutoRecordTraceLog.add(
        switch (event) {
          AdapterConnected() =>
            AutoRecordEventKind.adapterConnectIgnoredOtherMac,
          AdapterDisconnected() =>
            AutoRecordEventKind.adapterDisconnectIgnoredOtherMac,
        },
        mac: event.mac,
      );
      return;
    }

    switch (event) {
      case AdapterConnected():
        AutoRecordTraceLog.add(
          AutoRecordEventKind.adapterConnected,
          mac: event.mac,
        );
        // Fire-and-forget — opening the OBD2 session is async (BLE
        // scan + ELM327 init can take seconds) but the caller of
        // `_onAdapterEvent` is a stream callback that must return
        // synchronously. Errors are funnelled through `errorLogger`
        // inside `_onConnected` so the subscription stays alive.
        unawaited(_onConnected());
      case AdapterDisconnected():
        AutoRecordTraceLog.add(
          AutoRecordEventKind.adapterDisconnected,
          mac: event.mac,
        );
        unawaited(_onDisconnected());
    }
  }

  Future<void> _onConnected() async {
    // Reconnect within the disconnect-save window: cancel the timer
    // and let the existing trip continue. We still re-open the OBD2
    // session because the previous one died with the disconnect.
    _debouncer.cancelIfPending();
    _consecutiveSupraThreshold = 0;
    await _watch.stopWatching();
    // Close any orphan session from a prior connect cycle defensively
    // — under normal flow the held session is null here because the
    // disconnect path either handed it off (trip active) or closed
    // it (no trip). Double-close is cheap on a disconnected service.
    await _watch.closeSessionIfHeld();

    // If a trip is already active (hand-off happened on a previous
    // connect), the recorder owns the session and we don't need to
    // open a new one — speed sampling is the recorder's job now.
    if (_tripActive) return;

    await _watch.openAndWatch(sessionOpener);
  }

  /// Foreground-active arming fallback (#2282 concern 1).
  ///
  /// While the app is resumed and auto-record is on, the disabled
  /// foreground service can't deliver the `AdapterConnected` that kicks
  /// the state machine — so the orchestrator calls this on every resume
  /// to open a DIRECT connect ([foregroundSessionOpener] →
  /// `connectByMacDirect`) to the paired adapter from the live engine.
  /// On success the coordinator watches the 1 Hz speed stream exactly as
  /// it would after a background `AdapterConnected`, so engine-start
  /// detection works TODAY even with the FGS gated to the backgrounded
  /// transition.
  ///
  /// Idempotent + cheap: a no-op when not started, when a trip is
  /// already active, or when a session is already held (a prior resume,
  /// or a background connect, already armed the speed watch). Failure to
  /// connect is logged and swallowed — the next resume retries.
  Future<void> armForegroundActive() async {
    if (!_started) return;
    // #3569 — self-heal a stranded watch before consulting the
    // skip-guard: if the held session's transport is dead (the drop
    // happened while foregrounded, so no platform event and possibly a
    // stream that neither errored nor closed), tear it down now so this
    // resume re-arms instead of skipping forever.
    final held = _watch.session;
    if (!_tripActive && held != null && !held.isConnected) {
      AutoRecordTraceLog.add(
        AutoRecordEventKind.foregroundArmAttempt,
        mac: config.mac,
        detail: 'held session is dead — tearing down before re-arm',
      );
      await _onDisconnected();
    }
    // Already watching (session held) or recording — nothing to arm.
    if (_tripActive || _watch.hasOpenSession || _watch.isWatching) {
      AutoRecordTraceLog.add(
        AutoRecordEventKind.foregroundArmSkipped,
        mac: config.mac,
        detail: 'tripActive=$_tripActive sessionHeld=${_watch.hasOpenSession} '
            'watching=${_watch.isWatching}',
      );
      return;
    }
    AutoRecordTraceLog.add(
      AutoRecordEventKind.foregroundArmAttempt,
      mac: config.mac,
    );
    // Prefer the direct opener; fall back to the scan opener so a caller
    // that only wired one still arms.
    await _watch.openAndWatch(foregroundSessionOpener ?? sessionOpener);
  }

  Future<void> _onDisconnected() async {
    // Stop counting movement samples — the OBD2 session is gone, no
    // more speed will arrive until the adapter reappears.
    _consecutiveSupraThreshold = 0;
    await _watch.stopWatching();
    // Close any orphan session if no trip is active. When a trip IS
    // active the recorder owns the session, so we leave its
    // pause-on-drop logic to handle teardown.
    if (!_tripActive) {
      await _watch.closeSessionIfHeld();
    } else {
      // A trip is active: ownership has already moved to the recorder
      // on the threshold-cross hand-off, so the held session should
      // already be null here. Defensive null-out covers the edge case
      // where a test bypasses the hand-off.
      _watch.takeSession();
    }
    _debouncer.arm();
  }

  void _onSpeedSample(double kmh) {
    if (_tripActive) return;
    if (kmh > config.movementStartThresholdKmh) {
      _consecutiveSupraThreshold++;
      AutoRecordTraceLog.add(
        AutoRecordEventKind.speedSampleSupraThreshold,
        mac: config.mac,
        detail:
            'speed=${kmh.toStringAsFixed(1)} kmh, '
            'count=$_consecutiveSupraThreshold/$consecutiveSamplesWindow',
      );
    } else {
      _consecutiveSupraThreshold = 0;
      AutoRecordTraceLog.add(
        AutoRecordEventKind.speedSampleSubThreshold,
        mac: config.mac,
        detail: 'speed=${kmh.toStringAsFixed(1)} kmh',
      );
    }
    if (_consecutiveSupraThreshold >= consecutiveSamplesWindow) {
      AutoRecordTraceLog.add(
        AutoRecordEventKind.thresholdCrossed,
        mac: config.mac,
        detail: 'speed=${kmh.toStringAsFixed(1)} kmh',
      );
      _tripActive = true;
      _consecutiveSupraThreshold = 0;
      // Fire-and-forget — the coordinator's contract is "we observed
      // movement, the provider knows what to do". Errors are logged
      // through `errorLogger` rather than re-thrown into the speed
      // stream, where they'd kill the subscription.
      unawaited(_watch.handOffAndStartTrip(kmh));
    }
  }
}
