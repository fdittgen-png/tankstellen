// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'obd2_response_class.dart';
import 'obd2_session_diagnostic.dart';

/// Central, **gated** collector for OBD2 communication-health
/// diagnostics (#2464, foundation of Epic #2463).
///
/// Mirrors the `Obd2DebugSessionRecorder` opt-in pattern: off by default,
/// and **every** record method's first statement is `if (!enabled)
/// return;` — BEFORE any payload or string is built. So in production
/// (developer-mode off) the whole subsystem costs a single cached-bool
/// read and a branch-not-taken per instrumented event; nothing is
/// allocated, no map is touched, no snapshot mutates.
///
/// The collector is fed by the comm-path layers in later children
/// (#2465-#2469); this foundation introduces only the storage + the
/// gated record API + the immutable `snapshot()`. It owns:
///   * the live session being built;
///   * a capped ring of the last [maxSessions] finished sessions.
///
/// **Bounded by construction:** the per-PID map is keyed by the fixed set
/// of polled commands, the init transcript is one-shot capped at
/// [Obd2SessionDiagnostic.maxTranscriptLines], and every latency /
/// time-to-connect series is a capped-sample reservoir
/// ([_LatencyReservoir]) — never an unbounded list. The session ring is
/// capped at [maxSessions].
///
/// Single-isolate like the rest of the OBD2 stack, so no synchronisation.
class Obd2CommDiagnostics {
  Obd2CommDiagnostics({this.enabled = false});

  /// Process-wide collector the comm-path layers tee into (#2465).
  ///
  /// Mirrors the static singleton shape of [Obd2DebugSessionRecorder] /
  /// `AutoRecordTraceLog`: the OBD2 data layer is plumbing-free of
  /// Riverpod, so the connect/init path teaches itself the live collector
  /// through this single shared handle rather than threading an instance
  /// through every constructor. The `Obd2CommDiagnosticsGate` provider
  /// flips [instance.enabled] from `Feature.debugMode`; production
  /// (debug-mode off) leaves it `false`, so every tee is a no-op.
  static final Obd2CommDiagnostics instance = Obd2CommDiagnostics();

  /// Hard cap on the retained finished-session ring (#2463 design:
  /// "capped 5-session ring").
  static const int maxSessions = 5;

  /// Master switch. False ⇒ every record method returns immediately and
  /// the collector allocates / mutates nothing. Intended to be wired
  /// from `Feature.debugMode` by a later child (the provider sets this
  /// field once at start-up like `Obd2DebugSessionRecorder.enabled`); for
  /// now it is a plain mutable flag set via the constructor or directly.
  bool enabled;

  _LiveSession? _current;
  final List<Obd2SessionDiagnostic> _finished = <Obd2SessionDiagnostic>[];

  /// Read-only view of the last [maxSessions] finished sessions,
  /// oldest-first. Empty when nothing has been recorded.
  List<Obd2SessionDiagnostic> get finishedSessions =>
      List.unmodifiable(_finished);

  // -------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------

  /// Begin a new live session. Finalises any in-progress session first.
  /// No-op when disabled.
  void beginSession({String? linkKind, String? redactedMac}) {
    if (!enabled) return;
    if (_current != null) endSession();
    _current = _LiveSession(linkKind: linkKind, redactedMac: redactedMac);
  }

  /// Stamp the adapter identity discovered during the handshake. No-op
  /// when disabled or before [beginSession].
  ///
  /// [capabilityTier] is the firmware-derived runtime tier name (e.g.
  /// `'standardOnly'` / `'oemPidsCapable'` / `'passiveCanCapable'`).
  /// Wave 2 will add the reconciled value once the lazy multi-frame probe
  /// is instrumented; Wave 1 records the claimed tier (#2465).
  void recordAdapterIdentity({
    String? elmVersion,
    String? protocolDigit,
    int? mtu,
    bool? warmStart,
    String? capabilityTier,
  }) {
    if (!enabled) return;
    final cur = _current;
    if (cur == null) return;
    cur.elmVersion = elmVersion ?? cur.elmVersion;
    cur.protocolDigit = protocolDigit ?? cur.protocolDigit;
    cur.mtu = mtu ?? cur.mtu;
    cur.warmStart = warmStart ?? cur.warmStart;
    cur.capabilityTier = capabilityTier ?? cur.capabilityTier;
  }

  /// Append one redacted ELM init/handshake line. One-shot capped at
  /// [Obd2SessionDiagnostic.maxTranscriptLines] — once full, further
  /// lines are dropped (the early handshake is the diagnostic value).
  /// No-op when disabled.
  void recordHandshakeLine(String cmd, String rawResponse, int latencyMs) {
    if (!enabled) return;
    final cur = _current;
    if (cur == null) return;
    if (cur.transcript.length >= Obd2SessionDiagnostic.maxTranscriptLines) {
      return;
    }
    cur.transcript.add(
      Obd2HandshakeLine(
        cmd: cmd.trim(),
        response: rawResponse.trim(),
        latencyMs: latencyMs,
      ),
    );
  }

