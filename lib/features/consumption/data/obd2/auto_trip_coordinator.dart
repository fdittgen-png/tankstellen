import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/logging/error_logger.dart';
import 'auto_record_trace_log.dart';
import 'background_adapter_listener.dart';
import 'obd2_service.dart';
import 'obd2_speed_stream.dart';

/// Immutable snapshot of the auto-record fields off [VehicleProfile]
/// (#1004 phase 1) the coordinator needs to make decisions.
///
/// Modelled as a value object instead of holding the whole profile
/// because the coordinator doesn't care about brand, fuel type, or
/// odometer — only the MAC to filter on, the speed threshold to count
/// against, and the disconnect debounce window. Detaching from the
/// profile also makes this safe to copy into a future
/// background-isolate hand-off without dragging Hive types.
@immutable
class AutoRecordConfig {
  /// MAC address of the paired ELM327 adapter, sourced from
  /// `VehicleProfile.pairedAdapterMac`. The coordinator drops every
  /// event whose MAC does not equal this string — the multi-vehicle
  /// case (a household with two paired cars) only treats the active
  /// profile's adapter as live.
  final String mac;

  /// Speed (km/h) above which a sustained run kicks `startTrip()`.
  /// Sourced from `VehicleProfile.movementStartThresholdKmh`. Default
  /// in the profile is 5 km/h — low enough to catch pulling out of a
  /// parking spot, high enough to filter the brief speed spikes BLE
  /// adapters sometimes report on first connect.
  final double movementStartThresholdKmh;

  /// Debounce window before a disconnect triggers `stopAndSave`.
  /// Sourced from `VehicleProfile.disconnectSaveDelaySec`. Default in
  /// the profile is 60 s — long enough to absorb a tunnel or a
  /// parking-garage lift, short enough that the user sees a saved
  /// trip when they walk into the kitchen.
  final Duration disconnectSaveDelay;

  const AutoRecordConfig({
    required this.mac,
    required this.movementStartThresholdKmh,
    required this.disconnectSaveDelay,
  });
}

/// Callback that opens an [Obd2Service] for the configured MAC on
/// `AdapterConnected`. Returns null when the service can't be opened
/// (adapter already taken, scan timed out, init failed) so the
/// coordinator can stay idle until the next event without throwing.
///
/// Production wiring resolves to `Obd2ConnectionService.connectByMac`;
/// tests inject a fake that returns a stub service whose
/// `readSpeedKmh()` is wired to a queue.
typedef Obd2SessionOpener = Future<Obd2Service?> Function(String mac);

