// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/widgets/empty_state.dart';
import 'package:tankstellen/features/itinerary/domain/entities/saved_itinerary.dart';
import 'package:tankstellen/features/itinerary/providers/itinerary_provider.dart';
import 'package:tankstellen/features/map/presentation/widgets/route_best_stops_list.dart';
import 'package:tankstellen/features/map/presentation/widgets/route_info_bar.dart';
import 'package:tankstellen/features/map/presentation/widgets/route_map_view.dart';
import 'package:tankstellen/features/map/presentation/widgets/station_map_layers.dart';
import 'package:tankstellen/core/widgets/selectable_pill.dart';
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';
import 'package:tankstellen/features/route_search/providers/route_search_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

import '../../../../fixtures/stations.dart';
import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// Widget tests for [RouteMapView] — the route-map screen that renders
/// stations along a chosen driving route, supporting "All stations" and
/// "Best stops" view modes plus save-route and open-in-maps actions.
///
/// Covers the public surface:
///   - Empty state when both stations and geometry are missing.
///   - View-mode toggle (all vs best-stops) and chip selection.
///   - Save-route dialog flow, including cancel + submit paths.
///   - Station-count label wording for both view modes.
///   - The `RouteBestStopsList` only appearing in best-stops mode.
void main() {
  // Polyline used in the happy-path tests — a short Berlin-area track so the
  // center/zoom helpers pick a sensible value without needing real map tiles.
  final polyline = <LatLng>[
    const LatLng(52.52, 13.40),
    const LatLng(52.53, 13.42),
    const LatLng(52.54, 13.44),
  ];

  RouteSearchResult buildResult({
    List<Station> stations = const [],
    List<LatLng>? geometry,
    String? cheapestId,
    Map<int, String>? cheapestPerSegment,
    double distanceKm = 120,
    double durationMinutes = 90,
  }) {
    return RouteSearchResult(
      route: RouteInfo(
        geometry: geometry ?? polyline,
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        samplePoints: geometry ?? polyline,
      ),
      stations: stations.map((s) => FuelStationResult(s)).toList(),
      cheapestId: cheapestId,
      cheapestPerSegment: cheapestPerSegment,
    );
  }

  Widget buildHost(RouteSearchResult result, MapController controller) {
    // Wrap in a sized parent so the Column + Expanded layout gets real
    // constraints; FlutterMap needs finite height to lay out.
    return SizedBox(
      width: 800,
      height: 1000,
      child: RouteMapView(
        routeResult: result,
        selectedFuel: FuelType.e10,
        mapController: controller,
      ),
    );
  }

  group('RouteMapView empty state', () {
    testWidgets(
      'renders EmptyState when both stations and geometry are empty',
      (tester) async {
        final controller = MapController();
        addTearDown(controller.dispose);

        final overrides = standardTestOverrides();
        when(() => overrides.mockStorage.getActiveProfileId())
            .thenReturn(null);

        await pumpApp(
          tester,
          buildHost(
            buildResult(stations: const [], geometry: const []),
            controller,
          ),
          overrides: overrides.overrides,
        );

        expect(find.byType(EmptyState), findsOneWidget);
        // EmptyState renders the title + a "Back to search" action button.
        expect(find.text('No stations found along route'), findsOneWidget);
        expect(find.text('Search'), findsOneWidget);
        // Map-specific widgets MUST NOT render in the empty branch.
        expect(find.byType(RouteInfoBar), findsNothing);
        expect(find.byType(SelectablePill), findsNothing);
      },
    );

    testWidgets(
      'renders the map (not EmptyState) when geometry exists but stations do '
      'not — a routable track with no fuel stops is still worth showing',
      (tester) async {
        final controller = MapController();
        addTearDown(controller.dispose);

        final overrides = standardTestOverrides();
        when(() => overrides.mockStorage.getActiveProfileId())
            .thenReturn(null);

        await pumpApp(
          tester,
          buildHost(buildResult(stations: const []), controller),
          overrides: overrides.overrides,
        );

        expect(find.byType(EmptyState), findsNothing);
        expect(find.byType(RouteInfoBar), findsOneWidget);
        expect(find.byType(SelectablePill), findsNWidgets(2));
      },
    );
  });

  group('RouteMapView view-mode toggle', () {
    testWidgets(
      'defaults to "All stations" mode and shows the full station count',
      (tester) async {
        final controller = MapController();
        addTearDown(controller.dispose);

        final overrides = standardTestOverrides();
        when(() => overrides.mockStorage.getActiveProfileId())
            .thenReturn(null);

        await pumpApp(
          tester,
          buildHost(buildResult(stations: testStationList), controller),
          overrides: overrides.overrides,
        );

        // All-stations chip is selected; best-stops chip is not.
        final chips = tester
            .widgetList<SelectablePill>(find.byType(SelectablePill))
            .toList();
        expect(chips, hasLength(2));
        expect(chips[0].selected, isTrue,
            reason: 'All-stations chip should be selected by default');
        expect(chips[1].selected, isFalse);

        // Best-stops list should NOT be rendered in all-stations mode.
        expect(find.byType(RouteBestStopsList), findsNothing);

        // Station-count label reflects the full set (3 stations).
        expect(find.text('3 stations'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping "Best stops" swaps the selection, shows the best-stops list, '
      'and updates the station-count label',
      (tester) async {
        final controller = MapController();
        addTearDown(controller.dispose);

        final overrides = standardTestOverrides();
        when(() => overrides.mockStorage.getActiveProfileId())
            .thenReturn(null);

        // Give the result a single "cheapest" id so best-stops filters down
        // to exactly one station — easier to assert the label.
        await pumpApp(
          tester,
          buildHost(
            buildResult(
              stations: testStationList,
              cheapestId: testStationList.first.id,
            ),
            controller,
          ),
          overrides: overrides.overrides,
        );

        await tester.tap(find.text('Best stops'));
        await tester.pumpAndSettle();

        final chips = tester
            .widgetList<SelectablePill>(find.byType(SelectablePill))
            .toList();
        expect(chips[0].selected, isFalse);
        expect(chips[1].selected, isTrue);

        // The best-stops list appears now that we have ≥1 best station.
        expect(find.byType(RouteBestStopsList), findsOneWidget);
        // Station-count label switches to the "N best" wording.
        expect(find.text('1 best'), findsOneWidget);
      },
    );

    testWidgets(
      'best-stops mode uses cheapestPerSegment when provided',
      (tester) async {
        final controller = MapController();
        addTearDown(controller.dispose);

        final overrides = standardTestOverrides();
        when(() => overrides.mockStorage.getActiveProfileId())
            .thenReturn(null);

        await pumpApp(
          tester,
          buildHost(
            buildResult(
              stations: testStationList,
              cheapestPerSegment: {
                0: testStationList[0].id,
                1: testStationList[2].id,
              },
            ),
            controller,
          ),
          overrides: overrides.overrides,
        );

        await tester.tap(find.text('Best stops'));
        await tester.pumpAndSettle();

        // Two segments → two best stations.
        expect(find.text('2 best'), findsOneWidget);
      },
    );
  });

  // #2755 — route mode must frame the COMPLETE itinerary and hold the
  // camera across the All/Best toggle (the radius circle around the
  // polyline midpoint was the bug).
  group('RouteMapView camera framing (#2755)', () {
    // An ASYMMETRIC polyline: the midpoint index (geometry[mid] = p1) sits
    // near the dense start, far from the centroid of the full span — so a
    // route-bounds fit is provably distinct from the old midpoint centre.
    final asymmetricRoute = <LatLng>[
      const LatLng(52.40, 13.20), // p0 — south-west start
      const LatLng(52.42, 13.25), // p1 — midpoint index (mid = 1)
      const LatLng(52.80, 13.90), // p2 — far north-east end
    ];

    // Stations spread along the route, including one beyond the polyline's
    // own longitude span so the UNION bounds differ from the polyline-only
    // bounds and we can assert the union is what gets framed.
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
    final routeStations = <Station>[
      stationAt('a', 52.45, 13.30),
      stationAt('b', 52.60, 13.55),
      stationAt('c', 52.78, 13.95), // east of the polyline's max lng
    ];

    /// Expected camera target (#2782): bounds of the STATIONS (the search
    /// results) only — exactly what `RouteMapView._computeRouteBounds` now
    /// builds. The polyline geometry is intentionally NOT unioned in, so a
    /// long cross-border route no longer drags the camera far out.
    LatLngBounds stationBounds(List<Station> stations) {
      return LatLngBounds.fromPoints([
        for (final s in stations) LatLng(s.lat, s.lng),
      ]);
    }

    testWidgets(
      'frames the SEARCH RESULTS: fit target is the station bounds, and the '
      'far polyline start (SW of the station cluster) is NOT framed — the '
      'cross-border over-zoom fix (#2782)',
      (tester) async {
        final controller = MapController();
        addTearDown(controller.dispose);

        final overrides = standardTestOverrides();
        when(() => overrides.mockStorage.getActiveProfileId())
            .thenReturn(null);

        await pumpApp(
          tester,
          buildHost(
            buildResult(stations: routeStations, geometry: asymmetricRoute),
            controller,
          ),
          overrides: overrides.overrides,
        );
        await tester.pumpAndSettle();

        final expected = stationBounds(routeStations);

        // The StationMapLayers explicit fit target IS the station (results)
        // bounds — NOT the polyline∪stations union (#2782).
        final layers =
            tester.widget<StationMapLayers>(find.byType(StationMapLayers));
        expect(layers.cameraFitBounds, expected,
            reason: 'route mode frames the search-result stations, not the '
                'full route polyline');

        // The far polyline START (p0, SW of the station cluster) is OUTSIDE
        // the fit bounds — this is the whole point of #2782: a long
        // cross-border route no longer drags the camera out to the geometry.
        final polylineStart = asymmetricRoute.first; // 52.40, 13.20
        expect(expected.contains(polylineStart), isFalse,
            reason: 'the fit target must exclude the far route geometry so a '
                'cross-border itinerary does not over-zoom');

        // Every station (result) is inside the visible viewport.
        final visible = controller.camera.visibleBounds;
        for (final s in routeStations) {
          expect(visible.contains(LatLng(s.lat, s.lng)), isTrue,
              reason: 'station ${s.id} must be in view');
        }

        // The camera centre is the station-bounds centre.
        expect(controller.camera.center.latitude,
            closeTo(expected.center.latitude, 0.02));
        expect(controller.camera.center.longitude,
            closeTo(expected.center.longitude, 0.02));

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'STABILITY: after a manual zoom-out, toggling Best ↔ All does NOT '
      're-zoom — centre/zoom are identical across the two taps (#2755 lock)',
      (tester) async {
        final controller = MapController();
        addTearDown(controller.dispose);

        final overrides = standardTestOverrides();
        when(() => overrides.mockStorage.getActiveProfileId())
            .thenReturn(null);

        await pumpApp(
          tester,
          buildHost(
            buildResult(
              stations: routeStations,
              geometry: asymmetricRoute,
              cheapestId: routeStations.first.id,
            ),
            controller,
          ),
          overrides: overrides.overrides,
        );
        await tester.pumpAndSettle();

        // Simulate the user zooming out / panning away from the fitted view.
        final fitted = controller.camera;
        controller.move(fitted.center, fitted.zoom - 3);
        await tester.pumpAndSettle();
        final movedCenter = controller.camera.center;
        final movedZoom = controller.camera.zoom;

        // Toggle to Best stops: the marker subset shrinks, but the camera
        // must stay exactly where the user left it (no random snap).
        await tester.tap(find.text('Best stops'));
        await tester.pumpAndSettle();
        final afterBestCenter = controller.camera.center;
        final afterBestZoom = controller.camera.zoom;

        // Toggle back to All stations: again, no camera movement.
        await tester.tap(find.text('All stations'));
        await tester.pumpAndSettle();
        final afterAllCenter = controller.camera.center;
        final afterAllZoom = controller.camera.zoom;

        // The camera held through BOTH toggles — no re-zoom, no snap to a
        // station/cluster. The two taps produce IDENTICAL camera state.
        expect(afterBestZoom, movedZoom,
            reason: 'Best toggle must not re-zoom');
        expect(afterAllZoom, movedZoom,
            reason: 'All toggle must not re-zoom');
        expect(afterAllZoom, afterBestZoom, reason: 'no randomness');
        expect(afterBestCenter.latitude, closeTo(movedCenter.latitude, 1e-9));
        expect(afterBestCenter.longitude, closeTo(movedCenter.longitude, 1e-9));
        expect(afterAllCenter.latitude,
            closeTo(afterBestCenter.latitude, 1e-9));
        expect(afterAllCenter.longitude,
            closeTo(afterBestCenter.longitude, 1e-9));

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'degenerate single-point route → no exception (epsilon box), camera '
      'centred on the point',
      (tester) async {
        final controller = MapController();
        addTearDown(controller.dispose);

        final overrides = standardTestOverrides();
        when(() => overrides.mockStorage.getActiveProfileId())
            .thenReturn(null);

        const point = LatLng(48.8566, 2.3522);
        await pumpApp(
          tester,
          buildHost(
            buildResult(stations: const [], geometry: const [point]),
            controller,
          ),
          overrides: overrides.overrides,
        );
        await tester.pumpAndSettle();

        // No CameraFit divide-by-zero on a single-point polyline.
        expect(tester.takeException(), isNull);
        expect(controller.camera.center.latitude, closeTo(point.latitude, 0.01));
        expect(
            controller.camera.center.longitude, closeTo(point.longitude, 0.01));
      },
    );
  });

  // #3000 (Epic #2997) — the route map adopts the radar clustered+
  // cheapest-labelled grammar, but SELECTION-AWARE: cluster the non-selected
  // stations while the Best/All SELECTED stations stay as full un-clustered
  // pills. RouteMapView must hand StationMapLayers BOTH `clusterAlways` and
  // `excludeSelectedFromClustering`, and keep the cross-border resolver,
  // route polyline, the Best/All selection set, and the suppressed radius.
  group('RouteMapView selection-aware clustering wiring (#3000)', () {
    testWidgets(
      'passes clusterAlways AND excludeSelectedFromClustering to '
      'StationMapLayers, while keeping fuelResolver, routePolyline and '
      'showSearchRadius=false',
      (tester) async {
        final controller = MapController();
        addTearDown(controller.dispose);

        final overrides = standardTestOverrides();
        when(() => overrides.mockStorage.getActiveProfileId())
            .thenReturn(null);

        await pumpApp(
          tester,
          buildHost(buildResult(stations: testStationList), controller),
          overrides: overrides.overrides,
        );

        final layers =
            tester.widget<StationMapLayers>(find.byType(StationMapLayers));
        // Selection-aware clustering: cluster the non-selected, keep selected
        // as full pills.
        expect(layers.clusterAlways, isTrue,
            reason: 'route map adopts the radar clustered grammar');
        expect(layers.excludeSelectedFromClustering, isTrue,
            reason: 'Best/All selected stations stay OUT of clustering as full '
                'pills so the multi-select + list↔map 1:1 mapping survive');
        // #2631 — the cross-border resolver must still be supplied so a
        // Spanish station's cheapest rollup uses the resolved E10 price.
        expect(layers.fuelResolver, isNotNull,
            reason: 'cross-border fuel resolution (#2631) must be preserved');
        // Route polyline + suppressed radius are unchanged.
        expect(layers.routePolyline, isNotNull);
        expect(layers.showSearchRadius, isFalse);
        // Route map uses its OWN selection model — no map-row-select tap.
        expect(layers.onStationTap, isNull,
            reason: 'route map selects via its Best/All model, not map taps');
      },
    );

    testWidgets(
      'forwards the Best/All selected set as selectedStationIds once a Best '
      'station is chosen',
      (tester) async {
        final controller = MapController();
        addTearDown(controller.dispose);

        final overrides = standardTestOverrides();
        when(() => overrides.mockStorage.getActiveProfileId())
            .thenReturn(null);

        await pumpApp(
          tester,
          buildHost(
            buildResult(
              stations: testStationList,
              cheapestId: testStationList.first.id,
            ),
            controller,
          ),
          overrides: overrides.overrides,
        );

        // Switch to Best stops → the selected set is populated and forwarded.
        await tester.tap(find.text('Best stops'));
        await tester.pumpAndSettle();

        final layers =
            tester.widget<StationMapLayers>(find.byType(StationMapLayers));
        expect(layers.selectedStationIds, isNotNull);
        expect(layers.selectedStationIds, contains(testStationList.first.id),
            reason: 'the Best-stops selection set drives which markers stay '
                'un-clustered');
        // The two clustering flags hold across the toggle.
        expect(layers.clusterAlways, isTrue);
        expect(layers.excludeSelectedFromClustering, isTrue);
      },
    );
  });

  group('RouteMapView save-route dialog', () {
    testWidgets('opening the dialog shows a TextField and Cancel/Save buttons',
        (tester) async {
      final controller = MapController();
      addTearDown(controller.dispose);

      final overrides = standardTestOverrides();
      when(() => overrides.mockStorage.getActiveProfileId()).thenReturn(null);

      await pumpApp(
        tester,
        buildHost(buildResult(stations: testStationList), controller),
        overrides: [
          ...overrides.overrides,
          itineraryProvider.overrideWith(_FakeItineraryNotifier.new),
        ],
      );

      // Tap the "Save route" icon in the info bar (tooltip comes from l10n).
      await tester.tap(find.byTooltip('Save route'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Save route'), findsWidgets);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('Cancel pops the dialog without calling saveRoute',
        (tester) async {
      final controller = MapController();
      addTearDown(controller.dispose);

      final overrides = standardTestOverrides();
      when(() => overrides.mockStorage.getActiveProfileId()).thenReturn(null);

      final fake = _FakeItineraryNotifier();

      await pumpApp(
        tester,
        buildHost(buildResult(stations: testStationList), controller),
        overrides: [
          ...overrides.overrides,
          itineraryProvider.overrideWith(() => fake),
        ],
      );

      await tester.tap(find.byTooltip('Save route'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(fake.savedNames, isEmpty,
          reason: 'Cancel must not trigger itineraryProvider.saveRoute');
    });

    testWidgets(
      'typing a name and tapping Save invokes saveRoute with start+end '
      'waypoints derived from the polyline',
      (tester) async {
        final controller = MapController();
        addTearDown(controller.dispose);

        final overrides = standardTestOverrides();
        when(() => overrides.mockStorage.getActiveProfileId())
            .thenReturn(null);

        final fake = _FakeItineraryNotifier();

        await pumpApp(
          tester,
          buildHost(
            buildResult(
              stations: testStationList,
              distanceKm: 345,
              durationMinutes: 210,
            ),
            controller,
          ),
          overrides: [
            ...overrides.overrides,
            itineraryProvider.overrideWith(() => fake),
          ],
        );

        await tester.tap(find.byTooltip('Save route'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Berlin to Potsdam');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(fake.savedNames, ['Berlin to Potsdam']);
        final call = fake.lastCall!;
        expect(call.distanceKm, 345);
        expect(call.durationMinutes, 210);
        expect(call.waypoints, hasLength(2));
        expect(call.waypoints.first.label, 'Start');
        expect(call.waypoints.first.lat, polyline.first.latitude);
        expect(call.waypoints.first.lng, polyline.first.longitude);
        expect(call.waypoints.last.label, 'Destination');
        expect(call.waypoints.last.lat, polyline.last.latitude);
        expect(call.waypoints.last.lng, polyline.last.longitude);
      },
    );

    testWidgets(
      'Cancel lets the AlertDialog exit animation finish without throwing '
      '"TextEditingController used after being disposed"',
      (tester) async {
        // Regression: disposing the controller synchronously right after
        // `await showDialog` races the dialog's exit animation, which
        // still rebuilds the TextField one more time. The production code
        // defers dispose to addPostFrameCallback to avoid this.
        final controller = MapController();
        addTearDown(controller.dispose);

        final overrides = standardTestOverrides();
        when(() => overrides.mockStorage.getActiveProfileId())
            .thenReturn(null);

        await pumpApp(
          tester,
          buildHost(buildResult(stations: testStationList), controller),
          overrides: [
            ...overrides.overrides,
            itineraryProvider.overrideWith(_FakeItineraryNotifier.new),
          ],
        );

        await tester.tap(find.byTooltip('Save route'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        // A full settle drives every pending rebuild frame, which is
        // exactly what used to surface the dispose race.
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull,
            reason: 'Dialog dismissal must not throw on disposed controller');
      },
    );

    testWidgets('submitting an empty name does not call saveRoute',
        (tester) async {
      final controller = MapController();
      addTearDown(controller.dispose);

      final overrides = standardTestOverrides();
      when(() => overrides.mockStorage.getActiveProfileId()).thenReturn(null);

      final fake = _FakeItineraryNotifier();

      await pumpApp(
        tester,
        buildHost(buildResult(stations: testStationList), controller),
        overrides: [
          ...overrides.overrides,
          itineraryProvider.overrideWith(() => fake),
        ],
      );

      await tester.tap(find.byTooltip('Save route'));
      await tester.pumpAndSettle();

      // Leave the field empty and submit.
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(fake.savedNames, isEmpty);
    });
  });
}

/// Fake [ItineraryNotifier] that records `saveRoute` calls for assertions
/// without touching Hive storage or Supabase sync.
class _FakeItineraryNotifier extends ItineraryNotifier {
  final List<String> savedNames = [];
  _SavedRouteCall? lastCall;

  @override
  List<SavedItinerary> build() => const [];

  @override
  Future<bool> saveRoute({
    required String name,
    required List<RouteWaypoint> waypoints,
    required double distanceKm,
    required double durationMinutes,
    required bool avoidHighways,
    required String fuelType,
    List<String> selectedStationIds = const [],
  }) async {
    savedNames.add(name);
    lastCall = _SavedRouteCall(
      name: name,
      waypoints: waypoints,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      avoidHighways: avoidHighways,
      fuelType: fuelType,
      selectedStationIds: selectedStationIds,
    );
    return true;
  }
}

class _SavedRouteCall {
  final String name;
  final List<RouteWaypoint> waypoints;
  final double distanceKm;
  final double durationMinutes;
  final bool avoidHighways;
  final String fuelType;
  final List<String> selectedStationIds;

  _SavedRouteCall({
    required this.name,
    required this.waypoints,
    required this.distanceKm,
    required this.durationMinutes,
    required this.avoidHighways,
    required this.fuelType,
    required this.selectedStationIds,
  });
}
