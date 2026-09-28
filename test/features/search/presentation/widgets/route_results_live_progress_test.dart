// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/utils/route_progress.dart';
import 'package:tankstellen/features/route_search/api.dart';
import 'package:tankstellen/features/search/presentation/widgets/route_results_view.dart';
import 'package:tankstellen/features/search/providers/ignored_stations_provider.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// #4432 — the route list consumes the foreground progress: a stop the
/// driver has passed leaves the list (and its counts), leaving the route
/// offers "Update route from your position", and the listener pauses
/// while the surface is hidden.
class _FixedRouteSearch extends RouteSearchState {
  _FixedRouteSearch(this._result);
  final RouteSearchResult? _result;
  int refreshes = 0;

  @override
  AsyncValue<RouteSearchResult?> build() => AsyncValue.data(_result);

  @override
  Future<bool> refresh() async {
    refreshes++;
    return true;
  }
}

class _NoIgnoredStations extends IgnoredStations {
  @override
  List<String> build() => const [];
}

class _FakeProgress extends RouteLiveProgressController {
  _FakeProgress(this.value);
  final RouteLiveProgress value;
  int pauses = 0;
  int resumes = 0;

  @override
  RouteLiveProgress build() => value;

  @override
  void pause() => pauses++;

  @override
  void resume() => resumes++;
}

Station _station(String id, double lat, double lng) => Station(
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

void main() {
  // West → east along lat 48; 0.1° of longitude is ~7.44 km.
  final result = RouteSearchResult(
    route: const RouteInfo(
      geometry: [LatLng(48.0, 2.0), LatLng(48.0, 3.0)],
      distanceKm: 74,
      durationMinutes: 50,
      samplePoints: [LatLng(48.0, 2.0), LatLng(48.0, 3.0)],
    ),
    stations: [
      FuelStationResult(_station('passed', 48.0, 2.1)),
      FuelStationResult(_station('ahead', 48.0, 2.8)),
    ],
    request: const RouteSearchRequest(
      revision: 42,
      waypoints: [
        RouteWaypoint(
            lat: 48.0, lng: 2.0, label: 'Current location',
            isVehiclePosition: true),
        RouteWaypoint(lat: 48.0, lng: 3.0, label: 'Dest'),
      ],
      fuelType: FuelType.e10,
      searchRadiusKm: 5,
      strategyType: RouteSearchStrategyType.uniform,
    ),
  );

  late _FixedRouteSearch search;
  late _FakeProgress progress;

  Future<void> pumpList(
    WidgetTester tester,
    RouteLiveProgress value, {
    bool visible = true,
  }) async {
    search = _FixedRouteSearch(result);
    progress = _FakeProgress(value);
    final test = standardTestOverrides();
    await pumpApp(
      tester,
      TickerMode(
        enabled: visible,
        child: const CustomScrollView(slivers: [RouteResultsView()]),
      ),
      overrides: [
        ...test.overrides,
        routeSearchStateProvider.overrideWith(() => search),
        ignoredStationsProvider.overrideWith(() => _NoIgnoredStations()),
        routeLiveProgressControllerProvider.overrideWith(() => progress),
      ],
    );
    // Show every row, not the best-stops subset.
    await tester.tap(find.text('All stations').first);
    await tester.pumpAndSettle();
  }

  testWidgets('before any progress both stops are listed', (tester) async {
    await pumpList(tester, const RouteLiveProgress(revision: 42));

    expect(find.text('passed'), findsWidgets);
    expect(find.text('ahead'), findsWidgets);
    expect(find.byKey(const ValueKey('route-update-from-position')),
        findsNothing);
  });

  testWidgets('a stop the driver has passed leaves the list', (tester) async {
    await pumpList(
      tester,
      const RouteLiveProgress(
        revision: 42,
        status: RouteProgressStatus.onRoute,
        retiredBeforeKm: 20, // driver ~21 km in; "passed" sits at 7.4 km
      ),
    );

    expect(find.text('passed'), findsNothing);
    expect(find.text('ahead'), findsWidgets);
  });

  testWidgets('progress of ANOTHER route request filters nothing',
      (tester) async {
    await pumpList(
      tester,
      const RouteLiveProgress(revision: 41, retiredBeforeKm: 20),
    );

    expect(find.text('passed'), findsWidgets);
  });

  testWidgets(
      'leaving the route offers "Update route from your position", and '
      'only the tap refreshes the route', (tester) async {
    await pumpList(
      tester,
      const RouteLiveProgress(
        revision: 42,
        status: RouteProgressStatus.offRoute,
      ),
    );

    expect(find.byKey(const ValueKey('route-update-from-position')),
        findsOneWidget);
    expect(search.refreshes, 0);
    await tester.tap(find.text('Update route from your position'));
    await tester.pump();
    expect(search.refreshes, 1);
  });

  testWidgets('a hidden surface pauses the listener', (tester) async {
    await pumpList(tester, const RouteLiveProgress(revision: 42),
        visible: false);

    expect(progress.pauses, greaterThan(0));
  });
}
