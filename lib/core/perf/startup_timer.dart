// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

/// Lightweight stopwatch that records named milestones during app startup.
///
/// Usage:
/// ```dart
/// StartupTimer.instance.start();
/// // ... init step ...
/// StartupTimer.instance.mark('hive_init');
/// // ... more steps ...
/// StartupTimer.instance.finish();
/// ```
///
/// In debug mode, [finish] prints a summary table to the console.
/// The recorded [milestones] and [totalMs] are available programmatically
/// for CI budget checks or analytics.
class StartupTimer {
  StartupTimer._();

  /// Singleton instance used throughout the app startup sequence.
  static final StartupTimer instance = StartupTimer._();

  final Stopwatch _stopwatch = Stopwatch();
  final List<StartupMilestone> _milestones = [];
  final List<StartupSpan> _spans = [];
  DateTime? _wallClockEpoch;
  int? _totalMs;

  /// Whether the timer has been started.
  bool get isRunning => _stopwatch.isRunning;

  /// All recorded milestones (in order).
  List<StartupMilestone> get milestones => List.unmodifiable(_milestones);

  /// All recorded spans (in insertion order) — see [addSpan].
  List<StartupSpan> get spans => List.unmodifiable(_spans);

  /// Total startup time in milliseconds, available after [finish] is called.
  int? get totalMs => _totalMs;

  /// Start the timer. Call this as early as possible in main().
  void start() {
    _milestones.clear();
    _spans.clear();
    _totalMs = null;
    _wallClockEpoch = DateTime.now();
    _stopwatch.reset();
    _stopwatch.start();
  }

  /// Record a named milestone at the current elapsed time.
  void mark(String name) {
    if (!_stopwatch.isRunning) return;
    _milestones.add(StartupMilestone(
      name: name,
      elapsedMs: _stopwatch.elapsedMilliseconds,
    ));
  }

  /// Stop the timer and log results in debug mode.
  void finish() {
    if (!_stopwatch.isRunning) return;
    _stopwatch.stop();
    _totalMs = _stopwatch.elapsedMilliseconds;

    if (kDebugMode) {
      _printSummary();
    }
  }

  /// Milliseconds elapsed since [start] on the trace clock, usable both
  /// BEFORE and AFTER [finish] (#3445).
  ///
  /// While the stopwatch runs this is its reading; once [finish] stopped
  /// it, the wall-clock epoch captured by [start] takes over — the
  /// post-first-frame launch-sync phase runs after `finish()` and its
  /// spans must still land on the same timeline. `0` before [start].
  int elapsedMsNow() {
    if (_stopwatch.isRunning) return _stopwatch.elapsedMilliseconds;
    final epoch = _wallClockEpoch;
    if (epoch == null) return 0;
    final ms = DateTime.now().difference(epoch).inMilliseconds;
    return ms < 0 ? 0 : ms;
  }

  /// Record a named span on the startup timeline (#3445). Unlike [mark],
  /// this works after [finish] — the deferred launch-sync phase records
  /// its spans here. No-op before [start] (nothing to anchor to).
  /// [attributes] travel into the trace export verbatim (row counts …).
  void addSpan(
    String name, {
    required int startMs,
    required int endMs,
    Map<String, Object?> attributes = const {},
  }) {
    if (_wallClockEpoch == null) return;
    _spans.add(StartupSpan(
      name: name,
      startMs: startMs,
      endMs: endMs,
      attributes: Map.unmodifiable(attributes),
    ));
  }

  /// Reset the timer for reuse (primarily for testing).
  @visibleForTesting
  void reset() {
    _stopwatch
      ..stop()
      ..reset();
    _milestones.clear();
    _spans.clear();
    _wallClockEpoch = null;
    _totalMs = null;
  }

  void _printSummary() {
    final buffer = StringBuffer()
      ..writeln('=== Startup Time ===');

    int previousMs = 0;
    for (final m in _milestones) {
      final deltaMs = m.elapsedMs - previousMs;
      buffer.writeln('  ${m.name}: ${m.elapsedMs}ms (+${deltaMs}ms)');
      previousMs = m.elapsedMs;
    }

    buffer.writeln('  TOTAL: ${_totalMs}ms');
    debugPrint(buffer.toString());
  }
}

/// A single named checkpoint recorded during startup.
class StartupMilestone {
  const StartupMilestone({
    required this.name,
    required this.elapsedMs,
  });

  /// Human-readable label for this milestone (e.g. "hive_init").
  final String name;

  /// Milliseconds elapsed since [StartupTimer.start] was called.
  final int elapsedMs;

  @override
  String toString() => 'StartupMilestone($name, ${elapsedMs}ms)';
}

/// A named interval on the startup timeline (#3445) — unlike a
/// [StartupMilestone] checkpoint it has an explicit start AND end, plus
/// free-form [attributes] (per-table sync row counts). Recorded via
/// [StartupTimer.addSpan], including after `finish()` ran.
class StartupSpan {
  const StartupSpan({
    required this.name,
    required this.startMs,
    required this.endMs,
    this.attributes = const {},
  });

  /// Span label (e.g. `tanksync_init`, `trips_merge`, a table name).
  final String name;

  /// Milliseconds since [StartupTimer.start] when the span began.
  final int startMs;

  /// Milliseconds since [StartupTimer.start] when the span ended.
  final int endMs;

  /// Extra key/values exported verbatim (row counts pulled/pushed …).
  final Map<String, Object?> attributes;

  /// The span's length on the timeline.
  int get durationMs => endMs - startMs;

  @override
  String toString() => 'StartupSpan($name, $startMs..${endMs}ms)';
}
