// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';
import 'package:tankstellen/features/route_search/providers/route_search_provider.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/presentation/widgets/route_results_view.dart';
import 'package:tankstellen/features/search/providers/ignored_stations_provider.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

RouteSearchResult _resultWithStations(int count) {
  final stations = <SearchResultItem>[
    for (var i = 0; i < count; i++)
      FuelStationResult(Station(
        id: 'st-$i',
        name: 'Station $i',
        brand: 'TOTAL',
        street: 'Rue $i',
        postCode: '34120',
        place: 'Pézenas',
        lat: 43.46 + i * 0.01,
        lng: 3.42 + i * 0.01,
        dist: 1.0 + i,
        e10: 1.799,
        isOpen: true,
      )),
  ];
  return RouteSearchResult(
    route: const RouteInfo(
      geometry: [LatLng(43.46, 3.42), LatLng(43.5, 3.5)],
      distanceKm: 306,
      durationMinutes: 199,
      samplePoints: [LatLng(43.48, 3.46)],
    ),
    stations: stations,
  );
}

void main() {
  group('RouteResultsView', () {
    testWidgets('shows localized empty message when no stations found',
        (tester) async {
      final test = standardTestOverrides();

      const emptyResult = RouteSearchResult(
        route: RouteInfo(
          geometry: [LatLng(48.0, 2.0), LatLng(49.0, 3.0)],
          distanceKm: 100,
          durationMinutes: 60,
          samplePoints: [LatLng(48.5, 2.5)],
        ),
        stations: [],
      );

      await pumpApp(
        tester,
        const CustomScrollView(slivers: [RouteResultsView()]),
        overrides: [
          ...test.overrides,
          routeSearchStateProvider
              .overrideWith(() => _FixedRouteSearch(emptyResult)),
        ],
      );

      expect(
        find.text('No stations found along this route.'),
        findsOneWidget,
      );
    });

    testWidgets('shows localized start search message when no search performed',
        (tester) async {
      final test = standardTestOverrides();

      await pumpApp(
        tester,
        const CustomScrollView(slivers: [RouteResultsView()]),
        overrides: [
          ...test.overrides,
          routeSearchStateProvider
              .overrideWith(() => _FixedRouteSearch(null)),
        ],
      );

      expect(
        find.text('Search to find fuel stations.'),
        findsOneWidget,
      );
    });

    testWidgets('#2622 — header uses the pluralised station count, not the '
        'hard-coded "N stations" literal', (tester) async {
      final test = standardTestOverrides();

      await pumpApp(
        tester,
        const CustomScrollView(slivers: [RouteResultsView()]),
        overrides: [
          ...test.overrides,
          routeSearchStateProvider
              .overrideWith(() => _FixedRouteSearch(_resultWithStations(3))),
          ignoredStationsProvider.overrideWith(() => _NoIgnoredStations()),
        ],
      );

      // The summary line embeds the localized plural ("3 stations"), so the
      // distance/duration/count text is rendered exactly once.
      expect(find.textContaining('306 km'), findsOneWidget);
      expect(find.textContaining('3 stations'), findsOneWidget);
    });

    testWidgets('#2622 — singular station count reads "1 station"',
        (tester) async {
      final test = standardTestOverrides();

      await pumpApp(
        tester,
        const CustomScrollView(slivers: [RouteResultsView()]),
        overrides: [
          ...test.overrides,
          routeSearchStateProvider
              .overrideWith(() => _FixedRouteSearch(_resultWithStations(1))),
          ignoredStationsProvider.overrideWith(() => _NoIgnoredStations()),
        ],
      );

      expect(find.textContaining('1 station'), findsOneWidget);
      expect(find.textContaining('1 stations'), findsNothing);
    });

    testWidgets('#2622 — the duplicate "Every {km} km" segment row is gone '
        'from the header (it lives once on the SearchSummaryBar chip)',
        (tester) async {
      final test = standardTestOverrides();

      await pumpApp(
        tester,
        const CustomScrollView(slivers: [RouteResultsView()]),
        overrides: [
          ...test.overrides,
          routeSearchStateProvider
              .overrideWith(() => _FixedRouteSearch(_resultWithStations(2))),
          ignoredStationsProvider.overrideWith(() => _NoIgnoredStations()),
        ],
      );

      // The header no longer carries the straighten/"Every km" duplicate.
      expect(find.byIcon(Icons.straighten), findsNothing);
      expect(find.textContaining('Every'), findsNothing);
    });
  });
}

class _FixedRouteSearch extends RouteSearchState {
  final RouteSearchResult? _result;
  _FixedRouteSearch(this._result);

  @override
  AsyncValue<RouteSearchResult?> build() => AsyncValue.data(_result);
}

class _NoIgnoredStations extends IgnoredStations {
  @override
  List<String> build() => const [];
}
