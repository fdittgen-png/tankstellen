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
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/map/presentation/widgets/route_map_view.dart';
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';
import 'package:tankstellen/features/route_search/domain/route_search_strategy.dart';
import 'package:tankstellen/features/route_search/providers/route_search_provider.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// #4432 — the route map shows the DEVICE, distinct from the route's
/// endpoints and never at the camera centre.
///
/// Three deliberately different points: the device fix (where GPS says
/// the phone is), the route start (where the router's polyline begins —
/// snapped to a road, so not the fix itself), and the station-bounds
/// centre the camera frames. A prior fix removed the dot that sat at the
/// bounds centre; this pins that the device is marked where it IS, and
/// only while the fix is current.
void main() {
  const deviceFix = LatLng(45.7610, 5.6800);
  const routeStart = LatLng(45.7594, 5.6842); // snapped onto the road
  const routeEnd = LatLng(46.2044, 6.1432);
  final measuredAt = DateTime(2026, 9, 20, 14);

  Station forecourt(String id, double lat, double lng) => Station(
        id: id,
        name: id,
        brand: id,
        street: '',
        postCode: '',
        place: id,
        lat: lat,
        lng: lng,
        dist: 1,
        e10: 1.7,
        isOpen: true,
      );

  // Their bounds centre (~45.90, 5.81) is none of the three points.
  final stations = [
    forecourt('culoz', 45.847, 5.783),
    forecourt('seyssel', 45.957, 5.833),
  ];

  RouteSearchResult result({required bool currentLocation}) =>
      RouteSearchResult(
        route: const RouteInfo(
          geometry: [routeStart, LatLng(45.9, 5.8), routeEnd],
          distanceKm: 80,
          durationMinutes: 60,
          samplePoints: [routeStart, routeEnd],
        ),
        stations: [for (final s in stations) FuelStationResult(s)],
        request: RouteSearchRequest(
          revision: 1,
          waypoints: [
            RouteWaypoint(
              lat: deviceFix.latitude,
              lng: deviceFix.longitude,
              label: 'Current location',
              isVehiclePosition: currentLocation,
            ),
            RouteWaypoint(
              lat: routeEnd.latitude,
              lng: routeEnd.longitude,
              label: 'Genève',
            ),
          ],
          fuelType: FuelType.e10,
          searchRadiusKm: 15,
          strategyType: RouteSearchStrategyType.uniform,
          originCapturedAt: currentLocation ? measuredAt : null,
        ),
      );

  Future<void> pumpMap(
    WidgetTester tester,
    RouteSearchResult r, {
    required DateTime now,
  }) async {
    final controller = MapController();
    addTearDown(controller.dispose);
    final test = standardTestOverrides();
    when(() => test.mockStorage.getActiveProfileId()).thenReturn(null);
    await pumpApp(
      tester,
      SizedBox(
        width: 800,
        height: 1000,
        child: RouteMapView(
          routeResult: r,
          selectedFuel: FuelType.e10,
          mapController: controller,
        ),
      ),
      overrides: [
        ...test.overrides,
        appClockProvider.overrideWithValue(FixedClock(now)),
      ],
    );
  }

  Iterable<Marker> markers(WidgetTester tester) => tester
      .widgetList<MarkerLayer>(find.byType(MarkerLayer))
      .expand((layer) => layer.markers);

  Marker? byKey(WidgetTester tester, String key) {
    final hits = markers(tester).where((m) => m.key == ValueKey(key));
    return hits.isEmpty ? null : hits.single;
  }

  LatLng boundsCentre() => LatLng(
        (stations[0].lat + stations[1].lat) / 2,
        (stations[0].lng + stations[1].lng) / 2,
      );

  testWidgets(
      'a current fix is marked at the DEVICE — not at the route start, '
      'not at the bounds centre', (tester) async {
    await pumpMap(tester, result(currentLocation: true),
        now: measuredAt.add(const Duration(seconds: 30)));

    final device = byKey(tester, 'origin-marker');
    expect(device, isNotNull);
    expect(device!.point, deviceFix);
    expect(byKey(tester, 'route-start-marker')!.point, routeStart);
    expect(byKey(tester, 'route-destination-marker')!.point, routeEnd);

    expect(device.point, isNot(boundsCentre()));
    expect(
      markers(tester).where((m) => m.point == boundsCentre()),
      isEmpty,
      reason: 'the camera centre is never rendered as a position',
    );
  });

  testWidgets('a fix older than the freshness bound is no device marker',
      (tester) async {
    await pumpMap(tester, result(currentLocation: true),
        now: measuredAt.add(const Duration(minutes: 10)));

    expect(byKey(tester, 'origin-marker'), isNull);
    // The route's own endpoints are still drawn.
    expect(byKey(tester, 'route-start-marker'), isNotNull);
  });

  testWidgets('a NAMED origin is never drawn as the device position',
      (tester) async {
    await pumpMap(tester, result(currentLocation: false), now: measuredAt);

    expect(byKey(tester, 'origin-marker'), isNull);
    expect(markers(tester).where((m) => m.point == deviceFix), isEmpty);
  });
}
