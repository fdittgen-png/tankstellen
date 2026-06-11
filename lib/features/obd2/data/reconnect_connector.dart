// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'adapter_registry.dart';
import 'obd2_comm_diagnostics.dart';
import 'obd2_connection_service.dart';
import 'obd2_read_telemetry.dart';
import 'obd2_reconnect_telemetry.dart';
import 'obd2_service.dart';
import 'reconnect_rssi_gate.dart';
import 'transport_fallback_policy.dart';

/// Drives a single in-trip reconnect attempt for a pinned adapter MAC,
/// DIRECT-CONNECT-FIRST with an RSSI-gated scan fallback (#2245).
///
/// Pulled out of `_buildReconnectScannerFactory` so the connect policy
/// is unit-testable in isolation against a real [Obd2ConnectionService]
/// + fake facade, rather than buried in a provider closure.
///
/// One instance lives per drop (per [AdapterReconnectScanner] the
/// controller builds), holding the small mutable bookkeeping the gate
/// needs across the scanner's repeated connect cycles:
///   * the strongest sighting seen so far ([_lastCandidate]),
///   * the RSSI at the last SUCCESSFUL connect ([_lastSuccessfulRssi]) —
///     the relative-RSSI gate baseline, and
///   * how many back-to-back scan batches have carried the MAC
///     ([_consecutiveBatchesSeen]).
///
/// On a successful connect the new [Obd2Service] is handed to
/// [onConnected] (the provider swaps its owned `_service` pointer) and
/// the attempt returns `true`.
class ReconnectConnector {
  final Obd2ConnectionService connection;

  /// Hook invoked with the freshly-connected service so the owner can
  /// swap its service pointer. Fired exactly once per successful attempt.
  final void Function(Obd2Service service) onConnected;

  /// Transport kind of the link that just dropped — `'ble'` / `'classic'`
  /// (#2565), read off the (dead-but-typed) live service at handle-drop
  /// time. Drives WHICH direct-connect path [attempt] / [attemptPassive]
  /// take: a Classic drop reconnects over RFCOMM (the BLE direct path can
  /// only ever 4 s-timeout for a Classic adapter — the field reconnect-storm
  /// signature), while `'ble'` / null keep the existing BLE-direct-first
  /// behaviour unchanged.
  final String? transportHint;

  /// #2905 — reads the scanner's current attempt ordinal + backoff so each
  /// recorded per-attempt telemetry row is correctly placed in the episode
  /// timeline. Null in unit contexts with no scanner wired (the rows then
  /// carry ordinal/backoff 0, still useful for the path/reason/rssi).
  /// Wired by `buildReconnectScannerFactory` after the scanner is built.
  int Function()? attemptNumber;
  int Function()? backoffMs;

  ResolvedObd2Candidate? _lastCandidate;
  int? _lastSuccessfulRssi;
  var _consecutiveBatchesSeen = 0;

  /// #2908 — count of [attempt] cycles where the PREFERRED transport (direct +
  /// scan) failed to establish a link this drop. The cross-transport fallback
  /// only fires once this reaches [crossTransportThreshold], so a single
  /// transient blip (which the direct / `channel.open()` retries already
  /// absorb) doesn't thrash BOTH transports — only a sustained storm on the
  /// preferred transport escalates to the alternate.
  var _preferredFailures = 0;

  /// #2908 — number of consecutive preferred-transport [attempt] failures
  /// after which the alternate transport is tried. 1 ⇒ try the alternate as
  /// soon as the first full direct+scan budget is exhausted; higher values
  /// wait for a sustained storm. Default 2: don't escalate on the very first
  /// miss, but don't let a wedged transport spin for long either.
  final int crossTransportThreshold;

  /// #3014 — the human adapter NAME of the link that dropped, read off the
  /// dead-but-typed live service at handle-drop time (symmetric to
  /// [transportHint]). Threaded into each reconnect connect so the trace
  /// headline names the adapter instead of showing only the redacted MAC. Null
  /// when unknown ⇒ the trace falls back to the MAC, exactly as before.
  final String? adapterName;

  ReconnectConnector({
    required this.connection,
    required this.onConnected,
    this.transportHint,
    this.adapterName,
    this.attemptNumber,
    this.backoffMs,
    this.crossTransportThreshold = 2,
  });

