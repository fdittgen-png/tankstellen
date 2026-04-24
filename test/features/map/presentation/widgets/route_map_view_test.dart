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
import 'package:tankstellen/features/map/presentation/widgets/route_view_mode_chip.dart';
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
        expect(find.byType(RouteViewModeChip), findsNothing);
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
        expect(find.byType(RouteViewModeChip), findsNWidgets(2));
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
            .widgetList<RouteViewModeChip>(find.byType(RouteViewModeChip))
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
            .widgetList<RouteViewModeChip>(find.byType(RouteViewModeChip))
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
