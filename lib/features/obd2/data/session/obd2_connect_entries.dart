// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'obd2_connection_service.dart';

/// Connect-entry trace wrappers + the scan-path connect body for
/// [Obd2ConnectionService], extracted as a `part` (#3760 decomposition —
/// move-only, behaviour preserved) so the service file stays under the
/// #1680 file-length cap.
///
/// Free functions (NOT an `extension`) — the `obd2_connect_by_mac.dart`
/// precedent — so the thin delegating instance methods on
/// [Obd2ConnectionService] stay virtually dispatchable for test fakes
/// while these bodies keep library-level private access.

/// #2969 — open (or join) a connect trace around [body], stamp the terminal
/// outcome (success when a service comes back; the inner-stamped outcome — or
/// `scanEmpty` as the default — when null; the classified error on a throw),
/// and finalise it into [Obd2ConnectTraceLog]. The single wrapper every
/// public by-MAC connect entry threads through, so a failure at ANY phase
/// (incl. the pre-session phases) is captured. Re-entrant safe: a nested
/// connect (a fallback re-entering a public method) joins the same trace.
Future<Obd2Service?> _traced({
  required Obd2ConnectOrigin origin,
  String? mac,
  String? adapterName,
  required Obd2ConnectTransport requestedTransport,
  required Future<Obd2Service?> Function() body,
}) async {
  final trace = Obd2ConnectTraceLog.beginTrace(
    origin: origin,
    mac: mac,
    adapterName: adapterName,
    requestedTransport: requestedTransport,
  );
  try {
    final svc = await body();
    if (svc != null) {
      trace.setOutcome(Obd2ConnectOutcome.success);
    } else if (!trace.hasOutcome) {
      // A clean null with NO inner-stamped outcome means the scan/transport
      // path never matched the adapter — the scan-empty / not-in-range case.
      trace.setOutcome(Obd2ConnectOutcome.scanEmpty);
    }
    return svc;
    // rethrow preserves the stack; the (e) binding only classifies the trace.
    // ignore: catch_no_st
  } catch (e) {
    trace.setOutcomeFromError(e);
    rethrow;
  } finally {
    Obd2ConnectTraceLog.endTrace(trace);
  }
}

/// The [connect] body (trace open/outcome wrap around
/// [_connectResolved]); kept separate so the entry stays a thin shell.
Future<Obd2Service> _connectTraced(
  Obd2ConnectionService service,
  ResolvedObd2Candidate candidate,
) async {
  // #2969 — open (or join) a connect trace for the scan-based path. A child
  // when an outer by-MAC/best trace is already open (so the whole attempt is
  // ONE trace); the root when `connect(candidate)` is the entry (the
  // reconnect scan-fallback calls it directly). On success/throw the wrapper
  // stamps the outcome; the steps + resolved transport are recorded below.
  final trace = Obd2ConnectTraceLog.beginTrace(
    origin: Obd2ConnectOrigin.firstConnect,
    mac: candidate.candidate.deviceId,
    // #3014 — the scan resolved a real candidate, so its name is known: the
    // advertised name, or the registry display label when the advertisement
    // was anonymous. Fills the trace headline for a scan-path connect.
    adapterName: candidate.candidate.deviceName.isEmpty
        ? candidate.profile.displayName
        : candidate.candidate.deviceName,
    requestedTransport:
        candidate.profile.transport == BluetoothTransport.classic
            ? Obd2ConnectTransport.classic
            : Obd2ConnectTransport.ble,
  );
  try {
    final svc = await _connectResolved(service, candidate);
    trace.setOutcome(Obd2ConnectOutcome.success);
    return svc;
    // rethrow preserves the stack; the (e) binding only classifies the trace.
    // ignore: catch_no_st
  } catch (e) {
    trace.setOutcomeFromError(e);
    rethrow;
  } finally {
    Obd2ConnectTraceLog.endTrace(trace);
  }
}

