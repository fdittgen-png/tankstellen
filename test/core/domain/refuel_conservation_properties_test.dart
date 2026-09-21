// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// Property tests for the #4360 conservation and comparability laws,
/// folded into the economics train per #4339 S13 (#4158 style).
///
/// Each property names the contract sentence it enforces
/// (`refuel_trip_cost.dart`, `refuel_planner.dart`,
/// `docs/specs/refuel-economics.md` §6). Generators stay REALISTIC:
/// prices 0.5–3.0, distances 0–200 km, consumption 3–25 L/100 km; the
/// NaN/infinite guard clauses are example-tested in
/// `refuel_trip_cost_test.dart`.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart'
    show Glados3, Generator, any, DoubleAnys, GeneratorUtils;
import 'package:tankstellen/core/domain/refuel_economics.dart';
import 'package:tankstellen/core/domain/refuel_plan.dart';
import 'package:tankstellen/core/domain/refuel_planner.dart';
import 'package:tankstellen/core/domain/refuel_trip_cost.dart';

/// glados' default 100 cases per property: cheap pure functions, run in
/// well under a second.
Generator<double> get price =>
    any.doubleInRange(0.5, 3.0).map((d) => (d * 1000).round() / 1000);

Generator<double> get distanceKm =>
    any.doubleInRange(0, 200).map((d) => (d * 10).round() / 10);

Generator<double> get consumption =>
    any.doubleInRange(3, 25).map((d) => (d * 10).round() / 10);

