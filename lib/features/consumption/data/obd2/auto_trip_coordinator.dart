import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/logging/error_logger.dart';
import 'auto_record_trace_log.dart';
import 'background_adapter_listener.dart';

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

/// Coordinates the hands-free auto-record state machine: BLE connect
/// → movement detected → start trip → BLE disconnect (debounced) →
/// stop and save (#1004 phases 3+4, Dart side only).
///
/// ## State machine (high level)
///
/// ```
///   ┌─────────┐  AdapterConnected(matching mac)  ┌────────────────┐
///   │  Idle   │ ───────────────────────────────► │ Watching speed │
///   └─────────┘                                  └────────┬───────┘
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
/// ## Why this is a separate class
///
/// The trip-recording provider already owns the OBD2 session lifecycle
/// (start, pause, resume, stop). The coordinator does NOT replace any
/// of that — it just observes adapter / movement signals and forwards
/// `startTrip` and `stopAndSaveAutomatic` calls into the existing
/// provider. Keeping it as a thin orchestrator means the manual flow
/// (the user explicitly tapping "Start trip") stays the simple,
/// well-tested code path; the auto path is purely additive.
///
/// ## Phase 2a vs phase 2b
///
/// This file ships with phase 2a — Dart scaffolding plus the
/// state-machine logic. The actual BLE auto-connect that produces
/// `AdapterConnected` / `AdapterDisconnected` events lives in the
/// native Android foreground service (phase 2b, NOT in this PR). Until
/// the bridge ships, [BackgroundAdapterListener] is wired to
/// [UnimplementedBackgroundAdapterListener] in production so the
/// coordinator never observes a live event.
class AutoTripCoordinator {
  /// Source of BLE connect / disconnect transitions. In production a
  /// native-bridge implementation; in tests the
  /// [FakeBackgroundAdapterListener].
  final BackgroundAdapterListener listener;

  /// Bridge to [TripRecording.startTrip]. Returns the outcome enum so
  /// the coordinator can stay silent when a trip is already active
  /// (e.g. the user manually tapped Start before driving away).
  ///
  /// Typed as `Future<Object?>` because [StartTripOutcome] lives in
  /// the providers layer and pulling it into `lib/features/consumption/data/`
  /// would invert the data → providers dependency direction. The
  /// coordinator only checks "did we successfully fire?" which is
  /// captured by the future completing without throwing.
  final Future<Object?> Function() startTrip;

  /// Bridge to [TripRecording.stopAndSaveAutomatic]. The thin wrapper
  /// added in phase 2a guarantees the `automatic: true` flag reaches
  /// `_saveToHistory`, which in turn bumps the launcher-icon badge so
  /// the user sees "something happened while I was driving" without
  /// opening the app.
  final Future<void> Function() stopAndSaveAutomatic;

  /// Stream of vehicle speed in km/h. The coordinator subscribes only
  /// while a connected adapter is reachable; closes the subscription
  /// on disconnect to avoid leaking listeners on the OBD2 transport
  /// when the user has parked. The stream may emit nothing at all
  /// (engine off, parked) — we just wait.
  final Stream<double> speedStream;

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

  AutoTripCoordinator({
    required this.listener,
    required this.startTrip,
    required this.stopAndSaveAutomatic,
    required this.speedStream,
    required this.config,
    int? consecutiveSamplesWindow,
    DateTime Function()? now,
  })  : consecutiveSamplesWindow = consecutiveSamplesWindow ?? 3,
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

  /// Stop watching, cancel any pending disconnect timer, and unwind
  /// every subscription. Safe to call when not started; safe to call
  /// twice. Does NOT save an in-flight trip — if one is running the
  /// caller (the manual flow's stop button, or the timer) is
  /// responsible for that, otherwise a developer-initiated tear-down
  /// (test, lifecycle reset) would silently auto-save.
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
        _onConnected();
      case AdapterDisconnected():
        AutoRecordTraceLog.add(
          AutoRecordEventKind.adapterDisconnected,
          mac: event.mac,
        );
        _onDisconnected();
    }
  }

  void _onConnected() {
    // Reconnect within the disconnect-save window: cancel the timer
    // and let the existing trip continue. Speed-watching is already
    // wired from the previous connect, but we re-attach defensively
    // in case the native bridge tore the OBD2 session down on
    // disconnect (which it does in production — the speed stream from
    // the previous session has stopped emitting).
    if (_disconnectTimer?.isActive ?? false) {
      _disconnectTimer!.cancel();
      _disconnectTimer = null;
      AutoRecordTraceLog.add(
        AutoRecordEventKind.disconnectTimerCancelled,
        mac: config.mac,
      );
    }
    _consecutiveSupraThreshold = 0;
    _speedSub?.cancel();
    _speedSub = speedStream.listen(_onSpeedSample);
  }

  void _onDisconnected() {
    // Stop counting movement samples — the OBD2 session is gone, no
    // more speed will arrive until the adapter reappears.
    _consecutiveSupraThreshold = 0;
    _speedSub?.cancel();
    _speedSub = null;
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
    try {
      final Object? outcome = await startTrip();
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
}
