// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/price_history/data/models/price_record.dart';
import 'package:tankstellen/features/price_history/domain/entities/fill_up_guidance.dart';
import 'package:tankstellen/features/price_history/domain/services/fill_up_guidance_predictor.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';

/// Unit tests for the pure, model-free [FillUpGuidancePredictor] (#1543).
///
/// Every case drives the function directly with a fixed `now`, so the
/// heuristic is exercised without any Flutter / Riverpod / storage
/// machinery — that's the whole point of keeping it a pure function.
void main() {
  const predictor = FillUpGuidancePredictor();
  // A fixed "now" — Friday 2026-03-13 22:00 — so weekday/day-part maths
  // are deterministic and same-day noon-slot fixtures fall *before*
  // `now` (records after `now` are excluded by the predictor).
  final now = DateTime(2026, 3, 13, 22);

  PriceRecord rec(DateTime at, double e10) =>
      PriceRecord(stationId: 's1', recordedAt: at, e10: e10);

  group('thin-data guard', () {
    test('returns insufficientData below the sample threshold', () {
      final history = [
        for (int i = 0; i < FillUpGuidancePredictor.minSamples - 1; i++)
          rec(now.subtract(Duration(days: i)), 1.50),
      ];

      final g = predictor.predict(
        history: history,
        fuelType: FuelType.e10,
        now: now,
      );

      expect(g.kind, FillUpGuidanceKind.insufficientData);
      expect(g.hasGuidance, isFalse);
      expect(g.sampleCount, FillUpGuidancePredictor.minSamples - 1);
    });

    test('empty history is insufficientData, never throws', () {
      final g = predictor.predict(
        history: const [],
        fuelType: FuelType.e10,
        now: now,
      );
      expect(g.kind, FillUpGuidanceKind.insufficientData);
      expect(g.sampleCount, 0);
    });

    test('records for a different fuel type do not count toward the guard',
        () {
      // 20 diesel-only records → zero e10 samples → insufficient.
      final history = [
        for (int i = 0; i < 20; i++)
          PriceRecord(
            stationId: 's1',
            recordedAt: now.subtract(Duration(days: i)),
            diesel: 1.40,
          ),
      ];
      final g = predictor.predict(
        history: history,
        fuelType: FuelType.e10,
        now: now,
      );
      expect(g.kind, FillUpGuidanceKind.insufficientData);
      expect(g.sampleCount, 0);
    });

    test('records older than the window are excluded', () {
      // 15 records all 40+ days ago → outside the 30-day window.
      final history = [
        for (int i = 0; i < 15; i++)
          rec(now.subtract(Duration(days: 40 + i)), 1.50),
      ];
      final g = predictor.predict(
        history: history,
        fuelType: FuelType.e10,
        now: now,
      );
      expect(g.kind, FillUpGuidanceKind.insufficientData);
    });

    test('hydrogen / electric / all are never priced (always insufficient)',
        () {
      final history = [
        for (int i = 0; i < 20; i++)
          rec(now.subtract(Duration(days: i)), 1.50),
      ];
      for (final ft in [FuelType.hydrogen, FuelType.electric, FuelType.all]) {
        final g = predictor.predict(
          history: history,
          fuelType: ft,
          now: now,
        );
        expect(g.kind, FillUpGuidanceKind.insufficientData,
            reason: '$ft should yield no priced samples');
      }
    });
  });

  group('current-price percentile', () {
    test('cheapest current price → low percentile → goodTimeNow', () {
      // 19 dear historical readings + a cheap current reading.
      final history = <PriceRecord>[
        rec(now, 1.30), // current (newest) — cheapest
        for (int i = 1; i < 20; i++)
          rec(now.subtract(Duration(days: i)), 1.60),
      ];
      final g = predictor.predict(
        history: history,
        fuelType: FuelType.e10,
        now: now,
      );
      expect(g.currentPercentile, lessThanOrEqualTo(
          FillUpGuidancePredictor.cheapPercentile));
      expect(g.kind, FillUpGuidanceKind.goodTimeNow);
    });

    test('dearest current price → high percentile', () {
      final history = <PriceRecord>[
        rec(now, 1.90), // current — dearest
        for (int i = 1; i < 20; i++)
          rec(now.subtract(Duration(days: i)), 1.50),
      ];
      final g = predictor.predict(
        history: history,
        fuelType: FuelType.e10,
        now: now,
      );
      expect(g.currentPercentile, greaterThanOrEqualTo(
          FillUpGuidancePredictor.dearPercentile));
    });

    test('mid-band current price → mid percentile', () {
      // Linear ramp 1.40 … 1.59; current sits in the middle.
      final prices = [for (int i = 0; i < 20; i++) 1.40 + i * 0.01];
      final history = <PriceRecord>[
        rec(now, 1.50), // current — middle of the ramp
        for (int i = 1; i < 20; i++)
          rec(now.subtract(Duration(days: i)), prices[i]),
      ];
      final g = predictor.predict(
        history: history,
        fuelType: FuelType.e10,
        now: now,
      );
      expect(g.currentPercentile, inInclusiveRange(26, 74));
    });
  });

  group('trend detection', () {
    test('rising prices over the window → FillUpTrend.rising', () {
      // Oldest cheap, newest dear. Newest-first index 0 is "now".
      final history = <PriceRecord>[
        for (int i = 0; i < 21; i++)
          rec(now.subtract(Duration(days: i)), 1.70 - i * 0.02),
      ];
      final g = predictor.predict(
        history: history,
        fuelType: FuelType.e10,
        now: now,
      );
      expect(g.trend, FillUpTrend.rising);
    });

    test('falling prices over the window → FillUpTrend.falling', () {
      // Oldest dear, newest cheap.
      final history = <PriceRecord>[
        for (int i = 0; i < 21; i++)
          rec(now.subtract(Duration(days: i)), 1.30 + i * 0.02),
      ];
      final g = predictor.predict(
        history: history,
        fuelType: FuelType.e10,
        now: now,
      );
      expect(g.trend, FillUpTrend.falling);
    });

    test('flat prices → FillUpTrend.flat', () {
      final history = <PriceRecord>[
        for (int i = 0; i < 20; i++)
          rec(now.subtract(Duration(days: i)), 1.50),
      ];
      final g = predictor.predict(
        history: history,
        fuelType: FuelType.e10,
        now: now,
      );
      expect(g.trend, FillUpTrend.flat);
    });

    test('rising trend with no cheaper window → fillSoonRising', () {
      // All readings on the SAME weekday + hour → no day-of-week or
      // day-part window signal can fire, so the verdict can't be
      // waitCheaperWindow. Values rise toward the present but the
      // current reading sits mid-pack (not the absolute max), so it's
      // neither cheap (≤25th) nor at a dear band that matters without a
      // window — the rising trend is the deciding signal.
      // Spread minutes across the same date+hour so every reading lands
      // in the same weekday bucket AND the same day-part bucket — no
      // window signal can fire. Newest-first ordering is by timestamp,
      // so the latest minute is "current".
      DateTime sameSlot(int minute) =>
          DateTime(now.year, now.month, now.day, 12, minute);
      final history = <PriceRecord>[
        rec(sameSlot(59), 1.55), // current (latest minute) — mid-pack
        rec(sameSlot(40), 1.62), // an earlier dearer peak, same slot
        rec(sameSlot(35), 1.60),
        for (int i = 0; i < 12; i++) rec(sameSlot(i), 1.40 + i * 0.003),
      ];
      final g = predictor.predict(
        history: history,
        fuelType: FuelType.e10,
        now: now,
      );
      expect(g.trend, FillUpTrend.rising);
      expect(g.cheapestDayOfWeek, isNull,
          reason: 'single weekday bucket → no day-of-week window');
      expect(g.cheapestDayPart, isNull,
          reason: 'single day-part bucket → no time-of-day window');
      expect(g.kind, FillUpGuidanceKind.fillSoonRising);
    });
  });

  group('cheap-window detection', () {
    test('detects the cheapest day-of-week with enough buckets', () {
      // 4 weeks of noon readings. Monday is reliably the cheapest day
      // (1.40); every other day is dear (1.60). The single current
      // reading is a dearer spike (1.75) so it lands above the 75th
      // percentile and a cheaper day-of-week window genuinely exists →
      // waitCheaperWindow pointing at Monday.
      final history = <PriceRecord>[
        rec(now, 1.75), // current — dearest, drives the high percentile
      ];
      for (int d = 1; d < 28; d++) {
        final at = now.subtract(Duration(days: d));
        history.add(rec(
          DateTime(at.year, at.month, at.day, 12),
          at.weekday == DateTime.monday ? 1.40 : 1.60,
        ));
      }
      final g = predictor.predict(
        history: history,
        fuelType: FuelType.e10,
        now: now,
      );
      expect(g.cheapestDayOfWeek, DateTime.monday);
      expect(g.potentialSavingPerLitre, isNotNull);
      expect(g.potentialSavingPerLitre, greaterThan(0));
      expect(g.currentPercentile, greaterThanOrEqualTo(
          FillUpGuidancePredictor.dearPercentile));
      expect(g.kind, FillUpGuidanceKind.waitCheaperWindow);
    });

    test('detects the cheapest day-part', () {
      // Mornings (9-11) cheap, evenings (18+) dear, spread across days
      // so each day-part bucket clears the per-bucket sample guard and
      // at least 3 distinct day-parts exist.
      final history = <PriceRecord>[];
      for (int d = 0; d < 8; d++) {
        final day = now.subtract(Duration(days: d));
        history.add(rec(DateTime(day.year, day.month, day.day, 10), 1.40));
        history.add(rec(DateTime(day.year, day.month, day.day, 15), 1.55));
        history.add(rec(DateTime(day.year, day.month, day.day, 20), 1.65));
      }
      final g = predictor.predict(
        history: history,
        fuelType: FuelType.e10,
        now: now,
      );
      expect(g.cheapestDayPart, DayPart.morning);
    });

    test('no cheap-window signal when too few distinct buckets', () {
      // All 14 readings on the same weekday + same hour → only one
      // day-of-week bucket and one day-part bucket → below the
      // 3-bucket signal floor → no cheapest day / part surfaced.
      final history = <PriceRecord>[];
      for (int w = 0; w < 14; w++) {
        // step back 7 days each time → always the same weekday & hour.
        final at = now.subtract(Duration(days: 7 * w));
        history.add(rec(DateTime(at.year, at.month, at.day, 12), 1.50));
      }
      final g = predictor.predict(
        history: history,
        fuelType: FuelType.e10,
        now: now,
      );
      expect(g.cheapestDayOfWeek, isNull);
      expect(g.cheapestDayPart, isNull);
      expect(g.potentialSavingPerLitre, isNull);
    });

    test('high current price with NO cheaper window → not waitCheaperWindow',
        () {
      // 14 readings, all on the same date+hour slot (no window signal),
      // newest is clearly dear. Without a cheaper window the verdict
      // must not be waitCheaperWindow — it falls through to trend /
      // neutral.
      DateTime sameSlot(int minute) =>
          DateTime(now.year, now.month, now.day, 12, minute);
      final history = <PriceRecord>[
        rec(sameSlot(59), 1.90), // current dear (latest minute)
        for (int i = 0; i < 13; i++) rec(sameSlot(i), 1.50),
      ];
      final g = predictor.predict(
        history: history,
        fuelType: FuelType.e10,
        now: now,
      );
      expect(g.currentPercentile, greaterThanOrEqualTo(
          FillUpGuidancePredictor.dearPercentile));
      expect(g.kind, isNot(FillUpGuidanceKind.waitCheaperWindow));
    });
  });

  group('verdict + metadata', () {
    test('neutral verdict for mid-band, flat, no-window series', () {
      // Constant price on the SAME date+hour slot: no cheap-window
      // signal, a flat trend, and the current price equals the whole
      // population → mid-band percentile. Verdict is the neutral note.
      DateTime sameSlot(int minute) =>
          DateTime(now.year, now.month, now.day, 12, minute);
      final history = <PriceRecord>[
        for (int i = 0; i < 16; i++) rec(sameSlot(i), 1.50),
      ];
      final g = predictor.predict(
        history: history,
        fuelType: FuelType.e10,
        now: now,
      );
      expect(g.trend, FillUpTrend.flat);
      expect(g.currentPercentile, inInclusiveRange(26, 74));
      expect(g.kind, FillUpGuidanceKind.neutral);
    });

    test('always reports sampleCount and windowDays', () {
      final history = [
        for (int i = 0; i < 15; i++)
          rec(now.subtract(Duration(days: i)), 1.50 + (i % 3) * 0.01),
      ];
      final g = predictor.predict(
        history: history,
        fuelType: FuelType.e10,
        now: now,
        windowDays: 30,
      );
      expect(g.sampleCount, 15);
      expect(g.windowDays, 30);
    });

    test('respects a custom windowDays', () {
      // 15 readings within 7 days, 15 more between day 8 and 22.
      final history = <PriceRecord>[
        for (int i = 0; i < 15; i++)
          rec(now.subtract(Duration(days: i % 7)), 1.50),
        for (int i = 0; i < 15; i++)
          rec(now.subtract(Duration(days: 8 + i)), 1.50),
      ];
      final g = predictor.predict(
        history: history,
        fuelType: FuelType.e10,
        now: now,
        windowDays: 7,
      );
      expect(g.windowDays, 7);
      // Only the within-7-days readings count.
      expect(g.sampleCount, 15);
    });
  });

  group('holiday adjustment (#2570)', () {
    // All cases below share a fixed window anchored on New Year's Day
    // 2027 (a country-agnostic public holiday) so "now" is itself a
    // holiday without needing a country code. The trailing 30-day
    // window also captures Christmas Day 2026 — the second
    // country-agnostic date — giving 3+ holiday readings for the
    // shared premium maths to trust.
    final newYear = DateTime(2027, 1, 1, 12); // Fri, public holiday

    /// History where holiday readings run *dearer* than the
    /// non-holiday baseline, with the current (New Year) price sitting
    /// in the near-dear band (~61st percentile) and a genuine cheaper
    /// day-of-week / day-part window present. Engineered so the
    /// baseline (non-holiday) verdict is `fillSoonRising` but a
    /// dearer-holiday nudge escalates it to `waitCheaperWindow`.
    List<PriceRecord> dearerHolidayHistory() => <PriceRecord>[
          rec(newYear, 1.625), // current — New Year, near-dear
          // 3 dear Christmas readings → holiday avg well above baseline.
          rec(DateTime(2026, 12, 25, 9), 1.72),
          rec(DateTime(2026, 12, 25, 14), 1.73),
          rec(DateTime(2026, 12, 25, 19), 1.71),
          // Non-holiday baseline spread across weekdays + dayparts so a
          // cheaper window genuinely exists. Two readings sit above the
          // current price to keep the percentile below the 75th.
          rec(DateTime(2026, 12, 14, 9), 1.55),
          rec(DateTime(2026, 12, 14, 20), 1.58),
          rec(DateTime(2026, 12, 15, 9), 1.56),
          rec(DateTime(2026, 12, 15, 20), 1.59),
          rec(DateTime(2026, 12, 16, 10), 1.57),
          rec(DateTime(2026, 12, 16, 20), 1.60),
          rec(DateTime(2026, 12, 17, 10), 1.61),
          rec(DateTime(2026, 12, 17, 20), 1.62),
          rec(DateTime(2026, 12, 21, 10), 1.66),
          rec(DateTime(2026, 12, 22, 10), 1.68),
        ];

    /// History where holiday readings run *cheaper* than baseline, with
    /// the current (New Year) price in the slightly-above-cheap band
    /// (~39th percentile). Baseline verdict is `neutral`; a
    /// cheaper-holiday nudge promotes it to `goodTimeNow`.
    List<PriceRecord> cheaperHolidayHistory() => <PriceRecord>[
          rec(newYear, 1.50), // current — New Year, mid-low
          rec(DateTime(2026, 12, 25, 9), 1.40),
          rec(DateTime(2026, 12, 25, 14), 1.41),
          rec(DateTime(2026, 12, 25, 19), 1.42),
          rec(DateTime(2026, 12, 14, 9), 1.55),
          rec(DateTime(2026, 12, 14, 20), 1.60),
          rec(DateTime(2026, 12, 15, 9), 1.52),
          rec(DateTime(2026, 12, 15, 20), 1.62),
          rec(DateTime(2026, 12, 16, 10), 1.48),
          rec(DateTime(2026, 12, 16, 20), 1.64),
          rec(DateTime(2026, 12, 17, 10), 1.49),
          rec(DateTime(2026, 12, 17, 20), 1.66),
          rec(DateTime(2026, 12, 21, 10), 1.53),
          rec(DateTime(2026, 12, 22, 10), 1.58),
        ];

    test('today a holiday + holidays historically dearer → leans wait', () {
      final g = predictor.predict(
        history: dearerHolidayHistory(),
        fuelType: FuelType.e10,
        now: newYear, // New Year is itself the holiday
      );
      // Sanity: the current price is near-dear but below the 75th, so
      // the standard dear gate would NOT fire on its own.
      expect(g.currentPercentile, inInclusiveRange(60, 74));
      expect(g.kind, FillUpGuidanceKind.waitCheaperWindow,
          reason: 'a dearer holiday nudges a near-dear reading to wait');
    });

    test('today a holiday + holidays historically cheaper → leans fill', () {
      final g = predictor.predict(
        history: cheaperHolidayHistory(),
        fuelType: FuelType.e10,
        now: newYear,
      );
      // Sanity: the current price is above the cheap band, so the
      // standard cheap gate would NOT fire on its own.
      expect(g.currentPercentile, greaterThan(
          FillUpGuidancePredictor.cheapPercentile));
      expect(g.kind, FillUpGuidanceKind.goodTimeNow,
          reason: 'a cheaper holiday nudges a near-cheap reading to fill now');
    });

    test('same dearer history but today NOT a holiday → verdict unchanged', () {
      // Anchor "now" one day later (Jan 2 2027 — not a holiday). The
      // newest sample is still the Jan 1 reading and the 30-day window
      // is identical, so the only thing that changes vs the case above
      // is that today is no longer a holiday → no nudge → the baseline
      // verdict stands. This is the regression-lock for #2570.
      final notAHoliday = DateTime(2027, 1, 2, 12);
      final g = predictor.predict(
        history: dearerHolidayHistory(),
        fuelType: FuelType.e10,
        now: notAHoliday,
      );
      expect(g.currentPercentile, inInclusiveRange(60, 74));
      expect(g.kind, FillUpGuidanceKind.fillSoonRising,
          reason: 'no holiday today → the pre-#2570 verdict is preserved');
    });

    test('same cheaper history but today NOT a holiday → verdict unchanged', () {
      final notAHoliday = DateTime(2027, 1, 2, 12);
      final g = predictor.predict(
        history: cheaperHolidayHistory(),
        fuelType: FuelType.e10,
        now: notAHoliday,
      );
      expect(g.kind, FillUpGuidanceKind.neutral,
          reason: 'no holiday today → the pre-#2570 verdict is preserved');
    });

    test('no holiday readings in the window → holiday path is inert', () {
      // A plain rising series on distinct weekdays, none on a holiday.
      // With zero holiday samples the shared premium is null, so the
      // holiday term contributes nothing and the verdict must be
      // identical whether or not a country code is supplied. This is the
      // regression-lock: the #2570 change is a no-op when there is no
      // holiday signal.
      final baseNow = DateTime(2026, 3, 13, 22); // the file's default now
      final history = <PriceRecord>[
        for (int i = 0; i < 21; i++)
          rec(baseNow.subtract(Duration(days: i)), 1.70 - i * 0.02),
      ];
      final withoutCountry = predictor.predict(
        history: history,
        fuelType: FuelType.e10,
        now: baseNow,
      );
      final withCountry = predictor.predict(
        history: history,
        fuelType: FuelType.e10,
        now: baseNow,
        countryCode: 'DE',
      );
      expect(withoutCountry.trend, FillUpTrend.rising);
      // No holiday samples → the country code changes nothing.
      expect(withCountry.kind, withoutCountry.kind);
      expect(withCountry.currentPercentile, withoutCountry.currentPercentile);
    });

    test('country-specific holiday only nudges when its countryCode is set',
        () {
      // German Unity Day (Oct 3) is a DE-only fixed date — it is NOT a
      // country-agnostic holiday, so it flags only when countryCode
      // resolves to 'DE'. We reuse the dearer-history shape but move the
      // holiday readings and "now" onto Oct 3 2026 so the nudge depends
      // entirely on the country code. "now" is the evening so all four
      // Unity-Day readings fall before it (records after `now` are
      // excluded), giving the 3+ holiday samples the premium needs.
      final unityDay = DateTime(2026, 10, 3, 22); // Sat evening, DE day
      List<PriceRecord> deHistory() => <PriceRecord>[
            rec(DateTime(2026, 10, 3, 18), 1.625), // current — Unity Day
            // 3 more dear readings, also on Unity Day (distinct hours).
            rec(DateTime(2026, 10, 3, 7), 1.72),
            rec(DateTime(2026, 10, 3, 10), 1.73),
            rec(DateTime(2026, 10, 3, 14), 1.71),
            // Non-holiday baseline across distinct weekdays / dayparts.
            rec(DateTime(2026, 9, 14, 9), 1.55),
            rec(DateTime(2026, 9, 14, 20), 1.58),
            rec(DateTime(2026, 9, 15, 9), 1.56),
            rec(DateTime(2026, 9, 15, 20), 1.59),
            rec(DateTime(2026, 9, 16, 10), 1.57),
            rec(DateTime(2026, 9, 16, 20), 1.60),
            rec(DateTime(2026, 9, 17, 10), 1.61),
            rec(DateTime(2026, 9, 17, 20), 1.62),
            rec(DateTime(2026, 9, 21, 10), 1.66),
            rec(DateTime(2026, 9, 22, 10), 1.68),
          ];

      // Without a country code, Oct 3 is just a normal day → no nudge →
      // baseline verdict (fillSoonRising for this near-dear rising set).
      final withoutCountry = predictor.predict(
        history: deHistory(),
        fuelType: FuelType.e10,
        now: unityDay,
      );
      expect(withoutCountry.kind, FillUpGuidanceKind.fillSoonRising,
          reason: 'Oct 3 is not country-agnostic; null country = no nudge');

      // With 'DE', Oct 3 flags as a holiday → dearer nudge → wait.
      final withCountry = predictor.predict(
        history: deHistory(),
        fuelType: FuelType.e10,
        now: unityDay,
        countryCode: 'DE',
      );
      expect(withCountry.kind, FillUpGuidanceKind.waitCheaperWindow,
          reason: 'DE country code flags Unity Day → dearer-holiday nudge');
    });
  });
}

