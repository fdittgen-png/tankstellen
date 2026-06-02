// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/location/user_position_provider.dart';
import 'package:tankstellen/core/services/radar/corridor_location_cache.dart';
import 'package:tankstellen/core/services/radar/jit_price_cache.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/features/approach/providers/fuel_station_radar_provider.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_results_content.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_results_list.dart';
import 'package:tankstellen/features/search/providers/radar_search_provider.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';

import '../../../../fixtures/stations.dart';
import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// #2675 — the radar button on the search-results header runs the on-search
/// radar and the SAME results list re-renders the radar stations as ordinary
/// fuel cards, without touching `searchStateProvider`.

Station _station(String id, double lat, double lng, {double e10 = 1.5}) =>
    Station(
      id: id,
      name: 'Station $id',
      brand: 'TEST',
      street: 'Teststr.',
      postCode: '00000',
      place: 'Test',
      lat: lat,
      lng: lng,
      e10: e10,
      isOpen: true,
    );

class _FixedUserPosition extends UserPosition {
  @override
  UserPositionData? build() => UserPositionData(
        lat: 48.0,
        lng: 2.0,
        updatedAt: DateTime.now(),
        source: 'test',
      );
}

FuelStationRadar _recordedRadar(List<Station> corridor) => FuelStationRadar(
      isBulkSource: true,
      corridorCache: CorridorLocationCache(
        isBulk: true,
        corridorRadiusKm: 60,
        tileStepDegrees: 0.5,
        fetchCorridor: (lat, lng, r) async => corridor,
      ),
      priceCache: JitPriceCache(fetchPrice: (s) async => s),
    );

void main() {
  Future<void> noopRetry() async {}

  testWidgets(
      'tapping the radar button runs the radar and the list re-renders the '
      'radar stations as fuel cards — searchStateProvider untouched',
      (tester) async {
    final test = standardTestOverrides();
    when(() => test.mockStorage.hasApiKey()).thenReturn(false);
    when(() => test.mockStorage.getIgnoredIds()).thenReturn(<String>[]);
    when(() => test.mockStorage.getRatings()).thenReturn(const <String, int>{});

    await pumpApp(
      tester,
      SearchResultsContent(onGpsRetry: noopRetry),
      overrides: [
        ...test.overrides,
        userPositionProvider.overrideWith(_FixedUserPosition.new),
        fuelStationRadarProvider.overrideWithValue(
          _recordedRadar([_station('RADAR-NEAR', 48.0, 2.0)]),
        ),
        // A regular search result the radar must SUPPLANT, not mutate.
        searchStateProvider.overrideWith(() => _LoadedSearchState([testStation])),
      ].cast(),
    );

    // Before the radar runs the regular search result is on screen.
    expect(find.byKey(ValueKey('station-${testStation.id}')), findsOneWidget);

    await tester.tap(find.byKey(const Key('radarSearchButton')));
    await tester.pumpAndSettle();

    // The list now renders the radar station as a fuel card …
    expect(find.byKey(const ValueKey('station-RADAR-NEAR')), findsOneWidget);
    // … and the original search result is gone from the list.
    expect(find.byKey(ValueKey('station-${testStation.id}')), findsNothing);
    // The SearchResultsList host is still the renderer.
    expect(find.byType(SearchResultsList), findsOneWidget);
  });

  testWidgets('an active radar state renders its stations via the same list',
      (tester) async {
    final test = standardTestOverrides();
    when(() => test.mockStorage.hasApiKey()).thenReturn(false);
    when(() => test.mockStorage.getIgnoredIds()).thenReturn(<String>[]);
    when(() => test.mockStorage.getRatings()).thenReturn(const <String, int>{});

    await pumpApp(
      tester,
      SearchResultsContent(onGpsRetry: noopRetry),
      overrides: [
        ...test.overrides,
        radarSearchProvider.overrideWith(
          () => _ActiveRadar([_station('PRESET', 48.0, 2.0)]),
        ),
      ].cast(),
    );

    expect(find.byKey(const ValueKey('station-PRESET')), findsOneWidget);
    expect(find.byType(SearchResultsList), findsOneWidget);
  });
}

class _LoadedSearchState extends SearchState {
  _LoadedSearchState(this._stations);
  final List<Station> _stations;

  @override
  build() => AsyncData(
        ServiceResult(
          data: [for (final s in _stations) FuelStationResult(s)],
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