/// Factory that wraps an open [Obd2Service] in a polled km/h stream.
/// Test seam — production code uses [Obd2SpeedStream.new]; tests pass
/// a shorter `pollPeriod` so the timer fires inside `pumpEventQueue`.
typedef Obd2SpeedStreamFactory = Obd2SpeedStream Function(
  Obd2Service service, {
  String? mac,
});

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
  /// `lib/features/consumption/data/` would invert the data →
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

  /// Wraps an open service in an [Obd2SpeedStream]. Defaults to
  /// `Obd2SpeedStream.new` with the production poll period; tests
  /// inject a factory that returns a stream with a much shorter
  /// period so assertions run in microseconds.
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
  StreamSubscription<double>? _speedSub;
  Timer? _disconnectTimer;
  int _consecutiveSupraThreshold = 0;
  bool _started = false;
  bool _tripActive = false;

  /// Open OBD2 session held between `AdapterConnected` and either
  /// threshold-cross (handed to the recorder) or disconnect (closed
  /// here). Null when the coordinator is idle, when no opener was
  /// injected, or after a successful hand-off.
  Obd2Service? _session;

  AutoTripCoordinator({
    required this.listener,
    required this.startTrip,
    required this.stopAndSaveAutomatic,
    required this.config,
    this.sessionOpener,
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
  bool get hasPendingDisconnectTimer => _disconnectTimer?.isActive ?? false;

  /// Whether the coordinator currently holds an open OBD2 session.
  /// Test seam — flips to `false` after threshold-cross hand-off and
  /// after disconnect-without-trip teardown.
  @visibleForTesting
  bool get hasOpenSession => _session != null;

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
    _disconnectTimer?.cancel();
    _disconnectTimer = null;
    _consecutiveSupraThreshold = 0;
    await _adapterSub?.cancel();
    _adapterSub = null;
    await _speedSub?.cancel();
    _speedSub = null;
    // Idempotent — when `_session` is already null (e.g. handed off
    // to the recorder, or never opened) this is a no-op.
    await _closeSessionIfHeld();
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
    if (_disconnectTimer?.isActive ?? false) {
      _disconnectTimer!.cancel();
      _disconnectTimer = null;
      AutoRecordTraceLog.add(
        AutoRecordEventKind.disconnectTimerCancelled,
        mac: config.mac,
      );
    }
    _consecutiveSupraThreshold = 0;
    await _speedSub?.cancel();
    _speedSub = null;
    // Close any orphan session from a prior connect cycle defensively
    // — under normal flow `_session` is null here because the
    // disconnect path either handed it off (trip active) or closed
    // it (no trip). Double-close is cheap on a disconnected service.
    await _closeSessionIfHeld();

    // If a trip is already active (hand-off happened on a previous
    // connect), the recorder owns the session and we don't need to
    // open a new one — speed sampling is the recorder's job now.
    if (_tripActive) return;

    final opener = sessionOpener;
    if (opener == null) {
      // Test / legacy mode: no opener was wired. The coordinator's
      // pre-2b-3 contract was "speed comes from a stream injected at
      // construction time"; that field is gone, so without an opener
      // we simply have no speed source. Stay idle.
      return;
    }

    Obd2Service? service;
    try {
      service = await opener(config.mac);
    } catch (e, st) {
      service = null;
      AutoRecordTraceLog.add(
        AutoRecordEventKind.sessionOpenFailed,
        mac: config.mac,
        detail: 'exception=$e',
      );
      await errorLogger.log(
        ErrorLayer.background,
        e,
        st,
        context: <String, Object?>{
          'phase': 'AutoTripCoordinator.openSession',
          'mac': config.mac,
        },
      );
    }
    if (service == null) {
      AutoRecordTraceLog.add(
        AutoRecordEventKind.sessionOpenFailed,
        mac: config.mac,
        detail: 'opener returned null',
      );
      return;
    }

    // The connect cycle could have been cancelled between awaiting the
    // opener and now (stop() was called, or a disconnect already fired
    // and queued ahead of us). Drop the freshly-opened service rather
    // than wire a dangling subscription.
    if (!_started) {
      try {
        await service.disconnect();
      } catch (e, st) {
        debugPrint('AutoTripCoordinator: drop-orphan disconnect failed: $e\n$st');
      }
      return;
    }

    _session = service;
    final speedStream = speedStreamFactory(service, mac: config.mac);
    _speedSub = speedStream.stream.listen(_onSpeedSample);
  }

  Future<void> _onDisconnected() async {
    // Stop counting movement samples — the OBD2 session is gone, no
    // more speed will arrive until the adapter reappears.
    _consecutiveSupraThreshold = 0;
    await _speedSub?.cancel();
    _speedSub = null;
    // Close any orphan session if no trip is active. When a trip IS
    // active the recorder owns the session, so we leave its
    // pause-on-drop logic to handle teardown.
    if (!_tripActive) {
      await _closeSessionIfHeld();
    } else {
      // A trip is active: ownership has already moved to the recorder
      // on the threshold-cross hand-off, so `_session` should already
      // be null here. Defensive null-out covers the edge case where a
      // test bypasses the hand-off.
      _session = null;
    }
    // Arm the debounce. A reconnect within `disconnectSaveDelay`
    // cancels it and the trip carries on; otherwise the timer fires
    // and we save.
    _disconnectTimer?.cancel();
    _disconnectTimer = Timer(config.disconnectSaveDelay, _onSaveTimerFired);
    AutoRecordTraceLog.add(
      AutoRecordEventKind.disconnectTimerStarted,
      mac: config.mac,
      detail: 'delaySec=${config.disconnectSaveDelay.inSeconds} '
          'delayMs=${config.disconnectSaveDelay.inMilliseconds}',
    );
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
      unawaited(_invokeStartTrip(kmh));
    }
  }

  void _onSaveTimerFired() {
    final firedAt = _now();
    _disconnectTimer = null;
    AutoRecordTraceLog.add(
      AutoRecordEventKind.disconnectTimerFired,
      mac: config.mac,
      detail: 'tripActive=$_tripActive',
    );
    if (!_tripActive) {
      // Edge case: connect, no movement detected, disconnect, timer
      // fires. Nothing to save. Stay idle and let the next connect
      // start the cycle over.
      return;
    }
    _tripActive = false;
    unawaited(_invokeStopAndSave(firedAt));
  }

  Future<void> _invokeStartTrip(double observedSpeedKmh) async {
    final session = _session;
    if (session == null) {
      // Should not happen — `_onSpeedSample` only fires when the
      // speed stream is wired, and the speed stream only exists when
      // a session was opened. Trace it so a regression here is
      // visible rather than silent.
      AutoRecordTraceLog.add(
        AutoRecordEventKind.tripStartFailed,
        mac: config.mac,
        detail: 'no session held at threshold-cross',
      );
      _tripActive = false;
      return;
    }
    // Stop the coordinator's speed polling immediately — the recorder
    // is about to take ownership and will run its own per-PID
    // sampling. Holding the polling timer alongside would
    // double-issue PID 0x0D commands on the same transport.
    await _speedSub?.cancel();
    _speedSub = null;
    // Transfer ownership: null out the local pointer so neither
    // `stop()` nor `_onDisconnected()` will try to close a session
    // the recorder is using.
    _session = null;
    AutoRecordTraceLog.add(
      AutoRecordEventKind.sessionHandedOff,
      mac: config.mac,
      detail: 'observedSpeedKmh=${observedSpeedKmh.toStringAsFixed(1)}',
    );
    try {
      final Object? outcome = await startTrip(session);
      // The coordinator is decoupled from `StartTripOutcome` (it lives
      // in the providers layer). We classify outcomes by their string
      // form: enum `toString()` is `EnumName.value`, so the trailing
      // segment after the dot is the value name. `null` is the test
      // stub's signal for "no outcome to report" and is treated as
      // success — production wiring always returns a typed outcome.
      final String? outcomeName = outcome?.toString().split('.').last;
      if (outcome == null || outcomeName == 'started') {
        AutoRecordTraceLog.add(
          AutoRecordEventKind.tripStarted,
          mac: config.mac,
          detail: 'observedSpeedKmh=${observedSpeedKmh.toStringAsFixed(1)}',
        );
      } else {
        AutoRecordTraceLog.add(
          AutoRecordEventKind.tripStartFailed,
          mac: config.mac,
          detail: 'outcome=$outcomeName',
        );
      }
    } catch (e, st) {
      AutoRecordTraceLog.add(
        AutoRecordEventKind.tripStartFailed,
        mac: config.mac,
        detail: 'exception=$e',
      );
      await errorLogger.log(
        ErrorLayer.background,
        e,
        st,
        context: <String, Object?>{
          'phase': 'AutoTripCoordinator.startTrip',
          'mac': config.mac,
          'observedSpeedKmh': observedSpeedKmh,
        },
      );
    }
  }

  Future<void> _invokeStopAndSave(DateTime firedAt) async {
    try {
      await stopAndSaveAutomatic();
      AutoRecordTraceLog.add(
        AutoRecordEventKind.tripSavedAuto,
        mac: config.mac,
        detail: 'firedAt=${firedAt.toIso8601String()}',
      );
    } catch (e, st) {
      AutoRecordTraceLog.add(
        AutoRecordEventKind.tripSaveFailed,
        mac: config.mac,
        detail: 'exception=$e',
      );
      await errorLogger.log(
        ErrorLayer.background,
        e,
        st,
        context: <String, Object?>{
          'phase': 'AutoTripCoordinator.stopAndSaveAutomatic',
          'mac': config.mac,
          'firedAt': firedAt.toIso8601String(),
        },
      );
    }
  }

  /// Close [_session] if held, swallowing transport errors. Idempotent
  /// — `_session` is nulled out either way so a follow-up call is a
  /// no-op.
  Future<void> _closeSessionIfHeld() async {
    final held = _session;
    if (held == null) return;
    _session = null;
    try {
      await held.disconnect();
    } catch (e, st) {
      debugPrint('AutoTripCoordinator: session close failed: $e\n$st');
    }
  }
}
