// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'obd2_connection_service.dart';

/// Direct/passive by-MAC connect family for [Obd2ConnectionService],
/// extracted from the service file as a `part` so it keeps private-member
/// access while the service stays under the #1680 file-length cap (sanctioned
/// #2190 decomposition — move-only, behaviour preserved).
///
/// These are the NO-SCAN connect paths the in-trip reconnect orchestrator
/// (#2245) drives: a bounded direct GATT/RFCOMM connect and a long-lived
/// passive autoConnect GATT wait. Each reuses the shared
/// [Obd2ConnectionService._openAndInit] sequence so a reconnect produces a
/// session byte-for-byte identical to the scan path.
///
/// They are kept as free functions (NOT an `extension`) so the thin instance
/// methods on [Obd2ConnectionService] that delegate to them stay virtually
/// dispatchable — test fakes (`_RecordingFakeConnection` etc.) must be able to
/// `@override` `connectByMacDirect` / `connectByMacClassicDirect` /
/// `connectByMacPassive`, which extension methods (statically dispatched)
/// silently forbid. `part`-file privacy is library-level, so these reach the
/// service's private `_openAndInit` / `_teardownLastDirectChannel` /
/// `_lastDirectChannel`.

/// Body of [Obd2ConnectionService.connectByMacDirect] (#2242). Addresses the
/// adapter via `BluetoothDevice.fromId(mac)` with a bounded ~4 s [timeout],
/// skipping the active scan — essential for ELM327 clones that stop
/// advertising in standby (a scan never sees them; a direct GATT connect
/// still wakes them). Tears down any prior direct channel first (Android
/// GATT_ERROR 133 on a stale client), runs the SAME service-side init as
/// [Obd2ConnectionService.connect] via [Obd2ConnectionService._openAndInit].
///
/// On any failure it falls back to the scan-based
/// [Obd2ConnectionService.connectByMac], so behaviour is never worse than
/// today; returns null when both fail. [fallbackToScan] `false` (the #2245
/// in-trip path, which owns its own RSSI-gated scan) returns null immediately
/// on a failed direct attempt instead of double-scanning.
Future<Obd2Service?> _connectByMacDirect(
  Obd2ConnectionService svc,
  String mac, {
  Duration? timeout,
  bool fallbackToScan = true,
}) async {
  // #3113 — a cold iOS CoreBluetooth GATT connect to an ELM clone (OBDLink CX)
  // routinely exceeds Android's 4s, so a live adapter was clipped mid-connect
  // ("Timed out after 4s"). Give iOS a 7s budget; Android keeps the
  // LOAD-BEARING 4s (#2242: autoConnect:false blocks ~35s on a sleeping
  // adapter, so the bound must stay tight there). The scan-resolved path
  // already uses 10s — only this direct path was too tight.
  final connectTimeout = timeout ??
      (defaultTargetPlatform == TargetPlatform.iOS
          ? const Duration(seconds: 7)
          : const Duration(seconds: 4));
  // #2906 — stop any active scan + settle before the direct GATT open. An
  // in-trip reconnect can reach here while the scanner's last active scan is
  // still winding down on the radio; an unstopped scan racing this connect()
  // is the Android GATT_ERROR 133 trap.
  await svc.stopScanBeforeConnect();
  // Tear down a prior direct channel BEFORE reopening (dead-GATT
  // teardown). LOAD-BEARING on Android — a still-open GATT client for
  // the same device yields GATT_ERROR 133 on the next connect.
  await svc._teardownLastDirectChannel();

  // No scan ⇒ no resolved profile. Use the registry's generic FFF0
  // BLE profile for the adapter init quirks + display name; its UUIDs
  // match the channel [channelForDirect] builds.
  final generic = _genericBleProfile(svc);
  // #2969 — this is the BLE direct path. Stamp the resolved transport so a
  // wrong-transport attempt (a BLE direct connect against a Classic adapter)
  // shows resolvedTransport:ble in the trace.
  Obd2ConnectTraceLog.active?.setResolvedTransport(Obd2ConnectTransport.ble);
  final channel =
      svc.bluetooth.channelForDirect(mac, connectTimeout: connectTimeout);
  svc._lastDirectChannel = channel;
  try {
    return await svc._openAndInit(
      channel: channel,
      adapter: generic.adapter,
      mac: mac,
      name: generic.displayName,
      logFailureAsError: false, // #2379 — recoverable (scan fallback)
    );
  } on Object catch (e, st) {
    // #2969 correction 3 — the channel-open outcome is normally stamped FIRST
    // (first-wins) at the channel-open catch (FlutterBluePlusElmChannel), where
    // the REAL FBP error is in hand; an init failure is classified in
    // `_openAndInit` from the AT transcript. This is the BACKSTOP for the case
    // where a raw channel-open error reaches here UN-stamped (a non-FBP channel
    // / a fake). first-wins means a real channel-layer stamp always wins, so
    // the wrong-transport gattTimeout is never overwritten by the fallback's
    // scanEmpty.
    final trace = Obd2ConnectTraceLog.active;
    if (trace != null) {
      trace.addStep(
        label: 'direct-connect-failed',
        status: Obd2ConnectStepStatus.fail,
        detail: e.toString(),
      );
      if (!trace.hasOutcome) {
        trace.setOutcome(
          e is Obd2ConnectionError
              ? classifyObd2ConnectError(e)
              : classifyBleOpenOutcome(e),
          failureDetail: e.toString(),
        );
      }
    }
    // #2379 — a RECOVERABLE attempt (scan fallback below routinely succeeds):
    // NOT an error trace, so the stack stays debug-only (#1103 — st bound +
    // piped to debugPrint). Inner connect already suppressed its trace; the
    // outcome is owned by the orchestrator + breadcrumbs.
    assert(() {
      debugPrint('_connectByMacDirect: recoverable direct-connect failure, '
          'falling back to scan: $e\n$st');
      return true;
    }());
    await svc._teardownLastDirectChannel();
    // #3181 — a TYPED pairing failure must NOT be masked by the scan
    // fallback: the scan would re-dial the same un-bonded adapter (burning
    // its 5-minute bond-acceptance window) and its scanEmpty/timeout would
    // bury the actionable "power-cycle and retry" guidance. Rethrow so the
    // picker / coordinator surfaces it.
    if (e is Obd2PairingRequired) rethrow;
    if (!fallbackToScan) return null;
    return svc.connectByMac(mac);
  }
}

