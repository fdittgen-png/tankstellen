// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/widgets/empty_state.dart';
import 'package:tankstellen/features/map/presentation/widgets/inline_map.dart';
import 'package:tankstellen/features/map/presentation/widgets/station_map_layers.dart';
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';
import 'package:tankstellen/features/route_search/providers/route_search_provider.dart';
import 'package:tankstellen/core/domain/search_mode.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/search/providers/radar_search_provider.dart';
import 'package:tankstellen/features/search/providers/search_mode_provider.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';
import 'package:tankstellen/features/search/providers/selected_station_provider.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// #3033 — the landscape split map must honour ROUTE mode (mirroring the
/// list's `RouteResultsView` early-return). RED-before: `InlineMap` watched
/// only `radarSearchProvider`/`searchStateProvider`, so a route search showed
/// the STALE nearby set with NO route polyline. These assertions on the route
/// data + the polyline would have failed (the map would have rendered the
/// stale stations instead).
void main() {
  Station station(String id, double lat, double lng, {double? e10}) => Station(
        id: id,
        name: 'Station $id',
        brand: 'TEST',
        street: 'Teststr.',
        postCode: '00000',
        place: 'Test',
        lat: lat,
        lng: lng,
        dist: 1,
        e10: e10,
        isOpen: true,
      );

  // Along-route stations spread across the corridor (Berlin -> south-east).
  final routeStations = [
    station('rt1', 52.520, 13.405, e10: 1.799),
    station('rt2', 52.300, 13.600, e10: 1.659),
    station('rt3', 52.100, 13.900, e10: 1.729),
  ];

  // A distinct STALE nearby set the map must NOT fall through to in route mode.
  final staleNearby = [
    station('stale1', 48.137, 11.575, e10: 1.999), // Munich — far away.
    station('stale2', 48.140, 11.580, e10: 1.989),
  ];

  final polyline = <LatLng>[
    const LatLng(52.520, 13.405),
    const LatLng(52.300, 13.600),
    const LatLng(52.100, 13.900),
  ];

  RouteSearchResult buildResult({
    required List<Station> stations,
    List<LatLng>? geometry,
  }) =>
      RouteSearchResult(
        route: RouteInfo(
          geometry: geometry ?? polyline,
          distanceKm: 120,
          durationMinutes: 90,
          samplePoints: geometry ?? polyline,
        ),
        stations: stations.map((s) => FuelStationResult(s)).toList(),
      );

  Widget host() => const SizedBox(width: 800, height: 600, child: InlineMap());

  /// Route mode active, with a fresh route result AND a deliberately-stale
  /// nearby search + a (would-be-active) radar to prove route data WINS.
  List<Object> routeOverrides({
    required RouteSearchResult? result,
    String? selected,
  }) {
    final test = standardTestOverrides();
    return [
      ...test.overrides,
      activeSearchModeProvider.overrideWith(() => _RouteMode()),
      routeSearchStateProvider.overrideWith(() => _RouteState(result)),
      // Stale fall-through guards: if the route branch is missing, the map
      // would render one of these instead.
      searchStateProvider.overrideWith(() => _StaleSearch(staleNearby)),
      radarSearchProvider.overrideWith(() => _ActiveRadar(staleNearby)),
      if (selected != null)
        selectedStationProvider.overrideWith(() => _SelectedStub(selected)),
    ];
  }

  testWidgets(
      'route mode renders the along-route fuel stations from '
      'routeSearchStateProvider (NOT the stale nearby/radar set)',
      (tester) async {
    await pumpApp(
      tester,
      host(),
      overrides: routeOverrides(
        result: buildResult(stations: routeStations),
      ).cast(),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 50));

    final layer =
        tester.widget<StationMapLayers>(find.byType(StationMapLayers));
    // The map is fed the ROUTE stations — all of them.
    expect(
      layer.stations.map((s) => s.id).toList(),
      routeStations.map((s) => s.id).toList(),
    );
    // ROUTE-DATA-WINS: the stale nearby + radar set must NOT have reached the
    // map (the bug). None of its ids may appear.
    final ids = layer.stations.map((s) => s.id).toSet();
    expect(ids.contains('stale1'), isFalse);
    expect(ids.contains('stale2'), isFalse);
    // Proximity clustering for the route overview; radius circle suppressed.
    expect(layer.clusterAlways, isTrue);
    expect(layer.excludeSelectedFromClustering, isFalse);
    expect(layer.showSearchRadius, isFalse);
  });

  testWidgets('route mode draws the route polyline (route.geometry)',
      (tester) async {
    await pumpApp(
      tester,
      host(),
      overrides: routeOverrides(
        result: buildResult(stations: routeStations),
      ).cast(),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 50));

    final layer =
        tester.widget<StationMapLayers>(find.byType(StationMapLayers));
    // The route line is forwarded so a PolylineLayer paints it.
    expect(layer.routePolyline, isNotNull);
    expect(layer.routePolyline, equals(polyline));
  });

  testWidgets(
      'route mode frames the camera to the along-route STATION bounds (#2782)',
      (tester) async {
    await pumpApp(
      tester,
      host(),
      overrides: routeOverrides(
        result: buildResult(stations: routeStations),
      ).cast(),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 50));

    final layer =
        tester.widget<StationMapLayers>(find.byType(StationMapLayers));
    final bounds = layer.cameraFitBounds;
    expect(bounds, isNotNull);
    final expected = LatLngBounds.fromPoints(
        [for (final s in routeStations) LatLng(s.lat, s.lng)]);
    expect(bounds!.south, closeTo(expected.south, 1e-9));
    expect(bounds.north, closeTo(expected.north, 1e-9));
    expect(bounds.west, closeTo(expected.west, 1e-9));
    expect(bounds.east, closeTo(expected.east, 1e-9));
  });

  testWidgets('route mode keeps list<->map selection two-way sync',
      (tester) async {
    await pumpApp(
      tester,
      host(),
      overrides: routeOverrides(
        result: buildResult(stations: routeStations),
        selected: 'rt2',
      ).cast(),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 50));

    final layer =
        tester.widget<StationMapLayers>(find.byType(StationMapLayers));
    expect(layer.selectedStationIds, contains('rt2'));
    expect(layer.onStationTap, isNotNull);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(StationMapLayers)),
    );
    layer.onStationTap!('rt1');
    await tester.pump();
    expect(container.read(selectedStationProvider), 'rt1');
    expect(find.byType(StationMapLayers), findsOneWidget);
  });

  testWidgets(
      'route mode with an empty result (no stations, no geometry) renders the '
      'noStationsAlongRoute EmptyState — not a crash, not the stale set',
      (tester) async {
    await pumpApp(
      tester,
      host(),
      overrides: routeOverrides(
        result: buildResult(stations: const [], geometry: const []),
      ).cast(),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('No stations found along route'), findsOneWidget);
    expect(find.byType(StationMapLayers), findsNothing);
  });

  testWidgets(
      'route mode with a null result (search not yet run) renders the empty '
      'state, not the stale nearby set', (tester) async {
    await pumpApp(
      tester,
      host(),
      overrides: routeOverrides(result: null).cast(),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.byType(StationMapLayers), findsNothing);
  });

  testWidgets(
      'regression: NEARBY mode is unaffected — the radar still owns the map',
      (tester) async {
    final test = standardTestOverrides();
    await pumpApp(
      tester,
      host(),
      overrides: [
        ...test.overrides,
        // Default search mode is nearby; assert explicitly anyway.
        activeSearchModeProvider.overrideWith(() => _NearbyMode()),
        radarSearchProvider.overrideWith(() => _ActiveRadar(staleNearby)),
      ].cast(),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 50));

    final layer =
        tester.widget<StationMapLayers>(find.byType(StationMapLayers));
    // The radar set (here `staleNearby`) is what nearby mode renders — proving
    // the route branch did NOT hijack the non-route path.
    expect(
      layer.stations.map((s) => s.id).toList(),
      staleNearby.map((s) => s.id).toList(),
    );
    // No route polyline in nearby mode.
    expect(layer.routePolyline, isNull);
  });

  testWidgets(
      'regression: plain-search (radar idle) mode still renders via '
      'searchStateProvider', (tester) async {
    final test = standardTestOverrides();
    await pumpApp(
      tester,
      host(),
      overrides: [
        ...test.overrides,
        activeSearchModeProvider.overrideWith(() => _NearbyMode()),
        searchStateProvider.overrideWith(() => _StaleSearch(staleNearby)),
      ].cast(),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 50));

    final layer =
        tester.widget<StationMapLayers>(find.byType(StationMapLayers));
    expect(
      layer.stations.map((s) => s.id).toList(),
      staleNearby.map((s) => s.id).toList(),
    );
    expect(layer.routePolyline, isNull);
  });
}

