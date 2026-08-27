// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3828 — the fuel comparison showed two rows of numbers and left every
// decision to the reader. The numbers below are the ones from the field
// screenshot that motivated the issue:
//
//   E5   cost/km 0.057   L/100km 6.4   total 32.12   1 full tank
//   E85  cost/km 0.070   L/100km 5.5   total 130.09  3 full tanks
//
// Note E85 burns FEWER litres per 100 km and still costs MORE per km. That
// looks like a contradiction until the pump price is on screen, which is
// exactly what was missing.

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/services/co2_calculator.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fuel_type_efficiency_stats.dart';

FuelTypeEfficiencyStats _stats({
  required FuelType fuel,
  required double litres,
  required double distanceKm,
  required double cost,
  int intervals = 2,
}) =>
    FuelTypeEfficiencyStats(
      bucket: FuelEfficiencyBucket(dominant: fuel),
      avgL100km: distanceKm > 0 ? (litres / distanceKm) * 100 : null,
      avgCostPerKm: distanceKm > 0 ? cost / distanceKm : null,
      totalSpent: cost,
      fillCount: intervals,
      attributedIntervalCount: intervals,
      totalLitres: litres,
      totalDistanceKm: distanceKm,
      intervalCost: cost,
    );

void main() {
  group('#3828 metrics the aggregator already had but discarded', () {
    test('price per litre is derived from litres and interval cost', () {
      // 40 L for 64.00 => 1.60 / L.
      final s = _stats(
          fuel: FuelType.e10, litres: 40, distanceKm: 625, cost: 64);
      expect(s.avgPricePerLitre, closeTo(1.60, 1e-9));
    });

    test('price per litre uses intervalCost, NOT totalSpent', () {
      // totalSpent counts every non-correction fill; intervalCost counts only
      // the closed intervals the averages come from. Mixing them would give a
      // per-litre price that contradicts the per-km cost on the same row.
      const s = FuelTypeEfficiencyStats(
        bucket: FuelEfficiencyBucket(dominant: FuelType.e85),
        totalSpent: 130.09, // includes fills outside the closed intervals
        fillCount: 3,
        attributedIntervalCount: 2,
        totalLitres: 50,
        intervalCost: 75,
        totalDistanceKm: 800,
        avgL100km: 6.25,
        avgCostPerKm: 75 / 800,
      );
      expect(s.avgPricePerLitre, closeTo(1.50, 1e-9));
    });

    test('cost per 100 km and per 1000 km restate cost per km', () {
      final s = _stats(
          fuel: FuelType.e10, litres: 40, distanceKm: 1000, cost: 57);
      expect(s.avgCostPerKm, closeTo(0.057, 1e-9));
      expect(s.avgCostPer100km, closeTo(5.7, 1e-9));
      expect(s.costPer1000km, closeTo(57.0, 1e-9));
    });

    test('derived metrics are null rather than guessed when unmeasured', () {
      const empty = FuelTypeEfficiencyStats(
        bucket: FuelEfficiencyBucket(dominant: FuelType.diesel),
        totalSpent: 0,
        fillCount: 0,
        attributedIntervalCount: 0,
      );
      expect(empty.avgPricePerLitre, isNull);
      expect(empty.avgCostPer100km, isNull);
      expect(empty.costPer1000km, isNull);
    });

    test('one closed interval is a data point, two is a verdict', () {
      expect(_stats(
              fuel: FuelType.e85,
              litres: 40,
              distanceKm: 600,
              cost: 60,
              intervals: 1)
          .isConfident, isFalse);
      expect(_stats(
              fuel: FuelType.e85,
              litres: 40,
              distanceKm: 600,
              cost: 60,
              intervals: 2)
          .isConfident, isTrue);
    });
  });

  group('#3828 break-even pump price', () {
    // The field case: E85 burns less per 100 km but costs more per km.
    final e5 = _stats(
        fuel: FuelType.e5, litres: 64, distanceKm: 1000, cost: 57); // 6.4 L
    final e85 = _stats(
        fuel: FuelType.e85, litres: 55, distanceKm: 1000, cost: 70); // 5.5 L

    test('E85 must drop below this per-litre price to beat E5', () {
      // costPerKm = (L100 / 100) * price  =>  price = 0.057 * 100 / 5.5
      final be = e85.breakEvenPricePerLitreVersus(e5);
      expect(be, isNotNull);
      expect(be, closeTo(0.057 * 100 / 5.5, 1e-9));
    });

    test('at the break-even price the two really do cost the same per km', () {
      // The number is worthless if it does not actually equalise, so verify
      // the algebra rather than trusting the formula.
      final be = e85.breakEvenPricePerLitreVersus(e5)!;
      final e85CostPerKmAtBreakEven = (e85.avgL100km! / 100) * be;
      expect(e85CostPerKmAtBreakEven, closeTo(e5.avgCostPerKm!, 1e-9));
    });

    test('null when either side has no measured consumption', () {
      const noData = FuelTypeEfficiencyStats(
        bucket: FuelEfficiencyBucket(dominant: FuelType.lpg),
        totalSpent: 0,
        fillCount: 0,
        attributedIntervalCount: 0,
      );
      expect(noData.breakEvenPricePerLitreVersus(e5), isNull);
      expect(e85.breakEvenPricePerLitreVersus(noData), isNull);
    });
  });

  group('#3828 the emissions axis', () {
    // Real WTW factors from Co2Calculator: E85 1.40 kg/L, E5 2.31 kg/L.
    // This is the case the cost-only comparison could not express — E85 is
    // dearer per km here and still much cleaner.
    final e5 = _stats(
        fuel: FuelType.e5, litres: 64, distanceKm: 1000, cost: 57); // 6.4 L
    final e85 = _stats(
        fuel: FuelType.e85, litres: 55, distanceKm: 1000, cost: 70); // 5.5 L

    test('CO2 per km follows measured consumption, not litres alone', () {
      // 6.4 L/100km * 2.31 kg/L / 100 = 0.14784 kg/km
      expect(e5.co2PerKmWith(2.31), closeTo(0.14784, 1e-9));
      // 5.5 L/100km * 1.40 kg/L / 100 = 0.077 kg/km
      expect(e85.co2PerKmWith(1.40), closeTo(0.077, 1e-9));
    });

    test('the cheaper fuel per km is NOT the cleaner one here', () {
      // The entire reason this axis had to be added.
      expect(e5.avgCostPerKm! < e85.avgCostPerKm!, isTrue,
          reason: 'E5 is cheaper to drive');
      expect(e85.co2PerKmWith(1.40)! < e5.co2PerKmWith(2.31)!, isTrue,
          reason: 'yet E85 emits far less — a cost-only screen cannot say so');
    });

    test('per 1000 km restates per km, matching the cost delta unit', () {
      expect(e85.co2Per1000kmWith(1.40),
          closeTo(e85.co2PerKmWith(1.40)! * 1000, 1e-9));
    });

    test('no factor or no measured consumption yields null, never a guess',
        () {
      expect(e85.co2PerKmWith(null), isNull);
      const noConsumption = FuelTypeEfficiencyStats(
        bucket: FuelEfficiencyBucket(dominant: FuelType.e85),
        totalSpent: 0,
        fillCount: 0,
        attributedIntervalCount: 0,
      );
      expect(noConsumption.co2PerKmWith(1.40), isNull);
      expect(noConsumption.co2Per1000kmWith(1.40), isNull);
    });

    test('Co2Calculator has a factor for the pure fuels we compare', () {
      // The widget omits CO2 for blends deliberately; pure buckets must
      // resolve, or the axis silently disappears.
      for (final f in [FuelType.e5, FuelType.e10, FuelType.e85,
                       FuelType.diesel, FuelType.lpg]) {
        expect(Co2Calculator.emissionFactorFor(f), isNotNull,
            reason: 'no WTW factor for $f');
      }
      expect(Co2Calculator.emissionFactorFor(FuelType.e85)!
          < Co2Calculator.emissionFactorFor(FuelType.e5)!, isTrue);
    });
  });
}
