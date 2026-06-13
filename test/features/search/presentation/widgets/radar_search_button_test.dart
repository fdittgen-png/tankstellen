// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:tankstellen/core/location/user_position_provider.dart';
import 'package:tankstellen/core/services/radar/corridor_location_cache.dart';
import 'package:tankstellen/core/services/radar/jit_price_cache.dart';
import 'package:tankstellen/core/services/service_providers.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/approach/providers/fuel_station_radar_provider.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/search/presentation/widgets/radar_search_fab.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_results_content.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_results_list.dart';
import 'package:tankstellen/features/search/providers/radar_search_provider.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';

import '../../../../fixtures/stations.dart';
import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// #2682 — the radar launches from a "Start recording"-style extended-FAB pill
/// ([RadarSearchFab]), styled like the trip `TrajetsRecordFab` (a brand-tinted
/// rounded [FloatingActionButton.extended] with a leading icon + label) — NOT
/// the cramped #2675 header IconButton. Tapping it runs the on-search radar and
/// the SAME results list re-renders the radar stations as ordinary fuel cards,
/// without touching `searchStateProvider`. When the radar is active the pill
/// flips to a stop treatment that dismisses it.

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

  // #2806 — runRadar now refreshes the live fix first; keep the fixed point
  // (and off the geolocator method channel) in the widget test.
  @override
  Future<void> updateFromGps() async {}
}

/// #2806 — runRadar now merges a direct in-radius fetch; this empty service
/// keeps that merge deterministic (and off the network) so the recorded
/// corridor remains the only source under test.
class _EmptyStationService implements StationService {
  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async =>
      ServiceResult(
        data: const <Station>[],
        source: ServiceSource.cache,
        fetchedAt: DateTime.now(),
      );

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String stationId) =>
      throw UnimplementedError();

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) =>
      throw UnimplementedError();
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

  group('RadarSearchFab', () {
    testWidgets(
        'renders as a FloatingActionButton.extended (the "Start recording" '
        'pill style), idle label, with a leading radar icon', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const RadarSearchFab(),
        overrides: test.overrides.cast(),
      );

      // It is the extended-FAB pill, not a bare IconButton.
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.widgetWithIcon(FloatingActionButton, Icons.radar),
          findsOneWidget);
      expect(find.text('Start fuel station radar'), findsOneWidget);
    });

    testWidgets('tapping the pill runs the radar and the list re-renders the '
        'radar stations as fuel cards — searchStateProvider untouched',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getIgnoredIds()).thenReturn(<String>[]);
      when(() => test.mockStorage.getRatings())
          .thenReturn(const <String, int>{});

      // Pump the content + pill together so the single radar provider drives
      // both: the pill is the launch affordance, the content is the renderer.
      await pumpApp(
        tester,
        Column(
          children: [
            const RadarSearchFab(),
            Expanded(child: SearchResultsContent(onGpsRetry: noopRetry)),
          ],
        ),
        overrides: [
          ...test.overrides,
          userPositionProvider.overrideWith(_FixedUserPosition.new),
          fuelStationRadarProvider.overrideWithValue(
            _recordedRadar([_station('RADAR-NEAR', 48.0, 2.0)]),
          ),
          stationServiceProvider.overrideWithValue(_EmptyStationService()),
          // A regular search result the radar must SUPPLANT, not mutate.
          searchStateProvider
              .overrideWith(() => _LoadedSearchState([testStation])),
        ].cast(),
      );

      // Before the radar runs the regular search result is on screen.
      expect(
          find.byKey(ValueKey('station-${testStation.id}')), findsOneWidget);

      await tester.tap(find.byKey(const Key('radarSearchButton')));
      await tester.pumpAndSettle();

      // The list now renders the radar station as a fuel card …
      expect(find.byKey(const ValueKey('station-RADAR-NEAR')), findsOneWidget);
      // … and the original search result is gone from the list.
      expect(find.byKey(ValueKey('station-${testStation.id}')), findsNothing);
      // The SearchResultsList host is still the renderer.
      expect(find.byType(SearchResultsList), findsOneWidget);
    });

    testWidgets(
        'while a run is initialising the pill shows a spinner + "Searching…" '
        'so the user sees the radar is working (#3290)', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      // `settle: false` — the spinner animates forever, so pumpAndSettle would
      // hang; a single frame is enough to assert the first paint.
      await pumpApp(
        tester,
        const RadarSearchFab(),
        overrides: [
          ...test.overrides,
          radarSearchProvider.overrideWith(_InitialisingRadar.new),
        ].cast(),
        settle: false,
      );

      // A working spinner + "Searching…" — NOT the silent flip to "Stop radar"
      // or "Start" that gave no sign the scan was running.
      expect(find.text('Searching…'), findsOneWidget);
      expect(
          find.descendant(
            of: find.byType(FloatingActionButton),
            matching: find.byType(CircularProgressIndicator),
          ),
          findsOneWidget);
      expect(find.text('Stop radar'), findsNothing);
      expect(find.text('Start fuel station radar'), findsNothing);
      expect(find.widgetWithIcon(FloatingActionButton, Icons.stop_circle),
          findsNothing);

      // It stays tappable so the user can cancel mid-scan — dismiss flips it
      // back to the idle start treatment (no spinner left to animate).
      await tester.tap(find.byKey(const Key('radarSearchButton')));
      await tester.pump();
      expect(find.text('Start fuel station radar'), findsOneWidget);
    });

    testWidgets(
        'when the radar is active the pill flips to a stop treatment that '
        'dismisses it', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const RadarSearchFab(),
        overrides: [
          ...test.overrides,
          radarSearchProvider.overrideWith(
            () => _ActiveRadar([_station('PRESET', 48.0, 2.0)]),
          ),
        ].cast(),
      );

      // Active → a clear "Stop radar" label + a meaningful stop_circle icon
      // (#2744 — not the ambiguous "Étape"/close treatment), not the start
      // label.
      expect(find.text('Stop radar'), findsOneWidget);
      expect(find.text('Stop'), findsNothing);
      expect(find.text('Start fuel station radar'), findsNothing);
      expect(find.widgetWithIcon(FloatingActionButton, Icons.stop_circle),
          findsOneWidget);
      expect(
          find.widgetWithIcon(FloatingActionButton, Icons.close), findsNothing);

      // Tapping it dismisses the radar (flips back to the start treatment).
      await tester.tap(find.byKey(const Key('radarSearchButton')));
      await tester.pumpAndSettle();
      expect(find.text('Start fuel station radar'), findsOneWidget);
      expect(find.widgetWithIcon(FloatingActionButton, Icons.radar),
          findsOneWidget);
    });
  });

  testWidgets('the old header radar IconButton is gone from SearchResultsList',
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
        searchStateProvider.overrideWith(() => _LoadedSearchState([testStation])),
      ].cast(),
    );

    // The launch affordance no longer lives inside the results list header —
    // it is the screen-level FAB pill now.
    expect(find.byKey(const Key('radarSearchButton')), findsNothing);
    expect(find.byType(RadarSearchFab), findsNothing);
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

/// #3290 — an active radar still acquiring its first fix: `locating` true with
/// the list still loading. The pill must render the spinner + "Searching…"
/// rather than the bare "Stop radar" treatment.
class _InitialisingRadar extends RadarSearch {
  @override
  RadarSearchState build() => const RadarSearchState(
        active: true,
        locating: true,
        stations: AsyncLoading<List<Station>>(),
      );
}
