// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4367 through the PRODUCTION provider path.
///
/// The arithmetic is pinned in `vehicle_trip_comparison_test.dart`. What
/// matters here is what only the wiring can be wrong about: that each
/// column is planned from ITS vehicle's fuel and tank, that the
/// single-vehicle planner and the comparison cannot disagree, and that a
/// late road quote for a superseded selection cannot land on the visible
/// answer.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/core/domain/comparison_eligibility.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/refuel_economics.dart';
import 'package:tankstellen/core/domain/refuel_profile_provider.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/domain/tank_state_provider.dart';
import 'package:tankstellen/core/domain/travel_estimate.dart';
import 'package:tankstellen/core/domain/vehicle_comparison_key.dart';
import 'package:tankstellen/core/domain/vehicle_trip_providers.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';
import 'package:tankstellen/features/route_search/providers/route_search_provider.dart';
import 'package:tankstellen/features/search/providers/ignored_stations_provider.dart';
import 'package:tankstellen/features/search/providers/refuel_plan_provider.dart';
import 'package:tankstellen/features/search/providers/search_filters_provider.dart';
import 'package:tankstellen/features/search/providers/station_travel_estimates_provider.dart';
import 'package:tankstellen/features/search/providers/vehicle_trip_comparison_provider.dart';

final _now = DateTime.utc(2026, 9, 20, 8);