/// Body of [Obd2ConnectionService.connectByMacClassicDirect] (#2565) — a
/// direct-connect-by-MAC over Bluetooth **CLASSIC** SPP, NO scan. The
/// transport-correct in-trip reconnect for a Classic adapter (vLinker FS et
/// al.): the BLE [_connectByMacDirect] above unconditionally builds a BLE GATT
/// channel with a 4 s connect timeout, which for a Classic adapter can only
/// ever time out (`FlutterBluePlusException | connect | fbp-code:1 | Timed out
/// after 4s`) — the exact field reconnect-storm signature. This path instead
/// resolves the bonded Classic profile + opens an RFCOMM channel via
/// [Obd2ConnectionService.classicBluetooth], and runs the SAME service-side
/// init via [Obd2ConnectionService._openAndInit] with `linkKind:'classic'`.
///
/// Returns null when no Classic facade is wired (tests / BLE-only configs)
/// so the caller falls through to its transport-aware scan fallback. NEVER
/// touches [Obd2ConnectionService.bluetooth] / `channelForDirect` — there is
/// no 4 s BLE timeout on this path. Tears down any prior direct channel first
/// (mirrors the BLE path's dead-transport guard).
Future<Obd2Service?> _connectByMacClassicDirect(
  Obd2ConnectionService svc,
  String mac,
) async {
  final classic = svc.classicBluetooth;
  if (classic == null) return null;
  // #2906 — stop scan + settle before the RFCOMM open (mirrors the BLE path).
  await svc.stopScanBeforeConnect();
  await svc._teardownLastDirectChannel();

  // No scan ⇒ no resolved profile. Pick the best-fit Classic profile so
  // the init quirks + display name match the bonded adapter.
  final profile = _classicProfileForReconnect(svc);
  // #2969 — the RFCOMM path: stamp resolvedTransport:classic.
  Obd2ConnectTraceLog.active
      ?.setResolvedTransport(Obd2ConnectTransport.classic);
  final channel = classic.channelFor(mac);
  svc._lastDirectChannel = channel;
  try {
    return await svc._openAndInit(
      channel: channel,
      adapter: profile.adapter,
      mac: mac,
      name: profile.displayName,
      linkKind: 'classic',
      logFailureAsError: false, // #2379 — recoverable (scanner re-arms)
    );
  } on Object catch (e, st) {
    // #2969 — the rfcomm-open outcome was already stamped FIRST at the Classic
    // channel-open catch; the init-failure outcome inside _openAndInit. Record
    // the direct-path step here for the timeline.
    Obd2ConnectTraceLog.active?.addStep(
      label: 'classic-direct-connect-failed',
      status: Obd2ConnectStepStatus.fail,
      detail: e.toString(),
    );
    // #2565 — RECOVERABLE: the scanner owns its transport-aware scan fallback +
    // re-arm. Inner connect already suppressed its trace, so the stack stays
    // debug-only (#1103 — st bound + piped to debugPrint).
    assert(() {
      debugPrint('_connectByMacClassicDirect: recoverable failure: $e\n$st');
      return true;
    }());
    await svc._teardownLastDirectChannel();
    return null;
  }
}