  /// #2905 — record one per-attempt reconnect-telemetry row (gated; a no-op
  /// unless `Feature.debugMode` armed the collector). [path] is
  /// `'direct'`/`'scan'`/`'passive'`; [reasonCode] is null on success and a
  /// [classifyReconnectReason] tag otherwise; [rssi] is set on the scan
  /// path only.
  void _recordAttempt({
    required bool succeeded,
    required String path,
    String? reasonCode,
    int? rssi,
    int latencyMs = 0,
  }) {
    final diag = Obd2CommDiagnostics.instance;
    if (!diag.enabled) return;
    diag.noteReconnectAttempt(
      attemptNumber: attemptNumber?.call() ?? 0,
      backoffMs: backoffMs?.call() ?? 0,
      succeeded: succeeded,
      reasonCode: reasonCode,
      rssi: rssi,
      latencyMs: latencyMs,
      path: path,
    );
  }

  /// `true` when the live link that dropped was Bluetooth Classic AND a
  /// Classic facade is wired (#2565). Drives the transport-correct reconnect
  /// dispatch: a Classic drop must NOT take the BLE direct path.
  bool get _isClassicDrop =>
      transportHint == 'classic' && connection.classicBluetooth != null;

  /// Strongest-seen candidate from the scan fallback. Exposed for tests.
  ResolvedObd2Candidate? get lastCandidate => _lastCandidate;

  /// RSSI recorded at the last successful scan-path connect this drop —
  /// the relative gate baseline. Null until a scan-path connect lands.
  int? get lastSuccessfulRssi => _lastSuccessfulRssi;

