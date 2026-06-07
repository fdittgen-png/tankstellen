// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/data/storage_repository.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/storage/storage_providers.dart';
import '../data/obd2/last_good_adapter_store.dart';
import '../data/obd2/obd2_connection_service.dart';
import '../data/obd2/obd2_link_drop_signal.dart';
import '../data/obd2/obd2_reconnect_controller.dart';
import '../data/obd2/obd2_service.dart';
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
    _dropSub = Obd2LinkDropSignal.instance.drops.listen((_) {
      _controller?.notifyDropped();
    });
    ref.onDispose(() {
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
    return controller;
  }

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
      final svc = pinned.isClassic
          ? await connection.connectByMacClassicDirect(pinned.mac)
          : await connection.connectByMacDirect(pinned.mac, fallbackToScan: false);
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
      final svc = pinned != null
          ? await connection.connectByMac(pinned.mac)
          : await connection.connectBest();
      return _onResult(svc);
    } catch (e, st) {
      _logSeam('rescan', e, st);
      return Obd2ReconnectAttemptResult.failed;
    }
  }

  /// Translate a connect result into the controller's tri-state outcome and,
  /// on success, republish the recovered link into the app-wide status dot.
  Obd2ReconnectAttemptResult _onResult(Obd2Service? svc) {
    if (svc == null) return Obd2ReconnectAttemptResult.notFound;
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
