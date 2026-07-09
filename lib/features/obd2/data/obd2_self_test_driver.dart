// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'obd2_comm_diagnostics.dart';
import 'obd2_connect_trace.dart';
import 'obd2_connect_trace_log.dart';
import 'obd2_connection_errors.dart';
import 'obd2_connection_service.dart';
import 'obd2_link_supervisor.dart';
import 'obd2_response_class.dart';
import 'obd2_service.dart';

/// The per-step implementations + small pure helpers live in this `part`
/// so the driver file stays under the #1680/#2351 400-line cap — the
/// orchestration + public types stay here, the step bodies move next door.
part 'obd2_self_test_steps.dart';

/// Active OBD2 adapter self-test (#2645) — a pure async DRIVER layered
/// over the already-shipped connection service + comm-diagnostics infra
/// (#2463/#2464). NOT a new OBD2 stack: it drives the existing
/// [Obd2ConnectionService] + the [Obd2Service] it returns, and tees every
/// step into [Obd2CommDiagnostics.instance] so the full trace shows on the
/// OBD2 health screen (Live / Recent sessions + Copy-as-JSON) for free.
///
/// The explicit goal is a FULL diagnostic trace even on a failing adapter:
/// scan/connect failure ABORTS (still finalising the partial session so
/// the trace shows where it died); every later step (info/PID/sample/
/// reconnect) CONTINUES on failure so a flaky dongle still yields a
/// complete per-step picture. The driver ALWAYS `disconnect()`s +
/// `endSession()`s in a `finally`, so a throw mid-sequence never leaks the
/// link or an unfinalised session.
///
/// Timeouts are NEVER inferred from text (per `obd2_response_class.dart`):
/// every command is wrapped in `.timeout(stepDeadline)` and a
/// [TimeoutException] is recorded directly as [ResponseClass.timeout].

/// Synthetic init-transcript `cmd` that tags a session as a self-test
/// (#2645 option B). A reader keys off `cmd == selfTestTag` to tell a
/// self-test session from a passive recording capture — no freezed field
/// on the near-cap session model. Not user-facing: it is debug transcript
/// content (the same category as a raw `ATZ`/`ATI` line), so it is exempt
/// from ARB the way every other transcript token is.
// i18n-ignore: debug transcript marker, not user-facing UI text (#2645).
const String selfTestTag = 'SELF-TEST';

/// The synthetic transcript line's response field, recorded the moment the
/// self-test session opens. A human-readable marker for the transcript +
/// Copy-as-JSON export.
// i18n-ignore: debug transcript marker, not user-facing UI text (#2645).
const String selfTestStartedSummary = 'adapter self-test (#2645)';

/// The synthetic transcript line recorded on the post-reconnect session so
/// it, too, is identifiable as a self-test trace.
// i18n-ignore: debug transcript marker, not user-facing UI text (#2645).
const String selfTestReconnectSummary = 'adapter self-test reconnect (#2645)';

/// The seven self-test steps, in run order. Used as a stable key the UI
/// localises (`obd2TestStep<Name>`) and the controller renders per-step.
enum Obd2SelfTestStepId {
  scan,
  connect,
  info,
  supportedPids,
  sampleReads,
  reconnect,
  disconnect,
}

/// Per-step outcome status. [skipped] marks a step the driver never
/// reached because an earlier scan/connect failure aborted the run.
enum Obd2SelfTestStepStatus { ok, timeout, garbage, noResponse, fail, skipped }

/// The overall verdict of a self-test run (#3009).
///
/// A pure pass/fail boolean conflated two very different field outcomes: a
/// genuine adapter fault (RED — connect/init/rfcomm died) and the #1 real
/// non-fault condition, a perfectly healthy adapter on a SILENT bus because
/// the engine is off. The ELM327 is powered from the OBD port even with the
/// ignition off, so it answers every AT command (connect / init / info /
/// reconnect / disconnect all pass) — only the LIVE-DATA steps (supported
/// PIDs `0100` + sample reads) come back ECU-silent (`SEARCHING…STOPPED` /
/// `NO DATA`). Reporting that as a red "adapter test FAILED" blamed hardware
/// that is fine. [engineOff] is the distinct, non-alarming verdict for it.
enum Obd2SelfTestVerdict {
  /// Every step passed — the adapter AND the vehicle bus answered.
  passed,