  /// Run one connect cycle for [mac]: direct first, gated scan fallback.
  /// Returns `true` once a session is established. Never throws —
  /// failures are logged and surfaced as `false` so the scanner keeps
  /// its backoff schedule.
  Future<bool> attempt(String mac) async {
    // 1) DIRECT-CONNECT FIRST — no scan, over the LIVE transport kind (#2565).
    //    A Classic drop reconnects over RFCOMM (`connectByMacClassicDirect`);
    //    a BLE / unknown drop keeps the BLE direct-GATT path (#2245). The BLE
    //    `channelForDirect` path can only ever 4 s-timeout for a Classic
    //    adapter (no `channelForDirect` on the Classic facade), so dispatching
    //    by transport is what de-flaps SPP adapters.
    final directSw = Stopwatch()..start();
    try {
      final direct = _isClassicDrop
          ? await connection.connectByMacClassicDirect(mac,
              adapterName: adapterName)
          : await connection.connectByMacDirect(mac,
              fallbackToScan: false, adapterName: adapterName);
      if (direct != null) {
        // A direct connect carries no RSSI (it never scanned), so the
        // relative-RSSI baseline is left as-is — it is only ever set
        // from a scan-path candidate, which has a real RSSI reading.
        _recordAttempt(
          succeeded: true,
          path: 'direct',
          latencyMs: directSw.elapsedMilliseconds,
        );
        onConnected(direct);
        return true;
      }
      // #2905 — a clean null (no throw) is a connect that didn't land:
      // the adapter wasn't reachable on the direct path this cycle.
      _recordAttempt(
        succeeded: false,
        path: 'direct',
        reasonCode: Obd2ReconnectReason.deviceNotConnected.code,
        latencyMs: directSw.elapsedMilliseconds,
      );
    } catch (e, st) {
      // #2905 — forward the reconnect-PATH failure reason (normalised) into
      // the per-attempt telemetry. The init-path channels only ever recorded
      // init reasons; this is the missing reconnect-path reason.
      _recordAttempt(
        succeeded: false,
        path: 'direct',
        reasonCode: classifyReconnectReason(e),
        latencyMs: directSw.elapsedMilliseconds,
      );
      // #2892 — an EXPECTED, user-surfaced connect condition (the bus is
      // silent / the dongle is out of range on a parked car) is a breadcrumb,
      // not an ERROR trace: this attempt repeats on the scanner's backoff
      // schedule, so a raw `errorLogger.log` here floods (error-log #22:
      // Obd2AdapterUnresponsive ×20). A genuine fault still ERROR-logs.
      recordObd2ConnectTransient(e, st,
          where: 'ReconnectConnector direct connect failed');
    }

    // 2) SCAN FALLBACK (ultimate). One scan window: track the strongest
    //    sighting + consecutive-batch count, and only connect when the
    //    relative-RSSI / two-batch gate passes. The scan merges BLE +
    //    Classic, so it is transport-aware: a Classic drop reaches its own
    //    bonded candidate here even after the (skipped-for-classic) BLE
    //    direct path. The [transportHint] lets the gate accept a bonded
    //    Classic sighting on the FIRST batch (#2565).
    try {
      await for (final batch in connection.scan()) {
        final seen = batch.where((c) => c.candidate.deviceId == mac);
        if (seen.isEmpty) {
          _consecutiveBatchesSeen = 0;
          continue;
        }
        _consecutiveBatchesSeen++;
        // Refresh lastCandidate to the strongest-seen advertisement.
        for (final c in seen) {
          if (_lastCandidate == null ||
              c.candidate.rssi > _lastCandidate!.candidate.rssi) {
            _lastCandidate = c;
          }
        }
        final candidate = _lastCandidate!;
        if (!shouldConnectFromScan(
          lastSuccessfulRssi: _lastSuccessfulRssi,
          seenRssi: candidate.candidate.rssi,
          consecutiveBatchesSeen: _consecutiveBatchesSeen,
          transportHint: transportHint,
          // #2907 — every scan the connector runs IS an in-trip recovery: the
          // MAC is pinned (no wrong-device risk), so relax the gate so a
          // marginal single-batch sighting of the dropped adapter is
          // attempted instead of spinning the backoff for another window.
          recovery: true,
        )) {
          // Too weak AND not yet seen twice — keep scanning this window;
          // a later batch may strengthen or repeat it.
          continue;
        }
        final scanSw = Stopwatch()..start();
        try {
          final svc = await connection.connect(candidate);
          _lastSuccessfulRssi = candidate.candidate.rssi;
          _recordAttempt(
            succeeded: true,
            path: 'scan',
            rssi: candidate.candidate.rssi,
            latencyMs: scanSw.elapsedMilliseconds,
          );
          onConnected(svc);
          return true;
          // ignore: catch_no_st — rethrow-only: the original stack is preserved by rethrow
        } catch (e) {
          // #2905 — record the per-candidate scan-connect failure (with its
          // sighting RSSI + normalised reason) then rethrow to the outer
          // de-noise handler, which keeps the existing breadcrumb behaviour.
          _recordAttempt(
            succeeded: false,
            path: 'scan',
            reasonCode: classifyReconnectReason(e),
            rssi: candidate.candidate.rssi,
            latencyMs: scanSw.elapsedMilliseconds,
          );
          rethrow;
        }
      }
    } catch (e, st) {
      // #2892 — same de-noise: a scan-path `connect(candidate)` that throws
      // the EXPECTED Obd2AdapterUnresponsive (classic_elm_channel.dart /
      // _openAndInit) on a silent bus is a breadcrumb, not an ERROR trace.
      recordObd2ConnectTransient(e, st,
          where: 'ReconnectConnector scan fallback failed');
    }

    // 3) CROSS-TRANSPORT FALLBACK (#2908). The preferred transport (the one
    //    that just dropped) exhausted its direct + scan budget this cycle —
    //    a BLE 133 storm or a Classic rfcomm-open-fail. Once that has happened
    //    [crossTransportThreshold] times this drop, try the OTHER transport
    //    for the same adapter (many ELM327 clones expose both a Classic SPP
    //    and a BLE GATT endpoint) rather than spin the backoff on the SAME
    //    doomed transport. Gated on the threshold so a single transient blip
    //    — which the direct / `channel.open()` retries already absorb —
    //    doesn't thrash BOTH transports. Best-effort: a clean failure just
    //    returns false and the scanner keeps its schedule.
    _preferredFailures++;
    if (_preferredFailures >= crossTransportThreshold &&
        await _attemptAlternateTransport(mac)) {
      return true;
    }
    return false;
  }

