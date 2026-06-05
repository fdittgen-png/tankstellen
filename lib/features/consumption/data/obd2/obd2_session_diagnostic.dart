// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:freezed_annotation/freezed_annotation.dart';

import 'obd2_reconnect_telemetry.dart';
import 'obd2_session_stats.dart';

export 'obd2_reconnect_telemetry.dart'
    show Obd2ReconnectAttempt, Obd2SessionTransition, Obd2SessionState;
export 'obd2_session_stats.dart'
    show
        Obd2SchedulerStats,
        Obd2FuelDowngradeStats,
        Obd2CompletenessStats,
        Obd2FramingStats;

part 'obd2_session_diagnostic.freezed.dart';
part 'obd2_session_diagnostic.g.dart';

/// Immutable per-session snapshot of OBD2 communication health + (later)
/// completeness — the dev-tools analogue of `GpsSampleDiagnostic`
/// (#2464, foundation of Epic #2463).
///
/// Produced by `Obd2CommDiagnostics.snapshot()` and, in later children,
/// stamped (compactly) into the JSON error-log export so the maintainer
/// can reason about a remote dongle↔app failure from one mailed file.
///
/// Like every diagnostics value type in this codebase it is:
///   * **immutable** (freezed) with structural `==` / `hashCode`;
///   * **compact-JSON** round-trippable via short keys (so the export
///     payload stays small);
///   * **bounded by construction** — the collector that fills it caps
///     every list/reservoir, so a snapshot can never grow unboundedly.
///
/// The completeness fields ([expectedReads] / [achievedReads] /
/// [completenessPercent]) are left null/zero by the Wave-1 foundation;
/// Wave 2 (#2465-#2469) fills them once the scheduler instrumentation
/// lands.
@freezed
abstract class Obd2SessionDiagnostic with _$Obd2SessionDiagnostic {
  const factory Obd2SessionDiagnostic({
    /// Transport flavour that carried this session: `'ble'`, `'classic'`,
    /// `'usb'`, or a future link kind. Null until [beginSession] stamps it.
    @JsonKey(name: 'lk') String? linkKind,

    /// Redacted adapter MAC (the existing `_redactMac` form, e.g.
    /// `AA:BB:**:**:**:FF`). Null when unknown / not yet recorded.
    @JsonKey(name: 'mac') String? redactedMac,

    // ---- Adapter identity (filled by recordAdapterIdentity) -----------
    /// ELM firmware banner version string (e.g. `'ELM327 v1.5'`). Null
    /// until the handshake reads ATI.
    @JsonKey(name: 'ev') String? elmVersion,

    /// Auto-detected OBD protocol digit (ELM `ATDPN` reply, e.g. `'6'`
    /// for ISO 15765-4 CAN 11/500). Null until detected.
    @JsonKey(name: 'pd') String? protocolDigit,

    /// Negotiated BLE ATT MTU (bytes). Null for classic/USB links or
    /// before negotiation.
    @JsonKey(name: 'mtu') int? mtu,

    /// True when this session reused a warm (already-initialised) adapter
    /// rather than running the full cold handshake. Null until known.
    @JsonKey(name: 'ws') bool? warmStart,

    /// Firmware-derived runtime capability tier name (#2465) — one of
    /// `'standardOnly'` / `'oemPidsCapable'` / `'passiveCanCapable'`.
    /// Wave 1 records the firmware-CLAIMED tier; Wave 2 will record the
    /// value reconciled by the lazy multi-frame probe. Null until the
    /// handshake reads ATI.
    @JsonKey(name: 'ct') String? capabilityTier,

    /// Redacted ELM init/handshake transcript, capped one-shot at
    /// [maxTranscriptLines] by the collector. Oldest-first.
    @JsonKey(name: 'tx')
    @Default(<Obd2HandshakeLine>[]) List<Obd2HandshakeLine> initTranscript,

    // ---- Per-PID outcome table (Wave 2 fills; Wave 1 leaves empty) ----
    /// Map from a poll command (e.g. `'010C'`) to its 5-way outcome +
    /// latency row. Bounded by the fixed set of polled PIDs.
    @JsonKey(name: 'pid')
    @Default(<String, Obd2PidStat>{}) Map<String, Obd2PidStat> pidStats,

    // ---- Connection lifecycle counters --------------------------------
    /// Connection-lifecycle counters (attempts/successes/drops/reconnects
    /// + time-to-connect reservoirs).
    @JsonKey(name: 'conn')
    @Default(Obd2ConnectionStats()) Obd2ConnectionStats connection,

    // ---- Reconnect telemetry (#2905) ----------------------------------
    /// Bounded per-reconnect-ATTEMPT timeline (#2905): one row per try with
    /// its timestamp, failure reason, backoff, RSSI, latency, ordinal +
    /// success flag. The aggregate [connection] block can't diagnose a
    /// reconnect failure — this can. Capped by the collector at
    /// [maxReconnectAttempts]; oldest dropped first once full.
    @JsonKey(name: 'ra')
    @Default(<Obd2ReconnectAttempt>[])
    List<Obd2ReconnectAttempt> reconnectAttempts,

    /// Bounded session-state-transition timeline (#2905):
    /// connected→dropped→reconnecting→reconnected/orphaned markers plus the
    /// `Obd2DisconnectedException` + GPS-fallback-activation markers. Capped
    /// by the collector at [maxTransitions].
    @JsonKey(name: 'tn')
    @Default(<Obd2SessionTransition>[])
    List<Obd2SessionTransition> transitions,

    /// Epoch-millisecond wall clock when GPS-only fallback recording was
    /// activated for this session (OBD2 dropped, GPS alive). Null when
    /// fallback never activated. The field trajet ran 1024 s entirely on
    /// fallback yet recorded no marker — this fixes that.
    @JsonKey(name: 'fa') int? fallbackActivatedAtMs,

    /// Count of `Obd2DisconnectedException`s raised on the byte stream this
    /// session — the typed-drop signal the trajet export omitted. 0 until
    /// one fires.
    @JsonKey(name: 'de') @Default(0) int disconnectExceptions,

    // ---- Scheduler health (Wave 2 fills) ------------------------------
    /// Achieved scheduler tick-rate (Hz), back-pressure skips, governor
    /// demotions.
    @JsonKey(name: 'sch')
    @Default(Obd2SchedulerStats()) Obd2SchedulerStats scheduler,

    // ---- Framing counters ---------------------------------------------
    /// Wire-framing counters (partial frames / leftover bytes / stray
    /// prompts / garbage reads).
    @JsonKey(name: 'frm')
    @Default(Obd2FramingStats()) Obd2FramingStats framing,

    /// Per-tick fuel-resolution-tier distribution: branch tag → tick
    /// count (e.g. `{'pid5E': 412, 'maf': 88, 'speedDensity': 3}`).
    @JsonKey(name: 'ft')
    @Default(<String, int>{}) Map<String, int> fuelTierTicks,

    /// Fuel-tier downgrade cause rolled up FREE from the breadcrumb
    /// collector (#2469): `total` samples seen vs `suspicious` samples that
    /// tripped a sanity flag (suspicious-low / 5E-vs-MAF divergent). A high
    /// suspicious ratio alongside a [fuelTierTicks] skewed away from `pid5E`
    /// is the downgrade-cause signature. Null/zero until Wave 2 rolls it up.
    @JsonKey(name: 'fd')
    @Default(Obd2FuelDowngradeStats()) Obd2FuelDowngradeStats fuelDowngrade,

    /// How long the session was actively polling, in whole seconds — the
    /// `activeSeconds` term of the completeness expected-reads formula.
    /// 0 until Wave 2 stamps it.
    @JsonKey(name: 'as') @Default(0) int sessionActiveSeconds,

    /// Discovered-supported tri-state per polled command (#2469):
    /// `'supported'` / `'unsupported'` / `'unknown'`. Sourced from the
    /// resolver's discovered set ∩ target set; `'unknown'` for every command
    /// when discovery never ran (probe-less clone / blind session). Empty
    /// until Wave 2 records it.
    @JsonKey(name: 'tri')
    @Default(<String, String>{}) Map<String, String> discoveredSupported,

    // ---- Completeness (Wave 2 fills; null/zero for now) ---------------
    /// Σ(targetHz × activeSeconds) — the expected number of reads if the
    /// scheduler had hit every target. Null until Wave 2 computes it.
    @JsonKey(name: 'er') int? expectedReads,

    /// Reads actually achieved this session. Null until Wave 2.
    @JsonKey(name: 'ar') int? achievedReads,

    /// `achievedReads / expectedReads` as a 0–100 percentage. Null until
    /// Wave 2.
    @JsonKey(name: 'cp') double? completenessPercent,

    /// Per-tier completeness rollup (overall + 5/2/0.5/0.1 Hz tiers +
    /// active duty cycle + emit-index gaps). Empty default until Wave 2
    /// computes it via `summariseObd2Completeness`.
    @JsonKey(name: 'cm')
    @Default(Obd2CompletenessStats()) Obd2CompletenessStats completeness,
  }) = _Obd2SessionDiagnostic;

