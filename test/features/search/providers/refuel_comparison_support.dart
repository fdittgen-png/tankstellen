// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Shared fixtures for the #4363 comparison tests — one container shape
/// for the provider tests and the card tests, so both drive the SAME
/// production provider.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/core/domain/exchange_rate_provider.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/money.dart';
import 'package:tankstellen/core/domain/refuel_comparison_selection.dart';
import 'package:tankstellen/core/domain/refuel_economics.dart';
import 'package:tankstellen/core/domain/refuel_profile_provider.dart';
import 'package:tankstellen/core/domain/refuel_quantity_provider.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/domain/tank_state_provider.dart';
import 'package:tankstellen/core/domain/travel_estimate.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';
import 'package:tankstellen/features/route_search/providers/route_input_provider.dart';
import 'package:tankstellen/features/route_search/providers/route_search_provider.dart';
import 'package:tankstellen/features/search/providers/refuel_travel_origin_provider.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';
import 'package:tankstellen/features/search/providers/station_travel_estimates_provider.dart';

Station fixtureStation(
  String id, {
  required double price,
  required double dist,
  String? name,
  double lat = 52.5,
  double lng = 13.4,
}) =>
    Station(
      id: id,
      name: name ?? id,
      // `displayName` prefers the brand, so the fixture's readable name
      // has to live there for a card test to find it.
      brand: name ?? id,
      street: 'R',
      postCode: '1',
      place: 'P',
      lat: lat,
      lng: lng,
      dist: dist,
      e10: price,
    );

/// A ~444 km route north along longitude 5, one vertex per 0.1°.
RouteSearchResult fixtureRoute({List<Station> stations = const []}) =>
    RouteSearchResult(
      route: RouteInfo(
        geometry: [for (var i = 0; i <= 40; i++) LatLng(44.0 + i / 10, 5.0)],
        distanceKm: 444,
        durationMinutes: 300,
        samplePoints: const [LatLng(45, 5)],
      ),
      stations: [for (final s in stations) FuelStationResult(s)],
    );

List<Override> comparisonOverrides({
  required DateTime now,
  double? quantity,
  TravelEstimateFetcher? fetcher,
  ExchangeRateSnapshot rates = const ExchangeRateSnapshot.empty(),
  List<Station> preselected = const [],
  RouteSearchResult? route,
  RefuelProfile profile =
      const RefuelProfile(consumptionLPer100km: 7, litresIntended: 40),
  TankState tank = const TankState(capacityL: 60, currentL: 20),
  List<LatLng?> routeStops = const [],
  TravelPoint? origin,
}) =>
    [
      appClockProvider.overrideWithValue(FixedClock(now)),
      selectedFuelTypeProvider.overrideWith(FixedFuel.new),
      refuelProfileProvider.overrideWithValue(profile),
      refuelQuantityProvider.overrideWith(() => FixedQuantity(quantity)),
      tankStateProvider.overrideWithValue(tank),
      searchStateProvider.overrideWith(NoSearch.new),
      routeSearchStateProvider.overrideWith(() => FixedRoute(route)),
      comparisonCurrencyProvider.overrideWithValue('EUR'),
      exchangeRatesProvider.overrideWithValue(rates),
      travelEstimateFetcherProvider
          .overrideWithValue(fetcher ?? (context, stops) async => const []),
      routeInputControllerProvider
          .overrideWith(() => FixedRouteInput(routeStops)),
      refuelTravelOriginProvider.overrideWith(() => FixedOrigin(origin)),
      if (preselected.isNotEmpty)
        refuelComparisonSelectionProvider
            .overrideWith(() => Preselected(preselected)),
    ];

class FixedFuel extends SelectedFuelType {
  @override
  FuelType build() => FuelType.e10;
}

/// A quantity choice that never touches storage.
class FixedQuantity extends RefuelQuantity {
  FixedQuantity(this.initial);

  final double? initial;

  @override
  double? build() => initial;

  @override
  Future<void> set(double? litres) async => state = litres;
}

class NoSearch extends SearchState {
  @override
  AsyncValue<ServiceResult<List<SearchResultItem>>> build() =>
      const AsyncValue.loading();
}

class FixedRoute extends RouteSearchState {
  FixedRoute(this.result);

  final RouteSearchResult? result;

  @override
  AsyncValue<RouteSearchResult?> build() => AsyncValue.data(result);
}

class FixedRouteInput extends RouteInputController {
  FixedRouteInput([this.stops = const []]);

  final List<LatLng?> stops;

  @override
  RouteInputState build() =>
      RouteInputState(stopCoords: stops, stopCount: stops.length);
}

class Preselected extends RefuelComparisonSelection {
  Preselected(this.initial);

  final List<Station> initial;

  @override
  List<Station> build() => initial;
}

/// A published search origin, without running a search (#4359).
class FixedOrigin extends RefuelTravelOrigin {
  FixedOrigin(this.initial);

  final TravelPoint? initial;

  @override
  TravelPoint? build() => initial;
}