  /// Every ADAPTER-capability step (scan/connect/info/reconnect/disconnect)
  /// passed, and the ONLY failing steps are the live-data steps (supported
  /// PIDs + sample reads) with the engine-off / ECU-silent signature
  /// (`noResponse` / `garbage`). The adapter is OK — the engine is off.
  engineOff,

  /// A genuine failure — a connect/init/rfcomm step failed, a live-data step
  /// timed out / threw (not the engine-off signature), or the run aborted
  /// (skipped steps). RED.
  failed,
}

/// The two LIVE-DATA self-test steps — the only steps that need a running
/// engine (the vehicle ECU on the bus), as opposed to the ADAPTER-capability
/// steps which a powered ELM327 answers with the ignition off (#3009).
const Set<Obd2SelfTestStepId> kObd2LiveDataSteps = {
  Obd2SelfTestStepId.supportedPids,
  Obd2SelfTestStepId.sampleReads,
};

/// The per-step statuses that signal an ECU-silent / engine-off bus rather
/// than an adapter fault (#3009): `noResponse` (`NO DATA`) and `garbage`
/// (`SEARCHING…STOPPED` / `UNABLE TO CONNECT` / `?`). A `timeout` (the adapter
/// itself stopped answering), a `fail` (a thrown exception) or a `skipped`
/// (the run aborted earlier) are NOT engine-off — they stay RED.
const Set<Obd2SelfTestStepStatus> kObd2EngineOffStatuses = {
  Obd2SelfTestStepStatus.noResponse,
  Obd2SelfTestStepStatus.garbage,
};

/// One completed step of the self-test: which step, how it ended, and how
/// long the (timed) command(s) took. Emitted via the `onStep` callback so
/// the controller can animate live progress.
class Obd2SelfTestStepResult {
  const Obd2SelfTestStepResult({
    required this.id,
    required this.status,
    this.latencyMs,
  });

  final Obd2SelfTestStepId id;
  final Obd2SelfTestStepStatus status;
  final int? latencyMs;

  bool get passed => status == Obd2SelfTestStepStatus.ok;
}

/// Aggregate result of a full self-test run.
class Obd2SelfTestReport {
  const Obd2SelfTestReport({
    required this.steps,
    required this.verdict,
    required this.elapsedMs,
  });

  final List<Obd2SelfTestStepResult> steps;

  /// The tri-state verdict (#3009): passed / engineOff / failed. Replaces the
  /// former pure `passed` boolean so the engine-off (adapter-OK) condition is
  /// reported distinctly instead of as a red failure.
  final Obd2SelfTestVerdict verdict;
  final int elapsedMs;

  /// Back-compat convenience: `true` ONLY when every step passed. An
  /// engine-off verdict is NOT `passed` (the live-data steps did not answer)
  /// but is also NOT a failure — callers that care render [verdict] directly.
  bool get passed => verdict == Obd2SelfTestVerdict.passed;

  int get passCount => steps.where((s) => s.passed).length;
  int get stepCount => steps.length;
}

