// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../core/calendar/public_holiday_calendar.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../data/models/price_record.dart';
import '../entities/fill_up_guidance.dart';
import 'holiday_premium.dart';

/// Pure, model-free "best time to fill up?" heuristic (#1543).
///
/// This is the no-cost, no-ML, fully on-device alternative to the
/// dormant TFLite path from #1117. It reads only the locally collected
/// price history (passed in by the caller) and never touches the
/// network, a cloud service, or a `.tflite` artifact.
///
/// ## Method
///
/// Given a station's price records and "now", the predictor derives a
/// small, defensible feature set and folds it into one qualitative
/// [FillUpGuidance] verdict:
///
/// 1. **Window + extraction** — keep records inside [windowDays] that
///    carry a price for the requested [FuelType], newest first.
/// 2. **Thin-data guard** — below [minSamples] points the signal is
///    noise; we return [FillUpGuidanceKind.insufficientData] and the
///    UI shows nothing. No claim is ever made from thin data.
/// 3. **Current percentile** — rank the latest price against the whole
///    window (0 = cheapest seen, 100 = dearest). This is the primary
///    "is now cheap?" signal.
/// 4. **Short-term trend** — compare the mean of the newest third of
///    samples to the mean of the oldest third; a swing beyond
///    [trendThresholdEur] is rising / falling, else flat.
/// 5. **Cheap windows** — bucket prices by day-of-week and by coarse
///    time-of-day ([DayPart]); each bucket must clear
///    [minBucketSamples] and at least [minBucketsForSignal] distinct
///    buckets must exist before we trust the cheapest one. The
///    day-of-week spread also yields a potential per-litre saving.
/// 6. **Holiday adjustment** (#2570) — when a [countryCode] is supplied
///    each sample is stamped as on/off a public holiday via
///    [PublicHolidayCalendar]. If "now" is itself a holiday and the
///    window carries a trustworthy holiday premium (the shared
///    [HolidayPremium] maths, ≥ [HolidayPremium.minHolidaySamples]
///    holiday readings and a non-holiday baseline), the verdict is
///    nudged conservatively: holidays that historically run **dearer**
///    lean toward waiting, holidays that run **cheaper** lean toward
///    filling now. The nudge never fabricates a cheaper window and only
///    ever shifts the verdict by one step.
/// 7. **Verdict** —
///    - percentile ≤ [cheapPercentile] → [FillUpGuidanceKind.goodTimeNow]
///    - percentile ≥ [dearPercentile] **and** a cheaper window exists →
///      [FillUpGuidanceKind.waitCheaperWindow]
///    - trend rising (and not already cheap) →
///      [FillUpGuidanceKind.fillSoonRising]
///    - otherwise → [FillUpGuidanceKind.neutral]
///
/// Every threshold is a named constant so the rationale is auditable
/// and the function stays trivially unit-testable.
class FillUpGuidancePredictor {
  const FillUpGuidancePredictor();

  /// Minimum number of priced samples before any verdict is made.
  static const int minSamples = 12;

  /// Minimum samples a single day-of-week / day-part bucket needs
  /// before it counts toward a cheap-window signal.
  static const int minBucketSamples = 2;

  /// Minimum number of distinct buckets that must exist before the
  /// cheapest one is trusted — one or two buckets can't establish a
  /// "typically cheaper on X" pattern.
  static const int minBucketsForSignal = 3;

  /// Price percentile at or below which "now" is treated as cheap.
  static const int cheapPercentile = 25;

  /// Price percentile at or above which "now" is treated as dear.
  static const int dearPercentile = 75;

  /// EUR/L swing between the newest and oldest thirds that counts as a
  /// real trend rather than noise (0.5 ct/L).
  static const double trendThresholdEur = 0.005;

  /// Minimum day-of-week saving spread (EUR/L) worth surfacing as a
  /// "wait for a cheaper day" recommendation (1 ct/L).
  static const double minMeaningfulSavingEur = 0.01;