class _RouteMode extends ActiveSearchMode {
  @override
  SearchMode build() => SearchMode.route;
}

class _NearbyMode extends ActiveSearchMode {
  @override
  SearchMode build() => SearchMode.nearby;
}

class _RouteState extends RouteSearchState {
  _RouteState(this._result);
  final RouteSearchResult? _result;

  @override
  AsyncValue<RouteSearchResult?> build() => AsyncValue.data(_result);
}

/// A plain search result holding a DELIBERATELY-STALE nearby set, so a missing
/// route branch would surface these ids (the bug).
class _StaleSearch extends SearchState {
  _StaleSearch(this._stations);
  final List<Station> _stations;

  @override
  AsyncValue<ServiceResult<List<SearchResultItem>>> build() => AsyncValue.data(
        ServiceResult(
          data: _stations
              .map((s) => FuelStationResult(s) as SearchResultItem)
              .toList(),
          source: ServiceSource.cache,
          fetchedAt: DateTime.now(),
        ),
      );
}

class _ActiveRadar extends RadarSearch {
  _ActiveRadar(this._stations);
  final List<Station> _stations;

  @override
  RadarSearchState build() => RadarSearchState(
        active: true,
        stations: AsyncData<List<Station>>(_stations),
      );
}

class _SelectedStub extends SelectedStation {
  _SelectedStub(this._id);
  final String _id;

  @override
  String? build() => _id;
}
