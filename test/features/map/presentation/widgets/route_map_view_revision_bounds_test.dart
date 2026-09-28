// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/map/presentation/widgets/route_map_view.dart';
import 'package:tankstellen/features/map/presentation/widgets/station_map_layers.dart';
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';
import 'package:tankstellen/features/route_search/domain/route_search_strategy.dart';
import 'package:tankstellen/features/route_search/providers/route_search_provider.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// #4432 checkpoint 2 — "Recompute route-dependent bounds when the route
/// revision changes … keep the camera stable for All/Best toggles and
/// partial updates of the same route."
///
/// `_routeBounds` used to be a `late final`: the SAME map state handed a
/// new search's result kept framing the previous route's stations.
void main() {
  Station stationAt(String id, double lat, double lng) => Station(
        id: id,
        name: 'S-$id',
        brand: 'Brand',
        street: 'Street',
        postCode: '00000',
        place: 'Place',
        lat: lat,
        lng: lng,
        isOpen: true,
        e10: 1.70,
      );

  // Route A: around Berlin. Route B: around Lyon — far apart, so a stale
  // frame is unmistakable.
  const routeA = [LatLng(52.40, 13.20), LatLng(52.80, 13.90)];
  const routeB = [LatLng(45.70, 4.80), LatLng(46.20, 6.10)];
  final stationsA = [stationAt('a1', 52.45, 13.30), stationAt('a2', 52.70, 13.80)];
  final stationsB = [stationAt('b1', 45.80, 5.00), stationAt('b2', 46.10, 6.00)];
  final laterB = stationAt('b3', 45.72, 4.82);

  RouteSearchRequest request(int revision) => RouteSearchRequest(
        revision: revision,
        waypoints: const [],
        fuelType: FuelType.e10,
        searchRadiusKm: 5,
        strategyType: RouteSearchStrategyType.uniform,
      );

  RouteSearchResult result(
    RouteInfo route,
    List<Station> stations, {
    required int revision,
    bool partial = false,
  }) =>
      RouteSearchResult(
        route: route,
        stations: stations.map((s) => FuelStationResult(s)).toList(),
        cheapestId: stations.isEmpty ? null : stations.first.id,
        cheapestPerSegment: null,
        isPartial: partial,
        request: request(revision),
      );

  RouteInfo info(List<LatLng> geometry) => RouteInfo(
        geometry: geometry,
        distanceKm: 100,
        durationMinutes: 80,
        samplePoints: geometry,
      );

  LatLngBounds boundsOf(List<Station> s) =>
      LatLngBounds.fromPoints([for (final x in s) LatLng(x.lat, x.lng)]);

  Future<ValueNotifier<RouteSearchResult>> pumpHost(
    WidgetTester tester,
    RouteSearchResult first,
    MapController controller,
  ) async {
    final notifier = ValueNotifier(first);
    addTearDown(notifier.dispose);
    final overrides = standardTestOverrides();
    when(() => overrides.mockStorage.getActiveProfileId()).thenReturn(null);
    await pumpApp(
      tester,
      SizedBox(
        width: 800,
        height: 1000,
        child: ValueListenableBuilder<RouteSearchResult>(
          valueListenable: notifier,
          // One RouteMapView element for the whole test: the state that
          // used to latch the bounds is the state under test.
          builder: (_, r, _) => RouteMapView(
            routeResult: r,
            selectedFuel: FuelType.e10,
            mapController: controller,
          ),
        ),
      ),
      overrides: overrides.overrides,
    );
    await tester.pumpAndSettle();
    return notifier;
  }

  LatLngBounds? fitOf(WidgetTester tester) =>
      tester.widget<StationMapLayers>(find.byType(StationMapLayers))
          .cameraFitBounds;

  testWidgets('a new route revision re-frames the camera on the new route',
      (tester) async {
    final controller = MapController();
    addTearDown(controller.dispose);
    final notifier = await pumpHost(
        tester, result(info(routeA), stationsA, revision: 1), controller);
    expect(fitOf(tester), boundsOf(stationsA));

    notifier.value = result(info(routeB), stationsB, revision: 2);
    await tester.pumpAndSettle();

    expect(fitOf(tester), boundsOf(stationsB),
        reason: 'revision 2 must not keep framing revision 1');
    final centre = controller.camera.center;
    expect(boundsOf(stationsB).contains(centre), isTrue,
        reason: 'the camera actually moved to the new route');
    expect(tester.takeException(), isNull);
  });

  testWidgets('partial batches of the SAME route do not move the frame',
      (tester) async {
    final controller = MapController();
    addTearDown(controller.dispose);
    final route = info(routeB);
    final notifier = await pumpHost(
      tester,
      result(route, stationsB, revision: 3, partial: true),
      controller,
    );
    final before = fitOf(tester);

    // A later batch of the same request brings one more station, south
    // west of the current frame.
    notifier.value = result(route, [...stationsB, laterB], revision: 3,
        partial: true);
    await tester.pumpAndSettle();
    notifier.value = result(route, [...stationsB, laterB], revision: 3);
    await tester.pumpAndSettle();

    expect(fitOf(tester), before,
        reason: 'same revision, same route: the camera holds');
  });

  testWidgets('a route first framed by its polyline re-frames once when '
      'its first stations arrive, then holds', (tester) async {
    final controller = MapController();
    addTearDown(controller.dispose);
    final route = info(routeB);
    final notifier = await pumpHost(
      tester,
      result(route, const [], revision: 4, partial: true),
      controller,
    );
    expect(fitOf(tester), LatLngBounds.fromPoints(routeB));

    notifier.value = result(route, stationsB, revision: 4, partial: true);
    await tester.pumpAndSettle();
    expect(fitOf(tester), boundsOf(stationsB));

    notifier.value = result(route, [...stationsB, laterB], revision: 4);
    await tester.pumpAndSettle();
    expect(fitOf(tester), boundsOf(stationsB));
  });

  testWidgets('a new route with no stations yet still leaves the old area',
      (tester) async {
    final controller = MapController();
    addTearDown(controller.dispose);
    final notifier = await pumpHost(
        tester, result(info(routeA), stationsA, revision: 5), controller);

    notifier.value =
        result(info(routeB), const [], revision: 6, partial: true);
    await tester.pumpAndSettle();

    expect(LatLngBounds.fromPoints(routeB).contains(controller.camera.center),
        isTrue,
        reason: 'the empty first batch of a new route must not leave the '
            'camera on the previous route');
  });

  testWidgets('a selection survives a new route only if its station does',
      (tester) async {
    final controller = MapController();
    addTearDown(controller.dispose);
    final route = info(routeB);
    final notifier = await pumpHost(
        tester, result(route, stationsB, revision: 7), controller);

    // Best stops preselects the best-stop stations (here: the cheapest).
    await tester.tap(find.text('Best stops'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<StationMapLayers>(find.byType(StationMapLayers))
          .selectedStationIds,
      contains('b1'),
    );

    // A new route that no longer contains b1.
    notifier.value =
        result(info(routeA), stationsA, revision: 8);
    await tester.pumpAndSettle();

    final selected = tester
        .widget<StationMapLayers>(find.byType(StationMapLayers))
        .selectedStationIds;
    expect(selected == null || !selected.contains('b1'), isTrue,
        reason: 'a stop of the replaced route is not carried into the new '
            'one as a launch waypoint');
  });
}
