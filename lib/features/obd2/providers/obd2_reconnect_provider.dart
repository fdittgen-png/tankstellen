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
import '../data/obd2_link_drop_signal.dart';
import '../data/obd2_recording_link_ownership.dart';
import '../data/obd2_reconnect_controller.dart';
import '../data/obd2_service.dart';
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
///   * [reportDropped] (called by ANY drop signal — incl. the proactive Classic
///     socket-closed signal, #2671) starts the bounded backoff loop;
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
  StreamSubscription<Obd2LinkDropEvent>? _dropSub;

  @override
  Obd2ReconnectState build() {
    final controller = _buildController();
    _controller = controller;
    // #3019 — subscribe to the PROACTIVE link-drop signal both channels emit
    // the instant a link dies (BLE disconnect edge / Classic socket close), so
    // a drop while idle / between trips still starts the bounded backoff loop.
    _dropSub = Obd2LinkDropSignal.instance.drops.listen((e) {
      // #3386 — STAND DOWN while a trip recording owns the adapter: the trip's
      // own DroppedSessionManager (#2188) is the sole in-trip reconnect
      // authority. Two reconnectors on one adapter ping-pong the single RFCOMM
      // socket forever (the field "permanently reconnecting" war). #3019 only
      // handles drops while idle / between trips — exactly its #3013 charter.
      if (Obd2RecordingLinkOwnership.instance.active) return;
      // #3346 — carry WHY the link dropped (and on which transport) into the
      // controller so the reconnect-episode breadcrumb records it.
      _controller?.notifyDropped(
        reason: e.reason,
        transportKind: e.transportKind,
        mac: e.mac,
      );
    });
    // #3386 — if a recording CLAIMS the link while #3019 is mid-loop (an idle
    // drop that was recovering when the user hit Start), hand over immediately:
    // stop the loop so it can't tear down the recording's freshly-owned socket.
    final ownership = Obd2RecordingLinkOwnership.instance.recordingOwnsLink;
    void onOwnershipChanged() {
      if (ownership.value) _controller?.stop();
    }
    ownership.addListener(onOwnershipChanged);
    ref.onDispose(() {
      ownership.removeListener(onOwnershipChanged);
      unawaited(_dropSub?.cancel());
      _dropSub = null;
      controller.dispose();
      _controller = null;
    });
    return controller.state;
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

  /// Report a detected connection drop — the trip-INDEPENDENT entry point.
  /// Safe to call from anywhere a drop is observed (the proactive Classic
  /// socket-closed signal, the in-trip drop detector, a manual probe).
  void reportDropped() => _controller?.notifyDropped();

  /// Mark the link healthy (a first connect / external successful reconnect).
  void reportConnected() => _controller?.notifyConnected();

  /// User tapped the terminal "tap to retry" affordance — restart the loop.
  void retry() => _controller?.retry();

  /// Stop the loop (OBD2 disabled / owner disposing).
  void stop() => _controller?.stop();

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
