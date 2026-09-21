// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/map/presentation/widgets/station_map_layers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #4432 — one marker used to mean two different things.
///
/// `StationMapBody` drew a primary-colour circle at its `center`
/// unconditionally. In a proximity search that is the search origin and
/// reads correctly as "here". In route mode `RouteMapView` passes
/// `_routeBounds.center` — the bounding box of the FOUND STATIONS
/// (#2782/#2755) — so the same dot pointed at the middle of the results
/// and was read as the driver's position. A camera centre is not a
/// position claim.
void main() {
  // Three deliberately different points: the camera/bounds centre, the
  // route start, and the route destination.
  const boundsCentre = LatLng(45.95, 5.85);
  const routeStart = LatLng(45.7594, 5.6842); // Belley
  const routeEnd = LatLng(46.2044, 6.1432); // Geneva

  const seed = Station(
    id: 'seed',
    name: 'Seed',
    brand: 'Seed',
    street: '',
    postCode: '',
    place: 'Culoz',
    lat: 45.85,
    lng: 5.78,
    dist: 1,
    diesel: 1.7,
    isOpen: true,
  );

  Future<void> pumpLayers(
    WidgetTester tester, {
    required LatLng center,
    LatLng? originMarker,
    List<LatLng>? routePolyline,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StationMapLayers(
            mapController: MapController(),
            stations: const [seed],
            center: center,
            originMarker: originMarker,
            routePolyline: routePolyline,
            zoom: 9,
            searchRadiusKm: 10,
            selectedFuel: FuelType.diesel,
          ),
        ),
      ),
    );
  }

  /// Every marker currently in the layer tree, with its point.
  Iterable<Marker> markers(WidgetTester tester) => tester
      .widgetList<MarkerLayer>(find.byType(MarkerLayer))
      .expand((layer) => layer.markers);

  testWidgets(
      'a route map marks start and destination and claims no device '
      'position at the bounds centre', (tester) async {
    await pumpLayers(
      tester,
      center: boundsCentre,
      routePolyline: const [routeStart, LatLng(45.9, 5.8), routeEnd],
    );

    final all = markers(tester).toList();
    final start = all.where((m) => m.key == const ValueKey(
          'route-start-marker',
        ));
    final destination = all.where((m) => m.key == const ValueKey(
          'route-destination-marker',
        ));

    expect(start, hasLength(1));
    expect(destination, hasLength(1));
    expect(start.single.point, routeStart);
    expect(destination.single.point, routeEnd);

    // The one thing the field report's screenshot showed: NOTHING is
    // marked at the camera/bounds centre.
    expect(
      all.where((m) => m.point == boundsCentre),
      isEmpty,
      reason: 'the camera centre must not be rendered as a position',
    );
  });

  testWidgets('a proximity map still marks its origin at the centre',
      (tester) async {
    // Here `center` IS where the search was run from, so the marker
    // keeps its meaning and its old behaviour.
    await pumpLayers(
      tester,
      center: boundsCentre,
      originMarker: boundsCentre,
    );

    expect(
      markers(tester).where((m) => m.point == boundsCentre),
      isNotEmpty,
    );
  });

  testWidgets('no origin and no route means no position marker at all',
      (tester) async {
    await pumpLayers(tester, center: boundsCentre);

    expect(markers(tester).where((m) => m.point == boundsCentre), isEmpty);
  });
}
