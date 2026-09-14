// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4164 — the chain from a sensor reading to a money claim, end to end.
///
/// > One wrong assumption at the beginning can propagate all the way to a
/// > financial recommendation.
///
/// ```
/// consumption (L/100 km)  FuelConsumptionFigure
///        ↓
/// tank level + capacity   TankState
///        ↓
/// range + stop plan       RefuelPlanner        (#4146)
///        ↓
/// effective price         RefuelEconomics      (#4089)
///        ↓
/// opportunity             Opportunity          (#4149)
///        ↓
/// "save €3.80"            the notification     (#4148)
/// ```
///
/// Every link is tested. **The chain was not.** An 8 % optimistic
/// consumption figure, a capacity from a catalogue that does not match
/// the trim, or a crow-flies distance treated as a road distance each
/// arrive at the far end as a euro amount in a push notification.
///
/// Real domain objects throughout — no fakes that echo their input.
/// `feedback_fake_services_false_green` records that trap costing three
/// repeats of one bug.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/core/domain/refuel_plan.dart';
import 'package:tankstellen/core/services/provider_capability.dart';
import 'package:tankstellen/features/alerts/domain/opportunity_confidence.dart';
import 'package:tankstellen/features/alerts/domain/trip_opportunity_detector.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fuel_consumption_figure.dart';

