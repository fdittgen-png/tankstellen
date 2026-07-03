// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/data/storage_repository.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/telemetry/collectors/breadcrumb_collector.dart';
import '../data/last_good_adapter_store.dart';
import '../data/obd2_comm_diagnostics.dart';
import '../data/obd2_connect_trace.dart';
import '../data/obd2_connect_trace_log.dart';
import '../data/obd2_connection_service.dart';
import '../data/obd2_link_arbiter.dart';
import '../data/obd2_reconnect_controller.dart';
import '../data/obd2_service.dart';
import '../data/obd2_wedge_detector.dart';
import '../data/obd2_wedge_recovery.dart';
import 'obd2_connection_state_provider.dart';

part 'obd2_reconnect_provider.g.dart';

/// Local (NON-synced) auto-pin store for the last-good adapter (#3019 /
/// Epic #3013 phase 3), backed by the Hive `settings` box.
@Riverpod(keepAlive: true)
LastGoodAdapterStore lastGoodAdapterStore(Ref ref) =>
    LastGoodAdapterStore(ref.watch(settingsStorageProvider));

/// App-wide owner of the trip-INDEPENDENT auto-reconnect controller (#3019 /
/// Epic #3013 phase 3).
///
/// This is the decoupling the Epic asks for: the in-trip [DroppedSessionManager]
/// (#2188) only runs while a recording is active, so a drop while idle / between
/// trips never re-establishes. This notifier owns an [Obd2ReconnectController]
/// whose loop is driven purely by the connection lifecycle:
///   * drops reach it EXCLUSIVELY through its registered [Obd2LinkArbiter]
///     idle policy (#3420) — the arbiter is the sole consumer of the
///     proactive link-drop signal, so this loop runs only while no lease
///     holds the link (#3424 deleted the bypassing `reportDropped` seam);
///   * each attempt tries the auto-pinned adapter first (transport-correct
///     direct connect, #3016), then a re-scan fallback;
///   * after the bound it stops in [Obd2ReconnectState.terminalFailed] and the
///     UI shows a "tap to retry" affordance wired to [retry].
///
/// On a successful (re)connect it republishes the live state into the app-wide
/// [Obd2ConnectionStatus] dot so every screen reflects the recovered link.
@Riverpod(keepAlive: true)
class Obd2Reconnect extends _$Obd2Reconnect {
  Obd2ReconnectController? _controller;
  Obd2LinkIdleRegistration? _idleReg;

  @override
  Obd2ReconnectState build() {
    final controller = _buildController();
    _controller = controller;
    // #3420 — register as the arbiter's IDLE policy. The arbiter is the sole
    // consumer of the proactive link-drop signal: a drop reaches this loop
    // ONLY while no lease (recording / auto-record / interactive) holds the
    // link — the #3013 "idle / between trips" charter by construction, where
    // the #3386 latch left the auto-record ↔ #3019 pair ungated (#3415).
    // onStandDown fires the instant ANY lease is granted, so an in-flight
    // idle loop stops before it can tear down the new owner's socket.
    // #3346 — the drop reason/transport still reach the episode breadcrumb.
    _idleReg = Obd2LinkArbiter.instance.registerIdlePolicy(
      onDrop: (e) => _controller?.notifyDropped(
        reason: e.reason,
        transportKind: e.transportKind,
        mac: e.mac,
      ),
      onStandDown: () => _controller?.stop(),
    );
    // #3422 — wedge-recovery wiring. The detector latches LinkWedged after
    // N consecutive exhausted Classic ladders (noted at the ClassicElmChannel
    // funnel) and kicks the escalation ladder; the ladder's rungs verify with
    // ONE bounded pinned connect via [_wedgeProbe]. Both trace into the same
    // exported breadcrumb channel as the reconnect episodes (#3346).
    final recovery = Obd2WedgeRecovery.instance;
    recovery.onTrace = _trace;
    recovery.probeConnect = _wedgeProbe;
    Obd2WedgeDetector.instance.onWedged = (mac) {
      _trace('wedge-detected', {'mac': mac});
      unawaited(recovery.start(mac));
    };
    ref.onDispose(() {
      Obd2WedgeDetector.instance.onWedged = null;
      recovery.probeConnect = null;
      recovery.onTrace = null;
      _idleReg?.dispose();
      _idleReg = null;
      controller.dispose();
      _controller = null;
    });
    return controller.state;
  }

