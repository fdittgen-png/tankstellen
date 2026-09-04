// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fuel_consumption_figure.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fuel_type_efficiency_stats.dart';
import 'package:tankstellen/features/fill_ups/domain/fuel_energy_content.dart';
import 'package:tankstellen/features/fill_ups/domain/services/fuel_consumption_estimator.dart';
import 'package:tankstellen/features/fill_ups/domain/services/fuel_type_efficiency_aggregator.dart';

/// #3945 — the labelled estimate that fills the all-prices cell of a fuel
/// which has no PURE window (ADR 0015 amendment).
///
/// The fixtures drive the REAL ADR 0015 aggregator (not hand-built stats)
/// wherever a bucketing question is involved, so the estimate is tested on
/// the very buckets the table will get.

FillUp _f({
  required String id,
  required int day,
  required double liters,
  required double odo,
  required FuelType fuelType,
  bool isFullTank = true,
}) => FillUp(
  id: id,
  date: DateTime.utc(2026, 1, day),
  liters: liters,
  totalCost: liters * 1.8,
  odometerKm: odo,
  fuelType: fuelType,
  isFullTank: isFullTank,
  vehicleId: 'v1',
);

/// The #3933 fixture: E85 40 L → E85 30 L → E10 35 L → E10 23 L, 500 km
/// apart, on a 50 L tank. Under ADR 0015 v3 E85 is measured at 6,5 and the
/// last window is an E10/E85 MIX — so E10 has no pure window at all.
final _fixture3933 = <FillUp>[
  _f(id: '1', day: 1, liters: 40, odo: 1000, fuelType: FuelType.e85),
  _f(id: '2', day: 5, liters: 30, odo: 1500, fuelType: FuelType.e85),
  _f(id: '3', day: 9, liters: 35, odo: 2000, fuelType: FuelType.e10),
  _f(id: '4', day: 14, liters: 23, odo: 2500, fuelType: FuelType.e10),
];

FuelTypeEfficiencyStats _pure(
  FuelType fuel,
  double l100, {
  int intervals = 2,
  double litres = 60,
}) => FuelTypeEfficiencyStats(
  bucket: FuelEfficiencyBucket(dominant: fuel),
  avgL100km: l100,
  avgCostPerKm: 0.1,
  totalSpent: 100,
  fillCount: intervals,
  attributedIntervalCount: intervals,
  totalLitres: litres,
  totalDistanceKm: litres / l100 * 100,
);

