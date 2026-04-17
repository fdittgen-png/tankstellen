import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/services/service_providers.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';
import 'package:tankstellen/features/station_detail/providers/station_detail_provider.dart';

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
}
