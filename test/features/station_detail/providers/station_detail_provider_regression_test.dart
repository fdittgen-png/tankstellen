import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/service_providers.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';
import 'package:tankstellen/features/station_detail/providers/station_detail_provider.dart';

/// Regression guard for #753 — widget-tap-opens-wrong-station.
///
/// The hypothesis is that a station id coming from the widget (baked
/// into the URI as `tankstellenwidget://station?id=X`) can resolve to
/// a different station via `stationDetailProvider`. Three failure
/// vectors worth locking down with tests:
///
/// 1. The search-state short-circuit inside `stationDetailProvider`
///    filters on `station.id == stationId`. If a collision sneaks in,
///    the provider returns the WRONG station.
/// 2. When the search state has an entry with the same id from a
///    previous country, that entry wins over the current country's
///    API fallback — opening a station from a different country with
///    a colliding numeric id.
/// 3. No fallback to the API layer when the id isn't in the search
///    state, even though the widget list has long since been cached
///    independently of any search.
///
/// These tests don't fix the bug — they codify the expected
/// behaviour so any regression (or refactor that changes it) trips a
/// test rather than shipping to users.
void main() {
  group('stationDetailProvider id-resolution (#753 regression guards)', () {
    test('returns the station whose id matches — not a neighbour', () async {
      final container = _container(
        cachedSearchResults: [
          _station(id: '111', brand: 'Shell'),
          _station(id: '222', brand: 'Total'),
          _station(id: '333', brand: 'BP'),
        ],
        apiResult: null,
      );
      addTearDown(container.dispose);

      final result =
          await container.read(stationDetailProvider('222').future);
      expect(result.data.station.id, '222');
      expect(result.data.station.brand, 'Total',
          reason: 'If this returns Shell or BP, the matching filter '
              'broke — widget taps would open the wrong detail.');
    });

    test('matches id exactly — no substring or prefix fuzzy matching',
        () async {
      final container = _container(
        cachedSearchResults: [
          _station(id: 'de-111', brand: 'Shell DE'),
          _station(id: '111', brand: 'FR 111'),
          _station(id: 'ar-111', brand: 'AR 111'),
        ],
        apiResult: null,
      );
      addTearDown(container.dispose);

      final result =
          await container.read(stationDetailProvider('111').future);
      expect(result.data.station.brand, 'FR 111',
          reason: 'Must match `111` exactly, not `de-111` or `ar-111` '
              'via substring. The bug scenario in #753 is precisely '
              'this kind of cross-country id collision.');
    });

    test('falls back to stationService.getStationDetail when the id '
        'is not in the search results', () async {
      final apiStation =
          _station(id: 'api-only-999', brand: 'API Only');
      final container = _container(
        cachedSearchResults: [
          _station(id: '111', brand: 'Shell'),
        ],
        apiResult: ServiceResult(
          data: StationDetail(station: apiStation),
          source: ServiceSource.tankerkoenigApi,
          fetchedAt: DateTime.now(),
        ),
      );
      addTearDown(container.dispose);

      final result = await container
          .read(stationDetailProvider('api-only-999').future);
      expect(result.data.station.id, 'api-only-999');
      expect(result.data.station.brand, 'API Only');
    });

    test('empty id is forwarded to the service (caller responsibility)',
        () async {
      // The provider doesn't short-circuit on empty id — that's the
      // caller's job (router / widget click handler already enforce
      // non-empty ids). Locking the current behaviour here prevents
      // an accidental change from smuggling stale search-state
      // matches in when the widget URI is malformed.
      var serviceCalled = false;
      final container = _container(
        cachedSearchResults: [],
        apiResult: ServiceResult(
          data: StationDetail(station: _station(id: '', brand: 'Empty')),
          source: ServiceSource.tankerkoenigApi,
          fetchedAt: DateTime.now(),
        ),
        onGetStationDetail: () => serviceCalled = true,
      );
      addTearDown(container.dispose);

      await container.read(stationDetailProvider('').future);
      expect(serviceCalled, isTrue);
    });
  });
}

// --- helpers ----------------------------------------------------------

ProviderContainer _container({
  required List<Station> cachedSearchResults,
  required ServiceResult<StationDetail>? apiResult,
  void Function()? onGetStationDetail,
}) {
  return ProviderContainer(
    overrides: [
      stationServiceProvider.overrideWith(
        (_) => _FakeStationService(
          apiResult: apiResult,
          onGetStationDetail: onGetStationDetail,
        ),
      ),
      searchStateProvider.overrideWith(
        () => _SeededSearchState(cachedSearchResults),
      ),
    ],
  );
}

Station _station({required String id, required String brand}) => Station(
      id: id,
      name: brand,
      brand: brand,
      street: 'Chemin du test',
      postCode: '34810',
      place: 'Pomerols',
      lat: 43.4,
      lng: 3.4,
      isOpen: true,
    );

class _SeededSearchState extends SearchState {
  final List<Station> seeded;
  _SeededSearchState(this.seeded);

  @override
  AsyncValue<ServiceResult<List<SearchResultItem>>> build() {
    return AsyncValue.data(
      ServiceResult(
        data: seeded.map((s) => FuelStationResult(s)).toList(),
        source: ServiceSource.cache,
        fetchedAt: DateTime.now(),
      ),
    );
  }
}

class _FakeStationService implements StationService {
  final ServiceResult<StationDetail>? apiResult;
  final void Function()? onGetStationDetail;
  _FakeStationService({this.apiResult, this.onGetStationDetail});

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(
      String stationId) async {
    onGetStationDetail?.call();
    if (apiResult != null) return apiResult!;
    throw StateError('no api fixture for $stationId');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    dynamic cancelToken,
  }) =>
      throw UnimplementedError();

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
          List<String> ids) =>
      throw UnimplementedError();
}
