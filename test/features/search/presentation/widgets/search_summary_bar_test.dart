// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';
import 'package:tankstellen/features/route_search/domain/route_search_result.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/search_mode.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/presentation/screens/search_criteria_screen.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_summary_bar.dart';
import 'package:tankstellen/features/search/providers/radar_search_provider.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

const _route = RouteInfo(
  geometry: [LatLng(52.52, 13.41), LatLng(48.14, 11.58)],
  distanceKm: 584.0,
  durationMinutes: 330.0,
  samplePoints: [LatLng(52.52, 13.41)],
);

void main() {
  group('SearchSummaryBar', () {
    testWidgets('renders fuel type and radius badge (#2131 — inline button removed)',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SearchSummaryBar(),
        overrides: [
          ...test.overrides,
          selectedFuelTypeOverride(FuelType.e10),
          searchRadiusOverride(10),
        ],
      );

      expect(find.text('Super E10'), findsOneWidget);
      expect(find.text('Within 10 km'), findsOneWidget);
    });

    testWidgets('tapping the bar opens SearchCriteriaScreen', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SearchSummaryBar(),
        overrides: [
          ...test.overrides,
          selectedFuelTypeOverride(FuelType.diesel),
          searchRadiusOverride(5),
          userPositionNullOverride(),
        ],
      );

      expect(find.byType(SearchCriteriaScreen), findsNothing);

      // #2131 — the inline tonal "Search" button is gone; the bar
      // itself stays tappable as a discoverable refine affordance.
      await tester.tap(find.byType(SearchSummaryBar));
      await tester.pumpAndSettle();

      expect(find.byType(SearchCriteriaScreen), findsOneWidget);
    });

    // #2592 — route mode replaces the radius chip with a route-planning
    // summary: a "searching" placeholder while results stream in, then the
    // route-segment summary once the search completes.
    testWidgets('nearby mode keeps the radius badge (default mode)',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SearchSummaryBar(),
        overrides: [
          ...test.overrides,
          selectedFuelTypeOverride(FuelType.e10),
          searchRadiusOverride(10),
          activeSearchModeOverride(SearchMode.nearby),
        ],
      );

      expect(find.text('Within 10 km'), findsOneWidget);
    });

    testWidgets('route mode + loading shows searching chip, no radius',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SearchSummaryBar(),
        overrides: [
          ...test.overrides,
          selectedFuelTypeOverride(FuelType.e10),
          searchRadiusOverride(10),
          activeSearchModeOverride(SearchMode.route),
          routeSegmentSearchParamOverride(50),
          routeSearchStateOverride(
            const AsyncValue<RouteSearchResult?>.loading(),
          ),
        ],
      );

      expect(find.text('Searching the route…'), findsOneWidget);
      expect(find.text('Within 10 km'), findsNothing);
      expect(find.text('Every 50 km'), findsNothing);
    });

    testWidgets('route mode + partial result shows searching chip',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SearchSummaryBar(),
        overrides: [
          ...test.overrides,
          selectedFuelTypeOverride(FuelType.e10),
          searchRadiusOverride(10),
          activeSearchModeOverride(SearchMode.route),
          routeSegmentSearchParamOverride(50),
          routeSearchStateOverride(
            const AsyncValue<RouteSearchResult?>.data(
              RouteSearchResult(
                route: _route,
                stations: [],
                isPartial: true,
              ),
            ),
          ),
        ],
      );

      expect(find.text('Searching the route…'), findsOneWidget);
      expect(find.text('Every 50 km'), findsNothing);
    });

    testWidgets('route mode + complete result shows route-segment summary',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SearchSummaryBar(),
        overrides: [
          ...test.overrides,
          selectedFuelTypeOverride(FuelType.e10),
          searchRadiusOverride(10),
          activeSearchModeOverride(SearchMode.route),
          routeSegmentSearchParamOverride(50),
          routeSearchStateOverride(
            const AsyncValue<RouteSearchResult?>.data(
              RouteSearchResult(route: _route, stations: []),
            ),
          ),
        ],
      );

      expect(find.text('Every 50 km'), findsOneWidget);
      expect(find.text('Searching the route…'), findsNothing);
      expect(find.text('Within 10 km'), findsNothing);
    });

    // #2676 — while the on-search Fuel Station Radar owns the results, the
    // grey bar's second chip becomes a "radar result" badge instead of the
    // (now meaningless) radius chip.
    testWidgets('radar active replaces the radius chip with the radar badge',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SearchSummaryBar(),
        overrides: [
          ...test.overrides,
          selectedFuelTypeOverride(FuelType.e10),
          searchRadiusOverride(10),
          radarSearchProvider.overrideWith(_ActiveRadar.new),
        ],
      );

      expect(find.text('Fuel Station Radar result'), findsOneWidget);
      expect(find.text('Within 10 km'), findsNothing);
    });

    testWidgets('radar inactive keeps the radius chip (badge absent)',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SearchSummaryBar(),
        overrides: [
          ...test.overrides,
          selectedFuelTypeOverride(FuelType.e10),
          searchRadiusOverride(10),
        ],
      );

      expect(find.text('Within 10 km'), findsOneWidget);
      expect(find.text('Fuel Station Radar result'), findsNothing);
    });
  });
}

class _ActiveRadar extends RadarSearch {
  @override
  RadarSearchState build() => const RadarSearchState(
        active: true,
        stations: AsyncData<List<Station>>(<Station>[]),
      );
}
