// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/domain/services/fill_anchored_consumption.dart';

/// Pure unit tests for [fillAnchoredAvgLPer100Km] (#3645).
///
/// The service derives the vehicle's TRUE consumption from the only
/// physical measurement the user hands us at every refuel: pumped
/// litres ÷ odometer delta between consecutive FULL fills. Synthetic
/// fixtures only, mirroring the tank_level_estimator_test idiom.
void main() {
  var idCounter = 0;

  FillUp fill({
    required DateTime date,
    required double liters,
    required double odometerKm,
    bool isFullTank = true,
    bool isCorrection = false,
  }) {
    return FillUp(
      id: 'f${idCounter++}',
      date: date,
      liters: liters,
      totalCost: liters * 1.8,
      odometerKm: odometerKm,
      fuelType: FuelType.diesel,
      vehicleId: 'v1',
      isFullTank: isFullTank,
      isCorrection: isCorrection,
    );
  }

  group('fillAnchoredAvgLPer100Km — window math', () {
    test('two full fills form one window: liters of the CLOSING plein '
        'over the odometer delta', () {
      // Full at 100000, drive 500 km, refill 30 L to full:
      // 30 L / 500 km = 6.0 L/100 km — the physically true figure.
      final result = fillAnchoredAvgLPer100Km([
        fill(date: DateTime(2026, 4, 1), liters: 45, odometerKm: 100000),
        fill(date: DateTime(2026, 4, 10), liters: 30, odometerKm: 100500),
      ]);

      expect(result, isNotNull);
      expect(result!.avgLPer100Km, closeTo(6.0, 0.001));
      expect(result.windows, 1);
      expect(result.totalKm, closeTo(500, 0.001));
      expect(result.totalLiters, closeTo(30, 0.001));
    });

    test('a partial fill INSIDE the window adds its litres — the closing '
        'plein only refills what is still missing', () {
      // Full → 10 L partial → full 25 L over 500 km: consumed = 35 L.
      final result = fillAnchoredAvgLPer100Km([
        fill(date: DateTime(2026, 4, 1), liters: 45, odometerKm: 100000),
        fill(
          date: DateTime(2026, 4, 5),
          liters: 10,
          odometerKm: 100200,
          isFullTank: false,
        ),
        fill(date: DateTime(2026, 4, 10), liters: 25, odometerKm: 100500),
      ]);

      expect(result!.avgLPer100Km, closeTo(7.0, 0.001));
      expect(result.windows, 1);
    });

    test('correction entries (#1361) are synthetic, not pumped fuel — '
        'excluded from the window litres', () {
      final result = fillAnchoredAvgLPer100Km([
        fill(date: DateTime(2026, 4, 1), liters: 45, odometerKm: 100000),
        fill(
          date: DateTime(2026, 4, 5),
          liters: 8,
          odometerKm: 100200,
          isFullTank: false,
          isCorrection: true,
        ),
        fill(date: DateTime(2026, 4, 10), liters: 30, odometerKm: 100500),
      ]);

      // 30 L / 500 km — the 8 L correction must NOT inflate the window.
      expect(result!.avgLPer100Km, closeTo(6.0, 0.001));
    });

    test('multiple windows: km-weighted average, not a mean of ratios', () {
      // Window 1: 30 L / 500 km (6.0). Window 2: 45 L / 500 km (9.0).
      // km-weighted: 75 L / 1000 km = 7.5.
      final result = fillAnchoredAvgLPer100Km([
        fill(date: DateTime(2026, 4, 1), liters: 45, odometerKm: 100000),
        fill(date: DateTime(2026, 4, 10), liters: 30, odometerKm: 100500),
        fill(date: DateTime(2026, 4, 20), liters: 45, odometerKm: 101000),
      ]);

      expect(result!.avgLPer100Km, closeTo(7.5, 0.001));
      expect(result.windows, 2);
      expect(result.totalKm, closeTo(1000, 0.001));
    });

    test('input order does not matter — windows derive from dates', () {
      final a = fill(date: DateTime(2026, 4, 1), liters: 45, odometerKm: 100000);
      final b = fill(date: DateTime(2026, 4, 10), liters: 30, odometerKm: 100500);

      expect(
        fillAnchoredAvgLPer100Km([b, a])!.avgLPer100Km,
        closeTo(6.0, 0.001),
      );
    });
  });

  group('fillAnchoredAvgLPer100Km — guards (honest numbers only)', () {
    test('fewer than two full fills → null (no window exists)', () {
      expect(fillAnchoredAvgLPer100Km(const []), isNull);
      expect(
        fillAnchoredAvgLPer100Km([
          fill(date: DateTime(2026, 4, 1), liters: 45, odometerKm: 100000),
        ]),
        isNull,
      );
      expect(
        fillAnchoredAvgLPer100Km([
          fill(date: DateTime(2026, 4, 1), liters: 45, odometerKm: 100000),
          fill(
            date: DateTime(2026, 4, 5),
            liters: 10,
            odometerKm: 100200,
            isFullTank: false,
          ),
        ]),
        isNull,
      );
    });

    test('zero or negative odometer delta → window skipped (typo, reset, '
        'or an unset default like the estimator-test fixtures)', () {
      // Same odometer on both fulls — exactly the shape older fixtures
      // and quick manual logs produce. Must not fabricate a number.
      expect(
        fillAnchoredAvgLPer100Km([
          fill(date: DateTime(2026, 4, 1), liters: 45, odometerKm: 100000),
          fill(date: DateTime(2026, 4, 10), liters: 30, odometerKm: 100000),
        ]),
        isNull,
      );
      expect(
        fillAnchoredAvgLPer100Km([
          fill(date: DateTime(2026, 4, 1), liters: 45, odometerKm: 100500),
          fill(date: DateTime(2026, 4, 10), liters: 30, odometerKm: 100000),
        ]),
        isNull,
      );
    });

    test('missing odometer (0 or negative reading) skips the window', () {
      expect(
        fillAnchoredAvgLPer100Km([
          fill(date: DateTime(2026, 4, 1), liters: 45, odometerKm: 0),
          fill(date: DateTime(2026, 4, 10), liters: 30, odometerKm: 100500),
        ]),
        isNull,
      );
    });

    test('implausible per-window consumption is skipped, not averaged in', () {
      // 40 L over 50 km = 80 L/100 km — an odometer typo, not a reading.
      // The plausible window must survive alone.
      final result = fillAnchoredAvgLPer100Km([
        fill(date: DateTime(2026, 4, 1), liters: 45, odometerKm: 100000),
        fill(date: DateTime(2026, 4, 3), liters: 40, odometerKm: 100050),
        fill(date: DateTime(2026, 4, 10), liters: 30, odometerKm: 100550),
      ]);

      expect(result, isNotNull);
      expect(result!.windows, 1);
      expect(result.avgLPer100Km, closeTo(6.0, 0.001));
    });

    test('all windows implausible → null, never a fabricated figure', () {
      expect(
        fillAnchoredAvgLPer100Km([
          fill(date: DateTime(2026, 4, 1), liters: 45, odometerKm: 100000),
          fill(date: DateTime(2026, 4, 3), liters: 40, odometerKm: 100050),
        ]),
        isNull,
      );
    });

    test('only the most recent maxWindows windows count — the average '
        'tracks the CURRENT car, not its whole life', () {
      // Ten old 9.0-windows, then two recent 6.0-windows. maxWindows: 2
      // must yield 6.0, not a lifetime blend.
      final fills = <FillUp>[
        for (var i = 0; i <= 9; i++)
          fill(
            date: DateTime(2026, 1, 1 + i),
            liters: 45,
            odometerKm: 100000 + i * 500,
          ),
        fill(date: DateTime(2026, 4, 10), liters: 30, odometerKm: 105000),
        fill(date: DateTime(2026, 4, 20), liters: 30, odometerKm: 105500),
      ];

      final result = fillAnchoredAvgLPer100Km(fills, maxWindows: 2);
      expect(result!.windows, 2);
      expect(result.avgLPer100Km, closeTo(6.0, 0.001));
    });
  });
}
