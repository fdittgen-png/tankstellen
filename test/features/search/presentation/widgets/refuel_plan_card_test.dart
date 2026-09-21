// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/refuel_plan.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';
import 'package:tankstellen/features/search/presentation/widgets/refuel_plan_card.dart';
import 'package:tankstellen/features/search/providers/refuel_plan_provider.dart';

import '../../../../helpers/pump_app.dart';

/// #4146 — the plan card, and above all what it says when it cannot plan.
///
/// Range is the entire constraint the feature respects, so a missing tank
/// capacity or consumption produces a NAMED reason, never a guess
/// (economics spec §4.1). Those paths matter more than the happy one:
/// a plan built on an invented capacity would look identical to a real
/// one.
void main() {
  Future<void> pumpWith(WidgetTester tester, RefuelPlanState state) =>
      pumpApp(
        tester,
        const RefuelPlanCard(),
        overrides: [refuelPlanProvider.overrideWithValue(state)],
      );

  group('when it cannot plan, it says which input is missing', () {
    testWidgets('no consumption', (tester) async {
      await pumpWith(tester,
          const RefuelPlanState.blocked(RefuelPlanBlocker.noConsumption));
      expect(find.textContaining('fill-ups'), findsOneWidget);
    });

    testWidgets('no tank capacity', (tester) async {
      await pumpWith(tester,
          const RefuelPlanState.blocked(RefuelPlanBlocker.noTankCapacity));
      expect(find.textContaining('tank size'), findsOneWidget);
    });

    testWidgets('no priced station', (tester) async {
      await pumpWith(tester,
          const RefuelPlanState.blocked(RefuelPlanBlocker.noPricedStations));
      expect(find.textContaining('price for your fuel'), findsOneWidget);
    });
  });

  testWidgets('an unreachable route names the gap and shows no plan',
      (tester) async {
    // The one output that must never be dressed up as a recommendation:
    // a plan here would strand the driver.
    await pumpWith(
      tester,
      const RefuelPlanState.ready(RefuelPlanSet(
        gap: RefuelPlanGap(fromKm: 550, toKm: 700),
      )),
    );

    expect(find.textContaining('No station in range'), findsOneWidget);
    expect(find.textContaining('total'), findsNothing);
  });

  testWidgets('it shows BOTH plans, never one verdict', (tester) async {
    // `docs/specs/refuel-economics.md` §3 — cheapest and fastest are
    // genuinely different trips and the app does not choose for the
    // driver.
    const candidate = PlanCandidate(
      stationId: 'a', alongRouteKm: 100, pricePerLitre: 1.6,
    );
    const stop = PlannedStop(
      candidate: candidate, litres: 30, cost: 48, arrivalLitres: 10,
    );
    const plan = RefuelPlan(
      stops: [stop], fuelCost: 48, detourKm: 0, routeKm: 500,
      drivingMinutes: 300, consumptionLPer100km: 10,
    );

    await pumpWith(tester,
        const RefuelPlanState.ready(RefuelPlanSet(cheapest: plan, fastest: plan)));

    expect(find.textContaining('Cheapest trip'), findsOneWidget);
    expect(find.textContaining('Fastest trip'), findsOneWidget);
    // #4363 — the same itinerary answering two objectives is ONE result
    // carrying both titles. It used to be printed twice, which read as
    // two choices where there is one.
    expect(find.textContaining('1 stop'), findsOneWidget);
  });

  testWidgets('#4360 — the total is the pump cash, detour fuel NOT added '
      'a second time', (tester) async {
    // 6 km of detour at 10 L/100 km = 0.6 L, already bought inside the
    // 30 L at €1.60. The old total added 0.6 × 1.60 = €0.96 on top.
    const candidate = PlanCandidate(
      stationId: 'a', alongRouteKm: 100, pricePerLitre: 1.6, detourKm: 3,
    );
    const stop = PlannedStop(
      candidate: candidate, litres: 30, cost: 48, arrivalLitres: 10,
    );
    const plan = RefuelPlan(
      stops: [stop], fuelCost: 48, detourKm: 6, routeKm: 500,
      drivingMinutes: 300, consumptionLPer100km: 10,
    );

    await pumpWith(
        tester, const RefuelPlanState.ready(RefuelPlanSet(cheapest: plan)));

    // #4363 — a TOTAL is formatted as a total (two decimals), not with
    // the three-decimal per-litre mask the card used to borrow.
    expect(find.textContaining(PriceFormatter.formatTotal(48)), findsWidgets);
    expect(find.textContaining(PriceFormatter.formatTotal(48.96)), findsNothing);
  });

  testWidgets('a trip needing no stop says so rather than showing nothing',
      (tester) async {
    const plan = RefuelPlan(
      stops: [], fuelCost: 0, detourKm: 0, routeKm: 300,
      drivingMinutes: 200, consumptionLPer100km: 10,
    );

    await pumpWith(
        tester, const RefuelPlanState.ready(RefuelPlanSet(cheapest: plan)));

    // Zero is a real and good answer: the tank covers the trip.
    expect(find.textContaining('No stop needed'), findsOneWidget);
  });
}
