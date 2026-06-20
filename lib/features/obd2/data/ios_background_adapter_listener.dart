// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../../core/logging/error_logger.dart';
import '../../../core/telemetry/collectors/breadcrumb_collector.dart';
import 'background_adapter_listener.dart';
import 'ios_state_restoration_service.dart';

/// Produces the connected/disconnected stream for one peripheral id.
/// Production resolves to flutter_blue_plus's `connectionState`; tests
/// inject a controller-backed stream so no BLE stack is needed.
typedef IosAdapterConnectionStates = Stream<bool> Function(String deviceId);

/// iOS production [BackgroundAdapterListener] (#3167 — hands-free
/// auto-record Phase 3, Epic #3165).
///
/// Replaces the [UnimplementedBackgroundAdapterListener] the orchestrator
/// used to construct on iOS, closing the parity gap with Android's
/// foreground-service bridge. The iOS equivalent of "watch the paired
/// adapter in the background" is Core Bluetooth State Preservation and
/// Restoration, already wrapped by [IosStateRestorationService]:
///
/// 1. [start] opts the central manager into state restoration
///    ([IosStateRestorationService.initialize]) and queues the long-lived
///    `autoConnect` pending connect for the paired peripheral UUID
///    ([IosStateRestorationService.registerPersistedAdapter]). iOS retains
///    that pending connect across app termination; flutter_blue_plus also
///    passes `kCBConnectOptionEnableAutoReconnect` and tracks the device in
///    its auto-connect set, so a drop re-pends WITHOUT a re-register here.
/// 2. When the adapter powers up (driver enters the car), iOS completes
///    the connect — relaunching the app in the background if it was
///    terminated (the FBP plugin handles `willRestoreState` natively and
///    rehydrates the peripheral). Either way the device's
///    `connectionState` stream flips to connected.
/// 3. This listener maps that stream onto the same
///    [AdapterConnected] / [AdapterDisconnected] events the Android
///    bridge emits, so the [AutoTripCoordinator] state machine — session
///    open via the supervisor-admitted opener, speed watch, threshold
///    start, debounced disconnect save — runs UNCHANGED on iOS.
///
/// On a restoration relaunch the `connectionState` stream replays the
/// already-connected state to its first subscriber, so the coordinator is
/// armed immediately after [start] — that immediate session open is the
/// connect the trace stamps `Obd2ConnectOrigin.stateRestoration` (the
/// origin tag itself lives on the session-opener seam in
/// `auto_record_orchestrator_factories.dart`, not here).
///
/// ## Contracts
/// * The MAC slot of every event carries the `CBPeripheral.identifier`
///   UUID — on iOS `VehicleProfile.obd2AdapterMac` already stores that
///   UUID (the picker persists `deviceId`, see #2282 concern 3), so the
///   coordinator's MAC filter matches without translation.
/// * [start] / [stop] never throw — every restoration-service fault is
///   logged and the connection-state watch is still armed, because a
///   broken `setOptions` must not cost the user the foreground-arm path
///   that works without restoration.
/// * Late subscribers are tolerated per the [BackgroundAdapterListener]
///   contract: events emitted before the first subscriber attaches are
///   buffered and replayed on first listen.
class IosBackgroundAdapterListener implements BackgroundAdapterListener {
  IosBackgroundAdapterListener({
    required IosStateRestorationService restoration,
    IosAdapterConnectionStates? connectionStates,
    DateTime Function()? now,
  })  : _restoration = restoration,
        _connectionStates = connectionStates ?? _fbpConnectionStates,
        _now = now ?? DateTime.now;

  /// Production stream source: flutter_blue_plus's per-device
  /// `connectionState`, which replays the CURRENT state on listen —
  /// exactly what turns a background relaunch with an already-connected
  /// peripheral into an immediate [AdapterConnected].
  static Stream<bool> _fbpConnectionStates(String deviceId) {
    return BluetoothDevice.fromId(deviceId)
        .connectionState
        .map((s) => s == BluetoothConnectionState.connected);
  }

  final IosStateRestorationService _restoration;
  final IosAdapterConnectionStates _connectionStates;
  final DateTime Function() _now;

  late final StreamController<BackgroundAdapterEvent> _events =
      StreamController<BackgroundAdapterEvent>.broadcast(
    onListen: _flushPending,
  );

  /// Events emitted before the first subscriber attached (the
  /// coordinator subscribes only after `start` returns). Replayed on
  /// first listen so the initial restored-connect is never dropped.
  final List<BackgroundAdapterEvent> _pending = <BackgroundAdapterEvent>[];

  StreamSubscription<bool>? _stateSub;
  String? _watchedId;

  /// Last connected/disconnected value seen, used to (a) de-duplicate
  /// the replayed current state FBP emits to every new stream listener
  /// and (b) swallow the initial "disconnected" a normal foreground
  /// launch starts from (the coordinator must not arm a save timer for
  /// a car that was never connected this process).
  bool? _lastConnected;

  @override
  Stream<BackgroundAdapterEvent> get events => _events.stream;

