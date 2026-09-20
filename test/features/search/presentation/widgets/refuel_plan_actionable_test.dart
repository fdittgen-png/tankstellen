// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4363 — a plan the driver can act on: real station names, the exact
/// quantity, the trade-off against the cheapest, and every caveat the
/// domain attached to the answer.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/money.dart';
import 'package:tankstellen/core/domain/refuel_plan.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';
import 'package:tankstellen/core/utils/unit_formatter.dart';
import 'package:tankstellen/features/search/presentation/widgets/refuel_plan_card.dart';
import 'package:tankstellen/features/search/providers/refuel_plan_candidates.dart';
import 'package:tankstellen/features/search/providers/refuel_plan_provider.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  const near = PlanCandidate(
    stationId: 'de-1',
    alongRouteKm: 100,
    pricePerLitre: 1.60,
    nativePrice: Money(1.60, 'EUR'),
    countryCode: 'DE',
    roadExtraKm: 4,
    roadExtraMinutes: 5,
  );
  const abroad = PlanCandidate(
    stationId: 'shell-dk-1',
    alongRouteKm: 260,
    pricePerLitre: 1.50,
    nativePrice: Money(11.25, 'DKK'),
    countryCode: 'DK',
    roadExtraKm: 2,
    roadExtraMinutes: 3,
  );

  const cheapPlan = RefuelPlan(
    stops: [
      PlannedStop(
          candidate: near, litres: 12, cost: 19.2, arrivalLitres: 8.4),
      PlannedStop(
          candidate: abroad, litres: 24, cost: 36, arrivalLitres: 5.5),
    ],
    fuelCost: 55.2,
    detourKm: 6,
    roadDetourMinutes: 8,
    routeKm: 400,
    drivingMinutes: 240,
    consumptionLPer100km: 10,
    startLitres: 15,
    consumedLitres: 40.6,
    endLitres: 5,
    currencyCode: 'EUR',
  );

  const quickPlan = RefuelPlan(
    stops: [
      PlannedStop(
          candidate: near, litres: 33, cost: 52.8, arrivalLitres: 8.4),
    ],
    fuelCost: 58.8,
    detourKm: 4,
    roadDetourMinutes: 5,
    routeKm: 400,
    drivingMinutes: 240,
    consumptionLPer100km: 10,
    startLitres: 15,
    consumedLitres: 40.4,
    endLitres: 5,
    currencyCode: 'EUR',
  );

  const names = {'de-1': 'Rasthof Hansa', 'shell-dk-1': 'Shell Kolding'};

  RefuelPlanState state({
    RefuelPlanSet plans = const RefuelPlanSet(
      cheapest: cheapPlan,
      fastest: quickPlan,
      leastDetour: quickPlan,
      currencyCode: 'EUR',
    ),
    PlanCandidateSet candidates = const PlanCandidateSet(
      candidates: [near, abroad],
      travelStops: [],
      exclusions: {},
      coverageIncomplete: false,
      stationNames: names,
    ),
  }) =>
      RefuelPlanState.ready(plans, candidates: candidates);

  Future<void> pumpCard(
    WidgetTester tester, {
    RefuelPlanState? planState,
    Size size = const Size(400, 1400),
    double textScale = 1,
    Locale? locale,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpApp(
      tester,
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: const SingleChildScrollView(child: RefuelPlanCard()),
      ),
      overrides: [
        refuelPlanProvider.overrideWithValue(planState ?? state()),
      ],
      locale: locale ?? const Locale('en'),
    );
  }

  group('the plan names what to do', () {
    testWidgets('each stop is a real station, in order, with its quantity',
        (tester) async {
      await pumpCard(tester);

      // Twice: the cheapest plan and the quicker one both stop there,
      // and each block names its own stops.
      expect(find.textContaining('Rasthof Hansa'), findsNWidgets(2));
      expect(find.textContaining('Shell Kolding'), findsOneWidget);
      // The quantity, its cost and the tank on arrival — the number that
      // proves the reserve held.
      expect(find.textContaining(UnitFormatter.formatVolume(12)),
          findsOneWidget);
      expect(find.textContaining(UnitFormatter.formatVolume(8.4)),
          findsNWidgets(2));
    });

    testWidgets('a stop abroad keeps its own pump price', (tester) async {
      await pumpCard(tester);
      // #4361 — the Danish price is shown natively beside the converted
      // total, never replaced by it.
      expect(
        find.textContaining(
            PriceFormatter.formatPrice(11.25, currencyOverride: 'DKK')),
        findsOneWidget,
      );
      // The domestic stop does not repeat its own price.
      expect(find.textContaining(PriceFormatter.formatPrice(1.60)),
          findsNothing);
    });

    testWidgets('an alternative states its trade-off as three figures',
        (tester) async {
      await pumpCard(tester);
      final trade = find.textContaining('Against the cheapest');
      expect(trade, findsOneWidget);
      final text = tester.widget<Text>(trade).data!;
      // Costs more money, saves time, drives less. Three facts, no score.
      expect(text, contains('+'));
      expect(text, contains('−'));
    });

    testWidgets('objectives that agree collapse into one block',
        (tester) async {
      await pumpCard(tester);
      expect(find.textContaining('Fastest trip'), findsOneWidget);
      expect(find.textContaining('Least extra driving'), findsOneWidget);
      // Both titles on one block: the quick plan's stop appears once.
      expect(find.textContaining(UnitFormatter.formatVolume(33)),
          findsOneWidget);
    });
  });

  group('caveats are attached to the answer, not implied', () {
    testWidgets('a bounded search never claims complete coverage',
        (tester) async {
      await pumpCard(
        tester,
        planState: state(
          plans: const RefuelPlanSet(
            cheapest: cheapPlan,
            searchWasBounded: true,
            currencyCode: 'EUR',
          ),
        ),
      );
      expect(find.textContaining('best of the itineraries compared'),
          findsOneWidget);
    });

    testWidgets('an ignored station makes the evidence incomplete',
        (tester) async {
      await pumpCard(
        tester,
        planState: state(
          candidates: const PlanCandidateSet(
            candidates: [near],
            travelStops: [],
            exclusions: {'de-9': PlanCandidateExclusion.ignoredByUser},
            coverageIncomplete: false,
            stationNames: names,
          ),
        ),
      );
      expect(find.textContaining('Some stations were left out'),
          findsOneWidget);
    });

    testWidgets('a reference price is explained, not silently dropped',
        (tester) async {
      await pumpCard(
        tester,
        planState: state(
          candidates: const PlanCandidateSet(
            candidates: [near],
            travelStops: [],
            exclusions: {'lu-1': PlanCandidateExclusion.referencePrice},
            coverageIncomplete: false,
            stationNames: names,
          ),
        ),
      );
      expect(find.textContaining('reference price'), findsOneWidget);
    });

    testWidgets('an approximate detour time says so', (tester) async {
      await pumpCard(
        tester,
        planState: state(
          plans: const RefuelPlanSet(
            cheapest: RefuelPlan(
              stops: [
                PlannedStop(
                    candidate: near, litres: 12, cost: 19.2,
                    arrivalLitres: 8.4),
              ],
              fuelCost: 19.2,
              detourKm: 6,
              approximateDetourKm: 6,
              routeKm: 400,
              drivingMinutes: 240,
              consumptionLPer100km: 10,
              currencyCode: 'EUR',
            ),
            currencyCode: 'EUR',
          ),
        ),
      );
      expect(find.textContaining('estimated from the route'), findsOneWidget);
    });
  });

  group('it holds up where a layout usually breaks', () {
    testWidgets('a narrow screen at double text size does not overflow',
        (tester) async {
      await pumpCard(tester,
          size: const Size(320, 3000), textScale: 2);
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Rasthof Hansa'), findsNWidgets(2));
    });

    testWidgets('it renders in German without an English fallback',
        (tester) async {
      await pumpCard(tester, locale: const Locale('de'));
      expect(find.textContaining('Rasthof Hansa'), findsNWidgets(2));
      expect(find.textContaining('Cheapest trip'), findsNothing);
      expect(find.textContaining('Least extra driving'), findsNothing);
    });
  });

  testWidgets('a no-stop plan still states distance, time and consumption',
      (tester) async {
    await pumpCard(
      tester,
      planState: state(
        plans: const RefuelPlanSet(
          cheapest: RefuelPlan(
            stops: [],
            fuelCost: 0,
            detourKm: 0,
            routeKm: 300,
            drivingMinutes: 200,
            consumptionLPer100km: 10,
            startLitres: 40,
            consumedLitres: 30,
            endLitres: 10,
            currencyCode: 'EUR',
          ),
          currencyCode: 'EUR',
        ),
      ),
    );
    expect(find.textContaining('No stop needed'), findsOneWidget);
    expect(find.textContaining(UnitFormatter.formatVolume(30)),
        findsOneWidget);
    expect(find.textContaining('300'), findsOneWidget);
  });
}