  /// How far below [dearPercentile] a price may sit and still be
  /// escalated to "wait" when "now" is a holiday that historically runs
  /// dearer (#2570). Keeps the holiday nudge to a single conservative
  /// band rather than overriding a clearly mid-cheap reading.
  static const int holidayDearPercentileRelief = 15;

  /// How far above [cheapPercentile] a price may sit and still be
  /// promoted to "fill now" when "now" is a holiday that historically
  /// runs cheaper (#2570). Symmetric counterpart to
  /// [holidayDearPercentileRelief].
  static const int holidayCheapPercentileRelief = 15;

  /// Computes a [FillUpGuidance] verdict from [history] as of [now].
  ///
  /// [history] may be in any order; only records inside [windowDays] of
  /// [now] that carry a price for [fuelType] are considered. Returns a
  /// [FillUpGuidanceKind.insufficientData] verdict (never `null`) when
  /// the data is too thin — callers gate the UI on
  /// [FillUpGuidance.hasGuidance].
  ///
  /// [countryCode] is the ISO-3166 alpha-2 code of the station's
  /// country (e.g. `'DE'`). When supplied it enables the holiday
  /// adjustment (#2570): samples are stamped on/off public holidays via
  /// [PublicHolidayCalendar] and, if "now" is a holiday with a
  /// trustworthy holiday premium, the verdict is nudged. Pass `null`
  /// (the default) to disable the adjustment entirely — the verdict is
  /// then identical to the pre-#2570 heuristic.
  FillUpGuidance predict({
    required List<PriceRecord> history,
    required FuelType fuelType,
    required DateTime now,
    int windowDays = 30,
    String? countryCode,
  }) {
    final cutoff = now.subtract(Duration(days: windowDays));

    // (timestamp, price, isHoliday) triples inside the window, newest
    // first. The holiday flag is stamped from the shared calendar so
    // the predictor and the price-prediction provider agree on what a
    // "holiday reading" is. With no country the flag still catches the
    // country-agnostic dates (New Year, Christmas).
    final samples = <_Sample>[];
    for (final record in history) {
      if (record.recordedAt.isBefore(cutoff)) continue;
      if (record.recordedAt.isAfter(now)) continue;
      final price = _priceFor(record, fuelType);
      if (price == null) continue;
      samples.add(_Sample(
        record.recordedAt,
        price,
        PublicHolidayCalendar.isPublicHoliday(record.recordedAt, countryCode),
      ));
    }
    samples.sort((a, b) => b.at.compareTo(a.at)); // newest first

    if (samples.length < minSamples) {
      return FillUpGuidance.insufficient(
        sampleCount: samples.length,
        windowDays: windowDays,
      );
    }

    final prices = samples.map((s) => s.price).toList();
    final current = samples.first.price;

    final percentile = _percentileOf(current, prices);
    final trend = _trendOf(samples);

    final dayStat = _cheapestBucket(
      samples,
      (s) => s.at.weekday,
    );
    final dayPartStat = _cheapestBucket(
      samples,
      (s) => _dayPartIndex(s.at.hour),
    );

    final cheapestDayOfWeek = dayStat?.cheapestKey;
    final cheapestDayPart =
        dayPartStat == null ? null : DayPart.values[dayPartStat.cheapestKey];

    final saving = (dayStat != null &&
            dayStat.spread >= minMeaningfulSavingEur)
        ? double.parse(dayStat.spread.toStringAsFixed(3))
        : null;

    final hasCheaperWindow =
        cheapestDayOfWeek != null || cheapestDayPart != null;

    // Holiday adjustment (#2570): only relevant when *today* is itself a
    // public holiday — a holiday premium tells us nothing about a normal
    // day. We reuse the shared premium maths over this window's samples.
    final nowIsHoliday =
        PublicHolidayCalendar.isPublicHoliday(now, countryCode);
    final holidayBias =
        nowIsHoliday ? _holidayBias(samples) : _HolidayBias.none;

    final kind = _verdict(
      percentile: percentile,
      trend: trend,
      hasCheaperWindow: hasCheaperWindow,
      holidayBias: holidayBias,
    );

    return FillUpGuidance(
      kind: kind,
      currentPercentile: percentile,
      trend: trend,
      cheapestDayOfWeek: cheapestDayOfWeek,
      cheapestDayPart: cheapestDayPart,
      potentialSavingPerLitre: saving,
      sampleCount: samples.length,
      windowDays: windowDays,
    );
  }

