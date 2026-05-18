import 'package:flutter/foundation.dart';

// The recorder lives in its own file (#1930 — keeps each under the
// 400-line guard) but is re-exported so importers of this file still
// see `Obd2DebugSessionRecorder` as one unit.
export 'obd2_debug_session_recorder.dart';

/// Kinds of event captured in an [Obd2DebugSession] (#1925).
///
/// Most are mapped from `AutoRecordEventKind` as it is recorded — see
/// `Obd2DebugSessionRecorder.ingest`. [handshakeCommand] and [dataGap]
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

  /// The disconnect-save debounce timer was scheduled — the auto-record
  /// flow is waiting to either reconnect or save the trip (#1930).
  disconnectTimerStarted,

  /// A reconnect within the debounce window cancelled the pending
  /// save — the trip carries on (#1930).
  disconnectTimerCancelled,

  /// The disconnect-save debounce timer fired — the trip is about to
  /// be saved because the adapter never came back (#1930).
  disconnectTimerFired,

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

  /// Vehicle speed (km/h) at the last reading **before** a gap —
  /// [Obd2SessionEventKind.dataGap] only. A non-zero value means the
  /// car was moving when data stopped (the link died mid-drive); zero
  /// with [preGapRpm] zero means the engine was idle/off (#1930).
  final double? preGapSpeedKmh;

  /// Engine RPM at the last reading **before** a gap — dataGap only.
  final double? preGapRpm;

  /// Vehicle speed (km/h) at the first reading **after** a gap —
  /// dataGap only; null when data never resumed (a trailing gap).
  final double? postGapSpeedKmh;

  /// Engine RPM at the first reading **after** a gap — dataGap only;
  /// null when data never resumed.
  final double? postGapRpm;

  const Obd2SessionEvent({
    required this.timestamp,
    required this.kind,
    this.detail,
    this.command,
    this.response,
    this.latencyMs,
    this.gapMs,
    this.preGapSpeedKmh,
    this.preGapRpm,
    this.postGapSpeedKmh,
    this.postGapRpm,
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
        case Obd2SessionEventKind.disconnectTimerStarted:
        case Obd2SessionEventKind.disconnectTimerCancelled:
        case Obd2SessionEventKind.disconnectTimerFired:
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
