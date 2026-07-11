// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'obd2_response_class.dart';

/// Public model + verdict types of the #2645 adapter self-test, split out
/// of `obd2_self_test_driver.dart` in #3555 (the driver sat at the exact
/// 400-line cap and gained three new diagnostic layers). The driver
/// re-exports this file, so callers keep importing the driver unchanged.

/// The self-test steps, in run order (#3555 — the deep layered ladder).
///
/// Layer map: [bluetooth] = the PHONE's radio stack; [scan]/[connect] =
/// the transport/socket layer; [info] = the ELM adapter chip itself;
/// [supportedPids]/[protocol] = the vehicle-bus negotiation;
/// [sampleReads]/[soak] = live vehicle data (single reads + sustained
/// polling at recording cadence); [reconnect]/[disconnect] = the
/// recovery/teardown machinery. Used as a stable key the UI localises
/// (`obd2TestStep<Name>`) and the controller renders per-step.
enum Obd2SelfTestStepId {
  bluetooth,
  scan,
  connect,
  info,
  supportedPids,
  protocol,
  sampleReads,
  soak,
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

/// The LIVE-DATA self-test steps — the only steps that need a running
/// engine (the vehicle ECU on the bus), as opposed to the ADAPTER-capability
/// steps which a powered ELM327 answers with the ignition off (#3009).
/// #3555 — [Obd2SelfTestStepId.protocol] (an unanswered bus negotiates no
/// protocol) and [Obd2SelfTestStepId.soak] (sustained reads return NO DATA
/// on a silent bus) join the set.
const Set<Obd2SelfTestStepId> kObd2LiveDataSteps = {
  Obd2SelfTestStepId.supportedPids,
  Obd2SelfTestStepId.protocol,
  Obd2SelfTestStepId.sampleReads,
  Obd2SelfTestStepId.soak,
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

/// One completed step of the self-test: which step, how it ended, how
/// long the (timed) command(s) took, and (#3555) the DATA the layer
/// yielded. Emitted via the `onStep` callback so the controller can
/// animate live progress.
class Obd2SelfTestStepResult {
  const Obd2SelfTestStepResult({
    required this.id,
    required this.status,
    this.latencyMs,
    this.detail,
  });

  final Obd2SelfTestStepId id;
  final Obd2SelfTestStepStatus status;
  final int? latencyMs;

  /// #3555 — the layer's captured data as a raw, locale-neutral line the
  /// UI renders verbatim under the step (transcript category, i18n-exempt
  /// like every other protocol token): firmware id, battery voltage,
  /// negotiated protocol name, PID count, parsed live values, soak
  /// statistics, or the raw error token that failed the step.
  final String? detail;

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
  final adapterSteps = steps.where((s) => !kObd2LiveDataSteps.contains(s.id));
  // Engine-off requires: every adapter-capability step OK, every non-ok step
  // is a live-data step, and at least one live-data step shows the engine-off
  // signature while NONE shows a hard fault (timeout / fail / skipped).
  final adapterAllOk =
      adapterSteps.every((s) => s.status == Obd2SelfTestStepStatus.ok);
  final liveDataAllEngineOffOrOk = liveDataRan.every((s) =>
      s.status == Obd2SelfTestStepStatus.ok ||
      kObd2EngineOffStatuses.contains(s.status));
  final anyLiveDataEngineOff =
      liveDataRan.any((s) => kObd2EngineOffStatuses.contains(s.status));
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