void main() {
  final now = DateTime.utc(2026, 9, 14, 12);
  const freshPrice = DataValue.measured(Duration(minutes: 10));

  /// The whole chain, from a consumption FIGURE to an opportunity.
  ///
  /// Deliberately takes the same shapes the app passes between these
  /// layers, so a change to any link's contract breaks this and not a
  /// stub of it.
  TripOpportunityResult chain({
    FuelConsumptionFigure? consumption,
    DataValue<double> tankLitres = const DataValue.measured(18),
    double? capacityL = 50,
    double remainingKm = 400,
    List<PlanCandidate>? stations,
  }) =>
      TripOpportunityDetector.detect(
        trip: TripContext(
          remainingRouteKm: remainingKm,
          remainingMinutes: 240,
          tankLitres: tankLitres,
          tankCapacityL: capacityL,
          consumptionLPer100km: consumption?.litersPer100km,
          speedKmh: 100,
          candidatesAhead: stations ??
              const [
                PlanCandidate(
                    stationId: 'near', alongRouteKm: 8, pricePerLitre: 1.80),
                PlanCandidate(
                    stationId: 'far', alongRouteKm: 250, pricePerLitre: 1.55),
              ],
        ),
        priceAge: freshPrice,
        confidence: DataConfidence.high,
        now: now,
      );

  group('1. provenance survives the whole chain', () {
    test('a MEASURED consumption yields a confident money claim', () {
      final r = chain(consumption: const FuelConsumptionFigure.measured(6.5));
      expect(r.opportunity, isNotNull);

      final band = OpportunityConfidence.of(
        OpportunityConfidence.inputsFor(
          r.opportunity!,
          consumptionIsEstimated:
              const FuelConsumptionFigure.measured(6.5).isEstimated,
          distanceIsRoad: true,
        ),
      );
      expect(band, AlertConfidence.high);
    });

    test('an ESTIMATED consumption at the TOP is still qualified at the '
        'BOTTOM', () {
      // The link that had nothing enforcing it across the boundary.
      // #4160 made provenance a type; this proves it survives four
      // layers and reaches the notification as a hedge.
      const figure = FuelConsumptionFigure.estimated(6.5);
      expect(figure.asDataValue, isA<Estimated<double>>());

      final r = chain(consumption: figure);
      expect(r.opportunity, isNotNull);

      final band = OpportunityConfidence.of(
        OpportunityConfidence.inputsFor(
          r.opportunity!,
          consumptionIsEstimated: figure.isEstimated,
          distanceIsRoad: true,
        ),
      );
      expect(band, AlertConfidence.medium,
          reason: 'a saving computed from a MODELLED consumption reached '
              'the user stated as firmly as a measured one');
    });
  });

  group('2. a missing input stops the chain, it is never defaulted', () {
    test('no consumption → a named blocker, not a number', () {
      final r = chain(consumption: null);
      expect(r.opportunity, isNull);
      expect(r.blocker, TripOpportunityBlocker.noConsumption);
    });

    test('no capacity → a named blocker', () {
      final r = chain(
        consumption: const FuelConsumptionFigure.measured(6.5),
        capacityL: null,
      );
      expect(r.blocker, TripOpportunityBlocker.noTankCapacity);
    });

    test('no tank level → a named blocker, and NOT an empty tank', () {
      final r = chain(
        consumption: const FuelConsumptionFigure.measured(6.5),
        tankLitres: const DataValue.unknown(
            reason: DataUnknownReason.notMeasuredYet),
      );
      expect(r.blocker, TripOpportunityBlocker.noTankLevel);
    });

    test('each blocker is distinct — the user is told WHICH input is '
        'missing', () {
      final blockers = {
        chain(consumption: null).blocker,
        chain(
                consumption: const FuelConsumptionFigure.measured(6.5),
                capacityL: null)
            .blocker,
        chain(
                consumption: const FuelConsumptionFigure.measured(6.5),
                tankLitres: const DataValue.unknown(
                    reason: DataUnknownReason.notMeasuredYet))
            .blocker,
      };
      expect(blockers, hasLength(3));
    });
  });

  group('3. sensitivity is bounded — no sign flips', () {
    double? savingAt(double consumption) {
      final r = chain(
        consumption: FuelConsumptionFigure.measured(consumption),
        stations: const [
          PlanCandidate(
              stationId: 'near', alongRouteKm: 6, pricePerLitre: 1.85),
          PlanCandidate(
              stationId: 'far', alongRouteKm: 200, pricePerLitre: 1.50),
        ],
      );
      return r.opportunity?.netSaving;
    }

    test('±10 % on consumption never flips the sign of the claim', () {
      // "An 8 % optimistic consumption figure arrives at the end as a
      // euro amount." It may move the amount; it must not turn a saving
      // into a loss, which would be advice pointing the other way.
      const base = 6.5;
      final low = savingAt(base * 0.9);
      final mid = savingAt(base);
      final high = savingAt(base * 1.1);

      for (final s in [low, mid, high]) {
        if (s == null) continue;
        expect(s.isNegative, mid?.isNegative ?? s.isNegative,
            reason: 'a 10 % consumption error reversed the recommendation');
      }
    });

    test('every claim the chain emits is reproducible from its parts', () {
      // Trust rule 4, asserted at the END of the chain rather than at
      // the link that computes it.
      for (final c in [5.0, 6.5, 8.0, 12.0]) {
        final r = chain(consumption: FuelConsumptionFigure.measured(c));
        final o = r.opportunity;
        if (o == null) continue;
        expect(o.savingIsReproducible, isTrue,
            reason: 'at $c L/100 km the net does not equal gross − detour');
      }
    });
  });

  group('4. units survive every link', () {
    test('litres in, litres out — a 50 L tank never plans a 50 gal fill',
        () {
      final r = chain(
        consumption: const FuelConsumptionFigure.measured(6.5),
        capacityL: 50,
      );
      final plan = r.plans?.cheapest;
      if (plan == null) return;
      for (final stop in plan.stops) {
        expect(stop.litres, lessThanOrEqualTo(50),
            reason: 'a stop buys more than the tank holds — a unit '
                'slipped between capacity and the plan');
        expect(stop.litres, greaterThan(0));
      }
    });

    test('km in, km out — the stop is on the route, not past its end', () {
      final r = chain(
        consumption: const FuelConsumptionFigure.measured(6.5),
        remainingKm: 400,
      );
      final plan = r.plans?.cheapest;
      if (plan == null) return;
      for (final stop in plan.stops) {
        expect(stop.candidate.alongRouteKm, inInclusiveRange(0, 400),
            reason: 'a stop sits outside the route — a mile/km confusion '
                'anywhere in the chain lands here');
      }
    });

    test('a consumption an order of magnitude wrong does not silently '
        'produce a plausible plan', () {
      // 65 L/100 km is a lorry, not a car: the honest outcome is a plan
      // with MORE stops, never the same plan with a bigger number.
      final normal = chain(consumption: const FuelConsumptionFigure.measured(6.5));
      final absurd = chain(consumption: const FuelConsumptionFigure.measured(65));
      final n = normal.plans?.cheapest?.stops.length ?? 0;
      final a = absurd.plans?.cheapest?.stops.length ?? 0;
      expect(a >= n || absurd.plans?.isFeasible == false, isTrue,
          reason: 'ten times the consumption produced no extra stops and '
              'no infeasibility — the figure is not reaching the planner');
    });
  });
}
