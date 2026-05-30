// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../../core/logging/error_logger.dart';

/// Priority tier used as a tiebreaker when two subscribed PIDs have an
/// identical weight under the weighted round-robin selector.
///
/// The scheduler's primary selection metric is `(now − lastReadAt) × hz`,
/// so priority only matters when two PIDs are _exactly_ tied — e.g. both
/// subscribed on the same tick, or both have deterministic elapsed time.
enum PidPriority { high, medium, low }

/// Configuration for a single subscribed PID in the [PidScheduler].
///
/// The scheduler uses [hz] as the target refresh rate and computes each
/// tick's winner from `(now − lastReadAt) × hz`. A higher [hz] drags the
/// last-read timestamp toward "now" more aggressively, so fast-tier PIDs
/// naturally win more ticks than slow-tier PIDs.
///
/// [priority] is consulted only to break weight ties — it is _not_ a
/// hard override. A high-priority 0.1 Hz PID will still lose most ticks
/// to a medium-priority 5 Hz PID because its weight grows 50× slower.
class ScheduledPid {
  ScheduledPid({
    required this.hz,
    this.priority = PidPriority.medium,
  })  : assert(hz > 0, 'hz must be > 0'),
        lastReadAt = null;

  /// Target refresh rate in hertz (reads per second).
  final double hz;

  /// Tiebreaker when two PIDs have an identical weight this tick.
  final PidPriority priority;

  /// Timestamp of the most recent completed read, or `null` if the PID
  /// has been subscribed but never read yet. A `null` here makes the PID
  /// win the next tick unconditionally — a brand-new subscription should
  /// get one initial read before the round-robin math kicks in.
  DateTime? lastReadAt;
}

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
/// ## Phase 1 scope (#814)
///
/// This class is the selection engine only. The follow-up phase wires it
/// into `trip_recording_controller.dart`, adds default-tier PID tables,
/// and connects the per-command callbacks to `TripLiveReading` emissions.
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

  /// When the last aggregated "adapter unresponsive" diagnostic was
  /// emitted, used to rate-limit it to ≤1 per [_diagnosticWindow]. Null
  /// until the first one fires.
  DateTime? _lastDiagnosticAt;

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
      config: config,
      onResult: onResult,
      order: _subscriptionCounter++,
    );
  }

  /// Remove [command] from the rotation. A no-op if it isn't subscribed.
  void unsubscribe(String command) {
    _subs.remove(command);
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
    // A backed-off PID is selected at [_backoffHz] instead of its
    // configured rate — far less often, so it neither floods the adapter
    // nor starves healthy PIDs, while still being retried periodically so
    // it resumes the instant it answers (#2379).
    final hz = sub.isBackedOff ? _backoffHz : sub.config.hz;
    return (elapsedMs / 1000.0) * hz;
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
    if (_inFlight != null) return; // Backpressure: skip, do not queue.
    final now = _clock();
    final command = pickNextCommand(now);
    if (command == null) return;
    final sub = _subs[command];
    if (sub == null) return; // Subscription cancelled during selection.

    _inFlight = command;
    try {
      final response = await transport(command);
      sub.config.lastReadAt = _clock();
      // A successful read clears any accumulated failure streak so the
      // PID resumes its configured cadence immediately (#2379).
      sub.consecutiveFailures = 0;
      // Check subscription still exists — user may have unsubscribed
      // while the adapter round-trip was in flight.
      if (_subs.containsKey(command)) {
        try {
          sub.onResult(response);
        } catch (e, st) {
          // Callback errors are a real HANDLER bug — keep them logged so
          // they surface in triage. They live in OUR code, not the BLE
          // link, so the layer is `other` ("not yet classified"), not
          // `storage` (#2379).
          unawaited(errorLogger.log(ErrorLayer.other, e, st, context: {
            'where': 'PidScheduler: onResult for $command threw',
          }));
        }
      }
    } catch (e, st) {
      // Transport failures (timeout, NO DATA, adapter dropped) are
      // EXPECTED and recoverable — an engine-off car NO-DATAs many PIDs,
      // a slow clone times out intermittently. Logging one error trace
      // per PID per tick flooded a real user's error log (#2379), so we
      // do NOT error-log them here.
      //
      // We still stamp lastReadAt (anti-starvation: a forever-failing PID
      // must stop winning every tick or it would starve a healthy PID
      // tied on hz via the FIFO tiebreaker) and bump the failure streak.
      // Past [_maxConsecutiveFailures] the PID backs off to [_backoffHz]
      // (see [_weightFor]); a later success resets it.
      sub.config.lastReadAt = _clock();
      sub.consecutiveFailures++;
      _maybeEmitUnresponsiveDiagnostic(e, st);
    } finally {
      _inFlight = null;
    }
  }

  /// Emit AT MOST ONE aggregated "adapter unresponsive" diagnostic per
  /// [_diagnosticWindow] when [_backoffThreshold]+ PIDs are backed off.
  /// Replaces the old one-error-per-PID-per-tick flood with a single
  /// rate-limited breadcrumb that still makes a broadly-dead adapter
  /// visible in triage (#2379).
  void _maybeEmitUnresponsiveDiagnostic(Object error, StackTrace stack) {
    final downCount = backedOffCount;
    if (downCount < _backoffThreshold) return;
    final now = _clock();
    final last = _lastDiagnosticAt;
    if (last != null && now.difference(last) < _diagnosticWindow) return;
    _lastDiagnosticAt = now;
    unawaited(errorLogger.log(ErrorLayer.other, error, stack, context: {
      'where': 'PidScheduler: OBD2 adapter unresponsive — '
          '$downCount PIDs timing out',
      'backedOffPids': downCount,
    }));
  }
}

class _Subscription {
  _Subscription({
    required this.config,
    required this.onResult,
    required this.order,
  });

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