void main() {
  // ~444 km, one vertex every 0.1° so a station projects onto a vertex
  // beside it rather than tens of kilometres "off route".
  final geometry = [
    for (var i = 0; i <= 40; i++) LatLng(44.0 + i / 10, 5.0),
  ];

  Station station(String id, double lat, {double? e10, double? diesel}) =>
      Station(
        id: id,
        name: 'Station $id',
        brand: 'TOTAL',
        street: 'R',
        postCode: '1',
        place: 'P',
        lat: lat,
        lng: 5.0,
        e10: e10,
        diesel: diesel,
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

  VehicleTripBasis basis(
    String id, {
    required double? consumption,
    double? capacity = 50,
    double? start = 50,
    FuelType? fuel = FuelType.e10,
  }) =>
      VehicleTripBasis(
        vehicleId: id,
        vehicleName: id.toUpperCase(),
        fuel: fuel,
        capacityL: capacity,
        startLitres: start,
        consumptionLPer100km: consumption,
        consumptionSource: TripInputSource.measured,
        levelSource: TripInputSource.measured,
      );

  ComparedVehicleBases basesOf(List<VehicleTripBasis> bases) =>
      ComparedVehicleBases(
        key: VehicleComparisonKey(
            vehicleIds: [for (final b in bases) b.vehicleId]),
        bases: bases,
        referenceVehicleId: bases.isEmpty ? null : bases.first.vehicleId,
      );

  ProviderContainer container({
    required RouteSearchResult? route,
    required List<VehicleTripBasis> bases,
    TravelEstimateFetcher? fetcher,
    RefuelProfile activeProfile = const RefuelProfile(),
    TankState activeTank = const TankState(capacityL: null, currentL: null),
  }) =>
      ProviderContainer(overrides: [
        appClockProvider.overrideWithValue(FixedClock(_now)),
        routeSearchStateProvider.overrideWith(() => _FixedRoute(route)),
        selectedFuelTypeProvider.overrideWith(_FixedFuel.new),
        ignoredStationsProvider.overrideWith(() => _FixedIgnored(const [])),
        _bases.overrideWith(() => _Bases(basesOf(bases))),
        comparedVehicleBasesProvider.overrideWith((ref) => ref.watch(_bases)),
        refuelProfileProvider.overrideWithValue(activeProfile),
        tankStateProvider.overrideWithValue(activeTank),
        travelEstimateFetcherProvider
            .overrideWithValue(fetcher ?? (context, stops) async => const []),
      ]);

  group('it names what is missing', () {
    test('no route', () {
      final c = container(route: null, bases: [
        basis('a', consumption: 6),
        basis('b', consumption: 8),
      ]);
      addTearDown(c.dispose);
      expect(c.read(vehicleTripComparisonProvider).blocker,
          VehicleTripComparisonBlocker.noRoute);
    });

    test('fewer than two vehicles', () {
      final c = container(
          route: result([station('s', 45, e10: 1.80)]),
          bases: [basis('a', consumption: 6)]);
      addTearDown(c.dispose);
      expect(c.read(vehicleTripComparisonProvider).blocker,
          VehicleTripComparisonBlocker.notEnoughVehicles);
    });
  });

  group('a valid comparison', () {
    test('plans one column per vehicle, each from its own consumption', () {
      final c = container(
        route: result([station('mid', 45.0, e10: 1.80)]),
        bases: [
          basis('a', consumption: 6),
          basis('b', consumption: 8),
        ],
      );
      addTearDown(c.dispose);

      final comparison = c.read(vehicleTripComparisonProvider).comparison!;
      expect(comparison.columns.map((x) => x.vehicleId), ['a', 'b']);
      final a = comparison.columnFor('a')!;
      final b = comparison.columnFor('b')!;
      // ~444 km: A burns ~26.7 L, B burns ~35.6 L. B is the thirstier
      // car, and its cost to drive is higher at the same pump price.
      expect(a.fuelUsedLitres.valueOrNull!,
          lessThan(b.fuelUsedLitres.valueOrNull!));
      expect(a.costToDrive.valueOrNull!.amount,
          lessThan(b.costToDrive.valueOrNull!.amount));
      expect(comparison.lowestCostToDrive.valueOrNull, 'a');
    });

    test('the station names travel with the answer', () {
      final c = container(
        route: result([station('mid', 45.0, e10: 1.80)]),
        bases: [
          basis('a', consumption: 10, start: 20),
          basis('b', consumption: 12, start: 20),
        ],
      );
      addTearDown(c.dispose);
      final state = c.read(vehicleTripComparisonProvider);
      expect(state.stationNames['mid'], 'Station mid');
      expect(state.comparison!.columnFor('a')!.stationIds, contains('mid'));
    });
  });

  group('a partial comparison: each column sees only ITS fuel', () {
    test('a diesel car on a petrol-only route gets no fuel cost, and the '
        'petrol car keeps its own', () {
      final c = container(
        route: result([station('mid', 45.0, e10: 1.80)]),
        bases: [
          basis('petrol', consumption: 6),
          basis('diesel', consumption: 5, fuel: FuelType.diesel),
        ],
      );
      addTearDown(c.dispose);

      final comparison = c.read(vehicleTripComparisonProvider).comparison!;
      final diesel = comparison.columnFor('diesel')!;
      expect(diesel.costToDrive.eligibility, MetricEligibility.unavailable);
      expect(diesel.costToDrive.reason,
          ComparisonUnavailableReason.missingPrices);
      expect(diesel.costToDrive.valueOrNull, isNull,
          reason: 'no price is not a free drive');
      // The petrol column is unaffected.
      expect(comparison.columnFor('petrol')!.costToDrive.valueOrNull,
          isNotNull);
      // And with one comparable column the winner is withheld, not
      // awarded to the car nobody could price.
      expect(comparison.lowestCostToDrive.eligibility,
          MetricEligibility.unavailable);
    });

    test('a cross-fuel route prices each column at its own grade', () {
      final c = container(
        route: result([
          station('mid', 45.0, e10: 1.80, diesel: 1.60),
        ]),
        bases: [
          basis('petrol', consumption: 6),
          basis('diesel', consumption: 6, fuel: FuelType.diesel),
        ],
      );
      addTearDown(c.dispose);

      final comparison = c.read(vehicleTripComparisonProvider).comparison!;
      expect(comparison.columnFor('petrol')!.valuationPricePerLitre, 1.80);
      expect(comparison.columnFor('diesel')!.valuationPricePerLitre, 1.60);
    });
  });

  group('invalid input', () {
    test('a vehicle with no consumption on record is explained, never '
        'defaulted', () {
      final c = container(
        route: result([station('mid', 45.0, e10: 1.80)]),
        bases: [
          basis('known', consumption: 6),
          basis('blank', consumption: null),
        ],
      );
      addTearDown(c.dispose);

      final blank =
          c.read(vehicleTripComparisonProvider).comparison!.columnFor('blank')!;
      expect(blank.unavailable, ComparisonUnavailableReason.noEvidence);
      expect(blank.plan, isNull);
      expect(blank.fuelUsedLitres.valueOrNull, isNull);
    });

    test('a vehicle whose fuel is not sold by the litre is refused, not '
        'relabelled', () {
      final c = container(
        route: result([station('mid', 45.0, e10: 1.80)]),
        bases: [
          basis('petrol', consumption: 6),
          basis('ev', consumption: 18, fuel: FuelType.electric),
        ],
      );
      addTearDown(c.dispose);

      final ev =
          c.read(vehicleTripComparisonProvider).comparison!.columnFor('ev')!;
      expect(ev.unavailable, ComparisonUnavailableReason.unsupportedUnit);
      expect(ev.fuelUsedLitres.valueOrNull, isNull);
    });
  });

  group('the single-vehicle planner and the comparison cannot disagree', () {
    test('the same inputs give the same plan on both surfaces', () {
      final route = result([
        station('south', 44.5, e10: 1.80),
        station('middle', 45.5, e10: 1.60),
        station('north', 46.5, e10: 1.70),
      ]);
      // The active vehicle's single-vehicle inputs and column A's basis
      // are the same numbers, entered through the two different seams.
      final c = container(
        route: route,
        bases: [
          basis('a', consumption: 10, capacity: 50, start: 20),
          basis('b', consumption: 12, capacity: 50, start: 20),
        ],
        activeProfile: const RefuelProfile(consumptionLPer100km: 10),
        activeTank: const TankState(capacityL: 50, currentL: 20),
      );
      addTearDown(c.dispose);

      final single = c.read(refuelPlanProvider).plans!.cheapest!;
      final column =
          c.read(vehicleTripComparisonProvider).comparison!.columnFor('a')!;
      final compared = column.plan!;

      expect(
        compared.stops.map((s) => s.candidate.stationId),
        single.stops.map((s) => s.candidate.stationId),
      );
      expect(compared.fuelCost, single.fuelCost);
      expect(compared.consumedLitres, single.consumedLitres);
      expect(compared.endLitres, single.endLitres);
      expect(compared.totalMinutes, single.totalMinutes);
      expect(compared.detourKm, single.detourKm);
    });
  });

  group('a stale asynchronous result cannot overwrite a newer selection',
      () {
    test('the fresh quote is applied and the superseded one is not',
        () async {
      // Selection 1 is {a petrol, b diesel} and asks about both
      // forecourts; selection 2 is {a petrol, c petrol} and asks about
      // one. Different stop lists, so a different #4359 request — the
      // first answer can only resolve into a provider nothing watches.
      final gate = Completer<List<StationTravelEstimate>>();
      final asked = <List<TravelStop>>[];
      TravelContext? firstContext;
      final c = container(
        route: result([
          station('mid', 45.0, e10: 1.80),
          station('late', 46.0, diesel: 1.70),
        ]),
        bases: [
          basis('a', consumption: 10, start: 20),
          basis('b', consumption: 8, start: 20, fuel: FuelType.diesel),
        ],
        fetcher: (context, stops) {
          asked.add(stops);
          if (asked.length == 1) {
            firstContext = context;
            return gate.future;
          }
          return Future.value([
            StationTravelEstimate.routed(
              stationId: 'mid',
              context: context,
              toStation:
                  const TravelLeg(distanceKm: 170, durationMinutes: 120),
              fromStation:
                  const TravelLeg(distanceKm: 286, durationMinutes: 200),
              baseline:
                  const TravelLeg(distanceKm: 444, durationMinutes: 300),
              calculatedAt: _now,
            ),
          ]);
        },
      );
      addTearDown(c.dispose);
      final sub = c.listen(vehicleTripComparisonProvider, (_, _) {});
      addTearDown(sub.close);

      expect(c.read(vehicleTripComparisonProvider).quotesPending, isTrue);
      expect(asked.single.map((s) => s.id), containsAll(['mid', 'late']));

      // The driver drops the diesel and picks another petrol car.
      c.read(_bases.notifier).set(basesOf([
            basis('a', consumption: 10, start: 20),
            basis('c', consumption: 7, start: 20),
          ]));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(asked.length, 2, reason: 'a new selection is a new request');
      expect(asked.last.map((s) => s.id), ['mid']);

      final fresh = c.read(vehicleTripComparisonProvider).comparison!;
      expect(fresh.columns.map((x) => x.vehicleId), ['a', 'c']);
      expect(fresh.columnFor('a')!.plan!.stops.single.candidate.roadExtraKm,
          closeTo(12, 1e-9),
          reason: 'the CURRENT quote is applied — the control that makes '
              'the next assertion mean something');

      // Only now does the superseded request answer, claiming a detour
      // ten times the size at the same station.
      gate.complete([
        StationTravelEstimate.routed(
          stationId: 'mid',
          context: firstContext!,
          toStation: const TravelLeg(distanceKm: 400, durationMinutes: 400),
          fromStation:
              const TravelLeg(distanceKm: 400, durationMinutes: 400),
          baseline: const TravelLeg(distanceKm: 444, durationMinutes: 300),
          calculatedAt: _now,
        ),
      ]);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final after = c.read(vehicleTripComparisonProvider).comparison!;
      expect(after.columns.map((x) => x.vehicleId), ['a', 'c'],
          reason: 'the newer selection is still what is on screen');
      expect(after.columnFor('b'), isNull);
      expect(after.columnFor('a')!.plan!.stops.single.candidate.roadExtraKm,
          closeTo(12, 1e-9),
          reason: 'the stale answer never became a detour');
    });
  });
}

/// The compared vehicles, mutable so a test can change the selection
/// mid-flight the way the driver does.
final _bases = NotifierProvider<_Bases, ComparedVehicleBases>(
    () => _Bases(ComparedVehicleBases()));

class _Bases extends Notifier<ComparedVehicleBases> {
  _Bases(this._initial);
  final ComparedVehicleBases _initial;

  @override
  ComparedVehicleBases build() => _initial;

  // ignore: use_setters_to_change_properties
  void set(ComparedVehicleBases next) => state = next;
}

class _FixedFuel extends SelectedFuelType {
  @override
  FuelType build() => FuelType.e10;
}

class _FixedIgnored extends IgnoredStations {
  _FixedIgnored(this._ids);
  final List<String> _ids;

  @override
  List<String> build() => _ids;
}

class _FixedRoute extends RouteSearchState {
  _FixedRoute(this._result);
  final RouteSearchResult? _result;

  @override
  AsyncValue<RouteSearchResult?> build() => AsyncValue.data(_result);
}