void main() {
  const flexFuels = {FuelType.e5, FuelType.e10, FuelType.e98, FuelType.e85};

  group('FuelConsumptionEstimator — the #3933 fixture', () {
    late Map<FuelType, FuelConsumptionFigure> byFuel;

    setUp(() {
      final stats = FuelTypeEfficiencyAggregator.byFuelType(
        _fixture3933,
        tankCapacityL: 50,
      );
      byFuel = FuelConsumptionEstimator.byFuel(
        stats: stats,
        candidateFuels: flexFuels,
      );
    });

    test('E85 stays MEASURED at 6,5 — the pure windows are untouched', () {
      final e85 = byFuel[FuelType.e85]!;
      expect(e85.isMeasured, isTrue);
      expect(e85.litersPer100km, closeTo(6.5, 1e-9));
    });

    test('E10 now gets an ESTIMATED figure from E85 by energy content', () {
      final e10 = byFuel[FuelType.e10]!;
      expect(e10.isEstimated, isTrue);
      // 6,5 L/100 km of E85 × (25,6 / 31,9) ≈ 5,22 L/100 km of petrol.
      expect(
        e10.litersPer100km,
        closeTo(
          6.5 * FuelEnergyContent.e85MjPerL / FuelEnergyContent.petrolMjPerL,
          1e-9,
        ),
      );
      expect(e10.litersPer100km, closeTo(5.216, 1e-3));
    });

    test('the estimate is NOT the mix window credited to E10', () {
      // The E10/E85 mix window burned 23 L over 500 km = 4,6 — the ADR 0014
      // collapse would have handed E10 that number. It must not appear.
      expect(byFuel[FuelType.e10]!.litersPer100km, isNot(closeTo(4.6, 1e-3)));
    });

    test('every other usable grade of the family is estimated too', () {
      for (final f in [FuelType.e5, FuelType.e98]) {
        expect(byFuel[f]?.isEstimated, isTrue, reason: f.apiValue);
        expect(
          byFuel[f]!.litersPer100km,
          closeTo(byFuel[FuelType.e10]!.litersPer100km, 1e-12),
          reason: 'same petrol energy content as E10',
        );
      }
    });

    test('a fuel outside the candidate set gets nothing', () {
      expect(byFuel.containsKey(FuelType.diesel), isFalse);
      expect(byFuel.containsKey(FuelType.lpg), isFalse);
    });
  });

  group('FuelConsumptionEstimator — no baseline, no figure', () {
    test('a vehicle with NO measured window anywhere gets no figure', () {
      // One fill = no closed window; every bucket list is empty.
      final stats = FuelTypeEfficiencyAggregator.byFuelType([
        _f(id: '1', day: 1, liters: 40, odo: 1000, fuelType: FuelType.e10),
      ]);
      final byFuel = FuelConsumptionEstimator.byFuel(
        stats: stats,
        candidateFuels: flexFuels,
      );
      expect(byFuel, isEmpty);
    });

    test('only MIX windows and no fallback — still no figure', () {
      // 50 L of E10 carried in + 20 L of E85 splashed = a ~71/29 mix; then
      // the same again. Every window is a blend, nothing pure to anchor on.
      final stats = FuelTypeEfficiencyAggregator.byFuelType([
        _f(id: '1', day: 1, liters: 40, odo: 1000, fuelType: FuelType.e10),
        _f(id: '2', day: 5, liters: 20, odo: 1300, fuelType: FuelType.e85,
            isFullTank: false),
        _f(id: '3', day: 9, liters: 20, odo: 1500, fuelType: FuelType.e85),
      ], tankCapacityL: 50);
      expect(stats.every((s) => s.isMix), isTrue, reason: 'fixture sanity');

      final byFuel = FuelConsumptionEstimator.byFuel(
        stats: stats,
        candidateFuels: flexFuels,
      );
      expect(byFuel, isEmpty);
    });

    test('an empty stats list yields an empty model', () {
      expect(
        FuelConsumptionEstimator.byFuel(
          stats: const [],
          candidateFuels: flexFuels,
        ),
        isEmpty,
      );
    });
  });

  group('FuelConsumptionEstimator — the fallback baseline', () {
    test('every window a blend: the all-fuel average anchors the estimate', () {
      final byFuel = FuelConsumptionEstimator.byFuel(
        stats: const [],
        candidateFuels: flexFuels,
        fallbackBaseline: const ConsumptionBaseline(
          litersPer100km: 7.0,
          fuel: FuelType.e85,
        ),
      );
      expect(byFuel[FuelType.e85], const FuelConsumptionFigure.estimated(7.0));
      expect(byFuel[FuelType.e10]!.isEstimated, isTrue);
      expect(
        byFuel[FuelType.e10]!.litersPer100km,
        closeTo(7.0 * 25.6 / 31.9, 1e-9),
      );
    });

    test('a measured pure window beats the fallback baseline', () {
      final byFuel = FuelConsumptionEstimator.byFuel(
        stats: [_pure(FuelType.e10, 5.0)],
        candidateFuels: flexFuels,
        fallbackBaseline: const ConsumptionBaseline(
          litersPer100km: 9.0,
          fuel: FuelType.e85,
        ),
      );
      // E85 derives from the MEASURED E10 figure, not the 9,0 fallback.
      expect(byFuel[FuelType.e85]!.litersPer100km, closeTo(5.0 * 31.9 / 25.6, 1e-9));
    });

    test('a non-positive fallback is no baseline', () {
      final byFuel = FuelConsumptionEstimator.byFuel(
        stats: const [],
        candidateFuels: flexFuels,
        fallbackBaseline: const ConsumptionBaseline(
          litersPer100km: 0,
          fuel: FuelType.e10,
        ),
      );
      expect(byFuel, isEmpty);
    });
  });

  group('FuelConsumptionEstimator — choosing the baseline', () {
    test('the most-confident pure bucket anchors the estimate', () {
      final byFuel = FuelConsumptionEstimator.byFuel(
        stats: [
          _pure(FuelType.e10, 5.0, intervals: 1, litres: 30),
          _pure(FuelType.e85, 8.0, intervals: 3, litres: 90),
        ],
        candidateFuels: {...flexFuels, FuelType.lpg},
      );
      // LPG has no pure window; it derives from E85 (3 intervals), not E10.
      expect(
        byFuel[FuelType.lpg]!.litersPer100km,
        closeTo(8.0 * 25.6 / 26.0, 1e-9),
      );
    });

    test('a measured fuel is never overwritten by an estimate', () {
      final byFuel = FuelConsumptionEstimator.byFuel(
        stats: [_pure(FuelType.e10, 5.0), _pure(FuelType.e85, 8.0)],
        candidateFuels: flexFuels,
      );
      expect(byFuel[FuelType.e10], const FuelConsumptionFigure.measured(5.0));
      expect(byFuel[FuelType.e85], const FuelConsumptionFigure.measured(8.0));
    });

    test('a fuel without a volumetric energy content is never estimated', () {
      final byFuel = FuelConsumptionEstimator.byFuel(
        stats: [_pure(FuelType.e10, 5.0)],
        candidateFuels: {FuelType.e10, FuelType.cng},
      );
      expect(byFuel.containsKey(FuelType.cng), isFalse);
    });

    test('a mix bucket alone is no baseline (the ADR 0014 collapse)', () {
      const mix = FuelTypeEfficiencyStats(
        bucket: FuelEfficiencyBucket(
          dominant: FuelType.e85,
          secondary: FuelType.e10,
        ),
        avgL100km: 7.0,
        avgCostPerKm: 0.1,
        totalSpent: 100,
        fillCount: 4,
        attributedIntervalCount: 4,
      );
      final byFuel = FuelConsumptionEstimator.byFuel(
        stats: [mix],
        candidateFuels: flexFuels,
      );
      expect(byFuel, isEmpty);
    });
  });
}
