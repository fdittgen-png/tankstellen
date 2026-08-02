// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:io';
import 'dart:math' show min;

import 'package:flutter/foundation.dart';

import '../logging/error_logger.dart';
import 'collectors/breadcrumb_collector.dart';
import 'impl/proc_cpu_support.dart';
import '../../core/error/guarded.dart';

/// #3641 — lifecycle-gated CPU watchdog for the `[EXCESSIVE CPU USAGE]`
/// process kills.
///
/// Since 2026-07-27 the OS (Samsung / Android 16) repeatedly kills the
/// BACKGROUNDED app for burning 33–97% of a core over its 5-minute
/// observation window. The ApplicationExitInfo record (#3580) names the
/// process but never the thread, so the culprit stayed invisible across
/// two field exports. This watchdog catches the burn in the act:
///
///  * armed on `paused`, disarmed on `resumed` (foreground CPU is
///    legitimate — recording, maps);
///  * once per [tickInterval] it reads `/proc/self/stat` (utime+stime);
///  * a window above [alertThresholdPct] arms a per-thread snapshot of
///    `/proc/self/task/*/stat`; if the NEXT window is still hot, the top
///    threads by CPU delta are reported as an ERROR trace (background
///    layer — lands in the field export) plus a breadcrumb;
///  * reports are rate-limited to one per [minReportGap].
///
/// Cost while armed: one small proc read per minute; the thread sweep
/// (~40 tiny files) runs only after a hot window. No-op off Android.
/// Everything is injectable so tests never touch /proc. Failures are
/// swallowed to a debugPrint and stop the watchdog — forensics must
/// never hurt the app it observes.
class BackgroundCpuWatchdog {
  BackgroundCpuWatchdog({
    String? Function(String path)? readFile,
    List<String> Function()? listThreadStatPaths,
    DateTime Function()? now,
    this.tickInterval = const Duration(seconds: 60),
    this.alertThresholdPct = 25,
    this.minReportGap = const Duration(minutes: 10),
    bool? platformSupported,
    this.onReport,
  }) : _readFile = readFile ?? _readFileSync,
       _listThreadStatPaths = listThreadStatPaths ?? _realThreadStatPaths,
       _now = now ?? DateTime.now,
       _platformSupported = platformSupported ?? procCpuSupported();

  /// Process-wide instance wired by the app lifecycle observer.
  static final BackgroundCpuWatchdog instance = BackgroundCpuWatchdog();

  /// Sampling cadence while backgrounded. 60 s mirrors a fifth of the
  /// OS's own 300 s observation window.
  final Duration tickInterval;

  /// Report when a window's average CPU exceeds this % of one core —
  /// matches the `limit=25` the OS kill records carry.
  final int alertThresholdPct;

  /// Minimum gap between two reports from one process.
  final Duration minReportGap;

  /// Test seam — invoked with the report summary in addition to the
  /// production breadcrumb + error trace.
  final void Function(String summary)? onReport;

  final String? Function(String path) _readFile;
  final List<String> Function() _listThreadStatPaths;
  final DateTime Function() _now;
  final bool _platformSupported;

  Timer? _timer;
  int? _lastProcessJiffies;
  DateTime? _lastSampleAt;
  Map<String, _ThreadSample>? _armedThreadBaseline;
  DateTime? _lastReportAt;

  /// Whether the watchdog is currently sampling.
  bool get isRunning => _timer != null;

  /// Arm the watchdog (app went to background). Idempotent; no-op on
  /// unsupported platforms.
  void start() {
    if (!_platformSupported || _timer != null) return;
    _lastProcessJiffies = _sampleProcessJiffies();
    _lastSampleAt = _now();
    _armedThreadBaseline = null;
    _timer = Timer.periodic(tickInterval, (_) => tick());
  }

