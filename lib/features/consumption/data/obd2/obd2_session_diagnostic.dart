// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:freezed_annotation/freezed_annotation.dart';

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

/// Scheduler-health counters. Wave-2 (#2468) fills these from the PID
/// scheduler + its bandwidth governor (`PidScheduler.governorState`).
@freezed
abstract class Obd2SchedulerStats with _$Obd2SchedulerStats {
  const factory Obd2SchedulerStats({
    /// Achieved tick-rate (Hz), the effective poll loop frequency.
    @JsonKey(name: 'tr') @Default(0.0) double tickRateHz,

    /// Ticks skipped because the previous read had not completed
    /// (back-pressure) — the scheduler's `_inFlight != null` early return.
    @JsonKey(name: 'bp') @Default(0) int backpressureSkips,

    /// Governor demotions currently in force — count of commands the
    /// bandwidth governor has demoted to claw back budget for the dynamics
    /// tier on a slow link.
    @JsonKey(name: 'dm') @Default(0) int demotions,

    /// Total scheduler ticks observed (fired commands + backpressure
    /// skips). The denominator that makes [backpressureSkips] a rate.
    @JsonKey(name: 'tk') @Default(0) int ticks,

    /// Achieved total reads/second across all PIDs over the governor's
    /// rolling window (`GovernorState.achievedReadsPerSecond`).
    @JsonKey(name: 'rps') @Default(0.0) double achievedReadsPerSecond,

    /// Effective reads/s the slowest dynamics-tier PID is achieving — the
    /// metric the governor floors. May be very large /
    /// [double.infinity]-derived before two dynamics reads land; the tee
    /// clamps the infinity sentinel to 0 so the JSON stays finite.
    @JsonKey(name: 'dhz') @Default(0.0) double dynamicsEffectiveHz,

    /// PIDs currently in the #2379 backed-off state (≥3 consecutive
    /// failures) — the broadly-unresponsive-adapter indicator.
    @JsonKey(name: 'bof') @Default(0) int backedOffCount,

    /// Starvation indicator: true when the dynamics tier dropped below its
    /// floor (`dynamicsEffectiveHz` measured and < the governor floor) —
    /// RPM / speed are not keeping up despite the floor protection.
    @JsonKey(name: 'st') @Default(false) bool starved,
  }) = _Obd2SchedulerStats;

  factory Obd2SchedulerStats.fromJson(Map<String, dynamic> json) =>
      _$Obd2SchedulerStatsFromJson(json);
}

/// Fuel-tier downgrade-cause rollup (#2469), lifted FREE from the
/// `Obd2BreadcrumbCollector` running tally — no extra adapter I/O.
@freezed
abstract class Obd2FuelDowngradeStats with _$Obd2FuelDowngradeStats {
  const factory Obd2FuelDowngradeStats({
    /// Total fuel-rate samples seen this session.
    @JsonKey(name: 't') @Default(0) int totalSamples,

    /// Samples that tripped a sanity flag (suspicious-low / 5E-vs-MAF
    /// divergent) — the numerator of the suspicion ratio.
    @JsonKey(name: 's') @Default(0) int suspiciousSamples,
  }) = _Obd2FuelDowngradeStats;

  const Obd2FuelDowngradeStats._();

  factory Obd2FuelDowngradeStats.fromJson(Map<String, dynamic> json) =>
      _$Obd2FuelDowngradeStatsFromJson(json);

  /// Suspicious fraction (0–1) of fuel-rate samples, or null when none
  /// were seen.
  double? get suspiciousRatio =>
      totalSamples <= 0 ? null : suspiciousSamples / totalSamples;
}

/// Per-tier + overall session completeness (#2469): the OBD2 analogue of
/// the GPS sampling card. Computed by `summariseObd2Completeness`.
@freezed
abstract class Obd2CompletenessStats with _$Obd2CompletenessStats {
  const factory Obd2CompletenessStats({
    /// Overall `Σ ok / Σ(targetHz × activeSeconds)` as a 0–100 percentage.
    /// 0 when nothing was expected (no active seconds / no targets).
    @JsonKey(name: 'o') @Default(0.0) double overallPercent,

    /// Per-tier completeness percentage keyed by tier name
    /// (`'dynamics'`/`'mixture'`/`'slowCorrection'`/`'thermalContext'`).
    @JsonKey(name: 'pt')
    @Default(<String, double>{}) Map<String, double> perTierPercent,

    /// Fraction (0–1) of the session the scheduler was actively polling —
    /// `min(1, totalAchievedReads / totalExpectedReads)`, clamped. A proxy
    /// for "was the link delivering" vs idle/stalled.
    @JsonKey(name: 'dc') @Default(0.0) double activeDutyCycle,

    /// True when an emit-index gap was detected — a tier whose attainment
    /// fell below [emitGapThreshold], i.e. the scheduler skipped a
    /// meaningful share of that tier's expected reads.
    @JsonKey(name: 'eg') @Default(false) bool emitGapDetected,
  }) = _Obd2CompletenessStats;

  factory Obd2CompletenessStats.fromJson(Map<String, dynamic> json) =>
      _$Obd2CompletenessStatsFromJson(json);

  /// A tier whose achieved/expected ratio falls below this is treated as a
  /// detected emit-index gap.
  static const double emitGapThreshold = 0.7;
}

/// Wire-framing counters — the symptoms of a sloppy clone's serial line.
@freezed
abstract class Obd2FramingStats with _$Obd2FramingStats {
  const factory Obd2FramingStats({
    /// Reads that arrived as an incomplete frame (no terminating prompt).
    @JsonKey(name: 'pf') @Default(0) int partialFrames,

    /// Reads where leftover bytes from a prior frame prefixed this one.
    @JsonKey(name: 'lo') @Default(0) int leftoverBytes,

    /// Stray bare `>` prompts read with no data.
    @JsonKey(name: 'sp') @Default(0) int strayPrompts,

    /// Reads that classified as [ResponseClass.garbage].
    @JsonKey(name: 'gb') @Default(0) int garbageReads,
  }) = _Obd2FramingStats;

  factory Obd2FramingStats.fromJson(Map<String, dynamic> json) =>
      _$Obd2FramingStatsFromJson(json);
}
