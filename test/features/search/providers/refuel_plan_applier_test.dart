// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4363 — applying a plan goes through one injected launcher, gated
/// exactly as every station action is (#4348), and never drops the stops
/// the driver already put on the route.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/domain/refuel_plan.dart';
import 'package:tankstellen/features/route_search/providers/route_input_provider.dart';
import 'package:tankstellen/features/route_search/providers/route_search_provider.dart';
import 'package:tankstellen/features/search/providers/refuel_plan_applier.dart';
import 'package:tankstellen/features/search/providers/refuel_plan_candidates.dart';

import 'refuel_comparison_support.dart';

void main() {
  PlanCandidate candidate(String id, double km) => PlanCandidate(
        stationId: id,
        alongRouteKm: km,
        pricePerLitre: 1.6,
      );

  RefuelPlan plan(List<PlanCandidate> stops) => RefuelPlan(
        stops: [
          for (final c in stops)
            PlannedStop(candidate: c, litres: 10, cost: 16, arrivalLitres: 8),
        ],
        fuelCost: 16.0 * stops.length,
        detourKm: 0,
        routeKm: 444,
        drivingMinutes: 300,
        consumptionLPer100km: 10,
      );

  /// Stops sit on the route's own line (lng 5) so their projection is
  /// exactly where the plan says they are.
  PlanCandidateSet candidates(Map<String, double> latById) =>
      PlanCandidateSet(
        candidates: const [],
        travelStops: [
          for (final e in latById.entries) (id: e.key, lat: e.value, lng: 5.0),
        ],
        exclusions: const {},
        coverageIncomplete: false,
      );

  late List<RefuelPlanLaunch> launched;

  ProviderContainer container({
    bool withRoute = true,
    List<LatLng?> existingStops = const [],
    bool launchOk = true,
  }) {
    launched = [];
    final c = ProviderContainer(overrides: [
      routeSearchStateProvider
          .overrideWith(() => FixedRoute(withRoute ? fixtureRoute() : null)),
      routeInputControllerProvider
          .overrideWith(() => FixedRouteInput(existingStops)),
      refuelPlanLauncherProvider.overrideWithValue((launch) async {
        launched.add(launch);
        return launchOk;
      }),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('the launcher receives the plan stops in route order, with the '
      "driver's existing stop kept in its place", () async {
    // Existing stop at lat 46.0 (~222 km); plan stops at ~133 km and
    // ~333 km. The order handed over must be 133 → 222 → 333.
    final c = container(existingStops: const [LatLng(46.0, 5.0), null]);
    final result = await c.read(refuelPlanApplierProvider).apply(
          plan([candidate('de-late', 333), candidate('de-early', 133)]),
          candidates({'de-late': 47.0, 'de-early': 45.2}),
        );

    expect(result.isLaunched, isTrue);
    expect(launched, hasLength(1));
    final w = launched.single.waypoints;
    expect(w.map((x) => x.stationId), ['de-early', null, 'de-late']);
    expect(w[1].isPlanStop, isFalse, reason: "the driver's own stop survives");
    expect(launched.single.planStops.length, 2);
    expect(launched.single.originLat, 44.0);
    expect(launched.single.destinationLat, 48.0);
  });

  test('a reference price stop is refused before anything launches', () async {
    final lu = Countries.byCode('LU')!.stationIdPrefixes.first;
    final c = container();
    final result = await c.read(refuelPlanApplierProvider).apply(
          plan([candidate('${lu}centroid', 200)]),
          candidates({'${lu}centroid': 46.0}),
        );
    expect(result.refusal, RefuelPlanApplyRefusal.referenceLocation);
    expect(launched, isEmpty);
  });

  test("a stop whose country's provider is unavailable is refused", () async {
    final au = Countries.byCode('AU')!.stationIdPrefixes.first;
    final c = container();
    final result = await c.read(refuelPlanApplierProvider).apply(
          plan([candidate('${au}dead', 200)]),
          candidates({'${au}dead': 46.0}),
        );
    expect(result.refusal, RefuelPlanApplyRefusal.providerUnavailable);
    expect(launched, isEmpty);
  });

  test('no active route, no launch', () async {
    final c = container(withRoute: false);
    final result = await c.read(refuelPlanApplierProvider).apply(
          plan([candidate('de-1', 100)]),
          candidates({'de-1': 45.0}),
        );
    expect(result.refusal, RefuelPlanApplyRefusal.noRoute);
    expect(launched, isEmpty);
  });

  test('a platform refusal is reported, not swallowed', () async {
    final c = container(launchOk: false);
    final result = await c.read(refuelPlanApplierProvider).apply(
          plan([candidate('de-1', 100)]),
          candidates({'de-1': 45.0}),
        );
    expect(result.refusal, RefuelPlanApplyRefusal.launchFailed);
    expect(launched, hasLength(1), reason: 'it was attempted');
  });
}
