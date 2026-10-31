// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/consumption_stats.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/domain/services/fill_anchored_consumption.dart';
import 'package:tankstellen/features/fill_ups/domain/services/tank_report.dart';
import 'package:tankstellen/features/fill_ups/domain/services/physical_tank_windows.dart';
import 'package:tankstellen/features/fill_ups/domain/services/eco_score_calculator.dart';
import 'package:tankstellen/features/fill_ups/domain/services/fuel_type_efficiency_aggregator.dart';

import '../../fixtures/physical_tank_fixtures.dart';

void main() {
  final consumers = <String, double? Function(List<FillUp>)>{
    'fill history consumption': (fills) =>
        EcoScoreCalculator.computeLitersPer100Km(
          current: fills.reduce((a, b) => a.date.isAfter(b.date) ? a : b),
          history: fills,
        ),
    'fuel efficiency': (fills) {
      final buckets = FuelTypeEfficiencyAggregator.byFuelType(fills);
      final km = buckets.fold(0.0, (sum, b) => sum + b.totalDistanceKm);
      return km > 0
          ? buckets.fold(
                  0.0,
                  (sum, b) => sum + (b.avgL100km ?? 0) * b.totalDistanceKm,
                ) /
                km
          : null;
    },
    'tank report': (fills) => buildTankReport(
      fillUps: fills,
      tripSummariesById: const {},
    ).latest?.lPer100Km,
    'fill anchored reference': (fills) =>
        fillAnchoredAvgLPer100Km(fills)?.avgLPer100Km,
    'consumption statistics': (fills) =>
        ConsumptionStats.fromFillUps(fills).avgConsumptionL100km,
  };
  for (final consumer in consumers.entries) {
    group(consumer.key, () {
      test('a first partial cannot establish pump truth', () {
        expect(
          consumer.value([
            physicalFill('a', 1, 15, 10000, full: false),
            physicalFill('b', 8, 27.2, 10597),
          ]),
          isNull,
        );
      });
      for (final invalid in [0.0, -1.0, double.nan, double.infinity]) {
        test('unusable odometer $invalid is never a measurement', () {
          expect(
            consumer.value([
              physicalFill('a', 1, 40, invalid),
              physicalFill('b', 8, 27.2, 10597),
            ]),
            isNull,
          );
        });
        test('unusable quantity $invalid is never a measurement', () {
          expect(
            consumer.value([
              physicalFill('a', 1, 40, 10000),
              physicalFill('p', 3, invalid, 10250, full: false),
              physicalFill('b', 8, 27.2, 10597),
            ]),
            isNull,
          );
        });
      }
      test('identical imports count once regardless of input order', () {
        final opening = physicalFill('a', 1, 40, 10000);
        final partial = physicalFill('p', 3, 15, 10250, full: false);
        final closing = physicalFill('b', 8, 27.2, 10597);
        expect(
          consumer.value([closing, partial, opening, partial]),
          closeTo(7.0686767169, 1e-9),
        );
      });
      test('conflicting duplicate and simultaneous fills are unqualified', () {
        final opening = physicalFill('a', 1, 40, 10000);
        final closing = physicalFill('b', 8, 27.2, 10597);
        expect(
          consumer.value([opening, closing, closing.copyWith(liters: 28)]),
          isNull,
        );
        expect(
          consumer.value([opening, closing.copyWith(date: opening.date)]),
          isNull,
        );
        expect(
          consumer.value([
            opening,
            closing,
            physicalFill('z-partial', 8, 15, 10300, full: false),
          ]),
          isNull,
          reason: 'ID order cannot hide a same-time partial after the close',
        );
      });
      test('independent tank and vehicle identities cannot be combined', () {
        final opening = physicalFill('a', 1, 40, 10000);
        final closing = physicalFill('b', 8, 27.2, 10597);
        expect(
          consumer.value([opening, closing.copyWith(fuelType: FuelType.lpg)]),
          isNull,
        );
        expect(
          consumer.value([opening, closing.copyWith(vehicleId: 'another-car')]),
          isNull,
        );
      });
      test('UTC and local representations cannot hide a same-time partial', () {
        final opening = physicalFill('a', 1, 40, 10000);
        final closing = physicalFill('b', 8, 27.2, 10597);
        final partial = physicalFill(
          'z-partial',
          8,
          15,
          10300,
          full: false,
        ).copyWith(date: closing.date.toLocal());
        expect(closing.date.isUtc, isTrue);
        expect(partial.date.isUtc, isFalse);
        expect(closing.date.isAtSameMomentAs(partial.date), isTrue);
        // Keep closing last in the supplied list so the history consumer
        // explicitly reads it; production sorts the partial AFTER its ID.
        expect(consumer.value([opening, partial, closing]), isNull);
      });
      test('a petrol blend remains valid aggregate pump consumption', () {
        expect(
          consumer.value([
            physicalFill('a', 1, 40, 10000),
            physicalFill('p', 3, 15, 10250, full: false, fuel: FuelType.e85),
            physicalFill('b', 8, 27.2, 10597),
          ]),
          closeTo(7.0686767169, 1e-9),
        );
      });
      for (final syntheticFull in [false, true]) {
        test('42.2 L over 597 km ignores synthetic full=$syntheticFull', () {
          final fills = [
            physicalFill('a', 1, 40, 10000),
            physicalFill('p', 3, 15, 10250, full: false),
            physicalFill(
              'synthetic',
              4,
              6,
              10300,
              full: syntheticFull,
              correction: true,
            ),
            physicalFill('b', 8, 27.2, 10597),
          ];
          expect(consumer.value(fills), closeTo(7.0686767169, 1e-9));
          expect(
            fills[2].liters,
            6,
            reason: 'bookkeeping records are retained without mutation',
          );
        });
      }
    });
  }
  test('unequal windows are weighted by physical kilometres', () {
    final fills = [
      physicalFill('a', 1, 40, 10000),
      physicalFill('b', 4, 20, 10200),
      physicalFill('c', 8, 30, 10800),
    ];
    expect(fillAnchoredAvgLPer100Km(fills)!.avgLPer100Km, 6.25);
    expect(ConsumptionStats.fromFillUps(fills).avgConsumptionL100km, 6.25);
    expect(closedTankPeriods(fills).map((p) => p.lPer100Km), [10, 5]);
    expect(fillAnchoredAvgLPer100Km(fills, maxWindows: 0), isNull);
  });
  test('rejections state why an interval is not qualified', () {
    final opening = physicalFill('a', 1, 40, 10000);
    final closing = physicalFill('b', 8, 27.2, 10597);
    expect(
      physicalTankWindows([
        opening.copyWith(isFullTank: false),
        closing,
      ]).rejections,
      contains(PhysicalWindowRejection.missingFullAnchor),
    );
    expect(
      physicalTankWindows([
        opening.copyWith(odometerKm: 0),
        closing.copyWith(odometerKm: 500),
      ]).rejections,
      contains(PhysicalWindowRejection.invalidOdometer),
      reason: 'the shipped form and reference treat zero as an unset reading',
    );
    expect(
      physicalTankWindows([
        opening.copyWith(odometerKm: -1),
        closing,
      ]).rejections,
      contains(PhysicalWindowRejection.invalidOdometer),
    );
    expect(
      physicalTankWindows([
        opening,
        closing.copyWith(liters: double.nan),
      ]).rejections,
      contains(PhysicalWindowRejection.invalidQuantity),
    );
  });
}
