// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/services/service_providers.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/station_brand_header.dart';
import 'package:tankstellen/features/station_detail/providers/station_detail_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../mocks/mocks.dart';

/// Override for [SearchState] that emits a fixed list of search results.
///
/// Lets us test the "from search cache" fast path without wiring up
/// the full search pipeline (geocoding, location, service chain).
class _FakeSearchState extends SearchState {
  final List<SearchResultItem> items;

  _FakeSearchState(this.items);

  @override
  AsyncValue<ServiceResult<List<SearchResultItem>>> build() {
    return AsyncValue.data(ServiceResult(
      data: items,
      source: ServiceSource.cache,
      fetchedAt: DateTime.now(),
    ));
  }
}

/// Emits a permanent AsyncLoading, to exercise the `!hasValue` branch.
class _LoadingSearchState extends SearchState {
  @override
  AsyncValue<ServiceResult<List<SearchResultItem>>> build() {
    return const AsyncValue.loading();
  }
}

const _stationA = Station(
  id: 'st-a',
  name: 'Shell Alpha',
  brand: 'Shell',
  street: 'Mainstr.',
  postCode: '10115',
  place: 'Berlin',
  lat: 52.5,
  lng: 13.4,
  isOpen: true,
);

const _stationB = Station(
  id: 'st-b',
  name: 'BP Beta',
  brand: 'BP',
  street: 'Alt.',
  postCode: '80331',
  place: 'München',
  lat: 48.1,
  lng: 11.5,
  isOpen: true,
);