  /// #2908 — try the transport the live link was NOT using, once the
  /// preferred transport exhausted its direct + scan budget this cycle.
  /// Returns `true` once a session lands on the alternate transport (which is
  /// then handed to [onConnected]); `false` when the alternate is unavailable
  /// or also fails. The successful path is surfaced in the per-attempt
  /// telemetry as `'fallback-ble'` / `'fallback-classic'` and a
  /// [Obd2SessionState.reconnected] transition whose detail names the switch,
  /// so the next capture shows WHICH transport recovered the link.
  Future<bool> _attemptAlternateTransport(String mac) async {
    final alternate = alternateReconnectTransport(
      droppedTransport: transportHint,
      hasClassicFacade: connection.classicBluetooth != null,
    );
    if (alternate == null) return false; // no usable alternate wired
    final isClassic = alternate == BluetoothTransport.classic;
    final path = isClassic ? 'fallback-classic' : 'fallback-ble';
    final sw = Stopwatch()..start();
    try {
      // The dropped transport was Classic ⇒ try BLE direct; the dropped
      // transport was BLE/unknown ⇒ try Classic direct.
      final svc = isClassic
          ? await connection.connectByMacClassicDirect(mac,
              adapterName: adapterName)
          : await connection.connectByMacDirect(mac,
              fallbackToScan: false, adapterName: adapterName);
      if (svc != null) {
        _recordAttempt(
            succeeded: true, path: path, latencyMs: sw.elapsedMilliseconds);
        _noteTransportSwitch(alternate);
        onConnected(svc);
        return true;
      }
      _recordAttempt(
        succeeded: false,
        path: path,
        reasonCode: Obd2ReconnectReason.deviceNotConnected.code,
        latencyMs: sw.elapsedMilliseconds,
      );
    } catch (e, st) {
      _recordAttempt(
        succeeded: false,
        path: path,
        reasonCode: classifyReconnectReason(e),
        latencyMs: sw.elapsedMilliseconds,
      );
      // #2892 — the alternate transport on a silent bus / parked car raises
      // the EXPECTED user condition; breadcrumb it, don't ERROR-trace it.
      recordObd2ConnectTransient(e, st,
          where: 'ReconnectConnector alternate-transport fallback failed');
    }
    return false;
  }

  /// #2908 — record the connected→reconnected transition with a detail naming
  /// the transport switch (e.g. `'classic→ble'`), so the #2905 export shows
  /// which transport recovered the link. Gated; a no-op unless the collector
  /// is armed.
  void _noteTransportSwitch(BluetoothTransport landed) {
    final diag = Obd2CommDiagnostics.instance;
    if (!diag.enabled) return;
    final from = transportHint ?? 'unknown';
    final to = landed == BluetoothTransport.classic ? 'classic' : 'ble';
    diag.noteSessionTransition(
      Obd2SessionState.reconnected,
      detail: 'transport-fallback:$from→$to',
    );
  }

  /// Passive-wait connect cycle for [mac] (#2261 concern 2). Handed to
  /// the [AdapterReconnectScanner] as its `passiveConnect` callback: once
  /// the scanner hits its active-scan miss ceiling it stops burning the
  /// radio and waits on a low-power autoConnect GATT request instead.
  /// Returns `true` once a session is established. Never throws.
  ///
  /// #2565 — the passive path is a BLE autoConnect GATT wait, which is
  /// meaningless for a Classic adapter (the Classic facade has no
  /// autoConnect, and a BLE `channelForDirect` would only 4 s-timeout). For
  /// a Classic drop the cheap "wait" is instead a single bounded
  /// `connectByMacClassicDirect` retry — same paced cadence the scanner
  /// drives, but over the transport that can actually reconnect.
  Future<bool> attemptPassive(String mac) async {
    final passiveSw = Stopwatch()..start();
    try {
      final svc = _isClassicDrop
          ? await connection.connectByMacClassicDirect(mac,
              adapterName: adapterName)
          : await connection.connectByMacPassive(mac, adapterName: adapterName);
      if (svc != null) {
        _recordAttempt(
          succeeded: true,
          path: 'passive',
          latencyMs: passiveSw.elapsedMilliseconds,
        );
        onConnected(svc);
        return true;
      }
      _recordAttempt(
        succeeded: false,
        path: 'passive',
        reasonCode: Obd2ReconnectReason.deviceNotConnected.code,
        latencyMs: passiveSw.elapsedMilliseconds,
      );
    } catch (e, st) {
      _recordAttempt(
        succeeded: false,
        path: 'passive',
        reasonCode: classifyReconnectReason(e),
        latencyMs: passiveSw.elapsedMilliseconds,
      );
      // #2892 — same de-noise: the paced passive/Classic retry on a parked
      // car routinely raises the EXPECTED user condition; breadcrumb it.
      recordObd2ConnectTransient(e, st,
          where: 'ReconnectConnector passive connect failed');
    }
    return false;
  }
}