  /// Note that a poll command [pid] was dispatched. No-op when disabled.
  void noteDispatch(String pid) {
    if (!enabled) return;
    final cur = _current;
    if (cur == null) return;
    cur.pidRow(pid).polled++;
  }

  /// Note the outcome [cls] of a poll for [pid], with optional
  /// round-trip time [rttMs] folded into the latency reservoir. No-op
  /// when disabled.
  void noteResult(String pid, ResponseClass cls, {int? rttMs}) {
    if (!enabled) return;
    final cur = _current;
    if (cur == null) return;
    final row = cur.pidRow(pid);
    switch (cls) {
      case ResponseClass.ok:
        row.ok++;
      case ResponseClass.noData:
        row.noData++;
      case ResponseClass.timeout:
        row.timeout++;
      case ResponseClass.bufferFull:
      case ResponseClass.canError:
      case ResponseClass.unrecognized:
      case ResponseClass.garbage:
        row.error++;
    }
    if (rttMs != null) row.latency.add(rttMs);
  }

  /// Record a connection-lifecycle event. Exactly one of the optional
  /// flags is set per call by the caller. [failureReason] tags a failed
  /// attempt; [timeToConnectMs] / [timeToReconnectMs] feed the
  /// respective reservoir. No-op when disabled.
  void noteConnectionEvent({
    bool attempt = false,
    bool success = false,
    String? failureReason,
    bool drop = false,
    bool silentReconnect = false,
    bool visibleReconnect = false,
    int? timeToConnectMs,
    int? timeToReconnectMs,
  }) {
    if (!enabled) return;
    final cur = _current;
    if (cur == null) return;
    if (attempt) cur.connAttempts++;
    if (success) cur.connSuccesses++;
    if (failureReason != null) {
      cur.connFailuresByReason[failureReason] =
          (cur.connFailuresByReason[failureReason] ?? 0) + 1;
    }
    if (drop) cur.connDrops++;
    if (silentReconnect) cur.silentReconnects++;
    if (visibleReconnect) cur.visibleReconnects++;
    if (timeToConnectMs != null) cur.timeToConnect.add(timeToConnectMs);
    if (timeToReconnectMs != null) cur.timeToReconnect.add(timeToReconnectMs);
  }

  /// Record a wire-framing anomaly. Exactly one flag is set per call.
  /// No-op when disabled.
  void noteFraming({
    bool partialFrame = false,
    bool leftoverBytes = false,
    bool strayPrompt = false,
    bool garbage = false,
  }) {
    if (!enabled) return;
    final cur = _current;
    if (cur == null) return;
    if (partialFrame) cur.partialFrames++;
    if (leftoverBytes) cur.leftoverBytes++;
    if (strayPrompt) cur.strayPrompts++;
    if (garbage) cur.garbageReads++;
  }

  /// Note one fuel-resolution-tier tick (the branch tag that resolved the
  /// fuel rate this tick). No-op when disabled.
  void noteFuelTier(String tierTag) {
    if (!enabled) return;
    final cur = _current;
    if (cur == null) return;
    cur.fuelTierTicks[tierTag] = (cur.fuelTierTicks[tierTag] ?? 0) + 1;
  }

  /// Build an immutable snapshot of the live session. Returns an empty
  /// [Obd2SessionDiagnostic] (the const-default sentinel) when disabled
  /// or before [beginSession] — so a caller never sees null and the
  /// disabled path allocates nothing beyond the const default.
  Obd2SessionDiagnostic snapshot() {
    final cur = _current;
    if (!enabled || cur == null) return const Obd2SessionDiagnostic();
    return cur.toDiagnostic();
  }

  /// Finalise the live session into the capped ring. No-op when disabled
  /// or when there is no live session.
  void endSession() {
    if (!enabled) return;
    final cur = _current;
    if (cur == null) return;
    _finished.add(cur.toDiagnostic());
    if (_finished.length > maxSessions) _finished.removeAt(0);
    _current = null;
  }

  /// Drop the live + finished sessions. Used by tests and on disable.
  void reset() {
    _current = null;
    _finished.clear();
  }
}

/// Redact a raw adapter MAC for the diagnostics session (#2465).
///
/// MAC is a stable hardware identifier (PII). Everything before the
/// final four characters is replaced with the middle-dot `·` so the
/// length stays visible without leaking the address — the same form the
/// XML/report exporters already use (`obd2_debug_session_xml.dart`,
/// `obd2_diagnostic_report.dart`). A string of four characters or fewer
/// is returned unchanged (there is nothing to hide); null passes through.
String? redactObd2Mac(String? mac) {
  if (mac == null) return null;
  if (mac.length <= 4) return mac;
  final visible = mac.substring(mac.length - 4);
  return '${'·' * (mac.length - 4)}$visible';
}

/// Mutable live-session accumulator. Converted to the immutable
/// [Obd2SessionDiagnostic] on [snapshot]/[endSession].
class _LiveSession {
  _LiveSession({this.linkKind, this.redactedMac});

  final String? linkKind;
  final String? redactedMac;

