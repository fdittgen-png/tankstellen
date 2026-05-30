// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/price_history/data/models/price_record.dart';
import 'package:tankstellen/features/price_history/domain/entities/fill_up_guidance.dart';
import 'package:tankstellen/features/price_history/domain/services/fill_up_guidance_predictor.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

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
}

