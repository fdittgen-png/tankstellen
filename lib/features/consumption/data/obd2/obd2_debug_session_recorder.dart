import 'package:flutter/foundation.dart';

import 'auto_record_trace_log.dart';
import 'obd2_debug_session.dart';

/// Process-wide recorder for [Obd2DebugSession]s (#1925).
///
/// Off by default — every method is a cheap no-op until [enabled] is
/// flipped on (the user opts in via the OBD2 debug-logging checkbox in
/// settings; `Obd2DebugSessionLogging` keeps [enabled] in sync with the
/// persisted flag). When on, it captures one session per OBD2
/// connection so a failed recording can be exported as XML and analysed.
///
/// Most events are mirrored from [AutoRecordTraceLog]: [ingest] is
/// called from `AutoRecordTraceLog.add`, so the connect / drop /
/// reconnect transitions need no extra instrumentation. The connect
/// path adds per-command handshake timing via [recordHandshakeCommand];
/// the poll loop pings [recordData] so silence is detected as a gap.
///
/// Static, like [AutoRecordTraceLog] — the OBD2 stack is single-isolate
/// so no synchronisation is needed.
class Obd2DebugSessionRecorder {
  Obd2DebugSessionRecorder._();

  /// Master switch. False ⇒ every method returns immediately; the
  /// feature has zero cost when the user has not opted in.
  static bool enabled = false;

  /// A run of silence at least this long (ms) between successful data
  /// pings is recorded as an [Obd2SessionEventKind.dataGap]. The poll
  /// loop nominally delivers a sample every ~250 ms.
  static const int dataGapThresholdMs = 3000;

  static Obd2DebugSession? _current;
  static Obd2DebugSession? _last;
  static DateTime? _lastDataAt;

  // Vehicle state at the most recent [recordData] ping — stamped onto
  // the *pre-gap* side of the next [dataGap] event so a gap shows what
  // the car was doing when data stopped (#1930).
  static double? _lastSpeedKmh;
  static double? _lastRpm;

  /// The session currently being recorded, if any.
  static Obd2DebugSession? get currentSession => _current;

  /// The most relevant session for export — the live one if a
  /// connection is in progress, otherwise the last finished one.
  static Obd2DebugSession? get latestSession => _current ?? _last;

  /// Map a trace-ring event onto the session log. Called by
  /// `AutoRecordTraceLog.add`; a no-op when the feature is off.
  static void ingest(
    AutoRecordEventKind kind, {
    String? mac,
    String? detail,
    required DateTime timestamp,
  }) {
    if (!enabled) return;
    switch (kind) {
      case AutoRecordEventKind.connectStarted:
        _begin(mac, timestamp);
      case AutoRecordEventKind.connectSucceeded:
        _add(timestamp, Obd2SessionEventKind.connectionEstablished,
            detail: detail);
      case AutoRecordEventKind.connectFailed:
        _add(timestamp, Obd2SessionEventKind.connectionFailed,
            detail: detail);
        _finalize(timestamp);
      case AutoRecordEventKind.dropDetected:
        _add(timestamp, Obd2SessionEventKind.dropDetected, detail: detail);
      case AutoRecordEventKind.silentReconnectStarted:
        _add(timestamp, Obd2SessionEventKind.reconnectStarted,
            detail: detail);
      case AutoRecordEventKind.silentReconnectSucceeded:
      case AutoRecordEventKind.reconnectSucceeded:
        _add(timestamp, Obd2SessionEventKind.reconnectSucceeded,
            detail: detail);
      case AutoRecordEventKind.dropEscalatedToVisible:
        _add(timestamp, Obd2SessionEventKind.reconnectFailed,
            detail: detail ?? 'silent reconnect window elapsed');
      case AutoRecordEventKind.disconnectTimerStarted:
        _add(timestamp, Obd2SessionEventKind.disconnectTimerStarted,
            detail: detail);
      case AutoRecordEventKind.disconnectTimerCancelled:
        _add(timestamp, Obd2SessionEventKind.disconnectTimerCancelled,
            detail: detail);
      case AutoRecordEventKind.disconnectTimerFired:
        _add(timestamp, Obd2SessionEventKind.disconnectTimerFired,
            detail: detail);
      // Coordinator / threshold / trip-lifecycle events are not part
      // of the OBD2 link picture this log is meant to debug.
      default:
        break;
    }
  }