  const Obd2SessionDiagnostic._();

  factory Obd2SessionDiagnostic.fromJson(Map<String, dynamic> json) =>
      _$Obd2SessionDiagnosticFromJson(json);

  /// Hard cap on the retained init-transcript lines (one-shot per
  /// session). Mirrored by the collector so the snapshot can never carry
  /// more than this.
  static const int maxTranscriptLines = 40;

  /// Hard cap on the retained per-reconnect-attempt rows (#2905). A long
  /// out-of-range drive could otherwise accrue dozens of attempts; the most
  /// recent are the diagnostic value, so the collector keeps the last
  /// [maxReconnectAttempts] and drops the oldest.
  static const int maxReconnectAttempts = 64;

  /// Hard cap on the retained session-state-transition markers (#2905).
  static const int maxTransitions = 96;
}

/// One redacted ELM init/handshake line: the command sent, the (redacted)
/// reply, and the round-trip latency. Bounded set, captured one-shot at
/// connect.
@freezed
abstract class Obd2HandshakeLine with _$Obd2HandshakeLine {
  const factory Obd2HandshakeLine({
    /// The command sent (e.g. `'ATZ'`, `'0100'`). Trimmed.
    @JsonKey(name: 'c') required String cmd,

    /// The redacted reply text. Trimmed; PII (VIN bytes) scrubbed by the
    /// caller before it reaches here.
    @JsonKey(name: 'r') required String response,

    /// Round-trip latency in milliseconds.
    @JsonKey(name: 'l') required int latencyMs,
  }) = _Obd2HandshakeLine;

