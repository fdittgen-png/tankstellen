import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/widgets/empty_state.dart';
import 'package:tankstellen/features/map/presentation/widgets/inline_map.dart';
import 'package:tankstellen/features/map/presentation/widgets/station_map_layers.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';

import '../../../../fixtures/stations.dart';
import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// Widget tests for [InlineMap] — the embeddable map widget that drives
/// the split-screen layout from `searchStateProvider` + the active fuel
/// + radius. Covers the four AsyncValue branches (loading / error /
/// data-empty / data-non-empty) plus the selectedFuel/searchRadiusKm
/// prop forwarding to [StationMapLayers].
void main() {
  // Wrap InlineMap in a finite-sized parent so FlutterMap (which queries
  // its parent constraints during layout) does not blow up with an
  // unbounded width/height assertion.
  Widget host() => const SizedBox(
        width: 800,
        height: 600,
        child: InlineMap(),
      );

  group('InlineMap loading branch', () {
    testWidgets('renders a CircularProgressIndicator while AsyncLoading',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      // Bypass pumpAndSettle — the spinner animates forever.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...test.overrides,
            searchStateProvider.overrideWith(() => _LoadingSearchState()),
          ].cast(),
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: InlineMap(),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Loading branch must not render the data widgets.
      expect(find.byType(StationMapLayers), findsNothing);
      expect(find.byType(EmptyState), findsNothing);
    });
  });

  group('InlineMap error branch', () {
    testWidgets('renders "Map unavailable" text when AsyncError',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        host(),
        overrides: [
          ...test.overrides,
          searchStateProvider.overrideWith(() => _ErrorSearchState()),
        ].cast(),
      );

      expect(find.text('Map unavailable'), findsOneWidget);
      expect(find.byType(StationMapLayers), findsNothing);
      expect(find.byType(EmptyState), findsNothing);
    });
  });

  group('InlineMap empty data branch', () {
    testWidgets(
        'renders EmptyState with the map icon and "search to see stations" '
        'title when the result list is empty', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        host(),
        overrides: [
          ...test.overrides,
          searchStateProvider.overrideWith(() => _EmptySearchState()),
        ].cast(),
      );

      expect(find.byType(EmptyState), findsOneWidget);
      // The English ARB copy used by AppLocalizations.searchToSeeMap.
      expect(
        find.text('Search to see stations on the map'),
        findsOneWidget,
      );
      // Map-specific widgets must not render in the empty branch.
      expect(find.byType(StationMapLayers), findsNothing);

      // The EmptyState renders the map_outlined icon.
      final emptyState = tester.widget<EmptyState>(find.byType(EmptyState));
      expect(emptyState.icon, Icons.map_outlined);
    });
  });

  group('InlineMap data branch with stations', () {
    testWidgets('mounts StationMapLayers when the result has fuel stations',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        host(),
        overrides: [
          ...test.overrides,
          searchStateProvider.overrideWith(
            () => _LoadedSearchState([testStation]),
          ),
        ].cast(),
      );

      expect(find.byType(StationMapLayers), findsOneWidget);
      // Empty/error/loading branches must not co-exist with data.
      expect(find.byType(EmptyState), findsNothing);
      expect(find.text('Map unavailable'), findsNothing);
    });

    testWidgets('forwards searchRadiusKm from searchRadiusProvider to '
        'StationMapLayers', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        host(),
        overrides: [
          ...test.overrides,
          searchStateProvider.overrideWith(
            () => _LoadedSearchState([testStation]),
          ),
          searchRadiusOverride(17.5),
        ].cast(),
      );

      final layer =
          tester.widget<StationMapLayers>(find.byType(StationMapLayers));
      expect(layer.searchRadiusKm, 17.5);
    });

    testWidgets('forwards selectedFuel from selectedFuelTypeProvider to '
        'StationMapLayers', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        host(),
        overrides: [
          ...test.overrides,
          searchStateProvider.overrideWith(
            () => _LoadedSearchState([testStation]),
          ),
          selectedFuelTypeOverride(FuelType.diesel),
        ].cast(),
      );

      final layer =
          tester.widget<StationMapLayers>(find.byType(StationMapLayers));
      expect(layer.selectedFuel, FuelType.diesel);
    });

    testWidgets(
        'feeds the underlying StationMapLayers with the unwrapped Station '
        'list (FuelStationResult.station, not the SearchResultItem itself)',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        host(),
        overrides: [
          ...test.overrides,
          searchStateProvider.overrideWith(
            () => _LoadedSearchState(testStationList),
          ),
        ].cast(),
      );

      final layer =
          tester.widget<StationMapLayers>(find.byType(StationMapLayers));
      expect(layer.stations, hasLength(testStationList.length));
      expect(
        layer.stations.map((s) => s.id).toList(),
        testStationList.map((s) => s.id).toList(),
      );
    });
  });
}

class _LoadingSearchState extends SearchState {
  @override
  AsyncValue<ServiceResult<List<SearchResultItem>>> build() =>
      const AsyncValue.loading();
}

class _ErrorSearchState extends SearchState {
  @override
  AsyncValue<ServiceResult<List<SearchResultItem>>> build() =>
      AsyncValue.error(Exception('boom'), StackTrace.current);
}

class _EmptySearchState extends SearchState {
  @override
  AsyncValue<ServiceResult<List<SearchResultItem>>> build() => AsyncValue.data(
        ServiceResult(
          data: const [],
          source: ServiceSource.cache,
          fetchedAt: DateTime.now(),
        ),
      );
}

class _LoadedSearchState extends SearchState {
  _LoadedSearchState(this._stations);
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
