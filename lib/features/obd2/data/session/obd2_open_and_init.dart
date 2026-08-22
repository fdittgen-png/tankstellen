// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'obd2_connection_service.dart';

/// The shared open→init chokepoint for [Obd2ConnectionService], extracted
/// as a `part` (#3760 decomposition — move-only, behaviour preserved) so
/// the service file stays under the #1680 file-length cap. Every connect
/// path funnels through [_openAndInitImpl] via the thin private
/// `Obd2ConnectionService._openAndInit` delegate, which keeps the sibling
/// `part`s' `svc._openAndInit(...)` call sites unchanged.

/// Vehicle identity the supported-PID cache (#811/#2253) refines its
/// per-adapter key with. Supplied lazily by the [Obd2ConnectionService]
/// owner so the data layer never depends on the vehicle feature's
/// providers directly — the Riverpod provider resolves the active
/// profile and hands these three fields through.
typedef Obd2VehicleKeyFields = ({
  String? make,
  String? model,
  int? year,
  String? vin,
});

/// Shared channel → transport → service → init sequence used by both
/// the scan-based [connect] and the no-scan [connectByMacDirect]
/// (#2242). Keeping it in ONE place guarantees a direct connect
/// produces a session identical to the scan path — notably the
/// service-side ELM327 init (`adapter.initSequence` via
/// [Obd2Service.connect]), which the transport itself no longer runs
/// (#2233). Surfaces [Obd2AdapterUnresponsive] when init fails (the
/// channel is closed first).
/// (#3760 — the body moved here from the service file, verbatim.)
Future<Obd2Service> _openAndInitImpl(
  Obd2ConnectionService svc, {
  required ElmByteChannel channel,
  required Elm327Adapter adapter,
  required String mac,
  required String name,
  String linkKind = 'ble',
  bool logFailureAsError = true,
}) async {
  // #3244 — capture THIS attempt's trace now: by failure time a preempted
  // zombie's `Obd2ConnectTraceLog.active` may already be the NEW holder's
  // root, and stamping a classification there corrupts the rival's trace.
  final ownTrace = Obd2ConnectTraceLog.active;
  // #2253/#2261 — build the session with the supported-PID + warm
  // negotiated-protocol caches wired in (see [buildObd2Session]).
  final vehicle = svc.activeVehicleKeyFields?.call();
  final service = buildObd2Session(
    channel: channel,
    mac: mac,
    name: name,
    pidsCache: svc.supportedPidsCache,
    protocolCache: svc.negotiatedProtocolCache,
    make: vehicle?.make,
    model: vehicle?.model,
    year: vehicle?.year,
    vin: vehicle?.vin,
    linkKind: linkKind, // #2465 — gated comm-diagnostics session label
  );
  // #3181 — FIRST-connect detection: a deviceId with NO recorded
  // successful connect (and that isn't the auto-pinned last-good
  // adapter — the pre-#3181 migration case) gets pairing mode armed for
  // the duration of this attempt, so the BLE channel widens the
  // setNotify budget to the 30 s pairing window and the UI can show the
  // "confirm the pairing request" hint. Cleared in `finally` so a
  // failed attempt never leaks the mode.
  final firstConnect = _isFirstConnectDevice(svc, mac);
  if (firstConnect) {
    Obd2PairingMode.markFirstConnect(mac);
    Obd2ConnectTraceLog.active?.addStep(
      label: 'first-connect',
      status: Obd2ConnectStepStatus.ok,
      detail: 'deviceId has no prior successful connect — '
          '${Obd2PairingMode.firstConnectSetNotifySecs}s pairing budget '
          'armed (#3181)',
    );
  }
  try {
    // #2268 concern 3 — a no-op override suppresses the wake window for a
    // MAC observed never to need it; null ⇒ honour the adapter policy.
    final wakeOverride = await svc.adapterWakeCache?.overrideFor(mac);
    // #1330 init. #2379 — recoverable attempts suppress the fail trace.
    final ok = await service.connect(adapter: adapter,
        wakePolicyOverride: wakeOverride,
        logFailureAsError: logFailureAsError);
    // #2268 concern 3 — persist the observed wake outcome (no-op unless the bounded window ran).
    await svc.adapterWakeCache
        ?.recordObservation(mac, service.wakeObservation);
    if (!ok) {
      // #2969 — `Obd2Service.connect` swallowed the real failure into a
      // `false`, so classify the connect-trace outcome from the AT
      // transcript teed so far (first-wins keeps channel-layer stamps):
      // ATZ garbage → counterfeit clone, an AT timeout → init timeout,
      // else silent ECU / ignition off. Stamped on the attempt's OWN
      // trace (#3244); a no-op for a non-connect-path caller.
      final trace = ownTrace;
      if (trace != null && !trace.hasOutcome) {
        trace.setOutcome(trace.classifyInitFailureOutcome());
      }
      await service.disconnect();
      // #3181 — a pairing-classified failure (stamped first-wins at the
      // channel-open catch / Obd2Service.connect) surfaces TYPED so the
      // by-MAC paths skip the masking scan fallback and the UI shows the
      // "power-cycle and retry within 5 minutes" guidance.
      if (trace?.outcome == Obd2ConnectOutcome.pairingRequired) {
        throw const Obd2PairingRequired();
      }
      throw const Obd2AdapterUnresponsive();
    }
    // #3181 — ANY successful init (even an engine-off one) proves the
    // BOND + link work, so the deviceId is no longer a first connect.
    await svc.knownAdaptersStore?.markKnownGood(mac);
  } finally {
    if (firstConnect) Obd2PairingMode.clearFirstConnect(mac);
  }
  // #3009/#3035 — init SUCCEEDED (every AT answered) but the vehicle bus
  // may be SILENT. CRITICAL distinction (#3035): the `0100` probe is now
  // tri-state ([Obd2Service.busProbe]). Stamp `ignitionOff` ONLY on
  // [Obd2BusProbeResult.probedSilent] — the ECU stayed silent through every
  // retry, the real engine-off signature. A [Obd2BusProbeResult.transient]
  // (the first `0100` merely TIMED OUT during the protocol search on a slow
  // clone) must NOT be classified engine-off — that was the false positive
  // that told a live car "turn the ignition on" and spun reconnects. The
  // connect still returns the service either way (first-wins on the trace);
  // we only correct the CLASSIFICATION, never the working connect path.
  if (service.busProbe == Obd2BusProbeResult.probedSilent) {
    ownTrace?.setOutcome(Obd2ConnectOutcome.ignitionOff); // #3244 own trace
  }
  // #3019 / Epic #3013 phase 3 — auto-pin the last-good adapter so the
  // trip-INDEPENDENT reconnect controller can try the fast pinned path on
  // the next drop. #3035 — but do NOT pin on a confirmed engine-off
  // (`probedSilent`): pinning a silent-bus connect is exactly what fed the
  // teardown→reconnect→engine-off loop. The HARDWARE link is good on a
  // [Obd2BusProbeResult.answered] OR [Obd2BusProbeResult.transient] connect
  // (a slow-but-live car) and on a warm cache-hit (`busAnswered`), so pin in
  // those cases. Best-effort + local-only (the store swallows + logs a write
  // failure), so it never derails a connect that just succeeded.
  final pinnable = service.busProbe != Obd2BusProbeResult.probedSilent &&
      (service.busAnswered ||
          service.busProbe == Obd2BusProbeResult.transient);
  if (pinnable) {
    await svc.lastGoodAdapterStore?.recordFrom(
      mac: service.adapterMac,
      transportKind: service.linkKind,
      name: service.adapterName,
    );
  }
  return service;
}

/// #3181 — whether [mac] has NEVER completed a successful connect on this
/// phone. False when no [knownAdaptersStore] is wired (tests / legacy
/// configs — pairing mode is then never armed), when the store knows the
/// id, or when it matches the auto-pinned last-good adapter (a pre-#3181
/// user must not re-enter pairing mode before the store backfills).
bool _isFirstConnectDevice(Obd2ConnectionService svc, String mac) {
  final store = svc.knownAdaptersStore;
  if (store == null) return false;
  if (store.isKnownGood(mac)) return false;
  final pinned = svc.lastGoodAdapterStore?.recall();
  if (pinned != null &&
      pinned.mac.trim().toUpperCase() == mac.trim().toUpperCase()) {
    return false;
  }
  return true;
}
