// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:freezed_annotation/freezed_annotation.dart';

part 'obd2_session_stats.freezed.dart';
part 'obd2_session_stats.g.dart';

/// Secondary per-session diagnostics stat value types (#2905 — extracted
/// from `obd2_session_diagnostic.dart` to keep that file under the 400-line
/// cap once the reconnect-telemetry fields landed).
///
/// These are the scheduler-health, fuel-downgrade, completeness, and
/// wire-framing rollups that hang off [Obd2SessionDiagnostic]. They are
/// independent freezed value types with no back-reference to the session,
/// so they live cleanly in their own library; the session diagnostic file
/// re-exports them so existing imports keep working.

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
