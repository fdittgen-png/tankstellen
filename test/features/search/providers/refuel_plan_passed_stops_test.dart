// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4432 — "Apply the same eligibility contract to … planner/comparison
/// candidates." A stop the foreground listener has retired must leave
/// the PLAN's own candidate set, not only the list and the map: the plan
/// is built from the route result (#4362), so without this a stale
/// recommendation could route the driver back to a forecourt they
/// already drove past.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/refuel_economics.dart';
import 'package:tankstellen/core/domain/refuel_profile_provider.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/domain/tank_state_provider.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/core/utils/route_progress.dart';
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';
import 'package:tankstellen/features/route_search/domain/route_search_strategy.dart';
import 'package:tankstellen/features/route_search/providers/route_live_progress_provider.dart';
import 'package:tankstellen/features/route_search/providers/route_search_provider.dart';
import 'package:tankstellen/features/search/providers/refuel_plan_candidates.dart';
import 'package:tankstellen/features/search/providers/refuel_plan_provider.dart';
import 'package:tankstellen/features/search/providers/search_filters_provider.dart';
import 'package:tankstellen/features/search/providers/station_travel_estimates_provider.dart';

final _now = DateTime.utc(2026, 9, 17, 12);

void main() {
  // ~444 km due north, a vertex every 0.1°.
  final geometry = [
    for (var i = 0; i <= 40; i++) LatLng(44.0 + i / 10, 5.0),
  ];

  Station station(String id, double lat, double price) => Station(
        id: id,
        name: id,
        brand: 'TOTAL',
        street: 'R',
        postCode: '1',
        place: 'P',
        lat: lat,
        lng: 5.0,
        e10: price,
      );

  RouteSearchResult result(List<Station> stations, {int revision = 9}) =>
      RouteSearchResult(
        route: RouteInfo(
          geometry: geometry,
          distanceKm: 444,
          durationMinutes: 300,
          samplePoints: const [LatLng(45, 5)],
        ),
        stations: [for (final s in stations) FuelStationResult(s)],
        request: RouteSearchRequest(
          revision: revision,
          waypoints: const [],
          fuelType: FuelType.e10,
          searchRadiusKm: 5,
          strategyType: RouteSearchStrategyType.uniform,
        ),
      );

  // The cheapest station on the route sits ~22 km in; the driver is
  // now ~60 km along, so it is behind them.
  final stations = [
    station('cheap-behind', 44.2, 1.20),
    station('ahead', 44.9, 1.80),
    station('far-ahead', 46.5, 1.85),
  ];

  ProviderContainer container({
    required RouteSearchResult route,
    required RouteLiveProgress progress,
  }) =>
      ProviderContainer(overrides: [
        appClockProvider.overrideWithValue(FixedClock(_now)),
        routeSearchStateProvider.overrideWith(() => _FixedRoute(route)),
        refuelProfileProvider
            .overrideWithValue(const RefuelProfile(consumptionLPer100km: 10)),
        tankStateProvider
            .overrideWithValue(const TankState(capacityL: 50, currentL: 20)),
        selectedFuelTypeProvider.overrideWith(_FixedFuel.new),
        travelEstimateFetcherProvider
            .overrideWithValue((context, stops) async => const []),
        routeProgressSnapshotProvider
            .overrideWith(() => _FixedSnapshot(progress)),
      ]);

  test('a passed stop is excluded from the plan with its own reason', () {
    final c = container(
      route: result(stations),
      progress: const RouteLiveProgress(
        revision: 9,
        status: RouteProgressStatus.onRoute,
        retiredBeforeKm: 60,
      ),
    );
    addTearDown(c.dispose);

    final state = c.read(refuelPlanProvider);
    expect(state.candidates.exclusions['cheap-behind'],
        PlanCandidateExclusion.alreadyPassed);
    expect(
      state.candidates.candidates.map((x) => x.stationId),
      isNot(contains('cheap-behind')),
    );
    final stops = [
      ...?state.plans?.cheapest?.stops,
      ...?state.plans?.fastest?.stops,
    ].map((s) => s.candidate.stationId);
    expect(stops, isNot(contains('cheap-behind')),
        reason: 'the cheapest price on the route is behind the driver; '
            'recommending it means turning back');
    // Nor is it quoted: no road estimate is spent on a passed stop.
    expect(state.candidates.travelStops.map((s) => s.id),
        isNot(contains('cheap-behind')));
  });

  test('without progress the same station is a candidate — the exclusion '
      'is caused by retirement, not by the fixture', () {
    final c = container(
      route: result(stations),
      progress: RouteLiveProgress.inactive,
    );
    addTearDown(c.dispose);

    final state = c.read(refuelPlanProvider);
    expect(state.candidates.exclusions, isEmpty);
    expect(state.candidates.candidates.map((x) => x.stationId),
        contains('cheap-behind'));
  });

  test('progress recorded on another route retires nothing on this one',
      () {
    final c = container(
      route: result(stations, revision: 10),
      progress: const RouteLiveProgress(
        revision: 9,
        status: RouteProgressStatus.onRoute,
        retiredBeforeKm: 60,
      ),
    );
    addTearDown(c.dispose);

    expect(c.read(refuelPlanProvider).candidates.exclusions, isEmpty);
  });
}

class _FixedRoute extends RouteSearchState {
  _FixedRoute(this.value);

  final RouteSearchResult value;

  @override
  AsyncValue<RouteSearchResult?> build() => AsyncValue.data(value);
}

class _FixedFuel extends SelectedFuelType {
  @override
  FuelType build() => FuelType.e10;
}

class _FixedSnapshot extends RouteProgressSnapshot {
  _FixedSnapshot(this.value);

  final RouteLiveProgress value;

  @override
  RouteLiveProgress build() => value;
}
