// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'obd2_response_class.dart';
import 'obd2_session_completeness.dart';
import 'obd2_session_diagnostic.dart';

/// The mutable live-session accumulator + bounded reservoir + the MAC
/// redactor live in this part so the collector file stays under the
/// 400-line cap (#2468/#2469 added the scheduler/completeness storage).
part 'obd2_comm_diagnostics_internal.dart';

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
  Obd2CommDiagnostics({this.enabled = false, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  /// Injectable wall clock for deterministic [sessionActiveSeconds] in
  /// tests. Production always uses [DateTime.now].
  final DateTime Function() _clock;

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
    _current = _LiveSession(
      linkKind: linkKind,
      redactedMac: redactedMac,
      startedAt: _clock(),
    );
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

  /// Note that a poll command [pid] was dispatched, optionally carrying the
  /// scheduler's configured [targetHz] + cadence [tier] (#2468) so the
  /// per-PID table can report target-Hz attainment per tier. No-op when
  /// disabled.
  void noteDispatch(String pid, {double? targetHz, String? tier}) {
    if (!enabled) return;
    final cur = _current;
    if (cur == null) return;
    final row = cur.pidRow(pid);
    row.polled++;
    if (targetHz != null) row.targetHz = targetHz;
    if (tier != null) row.tier = tier;
  }

  /// Note the outcome [cls] of a poll for [pid], with optional round-trip
  /// time [rttMs] folded into the latency reservoir and the scheduler's
  /// current [consecutiveFailures] streak + [backedOff] state (#2468,
  /// #2379). No-op when disabled.
  void noteResult(
    String pid,
    ResponseClass cls, {
    int? rttMs,
    int? consecutiveFailures,
    bool? backedOff,
  }) {
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
    if (consecutiveFailures != null) {
      row.consecutiveFailures = consecutiveFailures;
    }
    if (backedOff != null) row.backedOff = backedOff;
  }

  /// Tee the scheduler's health snapshot (#2468): a back-pressure skip
  /// (`backpressureSkip: true`) OR a once-per-tee governor/tick rollup. The
  /// scheduler calls this with the cheap counters it already keeps plus its
  /// `governorState`. No-op when disabled.
  void recordSchedulerHealth({
    bool backpressureSkip = false,
    bool tick = false,
    double? tickRateHz,
    double? achievedReadsPerSecond,
    double? dynamicsEffectiveHz,
    int? demotions,
    int? backedOffCount,
    bool? starved,
  }) {
    if (!enabled) return;
    final cur = _current;
    if (cur == null) return;
    if (backpressureSkip) cur.backpressureSkips++;
    if (tick) cur.schedulerTicks++;
    if (tickRateHz != null) cur.tickRateHz = tickRateHz;
    if (achievedReadsPerSecond != null) {
      cur.achievedReadsPerSecond = achievedReadsPerSecond;
    }
    if (dynamicsEffectiveHz != null) {
      // Clamp the governor's infinity cold-start sentinel to 0 so the JSON
      // stays finite + round-trippable.
      cur.dynamicsEffectiveHz =
          dynamicsEffectiveHz.isFinite ? dynamicsEffectiveHz : 0.0;
    }
    if (demotions != null) cur.demotions = demotions;
    if (backedOffCount != null) cur.backedOffCount = backedOffCount;
    if (starved != null) cur.starved = starved;
  }

  /// Record the discovered-supported tri-state for [pid] (#2469):
  /// `'supported'` / `'unsupported'` / `'unknown'`. No-op when disabled.
  void recordSupportedTriState(String pid, String triState) {
    if (!enabled) return;
    final cur = _current;
    if (cur == null) return;
    cur.discoveredSupported[pid] = triState;
  }

  /// Roll up the fuel-tier downgrade cause FREE from the breadcrumb
  /// collector's running tally (#2469): [totalSamples] seen vs
  /// [suspiciousSamples] that tripped a sanity flag. No-op when disabled.
  void recordFuelDowngrade({
    required int totalSamples,
    required int suspiciousSamples,
  }) {
    if (!enabled) return;
    final cur = _current;
    if (cur == null) return;
    cur.fuelTotalSamples = totalSamples;
    cur.fuelSuspiciousSamples = suspiciousSamples;
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
    return _summarise(cur);
  }

  /// Capture the diagnostic worth PERSISTING with a finished trip (#2912).
  ///
  /// The trip-detail comm-health card was always empty because it read the
  /// process-wide singleton instead of the viewed trip's own diagnostic; the
  /// fix snapshots this at trip finish and stores it on the trip record. We
  /// prefer the live session (which carries THIS trip's connection attempts,
  /// reconnect timeline + fallback markers, even when the adapter never
  /// connected) and fall back to the most recent finished session.
  ///
  /// Returns `null` — never the empty const sentinel — when there is nothing
  /// worth persisting (disabled, or a session with no signal at all), so a
  /// pure GPS-only trip that never touched OBD2 stores zero extra bytes and
  /// the card keeps self-hiding. "Has signal" mirrors the card's own
  /// `computeObd2DiagnosticsSummary` gate so a session the card would render
  /// is exactly a session we persist.
  ///
  /// **Never-throws contract:** called from the trip-save flow at trip finish,
  /// so any internal fault degrades to `null` (the trip still saves, just
  /// without a diagnostic) rather than derailing the save (#1103).
  Obd2SessionDiagnostic? captureForTrip() {
    if (!enabled) return null;
    try {
      final live = _current != null ? _summarise(_current!) : null;
      if (live != null && _hasSignal(live)) return live;
      if (_finished.isNotEmpty && _hasSignal(_finished.last)) {
        return _finished.last;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Whether [d] carries any diagnostic signal worth surfacing — the same
  /// predicate `computeObd2DiagnosticsSummary` uses to choose its non-empty
  /// branch. Kept inline so the collector stays free of a presentation-layer
  /// import; a connection ATTEMPT alone (even a failed connect) counts, which
  /// is exactly the "adapter never connected" case #2912 must still surface.
  static bool _hasSignal(Obd2SessionDiagnostic d) =>
      d.pidStats.isNotEmpty ||
      d.connection.attempts > 0 ||
      d.redactedMac != null ||
      d.elmVersion != null ||
      d.reconnectAttempts.isNotEmpty ||
      d.transitions.isNotEmpty ||
      d.disconnectExceptions > 0 ||
      d.fallbackActivatedAtMs != null;

  /// Finalise the live session into the capped ring. No-op when disabled
  /// or when there is no live session.
  void endSession() {
    if (!enabled) return;
    final cur = _current;
    if (cur == null) return;
    _finished.add(_summarise(cur));
    if (_finished.length > maxSessions) _finished.removeAt(0);
    _current = null;
  }

  /// Build the raw snapshot (stamping the elapsed active seconds) and run
  /// the pure completeness summariser (#2469) over it.
  Obd2SessionDiagnostic _summarise(_LiveSession cur) {
    final activeSeconds = _clock().difference(cur.startedAt).inSeconds;
    return summariseObd2Completeness(cur.toDiagnostic(activeSeconds));
  }

  /// Drop the live + finished sessions. Used by tests and on disable.
  void reset() {
    _current = null;
    _finished.clear();
  }
}
