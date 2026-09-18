// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4362 through the PRODUCTION provider path, which is where the defect
/// lived: the plan was built from a list that had already been filtered
/// for display, so a necessary expensive bridge stop could vanish before
/// feasibility was considered.
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
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';
import 'package:tankstellen/features/route_search/providers/route_search_provider.dart';
import 'package:tankstellen/features/search/providers/ignored_stations_provider.dart';
import 'package:tankstellen/features/search/providers/refuel_plan_candidates.dart';
import 'package:tankstellen/features/search/providers/refuel_plan_provider.dart';
import 'package:tankstellen/features/search/providers/search_filters_provider.dart';
import 'package:tankstellen/features/search/providers/station_travel_estimates_provider.dart';

final _now = DateTime.utc(2026, 9, 17, 12);

void main() {
  // ~444 km, one vertex every 0.1° so a station projects onto a vertex
  // beside it rather than tens of kilometres "off route".
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

  RouteSearchResult result(List<Station> stations) => RouteSearchResult(
        route: RouteInfo(
          geometry: geometry,
          distanceKm: 444,
          durationMinutes: 300,
          samplePoints: const [LatLng(45, 5)],
        ),
        stations: [for (final s in stations) FuelStationResult(s)],
      );

  ProviderContainer container({
    required RouteSearchResult route,
    double level = 20,
    List<String> ignored = const [],
  }) =>
      ProviderContainer(overrides: [
        appClockProvider.overrideWithValue(FixedClock(_now)),
        routeSearchStateProvider.overrideWith(() => _FixedRoute(route)),
        refuelProfileProvider
            .overrideWithValue(const RefuelProfile(consumptionLPer100km: 10)),
        tankStateProvider
            .overrideWithValue(TankState(capacityL: 50, currentL: level)),
        selectedFuelTypeProvider.overrideWith(_FixedFuel.new),
        ignoredStationsProvider.overrideWith(() => _FixedIgnored(ignored)),
        travelEstimateFetcherProvider
            .overrideWithValue((context, stops) async => const []),
      ]);

  group('hard exclusions are separated from soft filters', () {
    test('an expensive bridge station survives — nothing filters on price',
        () {
      // 20 L aboard, reserve 5 → 150 km of range. The only station inside
      // it is the dear one; the cheap one 330 km along cannot be reached
      // without it. A price filter would have deleted the bridge and the
      // journey would read as impossible.
      final c = container(
        route: result([
          station('dear-bridge', 45.2, 2.40),
          station('cheap-far', 46.9, 1.30),
        ]),
      );
      addTearDown(c.dispose);

      final state = c.read(refuelPlanProvider);
      expect(state.isReady, isTrue);
      expect(state.plans!.isFeasible, isTrue);
      expect(
        state.plans!.cheapest!.stops.map((s) => s.candidate.stationId),
        contains('dear-bridge'),
      );
      expect(state.candidates.exclusions, isEmpty);
      expect(state.evidenceIncomplete, isFalse);
    });

    test('an ignored station is respected, and the resulting gap is '
        'attributed to it', () {
      final c = container(
        route: result([
          station('dear-bridge', 45.2, 2.40),
          station('cheap-far', 46.9, 1.30),
        ]),
        ignored: const ['dear-bridge'],
      );
      addTearDown(c.dispose);

      final state = c.read(refuelPlanProvider);
      expect(state.candidates.exclusions['dear-bridge'],
          PlanCandidateExclusion.ignoredByUser);
      expect(state.candidates.candidates.map((x) => x.stationId),
          ['cheap-far']);
      expect(state.plans!.gap, isNotNull,
          reason: 'the hard choice stands, and the consequence is stated');
      expect(state.evidenceIncomplete, isTrue,
          reason: 'this gap is a fact about the allowed set, not the road');
    });

    test('a station with no price for the fuel is excluded with a reason',
        () {
      final c = container(
        route: result([
          station('priced', 45.2, 1.80),
          const Station(
            id: 'unpriced',
            name: 'unpriced',
            brand: 'B',
            street: 'R',
            postCode: '1',
            place: 'P',
            lat: 45.4,
            lng: 5.0,
          ),
        ]),
      );
      addTearDown(c.dispose);

      final state = c.read(refuelPlanProvider);
      expect(state.candidates.exclusions['unpriced'],
          PlanCandidateExclusion.noPriceForFuel);
      expect(state.candidates.candidates.single.stationId, 'priced');
    });
  });

  group('a no-stop journey is a first-class answer', () {
    test('a full tank plans zero stops even with no priced station', () {
      final c = container(route: result(const []), level: 50);
      addTearDown(c.dispose);

      final state = c.read(refuelPlanProvider);
      expect(state.isReady, isTrue);
      expect(state.plans!.cheapest!.stops, isEmpty);
      expect(state.plans!.cheapest!.consumedLitres, greaterThan(0),
          reason: 'zero pump spend is not zero consumption');
      expect(state.plans!.cheapest!.totalCost, 0);
    });

    test('an empty candidate set and a short tank is missing EVIDENCE, '
        'not a proven gap', () {
      final c = container(route: result(const []), level: 20);
      addTearDown(c.dispose);

      final state = c.read(refuelPlanProvider);
      expect(state.blocker, RefuelPlanBlocker.noPricedStations);
      expect(state.plans, isNull,
          reason: 'a gap would claim the road was checked');
    });
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

class _FixedIgnored extends IgnoredStations {
  _FixedIgnored(this.ids);

  final List<String> ids;

  @override
  List<String> build() => ids;
}