/// The scan-based connect body (#2969 extraction): channel → transport →
/// service → init for an already-resolved [candidate]. Kept separate so the
/// public [connect] can wrap it in a connect trace.
Future<Obd2Service> _connectResolved(
  Obd2ConnectionService svc,
  ResolvedObd2Candidate candidate,
) async {
  // #2906 — stop any active scan (BLE + Classic) and let the radio settle
  // BEFORE the channel opens. Android BLE returns GATT_ERROR 133 when a
  // `connect()` races a scan still winding down on the controller; the
  // scan-fallback `connect` is the worst offender (it reaches here straight
  // out of the `await for` scan loop, whose subscription cancels — and so
  // calls `stopScan()` — only asynchronously). Stopping + settling here
  // closes that race for every connect path that funnels through `connect`.
  await svc.stopScanBeforeConnect();
  // #2907 — tear down any stale direct/passive channel from a PRIOR
  // by-MAC connect before the scan path opens a fresh one. The
  // [connectByMacDirect]/[connectByMacPassive] paths already self-clean,
  // but the SCAN-fallback `connect` did not — so an in-trip reconnect that
  // tried a direct connect (which retained `_lastDirectChannel`) and then
  // fell back to the gated scan left that GATT client open, and Android
  // returned GATT_ERROR 133 on the scan-path open against the same device
  // (the repeat-133 reconnect trap). Idempotent + best-effort.
  await svc._teardownLastDirectChannel();
  // #2969 — stamp the resolved transport on the active connect trace. The
  // scan path resolved a real profile, so this is the authoritative transport
  // (unlike the no-scan by-MAC paths, which stamp their requested transport).
  Obd2ConnectTraceLog.active?.setResolvedTransport(
    candidate.profile.transport == BluetoothTransport.classic
        ? Obd2ConnectTransport.classic
        : Obd2ConnectTransport.ble,
  );
  final channel = switch (candidate.profile.transport) {
    BluetoothTransport.ble => svc.bluetooth.channelFor(
        candidate.candidate.deviceId, candidate.profile),
    BluetoothTransport.classic => (svc.classicBluetooth ??
            (throw const Obd2AdapterUnresponsive(
                'Classic BT transport requested but no Classic '
                'facade is wired — app misconfiguration')))
        .channelFor(candidate.candidate.deviceId),
  };
  // #1312 — stamp adapter identity onto the service so the trip
  // recorder can persist it on the saved [TripHistoryEntry] and the
  // detail screen can name the device. The friendly name falls back to
  // the registry display label when the advertisement was empty.
  final name = candidate.candidate.deviceName.isEmpty
      ? candidate.profile.displayName
      : candidate.candidate.deviceName;
  return svc._openAndInit(
    channel: channel,
    adapter: candidate.profile.adapter,
    mac: candidate.candidate.deviceId,
    name: name,
    linkKind: obd2LinkKindOf(candidate.profile.transport),
  );
}

/// Body of [Obd2ConnectionService.connectBest] (#3760 — move-only).
Future<Obd2Service?> _connectBestTraced(Obd2ConnectionService service) async {
  // #2969 — connectBest() was the silent dead-end: an empty `_lastRanked`
  // returned null with NO trace, so the user's "it won't connect" left
  // nothing. Open a trace at the entry so even the no-candidate case is
  // captured with a `scanEmpty` outcome. The inner `connect(candidate)` joins
  // this as a child trace, so a real attempt is still ONE trace.
  final trace = Obd2ConnectTraceLog.beginTrace(
    origin: Obd2ConnectOrigin.firstConnect,
  );
  try {
    if (service._lastRanked.isEmpty) {
      trace.addStep(
        label: 'rank',
        status: Obd2ConnectStepStatus.fail,
        detail: 'no ranked candidate cached — scan first',
      );
      trace.setOutcome(Obd2ConnectOutcome.scanEmpty);
      return null;
    }
    final svc = await _connectBestInner(service);
    trace.setOutcome(Obd2ConnectOutcome.success);
    return svc;
    // rethrow preserves the stack; the (e) binding only classifies the trace
    // (permission / BT-off throw before registry.rank, so recordScan misses).
    // ignore: catch_no_st
  } catch (e) {
    trace.setOutcomeFromError(e);
    rethrow;
  } finally {
    Obd2ConnectTraceLog.endTrace(trace);
  }
}

