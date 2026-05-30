// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The qualitative "should I fill up now?" verdict produced by the
/// on-device heuristic predictor (#1543).
///
/// Each value maps to one localized guidance sentence at the
/// presentation layer — the predictor never builds user-facing text
/// itself, so the heuristic stays a pure, locale-agnostic function.
enum FillUpGuidanceKind {
  /// Not enough history to make any defensible claim. The card stays
  /// hidden — we never guess from thin data.
  insufficientData,

  /// The current price sits in the cheapest band of the trailing
  /// window — a good moment to fill up.
  goodTimeNow,

  /// The current price sits in the most expensive band AND there is a
  /// reliably cheaper day-of-week / time-of-day window — suggest
  /// waiting for it.
  waitCheaperWindow,

  /// The short-term trend is clearly rising — suggest filling soon
  /// before it climbs further.
  fillSoonRising,

  /// Mid-band price with no strong signal either way — show a neutral,
  /// informational note rather than a recommendation.
  neutral,
}

/// Short-term price-movement direction over the most recent samples.
enum FillUpTrend { rising, falling, flat }

/// Coarse time-of-day block a cheap window falls into. Keeps the
/// guidance copy short ("Tuesday mornings") instead of an exact hour.
enum DayPart { earlyMorning, morning, afternoon, evening, night }

/// Result of the on-device heuristic price predictor (#1543).
///
/// This is a pure value type with **no** baked user-facing text — the
/// [FillUpGuidanceCard] turns [kind] plus the numeric fields into a
/// localized sentence. That separation is what keeps
/// [FillUpGuidancePredictor.predict] a model-free, unit-testable
/// function and keeps every string in ARB (project HARD RULE).
class FillUpGuidance {
  /// The qualitative verdict. The single source of truth for which
  /// guidance sentence the card renders.
  final FillUpGuidanceKind kind;

  /// Where the current price sits within the trailing window, as an
  /// integer percentile `0..100` (0 = cheapest observed, 100 = dearest).
  /// `null` when [kind] is [FillUpGuidanceKind.insufficientData].
  final int? currentPercentile;

  /// Short-term price direction over the most recent samples.
  final FillUpTrend trend;

  /// Cheapest day of week on average (1 = Monday … 7 = Sunday), or
  /// `null` when no day-of-week signal cleared the sample-size guard.
  final int? cheapestDayOfWeek;

  /// Coarse time-of-day block for the cheapest hours, or `null` when no
  /// time-of-day signal cleared the sample-size guard.
  final DayPart? cheapestDayPart;

  /// Average saving (EUR/L) between the most- and least-expensive
  /// day-of-week windows. `null` when not computable / not meaningful.
  final double? potentialSavingPerLitre;

  /// Number of price points the verdict is based on. Surfaced so the
  /// UI can show "based on N readings" and so callers can audit the
  /// confidence behind a verdict.
  final int sampleCount;

  /// Trailing window length (days) the verdict was computed over.
  final int windowDays;

  const FillUpGuidance({
    required this.kind,
    required this.trend,
    required this.sampleCount,
    required this.windowDays,
    this.currentPercentile,
    this.cheapestDayOfWeek,
    this.cheapestDayPart,
    this.potentialSavingPerLitre,
  });

  /// Canonical "not enough data" result. Carries the [sampleCount] so
  /// callers can still surface how close the user is to the threshold.
  factory FillUpGuidance.insufficient({
    required int sampleCount,
    required int windowDays,
  }) =>
      FillUpGuidance(
        kind: FillUpGuidanceKind.insufficientData,
        trend: FillUpTrend.flat,
        sampleCount: sampleCount,
        windowDays: windowDays,
      );

  /// Whether this verdict carries an actionable recommendation worth
  /// surfacing. `insufficientData` is never actionable.
  bool get hasGuidance => kind != FillUpGuidanceKind.insufficientData;

  @override
  String toString() => 'FillUpGuidance(kind: $kind, '
      'percentile: $currentPercentile, trend: $trend, '
      'cheapestDay: $cheapestDayOfWeek, dayPart: $cheapestDayPart, '
      'saving: $potentialSavingPerLitre, n: $sampleCount/$windowDays d)';
}