/// Body of [Obd2ConnectionService.connectByMacTransportAware] (#3025 / Epic
/// #3013). Routes a FIRST-connect / pinned by-MAC connect to the transport the
/// paired [adapterName] name-matches in the registry, so a Classic adapter is
/// NEVER reached on the doomed BLE GATT path.
///
///   * CLASSIC name → [Obd2ConnectionService.connectByMacClassicDirect] only
///     (RFCOMM; no `channelForDirect`, no 4 s BLE timeout). On a clean miss
///     (null) it falls through to the transport-aware scan via
///     [Obd2ConnectionService.connectByMac] when [fallbackToScan] — the merged
///     BLE+Classic scan reaches the bonded Classic candidate WITHOUT a prior
///     BLE GATT to poison the socket.
///   * BLE name → [Obd2ConnectionService.connectByMacDirect] (its own scan
///     fallback honoured via [fallbackToScan]).
///   * UNKNOWN / nameless → the historical BLE-direct-first, then a Classic
///     direct attempt for the same MAC. The BLE [Obd2ConnectionService.bluetooth]
///     channel is FULLY torn down (GATT disconnected — `channel.close()` ⇒
///     `device.disconnect()`) by `connectByMacDirect`/the Classic path's own
///     `_teardownLastDirectChannel` between the two, so no half-open GATT can
///     poison the RFCOMM socket (the #3025 dual-mode conflict).
///
/// `requestedTransport` is stamped to match the chosen path (Classic adapter ⇒
/// `rtx: classic`) by the per-transport `_traced` wrappers each branch delegates
/// to — so a field trace is truthful (a Classic adapter no longer shows the
/// misleading `rtx: ble`). A single transport-determined attempt is one trace.
Future<Obd2Service?> _connectByMacTransportAware(
  Obd2ConnectionService svc,
  String mac, {
  String? adapterName,
  bool fallbackToScan = true,
}) async {
  final transport = svc.registry.transportForName(adapterName);
  switch (transport) {
    case BluetoothTransport.classic:
      // Classic-classified: ONLY the RFCOMM direct path — never the BLE GATT
      // path that 4 s-times-out and poisons the socket. The Classic facade is
      // required; with none wired (BLE-only test config), fall through to the
      // transport-aware scan instead of silently doing nothing.
      if (svc.classicBluetooth != null) {
        final direct =
            await svc.connectByMacClassicDirect(mac, adapterName: adapterName);
        if (direct != null) return direct;
      }
      return fallbackToScan
          ? svc.connectByMac(mac, adapterName: adapterName)
          : null;
    case BluetoothTransport.ble:
      return svc.connectByMacDirect(mac,
          fallbackToScan: fallbackToScan, adapterName: adapterName);
    case null:
      // UNKNOWN transport (an unfamiliar / nameless adapter). Preserve the
      // historical BLE-direct-first behaviour, then try the Classic direct path
      // for the SAME MAC. `connectByMacDirect` self-tears-down its GATT on
      // failure (close ⇒ device.disconnect), and `connectByMacClassicDirect`
      // also tears down any prior direct channel before opening — so the BLE
      // GATT is fully gone before the RFCOMM open (no socket poisoning).
      // `fallbackToScan:false` here so the doomed-BLE attempt fails fast to the
      // Classic attempt; the final scan fallback runs once at the end.
      final ble = await svc.connectByMacDirect(mac,
          fallbackToScan: false, adapterName: adapterName);
      if (ble != null) return ble;
      if (svc.classicBluetooth != null) {
        final classic =
            await svc.connectByMacClassicDirect(mac, adapterName: adapterName);
        if (classic != null) return classic;
      }
      return fallbackToScan
          ? svc.connectByMac(mac, adapterName: adapterName)
          : null;
  }
}