  /// #3422 — the recovery ladder's single bounded verification connect: a
  /// pinned-style DIRECT Classic connect to the wedged [mac] (every other
  /// reconnect policy is standing down, so this is the only connect
  /// traffic). `true` when the adapter answered — including a #3035
  /// engine-off probe (the adapter is back; the ECU is just silent), which
  /// is exactly the wedge-cleared condition. On a full success the recovered
  /// link is republished into the app-wide status dot via [_onResult].
  Future<bool> _wedgeProbe(String mac) async {
    try {
      final svc = await Obd2ConnectTraceLog.runWithOrigin(
        Obd2ConnectOrigin.liveReconnect,
        () => ref.read(obd2ConnectionProvider).connectByMacClassicDirect(mac),
        transportDecisionReason: 'wedge-recovery-probe',
      );
      if (svc == null) return false;
      final result = _onResult(svc);
      if (result == Obd2ReconnectAttemptResult.connected) {
        _controller?.notifyConnected();
      }
      return result == Obd2ReconnectAttemptResult.connected ||
          result == Obd2ReconnectAttemptResult.engineOff;
    } catch (e, st) {
      _logSeam('wedge probe', e, st);
      return false;
    }
  }

  Obd2ReconnectController _buildController() {
    // The app shell watches this provider, so a failed dependency read (a
    // not-yet-bootstrapped Bluetooth graph / settings box, or a widget-test
    // scope that doesn't override them) must NEVER crash the shell. Guard the
    // reads and degrade to a no-op connector — the state machine still works
    // (it just can't connect), and the surface stays inert. Best-effort: the
    // failure is logged once at build.
    Obd2ConnectionService? connection;
    LastGoodAdapterStore? pinStore;
    try {
      connection = ref.read(obd2ConnectionProvider);
      pinStore = ref.read(lastGoodAdapterStoreProvider);
    } catch (e, st) {
      _logSeam('build dependency read', e, st);
    }
    final resolvedStore =
        pinStore ?? const LastGoodAdapterStore(_NullSettingsStorage());
    final controller = Obd2ReconnectController(
      pinStore: resolvedStore,
      pinnedConnect: connection == null
          ? (_) async => Obd2ReconnectAttemptResult.notFound
          : (pinned) => _connectPinned(connection!, pinned),
      rescanConnect: connection == null
          ? (_) async => Obd2ReconnectAttemptResult.notFound
          : (pinned) => _connectRescan(connection!, pinned),
    );
    // Republish every transition into the Riverpod state so the UI rebuilds.
    controller.onState = (s) => state = s;
    // #3346 — route the reconnect-EPISODE breadcrumbs (drop reason, each
    // attempt's path/outcome/latency, backoff, terminal) into the exported
    // channels: the always-on BreadcrumbCollector (rides every error trace)
    // + the developer-mode comm-diagnostics reconnect reservoir.
    controller.onTrace = _trace;
    return controller;
  }

  /// #3346 — fan one reconnect-episode event out to the exported telemetry
  /// channels. Best-effort: the controller already guards this against throws.
  void _trace(String event, Map<String, Object?> data) {
    BreadcrumbCollector.add('obd2-reconnect: $event', detail: _fmt(data));
    // Feed the gated comm-diagnostics reconnect counters so the developer-mode
    // health screen's reservoir reflects real reconnect activity, not just
    // first-connects.
    final diag = Obd2CommDiagnostics.instance;
    if (!diag.enabled) return;
    switch (event) {
      case 'attempt-start':
        diag.noteConnectionEvent(attempt: true);
      case 'connected':
        final ms = data['episodeMs'];
        diag.noteConnectionEvent(
          success: true,
          visibleReconnect: true,
          timeToReconnectMs: ms is int ? ms : null,
        );
      case 'terminal-failed':
        diag.noteConnectionEvent(failureReason: 'reconnect-exhausted');
      case 'terminal-engine-off':
        diag.noteConnectionEvent(failureReason: 'reconnect-engine-off');
    }
  }

  /// Render a flat breadcrumb map as a compact `k=v` string (stable key
  /// order is not required — a field reader scans for the tokens).
  static String _fmt(Map<String, Object?> data) =>
      data.entries.map((e) => '${e.key}=${e.value}').join(' ');

  // #3424 — the `reportDropped` / `reportConnected` / `stop` entry points
  // were deleted: no production caller remained once the arbiter became the
  // sole drop router (#3420) — drops arrive via the idle-policy registration
  // in [build], connect/stand-down via `onStandDown`. Regression lock:
  // test/features/obd2/obd2_link_authority_races_test.dart (races 1–3).

  /// User tapped the terminal "tap to retry" affordance — restart the loop.
  void retry() => _controller?.retry();

