// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../../core/logging/error_logger.dart';
import 'obd2_comm_diagnostics.dart';
import 'pid_bandwidth_governor.dart';
import 'pid_scheduler_comm_diagnostics.dart';
import 'scheduled_pid.dart';
import 'unresponsive_adapter_diagnostic.dart';

// Re-export the per-PID config vocabulary (#2457) so existing call sites
// that import `pid_scheduler.dart` keep seeing PidPriority / PidTier /
// ScheduledPid without a second import.
export 'scheduled_pid.dart';

/// Weighted round-robin scheduler for OBD-II PID polling.
///
/// Each subscribed PID declares a target refresh rate in Hz. Every tick,
/// the scheduler picks the PID with the largest weight
/// (`(now − lastReadAt) × hz`) and fires it through [transport]. A PID
/// that has never been read (`lastReadAt == null`) wins immediately.
///
/// Only one command is in-flight at a time. If the transport round-trip
/// exceeds [tickRate] the next tick finds `_inFlight != null` and simply
/// waits — the scheduler never queues commands behind a slow adapter.
///
/// ## Transient-failure handling (#2379)
///
/// Per-PID transport failures (timeout, NO DATA, adapter dropped) are
/// **expected and recoverable** — engine-off cars NO-DATA half their
/// PIDs, and a slow clone times out intermittently. They are NOT error-
/// logged one-per-PID-per-tick (which flooded a real user's error log
/// with ~50 of 54 traces). Instead:
///
/// - Each subscription counts consecutive failures. After
///   [_maxConsecutiveFailures] in a row the PID is **backed off**: its
///   selection weight is recomputed at [_backoffHz] (≈ once per 30 s)
///   instead of its configured hz, so it neither floods the adapter nor
///   starves healthy PIDs. A single successful read resets the counter
///   and restores full cadence. The `lastReadAt` anti-starvation stamp
///   is kept on every attempt (success OR failure), so a backed-off PID
///   still climbs weight and is retried — just rarely.
/// - When the adapter looks broadly unresponsive ([_backoffThreshold]+
///   PIDs backed off) a SINGLE rate-limited aggregated diagnostic is
///   emitted, at most once per [_diagnosticWindow].
///
/// Recording is unaffected — a backed-off PID simply contributes fewer
/// samples; the loop never stalls.
///
/// ## Bandwidth governor (#2457)
///
/// PIDs declare a [PidTier]. On a slow ELM327 clone the total reads/second
/// the link sustains is the binding constraint, so the [PidBandwidthGovernor]
/// demotes the most-expendable PID (deepest tier first) when the dynamics
/// tier's effective hz drops below its floor, then restores it once headroom
/// returns. The dynamics tier is never demoted, so RPM / speed never starve.
/// Its demotions + achieved tick-rate are exposed read-only via
/// [governorState] for the comm-diagnostics overlay (#2468).
///
/// ## Comm-diagnostics tee (#2468)
///
/// When developer mode is on, every tick tees the per-PID 5-way outcome +
/// RTT and the scheduler/governor health into the gated collector via
/// [PidSchedulerCommDiagnostics] — guarded by the cached `enabled` bool so
/// production pays one branch-not-taken per tick (selection core unchanged).
class PidScheduler {
  PidScheduler({
    required this.transport,
    this.tickRate = const Duration(milliseconds: 100),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Consecutive per-PID transport failures before the PID is backed off
  /// to [_backoffHz]. Three covers a brief blip (one slow round-trip,
  /// one NO-DATA) without flapping, while reacting within a few seconds
  /// to a genuinely dead PID.
  static const int _maxConsecutiveFailures = 3;

  /// Effective refresh rate a backed-off PID is selected at — ≈ once per
  /// 30 s. Low enough that a dead PID never crowds out healthy ones, high
  /// enough that it resumes promptly the moment the engine starts / the
  /// adapter recovers.
  static const double _backoffHz = 1.0 / 30.0;

  /// How many PIDs must be simultaneously backed off before the adapter
  /// is considered "broadly unresponsive" and the aggregated diagnostic
  /// is worth emitting. One dead PID (e.g. an unsupported optional PID)
  /// is normal and silent; several at once signals a real problem.
  static const int _backoffThreshold = 3;

  /// Minimum gap between aggregated "adapter unresponsive" diagnostics.
  /// Caps the diagnostic at ≤1 per this window no matter how many PIDs
  /// time out per tick.
  static const Duration _diagnosticWindow = Duration(seconds: 30);

  /// Sends one OBD-II command and returns the raw adapter response.
  /// Typically `Obd2Transport.sendCommand`.
  final Future<String> Function(String command) transport;

  /// How often the scheduler wakes up to pick the next command. Defaults
  /// to 100 ms — well below the 200 ms target period of a 5 Hz PID, and
  /// coarse enough that tick overhead stays invisible next to the
  /// 100–500 ms Bluetooth round-trip.
  final Duration tickRate;

  /// Injectable clock for deterministic testing. Production always uses
  /// [DateTime.now].
  final DateTime Function() _clock;

  final Map<String, _Subscription> _subs = <String, _Subscription>{};
  Timer? _timer;
  bool _running = false;
  String? _inFlight;
  int _subscriptionCounter = 0;

  /// #2524 — owns the "adapter broadly unresponsive" log-once-per-episode
  /// decision (extracted so the selection core stays under the 400-line
  /// cap). Logs ≤1 ERROR per episode transition; per-tick it is a
  /// `debugPrint` breadcrumb, never an `errorLogger.log` flood (#2424/#2428).
  late final UnresponsiveAdapterDiagnostic _unresponsiveDiagnostic =
      UnresponsiveAdapterDiagnostic(
    backoffThreshold: _backoffThreshold,
    window: _diagnosticWindow,
    clock: _clock,
  );

  /// Bandwidth governor (#2457). Owns the achieved-reads windows + the
  /// demotion policy that protects the dynamics tier on a slow link. The
  /// scheduler feeds it read completions and queries its demotion set when
  /// computing selection weight; it takes no transport / timer of its own.
  late final PidBandwidthGovernor _governor =
      PidBandwidthGovernor(clock: _clock);

  /// Read-only snapshot of the bandwidth governor (#2457) for the
  /// comm-diagnostics overlay (#2468): the achieved tick rate, the
  /// dynamics tier's effective hz, and the currently-demoted commands.
  GovernorState get governorState => _governor.state;

  /// Commands currently demoted by the governor. Exposed for tests.
  @visibleForTesting
  Set<String> get demotedCommands => _governor.state.demotedCommands;

  /// Number of subscribed PIDs currently in the backed-off state
  /// (consecutive failures ≥ [_maxConsecutiveFailures]). Exposed for
  /// tests that assert backoff engaged / cleared.
  @visibleForTesting
  int get backedOffCount =>
      _subs.values.where((s) => s.isBackedOff).length;

  /// Whether [start] has been called and [stop] has not yet run.
  bool get isRunning => _running;

  /// The command currently in-flight, or `null` if the scheduler is idle
  /// (no command has been dispatched or the last response has landed).
  /// Exposed for tests that assert backpressure behaviour.
  @visibleForTesting
  String? get inFlightCommand => _inFlight;

  /// Subscribe [command] (e.g. `'010C'` for RPM) at the cadence defined
  /// by [config]. [onResult] fires every time a response for this command
  /// lands. Re-subscribing the same command replaces the previous config
  /// and callback (and resets `lastReadAt`).
  void subscribe(
    String command,
    ScheduledPid config,
    void Function(String response) onResult,
  ) {
    _subs[command] = _Subscription(
      command: command,
      config: config,
      onResult: onResult,
      order: _subscriptionCounter++,
    );
    _governor.register(
      command,
      tier: config.tier,
      priority: config.priority,
      hz: config.hz,
    );
  }

  /// Remove [command] from the rotation. A no-op if it isn't subscribed.
  /// Also drops any governor demotion / read-window held against it so a
  /// re-subscribe starts clean.
  void unsubscribe(String command) {
    _subs.remove(command);
    _governor.unregister(command);
  }

  /// Start the periodic selection timer. Safe to call multiple times —
  /// subsequent calls are no-ops while [isRunning] is true.
  void start() {
    if (_running) return;
    _running = true;
    _timer = Timer.periodic(tickRate, (_) => _tick());
  }

  /// Stop the timer. Any in-flight command is allowed to complete but
  /// its result is still delivered via the subscribed callback. Safe to
  /// call when not running.
  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  /// Pure selection: given the current subscription state and [now],
  /// return the command that should fire next — or `null` if nothing is
  /// subscribed. Exposed for tests that need to verify the weighted
  /// round-robin math without running the timer.
  ///
  /// Selection rules (in order):
  /// 1. PIDs with `lastReadAt == null` always win over ever-read PIDs.
  /// 2. Otherwise the highest weight `(now − lastReadAt) × hz` wins.
  /// 3. On weight tie, higher [PidPriority] wins.
  /// 4. On priority tie, earlier-subscribed command wins (FIFO).
  @visibleForTesting
  String? pickNextCommand(DateTime now) {
    if (_subs.isEmpty) return null;

    String? bestCommand;
    _Subscription? best;
    var bestWeight = double.negativeInfinity;

    for (final entry in _subs.entries) {
      final sub = entry.value;
      final weight = _weightFor(sub, now);
      if (_beats(weight, sub, bestWeight, best)) {
        bestWeight = weight;
        best = sub;
        bestCommand = entry.key;
      }
    }
    return bestCommand;
  }

  double _weightFor(_Subscription sub, DateTime now) {
    final last = sub.config.lastReadAt;
    if (last == null) return double.infinity;
    final elapsedMs = now.difference(last).inMicroseconds / 1000.0;
    if (elapsedMs <= 0) return 0.0;
    return (elapsedMs / 1000.0) * _effectiveHz(sub);
  }

  /// The selection hz actually applied to [sub] this tick, after the two
  /// dampers stack:
  ///   - #2379 backoff: a PID that has failed [_maxConsecutiveFailures]
  ///     times runs at [_backoffHz] (≈ 1/30 s) so a dead PID never crowds
  ///     out healthy ones, yet is still retried periodically.
  ///   - #2457 governor demotion: an expendable PID the governor has
  ///     demoted runs at its configured hz × the governor's demotion
  ///     factor, handing the freed budget to the dynamics tier on a slow
  ///     link.
  /// Backoff dominates (a dead PID stays at [_backoffHz] regardless).
  double _effectiveHz(_Subscription sub) {
    if (sub.isBackedOff) return _backoffHz;
    final base = sub.config.hz;
    return _governor.isDemoted(sub.command)
        ? base * PidBandwidthGovernor.demotionFactor
        : base;
  }

  /// Returns true if [candidateWeight]/[candidate] should replace
  /// [currentBestWeight]/[currentBest] as the winner so far.
  bool _beats(
    double candidateWeight,
    _Subscription candidate,
    double currentBestWeight,
    _Subscription? currentBest,
  ) {
    if (currentBest == null) return true;
    if (candidateWeight > currentBestWeight) return true;
    if (candidateWeight < currentBestWeight) return false;
    // Weight tie → priority tiebreaker. Lower enum index = higher
    // priority (high=0, medium=1, low=2), so the smaller index wins.
    final candPri = candidate.config.priority.index;
    final bestPri = currentBest.config.priority.index;
    if (candPri < bestPri) return true;
    if (candPri > bestPri) return false;
    // Priority tie → FIFO by subscription order.
    return candidate.order < currentBest.order;
  }

  Future<void> _tick() async {
    if (!_running) return;
    // Tee EVERY tick (fired or skipped) so back-pressure becomes a rate
    // (#2468). Gated: a pure branch-not-taken in prod (debug-mode off).
    final diag = Obd2CommDiagnostics.instance;
    if (_inFlight != null) {
      // Backpressure: skip, do not queue.
      if (diag.enabled) PidSchedulerCommDiagnostics.noteTick(backpressureSkip: true);
      return;
    }
    if (diag.enabled) PidSchedulerCommDiagnostics.noteTick();
    final now = _clock();
    final command = pickNextCommand(now);
    if (command == null) return;
    final sub = _subs[command];
    if (sub == null) return; // Subscription cancelled during selection.

    _inFlight = command; // `now` is the dispatch instant for the RTT below.
    if (diag.enabled) PidSchedulerCommDiagnostics.noteDispatch(command, sub.config);
    try {
      final response = await transport(command);
      final completedAt = _clock();
      sub.config.lastReadAt = completedAt;
      _governor.recordRead(command, completedAt);
      // A successful read clears any accumulated failure streak so the
      // PID resumes its configured cadence immediately (#2379).
      sub.consecutiveFailures = 0;
      if (diag.enabled) {
        PidSchedulerCommDiagnostics.noteSuccess(command, response,
            dispatchedAt: now, completedAt: completedAt);
      }
      // Check subscription still exists — user may have unsubscribed
      // while the adapter round-trip was in flight.
      if (_subs.containsKey(command)) {
        try {
          sub.onResult(response);
        } catch (e, st) {
          // Callback errors are a real HANDLER bug in OUR code (not the BLE
          // link) — keep them logged for triage, as layer `other` (#2379).
          unawaited(errorLogger.log(ErrorLayer.other, e, st, context: {
            'where': 'PidScheduler: onResult for $command threw',
          }));
        }
      }
    } catch (e, st) {
      // Transport failures (timeout, NO DATA, adapter dropped) are EXPECTED
      // and recoverable — an engine-off car NO-DATAs many PIDs, a slow clone
      // times out. NOT error-logged per-PID-per-tick (it flooded a real
      // user's log, #2379). We still stamp lastReadAt (anti-starvation) and
      // bump the failure streak; past [_maxConsecutiveFailures] the PID backs
      // off to [_backoffHz] (see [_weightFor]); a later success resets it.
      final completedAt = _clock();
      sub.config.lastReadAt = completedAt;
      _governor.recordRead(command, completedAt);
      sub.consecutiveFailures++;
      if (diag.enabled) {
        PidSchedulerCommDiagnostics.noteFailure(command, e,
            dispatchedAt: now,
            completedAt: completedAt,
            consecutiveFailures: sub.consecutiveFailures,
            backedOff: sub.isBackedOff);
      }
      _maybeEmitUnresponsiveDiagnostic(e, st);
    } finally {
      _inFlight = null;
      // Re-evaluate the bandwidth budget after every completed read (the
      // achieved-hz window only changes when a read lands), AFTER
      // `_inFlight` clears so a demotion takes effect on the next tick.
      _governor.evaluate();
      // Tee the post-read governor/scheduler health snapshot (#2468).
      if (diag.enabled) {
        PidSchedulerCommDiagnostics.noteHealth(_governor.state,
            tickRate: tickRate, backedOffCount: backedOffCount);
      }
    }
  }

  /// Surface a broadly-unresponsive adapter WITHOUT flooding the error log
  /// (#2379 / #2524). Delegates the log-once-per-episode decision to
  /// [UnresponsiveAdapterDiagnostic]; see that class for the contract.
  void _maybeEmitUnresponsiveDiagnostic(Object error, StackTrace stack) {
    _unresponsiveDiagnostic.onFailure(backedOffCount, error, stack);
  }
}

class _Subscription {
  _Subscription({
    required this.command,
    required this.config,
    required this.onResult,
    required this.order,
  });

  /// The OBD-II command this subscription polls (e.g. `'010C'`). Kept so
  /// the governor can address demotions by command without a reverse map.
  final String command;

  final ScheduledPid config;
  final void Function(String response) onResult;

  /// Monotonic subscription index used for FIFO tie-breaking.
  final int order;

  /// Consecutive transport failures since the last successful read. Reset
  /// to 0 on any success. Drives the [isBackedOff] state (#2379).
  int consecutiveFailures = 0;

  /// True once this PID has failed [PidScheduler._maxConsecutiveFailures]
  /// times in a row — it is then selected at the slow backoff rate until
  /// it next answers.
  bool get isBackedOff =>
      consecutiveFailures >= PidScheduler._maxConsecutiveFailures;
}