  factory Obd2HandshakeLine.fromJson(Map<String, dynamic> json) =>
      _$Obd2HandshakeLineFromJson(json);
}

/// Per-PID 5-way outcome counts + latency percentiles for one poll
/// command across the session. Filled by Wave-2 instrumentation.
@freezed
abstract class Obd2PidStat with _$Obd2PidStat {
  const factory Obd2PidStat({
    /// How many times this PID was dispatched.
    @JsonKey(name: 'p') @Default(0) int polled,

    /// Replies classified [ResponseClass.ok].
    @JsonKey(name: 'ok') @Default(0) int ok,

    /// Replies classified [ResponseClass.noData].
    @JsonKey(name: 'nd') @Default(0) int noData,

    /// Reads that elapsed with no reply (caller-set timeout).
    @JsonKey(name: 'to') @Default(0) int timeout,

    /// Replies in any error/garbage bucket (bufferFull/canError/
    /// unrecognized/garbage rolled up).
    @JsonKey(name: 'er') @Default(0) int error,

    /// Median (p50) round-trip latency in ms across this PID's reads.
    @JsonKey(name: 'p50') @Default(0) int latencyP50Ms,

    /// 95th-percentile round-trip latency in ms.
    @JsonKey(name: 'p95') @Default(0) int latencyP95Ms,

    /// Configured target refresh rate (Hz) the scheduler aims for this PID.
    /// 0 when the dispatch tee didn't carry a target (e.g. a one-off raw
    /// read outside the scheduler).
    @JsonKey(name: 'th') @Default(0.0) double targetHz,

    /// Achieved effective refresh rate (Hz) = `ok / sessionActiveSeconds`,
    /// filled by `summariseObd2Completeness`. 0 until completeness runs.
    @JsonKey(name: 'eh') @Default(0.0) double effectiveHz,

    /// Cadence tier name (`'dynamics'`/`'mixture'`/`'slowCorrection'`/
    /// `'thermalContext'`) carried by the dispatch tee. Null for un-tiered
    /// raw reads.
    @JsonKey(name: 'ti') String? tier,

    /// Consecutive transport failures at the last result for this PID — the
    /// scheduler's #2379 backoff streak. 0 when the last read succeeded.
    @JsonKey(name: 'cf') @Default(0) int consecutiveFailures,

    /// True when this PID was in the scheduler's backed-off state at the
    /// last result (failed ≥ the backoff threshold in a row, polled at the
    /// slow ≈1/30 s rate). Persisted so a mostly-NO-DATA PID is visible.
    @JsonKey(name: 'bo') @Default(false) bool backedOff,
  }) = _Obd2PidStat;