  /// Pinned fast path: a transport-correct DIRECT connect, no scan (#3016).
  /// A Classic adapter goes over RFCOMM; BLE / unknown keep the direct-GATT
  /// path. A connect failure is caught + classified to `failed` here (the
  /// controller's own guard is a second backstop), so the bounded loop keeps
  /// its backoff schedule rather than surfacing a raw error.
  Future<Obd2ReconnectAttemptResult> _connectPinned(
    Obd2ConnectionService connection,
    LastGoodAdapter pinned,
  ) async {
    try {
      // #3346 — stamp the per-attempt connect trace as a liveReconnect (not a
      // firstConnect), so the persisted, exported connect-trace ring tells a
      // silent mid-drive reconnect apart from a user-driven first connect.
      final svc = await Obd2ConnectTraceLog.runWithOrigin(
        Obd2ConnectOrigin.liveReconnect,
        () => pinned.isClassic
            ? connection.connectByMacClassicDirect(pinned.mac)
            : connection.connectByMacDirect(pinned.mac, fallbackToScan: false),
        transportDecisionReason:
            pinned.isClassic ? 'reconnect-pinned-classic' : 'reconnect-pinned-ble',
      );
      return _onResult(svc);
    } catch (e, st) {
      _logSeam('pinned', e, st);
      return Obd2ReconnectAttemptResult.failed;
    }
  }

  /// Re-scan fallback: scan + match the pinned MAC (#1188), so a changed /
  /// duplicate adapter still recovers. With no pin we fall back to the
  /// highest-RSSI known adapter ([Obd2ConnectionService.connectByMac] requires
  /// a MAC, so the no-pin case uses a fresh scan via [connectBest]).
  Future<Obd2ReconnectAttemptResult> _connectRescan(
    Obd2ConnectionService connection,
    LastGoodAdapter? pinned,
  ) async {
    try {
      final svc = await Obd2ConnectTraceLog.runWithOrigin(
        Obd2ConnectOrigin.liveReconnect,
        () => pinned != null
            ? connection.connectByMac(pinned.mac)
            : connection.connectBest(),
        transportDecisionReason: 'reconnect-rescan',
      );
      return _onResult(svc);
    } catch (e, st) {
      _logSeam('rescan', e, st);
      return Obd2ReconnectAttemptResult.failed;
    }
  }

  /// Translate a connect result into the controller's outcome and, on
  /// success, republish the recovered link into the app-wide status dot.
  ///
  /// #3035 — a non-null service whose `0100` probe came back
  /// [Obd2BusProbeResult.probedSilent] is a CONFIRMED engine-off: the adapter
  /// re-connected fine, the ECU is just silent (parked car). Surface
  /// [Obd2ReconnectAttemptResult.engineOff] so the controller STOPS into its
  /// terminal "turn the ignition on" state instead of looping
  /// reconnect→engine-off→teardown. A [Obd2BusProbeResult.transient] (slow
  /// live car / flaky link) is NOT engine-off — it counts as `connected`.
  Obd2ReconnectAttemptResult _onResult(Obd2Service? svc) {
    if (svc == null) return Obd2ReconnectAttemptResult.notFound;
    if (svc.busProbe == Obd2BusProbeResult.probedSilent) {
      return Obd2ReconnectAttemptResult.engineOff;
    }
    try {
      ref.read(obd2ConnectionStatusProvider.notifier).markConnected(
            adapterName: svc.adapterName,
            adapterMac: svc.adapterMac,
            capability: svc.capability,
          );
    } catch (e, st) {
      // Republishing the status dot must never fail the reconnect itself.
      _logSeam('markConnected', e, st);
    }
    return Obd2ReconnectAttemptResult.connected;
  }

  void _logSeam(String where, Object e, StackTrace st) {
    unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: {
      'where': 'Obd2Reconnect $where seam failed',
    }));
  }
}

/// No-op [SettingsStorage] backing the reconnect controller's pin store ONLY
/// when the real settings box could not be resolved at build (#3019). It
/// recalls nothing, so the pinned fast path is simply skipped — the shell
/// stays alive instead of crashing on a not-yet-bootstrapped graph.
class _NullSettingsStorage implements SettingsStorage {
  const _NullSettingsStorage();
  @override
  dynamic getSetting(String key) => null;
  @override
  Future<void> putSetting(String key, dynamic value) async {}
  @override
  bool get isSetupComplete => false;
  @override
  bool get isSetupSkipped => false;
  @override
  Future<void> skipSetup() async {}
  @override
  Future<void> resetSetupSkip() async {}
}
