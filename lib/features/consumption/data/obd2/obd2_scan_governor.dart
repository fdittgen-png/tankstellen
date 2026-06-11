// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;

import 'obd2_connect_trace.dart';
import 'obd2_connect_trace_log.dart';

/// #3185 / Epic #3178 — process-wide SCAN GOVERNOR for BLE scan starts.
///
/// Android silently throttles an app that starts more than 5 BLE scans in
/// 30 s: past the limit `startScan` "succeeds" but every scan returns
/// NOTHING until the window cools down — the field signature is a dense
/// connect episode (scan-seed + scan fallback + user retry) after which
/// the adapter "disappears" from every scan. iOS has no such hard limit,
/// but pacing costs nothing there.
///
/// This governor is a token bucket of [maxStartsPerWindow] scan starts per
/// rolling [window], sitting in front of every radio scan start (the
/// service's merged picker/connect scan AND the channel's targeted
/// scan-seed, which both count against the same OS budget). The 5th start
/// inside a window is DELAYED until the oldest token ages out — and the
/// throttle suspicion is stamped on the active connect trace
/// (`scan-throttle` step) so a field export explains the pause instead of
/// showing an unexplained gap.
///
/// Bucket size 4 (not 5) leaves one start of headroom: the OS counts scans
/// this process cannot see perfectly (a plugin-internal restart, a race
/// with a stop still in flight), so the governor must saturate BEFORE the
/// OS does.
///
/// One [process] instance backs production (the OS budget is per app, not
/// per service object); tests inject fresh instances with a fake clock +
/// wait so nothing sleeps for real.
///
/// [admitScanStart] never throws and fails OPEN (#1103): governor
/// bookkeeping must never abort a scan that would otherwise run — at worst
/// the OS throttle bites exactly as it did before #3185. The delay is also
/// bounded to a single wait round so a clock fault can never spin it.
class Obd2ScanGovernor {
  Obd2ScanGovernor({
    this.maxStartsPerWindow = 4,
    this.window = const Duration(seconds: 30),
    DateTime Function()? now,
    Future<void> Function(Duration)? wait,
  })  : _now = now ?? DateTime.now,
        _wait = wait ?? _realWait;

  static Future<void> _realWait(Duration d) => Future<void>.delayed(d);

  /// The single process-wide instance production wires everywhere the OS
  /// scan budget is spent (the service scans + the facade's scan-seed).
  static final Obd2ScanGovernor process = Obd2ScanGovernor();

  /// Token-bucket capacity per rolling [window]. 4 = the Android limit (5)
  /// minus one start of headroom.
  final int maxStartsPerWindow;

  /// Rolling window the OS throttle measures over (Android: 30 s).
  final Duration window;

  final DateTime Function() _now;
  final Future<void> Function(Duration) _wait;

  final List<DateTime> _starts = [];

  /// Total scan starts admitted (lifetime). Exposed so a wiring test can
  /// assert a code path actually consulted the governor.
  @visibleForTesting
  int get debugStartCount => _debugStartCount;
  int _debugStartCount = 0;

  /// Scan starts still inside the current rolling window.
  @visibleForTesting
  int get startsInWindow {
    _prune(_now());
    return _starts.length;
  }

  /// Admit one radio scan start, delaying when the bucket is exhausted.
  /// [reason] names the requesting path (`service-scan` / `scan-seed` /
  /// the caller's label) for the trace step + log line. Never throws and
  /// fails open — see the class doc.
  Future<void> admitScanStart({required String reason}) async {
    try {
      var now = _now();
      _prune(now);
      if (_starts.length >= maxStartsPerWindow) {
        final delay = window - now.difference(_starts.first);
        _stampThrottle(reason, delay);
        if (delay > Duration.zero) await _wait(delay);
        now = _now();
        _prune(now);
      }
      // Single wait round, then proceed regardless (fail-open): a second
      // saturation here means the clock/wait seams misbehaved, and spinning
      // on them would be worse than letting the OS throttle bite.
      _starts.add(now);
      _debugStartCount++;
    } catch (e, st) {
      // Fail OPEN: governor bookkeeping (the injected wait, the trace
      // stamp) must never abort the scan itself.
      debugPrint('Obd2ScanGovernor: admitScanStart failed open '
          '(scan proceeds): $e\n$st');
    }
  }

  void _prune(DateTime now) {
    _starts.removeWhere((t) => now.difference(t) >= window);
  }

  /// Make the throttle pause visible: a `scan-throttle` step on the active
  /// connect/scan trace (#3184 machinery) + a debug log line. Best-effort.
  void _stampThrottle(String reason, Duration delay) {
    final detail = 'scan budget exhausted ($maxStartsPerWindow starts/'
        '${window.inSeconds}s) — pacing "$reason" by ${delay.inMilliseconds}ms '
        'to dodge the Android 5-scans/30s throttle (silently-empty results); '
        '#3185';
    debugPrint('Obd2ScanGovernor: $detail');
    Obd2ConnectTraceLog.active?.addStep(
      label: 'scan-throttle',
      status: Obd2ConnectStepStatus.timeout,
      detail: detail,
    );
  }
}
