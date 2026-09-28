// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/core/domain/search_mode.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/route_search/api.dart';
import 'package:tankstellen/features/search/providers/station_off_route_provider.dart';
import 'package:tankstellen/features/search/providers/search_mode_provider.dart';

/// #4432 — the number a route row shows must be measured against THIS
/// route, not inherited from whichever sample-point query happened to
/// return the station first.
class _FixedRoute extends RouteSearchState {
  _FixedRoute(this._result);
  final RouteSearchResult? _result;

  @override
  AsyncValue<RouteSearchResult?> build() => AsyncValue.data(_result);
}

class _FixedMode extends ActiveSearchMode {
  _FixedMode(this._mode);
  final SearchMode _mode;

  @override
  SearchMode build() => _mode;
}

void main() {
  // Belley → Geneva.
  const corridor = [
    LatLng(45.7594, 5.6842),
    LatLng(45.8470, 5.7830),
    LatLng(45.9570, 5.8330),
    LatLng(46.2044, 6.1432),
  ];

  Station station(String id, double lat, double lng, {double dist = 1.2}) =>
      Station(
        id: id,
        name: id,
        brand: id,
        street: '',
        postCode: '',
        place: id,
        lat: lat,
        lng: lng,
        // The per-sample-point crow-flies figure the card used to show
        // unlabelled — deliberately wrong as an off-route offset.
        dist: dist,
        e10: 1.70,
        isOpen: true,
      );

  RouteSearchResult result({double firstSeenDist = 1.2}) => RouteSearchResult(
        route: const RouteInfo(
          geometry: corridor,
          distanceKm: 80,
          durationMinutes: 62,
          samplePoints: corridor,
        ),
        stations: [
          FuelStationResult(
              station('on-route', 45.8470, 5.7830, dist: firstSeenDist)),
          FuelStationResult(
              station('off-route', 45.8470, 5.8340, dist: firstSeenDist)),
        ],
        cheapestId: null,
        cheapestPerSegment: null,
        strategyType: RouteSearchStrategyType.uniform,
      );

  ProviderContainer container({
    RouteSearchResult? route,
    SearchMode mode = SearchMode.route,
  }) =>
      ProviderContainer(overrides: [
        routeSearchStateProvider.overrideWith(() => _FixedRoute(route)),
        activeSearchModeProvider.overrideWith(() => _FixedMode(mode)),
      ]);

  test('a route search publishes each stop\'s offset from the corridor', () {
    final c = container(route: result());
    addTearDown(c.dispose);

    final metrics = c.read(stationRouteMetricsProvider);
    expect(metrics.keys, containsAll(['on-route', 'off-route']));
    // A stop sitting ON a corridor vertex is not off the route at all.
    expect(metrics['on-route']!.offRouteKm, closeTo(0, 0.1));
    // The one to the side is — and it is NOT the station's own `dist`.
    expect(metrics['off-route']!.offRouteKm, greaterThan(2));
    expect(metrics['off-route']!.offRouteKm, isNot(closeTo(1.2, 0.01)));
  });

  test('each stop carries its along-route progress, distinct from its '
      'offset, stamped with the route revision', () {
    final c = container(route: result());
    addTearDown(c.dispose);

    final metrics = c.read(stationRouteMetricsProvider);
    // 'on-route' sits on the second corridor vertex, ~12.4 km from the
    // start; its progress is that distance, not its (zero) offset and
    // not its first-seen `dist`.
    final along = metrics['on-route']!.alongKm;
    expect(along, greaterThan(10));
    expect(along, lessThan(16));
    expect(along, isNot(closeTo(metrics['on-route']!.offRouteKm, 1)));
    // Both stations project onto the same stretch of road, so they are
    // met at nearly the same progress even though their offsets differ.
    expect(metrics['off-route']!.alongKm, closeTo(along, 3));
    // No request on the fixture → revision 0; a real search stamps its
    // own revision so a metric can never be read as another route's.
    expect(metrics['on-route']!.routeRevision, 0);
  });

  test(
      'the figure is the route\'s, so a different first-seen sample '
      'distance cannot change it', () {
    // The reported instability: `Station.dist` is whatever the query at
    // the sample point that returned the station first computed, and the
    // dedup keeps the first-seen object. The route metric must not care.
    final a = container(route: result(firstSeenDist: 1.2));
    final b = container(route: result(firstSeenDist: 13.9));
    addTearDown(a.dispose);
    addTearDown(b.dispose);

    expect(
      a.read(stationRouteMetricsProvider)['off-route']!.offRouteKm,
      closeTo(b.read(stationRouteMetricsProvider)['off-route']!.offRouteKm, 1e-9),
    );
  });

  test('a nearby search publishes nothing, even with a route in memory', () {
    // Otherwise a route result left in memory would relabel the
    // distances in a proximity list — the same lie in reverse.
    final c = container(route: result(), mode: SearchMode.nearby);
    addTearDown(c.dispose);

    expect(c.read(stationRouteMetricsProvider), isEmpty);
  });

  test('no route result yields an empty map', () {
    final c = container(route: null);
    addTearDown(c.dispose);

    expect(c.read(stationRouteMetricsProvider), isEmpty);
  });
}