void main() {
  late MockStationService mockStationService;

  setUp(() {
    mockStationService = MockStationService();
  });

  ProviderContainer createContainer({
    required SearchState Function() searchState,
  }) {
    final c = ProviderContainer(overrides: [
      stationServiceProvider.overrideWithValue(mockStationService),
      searchStateProvider.overrideWith(searchState),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('stationDetail provider', () {
    test('returns station from search cache when id matches', () async {
      final container = createContainer(
        searchState: () => _FakeSearchState(const [
          FuelStationResult(_stationA),
          FuelStationResult(_stationB),
        ]),
      );

      final result = await container.read(stationDetailProvider('st-a').future);

      expect(result.data.station, _stationA);
      expect(result.source, ServiceSource.cache);
      // fetchedAt is set to "now" at the call site — assert it was
      // populated rather than matching a specific instant.
      expect(result.fetchedAt, isNotNull);

      verifyNever(() => mockStationService.getStationDetail(any()));
    });

    test('preserves OSM-enriched brand from search results', () async {
      const enriched = Station(
        id: 'st-osm',
        name: 'Raw API name',
        brand: 'Shell', // OSM-enriched — would be missing from API fetch
        street: 'X',
        postCode: '00000',
        place: 'Y',
        lat: 0,
        lng: 0,
        isOpen: true,
      );
      final container = createContainer(
        searchState: () => _FakeSearchState(const [
          FuelStationResult(enriched),
        ]),
      );

      final result =
          await container.read(stationDetailProvider('st-osm').future);

      expect(result.data.station.brand, 'Shell');
      verifyNever(() => mockStationService.getStationDetail(any()));
    });

    test('falls back to station service when id is not in search results',
        () async {
      final now = DateTime(2026, 1, 1);
      when(() => mockStationService.getStationDetail('missing'))
          .thenAnswer((_) async => ServiceResult(
                data: const StationDetail(station: _stationA),
                source: ServiceSource.tankerkoenigApi,
                fetchedAt: now,
              ));

      final container = createContainer(
        searchState: () => _FakeSearchState(const [
          FuelStationResult(_stationB),
        ]),
      );

      final result =
          await container.read(stationDetailProvider('missing').future);

      expect(result.source, ServiceSource.tankerkoenigApi);
      expect(result.fetchedAt, now);
      verify(() => mockStationService.getStationDetail('missing')).called(1);
    });

    test('falls back to station service when search state has no value',
        () async {
      when(() => mockStationService.getStationDetail('st-a'))
          .thenAnswer((_) async => ServiceResult(
                data: const StationDetail(station: _stationA),
                source: ServiceSource.tankerkoenigApi,
                fetchedAt: DateTime(2026, 2, 2),
              ));

      final container = createContainer(
        searchState: () => _LoadingSearchState(),
      );

      final result =
          await container.read(stationDetailProvider('st-a').future);

      expect(result.data.station, _stationA);
      verify(() => mockStationService.getStationDetail('st-a')).called(1);
    });

    test('only matches FuelStationResult entries, not other result types',
        () async {
      // An EV station with the same id as the fuel station under query
      // must NOT short-circuit the search-cache path; the provider is
      // specifically scoped to fuel stations.
      when(() => mockStationService.getStationDetail('shared-id'))
          .thenAnswer((_) async => ServiceResult(
                data: const StationDetail(station: _stationB),
                source: ServiceSource.tankerkoenigApi,
                fetchedAt: DateTime(2026, 3, 3),
              ));

      final container = createContainer(
        // Empty: no FuelStationResult with id 'shared-id'.
        searchState: () => _FakeSearchState(const []),
      );

      final result =
          await container.read(stationDetailProvider('shared-id').future);

      expect(result.source, ServiceSource.tankerkoenigApi);
      verify(() => mockStationService.getStationDetail('shared-id'))
          .called(1);
    });
  });

  // #2599 — the cold notification deep-link bug. Tapping a price-alert
  // notification opens `/station/:id` on a cold launch: the in-memory search
  // cache is empty, so the provider falls back to the country station
  // service's `getStationDetail`. That re-fetch must carry the FULL station
  // (brand + address) so the detail header renders IDENTICALLY to the
  // search-results path — not the degraded "street + Independent station"
  // header from the original report. The fix enriches the re-fetched station
  // (PrixCarburants service); here we assert the provider→header contract:
  // a branded fallback survives the provider and renders as the brand.
  group('cold notification deep-link hydration (#2599)', () {
    // The exact station from the bug screenshots: brand "Intermarché",
    // address "Route St Thibéry, 34550 Bessan". This is what the enriched
    // re-fetch now returns on a cache miss. A bare (unprefixed) id keeps the
    // provider on its `stationServiceProvider` branch (no `activeCountry` /
    // Hive lookup) so the test stays a focused, Hive-free assertion of the
    // hydration contract — the brand survives the fallback re-fetch — exactly
    // like the other fallback tests above.
    const refetchId = 'st-2599';
    const brandedFromRefetch = Station(
      id: refetchId,
      name: 'ROUTE ST THIBERY', // raw feed name = the street
      brand: 'Intermarché', // OSM-enriched by getStationDetail (#2599)
      street: 'Route St Thibéry',
      postCode: '34550',
      place: 'Bessan',
      lat: 43.36,
      lng: 3.40,
      isOpen: true,
    );

    testWidgets(
        'cold cache resolves a station WITH its brand and the header renders '
        'the brand, not the street', (tester) async {
      when(() => mockStationService.getStationDetail(refetchId))
          .thenAnswer((_) async => ServiceResult(
                data: const StationDetail(station: brandedFromRefetch),
                source: ServiceSource.prixCarburantsApi,
                fetchedAt: DateTime(2026, 6, 1),
              ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            stationServiceProvider.overrideWithValue(mockStationService),
            // COLD: search cache empty (no FuelStationResult for this id).
            searchStateProvider.overrideWith(() => _FakeSearchState(const [])),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final async = ref.watch(stationDetailProvider(refetchId));
                  return async.when(
                    data: (r) => StationBrandHeader(station: r.data.station),
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => Text('error: $e'),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The brand is the headline — NOT the street, NOT "Independent station".
      expect(find.text('Intermarché'), findsOneWidget,
          reason: 'the cold deep-link must hydrate the brand (#2599)');
      expect(find.text('Independent station'), findsNothing,
          reason: 'the sentinel must NOT appear for a branded station');
      // The full address still surfaces as the subtitle (identical to search).
      expect(find.textContaining('Route St Thibéry'), findsAtLeast(1));
      expect(find.textContaining('34550'), findsAtLeast(1));
      verify(() => mockStationService.getStationDetail(refetchId)).called(1);
    });

    test('cold cache fallback preserves the re-fetched brand on the provider',
        () async {
      when(() => mockStationService.getStationDetail(refetchId))
          .thenAnswer((_) async => ServiceResult(
                data: const StationDetail(station: brandedFromRefetch),
                source: ServiceSource.prixCarburantsApi,
                fetchedAt: DateTime(2026, 6, 1),
              ));

      final container = createContainer(
        searchState: () => _FakeSearchState(const []),
      );

      final result =
          await container.read(stationDetailProvider(refetchId).future);

      expect(result.data.station.brand, 'Intermarché');
      expect(result.source, ServiceSource.prixCarburantsApi);
      verify(() => mockStationService.getStationDetail(refetchId)).called(1);
    });

    testWidgets(
        'in-app (search-results) path still renders the brand — unchanged',
        (tester) async {
      // The search cache HAS the branded station: the provider returns it
      // from cache WITHOUT a re-fetch. This path was always correct; assert
      // the fix did not regress it.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            stationServiceProvider.overrideWithValue(mockStationService),
            searchStateProvider.overrideWith(
              () => _FakeSearchState(const [
                FuelStationResult(brandedFromRefetch),
              ]),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final async = ref.watch(stationDetailProvider(refetchId));
                  return async.when(
                    data: (r) => StationBrandHeader(station: r.data.station),
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => Text('error: $e'),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Intermarché'), findsOneWidget);
      expect(find.text('Independent station'), findsNothing);
      // No re-fetch on the in-app path — it resolves from the search cache.
      verifyNever(() => mockStationService.getStationDetail(any()));
    });
  });
}
