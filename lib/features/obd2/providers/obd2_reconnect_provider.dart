// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/widgets.dart' show AppLifecycleState, WidgetsBinding;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/error_logger.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/telemetry/collectors/breadcrumb_collector.dart';
import '../../vehicle/api.dart' show activeVehicleProfileProvider;
import '../data/last_good_adapter_store.dart';
import '../data/obd2_comm_diagnostics.dart';
import '../data/obd2_connect_trace.dart';
import '../data/obd2_connect_trace_log.dart';
import '../data/session/obd2_connection_service.dart';
import '../data/session/obd2_dial_budget.dart';
import '../data/session/obd2_disconnect_quietly.dart';
import '../data/session/obd2_link_supervisor.dart';
import '../data/session/obd2_service.dart';
import '../domain/obd2_engine_evidence.dart';
import 'obd2_connection_state_provider.dart';

part 'obd2_reconnect_provider.g.dart';

/// Local (NON-synced) auto-pin store for the last-good adapter (#3019 /
/// Epic #3013 phase 3), backed by the Hive `settings` box.
@Riverpod(keepAlive: true)
LastGoodAdapterStore lastGoodAdapterStore(Ref ref) =>
    LastGoodAdapterStore(ref.watch(settingsStorageProvider));

/// App-wide owner of THE [Obd2LinkSupervisor] (#3529, Epic #3527).
///
/// The supervisor is the single reconnect authority of the rewritten
/// link layer — this provider wires it into the app graph:
///   * the DEFAULT dial policy (auto-pinned adapter direct-connect
///     first, transport-correct, #3016; then a re-scan fallback);
///   * engine-off classification (#3035): a dial that reaches the
///     adapter but finds a silent bus parks the supervisor in
///     [Obd2LinkState.engineOff] instead of feeding the backoff loop;
///   * republishing a recovered link into the app-wide status dot;
///   * the #3346 episode breadcrumbs + gated comm-diagnostics counters.
///
/// Replaces the #3019 [Obd2ReconnectController] + arbiter idle-policy +
/// wedge-recovery constellation (deletion tracked by #3533): there is
/// no terminal-failed dead end anymore — the loop retries (capped
/// backoff) until the user disconnects or the engine is off.
@Riverpod(keepAlive: true)
class Obd2Reconnect extends _$Obd2Reconnect {
  Obd2LinkSupervisor? _supervisor;
  StreamSubscription<Obd2LinkState>? _statesSub;

  /// THE supervisor. Interactive surfaces (picker, VIN reader,
  /// self-test) route their one-shot dials through
  /// [Obd2LinkSupervisor.connectWith] so the app has exactly one dial
  /// path; the recording pipeline reads the live service from here.
  Obd2LinkSupervisor get supervisor {
    // build() ran before any access (Riverpod contract), so this is
    // only null after dispose — a programming error worth surfacing.
    final sup = _supervisor;
    if (sup == null) {
      throw StateError('Obd2Reconnect accessed after dispose');
    }
    return sup;
  }

  @override
  Obd2LinkState build() {
    final sup = Obd2LinkSupervisor(dial: _dialDefault);
    _supervisor = sup;
    _statesSub = sup.states.listen(_onLinkState);
    ref.onDispose(() {
      unawaited(_statesSub?.cancel());
      _statesSub = null;
      unawaited(sup.dispose());
      _supervisor = null;
    });
    return sup.state.value;
  }

  /// #3676 — user-initiated hard reset: ATZ on the dongle (best
  /// effort), full link recycle, fresh dial. Returns true when the
  /// redial produced a live service.
  Future<bool> resetConnection() async {
    final svc = await supervisor.resetLink();
    return svc != null;
  }

  DateTime? _reconnectingSince;

  void _onLinkState(Obd2LinkState next) {
    state = next;
    // #3346 — episode breadcrumbs + gated comm-diagnostics counters.
    BreadcrumbCollector.add('obd2-link: $next');
    final diag = Obd2CommDiagnostics.instance;
    switch (next) {
      case Obd2LinkState.reconnecting:
        _reconnectingSince ??= DateTime.now();
        if (diag.enabled) diag.noteConnectionEvent(attempt: true);
      case Obd2LinkState.ready:
        final since = _reconnectingSince;
        _reconnectingSince = null;
        if (diag.enabled && since != null) {
          diag.noteConnectionEvent(
            success: true,
            visibleReconnect: true,
            timeToReconnectMs:
                DateTime.now().difference(since).inMilliseconds,
          );
        }
        _republishStatusDot();
      case Obd2LinkState.engineOff:
        _reconnectingSince = null;
        if (diag.enabled) {
          diag.noteConnectionEvent(failureReason: 'reconnect-engine-off');
        }
      case Obd2LinkState.idle:
      case Obd2LinkState.connecting:
      case Obd2LinkState.userDisconnected:
        _reconnectingSince = null;
    }
  }