  /// Disarm (app resumed). Idempotent.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _lastProcessJiffies = null;
    _lastSampleAt = null;
    _armedThreadBaseline = null;
  }

  /// One sampling window. Public for tests; production calls arrive from
  /// the periodic timer.
  @visibleForTesting
  void tick() {
    try {
      final nowJiffies = _sampleProcessJiffies();
      final at = _now();
      final lastJiffies = _lastProcessJiffies;
      final lastAt = _lastSampleAt;
      _lastProcessJiffies = nowJiffies;
      _lastSampleAt = at;
      if (nowJiffies == null || lastJiffies == null || lastAt == null) {
        _armedThreadBaseline = null;
        return;
      }
      final wallMs = at.difference(lastAt).inMilliseconds;
      // Deep sleep / clock weirdness: a degenerate window proves nothing.
      if (wallMs < tickInterval.inMilliseconds ~/ 2) return;
      final cpuMs = (nowJiffies - lastJiffies) * _msPerJiffy;
      final pct = (cpuMs * 100 / wallMs).round();
      if (pct < alertThresholdPct) {
        _armedThreadBaseline = null;
        return;
      }
      final baseline = _armedThreadBaseline;
      if (baseline == null) {
        // First hot window: arm the per-thread baseline and wait one more
        // window so the report carries real deltas, not lifetime totals.
        _armedThreadBaseline = _sampleThreads();
        return;
      }
      _armedThreadBaseline = _sampleThreads();
      final lastReport = _lastReportAt;
      if (lastReport != null && at.difference(lastReport) < minReportGap) {
        return;
      }
      _lastReportAt = at;
      _report(pct: pct, wallMs: wallMs, baseline: baseline);
    } catch (e, st) {
      // Forensics must never hurt the app: disarm on any fault.
      debugPrint('BackgroundCpuWatchdog: tick failed — disarming: $e\n$st');
      stop();
    }
  }

  void _report({
    required int pct,
    required int wallMs,
    required Map<String, _ThreadSample> baseline,
  }) {
    final current = _armedThreadBaseline ?? const {};
    final deltas = <MapEntry<String, int>>[];
    current.forEach((tid, sample) {
      final before = baseline[tid];
      final deltaMs = (sample.jiffies - (before?.jiffies ?? 0)) * _msPerJiffy;
      if (deltaMs > 0) deltas.add(MapEntry('${sample.name}#$tid', deltaMs));
    });
    deltas.sort((a, b) => b.value.compareTo(a.value));
    final top = deltas.take(8).map((e) => '${e.key}:+${e.value}ms').join(', ');
    // i18n-ignore: telemetry export text, never rendered in the UI.
    final threadList = top.isEmpty ? 'no per-thread data' : top;
    final summary =
        'background CPU ~$pct% of a core over ${wallMs}ms '
        '(OS kill limit 25%) — top threads: $threadList';
    onReport?.call(summary);
    BreadcrumbCollector.add('bg-cpu-overload', detail: summary);
    logFailure(
      StateError('BackgroundCpuWatchdog: $summary'),
      StackTrace.current,
      where: 'BackgroundCpuWatchdog (#3641)',
      layer: ErrorLayer.background,
    );
  }

  int? _sampleProcessJiffies() =>
      parseProcStatCpuJiffies(_readFile('/proc/self/stat') ?? '');

  Map<String, _ThreadSample> _sampleThreads() {
    final samples = <String, _ThreadSample>{};
    for (final path in _listThreadStatPaths()) {
      final content = _readFile(path);
      if (content == null) continue;
      final jiffies = parseProcStatCpuJiffies(content);
      final name = parseProcStatComm(content);
      if (jiffies == null || name == null) continue;
      // /proc/self/task/<tid>/stat — the tid segment keys the map.
      final segments = path.split('/');
      final tid = segments.length >= 2 ? segments[segments.length - 2] : path;
      samples[tid] = _ThreadSample(name: name, jiffies: jiffies);
    }
    return samples;
  }

  static String? _readFileSync(String path) {
    try {
      return File(path).readAsStringSync();
    } catch (_) {
      // ignore: silent_catch — a vanished tid / unreadable proc entry is normal churn.
      return null;
    }
  }

  static List<String> _realThreadStatPaths() {
    try {
      return Directory(
        '/proc/self/task',
      ).listSync().map((e) => '${e.path}/stat').toList(growable: false);
    } catch (_) {
      // ignore: silent_catch — no task dir (unsupported kernel view) degrades to process-only.
      return const [];
    }
  }
}

/// Android USER_HZ is 100 on every shipping kernel, so one jiffy is
/// 10 ms. The reported figures are attribution ratios, not billing —
/// a non-100 USER_HZ would skew absolutes, never the ranking.
const int _msPerJiffy = 10;

class _ThreadSample {
  const _ThreadSample({required this.name, required this.jiffies});
  final String name;
  final int jiffies;
}

/// Parse utime+stime (in jiffies) out of a `/proc/<pid>/stat` line.
///
/// The comm field is parenthesised and may itself contain spaces and
/// parens (`(Signal Catcher)`), so fields are counted from the LAST `)`:
/// after it, token 0 is the state (field 3), utime is field 14 → token
/// 11, stime field 15 → token 12. Returns null on any malformed input.
int? parseProcStatCpuJiffies(String stat) {
  final close = stat.lastIndexOf(')');
  if (close < 0 || close + 1 >= stat.length) return null;
  final fields = stat.substring(close + 1).trim().split(RegExp(r'\s+'));
  if (fields.length < 13) return null;
  final utime = int.tryParse(fields[11]);
  final stime = int.tryParse(fields[12]);
  if (utime == null || stime == null) return null;
  return utime + stime;
}

/// Extract the comm (thread name) from a `/proc/<pid>/stat` line — the
/// text between the first `(` and the LAST `)`. Null when malformed.
String? parseProcStatComm(String stat) {
  final open = stat.indexOf('(');
  final close = stat.lastIndexOf(')');
  if (open < 0 || close <= open) return null;
  return stat.substring(open + 1, min(close, stat.length));
}
