// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';
import 'package:tankstellen/features/route_search/domain/route_search_result.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/search_mode.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/search/presentation/screens/search_criteria_screen.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_summary_bar.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/search/presentation/widgets/results/summary_chip.dart';
import 'package:tankstellen/features/search/presentation/widgets/user_position_bar.dart';
import 'package:tankstellen/features/search/providers/radar_search_provider.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';

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
    testWidgets(
        'renders fuel type and radius badge (#2131 — inline button removed)',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);

      await pumpApp(
        tester,
        const SearchSummaryBar(),
        overrides: [
          ...test.overrides,
          selectedFuelTypeOverride(FuelType.e10),
          searchRadiusOverride(10),
        ],
      );

      // #3939 — value only: the pump glyph says "fuel", the radius glyph
      // says "within a radius of".
      expect(find.text('E10'), findsOneWidget);
      expect(find.text('Super E10'), findsNothing);
      expect(find.text('10 km'), findsOneWidget);
      expect(find.text('Within 10 km'), findsNothing);
    });

    testWidgets('#3939 — the value-only pills carry the full sentence as a '
        'tooltip AND as their screen-reader label', (tester) async {
      final handle = tester.ensureSemantics();
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);

      await pumpApp(
        tester,
        const SearchSummaryBar(),
        overrides: [
          ...test.overrides,
          selectedFuelTypeOverride(FuelType.e85),
          searchRadiusOverride(10),
          userPositionNullOverride(),
        ],
      );

      expect(find.text('E85'), findsOneWidget);
      expect(find.byTooltip('Fuel: E85 / Bioéthanol'), findsOneWidget);
      expect(find.byTooltip('Within 10 km'), findsOneWidget);

      // The whole band is one tappable semantics node, so the pills'
      // sentences are announced as part of it — the words the pills
      // stopped showing are still read out.
      expect(
        find.bySemanticsLabel(RegExp(r'Fuel: E85 / Bioéthanol')),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp(r'Within 10 km')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('tapping the bar opens SearchCriteriaScreen', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);

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
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);

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

      expect(find.text('10 km'), findsOneWidget);
    });

    testWidgets('route mode + loading shows searching chip, no radius',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);

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
        // #2783 — the searching chip now carries an indefinite spinner;
        // pumpAndSettle would hang, so pump a single frame.
        settle: false,
      );

      expect(find.text('Searching the route…'), findsOneWidget);
      // #2783 — a live spinner signals the search is ongoing.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('10 km'), findsNothing);
      expect(find.text('Along the route · every 50 km'), findsNothing);
    });

    testWidgets('route mode + partial result shows searching chip',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);

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
        // #2783 — spinner animates indefinitely during the partial phase too.
        settle: false,
      );

      expect(find.text('Searching the route…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Along the route · every 50 km'), findsNothing);
    });

    testWidgets('route mode + complete result shows route-segment summary',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);

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

      expect(find.text('Along the route · every 50 km'), findsOneWidget);
      expect(find.text('Searching the route…'), findsNothing);
      expect(find.text('10 km'), findsNothing);
    });

    // #2676 — while the on-search Fuel Station Radar owns the results, the
    // grey bar's second chip becomes a "radar result" badge instead of the
    // (now meaningless) radius chip.
    testWidgets('radar active replaces the radius chip with the radar badge',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);

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
      expect(find.text('10 km'), findsNothing);
    });

    testWidgets('radar inactive keeps the radius chip (badge absent)',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);

      await pumpApp(
        tester,
        const SearchSummaryBar(),
        overrides: [
          ...test.overrides,
          selectedFuelTypeOverride(FuelType.e10),
          searchRadiusOverride(10),
        ],
      );

      expect(find.text('10 km'), findsOneWidget);
      expect(find.text('Fuel Station Radar result'), findsNothing);
    });

    // #3926 — row A absorbed the position strip and the freshness pill.
    testWidgets('carries the position segment when no address was searched',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);

      await pumpApp(
        tester,
        const SearchSummaryBar(),
        overrides: [
          ...test.overrides,
          selectedFuelTypeOverride(FuelType.e10),
          searchRadiusOverride(10),
          userPositionOverride(lat: 52.52, lng: 13.405, source: 'GPS'),
        ],
      );

      expect(find.byType(UserPositionBar), findsOneWidget);
      expect(find.byKey(const Key('search_summary_address')), findsNothing);
    });

    testWidgets('a searched address replaces the position segment',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);

      await pumpApp(
        tester,
        const SearchSummaryBar(),
        overrides: [
          ...test.overrides,
          selectedFuelTypeOverride(FuelType.e10),
          searchRadiusOverride(10),
          userPositionNullOverride(),
          searchLocationOverride('75001 Paris'),
        ],
      );

      expect(find.text('75001 Paris'), findsOneWidget);
      expect(find.byType(UserPositionBar), findsNothing);
    });

    testWidgets(
        'the freshness segment says WHAT is old — the price download age — '
        'and stays neutral inside the staleness threshold (#3926)',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);

      await pumpApp(
        tester,
        const SearchSummaryBar(),
        overrides: [
          ...test.overrides,
          selectedFuelTypeOverride(FuelType.e10),
          searchRadiusOverride(10),
          userPositionNullOverride(),
          appClockProvider.overrideWithValue(FixedClock(_fixedNow)),
          searchStateProvider.overrideWith(
            () => _SeededSearch(_fixedNow.subtract(const Duration(hours: 2))),
          ),
        ],
      );

      // #3939 — the pill shows the bare age; the sentence that names WHAT
      // is two hours old moved to its tooltip and semantics label, so
      // nothing the #3926 wording won is lost.
      expect(find.text('2 h'), findsOneWidget);
      expect(find.text('Prices from 2 h ago'), findsNothing);
      expect(find.byTooltip('Prices from 2 h ago'), findsOneWidget);
      final chip = tester.widget<SummaryChip>(
        find.byKey(const Key('search_freshness_segment')),
      );
      // 2 h is past the 15-minute staleness threshold → amber.
      expect(chip.emphasized, isTrue);
    });

    testWidgets('a fresh price list is NOT amber (#3926)', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);

      await pumpApp(
        tester,
        const SearchSummaryBar(),
        overrides: [
          ...test.overrides,
          selectedFuelTypeOverride(FuelType.e10),
          searchRadiusOverride(10),
          userPositionNullOverride(),
          appClockProvider.overrideWithValue(FixedClock(_fixedNow)),
          searchStateProvider.overrideWith(
            () => _SeededSearch(_fixedNow.subtract(const Duration(minutes: 3))),
          ),
        ],
      );

      expect(find.text('3 min'), findsOneWidget);
      expect(find.byTooltip('Prices from 3 min ago'), findsOneWidget);
      final chip = tester.widget<SummaryChip>(
        find.byKey(const Key('search_freshness_segment')),
      );
      expect(chip.emphasized, isFalse);
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

/// A mid-month Wednesday — the house convention for a pinned test clock.
final _fixedNow = DateTime(2026, 3, 11, 14, 30);

/// A loaded search whose payload was downloaded at [_fetchedAt] — the value
/// the freshness segment ages against.
class _SeededSearch extends SearchState {
  _SeededSearch(this._fetchedAt);

  final DateTime _fetchedAt;

  @override
  AsyncValue<ServiceResult<List<SearchResultItem>>> build() => AsyncValue.data(
        ServiceResult(
          data: const [FuelStationResult(_station)],
          source: ServiceSource.prixCarburantsApi,
          fetchedAt: _fetchedAt,
        ),
      );
}

const _station = Station(
  id: 'fr-1',
  name: 'Station',
  brand: 'TEST',
  street: 'rue',
  postCode: '75001',
  place: 'Paris',
  lat: 48.85,
  lng: 2.35,
  e10: 1.75,
  isOpen: true,
);