  /// On a recovered link, repaint the app-wide status dot. Must never
  /// fail the reconnect itself.
  void _republishStatusDot() {
    final svc = _supervisor?.service;
    if (svc == null) return;
    try {
      ref.read(obd2ConnectionStatusProvider.notifier).markConnected(
            adapterName: svc.adapterName,
            adapterMac: svc.adapterMac,
            capability: svc.capability,
          );
    } catch (e, st) {
      _logSeam('markConnected', e, st);
    }
  }

  /// The supervisor's DEFAULT dial policy: auto-pinned adapter first
  /// via a transport-correct DIRECT connect (no scan, #3016), then a
  /// re-scan fallback (#1188 — a changed/duplicate adapter still
  /// recovers; no pin ⇒ highest-RSSI known adapter).
  ///
  /// Engine-off classification (#3035): a non-null service whose `0100`
  /// probe came back [Obd2BusProbeResult.probedSilent] means the
  /// adapter is fine and the CAR is off — park the supervisor instead
  /// of feeding the backoff loop (reconnect→engine-off→teardown cycles
  /// burn the battery of a parked car).
  ///
  /// Shell safety: the app shell watches this provider, so failed
  /// dependency reads (not-yet-bootstrapped graph / widget-test scope)
  /// must degrade to a no-op dial, never crash the shell.
  Future<Obd2Service?> _dialDefault() =>
      // #3671 — the automatic reconnect dial runs under a whole-attempt
      // budget; see [dialWithBudget] for the field pathology (a single
      // liveReconnect attempt grinding 21 minutes in the background).
      dialWithBudget(_dialDefaultBody);

  Future<Obd2Service?> _dialDefaultBody() async {
    final Obd2ConnectionService connection;
    final LastGoodAdapterStore pinStore;
    try {
      connection = ref.read(obd2ConnectionProvider);
      pinStore = ref.read(lastGoodAdapterStoreProvider);
    } catch (e, st) {
      _logSeam('dial dependency read', e, st);
      return null;
    }
    final pinned = pinStore.recall();

    // #3553 — the ACTIVE vehicle's pinned adapter is authoritative user
    // intent; the last-good pin is only an optimization (it updates
    // exclusively on a SUCCESSFUL connect, so after a vehicle/adapter
    // switch it points at the PREVIOUS device until the new one connects
    // — which this loop then prevented by always dialing the stale pin).
    // When the two disagree, dial the vehicle's adapter FIRST
    // (transport-aware); the last-good + rescan paths below stay the
    // fallbacks.
    final vehicleMac = _activeVehicleAdapterMac();
    if (vehicleMac != null && vehicleMac != pinned?.mac) {
      final byVehicle = await Obd2ConnectTraceLog.runWithOrigin(
        Obd2ConnectOrigin.liveReconnect,
        () => connection.connectByMacTransportAware(
          vehicleMac,
          adapterName: _activeVehicleAdapterName(),
          fallbackToScan: false,
        ),
        transportDecisionReason: 'reconnect-active-vehicle',
      );
      final classified = await _classify(byVehicle);
      if (classified != null || _supervisor?.userRequestedDisconnect == true) {
        return classified;
      }
    }

    // Pinned fast path — transport-correct direct connect.
    if (pinned != null) {
      final direct = await Obd2ConnectTraceLog.runWithOrigin(
        Obd2ConnectOrigin.liveReconnect,
        () => pinned.isClassic
            ? connection.connectByMacClassicDirect(pinned.mac)
            : connection.connectByMacDirect(pinned.mac, fallbackToScan: false),
        transportDecisionReason: pinned.isClassic
            ? 'reconnect-pinned-classic'
            : 'reconnect-pinned-ble',
      );
      final classified = await _classify(direct);
      if (classified != null || _supervisor?.userRequestedDisconnect == true) {
        return classified;
      }
    }

    // Re-scan fallback — #3671: only while the app is visible. The
    // scan is the expensive step of a dial (continuous BLE callbacks on
    // the main looper, throttled-but-not-free in background); with the
    // phone parked away from the car overnight it ground for tens of
    // minutes per attempt until the OS killed the process for excessive
    // background CPU. The direct by-MAC dials above still run, so
    // auto-record keeps recovering the moment the adapter answers; the
    // scan-based rescue resumes on the next foreground dial.
    if (shouldSkipRescanWhenBackgrounded(_lifecycleStateOrNull())) {
      BreadcrumbCollector.add('obd2-reconnect: rescan skipped (backgrounded)');
      return null;
    }
    final rescanned = await Obd2ConnectTraceLog.runWithOrigin(
      Obd2ConnectOrigin.liveReconnect,
      () => pinned != null
          ? connection.connectByMac(pinned.mac)
          : connection.connectBest(),
      transportDecisionReason: 'reconnect-rescan',
    );
    return _classify(rescanned);
  }

