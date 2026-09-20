// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/comparison_eligibility.dart';
import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/core/domain/fuel/fuel_behaviour_evidence.dart';
import 'package:tankstellen/core/domain/fuel/fuel_quantity_unit.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/money.dart';
import 'package:tankstellen/core/domain/money_tally.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/domain/services/vehicle_history_comparison.dart';
import 'package:tankstellen/features/fill_ups/domain/services/vehicle_history_comparison_builder.dart';
import 'package:tankstellen/features/trips/api.dart';

/// #4365 — the period-scoped, multi-vehicle historical comparison.
/// Synthetic records throughout: these pin the RULES, never any real
/// car's consumption.
void main() {
  const a = VehicleProfile(id: 'a', name: 'A', tankCapacityL: 50);
  const b = VehicleProfile(id: 'b', name: 'B', tankCapacityL: 50);
  final asOf = DateTime.utc(2026, 3, 11, 14, 30);

  FillUp fill(
    String id,
    String? vehicleId,
    int month,
    int day,
    double odo, {
    double litres = 40,
    double cost = 60,
    String? currency = 'EUR',
    FuelType fuel = FuelType.e10,
    bool full = true,
    bool correction = false,
    String? station,
  }) =>
      FillUp(
        id: id,
        date: DateTime.utc(2026, month, day),
        liters: litres,
        totalCost: cost,
        odometerKm: odo,
        fuelType: fuel,
        vehicleId: vehicleId,
        currency: currency,
        isFullTank: full,
        isCorrection: correction,
        stationName: station,
      );

  TripHistoryEntry trip(String id, String? vehicleId,
          {double km = 20,
          bool virtual = false,
          int day = 15,
          TripKind kind = TripKind.gpsPlusObd2}) =>
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
          startedAt: DateTime.utc(2026, 1, day, 8),
          endedAt: DateTime.utc(2026, 1, day, 8, 30),
          isVirtual: virtual,
          kind: kind,
        ),
      );

  /// A's two closed windows: 600 km / 36 L / €60, then 400 km / 28 L /
  /// €48. The acceptance arithmetic lives on exactly this history.
  List<FillUp> vehicleA() => [
        fill('a0', 'a', 1, 1, 0, litres: 40, cost: 60),
        fill('a1', 'a', 1, 10, 600, litres: 36, cost: 60),
        fill('a2', 'a', 1, 20, 1000, litres: 28, cost: 48),
      ];

  /// B: two windows, 500 km / 40 L / €70 and 500 km / 40 L / €70.
  List<FillUp> vehicleB() => [
        fill('b0', 'b', 1, 1, 5000, litres: 45, cost: 70),
        fill('b1', 'b', 1, 10, 5500, litres: 40, cost: 70),
        fill('b2', 'b', 1, 20, 6000, litres: 40, cost: 70),
      ];

  VehicleHistoryComparison compare(
    List<FillUp> fills, {
    List<TripHistoryEntry> trips = const [],
    List<String> ids = const ['a', 'b'],
    ComparisonPeriod period = ComparisonPeriod.allHistory,
    Map<String, VehicleProfile> vehicles = const {'a': a, 'b': b},
    MoneyValuationPolicy? valuation,
    DateTime? at,
  }) =>
      buildVehicleHistoryComparison(
        key: VehicleComparisonKey(vehicleIds: ids, period: period),
        fillUps: fills,
        trips: trips,
        asOf: at ?? asOf,
        vehicles: vehicles,
        valuation: valuation,
      );

  VehicleHistoryColumn columnA(VehicleHistoryComparison c) =>
      c.columnFor('a')!;

  group('box 1 — two vehicles, one period, the active vehicle untouched',
      () {
    test('both selected vehicles get a column over the same period', () {
      final c = compare([...vehicleA(), ...vehicleB()]);

      expect(c.columns.map((x) => x.vehicleId), ['a', 'b']);
      expect(c.key.period, ComparisonPeriod.allHistory);
      expect(c.referenceVehicleId, 'a');
    });

    test('the builder takes ids explicitly and reads no Ref', () {
      // Structural, not incidental: `buildVehicleHistoryComparison` is a
      // pure function of the records and the key. There is no container
      // to read `activeVehicleProfileProvider` from, so selecting a
      // column cannot switch the car the rest of the app shows.
      final only = compare([...vehicleA(), ...vehicleB()], ids: ['b']);

      expect(only.columns.map((x) => x.vehicleId), ['b']);
    });

    test('the key normalises order and dedupes, so A+B is B+A', () {
      expect(VehicleComparisonKey(vehicleIds: const ['b', 'a', 'b']),
          VehicleComparisonKey(vehicleIds: const ['a', 'b']));
      expect(VehicleComparisonKey(vehicleIds: const ['a', 'b']).signature,
          'a+b|*..*/closingFillInPeriod|$kVehicleComparisonEvidenceVersion');
    });

    test('the evidence version is part of the identity', () {
      expect(
        VehicleComparisonKey(
                vehicleIds: const ['a'], evidenceVersion: 'other') ==
            VehicleComparisonKey(vehicleIds: const ['a']),
        isFalse,
      );
    });
  });

  group('box 2 — matched totals, never the mean of the means', () {
    test('600 km/36 L and 400 km/28 L give 6.4, not the unweighted 6.5',
        () {
      final column = columnA(compare(vehicleA()));

      expect(column.matchedWindowCount, 2);
      expect(column.matchedDistanceKm, 1000);
      expect(column.consumptionPer100Km.valueOrNull, closeTo(6.4, 1e-9));
      // The unweighted mean of 6.0 and 7.0 — the wrong answer.
      expect(column.consumptionPer100Km.valueOrNull, isNot(closeTo(6.5, 1e-9)));
    });

    test('matched costs of EUR 60 and EUR 48 give EUR 0.108/km', () {
      final column = columnA(compare(vehicleA()));

      expect(column.costPerKm.valueOrNull, closeTo(0.108, 1e-9));
      expect(column.costValuationBasis,
          MoneyValuationBasis.closingWindowPurchaseCost);
    });

    test('the cost denominator is the matched window distance, not the '
        'odometer span of every purchase', () {
      // A third, UNCLOSED fill adds purchases and odometer span but no
      // closed window: dividing all purchases by the closed distance is
      // exactly the defect #4365 names.
      final withOpenTail = [
        ...vehicleA(),
        fill('a3', 'a', 1, 25, 1400, litres: 30, cost: 99, full: false),
      ];
      final column = columnA(compare(withOpenTail));

      expect(column.matchedDistanceKm, 1000);
      expect(column.costPerKm.valueOrNull, closeTo(0.108, 1e-9));
      expect(column.recordedDistanceKm, 1400);
      expect(column.recordedSpend.valueOrNull, const Money(267, 'EUR'));
    });
  });

  group('box 3 — a period beginning between two fills', () {
    // The report starts on 5 January: after A's opening fill (1 Jan) and
    // before the fill that closes the first window (10 Jan).
    final midTank = ComparisonPeriod(start: DateTime.utc(2026, 1, 5));

    test('the opening tank is preserved and flagged as pre-period', () {
      final column = columnA(compare(vehicleA(), period: midTank));

      final opening = column.opening!;
      expect(opening.openingFillId, 'a0');
      expect(opening.precedesPeriodStart, isTrue);
      expect(opening.openingFuel, FuelType.e10);
      expect(opening.openingOdometerKm, 0);
    });

    test('the straddling window is counted whole under the default rule',
        () {
      final column = columnA(compare(vehicleA(), period: midTank));

      expect(column.matchedWindowCount, 2);
      expect(column.boundaryWindowsIncluded, 1);
      expect(column.boundaryWindowsExcluded, 0);
      expect(column.consumptionPer100Km.valueOrNull, closeTo(6.4, 1e-9));
    });

    test('the stricter rule drops it and says how many it dropped', () {
      final column = columnA(compare(vehicleA(),
          period: ComparisonPeriod(
            start: DateTime.utc(2026, 1, 5),
            boundaryPolicy: BoundaryWindowPolicy.whollyContained,
          )));

      expect(column.matchedWindowCount, 1);
      expect(column.boundaryWindowsIncluded, 0);
      expect(column.boundaryWindowsExcluded, 1);
      // 28 L over 400 km — the whole surviving window, never a
      // prorated slice of the one that was cut.
      expect(column.consumptionPer100Km.valueOrNull, closeTo(7.0, 1e-9));
    });
  });

  group('box 4 — later purchases cannot rewrite an earlier period', () {
    final period = ComparisonPeriod(end: DateTime.utc(2026, 1, 31));

    test('an expensive purchase after every counted window changes '
        'neither the recorded spend nor the observed cost', () {
      final before = columnA(compare(vehicleA(), period: period));
      final after = columnA(compare([
        ...vehicleA(),
        fill('late', 'a', 3, 1, 1600, litres: 50, cost: 500),
      ], period: period));

      expect(after.recordedSpend.valueOrNull, before.recordedSpend.valueOrNull);
      expect(after.costPerKm.valueOrNull, before.costPerKm.valueOrNull);
      expect(after.consumedFuelCostPerKm.valueOrNull,
          before.consumedFuelCostPerKm.valueOrNull);
    });

    test('a fuel switch separates the purchase and consumed-fuel bases',
        () {
      // E10 in the tank at 1.50/L, then a switch to a dearer E5.
      final switched = [
        fill('s0', 'a', 1, 1, 0, litres: 40, cost: 60),
        fill('s1', 'a', 1, 10, 600, litres: 36, cost: 90, fuel: FuelType.e5),
        fill('s2', 'a', 1, 20, 1000, litres: 28, cost: 70, fuel: FuelType.e5),
      ];
      final column = columnA(compare(switched));

      // Purchase basis: what the windows' own fills cost, EUR 160/1000 km.
      expect(column.costPerKm.valueOrNull, closeTo(0.16, 1e-9));
      // Consumed-fuel basis: 36 L at the opening's 1.50 plus 28 L at
      // 90/36 = 2.50 — a model of what was burned, not what was bought.
      expect(column.consumedFuelCostPerKm.valueOrNull,
          closeTo((36 * 1.5 + 28 * 2.5) / 1000, 1e-9));
      expect(column.consumedFuelCostPerKm.qualifications,
          contains(ComparisonQualification.reconstructedValuation));
      expect(column.consumedFuelCostPerKm.qualifications,
          contains(ComparisonQualification.estimatedBasis));
    });

    test('a window that mixed grades cannot claim a known blend share',
        () {
      final switched = [
        fill('s0', 'a', 1, 1, 0, litres: 40, cost: 60),
        fill('s1', 'a', 1, 10, 600, litres: 36, cost: 90, fuel: FuelType.e5),
        fill('s2', 'a', 1, 20, 1000, litres: 28, cost: 70, fuel: FuelType.e5),
      ];
      final column = columnA(compare(switched));

      expect(column.consumptionPer100Km.qualifications,
          contains(ComparisonQualification.unknownBlendShare));
    });
  });

  group('box 5 — attribution, corrections and unfinished windows', () {
    test('an unassigned fill lands in neither column and is counted once',
        () {
      final c = compare([
        ...vehicleA(),
        ...vehicleB(),
        fill('orphan', null, 1, 12, 99000, litres: 50, cost: 99),
      ]);

      expect(columnA(c).matchedDistanceKm, 1000);
      expect(c.columnFor('b')!.matchedDistanceKm, 1000);
      expect(c.unassignedFillCount, 1);
      expect(c.ambiguousFillCount, 0);
    });

    test('an unassigned fill inside two vehicles odometer ranges is '
        'ambiguous, not shared', () {
      // B is re-odometered to overlap A, so the orphan at 800 km sits
      // inside both recorded ranges.
      final overlapping = [
        ...vehicleA(),
        fill('b0', 'b', 1, 1, 100, litres: 45, cost: 70),
        fill('b1', 'b', 1, 10, 700, litres: 40, cost: 70),
        fill('b2', 'b', 1, 20, 1100, litres: 40, cost: 70),
        fill('orphan', null, 1, 12, 800, litres: 50, cost: 99),
      ];
      final c = compare(overlapping);

      expect(c.ambiguousFillCount, 1);
      expect(c.unassignedFillCount, 0);
      expect(columnA(c).coverage.exclusions[ComparisonExclusion.ambiguousVehicle],
          1);
    });

    test('a vehicle whose only evidence is ambiguous says so', () {
      final c = compare([
        fill('a0', 'a', 1, 1, 0, litres: 40, cost: 60),
        fill('a1', 'a', 1, 10, 600, litres: 36, cost: 60),
        fill('b0', 'b', 1, 2, 100, litres: 40, cost: 60),
        fill('b1', 'b', 1, 11, 500, litres: 36, cost: 60),
        fill('orphan', null, 1, 12, 300, litres: 50, cost: 99),
      ], ids: ['a', 'b', 'c'], vehicles: const {'a': a, 'b': b});

      final cc = c.columnFor('c')!;
      expect(cc.consumptionPer100Km.eligibility, MetricEligibility.unavailable);
      expect(cc.consumptionPer100Km.reason,
          ComparisonUnavailableReason.ambiguousAttribution);
    });

    test('an unassigned trip belongs to no column', () {
      final c = compare([...vehicleA(), ...vehicleB()],
          trips: [trip('t1', 'a'), trip('t2', null)]);

      expect(columnA(c).coverage.tripCount, 1);
      expect(c.columnFor('b')!.coverage.tripCount, 0);
      expect(c.unassignedTripCount, 1);
    });

    test('a virtual trip is excluded and counted', () {
      final c = compare(vehicleA(),
          ids: ['a'], trips: [trip('t1', 'a', virtual: true)]);

      expect(columnA(c).coverage.tripCount, 0);
      expect(columnA(c).coverage.exclusions[ComparisonExclusion.virtualRecord],
          1);
    });

    test('corrections are counted apart from pump visits', () {
      final c = compare([
        ...vehicleA(),
        fill('corr', 'a', 1, 15, 800, litres: 2, cost: 0, correction: true),
      ], ids: ['a']);

      expect(columnA(c).refuelling.fillCount, 3);
      expect(columnA(c).refuelling.correctionCount, 1);
      expect(columnA(c).coverage.exclusions[ComparisonExclusion.correction], 1);
    });

    test('the in-progress window after the last full tank is excluded',
        () {
      final c = compare([
        ...vehicleA(),
        fill('open', 'a', 1, 25, 1200, litres: 20, cost: 30, full: false),
      ], ids: ['a']);

      expect(columnA(c).matchedWindowCount, 2);
      expect(columnA(c).coverage.exclusions[ComparisonExclusion.openWindow], 1);
      expect(columnA(c).consumptionPer100Km.qualifications,
          contains(ComparisonQualification.openWindowExcluded));
    });
  });

  group('box 6 — stated denominators', () {
    test('pump spend, consumed-fuel cost and quantities do not share one '
        'number', () {
      final column = columnA(compare(vehicleA(), ids: ['a']));

      // Recorded spend counts EVERY period purchase, opening included.
      expect(column.recordedSpend.valueOrNull, const Money(168, 'EUR'));
      // The closing-window basis counts only the windows' own fills.
      expect(column.matchedSpend.amountIn('EUR'), 108);
      // The pattern's quantity counts real pump visits, not windows.
      expect(column.refuelling.totalQuantity, 104);
      expect(column.refuelling.fillCount, 3);
      expect(column.refuelling.fullFillCount, 3);
      expect(column.refuelling.typicalQuantity, 36);
      expect(column.refuelling.medianDistanceBetweenFillsKm, 500);
      expect(column.refuelling.medianTimeBetweenFills,
          const Duration(days: 9, hours: 12));
    });

    test('price per unit divides the priced spend by the priced quantity',
        () {
      final column = columnA(compare(vehicleA(), ids: ['a']));

      expect(column.pricePerUnit.valueOrNull, closeTo(168 / 104, 1e-9));
    });

    test('station distribution counts only what was recorded', () {
      final c = compare([
        fill('a0', 'a', 1, 1, 0, litres: 40, cost: 60, station: 'Total'),
        fill('a1', 'a', 1, 10, 600, litres: 36, cost: 60, station: 'Total'),
        fill('a2', 'a', 1, 20, 1000, litres: 28, cost: 48),
      ], ids: ['a']);

      expect(columnA(c).stationFillCounts, {'Total': 2});
      expect(columnA(c).unnamedStationFillCount, 1);
    });

    test('range is an estimate derived from capacity and observation', () {
      final column = columnA(compare(vehicleA(), ids: ['a']));

      expect(column.estimatedRangeKm.eligibility, MetricEligibility.qualified);
      expect(column.estimatedRangeKm.qualifications,
          contains(ComparisonQualification.estimatedBasis));
      expect(column.estimatedRangeKm.valueOrNull, closeTo(50 / 6.4 * 100, 1e-6));
    });

    test('no capacity, no range — never a zero', () {
      final c = compare(vehicleA(),
          ids: ['a'], vehicles: const {'a': VehicleProfile(id: 'a', name: 'A')});

      expect(columnA(c).estimatedRangeKm.eligibility,
          MetricEligibility.unavailable);
      expect(columnA(c).estimatedRangeKm.valueOrNull, isNull);
    });
  });

  group('box 7 — qualified observations, never a fabricated winner', () {
    test('two currencies leave both observations and withhold the winner',
        () {
      final c = compare([
        ...vehicleA(),
        fill('b0', 'b', 1, 1, 5000, litres: 45, cost: 500, currency: 'DKK'),
        fill('b1', 'b', 1, 10, 5500, litres: 40, cost: 500, currency: 'DKK'),
        fill('b2', 'b', 1, 20, 6000, litres: 40, cost: 500, currency: 'DKK'),
      ]);

      expect(columnA(c).costPerKm.valueOrNull, closeTo(0.108, 1e-9));
      expect(c.columnFor('b')!.costPerKm.valueOrNull, closeTo(1.0, 1e-9));
      expect(c.lowestCostPerKm.eligibility, MetricEligibility.unavailable);
      expect(c.lowestCostPerKm.reason,
          ComparisonUnavailableReason.mixedCurrencies);
      // Consumption is unit-compatible, so IT still ranks.
      expect(c.lowestConsumption.valueOrNull, 'a');
    });

    test('a stale rate withholds the winner with its own reason', () {
      final stale = ExchangeRateSnapshot(rates: [
        ExchangeRate(
          baseCurrency: 'DKK',
          quoteCurrency: 'EUR',
          rate: 1 / 7.5,
          capturedAt: DateTime.utc(2020),
          source: 'test',
        ),
      ]);
      final c = compare([
        ...vehicleA(),
        fill('b0', 'b', 1, 1, 5000, litres: 45, cost: 500, currency: 'DKK'),
        fill('b1', 'b', 1, 10, 5500, litres: 40, cost: 500, currency: 'DKK'),
        fill('b2', 'b', 1, 20, 6000, litres: 40, cost: 500, currency: 'DKK'),
      ], valuation: MoneyValuationPolicy(
        targetCurrency: 'EUR',
        rates: stale,
        asOf: asOf,
      ));

      expect(c.lowestCostPerKm.reason,
          ComparisonUnavailableReason.exchangeRateStale);
    });

    test('an unknown currency cannot enter a euro figure', () {
      final c = compare([
        fill('a0', 'a', 1, 1, 0, litres: 40, cost: 60, currency: null),
        fill('a1', 'a', 1, 10, 600, litres: 36, cost: 60, currency: null),
        fill('a2', 'a', 1, 20, 1000, litres: 28, cost: 48, currency: null),
      ], ids: ['a']);

      expect(columnA(c).costPerKm.reason,
          ComparisonUnavailableReason.unknownCurrency);
      expect(columnA(c).purchaseSpend.amountIn(kUnknownCurrency), 168);
      // Quantities survive: the litres were real even when the money
      // has no denomination.
      expect(columnA(c).consumptionPer100Km.valueOrNull, closeTo(6.4, 1e-9));
    });

    test('a missing price does not manufacture a cheaper vehicle', () {
      final c = compare([
        fill('a0', 'a', 1, 1, 0, litres: 40, cost: 60),
        fill('a1', 'a', 1, 10, 600, litres: 36, cost: 0),
        fill('a2', 'a', 1, 20, 1000, litres: 28, cost: 48),
      ], ids: ['a']);

      expect(columnA(c).costPerKm.reason,
          ComparisonUnavailableReason.missingPrices);
      expect(columnA(c).costPerKm.valueOrNull, isNull);
    });

    test('a kg history keeps its spend and gets no L/100 km', () {
      final c = compare([
        fill('a0', 'a', 1, 1, 0, litres: 5, cost: 6, fuel: FuelType.cng),
        fill('a1', 'a', 1, 10, 600, litres: 4, cost: 6, fuel: FuelType.cng),
        fill('a2', 'a', 1, 20, 1000, litres: 4, cost: 6, fuel: FuelType.cng),
      ], ids: ['a']);

      expect(columnA(c).quantityUnit, FuelQuantityUnit.kilogram);
      expect(columnA(c).consumptionPer100Km.reason,
          ComparisonUnavailableReason.unsupportedUnit);
      expect(columnA(c).recordedSpend.valueOrNull, const Money(18, 'EUR'));
    });

    test('a single window is too short a history to crown a winner', () {
      final c = compare([
        ...vehicleA(),
        fill('b0', 'b', 1, 1, 5000, litres: 45, cost: 30),
        fill('b1', 'b', 1, 10, 5500, litres: 20, cost: 30),
      ]);

      expect(c.columnFor('b')!.consumptionPer100Km.valueOrNull,
          closeTo(4.0, 1e-9));
      expect(c.lowestConsumption.eligibility, MetricEligibility.unavailable);
      expect(c.lowestConsumption.reason,
          ComparisonUnavailableReason.tooFewSamples);
    });

    test('an uneven but sufficient sample is crowned WITH the caveat', () {
      final c = compare([
        fill('a0', 'a', 1, 1, 0, litres: 40, cost: 60),
        fill('a1', 'a', 1, 5, 400, litres: 20, cost: 30),
        fill('a2', 'a', 1, 10, 800, litres: 20, cost: 30),
        fill('a3', 'a', 1, 15, 1200, litres: 20, cost: 30),
        fill('a4', 'a', 1, 20, 1600, litres: 20, cost: 30),
        ...vehicleB(),
      ]);

      expect(c.lowestConsumption.valueOrNull, 'a');
      expect(c.lowestConsumption.qualifications,
          contains(ComparisonQualification.unequalSampleSizes));
      expect(c.lowestConsumption.qualifications,
          contains(ComparisonQualification.uncontrolledConditions));
    });

    test('an absent metric is never zero and never wins', () {
      final c = compare([
        ...vehicleA(),
        fill('b0', 'b', 1, 1, 5000, litres: 45, cost: 70),
      ]);

      final bc = c.columnFor('b')!;
      expect(bc.consumptionPer100Km.valueOrNull, isNull);
      expect(bc.consumptionPer100Km.reason,
          ComparisonUnavailableReason.noEvidence);
      expect(c.lowestConsumption.valueOrNull, isNull);
    });

    test('no condition-adjusted efficiency is claimed at all', () {
      final column = columnA(compare(vehicleA(), ids: ['a']));

      expect(column.conditionAdjustedPer100Km.reason,
          ComparisonUnavailableReason.noExpectedConsumption);
      expect(column.consumptionPer100Km.qualifications,
          contains(ComparisonQualification.uncontrolledConditions));
      expect(column.consumptionPer100Km.qualifications,
          contains(ComparisonQualification.partialConditionCoverage));
      expect(column.coverage.conditionCoverage, 0);
    });

    test('an observation older than the stale horizon says so', () {
      final c = compare(vehicleA(),
          ids: ['a'], at: DateTime.utc(2027, 6, 1));

      expect(columnA(c).consumptionPer100Km.qualifications,
          contains(ComparisonQualification.staleBasis));
      expect(columnA(c).consumptionPer100Km.figure, isA<Stale<double>>());
    });

    test('measured windows beside estimated trips are not pooled', () {
      // A GPS-only drive is MODELLED; the fill windows are measured.
      final c = compare(vehicleA(),
          ids: ['a'], trips: [trip('t1', 'a', kind: TripKind.gpsOnly)]);

      expect(columnA(c).coverage.provenance[EvidenceTier.measured], 2);
      expect(columnA(c).coverage.provenance[EvidenceTier.estimated], 1);
      expect(columnA(c).consumptionPer100Km.qualifications,
          contains(ComparisonQualification.mixedProvenance));
    });
  });

  group('box 8 — edits, deletions and a deleted vehicle', () {
    test('deleting a fill changes only that vehicle', () {
      final full = [...vehicleA(), ...vehicleB()];
      final before = compare(full);
      final after = compare(full.where((f) => f.id != 'a2').toList());

      expect(after.columnFor('b')!.consumptionPer100Km.valueOrNull,
          before.columnFor('b')!.consumptionPer100Km.valueOrNull);
      expect(columnA(after).matchedWindowCount, 1);
      expect(columnA(after).consumptionPer100Km.valueOrNull, closeTo(6.0, 1e-9));
    });

    test('reassigning a fill moves it one way only', () {
      final reassigned = [
        for (final f in [...vehicleA(), ...vehicleB()])
          if (f.id == 'a2') f.copyWith(vehicleId: 'b') else f,
      ];
      final c = compare(reassigned);

      expect(columnA(c).matchedWindowCount, 1);
      expect(columnA(c).sourcesFor(ComparisonFigure.consumption).windowIds,
          ['a1']);
      expect(c.columnFor('b')!.sourcesFor(ComparisonFigure.consumption)
          .windowIds
          .contains('a2'),
          isFalse,
          reason: 'the odometer jump makes it no window of B');
    });

    test('a deleted vehicle keeps its place in the selection', () {
      final c = compare([...vehicleA(), ...vehicleB()],
          vehicles: const {'a': a});

      expect(c.missingVehicleIds, ['b']);
      expect(c.key.vehicleIds, ['a', 'b']);
      expect(c.columns.length, 2);
    });
  });

  group('box 9 — summary to source record', () {
    test('every figure names the records behind it', () {
      final column = columnA(compare(vehicleA(), ids: ['a']));

      expect(column.sourcesFor(ComparisonFigure.consumption).windowIds,
          ['a1', 'a2']);
      expect(column.sourcesFor(ComparisonFigure.consumption).fillIds,
          ['a1', 'a2']);
      expect(column.sourcesFor(ComparisonFigure.consumedFuelCost).fillIds,
          containsAll(['a0', 'a1']));
      expect(column.sourcesFor(ComparisonFigure.recordedSpend).fillIds,
          ['a0', 'a1', 'a2']);
      expect(column.sourcesFor(ComparisonFigure.recordedSpend).recordCount, 3);
    });

    test('a figure with no evidence names no records', () {
      final c = compare([...vehicleA(), ...vehicleB()], vehicles: const {'a': a});

      expect(c.columnFor('b')!.sourcesFor(ComparisonFigure.consumption).isEmpty,
          isFalse);
      expect(
          compare(const <FillUp>[], ids: ['a'])
              .columnFor('a')!
              .sourcesFor(ComparisonFigure.consumption)
              .isEmpty,
          isTrue);
    });
  });

  group('deltas against the reference', () {
    test('a delta is absolute and relative, carrying both caveats', () {
      final c = compare([...vehicleA(), ...vehicleB()]);

      final delta = c.deltaFor('b', ComparisonFigure.consumption)!;
      expect(delta.absolute, closeTo(8.0 - 6.4, 1e-9));
      expect(delta.percent, closeTo((8.0 - 6.4) / 6.4, 1e-9));
      expect(delta.qualifications,
          contains(ComparisonQualification.uncontrolledConditions));
    });

    test('no delta across currencies and none against an absent figure',
        () {
      final c = compare([
        ...vehicleA(),
        fill('b0', 'b', 1, 1, 5000, litres: 45, cost: 500, currency: 'DKK'),
        fill('b1', 'b', 1, 10, 5500, litres: 40, cost: 500, currency: 'DKK'),
        fill('b2', 'b', 1, 20, 6000, litres: 40, cost: 500, currency: 'DKK'),
      ]);

      expect(c.deltaFor('b', ComparisonFigure.costPerKm), isNull);
      expect(c.deltaFor('a', ComparisonFigure.consumption), isNull,
          reason: 'the reference has no delta against itself');
    });

    test('the reference can be chosen without rebuilding', () {
      final c = compare([...vehicleA(), ...vehicleB()]);

      final againstB =
          c.deltaBetween('a', 'b', ComparisonFigure.consumption)!;
      expect(againstB.absolute, closeTo(6.4 - 8.0, 1e-9));
    });
  });
}
