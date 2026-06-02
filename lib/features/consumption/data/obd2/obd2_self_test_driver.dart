// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'obd2_comm_diagnostics.dart';
import 'obd2_connection_errors.dart';
import 'obd2_connection_service.dart';
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
    required this.passed,
    required this.elapsedMs,
  });

  final List<Obd2SelfTestStepResult> steps;
  final bool passed;
  final int elapsedMs;

  int get passCount => steps.where((s) => s.passed).length;
  int get stepCount => steps.length;
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
/// command so a dead adapter cannot freeze the run. [pinnedMac], when
/// non-null, takes the no-scan direct-connect + visible-reconnect path
/// (the production reconnect machinery); otherwise the test scans.
Future<Obd2SelfTestReport> runObd2SelfTest(
  Obd2ConnectionService connection, {
  void Function(Obd2SelfTestStepResult step)? onStep,
  bool Function()? isCancelled,
  Duration stepDeadline = const Duration(seconds: 6),
  String? pinnedMac,
}) async {
  final diag = Obd2CommDiagnostics.instance;
  final priorEnabled = diag.enabled;
  // The self-test is itself a Developer-mode action, so arm the collector
  // for the run regardless of the live gate — and RESTORE the prior value
  // in finally so it never silently arms the passive collector.
  diag.enabled = true;

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
      service = pinnedMac != null
          ? await connection
              .connectByMacDirect(pinnedMac)
              .timeout(stepDeadline)
          : await connection.connectBest().timeout(stepDeadline);
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
    if (!cancelled()) {
      emit(await _supportedPidsStep(service, diag, stepDeadline));
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
          connection, service, diag, mac, stepDeadline);
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
    try {
      await service?.disconnect();
    } catch (_) {
      // Disconnect is best-effort; the session is finalised regardless.
    }
    diag.endSession();
    diag.enabled = priorEnabled;
  }

  // --- 7. clean disconnect (the finally above ran it) -----------------
  emit(_step(Obd2SelfTestStepId.disconnect, Obd2SelfTestStepStatus.ok, 0));
  return _buildReport(results, overall);
}