/// Body of [Obd2ConnectionService.connectByMacPassive] (#2261 concern 2).
/// Opens a channel with `autoConnect:true` and NO bounded timeout, so the OS
/// holds a low-power background GATT request that resolves the instant the
/// pinned adapter advertises again — used by the reconnect scanner past its
/// active-scan miss ceiling so a parked car stops burning the radio. NO scan
/// fallback (the passive wait IS the fallback) and NO requestMtu (FBP forbids
/// it with autoConnect). Returns null on any failure; runs the SAME
/// service-side init via [Obd2ConnectionService._openAndInit].
Future<Obd2Service?> _connectByMacPassive(
  Obd2ConnectionService svc,
  String mac,
) async {
  // #2906 — stop scan + settle before the passive autoConnect GATT open.
  await svc.stopScanBeforeConnect();
  await svc._teardownLastDirectChannel();
  final generic = _genericBleProfile(svc);
  final channel = svc.bluetooth.channelForDirect(mac, autoConnect: true);
  svc._lastDirectChannel = channel;
  try {
    return await svc._openAndInit(
      channel: channel,
      adapter: generic.adapter,
      mac: mac,
      name: generic.displayName,
      logFailureAsError: false, // #2379 — recoverable (scanner re-arms)
    );
  } on Object catch (e, st) {
    // #2892 — the passive autoConnect wait routinely raises the EXPECTED
    // Obd2AdapterUnresponsive on a parked car (silent bus / out of range);
    // breadcrumb it instead of an ERROR trace (error-log #22 flood). A
    // genuine fault still ERROR-logs (#2379 — OBD2/BLE → `other`).
    recordObd2ConnectTransient(e, st,
        where: 'Obd2ConnectionService.connectByMacPassive failed',
        layer: ErrorLayer.other);
    await svc._teardownLastDirectChannel();
    return null;
  }
}

/// Body of [Obd2ConnectionService.stopScanBeforeConnect] (#2906). Stops the
/// active BLE + Classic scan, then pauses [Obd2ConnectionService.scanSettleDelay]
/// so the radio quiesces before a `channel.open()`. Android returns
/// GATT_ERROR 133 when a `connect()` races a scan still winding down on the
/// controller; the in-trip scan-fallback `connect` is the worst offender (it
/// reaches the open straight out of an `await for` scan loop whose
/// subscription — and so `stopScan()` — cancels only asynchronously).
/// Idempotent + best-effort: a `stopScan()` that throws (no scan in flight,
/// plugin quirk) is logged as a recoverable OBD2/BLE transient and never
/// aborts the connect.
Future<void> _stopScanBeforeConnect(Obd2ConnectionService svc) async {
  // #2906 — capture whether a BLE scan is ACTUALLY in flight before we stop
  // it. The settle pause below is only needed to let the radio quiesce after a
  // real scan winds down (the in-trip-reconnect GATT_ERROR 133 race). With no
  // active scan — a cold direct connect, the recording pre-warm, or a widget
  // test driving the prod connection graph — the pause buys nothing and would
  // leave a pending timer past widget disposal (the #2918 prewarm leak).
  final wasScanning = FlutterBluePlus.isScanningNow;
  try {
    await svc.bluetooth.stopScan();
  } catch (e, st) {
    // #2379 — OBD2/BLE radio, not local storage. Best-effort; never fatal.
    unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
      'where': 'Obd2ConnectionService: stopScan (BLE) before connect',
    }));
  }
  try {
    await svc.classicBluetooth?.stopScan();
  } catch (e, st) {
    unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
      'where': 'Obd2ConnectionService: stopScan (classic) before connect',
    }));
  }
  if (wasScanning && svc.scanSettleDelay > Duration.zero) {
    await Future<void>.delayed(svc.scanSettleDelay);
  }
}

/// Generic FFF0 BLE profile used for direct/passive connect quirks +
/// display name when no scan resolved a profile.
Obd2AdapterProfile _genericBleProfile(Obd2ConnectionService svc) =>
    svc.registry.profiles.firstWhere(
      (p) => p.id == 'generic-fff0',
      orElse: () => svc.registry.profiles.firstWhere(
        (p) => p.transport == BluetoothTransport.ble,
      ),
    );

/// Best Classic profile for an in-trip reconnect (#2565). No scan ran, so
/// the MAC is all we have; we can't name-match an RFCOMM socket, so prefer
/// the `vlinker-fs-classic` profile (the dominant field adapter + the one
/// in the reconnect-storm report) and fall back to the first Classic
/// profile. The Classic adapter quirks are a safe superset for ELM327 SPP.
Obd2AdapterProfile _classicProfileForReconnect(Obd2ConnectionService svc) =>
    svc.registry.profiles.firstWhere(
      (p) => p.id == 'vlinker-fs-classic',
      orElse: () => svc.registry.profiles.firstWhere(
        (p) => p.transport == BluetoothTransport.classic,
      ),
    );
