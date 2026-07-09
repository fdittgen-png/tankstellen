// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'obd2_self_test_driver.dart';

/// The per-step bodies + small pure helpers of the #2645 adapter
/// self-test. Lives in this `part` of `obd2_self_test_driver.dart` so the
/// driver file keeps its orchestration + public types under the 400-line
/// cap; everything here is `_`-private to the library.

Obd2SelfTestStepResult _step(
        Obd2SelfTestStepId id, Obd2SelfTestStepStatus status, int? latencyMs) =>
    Obd2SelfTestStepResult(id: id, status: status, latencyMs: latencyMs);

/// #3527 — route the self-test's one-shot connect through THE link
/// supervisor when one is wired: reuse its live service (never a second
/// dial against a link it owns), else join its single-flight machinery
/// via [Obd2LinkSupervisor.connectWith]. Bare [dial] when no supervisor
/// is available (unit tests / legacy path).
Future<Obd2Service?> _superviseDial(
  Obd2LinkSupervisor? sup,
  Obd2LinkDialer dial,
) async {
  if (sup == null) return dial();
  return sup.service ?? await sup.connectWith(dial);
}

/// #2969 / #3380 — transport-aware pinned connect for the self-test, stamping
/// `origin:selfTest` + the transport decision reason on the connect trace the
/// service opens. Routes by the inferred [transport]:
///
/// - **classic** → the RFCOMM direct path (`connectByMacClassicDirect`) — the
///   BLE direct path can ONLY 4 s-timeout for a Classic-SPP adapter (the real
///   vLinker FS trap), so this is the reliability fix that makes the self-test
///   actually connect to the user's hardware.
/// - **ble** → the BLE GATT direct path (`connectByMacDirect`).
/// - **null / unknown** → #3380: NO blind BLE default. Take the SAME
///   production resolver the picker uses (`connectByMacTransportAware`), which
///   scan-classifies the MAC + cross-transport falls back — so a Classic
///   adapter whose stored profile lacks a name (→ no inferable hint) still
///   connects over RFCOMM instead of burning a doomed 4 s BLE timeout. Recorded
///   as `no-hint-transport-aware` — visible, not silent.
Future<Obd2Service?> _selfTestConnect(
  Obd2ConnectionService connection,
  String pinnedMac, {
  required Obd2ConnectTransport? transport,
  required String decisionReason,
  String? adapterName,
}) =>
    Obd2ConnectTraceLog.runWithOrigin(
      Obd2ConnectOrigin.selfTest,
      transportDecisionReason: decisionReason,
      // #3014 — thread the resolved adapter NAME down so the self-test trace
      // headline reads the human name (e.g. `SmartOBD`) instead of just the
      // redacted MAC — the maintainer's #1 trace-tool complaint.
      () => switch (transport) {
        Obd2ConnectTransport.classic => connection.connectByMacClassicDirect(
            pinnedMac,
            adapterName: adapterName),
        Obd2ConnectTransport.ble =>
          connection.connectByMacDirect(pinnedMac, adapterName: adapterName),
        Obd2ConnectTransport.unknown ||
        null =>
          connection.connectByMacTransportAware(pinnedMac,
              adapterName: adapterName),
      },
    );

/// Info step: AT@1 (device description) + ATRV (battery voltage) are sent
/// RAW because they are absent from the production init list, and treated
/// as free-form "info" lines — a `12.4V` reply is `garbage` to the hex
/// classifier, so the step is judged ok when BOTH replies are non-empty
/// and carry no error token, rather than hex-classified.
Future<Obd2SelfTestStepResult> _infoStep(
  Obd2Service service,
  Obd2CommDiagnostics diag,
  Duration deadline,
) async {
  final sw = Stopwatch()..start();
  try {
    final desc = await service.sendCommand('AT@1\r').timeout(deadline);
    diag.recordHandshakeLine('AT@1', desc, sw.elapsedMilliseconds);
    final rvSw = Stopwatch()..start();
    final voltage = await service.sendCommand('ATRV\r').timeout(deadline);
    diag.recordHandshakeLine('ATRV', voltage, rvSw.elapsedMilliseconds);
    sw.stop();
    final ok = _looksLikeInfoReply(desc) && _looksLikeInfoReply(voltage);
    return _step(
      Obd2SelfTestStepId.info,
      ok ? Obd2SelfTestStepStatus.ok : Obd2SelfTestStepStatus.garbage,
      sw.elapsedMilliseconds,
    );
  } on TimeoutException {
    sw.stop();
    diag.recordHandshakeLine('ATRV', 'TIMEOUT', sw.elapsedMilliseconds);
    return _step(Obd2SelfTestStepId.info, Obd2SelfTestStepStatus.timeout,
        sw.elapsedMilliseconds);
  } catch (_) {
    sw.stop();
    return _step(Obd2SelfTestStepId.info, Obd2SelfTestStepStatus.fail,
        sw.elapsedMilliseconds);
  }
}