  // --- Verdict selection ---

  FillUpGuidanceKind _verdict({
    required int percentile,
    required FillUpTrend trend,
    required bool hasCheaperWindow,
    _HolidayBias holidayBias = _HolidayBias.none,
  }) {
    // Cheap-band reading is always a "good time", even on a dearer
    // holiday — the absolute price already beats the window.
    if (percentile <= cheapPercentile) {
      return FillUpGuidanceKind.goodTimeNow;
    }

    // Holiday-cheaper nudge: a slightly-above-cheap reading on a holiday
    // that historically runs cheaper is promoted to "fill now". The
    // relief band keeps this from firing on a genuinely mid/dear price.
    if (holidayBias == _HolidayBias.cheaper &&
        percentile <= cheapPercentile + holidayCheapPercentileRelief) {
      return FillUpGuidanceKind.goodTimeNow;
    }

    // Standard "wait" gate.
    if (percentile >= dearPercentile && hasCheaperWindow) {
      return FillUpGuidanceKind.waitCheaperWindow;
    }

    // Holiday-dearer nudge: a near-dear reading on a holiday that
    // historically runs dearer leans toward waiting — but only when a
    // genuinely cheaper window actually exists to wait for. We never
    // fabricate a window, so the recommendation stays honest.
    if (holidayBias == _HolidayBias.dearer &&
        hasCheaperWindow &&
        percentile >= dearPercentile - holidayDearPercentileRelief) {
      return FillUpGuidanceKind.waitCheaperWindow;
    }

    if (trend == FillUpTrend.rising) {
      return FillUpGuidanceKind.fillSoonRising;
    }
    return FillUpGuidanceKind.neutral;
  }

  /// Resolves the holiday bias for the current window from the shared
  /// [HolidayPremium] maths (#2570). Returns [_HolidayBias.none] when
  /// the premium is absent (too few holiday samples / no baseline) or
  /// below the actionable threshold, so a weak signal never moves the
  /// verdict.
  _HolidayBias _holidayBias(List<_Sample> samples) {
    final holidayPrices = <double>[];
    final nonHolidayPrices = <double>[];
    for (final s in samples) {
      (s.isHoliday ? holidayPrices : nonHolidayPrices).add(s.price);
    }
    final premium = HolidayPremium.compute(
      holidayPrices: holidayPrices,
      nonHolidayPrices: nonHolidayPrices,
    );
    if (!HolidayPremium.isActionable(premium)) return _HolidayBias.none;
    return premium! > 0 ? _HolidayBias.dearer : _HolidayBias.cheaper;
  }

  // --- Statistics helpers (pure) ---

  /// Integer percentile rank (0..100) of [value] within [population],
  /// using the standard mid-point method: samples strictly below count
  /// fully and equal samples count half. This keeps a value that ties a
  /// crowded mode near the middle (≈50) instead of being mislabelled
  /// "cheap" just because many readings share its price. 0 means
  /// nothing is cheaper, 100 means nothing is dearer.
  int _percentileOf(double value, List<double> population) {
    if (population.length <= 1) return 50;
    final below = population.where((p) => p < value).length;
    final equal = population.where((p) => p == value).length;
    return (((below + 0.5 * equal) / population.length) * 100).round();
  }