/// De-noise wrapper preserved from the pre-#2969 `connectBest`: the trace is
/// owned by the public method above; this keeps the #2935/#2943 breadcrumb-
/// vs-ERROR behaviour. (Kept as a separate seam so the trace bookkeeping and
/// the error-log de-noise stay independently testable.)
Future<Obd2Service> _connectBestInner(Obd2ConnectionService svc) async {
  try {
    return await svc.connect(svc._lastRanked.first);
  } catch (e, st) {
    // #2379 final-failure log → #2943 (error-log #28/29): completing the
    // #2935 de-noise. An EXPECTED engine-off condition (Obd2AdapterUnresponsive
    // et al.) or a bare ELM327 connect TimeoutException de-noises to a
    // breadcrumb here instead of spooling an ERROR on every probe of a
    // parked car (5× in that log); a GENUINE fault (Obd2PermissionDenied,
    // Obd2ProtocolInitFailed, any non-expected error) still ERROR-logs on
    // `other`. The error is rethrown either way so the caller's own
    // handling is unchanged. (Catching broadly — not just
    // Obd2ConnectionError — lets the shared de-noiser classify a raw
    // TimeoutException too; #1103 satisfied via the (e, st) binding.)
    recordObd2ConnectTransient(e, st,
        where: 'Obd2ConnectionService.connectBest failed',
        layer: ErrorLayer.other);
    rethrow;
  }
}

/// #2969 — [Obd2ConnectionService.connectByMacDirect] is wrapped in a
/// connect trace at the service entry point (the single virtual-dispatch
/// chokepoint every by-MAC caller funnels through), so a failed FIRST
/// connect / in-trip reconnect — even with developer mode off — leaves a
/// non-empty trace. Records `requestedTransport: ble` (this IS the BLE
/// direct path); the inner body stamps the channel-open outcome BEFORE any
/// scan fallback (first-wins). (#3760 — moved from the service file.)
Future<Obd2Service?> _connectByMacDirectTraced(
  Obd2ConnectionService svc,
  String mac, {
  Duration? timeout,
  bool fallbackToScan = true,
  String? adapterName,
}) =>
    _traced(
      origin: Obd2ConnectOrigin.firstConnect,
      mac: mac,
      adapterName: adapterName, // #3014 — name the BLE by-MAC attempt
      requestedTransport: Obd2ConnectTransport.ble,
      body: () => _connectByMacDirect(svc, mac,
          timeout: timeout, fallbackToScan: fallbackToScan),
    );

/// Trace wrapper for [Obd2ConnectionService.connectByMacClassicDirect]
/// (#2565; #3760 — moved from the service file).
Future<Obd2Service?> _connectByMacClassicDirectTraced(
  Obd2ConnectionService svc,
  String mac, {
  String? adapterName,
}) =>
    _traced(
      origin: Obd2ConnectOrigin.firstConnect,
      mac: mac,
      adapterName: adapterName, // #3014 — name the Classic by-MAC attempt
      requestedTransport: Obd2ConnectTransport.classic,
      body: () =>
          _connectByMacClassicDirect(svc, mac, adapterName: adapterName),
    );

/// Trace wrapper for [Obd2ConnectionService.connectByMacPassive] (#2261
/// concern 2; #3760 — moved from the service file).
Future<Obd2Service?> _connectByMacPassiveTraced(
  Obd2ConnectionService svc,
  String mac, {
  String? adapterName,
}) =>
    _traced(
      origin: Obd2ConnectOrigin.liveReconnect,
      mac: mac,
      adapterName: adapterName, // #3014 — name the passive attempt
      requestedTransport: Obd2ConnectTransport.ble,
      body: () => _connectByMacPassive(svc, mac),
    );

/// Body of [Obd2ConnectionService._teardownLastDirectChannel] (#2907;
/// #3760 — moved from the service file): close + null the prior
/// direct/passive channel.
Future<void> _teardownLastDirectChannelImpl(Obd2ConnectionService svc) async {
  final prior = svc._lastDirectChannel;
  svc._lastDirectChannel = null;
  if (prior == null) return;
  try {
    await prior.close();
  } catch (e, st) {
    // #2379 — OBD2/BLE, not local storage.
    unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
      'where': 'Obd2ConnectionService: prior-direct-channel teardown',
    }));
  }
}