/// A free-form info reply (AT@1 / ATRV) is "ok" when it is non-empty and
/// carries no ELM error token (`?`, `NO DATA`, `STOPPED`, `UNABLE`).
bool _looksLikeInfoReply(String raw) {
  final trimmed = raw
      .replaceAll('>', ' ')
      .replaceAll('\r', ' ')
      .replaceAll('\n', ' ')
      .trim();
  if (trimmed.isEmpty) return false;
  final upper = trimmed.toUpperCase();
  if (upper.contains('?') ||
      upper.contains('NO DATA') ||
      upper.contains('NODATA') ||
      upper.contains('STOPPED') ||
      upper.contains('UNABLE')) {
    return false;
  }
  return true;
}

/// Supported-PID step (#3037): drive the SAME robust first-`0100` probe the
/// production connect path uses ([Obd2Service.discoverSupportedPids] →
/// `probeFirstSupportedPids`), instead of a single-shot `0100` that
/// false-failed on a slow link. The probe sends `0100` ONCE with the generous
/// protocol-search window (re-read, not re-send mid-search), tees the raw
/// reply into the connect trace + session transcript for observability, and
/// settles a tri-state ([Obd2Service.busProbe]) that maps onto the step:
///   - answered     → ok (a live ECU answered `41 00`);
///   - probedSilent → noResponse (the ECU is genuinely silent = engine-off,
///     which the #3009 verdict treats as the non-alarming engineOff, NOT a
///     hard fault);
///   - transient    → garbage (an indeterminate slow/flaky search — surfaced
///     but not a hard fault, so the #3009 verdict can still read engine-off).
/// [deadline] caps the WHOLE probe so a dead adapter can't freeze the step.
Future<Obd2SelfTestStepResult> _supportedPidsStep(
  Obd2Service service,
  Obd2CommDiagnostics diag,
  Duration deadline,
) async {
  final sw = Stopwatch()..start();
  try {
    // The probe records the raw `0100` reply (trace + transcript) itself via
    // its recordTrace tee, so we only map the tri-state result here.
    await service.discoverSupportedPids().timeout(deadline);
    sw.stop();
    final status = switch (service.busProbe) {
      Obd2BusProbeResult.answered => Obd2SelfTestStepStatus.ok,
      Obd2BusProbeResult.probedSilent => Obd2SelfTestStepStatus.noResponse,
      Obd2BusProbeResult.transient => Obd2SelfTestStepStatus.garbage,
      Obd2BusProbeResult.notProbed => Obd2SelfTestStepStatus.noResponse,
    };
    diag.recordSupportedTriState('0100',
        status == Obd2SelfTestStepStatus.ok ? 'supported' : 'unsupported');
    return _step(
        Obd2SelfTestStepId.supportedPids, status, sw.elapsedMilliseconds);
  } on TimeoutException {
    sw.stop();
    diag.recordSupportedTriState('0100', 'unknown');
    return _step(Obd2SelfTestStepId.supportedPids,
        Obd2SelfTestStepStatus.timeout, sw.elapsedMilliseconds);
  } catch (_) {
    sw.stop();
    return _step(Obd2SelfTestStepId.supportedPids, Obd2SelfTestStepStatus.fail,
        sw.elapsedMilliseconds);
  }
}

/// Sample-reads step: 010C / 010D / 0105, each `noteDispatch` + timed
/// `sendCommand` + classify + `noteResult`. The step is ok only when ALL
/// three classify ok; otherwise it reports the worst observed status so a
/// partially-answering ECU surfaces (timeout > garbage > noResponse > ok).
Future<Obd2SelfTestStepResult> _sampleReadsStep(
  Obd2Service service,
  Obd2CommDiagnostics diag,
  Duration deadline,
) async {
  const pids = ['010C', '010D', '0105'];
  var worst = Obd2SelfTestStepStatus.ok;
  final sw = Stopwatch()..start();
  for (final pid in pids) {
    diag.noteDispatch(pid);
    final pidSw = Stopwatch()..start();
    try {
      final raw = await service.sendCommand('$pid\r').timeout(deadline);
      pidSw.stop();
      final cls = classifyObd2Response(raw);
      diag.noteResult(pid, cls, rttMs: pidSw.elapsedMilliseconds);
      worst = _worse(worst, statusForResponseClass(cls));
    } on TimeoutException {
      pidSw.stop();
      diag.noteResult(pid, ResponseClass.timeout,
          rttMs: pidSw.elapsedMilliseconds);
      worst = _worse(worst, Obd2SelfTestStepStatus.timeout);
    } catch (_) {
      pidSw.stop();
      worst = _worse(worst, Obd2SelfTestStepStatus.fail);
    }
  }
  sw.stop();
  return _step(Obd2SelfTestStepId.sampleReads, worst, sw.elapsedMilliseconds);
}

