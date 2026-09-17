// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/core/domain/refuel_economics.dart';
import 'package:tankstellen/core/domain/refuel_profile_provider.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/domain/tank_state_provider.dart';
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';
import 'package:tankstellen/features/route_search/providers/route_search_provider.dart';
import 'package:tankstellen/features/search/providers/refuel_plan_provider.dart';
import 'package:tankstellen/features/search/providers/search_filters_provider.dart';
import 'package:tankstellen/features/search/providers/station_travel_estimates_provider.dart';
import 'package:tankstellen/core/domain/travel_estimate.dart';
import 'package:tankstellen/core/domain/refuel_plan.dart';
import 'package:tankstellen/core/time/app_clock.dart';

/// #4146 — the provider's job is assembly, and saying what is missing.
///
/// The arithmetic is tested in `refuel_plan_test.dart`. What matters here
/// is that a missing input produces a NAMED reason instead of a guess:
/// range is the entire constraint the feature exists to respect, so a
/// default capacity or an assumed tank level would invent the answer
/// (economics spec §4.1).
final _now = DateTime.utc(2026, 9, 16, 12);

void main() {
  // Roughly 1° of latitude ≈ 111 km, so this route is ~444 km.
  final geometry = [
    for (var i = 0; i <= 4; i++) LatLng(44.0 + i, 5.0),
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

  RouteSearchResult result({List<Station> stations = const []}) =>
      RouteSearchResult(
        route: RouteInfo(
          geometry: geometry,
          distanceKm: 444,
          durationMinutes: 300,
          samplePoints: const [LatLng(45, 5)],
        ),
        stations: [for (final s in stations) FuelStationResult(s)],
      );

  ProviderContainer container({
    RouteSearchResult? route,
    double? consumption = 10,
    double? capacity = 50,
    double? level = 50,
    TravelEstimateFetcher? fetcher,
  }) =>
      ProviderContainer(overrides: [
        appClockProvider.overrideWithValue(FixedClock(_now)),
        routeSearchStateProvider.overrideWith(() => _FixedRoute(route)),
        refuelProfileProvider.overrideWithValue(
          RefuelProfile(consumptionLPer100km: consumption),
        ),
        tankStateProvider.overrideWithValue(
          TankState(capacityL: capacity, currentL: level),
        ),
        // The real one reads the profile out of Hive; the fuel choice is
        // not what these tests are about.
        selectedFuelTypeProvider.overrideWith(() => _FixedFuel()),
        // #4359 — no router in a unit test: every stop stays on its
        // explicitly approximate projection unless a case says otherwise.
        travelEstimateFetcherProvider
            .overrideWithValue(fetcher ?? (context, stops) async => const []),
      ]);

  group('it names what is missing', () {
    test('no route', () {
      final c = container(route: null);
      addTearDown(c.dispose);
      expect(c.read(refuelPlanProvider).blocker, RefuelPlanBlocker.noRoute);
    });

    test('no consumption — never a default', () {
      final c = container(route: result(), consumption: null);
      addTearDown(c.dispose);
      expect(c.read(refuelPlanProvider).blocker,
          RefuelPlanBlocker.noConsumption);
    });

    test('no tank capacity — never a default', () {
      // The one that matters most: a guessed capacity silently invents
      // the range constraint the whole feature is about.
      final c = container(route: result(), capacity: null);
      addTearDown(c.dispose);
      expect(c.read(refuelPlanProvider).blocker,
          RefuelPlanBlocker.noTankCapacity);
    });

    test('no tank level', () {
      final c = container(route: result(), level: null);
      addTearDown(c.dispose);
      expect(
          c.read(refuelPlanProvider).blocker, RefuelPlanBlocker.noTankLevel);
    });

    test('stations exist but none has a price for the selected fuel', () {
      final c = container(
        route: result(stations: const [
          Station(
            id: 'a', name: 'a', brand: 'b', street: 'r', postCode: '1',
            place: 'p', lat: 45, lng: 5,
          ),
        ]),
      );
      addTearDown(c.dispose);
      expect(c.read(refuelPlanProvider).blocker,
          RefuelPlanBlocker.noPricedStations);
    });
  });

  group('with everything present', () {
    test('it plans, and the stops are real stations in route order', () {
      final c = container(
        route: result(stations: [
          station('south', 44.5, 1.80),
          station('middle', 45.5, 1.60),
          station('north', 46.5, 1.70),
        ]),
        level: 20, // 150 km usable — a stop is required
      );
      addTearDown(c.dispose);

      final state = c.read(refuelPlanProvider);
      expect(state.isReady, isTrue);
      expect(state.plans!.isFeasible, isTrue);

      final ids = state.plans!.cheapest!.stops
          .map((s) => s.candidate.stationId)
          .toList();
      expect(ids, isNotEmpty);
      expect(ids.toSet().length, ids.length, reason: 'no station twice');

      // Positions come from the polyline, so the stops are ordered by
      // how far along the route they sit.
      final positions = state.plans!.cheapest!.stops
          .map((s) => s.candidate.alongRouteKm)
          .toList();
      final sorted = [...positions]..sort();
      expect(positions, sorted);
    });

    test('#4359 — a routed exit/rejoin replaces the vertex projection, and '
        'its routed minutes replace the average-speed guess', () async {
      TravelContext? asked;
      final c = container(
        route: result(stations: [station('middle', 45.5, 1.60)]),
        level: 20,
        fetcher: (context, stops) async {
          asked = context;
          return [
            for (final s in stops)
              StationTravelEstimate.routed(
                stationId: s.id,
                context: context,
                toStation: const TravelLeg(distanceKm: 170, durationMinutes: 120),
                fromStation:
                    const TravelLeg(distanceKm: 286, durationMinutes: 200),
                // 444 km / 300 min direct → +12 km / +20 min via the stop.
                baseline: const TravelLeg(distanceKm: 444, durationMinutes: 300),
                calculatedAt: _now,
              ),
          ];
        },
      );
      addTearDown(c.dispose);
      final sub = c.listen(refuelPlanProvider, (_, _) {});
      addTearDown(sub.close);

      expect(c.read(refuelPlanProvider).plans!.cheapest!.detourTimeIsApproximate,
          isTrue,
          reason: 'before the router answers the detour is approximate');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(asked!.purpose, TravelPurpose.stopOnJourney);
      final plan = c.read(refuelPlanProvider).plans!.cheapest!;
      final stop = plan.stops.single.candidate;
      expect(stop.roadExtraKm, closeTo(12, 1e-9));
      expect(plan.detourKm, closeTo(12, 1e-9),
          reason: 'the routed extra, not 2 × the vertex gap');
      expect(plan.detourTimeIsApproximate, isFalse);
      expect(plan.detourMinutes, closeTo(20 + kStopOverheadMinutes, 1e-9));
    });

    test('a tank that covers the route plans no stop at all', () {
      final c = container(
        route: result(stations: [station('mid', 45.5, 1.60)]),
        capacity: 200,
        level: 200,
      );
      addTearDown(c.dispose);

      expect(c.read(refuelPlanProvider).plans!.cheapest!.stops, isEmpty);
    });
  });
}

class _FixedFuel extends SelectedFuelType {
  @override
  FuelType build() => FuelType.e10;
}

class _FixedRoute extends RouteSearchState {
  _FixedRoute(this._result);
  final RouteSearchResult? _result;

  @override
  AsyncValue<RouteSearchResult?> build() => AsyncValue.data(_result);
}
