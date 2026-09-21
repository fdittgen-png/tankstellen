// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/core/domain/refuel_plan.dart';
import 'package:tankstellen/core/services/provider_capability.dart';
import 'package:tankstellen/features/alerts/domain/opportunity.dart';
import 'package:tankstellen/features/alerts/domain/trip_opportunity_detector.dart';

/// #4153 — trip- and tank-aware opportunities.
///
/// The alert worth having is "best fuel stop in 18 km"; the behaviour
/// worth having more is the SILENCE when the tank already covers the
/// trip. Both are pinned here, and so is the distinction that decides
/// correctness: an unknown tank level is not an empty tank.
void main() {
  final now = DateTime.utc(2026, 9, 14, 12);
  const freshPrice = DataValue.measured(Duration(minutes: 10));

  PlanCandidate at(double km, double price, {String? id}) => PlanCandidate(
        stationId: id ?? 'st${km.toInt()}',
        alongRouteKm: km,
        pricePerLitre: price,
      );

  TripContext trip({
    double remainingKm = 400,
    double remainingMinutes = 240,
    DataValue<double> litres = const DataValue.measured(20),
    double? capacity = 50,
    double? consumption = 6,
    double? speed = 100,
    List<PlanCandidate>? candidates,
  }) =>
      TripContext(
        remainingRouteKm: remainingKm,
        remainingMinutes: remainingMinutes,
        tankLitres: litres,
        tankCapacityL: capacity,
        consumptionLPer100km: consumption,
        speedKmh: speed,
        candidatesAhead: candidates ??
            [at(10, 1.90), at(150, 1.60), at(300, 1.85)],
      );

  TripOpportunityResult detect(TripContext t) =>
      TripOpportunityDetector.detect(
        trip: t,
        priceAge: freshPrice,
        confidence: DataConfidence.high,
        now: now,
      );

  group('a claim, never a guess', () {
    test('an UNKNOWN tank level blocks — it is not an empty tank', () {
      // The distinction this whole epic keeps running into. A `double?`
      // reading null as zero would tell a driver with a full tank to
      // refuel immediately, which is the most expensive way to lose
      // someone's trust in an alert.
      final r = detect(trip(
        litres: const DataValue.unknown(
            reason: DataUnknownReason.notMeasuredYet),
      ));
      expect(r.opportunity, isNull);
      expect(r.blocker, TripOpportunityBlocker.noTankLevel);
    });

    test('an ESTIMATED tank level blocks too', () {
      // "You need fuel" is a claim. An estimate is enough to rank
      // stations by value; it is not enough to tell someone they are
      // about to run out.
      final r = detect(trip(
        litres: const DataValue.estimated(8, basis: DataBasis.derived),
      ));
      expect(r.blocker, TripOpportunityBlocker.noTankLevel);
    });

    test('no consumption, no capacity, no trip — each named', () {
      expect(detect(trip(consumption: null)).blocker,
          TripOpportunityBlocker.noConsumption);
      expect(detect(trip(capacity: null)).blocker,
          TripOpportunityBlocker.noTankCapacity);
      expect(detect(trip(remainingKm: 0)).blocker,
          TripOpportunityBlocker.noTrip);
      expect(detect(trip(candidates: const [])).blocker,
          TripOpportunityBlocker.noPricedStations);
    });
  });

  group('silence is the correct output', () {
    test('a tank that covers the trip produces nothing', () {
      // 45 L at 6 L/100 km is 750 km of range for a 300 km drive.
      final r = detect(trip(
        remainingKm: 300,
        litres: const DataValue.measured(45),
      ));
      expect(r.opportunity, isNull);
      expect(r.blocker, TripOpportunityBlocker.noStopNeeded);
    });

    test('a needed stop that is still far away says nothing YET', () {
      // At 100 km/h the lead distance is ~13 km. A stop 150 km ahead is
      // real and is not news.
      final r = detect(trip(
        candidates: [at(150, 1.60), at(300, 1.85)],
      ));
      expect(r.blocker, TripOpportunityBlocker.tooEarlyToSay);
    });
  });

  group('lead time scales with speed', () {
    test('a motorway driver is told earlier than one in traffic', () {
      final fast = trip(speed: 130).leadDistanceKm;
      final slow = trip(speed: 40).leadDistanceKm;
      expect(fast, greaterThan(slow));
    });

    test('and it is clamped at both ends', () {
      expect(trip(speed: 5).leadDistanceKm, kMinStopLeadKm);
      expect(trip(speed: 400).leadDistanceKm, kMaxStopLeadKm);
    });

    test('no speed falls back to the route average', () {
      // 400 km in 240 min is 100 km/h, so this must match the explicit
      // 100 case rather than collapsing to the floor.
      expect(trip(speed: null).leadDistanceKm,
          closeTo(trip(speed: 100).leadDistanceKm, 0.001));
    });

    test('the same stop fires at 15 km on a motorway and not in town',
        () {
      final candidates = [at(15, 1.60), at(300, 1.85)];
      expect(detect(trip(speed: 130, candidates: candidates)).opportunity,
          isNotNull);
      expect(detect(trip(speed: 40, candidates: candidates)).blocker,
          TripOpportunityBlocker.tooEarlyToSay);
    });
  });

  group('when it does fire', () {
    test('it names the stop and how far ahead it is', () {
      final r = detect(trip(candidates: [at(8, 1.60), at(300, 1.85)]));
      final o = r.opportunity!;
      expect(o.kind, OpportunityKind.refuelSoon);
      expect(o.stationId, 'st8');
      expect(o.distanceKm, 8);
      expect(r.plans, isNotNull,
          reason: 'the surface must be able to show the stops behind the '
              'claim rather than ask the user to take it on faith');
    });

    test('any money it claims is reproducible', () {
      final o =
          detect(trip(candidates: [at(8, 1.60), at(300, 1.85)])).opportunity!;
      expect(o.savingIsReproducible, isTrue);
    });

    test('and when the two plans diverge, net IS their difference', () {
      // The decomposition trust rule 4 wants: gross at the pumps, detour
      // as the extra driving, and a net the user can check against the
      // two plans on screen. `totalCost` already contains each plan's
      // own detour, so using the difference of totals AS the gross would
      // subtract the driving twice.
      //
      // #4360 — at the SAME terminal state: each plan's pump cash already
      // pays for its own detour fuel, and the fastest plan's fuller tank
      // is valued back at the set's one basis before any difference is
      // called a saving.
      final r = detect(trip(candidates: [at(8, 1.60), at(300, 1.85)]));
      final o = r.opportunity!;
      final plans = r.plans!;
      final diff = plans.comparableCost(plans.fastest!)! -
          plans.comparableCost(plans.cheapest!)!;
      if (diff > 0) {
        expect(o.netSaving, closeTo(diff, 0.0001));
        expect(o.detourCost, 0, reason: 'never a second charge');
      } else {
        expect(o.netSaving, isNull);
      }
    });

    test('#4360 — a fuller tank is not a saving, and #4362 no longer '
        'buys one to be fast', () {
      // One station 5 km ahead at €2/L, 10 L in a 50 L tank, 120 km to
      // go at 10 L/100 km.
      //
      // This case used to assert a ≈€60 cash gap, because "fastest"
      // meant filling the tank. #4362 made each objective a genuine
      // minimum of the thing it names, and a fuller tank does not make
      // a one-stop journey quicker — so the planner now answers every
      // objective with the same plan and buys only what the journey
      // needs. Both halves of #4360 are asserted here at the detector:
      // the plans compare equal at one basis, and no saving is claimed.
      // The economics-level pair that DOES differ in cash (a hand-built
      // fill-up beside the cheapest, €76 apart, both €4 comparable) is
      // pinned in test/core/domain/refuel_plan_conservation_test.dart.
      final r = detect(trip(
        remainingKm: 120,
        remainingMinutes: 80,
        litres: const DataValue.measured(10),
        consumption: 10,
        candidates: [at(5, 2.0)],
      ));
      final plans = r.plans!;
      expect(plans.fastest!.litresBought,
          closeTo(plans.cheapest!.litresBought, 1e-9),
          reason: 'being fast is not a reason to buy fuel (#4362)');
      expect(plans.fastest!.endLitres, lessThan(50),
          reason: 'and the tank is not filled for its own sake');
      expect(plans.comparableCost(plans.fastest!),
          closeTo(plans.comparableCost(plans.cheapest!)!, 1e-9));
      final o = r.opportunity!;
      expect(o.grossSaving, isNull);
      expect(o.netSaving, isNull);
    });

    test('a cheaper station further on means no alert at the near one',
        () {
      // The planner already answers this and the detector must not
      // second-guess it: with a cheaper stop at 120 km that the tank
      // reaches, stopping at 8 km is not the advice, so there is
      // nothing to say yet.
      expect(
        detect(trip(candidates: [at(8, 1.60), at(120, 1.50)])).blocker,
        TripOpportunityBlocker.tooEarlyToSay,
      );
    });

    test('it expires, so closing the distance cannot re-raise it', () {
      final o = detect(trip(candidates: [at(8, 1.60), at(300, 1.85)]))
          .opportunity!;
      expect(o.isExpiredAt(now.add(const Duration(minutes: 20))), isTrue);
      expect(o.isExpiredAt(now.add(const Duration(minutes: 1))), isFalse);
    });
  });

  group('an unreachable station outranks everything', () {
    test('a gap fires even though no price is being compared', () {
      // 10 L at 6 L/100 km reaches ~166 km, minus the 5 L reserve: about
      // 83 km. The only station is 300 km away. Running dry is the most
      // urgent thing this app can say, and it says it without a saving
      // to offer.
      final r = detect(trip(
        remainingKm: 400,
        litres: const DataValue.measured(10),
        candidates: [at(300, 1.60)],
      ));
      expect(r.opportunity, isNotNull);
      expect(r.opportunity!.kind, OpportunityKind.refuelSoon);
      expect(r.plans!.isFeasible, isFalse);
      expect(r.opportunity!.isPriceable, isFalse,
          reason: 'there is no saving here, and it must not be ranked as '
              'though there were');
    });

    test('the gap is reported so the surface can say where', () {
      final r = detect(trip(
        remainingKm: 400,
        litres: const DataValue.measured(10),
        candidates: [at(300, 1.60)],
      ));
      expect(r.plans!.gap, isNotNull);
      expect(r.opportunity!.distanceKm, r.plans!.gap!.fromKm);
    });
  });
}
