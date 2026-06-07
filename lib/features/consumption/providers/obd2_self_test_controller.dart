// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/obd2/obd2_connect_trace.dart';
import '../data/obd2/obd2_connection_service.dart';
import '../data/obd2/obd2_self_test_driver.dart';
import 'obd2_self_test_state.dart';
import 'trip_recording_provider.dart';

export 'obd2_self_test_state.dart';

part 'obd2_self_test_controller.g.dart';

/// Orchestrates the #2645 active adapter self-test and exposes live
/// per-step progress for the OBD2 health screen.
///
/// Runs the pure [runObd2SelfTest] driver step-by-step, pushing a new
/// `state` after every step transition so the UI animates live, then
/// surfaces the pass/fail summary on completion. The driver already
/// `endSession()`s the trace into [Obd2CommDiagnostics.instance], so the
/// screen's Recent-sessions + Copy-as-JSON pick the persisted session up
/// for free — this controller only carries the live banner state.
///
/// Two guards (the highest self-test risk — the single-link adapter):
///   * reentrancy — [run] refuses while a run is already in flight;
///   * active recording — [run] refuses while a trip recording owns the
///     `Obd2Service`, since a second connect on the half-duplex link would
///     collide with the recording. It surfaces [Obd2SelfTestPhase.blockedByRecording].
///
/// `keepAlive` so the result banner survives the health screen rebuilding
/// on every collector tick (an autoDispose notifier would reset the moment
/// the screen re-runs).
@Riverpod(keepAlive: true)
class Obd2SelfTestController extends _$Obd2SelfTestController {
  bool _cancelled = false;

  @override
  Obd2SelfTestState build() => Obd2SelfTestState.idle();

  /// Run the full self-test. No-op (state unchanged) when a run is already
  /// in flight. Refuses with [Obd2SelfTestPhase.blockedByRecording] when a
  /// trip recording is active.
  ///
  /// [targetMac], when non-empty (#2938), takes the reliable no-scan
  /// connect-by-MAC path — the same `connectByMacDirect` machinery the rest
  /// of the app uses for a paired adapter — instead of the blind scan that
  /// times out on real hardware. A null/empty MAC keeps the legacy blind
  /// scan (back-compat with the original Run button).
  ///
  /// [transportHint] (#2969) routes the pinned connect + reconnect over the
  /// inferred transport — Classic takes the RFCOMM path
  /// (`connectByMacClassicDirect`) instead of the BLE GATT direct path. The
  /// panel infers it from the selected adapter's stored name via the registry
  /// name matchers — for a Classic-SPP adapter (vLinker FS) the BLE path can
  /// ONLY 4 s-timeout, so this is the reliability fix. A null hint defaults to
  /// BLE but records `no-hint-defaulted-ble` on the trace.
  Future<void> run({String? targetMac, Obd2ConnectTransport? transportHint}) async {
    if (state.phase == Obd2SelfTestPhase.running) return;

    // Guard the single-link adapter: a self-test connect during a live
    // recording would collide with the recording's link.
    final recording = ref.read(tripRecordingProvider);
    if (recording.isActive || recording.isConnecting) {
      state = const Obd2SelfTestState(
        phase: Obd2SelfTestPhase.blockedByRecording,
      );
      return;
    }

    _cancelled = false;
    state = Obd2SelfTestState(
      phase: Obd2SelfTestPhase.running,
      steps: _pendingSteps(),
    );

    final connection = ref.read(obd2ConnectionProvider);
    final pinnedMac =
        (targetMac != null && targetMac.isNotEmpty) ? targetMac : null;
    final report = await runObd2SelfTest(
      connection,
      pinnedMac: pinnedMac,
      transportHint: transportHint,
      isCancelled: () => _cancelled,
      onStep: _onStep,
    );

    state = Obd2SelfTestState(
      phase: Obd2SelfTestPhase.done,
      steps: [
        for (final s in report.steps)
          Obd2SelfTestStep(id: s.id, status: s.status, latencyMs: s.latencyMs),
      ],
      verdict: report.verdict,
      elapsedMs: report.elapsedMs,
    );
  }

  /// Request cancellation between steps — the driver short-circuits to its
  /// `finally` (disconnect + endSession) at the next step boundary.
  void cancel() => _cancelled = true;

  /// Reset to idle (e.g. to clear the banner before a fresh run).
  void reset() => state = Obd2SelfTestState.idle();

  /// Fold one completed driver step into the live step list: mark it
  /// terminal, and mark the NEXT pending step as running so the spinner
  /// advances.
  void _onStep(Obd2SelfTestStepResult result) {
    final next = [
      for (final s in state.steps)
        if (s.id == result.id)
          s.copyWith(
            status: result.status,
            latencyMs: result.latencyMs,
            running: false,
          )
        else
          s,
    ];
    // Light up the first still-pending step as running.
    final advancedIndex =
        next.indexWhere((s) => s.status == Obd2SelfTestStepStatus.skipped);
    if (advancedIndex >= 0) {
      next[advancedIndex] = next[advancedIndex].copyWith(running: true);
    }
    state = state.copyWith(steps: next);
  }

  /// The seven steps in run order, all pending; the first marked running so
  /// the UI shows immediate progress before the first step resolves.
  List<Obd2SelfTestStep> _pendingSteps() {
    final steps = [
      for (final id in Obd2SelfTestStepId.values)
        Obd2SelfTestStep(id: id),
    ];
    if (steps.isNotEmpty) {
      steps[0] = steps[0].copyWith(running: true);
    }
    return steps;
  }
}
