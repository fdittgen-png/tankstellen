import 'dart:async';

import 'package:flutter/foundation.dart';

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
    return (elapsedMs / 1000.0) * sub.config.hz;
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
      // Check subscription still exists — user may have unsubscribed
      // while the adapter round-trip was in flight.
      if (_subs.containsKey(command)) {
        try {
          sub.onResult(response);
        } catch (e) {
          // Callback errors must not stall the scheduler. Log and move on.
          debugPrint('PidScheduler: onResult for $command threw: $e');
        }
      }
    } catch (e) {
      // Transport failures (timeout, NO DATA, adapter dropped) must not
      // deadlock the loop OR starve healthy PIDs. We stamp lastReadAt
      // anyway so the failing PID stops winning every tick — otherwise
      // two PIDs with identical hz and one failing forever would leave
      // the healthy one starved by the FIFO tiebreaker. On the next
      // round the failing PID still gets retried when its weight wins,
      // just no more often than the cadence it was subscribed at.
      debugPrint('PidScheduler: transport for $command threw: $e');
      sub.config.lastReadAt = _clock();
    } finally {
      _inFlight = null;
    }
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
}