  /// Record one ELM327 init/handshake command and its reply. Called
  /// per command by `Obd2Service.connect`.
  static void recordHandshakeCommand(
    String command,
    String response,
    int latencyMs, {
    DateTime? clock,
  }) {
    if (!enabled || _current == null) return;
    final ts = clock ?? DateTime.now();
    _current!.events.add(Obd2SessionEvent(
      timestamp: ts,
      kind: Obd2SessionEventKind.handshakeCommand,
      command: command.trim(),
      response: response.trim(),
      latencyMs: latencyMs,
    ));
  }

  /// Ping that data was successfully received, with the vehicle state
  /// ([speedKmh] / [rpm]) at that moment. When the gap since the
  /// previous ping exceeds [dataGapThresholdMs] a [dataGap] event is
  /// recorded — stamped with the pre-gap state (carried from the last
  /// ping) and the post-gap state (this ping) so the export shows what
  /// the car was doing when data stopped and resumed (#1930).
  static void recordData(DateTime timestamp, {double? speedKmh, double? rpm}) {
    if (!enabled || _current == null) return;
    final last = _lastDataAt;
    if (last != null) {
      final gapMs = timestamp.difference(last).inMilliseconds;
      if (gapMs >= dataGapThresholdMs) {
        _current!.events.add(Obd2SessionEvent(
          timestamp: timestamp,
          kind: Obd2SessionEventKind.dataGap,
          gapMs: gapMs,
          preGapSpeedKmh: _lastSpeedKmh,
          preGapRpm: _lastRpm,
          postGapSpeedKmh: speedKmh,
          postGapRpm: rpm,
        ));
      }
    }
    _lastDataAt = timestamp;
    _lastSpeedKmh = speedKmh;
    _lastRpm = rpm;
  }

  /// Finalise the current session (e.g. when recording stops). Safe to
  /// call when there is no open session.
  static void endSession({DateTime? clock}) {
    if (!enabled) return;
    _finalize(clock ?? DateTime.now());
  }

  static void _begin(String? mac, DateTime ts) {
    _finalize(ts);
    _current = Obd2DebugSession(startedAt: ts, adapterMac: mac)
      ..events.add(Obd2SessionEvent(
        timestamp: ts,
        kind: Obd2SessionEventKind.sessionStarted,
        detail: mac == null ? null : 'adapter $mac',
      ));
    _lastDataAt = null;
    _lastSpeedKmh = null;
    _lastRpm = null;
  }

  static void _add(
    DateTime ts,
    Obd2SessionEventKind kind, {
    String? detail,
  }) {
    final cur = _current;
    if (cur == null) return;
    cur.events.add(Obd2SessionEvent(timestamp: ts, kind: kind, detail: detail));
  }

  static void _finalize(DateTime ts) {
    final cur = _current;
    if (cur == null) return;
    // Trailing data gap (#1930) — the session ended while data was
    // still silent, so no resuming ping ever emitted a dataGap. Record
    // it now (post-gap state null — data never came back) so a
    // recording that simply stopped receiving data is not invisible.
    final last = _lastDataAt;
    if (last != null) {
      final gapMs = ts.difference(last).inMilliseconds;
      if (gapMs >= dataGapThresholdMs) {
        cur.events.add(Obd2SessionEvent(
          timestamp: ts,
          kind: Obd2SessionEventKind.dataGap,
          gapMs: gapMs,
          preGapSpeedKmh: _lastSpeedKmh,
          preGapRpm: _lastRpm,
        ));
      }
    }
    cur.endedAt = ts;
    cur.events.add(Obd2SessionEvent(
      timestamp: ts,
      kind: Obd2SessionEventKind.sessionEnded,
    ));
    _last = cur;
    _current = null;
    _lastDataAt = null;
    _lastSpeedKmh = null;
    _lastRpm = null;
  }

  /// Test reset — drops the current and last session.
  @visibleForTesting
  static void reset() {
    _current = null;
    _last = null;
    _lastDataAt = null;
    _lastSpeedKmh = null;
    _lastRpm = null;
  }
}
