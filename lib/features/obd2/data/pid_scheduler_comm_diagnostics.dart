// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'obd2_comm_diagnostics.dart';
import 'obd2_response_class.dart';
import 'pid_bandwidth_governor.dart';
import 'scheduled_pid.dart';

/// Stateless tees that bridge the `PidScheduler`'s command-completion path
/// into the gated [Obd2CommDiagnostics] collector (#2468), kept out of the
/// scheduler so its selection core stays under the 400-line cap.
///
/// Every method is itself a no-op when the collector is disabled — but the
/// scheduler ALSO short-circuits on `Obd2CommDiagnostics.instance.enabled`
/// before building any argument, so in production (developer-mode off) not
/// even the tier-name / `e.toString()` is computed: the whole tee is a
/// branch-not-taken.
abstract final class PidSchedulerCommDiagnostics {
  /// Tee one scheduler tick: always counts the tick; sets [backpressureSkip]
  /// when the previous read was still in flight, so back-pressure becomes a
  /// rate against the tick total (#2468).
  static void noteTick({bool backpressureSkip = false}) {
    Obd2CommDiagnostics.instance.recordSchedulerHealth(
      tick: true,
      backpressureSkip: backpressureSkip,
    );
  }

  /// Tee a command dispatch, carrying its scheduler [config]'s target Hz +
  /// cadence tier so the per-PID table can report target-Hz attainment.
  static void noteDispatch(String command, ScheduledPid config) {
    Obd2CommDiagnostics.instance.noteDispatch(
      command,
      targetHz: config.hz,
      tier: config.tier.name,
    );
  }

  /// Tee a successful read: the [ResponseClass] of [response], its RTT, and
  /// the cleared failure streak (#2379 — a success resets the backoff).
  static void noteSuccess(
    String command,
    String response, {
    required DateTime dispatchedAt,
    required DateTime completedAt,
  }) {
    Obd2CommDiagnostics.instance.noteResult(
      command,
      classifyObd2Response(response),
      rttMs: _rttMs(dispatchedAt, completedAt),
      consecutiveFailures: 0,
      backedOff: false,
    );
  }

  /// Tee a failed read. A [TimeoutException] is the no-reply
  /// [ResponseClass.timeout]; any other throw is classified through the
  /// single-vocabulary [classifyObd2Response] on its message so a CAN /
  /// buffer-full / garbage error lands in the right 5-way bucket. Carries
  /// the current [consecutiveFailures] streak + [backedOff] state.
  static void noteFailure(
    String command,
    Object error, {
    required DateTime dispatchedAt,
    required DateTime completedAt,
    required int consecutiveFailures,
    required bool backedOff,
  }) {
    final cls = error is TimeoutException
        ? ResponseClass.timeout
        : classifyObd2Response(error.toString());
    Obd2CommDiagnostics.instance.noteResult(
      command,
      cls,
      rttMs: _rttMs(dispatchedAt, completedAt),
      consecutiveFailures: consecutiveFailures,
      backedOff: backedOff,
    );
  }

  /// Tee the post-read governor + scheduler health snapshot (#2468):
  /// achieved tick-rate (the configured loop frequency), the governor's
  /// achieved reads/s + dynamics floor + demotion count, the
  /// broadly-unresponsive [backedOffCount], and a starvation flag (a
  /// MEASURED dynamics rate below the governor's protective floor).
  static void noteHealth(
    GovernorState governor, {
    required Duration tickRate,
    required int backedOffCount,
  }) {
    final tickRateHz =
        tickRate.inMicroseconds > 0 ? 1e6 / tickRate.inMicroseconds : 0.0;
    final dynamicsHz = governor.dynamicsEffectiveHz;
    Obd2CommDiagnostics.instance.recordSchedulerHealth(
      tickRateHz: tickRateHz,
      achievedReadsPerSecond: governor.achievedReadsPerSecond,
      dynamicsEffectiveHz: dynamicsHz,
      demotions: governor.demotedCommands.length,
      backedOffCount: backedOffCount,
      starved: dynamicsHz.isFinite &&
          dynamicsHz < PidBandwidthGovernor.dynamicsFloorHz,
    );
  }

  /// Milliseconds between [dispatchedAt] and [completedAt], floored at 0 (a
  /// deterministic test clock can stamp both at the same instant).
  static int _rttMs(DateTime dispatchedAt, DateTime completedAt) {
    final ms = completedAt.difference(dispatchedAt).inMilliseconds;
    return ms < 0 ? 0 : ms;
  }
}