  String? elmVersion;
  String? protocolDigit;
  int? mtu;
  bool? warmStart;
  String? capabilityTier;

  final List<Obd2HandshakeLine> transcript = <Obd2HandshakeLine>[];
  final Map<String, _PidAccumulator> _pids = <String, _PidAccumulator>{};

  int connAttempts = 0;
  int connSuccesses = 0;
  final Map<String, int> connFailuresByReason = <String, int>{};
  int connDrops = 0;
  int silentReconnects = 0;
  int visibleReconnects = 0;
  final _LatencyReservoir timeToConnect = _LatencyReservoir();
  final _LatencyReservoir timeToReconnect = _LatencyReservoir();

  int partialFrames = 0;
  int leftoverBytes = 0;
  int strayPrompts = 0;
  int garbageReads = 0;

  final Map<String, int> fuelTierTicks = <String, int>{};

  _PidAccumulator pidRow(String pid) =>
      _pids.putIfAbsent(pid, _PidAccumulator.new);

  Obd2SessionDiagnostic toDiagnostic() => Obd2SessionDiagnostic(
        linkKind: linkKind,
        redactedMac: redactedMac,
        elmVersion: elmVersion,
        protocolDigit: protocolDigit,
        mtu: mtu,
        warmStart: warmStart,
        capabilityTier: capabilityTier,
        initTranscript: List.unmodifiable(transcript),
        pidStats: {
          for (final entry in _pids.entries) entry.key: entry.value.toStat(),
        },
        connection: Obd2ConnectionStats(
          attempts: connAttempts,
          successes: connSuccesses,
          failuresByReason: Map.unmodifiable(connFailuresByReason),
          drops: connDrops,
          silentReconnects: silentReconnects,
          visibleReconnects: visibleReconnects,
          timeToConnectP50Ms: timeToConnect.percentileOrNull(50),
          timeToConnectP95Ms: timeToConnect.percentileOrNull(95),
          timeToReconnectP50Ms: timeToReconnect.percentileOrNull(50),
          timeToReconnectP95Ms: timeToReconnect.percentileOrNull(95),
        ),
        framing: Obd2FramingStats(
          partialFrames: partialFrames,
          leftoverBytes: leftoverBytes,
          strayPrompts: strayPrompts,
          garbageReads: garbageReads,
        ),
        fuelTierTicks: Map.unmodifiable(fuelTierTicks),
      );
}

/// Mutable per-PID accumulator backing one [Obd2PidStat] row.
class _PidAccumulator {
  int polled = 0;
  int ok = 0;
  int noData = 0;
  int timeout = 0;
  int error = 0;
  final _LatencyReservoir latency = _LatencyReservoir();

  Obd2PidStat toStat() => Obd2PidStat(
        polled: polled,
        ok: ok,
        noData: noData,
        timeout: timeout,
        error: error,
        latencyP50Ms: latency.percentileOrNull(50) ?? 0,
        latencyP95Ms: latency.percentileOrNull(95) ?? 0,
      );
}

/// Bounded streaming latency reservoir. Retains at most [capacity]
/// samples; once full, new samples evict via reservoir sampling so the
/// retained set stays a uniform random sample of the whole stream — the
/// percentile estimate stays representative without storing every read.
class _LatencyReservoir {
  /// Maximum retained samples — never grows beyond this. 128 samples is
  /// ample for a stable p50/p95 estimate while keeping the per-PID
  /// footprint tiny.
  static const int capacity = 128;

  final List<int> _samples = <int>[];
  int _seen = 0;
  // Deterministic LCG so percentiles are reproducible in tests (no
  // dependency on dart:math Random's global seed).
  int _rng = 0x2545F4914F6CDD1D;

  /// Fold one sample into the reservoir.
  void add(int value) {
    _seen++;
    if (_samples.length < capacity) {
      _samples.add(value);
      return;
    }
    // Reservoir sampling: replace a random slot with decreasing
    // probability so the retained set stays uniform over the stream.
    final j = _nextInt(_seen);
    if (j < capacity) _samples[j] = value;
  }

  /// The [p]-th percentile (0–100) of the retained samples, or null when
  /// empty. Nearest-rank on the sorted retained set.
  int? percentileOrNull(int p) {
    if (_samples.isEmpty) return null;
    final sorted = [..._samples]..sort();
    final clamped = p.clamp(0, 100);
    // Nearest-rank: rank = ceil(p/100 * n), 1-based.
    final rank = ((clamped / 100.0) * sorted.length).ceil();
    final index = (rank <= 0 ? 1 : rank) - 1;
    return sorted[index.clamp(0, sorted.length - 1)];
  }

  /// Deterministic xorshift-based bounded RNG in `[0, bound)`.
  int _nextInt(int bound) {
    var x = _rng;
    x ^= (x << 13) & 0x7FFFFFFFFFFFFFFF;
    x ^= x >> 7;
    x ^= (x << 17) & 0x7FFFFFFFFFFFFFFF;
    _rng = x & 0x7FFFFFFFFFFFFFFF;
    return _rng % bound;
  }
}