void main() {
  group('trip ledger (refuel_trip_cost.dart "Conservation, leg by leg")', () {
    Glados3(distanceKm, distanceKm, consumption).test(
      'end = start − consumed + dispensed, for every meaning',
      (out, back, c) {
        for (final q in const [
          RefuelPurchaseQuantity.dispensed(40),
          RefuelPurchaseQuantity.netIncrease(30),
          RefuelPurchaseQuantity.targetFinal(55),
        ]) {
          final cost = RefuelEconomics.tripCost(RefuelTripInput(
            outboundKm: out,
            returnKm: back,
            pricePerLitre: 1.8,
            consumptionLPer100km: c,
            quantity: q,
            startLitres: 60,
          )).cost;
          if (cost == null) continue; // an explicit blocker is valid
          expect(cost.endLitres,
              closeTo(60 - cost.consumedLitres + cost.litresDispensed, 1e-9));
          expect(cost.litresDispensed, greaterThanOrEqualTo(0));
          expect(cost.cashAtPump,
              closeTo(cost.litresDispensed * 1.8, 1e-9),
              reason: 'each purchased litre is paid exactly once');
        }
      },
    );

    Glados3(price, distanceKm, consumption).test(
      'a target final level is met exactly — equal end states by construction',
      (p, km, c) {
        final cost = RefuelEconomics.tripCost(RefuelTripInput(
          outboundKm: km / 2,
          returnKm: km / 2,
          pricePerLitre: p,
          consumptionLPer100km: c,
          quantity: const RefuelPurchaseQuantity.targetFinal(50),
          startLitres: 60,
        )).cost;
        if (cost == null) return;
        expect(cost.endLitres, closeTo(50, 1e-9));
      },
    );

    Glados3(price, distanceKm, consumption).test(
      'at equal price, driving further never saves money (#4088 again)',
      (p, km, c) {
        RefuelTripCost trip(double d) => RefuelEconomics.tripCost(
              RefuelTripInput(
                outboundKm: d / 2,
                returnKm: d / 2,
                pricePerLitre: p,
                consumptionLPer100km: c,
                quantity: const RefuelPurchaseQuantity.netIncrease(40),
              ),
            ).cost!;
        final saving = netSavingAtEqualEnd(trip(km + 1), trip(km));
        expect(saving, isNotNull);
        expect(saving!, lessThanOrEqualTo(1e-9));
      },
    );

    Glados3(price, price, distanceKm).test(
      'the net saving is antisymmetric — one reference, one number',
      (pA, pB, km) {
        RefuelTripCost trip(double p, double d) => RefuelEconomics.tripCost(
              RefuelTripInput(
                outboundKm: d,
                returnKm: d,
                pricePerLitre: p,
                consumptionLPer100km: 7,
                quantity: const RefuelPurchaseQuantity.netIncrease(40),
              ),
            ).cost!;
        final a = trip(pA, 1), b = trip(pB, km);
        expect(netSavingAtEqualEnd(a, b)! + netSavingAtEqualEnd(b, a)!,
            closeTo(0, 1e-9));
      },
    );
  });

  group('planner (refuel_planner.dart "Fuel is conserved on every leg")', () {
    RefuelPlanSet plans(double c, double pA, double pB, double detour) =>
        RefuelPlanner.plan(RefuelPlanRequest(
          routeKm: 600,
          drivingMinutes: 360,
          tankCapacityL: 55,
          startLitres: 30,
          consumptionLPer100km: c,
          candidates: [
            PlanCandidate(
                stationId: 'a',
                alongRouteKm: 120,
                pricePerLitre: pA,
                detourKm: detour),
            PlanCandidate(
                stationId: 'b', alongRouteKm: 330, pricePerLitre: pB),
            PlanCandidate(
                stationId: 'c',
                alongRouteKm: 480,
                pricePerLitre: pA,
                detourKm: detour / 2),
          ],
        ));

    Glados3(consumption, price, price).test(
      'start + bought − consumed = end, detours included',
      (c, pA, pB) {
        final set = plans(c, pA, pB, 4);
        for (final plan in [set.cheapest, set.fastest]) {
          if (plan == null) continue;
          expect(plan.endLitres,
              closeTo(plan.startLitres + plan.litresBought - plan.consumedLitres,
                  1e-6));
          expect(plan.consumedLitres,
              closeTo((600 + plan.detourKm) * c / 100, 1e-6),
              reason: 'the route and every access/rejoin leg burn fuel');
        }
      },
    );

    Glados3(consumption, price, price).test(
      'no stop arrives below the reserve, no purchase overflows, the '
      'destination keeps the reserve',
      (c, pA, pB) {
        final set = plans(c, pA, pB, 6);
        for (final plan in [set.cheapest, set.fastest]) {
          if (plan == null) continue;
          for (final stop in plan.stops) {
            expect(stop.arrivalLitres,
                greaterThanOrEqualTo(kDefaultReserveLitres - 1e-6));
            expect(stop.litres, greaterThanOrEqualTo(0));
            expect(stop.arrivalLitres + stop.litres,
                lessThanOrEqualTo(55 + 1e-6));
          }
          expect(plan.endLitres,
              greaterThanOrEqualTo(kDefaultReserveLitres - 1e-6));
        }
      },
    );

    Glados3(consumption, price, price).test(
      'at EQUAL terminal state the cheapest plan never costs more than the '
      'fastest (the old cash-only law compared different inventories)',
      (c, pA, pB) {
        final set = plans(c, pA, pB, 0);
        final cheap = set.cheapest, fast = set.fastest;
        if (cheap == null || fast == null) return;
        expect(set.comparableCost(cheap)!,
            lessThanOrEqualTo(set.comparableCost(fast)! + 1e-6));
      },
    );

    Glados3(consumption, price, distanceKm).test(
      'a longer detour never makes a plan cheaper at equal end state',
      (c, p, km) {
        RefuelPlanSet one(double detour) => RefuelPlanner.plan(
              RefuelPlanRequest(
                routeKm: 300,
                drivingMinutes: 200,
                tankCapacityL: 60,
                startLitres: 20,
                consumptionLPer100km: c,
                candidates: [
                  PlanCandidate(
                      stationId: 's',
                      alongRouteKm: 60,
                      pricePerLitre: p,
                      detourKm: detour),
                ],
              ),
            );
        final near = one(0), far = one(km / 20);
        if (near.cheapest == null || far.cheapest == null) return;
        expect(far.comparableCost(far.cheapest!)!,
            greaterThanOrEqualTo(near.comparableCost(near.cheapest!)! - 1e-6));
      },
    );
  });
}