/// Classify a completed self-test [steps] list into a tri-state verdict
/// (#3009). Engine-off = every ADAPTER-capability step passed AND the ONLY
/// non-ok steps are the live-data steps, each with the ECU-silent signature
/// (`noResponse` / `garbage`). All-ok ⇒ passed; anything else ⇒ failed.
Obd2SelfTestVerdict obd2SelfTestVerdict(List<Obd2SelfTestStepResult> steps) {
  if (steps.isEmpty) return Obd2SelfTestVerdict.failed;
  if (steps.every((s) => s.status == Obd2SelfTestStepStatus.ok)) {
    return Obd2SelfTestVerdict.passed;
  }
  final liveDataRan = steps.where((s) => kObd2LiveDataSteps.contains(s.id));
  final adapterSteps =
      steps.where((s) => !kObd2LiveDataSteps.contains(s.id));
  // Engine-off requires: every adapter-capability step OK, every non-ok step
  // is a live-data step, and at least one live-data step shows the engine-off
  // signature while NONE shows a hard fault (timeout / fail / skipped).
  final adapterAllOk =
      adapterSteps.every((s) => s.status == Obd2SelfTestStepStatus.ok);
  final liveDataAllEngineOffOrOk = liveDataRan.every((s) =>
      s.status == Obd2SelfTestStepStatus.ok ||
      kObd2EngineOffStatuses.contains(s.status));
  final anyLiveDataEngineOff = liveDataRan
      .any((s) => kObd2EngineOffStatuses.contains(s.status));
  if (adapterAllOk && liveDataAllEngineOffOrOk && anyLiveDataEngineOff) {
    return Obd2SelfTestVerdict.engineOff;
  }
  return Obd2SelfTestVerdict.failed;
}

/// Map a non-timeout [ResponseClass] onto the self-test step status. ok →
/// ok; noData → noResponse (the ECU said nothing for the PID); every
/// error/garbage bucket → garbage; timeout is handled by the caller (it is
/// never produced by the classifier).
Obd2SelfTestStepStatus statusForResponseClass(ResponseClass cls) {
  switch (cls) {
    case ResponseClass.ok:
      return Obd2SelfTestStepStatus.ok;
    case ResponseClass.noData:
      return Obd2SelfTestStepStatus.noResponse;
    case ResponseClass.timeout:
      return Obd2SelfTestStepStatus.timeout;
    case ResponseClass.bufferFull:
    case ResponseClass.canError:
    case ResponseClass.unrecognized:
    case ResponseClass.garbage:
      return Obd2SelfTestStepStatus.garbage;
  }
}

