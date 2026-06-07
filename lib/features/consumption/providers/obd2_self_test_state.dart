// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/obd2/obd2_self_test_driver.dart';

part 'obd2_self_test_state.freezed.dart';

/// Lifecycle phase of the #2645 adapter self-test run.
enum Obd2SelfTestPhase {
  /// No test has run yet (or the surface was reset). The Run button is
  /// enabled; no step list is shown.
  idle,

  /// A run refused to start because a trip recording owns the single-link
  /// adapter. The UI shows the cannot-run-while-recording notice.
  blockedByRecording,

  /// A run is in progress. The Run button is disabled; the step list
  /// animates as each step transitions to its terminal status.
  running,

  /// A run completed. The pass/fail banner + final step list + persisted
  /// session (under Recent sessions) are shown.
  done,
}

/// One row of the live step list: a stable step id (localised by the UI),
/// its current status, and the (timed) latency once it has run.
@freezed
abstract class Obd2SelfTestStep with _$Obd2SelfTestStep {
  const factory Obd2SelfTestStep({
    required Obd2SelfTestStepId id,
    @Default(Obd2SelfTestStepStatus.skipped) Obd2SelfTestStepStatus status,
    int? latencyMs,

    /// True while this step is the one currently executing — drives the
    /// inline progress spinner. Exactly one step is `running` at a time.
    @Default(false) bool running,
  }) = _Obd2SelfTestStep;
}

/// Immutable live state of the self-test controller. Freezed for value
/// equality so the health screen rebuilds only on a real change.
@freezed
abstract class Obd2SelfTestState with _$Obd2SelfTestState {
  const factory Obd2SelfTestState({
    @Default(Obd2SelfTestPhase.idle) Obd2SelfTestPhase phase,
    @Default(<Obd2SelfTestStep>[]) List<Obd2SelfTestStep> steps,

    /// The tri-state verdict of the completed run (#3009): passed /
    /// engineOff (adapter OK, engine off) / failed. `failed` until a run
    /// finishes. Drives the summary banner's colour + headline so the
    /// engine-off case shows a non-alarming amber notice, not a red failure.
    @Default(Obd2SelfTestVerdict.failed) Obd2SelfTestVerdict verdict,
    int? elapsedMs,
  }) = _Obd2SelfTestState;

  const Obd2SelfTestState._();

  /// The idle starting state.
  factory Obd2SelfTestState.idle() => const Obd2SelfTestState();

  /// Back-compat: `true` only on a full pass (every step ok). An engine-off
  /// verdict is NOT a pass; consumers that distinguish it read [verdict].
  bool get passed => verdict == Obd2SelfTestVerdict.passed;

  /// Number of steps that ended ok — the numerator of the summary line.
  int get passCount =>
      steps.where((s) => s.status == Obd2SelfTestStepStatus.ok).length;

  /// Number of steps that did not pass — the failure count of the summary.
  int get failCount =>
      steps.where((s) => s.status != Obd2SelfTestStepStatus.ok).length;
}