  /// Trend from the mean of the newest third vs the oldest third of
  /// [samples] (which must be newest-first). Falls back to first-vs-last
  /// when there are too few samples to form thirds.
  FillUpTrend _trendOf(List<_Sample> samples) {
    final n = samples.length;
    final third = (n / 3).floor().clamp(1, n);
    final newest = samples.take(third).map((s) => s.price);
    final oldest = samples.skip(n - third).map((s) => s.price);
    final newMean = _mean(newest.toList());
    final oldMean = _mean(oldest.toList());
    final delta = newMean - oldMean;
    if (delta > trendThresholdEur) return FillUpTrend.rising;
    if (delta < -trendThresholdEur) return FillUpTrend.falling;
    return FillUpTrend.flat;
  }

  /// Buckets [samples] by [keyOf], averages each bucket, and reports
  /// the cheapest key plus the spread to the dearest — but only when
  /// enough qualifying buckets exist. Returns `null` when the signal is
  /// too thin to trust.
  _BucketStat? _cheapestBucket(
    List<_Sample> samples,
    int Function(_Sample) keyOf,
  ) {
    final buckets = <int, List<double>>{};
    for (final s in samples) {
      buckets.putIfAbsent(keyOf(s), () => []).add(s.price);
    }
    // Only buckets with enough samples count toward the signal.
    final averages = <int, double>{};
    for (final entry in buckets.entries) {
      if (entry.value.length < minBucketSamples) continue;
      averages[entry.key] = _mean(entry.value);
    }
    if (averages.length < minBucketsForSignal) return null;

    int? cheapestKey;
    double minAvg = double.infinity;
    double maxAvg = double.negativeInfinity;
    averages.forEach((key, avg) {
      if (avg < minAvg) {
        minAvg = avg;
        cheapestKey = key;
      }
      if (avg > maxAvg) maxAvg = avg;
    });

    return _BucketStat(
      cheapestKey: cheapestKey!,
      spread: maxAvg - minAvg,
    );
  }

  double _mean(List<double> xs) =>
      xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;

  /// Maps an hour (0-23) to a [DayPart] ordinal so it can share the
  /// generic bucketing path. Kept in sync with [DayPart] declaration
  /// order.
  int _dayPartIndex(int hour) {
    if (hour < 6) return DayPart.night.index; // 0:00-5:59
    if (hour < 9) return DayPart.earlyMorning.index; // 6:00-8:59
    if (hour < 12) return DayPart.morning.index; // 9:00-11:59
    if (hour < 18) return DayPart.afternoon.index; // 12:00-17:59
    return DayPart.evening.index; // 18:00-23:59
  }

  double? _priceFor(PriceRecord r, FuelType fuelType) {
    return switch (fuelType) {
      FuelTypeE5() => r.e5,
      FuelTypeE10() => r.e10,
      FuelTypeE98() => r.e98,
      FuelTypeDiesel() => r.diesel,
      FuelTypeDieselPremium() => r.dieselPremium,
      FuelTypeE85() => r.e85,
      FuelTypeLpg() => r.lpg,
      FuelTypeCng() => r.cng,
      FuelTypeHydrogen() || FuelTypeElectric() || FuelTypeAll() => null,
    };
  }
}

/// One (timestamp, price, holiday-flag) observation used internally by
/// the predictor. [isHoliday] is stamped from [PublicHolidayCalendar]
/// at intake (#2570) so the holiday term needs no second calendar pass.
class _Sample {
  final DateTime at;
  final double price;
  final bool isHoliday;
  const _Sample(this.at, this.price, this.isHoliday);
}

/// Direction of the holiday price bias for the current window (#2570).
/// [none] means there is no trustworthy / actionable holiday signal, so
/// the verdict is left exactly as the non-holiday heuristic produced it.
enum _HolidayBias { none, dearer, cheaper }

/// Result of a cheap-window bucketing pass.
class _BucketStat {
  final int cheapestKey;
  final double spread;
  const _BucketStat({required this.cheapestKey, required this.spread});
}
