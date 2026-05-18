import 'package:flutter/foundation.dart';

import 'auto_record_trace_log.dart';

/// Kinds of event captured in an [Obd2DebugSession] (#1925).
///
/// Most are mapped from [AutoRecordEventKind] as it is recorded — see
/// [Obd2DebugSessionRecorder.ingest]. [handshakeCommand] and [dataGap]
/// carry detail the lightweight trace ring does not, so they are fed
/// in directly by the connect path and the poll loop.
enum Obd2SessionEventKind {
  /// A new OBD2 connection attempt began — the session header.
  sessionStarted,

  /// One ELM327 init/handshake command (ATZ, ATE0, …) and its reply.
  handshakeCommand,

  /// The init handshake completed and the link is usable.
  connectionEstablished,

  /// The connection attempt failed before a usable link was reached.
  connectionFailed,

  /// A stretch with no successful data transmission was observed.
  dataGap,

  /// The recording's drop detector flagged a connection drop.
  dropDetected,

  /// A reconnect attempt started (the silent in-presence reconnect).
  reconnectStarted,

  /// The adapter came back and polling resumed.
  reconnectSucceeded,

  /// A reconnect attempt did not bring the adapter back in time.
  reconnectFailed,

  /// The session was finalised — the session footer.
  sessionEnded,
}

/// One timestamped entry in an [Obd2DebugSession]. Immutable so a
/// finished session can be serialised without risking mutation.
@immutable
class Obd2SessionEvent {
  /// Wall-clock instant the event was recorded.
  final DateTime timestamp;

  /// Which transition this entry captures.
  final Obd2SessionEventKind kind;

  /// Free-form context (firmware string, drop reason, error message).
  final String? detail;

  /// The command string — [Obd2SessionEventKind.handshakeCommand] only.
  final String? command;

  /// The adapter's reply — [Obd2SessionEventKind.handshakeCommand] only.
  final String? response;

  /// Round-trip latency in ms — [Obd2SessionEventKind.handshakeCommand]
  /// only.
  final int? latencyMs;

  /// Duration of the silence in ms — [Obd2SessionEventKind.dataGap]
  /// only.
  final int? gapMs;

  const Obd2SessionEvent({
    required this.timestamp,
    required this.kind,
    this.detail,
    this.command,
    this.response,
    this.latencyMs,
    this.gapMs,
  });
}

/// Derived, serialise-ready statistics for a finished (or in-progress)
/// [Obd2DebugSession]. Computed by [Obd2DebugSession.summary].
@immutable
class Obd2SessionSummary {
  final Duration? duration;
  final int handshakeCommands;
  final int handshakeLatencyMs;
  final int reconnectAttempts;
  final int reconnectsSucceeded;
  final int dataGaps;
  final int longestDataGapMs;

  /// `established`, `failed`, or `unknown` — the connection outcome.
  final String outcome;

  const Obd2SessionSummary({
    required this.duration,
    required this.handshakeCommands,
    required this.handshakeLatencyMs,
    required this.reconnectAttempts,
    required this.reconnectsSucceeded,
    required this.dataGaps,
    required this.longestDataGapMs,
    required this.outcome,
  });
}

/// One OBD2 connection's worth of debug events (#1925). Built up by
/// [Obd2DebugSessionRecorder] while the opt-in debug mode is on, then
/// serialised to XML by `formatObd2DebugSessionXml`.
class Obd2DebugSession {
  /// Adapter display name, when known.
  final String? adapterName;

  /// Adapter BLE MAC — stored raw; redacted at serialisation time.
  final String? adapterMac;

  /// When the connection attempt began.
  final DateTime startedAt;

  /// When the session was finalised — null while in progress.
  DateTime? endedAt;

  /// Ordered event log.
  final List<Obd2SessionEvent> events = <Obd2SessionEvent>[];

  Obd2DebugSession({
    required this.startedAt,
    this.adapterName,
    this.adapterMac,
  });

  /// Compute the [Obd2SessionSummary] from the events recorded so far.
  Obd2SessionSummary get summary {
    var handshakes = 0;
    var handshakeLatency = 0;
    var reconnectAttempts = 0;
    var reconnectsOk = 0;
    var gaps = 0;
    var longestGap = 0;
    var established = false;
    var failed = false;
    for (final e in events) {
      switch (e.kind) {
        case Obd2SessionEventKind.handshakeCommand:
          handshakes++;
          handshakeLatency += e.latencyMs ?? 0;
        case Obd2SessionEventKind.connectionEstablished:
          established = true;
        case Obd2SessionEventKind.connectionFailed:
          failed = true;
        case Obd2SessionEventKind.reconnectStarted:
          reconnectAttempts++;
        case Obd2SessionEventKind.reconnectSucceeded:
          reconnectsOk++;
        case Obd2SessionEventKind.dataGap:
          gaps++;
          final g = e.gapMs ?? 0;
          if (g > longestGap) longestGap = g;
        case Obd2SessionEventKind.sessionStarted:
        case Obd2SessionEventKind.dropDetected:
        case Obd2SessionEventKind.reconnectFailed:
        case Obd2SessionEventKind.sessionEnded:
          break;
      }
    }
    return Obd2SessionSummary(
      duration: endedAt?.difference(startedAt),
      handshakeCommands: handshakes,
      handshakeLatencyMs: handshakeLatency,
      reconnectAttempts: reconnectAttempts,
      reconnectsSucceeded: reconnectsOk,
      dataGaps: gaps,
      longestDataGapMs: longestGap,
      outcome: established
          ? 'established'
          : failed
              ? 'failed'
              : 'unknown',
    );
  }
}

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

  /// Ping that data was successfully received. When the gap since the
  /// previous ping exceeds [dataGapThresholdMs] a [dataGap] event is
  /// recorded so stretches of silence are visible in the export.
  static void recordData(DateTime timestamp) {
    if (!enabled || _current == null) return;
    final last = _lastDataAt;
    if (last != null) {
      final gapMs = timestamp.difference(last).inMilliseconds;
      if (gapMs >= dataGapThresholdMs) {
        _current!.events.add(Obd2SessionEvent(
          timestamp: timestamp,
          kind: Obd2SessionEventKind.dataGap,
          gapMs: gapMs,
        ));
      }
    }
    _lastDataAt = timestamp;
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
    cur.endedAt = ts;
    cur.events.add(Obd2SessionEvent(
      timestamp: ts,
      kind: Obd2SessionEventKind.sessionEnded,
    ));
    _last = cur;
    _current = null;
    _lastDataAt = null;
  }

  /// Test reset — drops the current and last session.
  @visibleForTesting
  static void reset() {
    _current = null;
    _last = null;
    _lastDataAt = null;
  }
}
