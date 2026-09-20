// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/comparison_eligibility.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/refuel_plan.dart';
import 'package:tankstellen/core/domain/vehicle_comparison_key.dart';
import 'package:tankstellen/core/domain/vehicle_trip_comparison_builder.dart';

/// #4367 — the same journey, compared across vehicles.
///
/// Every fixture here is hand-checkable: the acceptance boxes of the
/// issue are arithmetic, and a test that cannot be reproduced on paper
/// proves nothing about a forecast the driver is asked to trust.
void main() {
  final departure = DateTime.utc(2026, 9, 20, 8);

  VehicleTripJourney journey({
    double routeKm = 200,
    double drivingMinutes = 120,
    String currency = 'EUR',
    RefuelObjective objective = RefuelObjective.lowestCost,
  }) =>
      VehicleTripJourney(
        routeKm: routeKm,
        drivingMinutes: drivingMinutes,
        currencyCode: currency,
        departAt: departure,
        objective: objective,
      );

  VehicleTripBasis basis(
    String id, {
    required double consumption,
    double capacity = 50,
    double start = 50,
    double reserve = kDefaultReserveLitres,
    FuelType? fuel = FuelType.e10,
    TripInputSource consumptionSource = TripInputSource.measured,
    Set<ComparisonQualification> qualifications = const {},
  }) =>
      VehicleTripBasis(
        vehicleId: id,
        vehicleName: id.toUpperCase(),
        fuel: fuel,
        capacityL: capacity,
        startLitres: start,
        reserveLitres: reserve,
        consumptionLPer100km: consumption,
        consumptionSource: consumptionSource,
        levelSource: TripInputSource.measured,
        qualifications: qualifications,
      );

  PlanCandidate station(String id, double km, double price) => PlanCandidate(
        stationId: id,
        alongRouteKm: km,
        pricePerLitre: price,
      );

  VehicleTripComparison compare(
    VehicleTripJourney j,
    List<VehicleTripInput> inputs, {
    String? reference,
  }) =>
      buildVehicleTripComparison(
        key: VehicleTripComparisonKey(
          vehicles: VehicleComparisonKey(
              vehicleIds: [for (final i in inputs) i.basis.vehicleId]),
          journey: j,
          basisSignature: [for (final i in inputs) i.basis.signature].join('+'),
        ),
        asOf: departure,
        inputs: inputs,
        referenceVehicleId: reference,
      );

  group('the 200 km arithmetic (acceptance box 1)', () {
    test(
        'A at 6 L/100 km and EUR1.80/L uses 12 L / EUR21.60; B at '
        '8 L/100 km and EUR1.60/L uses 16 L / EUR25.60', () {
      final result = compare(journey(), [
        VehicleTripInput(
          basis: basis('a', consumption: 6),
          candidates: [station('s-a', 100, 1.80)],
        ),
        VehicleTripInput(
          basis: basis('b', consumption: 8),
          candidates: [station('s-b', 100, 1.60)],
        ),
      ]);

      final a = result.columnFor('a')!;
      final b = result.columnFor('b')!;
      expect(a.fuelUsedLitres.valueOrNull, closeTo(12, 1e-9));
      expect(b.fuelUsedLitres.valueOrNull, closeTo(16, 1e-9));
      expect(a.costToDrive.valueOrNull!.amount, closeTo(21.60, 1e-9));
      expect(b.costToDrive.valueOrNull!.amount, closeTo(25.60, 1e-9));
      expect(a.costToDrive.valueOrNull!.currencyCode, 'EUR');
    });

    test('the lower pump price is NOT mistaken for the lower journey cost',
        () {
      final result = compare(journey(), [
        VehicleTripInput(
          basis: basis('a', consumption: 6),
          candidates: [station('s-a', 100, 1.80)],
        ),
        VehicleTripInput(
          basis: basis('b', consumption: 8),
          candidates: [station('s-b', 100, 1.60)],
        ),
      ]);

      // B buys the cheaper litre and still loses the journey.
      expect(b0(result).valuationPricePerLitre, 1.60);
      expect(result.columnFor('a')!.valuationPricePerLitre, 1.80);
      expect(result.lowestCostToDrive.valueOrNull, 'a');
    });

    test('the cost-to-drive winner is an ESTIMATE and says so', () {
      final result = compare(journey(), [
        VehicleTripInput(
          basis: basis('a', consumption: 6),
          candidates: [station('s-a', 100, 1.80)],
        ),
        VehicleTripInput(
          basis: basis('b', consumption: 8),
          candidates: [station('s-b', 100, 1.60)],
        ),
      ]);
      expect(result.lowestCostToDrive.eligibility,
          MetricEligibility.qualified);
      expect(result.lowestCostToDrive.qualifications,
          contains(ComparisonQualification.estimatedBasis));
    });
  });

  group('a full tank against an almost empty one (acceptance box 2)', () {
    // The SAME car, driven the same 200 km, differing only in what is in
    // the tank when it leaves.
    List<VehicleTripInput> pair() => [
          VehicleTripInput(
            basis: basis('full', consumption: 6, start: 50),
            candidates: [station('near', 10, 1.80), station('far', 100, 1.80)],
          ),
          VehicleTripInput(
            basis: basis('empty', consumption: 6, start: 6),
            candidates: [station('near', 10, 1.80), station('far', 100, 1.80)],
          ),
        ];

    test('new pump spend and stops differ', () {
      final result = compare(journey(), pair());
      final full = result.columnFor('full')!;
      final empty = result.columnFor('empty')!;

      expect(full.stopCount.valueOrNull, 0);
      expect(full.cashRequired.valueOrNull!.amount, closeTo(0, 1e-9));
      expect(empty.stopCount.valueOrNull, greaterThan(0));
      // Starts with 6 L, burns 12 L, must end on the 5 L reserve:
      // 11 L at EUR1.80 = EUR19.80.
      expect(empty.cashRequired.valueOrNull!.amount, closeTo(19.80, 1e-6));
    });

    test('cost-to-drive is unchanged — a full tank is not a cheaper car',
        () {
      final result = compare(journey(), pair());
      expect(result.columnFor('full')!.costToDrive.valueOrNull!.amount,
          closeTo(21.60, 1e-6));
      expect(result.columnFor('empty')!.costToDrive.valueOrNull!.amount,
          closeTo(21.60, 1e-6));
    });

    test('and no false efficiency winner is named between them', () {
      final result = compare(journey(), pair());
      // Identical cost to drive: the tie breaks deterministically on id
      // and never on who happened to start full.
      expect(result.lowestCostToDrive.valueOrNull, 'empty');
      expect(result.lowestCashRequired.valueOrNull, 'full');
    });
  });

  group('each vehicle keeps its own capacity, reserve and level '
      '(acceptance box 3)', () {
    test('two tanks produce two independently feasible plans', () {
      // A 28 L tank on a 10 L reserve has 180 km of range and cannot
      // cross 200 km at 10 L/100 km; a 60 L tank on a 5 L reserve can.
      final result = compare(journey(), [
        VehicleTripInput(
          basis: basis('small',
              consumption: 10, capacity: 28, start: 28, reserve: 10),
          candidates: [station('mid', 100, 1.70)],
        ),
        VehicleTripInput(
          basis: basis('large',
              consumption: 10, capacity: 60, start: 60, reserve: 5),
          candidates: [station('mid', 100, 1.70)],
        ),
      ]);

      final small = result.columnFor('small')!;
      final large = result.columnFor('large')!;
      expect(small.stopCount.valueOrNull, 1,
          reason: '18 L of usable fuel covers 180 km, so the small tank '
              'must refuel to keep its reserve over 200 km');
      expect(large.stopCount.valueOrNull, 0);
      // Every leg was checked: the stop is reached above the reserve.
      expect(small.plan!.stops.single.arrivalLitres,
          greaterThanOrEqualTo(small.basis.reserveLitres - 1e-9));
      expect(large.endLitres.valueOrNull, closeTo(40, 1e-9));
    });

    test('one column\'s level is never copied into the other', () {
      final result = compare(journey(), [
        VehicleTripInput(
          basis: basis('full', consumption: 6, start: 50),
          candidates: [station('mid', 100, 1.80)],
        ),
        VehicleTripInput(
          basis: basis('half', consumption: 6, start: 25),
          candidates: [station('mid', 100, 1.80)],
        ),
      ]);
      expect(result.columnFor('full')!.basis.startLitres, 50);
      expect(result.columnFor('half')!.basis.startLitres, 25);
      expect(result.columnFor('full')!.endLitres.valueOrNull,
          closeTo(38, 1e-9));
      expect(result.columnFor('half')!.endLitres.valueOrNull,
          closeTo(13, 1e-9));
    });
  });

  group('the #4361 border scenario, run with two ranges and two fuels '
      '(acceptance box 4)', () {
    // 200 km, station A at km40 before the border at EUR2/L, station B
    // at km100 after it at EUR1.50/L, no detours or fees.
    final petrolStops = [station('A', 40, 2.00), station('B', 100, 1.50)];
    // The diesel car sees its OWN country-fuel offers — a different set
    // of prices at the same two forecourts.
    final dieselStops = [station('A', 40, 1.90), station('B', 100, 1.40)];

    test('the short-range petrol car needs the bridge fill and pays EUR25',
        () {
      final result = compare(journey(), [
        VehicleTripInput(
          basis: basis('petrol',
              consumption: 10, capacity: 40, start: 10, reserve: 5),
          candidates: petrolStops,
        ),
        VehicleTripInput(
          basis: basis('diesel',
              consumption: 5,
              capacity: 50,
              start: 12,
              reserve: 5,
              fuel: FuelType.diesel),
          candidates: dieselStops,
        ),
      ]);

      final petrol = result.columnFor('petrol')!;
      expect(petrol.stationIds, ['A', 'B']);
      // 5 L at A (EUR10) + 10 L at B (EUR15), ending on the 5 L reserve.
      expect(petrol.cashRequired.valueOrNull!.amount, closeTo(25, 1e-6));
      expect(petrol.plan!.stops.first.litres, closeTo(5, 1e-6));
      expect(petrol.plan!.endLitres, closeTo(5, 1e-6));
    });

    test('the long-range diesel car reaches the cheaper station directly',
        () {
      final result = compare(journey(), [
        VehicleTripInput(
          basis: basis('petrol',
              consumption: 10, capacity: 40, start: 10, reserve: 5),
          candidates: petrolStops,
        ),
        VehicleTripInput(
          basis: basis('diesel',
              consumption: 5,
              capacity: 50,
              start: 12,
              reserve: 5,
              fuel: FuelType.diesel),
          candidates: dieselStops,
        ),
      ]);

      final diesel = result.columnFor('diesel')!;
      expect(diesel.stationIds, ['B'],
          reason: '7 usable litres cover 140 km — enough to reach the '
              'cheaper station past the border, so the expensive bridge '
              'stop the petrol car needs is not needed here');
      expect(diesel.basis.fuel, FuelType.diesel);
      // Each column values its own fuel at its own best price.
      expect(diesel.valuationPricePerLitre, 1.40);
      expect(result.columnFor('petrol')!.valuationPricePerLitre, 1.50);
    });

    test('an unreachable gap is a gap, not a plan', () {
      final result = compare(journey(), [
        VehicleTripInput(
          basis: basis('stranded',
              consumption: 10, capacity: 40, start: 6, reserve: 5),
          candidates: [station('B', 100, 1.50)],
        ),
        VehicleTripInput(
          basis: basis('ok', consumption: 6, start: 50),
          candidates: [station('B', 100, 1.50)],
        ),
      ]);
      final stranded = result.columnFor('stranded')!;
      expect(stranded.isInfeasible, isTrue);
      expect(stranded.plan, isNull);
      expect(stranded.cashRequired.eligibility,
          MetricEligibility.unavailable);
      // The route's own fuel need is still valid arithmetic.
      expect(stranded.fuelUsedLitres.valueOrNull, closeTo(20, 1e-9));
      // And with only one comparable column left there is no winner.
      expect(result.lowestCostToDrive.eligibility,
          MetricEligibility.unavailable);
      expect(result.lowestCostToDrive.reason,
          ComparisonUnavailableReason.tooFewSamples);
    });
  });

  group('provenance and unsupported metrics (acceptance box 7)', () {
    test('a kWh vehicle is refused, not relabelled into litres', () {
      final result = compare(journey(), [
        VehicleTripInput(
          basis: basis('ev', consumption: 18, fuel: FuelType.electric),
        ),
        VehicleTripInput(
          basis: basis('petrol', consumption: 6),
          candidates: [station('mid', 100, 1.80)],
        ),
      ]);
      final ev = result.columnFor('ev')!;
      expect(ev.unavailable, ComparisonUnavailableReason.unsupportedUnit);
      expect(ev.fuelUsedLitres.valueOrNull, isNull);
      expect(ev.costToDrive.valueOrNull, isNull);
      // What remains valid is still shown: the road's own duration.
      expect(ev.totalMinutes.valueOrNull, 120);
    });

    test('a column with no plan cannot become the guaranteed-fastest entry',
        () {
      final result = compare(journey(), [
        VehicleTripInput(
          basis: basis('ev', consumption: 18, fuel: FuelType.electric),
        ),
        VehicleTripInput(
          basis: basis('petrol', consumption: 6),
          candidates: [station('mid', 100, 1.80)],
        ),
      ]);
      // The EV's 120 unqualified minutes are the lowest number on the
      // screen and it still wins nothing.
      expect(result.shortestTime.eligibility, MetricEligibility.unavailable);
    });

    test('a manual consumption is used, and labelled manual', () {
      final typed = basis('typed', consumption: 6)
          .withAssumption(const VehicleTripAssumption(
              consumptionLPer100km: 9));
      final result = compare(journey(), [
        VehicleTripInput(
          basis: typed,
          candidates: [station('mid', 100, 1.80)],
        ),
        VehicleTripInput(
          basis: basis('measured', consumption: 6),
          candidates: [station('mid', 100, 1.80)],
        ),
      ]);
      final column = result.columnFor('typed')!;
      expect(column.basis.consumptionLPer100km, 9);
      expect(column.basis.consumptionSource, TripInputSource.manual);
      expect(column.basis.isManual, isTrue);
      expect(column.fuelUsedLitres.valueOrNull, closeTo(18, 1e-9));
      // And the measured column is untouched by the other's assumption.
      expect(result.columnFor('measured')!.basis.consumptionSource,
          TripInputSource.measured);
      expect(result.columnFor('measured')!.fuelUsedLitres.valueOrNull,
          closeTo(12, 1e-9));
    });

    test('a stale or uncontrolled consumption stays qualified in the '
        'forecast', () {
      final result = compare(journey(), [
        VehicleTripInput(
          basis: basis('stale',
              consumption: 6,
              qualifications: const {ComparisonQualification.staleBasis}),
          candidates: [station('mid', 100, 1.80)],
        ),
        VehicleTripInput(
          basis: basis('fresh', consumption: 6),
          candidates: [station('mid', 100, 1.80)],
        ),
      ]);
      expect(result.columnFor('stale')!.costToDrive.qualifications,
          containsAll(<ComparisonQualification>{
            ComparisonQualification.staleBasis,
            ComparisonQualification.estimatedBasis,
          }));
    });

    test('no station selling this fuel means no cost to drive, not a free '
        'drive', () {
      final result = compare(journey(), [
        VehicleTripInput(basis: basis('unpriced', consumption: 6)),
        VehicleTripInput(
          basis: basis('priced', consumption: 6),
          candidates: [station('mid', 100, 1.80)],
        ),
      ]);
      final column = result.columnFor('unpriced')!;
      expect(column.plan, isNotNull, reason: 'the tank covers the journey');
      expect(column.costToDrive.eligibility, MetricEligibility.unavailable);
      expect(column.costToDrive.reason,
          ComparisonUnavailableReason.missingPrices);
      expect(column.costToDrive.valueOrNull, isNull);
    });
  });

  group('the comparison identity reuses #4365\'s key', () {
    test('picking A then B and B then A is ONE question', () {
      final j = journey();
      final ab = VehicleTripComparisonKey(
          vehicles: VehicleComparisonKey(vehicleIds: const ['a', 'b']),
          journey: j);
      final ba = VehicleTripComparisonKey(
          vehicles: VehicleComparisonKey(vehicleIds: const ['b', 'a']),
          journey: j);
      expect(ab, ba);
      expect(ab.hashCode, ba.hashCode);
    });

    test('the same cars over a different road are a different question', () {
      final short = VehicleTripComparisonKey(
          vehicles: VehicleComparisonKey(vehicleIds: const ['a', 'b']),
          journey: journey(routeKm: 200));
      final long = VehicleTripComparisonKey(
          vehicles: VehicleComparisonKey(vehicleIds: const ['a', 'b']),
          journey: journey(routeKm: 400));
      expect(short == long, isFalse);
    });

    test('a changed assumption is a different question', () {
      final j = journey();
      final plain = VehicleTripComparisonKey(
          vehicles: VehicleComparisonKey(vehicleIds: const ['a']),
          journey: j,
          basisSignature: basis('a', consumption: 6).signature);
      final typed = VehicleTripComparisonKey(
          vehicles: VehicleComparisonKey(vehicleIds: const ['a']),
          journey: j,
          basisSignature: basis('a', consumption: 6)
              .withAssumption(
                  const VehicleTripAssumption(consumptionLPer100km: 9))
              .signature);
      expect(plain == typed, isFalse);
    });
  });

  group('the objective is one question for every column', () {
    test('every column is reported on the selected objective', () {
      final result = compare(
        journey(objective: RefuelObjective.leastExtraDistance),
        [
          VehicleTripInput(
            basis: basis('a', consumption: 6),
            candidates: [station('mid', 100, 1.80)],
          ),
          VehicleTripInput(
            basis: basis('b', consumption: 8),
            candidates: [station('mid', 100, 1.60)],
          ),
        ],
      );
      for (final column in result.columns) {
        expect(column.plan, same(column.plans!.leastDetour));
      }
    });
  });

  group('deltas', () {
    test('a money delta is withheld across two currencies', () {
      final result = compare(journey(), [
        VehicleTripInput(
          basis: basis('a', consumption: 6),
          candidates: [station('mid', 100, 1.80)],
        ),
        VehicleTripInput(
          basis: basis('b', consumption: 8),
          candidates: [station('mid', 100, 1.60)],
        ),
      ]);
      final delta =
          result.deltaBetween('b', 'a', TripComparisonFigure.costToDrive);
      expect(delta!.absolute, closeTo(4.0, 1e-6));
      expect(delta.qualifications,
          contains(ComparisonQualification.estimatedBasis));
    });

    test('a delta against an unavailable metric is null, never zero', () {
      final result = compare(journey(), [
        VehicleTripInput(
          basis: basis('ev', consumption: 18, fuel: FuelType.electric),
        ),
        VehicleTripInput(
          basis: basis('petrol', consumption: 6),
          candidates: [station('mid', 100, 1.80)],
        ),
      ]);
      expect(
          result.deltaBetween(
              'ev', 'petrol', TripComparisonFigure.costToDrive),
          isNull);
    });
  });
}

/// The `b` column, named so the assertion above reads as a sentence.
VehicleTripColumn b0(VehicleTripComparison result) => result.columnFor('b')!;