/// Run the active adapter self-test over [connection].
///
/// [onStep] fires once per completed step (running → terminal) so the
/// controller can push live UI state. [isCancelled] is polled between
/// steps to short-circuit to the `finally`. [stepDeadline] caps each
/// per-command read so a dead adapter cannot freeze the run. [connectDeadline]
/// (#2969) caps the WHOLE connect step separately + longer than [stepDeadline]:
/// a worst-case connect (a clone that needs 2-3 RFCOMM retries ≈ 13 s) is far
/// longer than a single AT read, so a 6 s connect cap reported a false
/// "0 of 7" timeout on real hardware. [pinnedMac], when non-null, takes the
/// no-scan direct-connect + visible-reconnect path (the production reconnect
/// machinery); otherwise the test scans. [transportHint] (#2969) routes the
/// pinned connect + reconnect over the inferred transport — Classic takes the
/// RFCOMM path (`connectByMacClassicDirect`) instead of the BLE GATT direct
/// path, which can ONLY 4 s-timeout for a Classic-SPP adapter (the real vLinker
/// FS trap). A null hint no longer defaults to BLE (#3380): it routes through
/// the production `connectByMacTransportAware` resolver (scan-classify +
/// cross-transport fallback) and records `no-hint-transport-aware` on the
/// trace — visible, not silent.
Future<Obd2SelfTestReport> runObd2SelfTest(
  Obd2ConnectionService connection, {
  void Function(Obd2SelfTestStepResult step)? onStep,
  bool Function()? isCancelled,
  Duration stepDeadline = const Duration(seconds: 6),
  // #3035/#3037 — the `0100` step is the FIRST OBD request on the bus, so it
  // triggers the ELM327 protocol search (`SEARCHING…`), whose real answer can
  // arrive several seconds later. The step now drives the SAME robust probe as
  // production ([Obd2Service.discoverSupportedPids] → `probeFirstSupportedPids`),
  // whose generous single-shot search window is [kObd2ProtocolSearchTimeout]
  // (~15 s). This whole-step deadline must therefore sit ABOVE that window so
  // the self-test never false-cuts a search the probe was about to WIN (which
  // would mis-report a live-but-slow ECU as a hard `timeout` fault instead of
  // the correct engine-on pass / engine-off verdict).
  Duration supportedPidsDeadline = const Duration(seconds: 18),
  Duration connectDeadline = const Duration(seconds: 15),
  String? pinnedMac,
  Obd2ConnectTransport? transportHint,
  String? adapterName,
  // #3527 — THE one link supervisor; when wired, the connect step reuses its
  // live service / joins its single-flight dial, and the final teardown
  // KEEP-LINKs a supervisor-owned service. Null = bare dial (tests).
  Obd2LinkSupervisor? linkSupervisor,
}) async {
  // #3380 — a null/unknown hint no longer hard-defaults to BLE; it routes
  // through the production transport-aware resolver (see [_selfTestConnect]),
  // so the decision reason reflects that, not a doomed BLE default.
  final decisionReason = switch (transportHint) {
    Obd2ConnectTransport.classic => 'name-matched-classic',
    Obd2ConnectTransport.ble => 'name-matched-ble',
    Obd2ConnectTransport.unknown || null => 'no-hint-transport-aware',
  };
  final diag = Obd2CommDiagnostics.instance;
  final priorEnabled = diag.enabled;
  // The self-test is itself a Developer-mode action, so arm the collector
  // for the run regardless of the live gate — and RESTORE the prior value
  // in finally so it never silently arms the passive collector.
  diag.enabled = true;
  // #2969 correction 1 — the connection service already opened the connect
  // trace at its entry point; stamp THIS run's origin onto it so the health
  // screen reads "self-test" (the service can't know who called it). The
  // service opens the trace synchronously inside the connect call below, so the
  // stamp lands once a trace is active — done right after the connect attempt.

  final results = <Obd2SelfTestStepResult>[];
  final overall = Stopwatch()..start();
  Obd2Service? service;

  void emit(Obd2SelfTestStepResult r) {
    results.add(r);
    onStep?.call(r);
  }

  bool cancelled() => isCancelled?.call() ?? false;

  try {
    // --- 1+2. scan / connect (single connect call runs both) -----------
    // A connect failure ABORTS: there is nothing to test without a link.
    final connectSw = Stopwatch()..start();
    try {
      // #2969 — transport-aware pinned connect: a Classic adapter takes the
      // RFCOMM direct path (the BLE direct path would only 4 s-timeout); the
      // connect step gets its OWN longer budget ([connectDeadline]).
      // #3527 — the dial routes through THE link supervisor when wired
      // (reuse-live / single-flight, see [_superviseDial]); the controller's
      // no-live-recording guard remains the first line of defence.
      service = await _superviseDial(
          linkSupervisor,
          () async => pinnedMac != null
              ? await _selfTestConnect(connection, pinnedMac,
                      transport: transportHint,
                      decisionReason: decisionReason,
                      adapterName: adapterName)
                  .timeout(connectDeadline)
              : await connection.connectBest().timeout(connectDeadline));
    } on TimeoutException {
      connectSw.stop();
      emit(_step(Obd2SelfTestStepId.scan, Obd2SelfTestStepStatus.timeout,
          connectSw.elapsedMilliseconds));
      return _finalise(results, overall);
    } on Obd2ConnectionError {
      connectSw.stop();
      emit(_step(Obd2SelfTestStepId.scan, Obd2SelfTestStepStatus.fail,
          connectSw.elapsedMilliseconds));
      return _finalise(results, overall);
    } catch (_) {
      connectSw.stop();
      emit(_step(Obd2SelfTestStepId.scan, Obd2SelfTestStepStatus.fail,
          connectSw.elapsedMilliseconds));
      return _finalise(results, overall);
    }
    connectSw.stop();

    if (service == null) {
      // No usable adapter (no scan match / nothing connectable).
      emit(_step(Obd2SelfTestStepId.scan, Obd2SelfTestStepStatus.noResponse,
          connectSw.elapsedMilliseconds));
      return _finalise(results, overall);
    }
    // scan + connect both succeeded; `service.connect()` already opened the
    // diagnostics session + teed the init transcript. Tag this session as a
    // self-test with a synthetic transcript line (#2645 option B — no model
    // change): the health screen + Copy-as-JSON render it verbatim, and the
    // `cmd == selfTestTag` convention lets a reader filter test sessions
    // without a freezed field on the near-cap session model.
    diag.recordHandshakeLine(selfTestTag, selfTestStartedSummary, 0);
    emit(_step(Obd2SelfTestStepId.scan, Obd2SelfTestStepStatus.ok, 0));
    emit(_step(Obd2SelfTestStepId.connect, Obd2SelfTestStepStatus.ok,
        connectSw.elapsedMilliseconds));

    // --- 3. info — RAW AT@1 / ATRV (absent from the production init) ----
    if (!cancelled()) {
      final infoStatus = await _infoStep(service, diag, stepDeadline);
      emit(infoStatus);
    }

    // --- 4. supportedPids — 0100 bitmask -------------------------------
    // #3035 — uses the search-aware [supportedPidsDeadline] (not the generic
    // [stepDeadline]) so a protocol-searching ECU isn't false-timed-out.
    if (!cancelled()) {
      emit(await _supportedPidsStep(service, diag, supportedPidsDeadline));
    }

    // --- 5. sampleReads — 010C / 010D / 0105 ---------------------------
    if (!cancelled()) {
      emit(await _sampleReadsStep(service, diag, stepDeadline));
    }

    // --- 6. reconnect — deliberate drop + reconnect --------------------
    // The reconnect goes through the production `connectByMacDirect` →
    // `service.connect()` machinery, which calls `beginSession()` and so
    // FINALISES the rich pre-reconnect session (init/info/PID/sample) and
    // opens a fresh one. That is correct + intentional: the health screen
    // then shows a pre-reconnect trace AND a post-reconnect trace, both
    // self-test-tagged — the reconnect-recovery picture lives in its own
    // session, exactly as a real dropped-then-reconnected trip would.
    if (!cancelled()) {
      final mac = pinnedMac ?? service.adapterMac;
      final reconnected = await _reconnectStep(
          connection, service, diag, mac, stepDeadline,
          transport: transportHint,
          decisionReason: decisionReason,
          adapterName: adapterName,
          connectDeadline: connectDeadline);
      emit(reconnected.result);
      if (reconnected.service != null) {
        // Re-tag the post-reconnect session so BOTH self-test sessions are
        // identifiable by the `cmd == selfTestTag` convention.
        diag.recordHandshakeLine(selfTestTag, selfTestReconnectSummary, 0);
        service = reconnected.service;
      }
    }
  } finally {
    // ALWAYS tear down + finalise so a failing adapter never leaks the
    // link and the trace is always persisted to the health protocol.
    // #3527 KEEP-LINK — never disconnect a service the supervisor owns.
    try {
      if (!identical(linkSupervisor?.service, service)) {
        await service?.disconnect();
      }
    } catch (_) {
      // ignore: silent_catch — Disconnect is best-effort; the session is finalised regardless.
    }
    diag.endSession();
    diag.enabled = priorEnabled;
  }

  // --- 7. clean disconnect (the finally above ran it) -----------------
  emit(_step(Obd2SelfTestStepId.disconnect, Obd2SelfTestStepStatus.ok, 0));
  return _buildReport(results, overall);
}