  /// Arm the watch for [mac] (the paired peripheral UUID on iOS).
  /// Idempotent for the same id; a different id implicitly stops the
  /// previous watch. Never throws — restoration-service faults are
  /// logged and the connection-state watch is armed regardless.
  @override
  Future<void> start({required String mac}) async {
    if (_watchedId == mac) return;
    if (_watchedId != null) await stop();
    _watchedId = mac;
    // Opt into state restoration + queue the long-lived pending connect.
    // Both are guarded individually: a failed setOptions (restoration
    // unavailable) must not block the pending connect, and a failed
    // pending connect must not block the live connection-state watch.
    //
    // NOTE on #3185: registerPersistedAdapter only ISSUES a pending
    // connect — it never tears down a channel or stops a scan, so it
    // cannot disturb a supervisor-admitted attempt. The actual OBD2
    // session open this watch triggers enters through the coordinator's
    // session opener → `Obd2ConnectionService.connectByMac` → supervisor
    // admission, like every other requester.
    try {
      await _restoration.initialize();
    } catch (e, st) {
      await errorLogger.log(ErrorLayer.background, e, st, context: {
        'where': 'IosBackgroundAdapterListener.start initialize',
        'deviceId': mac,
      });
    }
    try {
      await _restoration.registerPersistedAdapter(mac);
    } catch (e, st) {
      await errorLogger.log(ErrorLayer.background, e, st, context: {
        'where': 'IosBackgroundAdapterListener.start registerPersistedAdapter',
        'deviceId': mac,
      });
    }
    _lastConnected = null;
    _stateSub = _connectionStates(mac).listen(
      _onConnectionState,
      onError: (Object e, StackTrace st) {
        // A stream error must not kill the watch silently — log it; the
        // subscription itself stays alive (cancelOnError defaults false).
        unawaited(errorLogger.log(ErrorLayer.background, e, st, context: {
          'where': 'IosBackgroundAdapterListener connectionState error',
          'deviceId': mac,
        }));
      },
    );
  }

  void _onConnectionState(bool connected) {
    final id = _watchedId;
    if (id == null) return;
    if (_lastConnected == connected) return; // de-dupe replays
    final isFirst = _lastConnected == null;
    _lastConnected = connected;
    if (isFirst && !connected) {
      // The replayed initial state on a normal launch is "disconnected"
      // — not a transition, nothing for the coordinator to debounce.
      return;
    }
    _emit(connected
        ? AdapterConnected(mac: id, at: _now())
        : AdapterDisconnected(mac: id, at: _now()));
    // #3242 — FBP's `disconnect()` (our session teardown ALWAYS calls it:
    // channel close, pre-connect stale-GATT teardown, coordinator session
    // close) removes the remoteId from FBP's auto-connect set, and the
    // background re-pend is gated on set membership — so the #3167 hands-free
    // pending connect would survive only until the FIRST trip of each process
    // ends, with no trace/UI signal. Re-issue the pend on every real
    // disconnect so the NEXT adapter power-on still relaunches the app.
    if (!connected) unawaited(_repend(id));
  }

  /// #3242 — re-arm the OS-level pending connect after a disconnect cleared it.
  /// `registerPersistedAdapter` only ISSUES a pending connect (it never tears a
  /// channel down or stops a scan), so re-issuing it is idempotent + safe. Best
  /// effort: a restoration-service fault is logged, never thrown.
  Future<void> _repend(String mac) async {
    try {
      await _restoration.registerPersistedAdapter(mac);
      BreadcrumbCollector.add('obd2-restoration: restoration-repend',
          detail: 'mac=$mac');
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.background, e, st, context: {
        'where': 'IosBackgroundAdapterListener._repend',
        'deviceId': mac,
      }));
    }
  }

  void _emit(BackgroundAdapterEvent event) {
    if (_events.isClosed) return;
    if (_events.hasListener) {
      _events.add(event);
    } else {
      _pending.add(event);
    }
  }

  void _flushPending() {
    if (_pending.isEmpty) return;
    // Microtask: the first subscriber is fully registered by then, so
    // the replay is guaranteed to be delivered to it.
    scheduleMicrotask(() {
      final replay = List<BackgroundAdapterEvent>.of(_pending);
      _pending.clear();
      for (final event in replay) {
        if (!_events.isClosed) _events.add(event);
      }
    });
  }

  /// Stop watching. Cancels the connection-state subscription; the
  /// pending OS-level connect stays registered on purpose (tearing it
  /// down belongs to whoever owns the BLE link). Safe to call when no
  /// watch is active; never throws.
  @override
  Future<void> stop() async {
    _watchedId = null;
    _lastConnected = null;
    try {
      await _stateSub?.cancel();
    } catch (e, st) {
      await errorLogger.log(ErrorLayer.background, e, st, context: const {
        'where': 'IosBackgroundAdapterListener.stop',
      });
    } finally {
      _stateSub = null;
    }
  }

  /// Close the event stream. Test/teardown helper — production drops the
  /// listener with the coordinator entry and lets GC collect it, the same
  /// lifecycle the Android bridge follows. Safe to call more than once.
  Future<void> dispose() async {
    await stop();
    if (!_events.isClosed) {
      await _events.close();
    }
  }
}
