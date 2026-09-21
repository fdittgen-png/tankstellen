// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/comparison_eligibility.dart';
import 'package:tankstellen/core/domain/fuel/fuel_quantity_unit.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/money.dart';
import 'package:tankstellen/core/domain/money_tally.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/domain/services/vehicle_cost_comparison.dart';
import 'package:tankstellen/features/trips/api.dart';

/// #4364 — the shared comparison-eligibility contract #4365/#4366/#4367
/// consume. Synthetic records throughout: these pin the RULES, not any
/// real car's consumption.
void main() {
  const a = VehicleProfile(id: 'a', name: 'A', tankCapacityL: 50);
  const b = VehicleProfile(id: 'b', name: 'B', tankCapacityL: 50);
  final asOf = DateTime.utc(2026, 9, 20, 12);

  FillUp fill(
    String id,
    String? vehicleId,
    int day,
    double odo, {
    double litres = 40,
    double cost = 60,
    String? currency = 'EUR',
    FuelType fuel = FuelType.e10,
    bool full = true,
  }) =>
      FillUp(
        id: id,
        date: DateTime.utc(2026, 1, day),
        liters: litres,
        totalCost: cost,
        odometerKm: odo,
        fuelType: fuel,
        vehicleId: vehicleId,
        currency: currency,
        isFullTank: full,
      );

  TripHistoryEntry trip(String id, String? vehicleId,
          {double km = 20, bool virtual = false}) =>
      TripHistoryEntry(
        id: id,
        vehicleId: vehicleId,
        summary: TripSummary(
          distanceKm: km,
          maxRpm: 3000,
          highRpmSeconds: 0,
          idleSeconds: 0,
          harshBrakes: 0,
          harshAccelerations: 0,
          fuelLitersConsumed: km * 0.06,
          avgLPer100Km: 6,
          startedAt: DateTime.utc(2026, 1, 5, 8),
          endedAt: DateTime.utc(2026, 1, 5, 8, 30),
          isVirtual: virtual,
        ),
      );

  /// Two vehicles, three EUR fills each, identical distances.
  List<FillUp> twoVehicleHistory({String? currencyB = 'EUR', double costB = 45}) => [
        fill('a1', 'a', 1, 1000),
        fill('a2', 'a', 10, 1500),
        fill('a3', 'a', 20, 2000),
        fill('b1', 'b', 1, 5000, currency: currencyB, cost: costB),
        fill('b2', 'b', 10, 5500, currency: currencyB, cost: costB),
        fill('b3', 'b', 20, 6000, currency: currencyB, cost: costB),
      ];

  VehicleCostComparison compare(
    List<FillUp> fills, {
    List<TripHistoryEntry> trips = const [],
    List<String> ids = const ['a', 'b'],
    MoneyValuationPolicy? valuation,
  }) =>
      buildVehicleCostComparison(
        vehicleIds: ids,
        fillUps: fills,
        trips: trips,
        vehicles: const {'a': a, 'b': b},
        valuation: valuation,
      );

  group('currency segregation and conversion (boxes 1 + 2)', () {
    test('a EUR vehicle and a DKK vehicle get no combined winner', () {
      final c = compare(twoVehicleHistory(currencyB: 'DKK', costB: 337.5));

      expect(c.cheapestPerKm.eligibility, MetricEligibility.unavailable);
      expect(c.cheapestPerKm.reason, ComparisonUnavailableReason.mixedCurrencies);
      expect(c.cheapestPerKm.valueOrNull, isNull);
      // The per-vehicle observations survive the withheld ranking.
      for (final s in c.subjects) {
        expect(s.consumptionL100Km.isComparable, isTrue);
        expect(s.costPerKm.isComparable, isTrue);
      }
    });

    test('a named 7.50 DKK/EUR policy produces a converted winner', () {
      // A: 45.00 EUR over 500 km. B: 337.50 DKK over 500 km = 45.00 EUR.
      // A tie at the true rate; make B cheaper by a third.
      final c = compare(
        twoVehicleHistory(currencyB: 'DKK', costB: 225),
        valuation: MoneyValuationPolicy(
          targetCurrency: 'EUR',
          rates: ExchangeRateSnapshot(rates: [
            ExchangeRate(
              baseCurrency: 'EUR',
              quoteCurrency: 'DKK',
              rate: 7.50,
              source: 'synthetic test rate',
              capturedAt: asOf,
            ),
          ]),
          asOf: asOf,
        ),
      );

      expect(c.cheapestPerKm.valueOrNull, 'b');
      expect(c.cheapestPerKm.qualifications,
          contains(ComparisonQualification.convertedCurrency));
    });

    test('unknown-currency history cannot enter a euro cost/km or winner', () {
      final c = compare(twoVehicleHistory(currencyB: null));

      final subjectB = c.subjects.firstWhere((s) => s.vehicleId == 'b');
      expect(subjectB.recordedSpend.eligibility, MetricEligibility.unavailable);
      expect(subjectB.recordedSpend.reason,
          ComparisonUnavailableReason.unknownCurrency);
      expect(subjectB.recordedSpend.valueOrNull, isNull);
      // The quantities are intact.
      expect(subjectB.spend.byCurrency[kUnknownCurrency], 135);
      expect(subjectB.consumptionL100Km.valueOrNull, isNotNull);
    });

    test('a named-currency subject still reports its Money', () {
      final c = compare(twoVehicleHistory());

      final subjectA = c.subjects.firstWhere((s) => s.vehicleId == 'a');
      expect(subjectA.recordedSpend.valueOrNull, const Money(180, 'EUR'));
    });
  });

  group('strict vehicle attribution (box 3)', () {
    test('an unassigned trip lands in neither vehicle and is counted once',
        () {
      final c = compare(
        twoVehicleHistory(),
        trips: [trip('t1', 'a'), trip('t2', null), trip('t3', 'b')],
      );

      expect(c.unassignedTripCount, 1);
      for (final s in c.subjects) {
        expect(s.coverage.tripCount, 1);
        expect(s.coverage.coveredKm, 20);
      }
    });

    test('assigning the trip refreshes only that vehicle', () {
      final before = compare(
        twoVehicleHistory(),
        trips: [trip('t1', 'a'), trip('t2', null)],
      );
      final after = compare(
        twoVehicleHistory(),
        trips: [trip('t1', 'a'), trip('t2', 'b')],
      );

      final beforeA = before.subjects.firstWhere((s) => s.vehicleId == 'a');
      final afterA = after.subjects.firstWhere((s) => s.vehicleId == 'a');
      final afterB = after.subjects.firstWhere((s) => s.vehicleId == 'b');
      expect(afterA.coverage.tripCount, beforeA.coverage.tripCount);
      expect(afterB.coverage.tripCount, 1);
      expect(after.unassignedTripCount, 0);
    });

    test('an unassigned FILL is excluded from both and reported', () {
      final c = compare([...twoVehicleHistory(), fill('legacy', null, 15, 9000)]);

      expect(c.unassignedFillCount, 1);
      for (final s in c.subjects) {
        expect(s.stats.fillUpCount, 3);
        expect(s.coverage.exclusions[ComparisonExclusion.unassignedVehicle], 1);
      }
    });

    test('one vehicle keeps the #3945 legacy-fill policy', () {
      // Single-vehicle driver: the pre-profile fill IS theirs.
      final c = compare(
        [
          fill('a1', 'a', 1, 1000),
          fill('legacy', null, 10, 1500),
          fill('a3', 'a', 20, 2000),
        ],
        ids: ['a'],
      );

      expect(c.subjects.single.stats.fillUpCount, 3);
    });

    test('overlapping odometers cannot join two vehicles into one window', () {
      // Both cars sit in the same odometer range. Strict attribution
      // means a window never spans them.
      final c = compare([
        fill('a1', 'a', 1, 1000),
        fill('b1', 'b', 2, 1100),
        fill('a2', 'a', 10, 1500),
        fill('b2', 'b', 11, 1600),
      ]);

      final subjectA = c.subjects.firstWhere((s) => s.vehicleId == 'a');
      expect(subjectA.stats.totalDistanceKm, 500);
      expect(subjectA.coverage.windowCount, 1);
    });

    test('a virtual trip is excluded and counted, never averaged', () {
      final c = compare(
        twoVehicleHistory(),
        trips: [trip('t1', 'a'), trip('t2', 'a', virtual: true)],
      );

      final subjectA = c.subjects.firstWhere((s) => s.vehicleId == 'a');
      expect(subjectA.coverage.tripCount, 1);
      expect(subjectA.coverage.exclusions[ComparisonExclusion.virtualRecord], 1);
    });
  });

  group('units (box 5)', () {
    test('a CNG vehicle reports no L/100 km and says why', () {
      final c = compare(
        [
          fill('c1', 'a', 1, 1000, fuel: FuelType.cng, litres: 12, cost: 18),
          fill('c2', 'a', 10, 1400, fuel: FuelType.cng, litres: 12, cost: 18),
        ],
        ids: ['a'],
      );

      final s = c.subjects.single;
      expect(s.quantityUnit, FuelQuantityUnit.kilogram);
      expect(s.consumptionL100Km.eligibility, MetricEligibility.unavailable);
      expect(s.consumptionL100Km.reason,
          ComparisonUnavailableReason.unsupportedUnit);
      expect(s.consumptionL100Km.valueOrNull, isNull);
      // The useful observation survives: native spend is still shown.
      expect(s.recordedSpend.valueOrNull, const Money(36, 'EUR'));
    });

    test('litres and kg in one history are incompatible, not additive', () {
      final c = compare(
        [
          fill('m1', 'a', 1, 1000),
          fill('m2', 'a', 10, 1400, fuel: FuelType.cng, litres: 12, cost: 18),
        ],
        ids: ['a'],
      );

      expect(c.subjects.single.consumptionL100Km.reason,
          ComparisonUnavailableReason.incompatibleUnits);
    });
  });

  group('missing prices (box 6)', () {
    test('an unpriced fill withholds cost/km rather than halving it', () {
      final c = compare(
        [
          fill('a1', 'a', 1, 1000),
          fill('a2', 'a', 10, 1500),
          fill('a3', 'a', 20, 2000, cost: 0),
          ...twoVehicleHistory().where((f) => f.vehicleId == 'b'),
        ],
      );

      final subjectA = c.subjects.firstWhere((s) => s.vehicleId == 'a');
      expect(subjectA.costPerKm.eligibility, MetricEligibility.unavailable);
      expect(subjectA.costPerKm.reason, ComparisonUnavailableReason.missingPrices);
      expect(subjectA.costPerKm.valueOrNull, isNull);
      expect(subjectA.coverage.exclusions[ComparisonExclusion.missingPrice], 1);
      // ...and no winner is crowned from the one vehicle that is left.
      expect(c.cheapestPerKm.eligibility, MetricEligibility.unavailable);
    });
  });

  group('coverage and qualifications (boxes 8 + 9)', () {
    test('every observation is qualified as condition-uncontrolled', () {
      final c = compare(twoVehicleHistory(), trips: [trip('t1', 'a')]);

      final subjectA = c.subjects.firstWhere((s) => s.vehicleId == 'a');
      expect(subjectA.consumptionL100Km.eligibility,
          MetricEligibility.qualified);
      expect(subjectA.consumptionL100Km.qualifications,
          containsAll(<ComparisonQualification>[
            ComparisonQualification.uncontrolledConditions,
            ComparisonQualification.partialConditionCoverage,
          ]));
      expect(subjectA.coverage.conditionCoverage, 0);
    });

    test('the in-progress window is excluded and stated', () {
      final c = compare(
        [
          fill('a1', 'a', 1, 1000),
          fill('a2', 'a', 10, 1500),
          fill('a3', 'a', 20, 1800, full: false),
        ],
        ids: ['a'],
      );

      final s = c.subjects.single;
      expect(s.coverage.exclusions[ComparisonExclusion.openWindow], 1);
      expect(s.consumptionL100Km.qualifications,
          contains(ComparisonQualification.openWindowExcluded));
    });

    test('the covered window and distance travel with the metric', () {
      final c = compare(twoVehicleHistory(), trips: [trip('t1', 'a', km: 33)]);

      final s = c.subjects.firstWhere((v) => v.vehicleId == 'a');
      expect(s.coverage.periodStart, DateTime.utc(2026, 1, 1));
      expect(s.coverage.periodEnd, DateTime.utc(2026, 1, 20));
      expect(s.coverage.windowCount, 2);
      expect(s.coverage.coveredKm, 33);
      expect(s.coverage.coveredTime, const Duration(minutes: 30));
    });

    test('unequal window counts are stated on the winner', () {
      final c = compare([
        fill('a1', 'a', 1, 1000),
        fill('a2', 'a', 5, 1500),
        fill('a3', 'a', 10, 2000),
        fill('a4', 'a', 15, 2500),
        fill('a5', 'a', 20, 3000),
        fill('b1', 'b', 1, 5000, cost: 90),
        fill('b2', 'b', 20, 5500, cost: 90),
      ]);

      expect(c.cheapestPerKm.valueOrNull, 'a');
      expect(c.cheapestPerKm.qualifications,
          contains(ComparisonQualification.unequalSampleSizes));
    });
  });

  group('the builder never touches the active vehicle (box 11)', () {
    test('it takes the compared ids explicitly and reads no Ref', () {
      // Selecting vehicles for a comparison must not switch the car the
      // rest of the app is showing. The contract makes that structural:
      // `buildVehicleCostComparison` is a pure function of the records
      // and an explicit id list — there is no container to read an
      // active-vehicle provider from.
      final c = buildVehicleCostComparison(
        vehicleIds: const ['b'],
        fillUps: twoVehicleHistory(),
        trips: const [],
        vehicles: const {'a': a, 'b': b},
      );

      expect(c.subjects.map((s) => s.vehicleId), ['b']);
    });
  });

  group('observed cost is not intrinsic efficiency', () {
    test('the valuation basis is stated on every subject', () {
      final c = compare(twoVehicleHistory());

      for (final s in c.subjects) {
        expect(s.costValuationBasis,
            MoneyValuationBasis.closingWindowPurchaseCost);
      }
    });
  });

  group('edits invalidate the summary without touching the active vehicle',
      () {
    test('deleting a record changes only that vehicle\'s totals (box 11)', () {
      final full = twoVehicleHistory();
      final before = compare(full);
      final after = compare(full.where((f) => f.id != 'a3').toList());

      final beforeB = before.subjects.firstWhere((s) => s.vehicleId == 'b');
      final afterB = after.subjects.firstWhere((s) => s.vehicleId == 'b');
      final afterA = after.subjects.firstWhere((s) => s.vehicleId == 'a');
      expect(afterB.stats, beforeB.stats, reason: 'B is untouched');
      expect(afterA.stats.fillUpCount, 2);
      expect(afterA.coverage.windowCount, 1);
      // The comparison is a pure function of the records, so a re-read
      // after an edit needs no cache invalidation of its own.
      expect(compare(full).subjects.first.stats, before.subjects.first.stats);
    });

    test('reassigning a fill moves it between vehicles, one way only', () {
      final reassigned = [
        for (final f in twoVehicleHistory())
          if (f.id == 'a3') f.copyWith(vehicleId: 'b') else f,
      ];
      final c = compare(reassigned);

      expect(c.subjects.firstWhere((s) => s.vehicleId == 'a').stats.fillUpCount,
          2);
      expect(c.subjects.firstWhere((s) => s.vehicleId == 'b').stats.fillUpCount,
          4);
    });
  });
}