  const Obd2PidStat._();

  factory Obd2PidStat.fromJson(Map<String, dynamic> json) =>
      _$Obd2PidStatFromJson(json);

  /// `effectiveHz / targetHz` as a 0–1 attainment ratio, or null when no
  /// target was carried. >1 is possible if the scheduler over-polled (a
  /// never-read PID wins immediately and re-fires).
  double? get targetHzAttainment =>
      targetHz <= 0 ? null : effectiveHz / targetHz;
}

/// Connection-lifecycle counters for the session.
@freezed
abstract class Obd2ConnectionStats with _$Obd2ConnectionStats {
  const factory Obd2ConnectionStats({
    /// Total connection attempts (cold + reconnect).
    @JsonKey(name: 'at') @Default(0) int attempts,

    /// Attempts that established a working link.
    @JsonKey(name: 'su') @Default(0) int successes,

    /// Map from a failure reason tag to its count (e.g.
    /// `{'gattTimeout': 2, 'noElm': 1}`). Bounded by the small set of
    /// known reasons.
    @JsonKey(name: 'fr')
    @Default(<String, int>{}) Map<String, int> failuresByReason,

    /// Detected mid-session link drops.
    @JsonKey(name: 'dr') @Default(0) int drops,

    /// Reconnects that recovered without the user seeing a disconnect.
    @JsonKey(name: 'sr') @Default(0) int silentReconnects,

    /// Reconnects that surfaced a visible disconnect first.
    @JsonKey(name: 'vr') @Default(0) int visibleReconnects,

    /// Time-to-connect reservoir percentiles (ms) for cold connects.
    @JsonKey(name: 'tc') int? timeToConnectP50Ms,
    @JsonKey(name: 'tcp95') int? timeToConnectP95Ms,

    /// Time-to-reconnect reservoir percentiles (ms).
    @JsonKey(name: 'rc') int? timeToReconnectP50Ms,
    @JsonKey(name: 'rcp95') int? timeToReconnectP95Ms,
  }) = _Obd2ConnectionStats;

  factory Obd2ConnectionStats.fromJson(Map<String, dynamic> json) =>
      _$Obd2ConnectionStatsFromJson(json);
}