/// Reconnect step: deliberate `disconnect()` (noteConnectionEvent drop)
/// then reconnect via the production `connectByMacDirect` machinery,
/// wall-clock-timed. Returns the (possibly new) live service for the final
/// clean disconnect. A reconnect failure CONTINUES (status fail).
Future<({Obd2SelfTestStepResult result, Obd2Service? service})> _reconnectStep(
  Obd2ConnectionService connection,
  Obd2Service service,
  Obd2CommDiagnostics diag,
  String? mac,
  Duration deadline, {
  Obd2ConnectTransport? transport,
  String decisionReason = 'no-hint-transport-aware',
  String? adapterName,
  Duration connectDeadline = const Duration(seconds: 15),
}) async {
  try {
    await service.disconnect();
  } catch (_) {
    // ignore: silent_catch — A failed deliberate drop still proceeds to attempt reconnect.
  }
  diag.noteConnectionEvent(drop: true);
  if (mac == null) {
    return (
      result: _step(
          Obd2SelfTestStepId.reconnect, Obd2SelfTestStepStatus.fail, null),
      service: null,
    );
  }
  final start = DateTime.now();
  try {
    // #2969 — transport-aware reconnect (Classic → RFCOMM) on its OWN connect
    // budget, mirroring the initial connect step.
    final reconnected = await _selfTestConnect(connection, mac,
            transport: transport,
            decisionReason: decisionReason,
            adapterName: adapterName)
        .timeout(connectDeadline);
    final elapsed = DateTime.now().difference(start).inMilliseconds;
    if (reconnected == null) {
      return (
        result: _step(Obd2SelfTestStepId.reconnect,
            Obd2SelfTestStepStatus.noResponse, elapsed),
        service: null,
      );
    }
    diag.noteConnectionEvent(
        visibleReconnect: true, timeToReconnectMs: elapsed);
    return (
      result: _step(
          Obd2SelfTestStepId.reconnect, Obd2SelfTestStepStatus.ok, elapsed),
      service: reconnected,
    );
  } on TimeoutException {
    final elapsed = DateTime.now().difference(start).inMilliseconds;
    return (
      result: _step(Obd2SelfTestStepId.reconnect,
          Obd2SelfTestStepStatus.timeout, elapsed),
      service: null,
    );
  } catch (_) {
    final elapsed = DateTime.now().difference(start).inMilliseconds;
    return (
      result: _step(
          Obd2SelfTestStepId.reconnect, Obd2SelfTestStepStatus.fail, elapsed),
      service: null,
    );
  }
}

/// Severity ordering for the worst-status fold in [_sampleReadsStep]:
/// fail > timeout > garbage > noResponse > ok.
Obd2SelfTestStepStatus _worse(
    Obd2SelfTestStepStatus a, Obd2SelfTestStepStatus b) {
  int rank(Obd2SelfTestStepStatus s) {
    switch (s) {
      case Obd2SelfTestStepStatus.ok:
        return 0;
      case Obd2SelfTestStepStatus.noResponse:
        return 1;
      case Obd2SelfTestStepStatus.garbage:
        return 2;
      case Obd2SelfTestStepStatus.timeout:
        return 3;
      case Obd2SelfTestStepStatus.fail:
      case Obd2SelfTestStepStatus.skipped:
        return 4;
    }
  }

  return rank(a) >= rank(b) ? a : b;
}

/// Build a partial report after an abort: mark the steps that never ran as
/// skipped so the UI shows where the test died.
Obd2SelfTestReport _finalise(
  List<Obd2SelfTestStepResult> results,
  Stopwatch overall,
) {
  final ran = results.map((r) => r.id).toSet();
  for (final id in Obd2SelfTestStepId.values) {
    if (!ran.contains(id)) {
      results.add(_step(id, Obd2SelfTestStepStatus.skipped, null));
    }
  }
  return _buildReport(results, overall);
}

Obd2SelfTestReport _buildReport(
  List<Obd2SelfTestStepResult> results,
  Stopwatch overall,
) {
  overall.stop();
  // The verdict (#3009) is tri-state: passed (every step ok), engineOff (the
  // adapter-capability steps all passed and only the live-data steps came back
  // ECU-silent — a healthy adapter on an engine-off bus), or failed (any
  // genuine fault / abort). An aborted run leaves skipped steps, which
  // [obd2SelfTestVerdict] treats as a hard fault, so it never reports passed.
  return Obd2SelfTestReport(
    steps: List.unmodifiable(results),
    verdict: obd2SelfTestVerdict(results),
    elapsedMs: overall.elapsedMilliseconds,
  );
}