  /// #3671 — the app lifecycle, or null when the widgets binding is not
  /// up (pure-Dart provider tests / early startup). Null errs on the
  /// visible side, keeping the full dial.
  AppLifecycleState? _lifecycleStateOrNull() {
    try {
      return WidgetsBinding.instance.lifecycleState;
    } catch (_) {
      return null;
    }
  }

  /// The active vehicle's pinned adapter MAC (#3553), or null when no
  /// vehicle is active / none is pinned / the graph isn't up (shell
  /// safety — same degradation contract as the dependency reads above).
  String? _activeVehicleAdapterMac() {
    try {
      final mac = ref.read(activeVehicleProfileProvider)?.obd2AdapterMac;
      return (mac == null || mac.trim().isEmpty) ? null : mac;
    } catch (_) {
      return null;
    }
  }

  /// The active vehicle's pinned adapter NAME (#3553) — feeds the
  /// transport registry's name-based Classic/BLE inference. Null on any
  /// failure, mirroring [_activeVehicleAdapterMac].
  String? _activeVehicleAdapterName() {
    try {
      return ref.read(activeVehicleProfileProvider)?.obd2AdapterName;
    } catch (_) {
      return null;
    }
  }

  /// Engine-off gate for a dial result. Returns the service to keep, or
  /// null after parking/releasing.
  ///
  /// #3780 (Epic #3775) — `probedSilent` is NOT a reliable engine-off
  /// signal: `UNABLE TO CONNECT`/`STOPPED` classify as silent, yet the
  /// K-line failed-search livelock produces exactly that reply with the
  /// engine RUNNING (#3575). The trip-START gate got the #3551/#3571
  /// recovery rungs; this reconnect gate never did — it parked the
  /// supervisor mid-drive on the first silent verdict, disabling every
  /// redial AND the trip's re-attach for the rest of the drive. With
  /// fresh engine evidence (#3756 — an engine PID parsed within 10 min)
  /// a drive is demonstrably in progress: pay one bounded
  /// `recoverVehicleProtocol` pass, and even if the bus stays silent
  /// KEEP the link instead of parking — the in-trip #3575/#3577 episode
  /// recovery gets its chance, and a mid-drive park is the one
  /// catastrophic outcome. A parked car produces no evidence and keeps
  /// the zero-cost park exactly as before.
  Future<Obd2Service?> _classify(Obd2Service? svc) async {
    if (svc == null) return null;
    if (svc.busProbe != Obd2BusProbeResult.probedSilent) return svc;
    if (Obd2EngineEvidence.instance.isFresh()) {
      BreadcrumbCollector.add(
        'OBD2 reconnect: silent bus but engine evidence fresh — '
        'recovering protocol (#3780)',
      );
      final answered = await svc.recoverVehicleProtocol();
      BreadcrumbCollector.add(
        'OBD2 reconnect: post-recovery verdict (#3780)',
        detail: answered
            ? 'bus answered — kept'
            : 'still silent — kept (mid-drive park refused; in-trip '
                'recovery owns the rest)',
      );
      return svc;
    }
    // Adapter back, ECU silent, no evidence of a running engine — a
    // parked car. Release the link (the adapter sleeps on its own) and
    // park the loop.
    unawaited(svc.disconnectQuietly());
    _supervisor?.noteEngineOff();
    return null;
  }

  void _logSeam(String where, Object e, StackTrace st) {
    unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: {
      'where': 'Obd2Reconnect $where seam failed',
    }));
  }
}

/// #3671 — whether a reconnect dial should skip its re-scan fallback.
///
/// `paused` / `hidden` / `detached` are genuinely backgrounded — the
/// user cannot see the app, and a BLE scan there burns main-looper CPU
/// for a rescue no one is waiting on. `inactive` (a transient overlay,
/// the iOS app-switcher flash) and `resumed` keep the full dial.
/// A null lifecycle (engine not yet told) errs on the visible side.
bool shouldSkipRescanWhenBackgrounded(AppLifecycleState? lifecycle) =>
    lifecycle == AppLifecycleState.paused ||
    lifecycle == AppLifecycleState.hidden ||
    lifecycle == AppLifecycleState.detached;

