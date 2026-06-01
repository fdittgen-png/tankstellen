// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/price_history/domain/services/holiday_premium.dart';

/// Unit tests for the shared [HolidayPremium] maths (#2570).
///
/// This helper is the single source of truth for the holiday-vs-non-
/// holiday EUR/L premium consumed by both `pricePredictionProvider`
/// (text hint) and `FillUpGuidancePredictor` (verdict nudge), so its
/// thresholds and rounding are locked down here.
void main() {
  group('compute', () {
    test('returns null below the minimum holiday-sample count', () {
      // Two holiday readings is one short of the 3-sample floor.
      final premium = HolidayPremium.compute(
        holidayPrices: const [1.80, 1.82],
        nonHolidayPrices: const [1.60, 1.61, 1.62],
      );
      expect(premium, isNull);
    });

    test('returns null when there is no non-holiday baseline', () {
      final premium = HolidayPremium.compute(
        holidayPrices: const [1.80, 1.81, 1.82],
        nonHolidayPrices: const [],
      );
      expect(premium, isNull);
    });

    test('positive premium when holidays run dearer, rounded to 3 dp', () {
      // Holiday avg 1.80, non-holiday avg 1.60 → +0.20 EUR/L.
      final premium = HolidayPremium.compute(
        holidayPrices: const [1.80, 1.80, 1.80],
        nonHolidayPrices: const [1.60, 1.60, 1.60],
      );
      expect(premium, closeTo(0.20, 1e-9));
    });

    test('negative premium when holidays run cheaper', () {
      final premium = HolidayPremium.compute(
        holidayPrices: const [1.40, 1.41, 1.42],
        nonHolidayPrices: const [1.60, 1.62, 1.64],
      );
      expect(premium, isNotNull);
      expect(premium, lessThan(0));
    });

    test('rounds the delta to 3 decimals (0.1 ct/L granularity)', () {
      // Raw delta 0.0123… → rounded to 0.012.
      final premium = HolidayPremium.compute(
        holidayPrices: const [1.6123, 1.6123, 1.6123],
        nonHolidayPrices: const [1.6000],
      );
      expect(premium, 0.012);
    });

    test('exactly at the minimum sample count is computed', () {
      final premium = HolidayPremium.compute(
        holidayPrices: const [1.80, 1.81, 1.82],
        nonHolidayPrices: const [1.60],
      );
      expect(premium, isNotNull);
    });
  });

  group('isActionable', () {
    test('null premium is never actionable', () {
      expect(HolidayPremium.isActionable(null), isFalse);
    });

    test('premium exactly at the threshold is NOT actionable', () {
      // Mirrors the legacy provider's `<=` boundary: 2 ct/L exactly is
      // below the bar and must not append a hint / fire a nudge.
      expect(
        HolidayPremium.isActionable(HolidayPremium.noticeThresholdEur),
        isFalse,
      );
    });

    test('premium just above the threshold is actionable (either sign)', () {
      expect(
        HolidayPremium.isActionable(HolidayPremium.noticeThresholdEur + 0.001),
        isTrue,
      );
      expect(
        HolidayPremium.isActionable(-(HolidayPremium.noticeThresholdEur + 0.001)),
        isTrue,
      );
    });

    test('sub-threshold premium is not actionable', () {
      expect(HolidayPremium.isActionable(0.005), isFalse);
    });
  });
}
