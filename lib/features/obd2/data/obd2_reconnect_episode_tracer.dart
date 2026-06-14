// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

/// Structured breadcrumb sink for the reconnect EPISODE (#3346). The
/// controller fires this at every lifecycle point — drop received, each
/// attempt's path + outcome + latency, backoff, terminal / connected — so the
/// orchestration the per-attempt connect-trace ring can't see lands in an
/// exported channel. [event] is a stable, low-cardinality tag; [data] is a
/// flat map of Hive-safe primitives.
typedef Obd2ReconnectTraceSink = void Function(
  String event,
  Map<String, Object?> data,
);

/// Owns the reconnect-episode breadcrumb emission + timing for
/// `Obd2ReconnectController` (#3346), kept separate so the controller stays a
/// lean state machine. Stamps `episodeMs` (whole-episode duration) and per-
/// attempt latencies off an injectable clock, and guards the sink so a buggy
/// collector can never wedge the reconnect loop (#1103).
class Obd2ReconnectEpisodeTracer {
  Obd2ReconnectEpisodeTracer({this.onTrace, DateTime Function()? now})
      : _now = now ?? DateTime.now;

  /// The breadcrumb sink. Mutable so the owner can wire / detach it after
  /// construction; null disables tracing entirely.
  Obd2ReconnectTraceSink? onTrace;

  final DateTime Function() _now;

  /// When the current episode began (a fresh drop / retry), used to stamp
  /// `episodeMs` on the terminal / connected breadcrumb.
  DateTime? _startedAt;

  /// A timestamp for the caller to bracket a connect-seam latency.
  DateTime now() => _now();

  void dropReceived({
    required String reason,
    String? transport,
    String? mac,
    required bool hadPin,
  }) {
    _startedAt = _now();
    _emit('drop-received', {
      'reason': reason,
      'transport': transport,
      'mac': mac,
      'hadPin': hadPin,
    });
  }

  void dropIgnored({required String reason, String? transport}) => _emit(
        'drop-ignored-already-reconnecting',
        {'reason': reason, 'transport': transport},
      );

  void retry(String from) {
    _startedAt = _now();
    _emit('retry', {'from': from});
  }

  void attemptStart({
    required int attempt,
    required int maxAttempts,
    required bool hasPin,
  }) =>
      _emit('attempt-start', {
        'attempt': attempt,
        'maxAttempts': maxAttempts,
        'hasPin': hasPin,
      });

  void pinnedSkipped(int attempt) =>
      _emit('pinned-skipped', {'attempt': attempt, 'reason': 'no-pin'});

  void pinnedResult({
    required int attempt,
    required String result,
    required DateTime start,
    String? transport,
  }) =>
      _emit('pinned-result', {
        'attempt': attempt,
        'result': result,
        'ms': _sinceMs(start),
        'transport': transport,
      });

  void rescanResult({
    required int attempt,
    required String result,
    required DateTime start,
  }) =>
      _emit('rescan-result', {
        'attempt': attempt,
        'result': result,
        'ms': _sinceMs(start),
      });

  void connected(int attempts) {
    _emit('connected', {'attempts': attempts, 'episodeMs': _episodeMs()});
    _startedAt = null;
  }

  /// Emit a terminal breadcrumb (`terminal-failed` / `terminal-engine-off`)
  /// stamping the attempts spent + whole-episode duration, then clear the
  /// episode clock.
  void terminal(String event, int attempts) {
    _emit(event, {'attempts': attempts, 'episodeMs': _episodeMs()});
    _startedAt = null;
  }

  void backoffScheduled({required int nextAttempt, required int delayMs}) =>
      _emit('backoff-scheduled',
          {'nextAttempt': nextAttempt, 'delayMs': delayMs});

  int? _episodeMs() {
    final start = _startedAt;
    return start == null ? null : _sinceMs(start);
  }

  int _sinceMs(DateTime from) => _now().difference(from).inMilliseconds;

  /// Fire the sink defensively — observability must NEVER derail the reconnect
  /// loop (#1103).
  void _emit(String event, Map<String, Object?> data) {
    final sink = onTrace;
    if (sink == null) return;
    try {
      sink(event, data);
    } catch (e, st) {
      debugPrint(
          'Obd2ReconnectEpisodeTracer: onTrace sink threw (ignored) — $e\n$st');
    }
  }

  /// Detach the sink for good.
  void dispose() => onTrace = null;
}
