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
  int? _totalMs;

  /// Whether the timer has been started.
  bool get isRunning => _stopwatch.isRunning;

  /// All recorded milestones (in order).
  List<StartupMilestone> get milestones => List.unmodifiable(_milestones);

  /// Total startup time in milliseconds, available after [finish] is called.
  int? get totalMs => _totalMs;

  /// Start the timer. Call this as early as possible in main().
  void start() {
    _milestones.clear();
    _totalMs = null;
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

  /// Reset the timer for reuse (primarily for testing).
  @visibleForTesting
  void reset() {
    _stopwatch
      ..stop()
      ..reset();
    _milestones.clear();
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
