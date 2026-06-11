// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/service_providers.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';
import 'package:tankstellen/features/route_search/providers/route_search_provider.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';
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

  // #2408 — a non-resolvable / stale deep-link id used to await a country
  // fetch that never completed, leaving StationDetailScreen stuck in the
  // shimmer skeleton forever. The provider now bounds that fallback fetch
  // so it throws (surfacing the screen's EXISTING error/retry branch).
  group('stationDetailProvider fallback timeout (#2408)', () {
    test('surfaces an error when the fallback fetch never resolves', () {
      fakeAsync((async) {
        final container = ProviderContainer(
          overrides: [
            stationServiceProvider.overrideWith(
              (_) => _HangingStationService(),
            ),
            // No search-cache match → the provider takes the bounded
            // fallback-fetch path for this unresolvable id.
            searchStateProvider.overrideWith(() => _SeededSearchState(const [])),
          ],
        );
        addTearDown(container.dispose);

        Object? caught;
        var completed = false;
        // Swallow the error here (assert on `caught`) so the rejected
        // future does not surface as an unhandled async error inside the
        // fake zone — re-throwing would fail the test even though the
        // timeout behaviour is exactly what we want.
        unawaited(
          container
              .read(stationDetailProvider('never-resolves').future)
              .then((_) => completed = true)
              .onError((Object e, _) {
            caught = e;
            return false;
          }),
        );

        // Before the timeout elapses the future is still pending.
        async.elapse(const Duration(seconds: 11));
        expect(caught, isNull);
        expect(completed, isFalse);

        // Past the 12s bound the fallback fetch is abandoned and errors.
        async.elapse(const Duration(seconds: 2));
        expect(caught, isA<TimeoutException>(),
            reason: 'a bounded fetch lets the screen show retry instead of '
                'shimmering forever');
      });
    });
  });

  // #2763 — a station tapped from the "cheapest along my route" list lives in
  // `routeSearchStateProvider`, not `searchStateProvider`. Before the fix the
  // fast path only consulted search state, so a route tap fell through to the
  // network — and a transient empty feed slice mislabeled as a 404 spammed 8
  // ERROR traces. The route-state fast path must render it from cache with NO
  // network call and NO throw.
  group('stationDetailProvider route-search fast path (#2763)', () {
    test('renders a route-list station from cache — no network, no throw',
        () async {
      var serviceCalled = false;
      final container = _container(
        cachedSearchResults: const [],
        cachedRouteResults: [
          _station(id: 'fr-11100013', brand: 'Intermarché'),
        ],
        apiResult: null,
        onGetStationDetail: () => serviceCalled = true,
      );
      addTearDown(container.dispose);

      final result =
          await container.read(stationDetailProvider('fr-11100013').future);

      expect(result.data.station.id, 'fr-11100013');
      expect(result.data.station.brand, 'Intermarché',
          reason: 'the OSM-enriched brand from the route result must survive');
      expect(result.source, ServiceSource.cache);
      expect(serviceCalled, isFalse,
          reason: 'a route tap must short-circuit the network entirely — '
              'this is the cure for the 8× "station not found" storm');
    });

    test('still matches the route id EXACTLY — no cross-country collision',
        () async {
      final container = _container(
        cachedSearchResults: const [],
        cachedRouteResults: [
          _station(id: 'fr-111', brand: 'FR 111'),
          _station(id: 'ar-111', brand: 'AR 111'),
        ],
        apiResult: null,
      );
      addTearDown(container.dispose);

      final result =
          await container.read(stationDetailProvider('ar-111').future);
      expect(result.data.station.brand, 'AR 111',
          reason: 'exact id match preserves the #753 guarantee on the '
              'route-state path too');
    });
  });

  // #2763 Fix 3 — defense-in-depth. On a cold deep-link race the search/route
  // state can populate AFTER the fast-path read, so the network call runs and
  // the chain throws. The provider must re-check state and serve the cached
  // Station rather than hard-failing the screen — but ONLY when the id is
  // actually held; otherwise the #2408 error/retry branch must still surface.
  group('stationDetailProvider network-branch last-resort fallback (#2763)',
      () {
    test(
        'id absent at fast-path read but present when the chain throws → '
        'serves the cached Station instead of rethrowing', () async {
      // Cold deep-link race: route state is EMPTY when the fast path reads it,
      // so the provider proceeds to the network. The async fetch yields; while
      // it is suspended the route search resolves (modelled by the service
      // populating route state right before it throws). The provider's catch
      // must re-read the now-populated state and serve the Station.
      // Unprefixed id → the fallback takes the `originCountry == null` branch
      // (just `stationServiceProvider`), so the test needs no Hive / active-
      // country override — the same convention the #2408 test uses.
      late ProviderContainer container;
      container = _container(
        cachedSearchResults: const [],
        cachedRouteResults: const [], // EMPTY at fast-path read
        apiResult: null,
        onGetStationDetail: () {
          // The route search "finished" mid-fetch — populate state now.
          (container.read(routeSearchStateProvider.notifier)
                  as _SeededRouteState)
              .seedLate(_station(id: 'late-22200099', brand: 'Esso'));
        },
        apiError: const ServiceChainExhaustedException(errors: []),
      );
      addTearDown(container.dispose);

      final result =
          await container.read(stationDetailProvider('late-22200099').future);
      expect(result.data.station.brand, 'Esso',
          reason: 'the chain threw, but the app already holds the station — '
              'the screen must never hard-fail in that case');
      expect(result.source, ServiceSource.cache);
    });

    test(
        'rethrows when the chain throws AND neither search nor route holds '
        'the id (preserves the #2408 error/retry branch)', () async {
      final container = _container(
        cachedSearchResults: const [],
        cachedRouteResults: const [],
        apiResult: null,
        apiError: const ServiceChainExhaustedException(errors: []),
      );
      addTearDown(container.dispose);

      final sub = container.listen(
        stationDetailProvider('absent-99999999'),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      // Pump until the provider leaves the loading state (the rejected fetch
      // future settles within a few microtasks — the fake throws eagerly).
      AsyncValue<ServiceResult<StationDetail>> value = sub.read();
      for (var i = 0; i < 100 && value.isLoading; i++) {
        await Future<void>.delayed(Duration.zero);
        value = sub.read();
      }

      expect(value.hasError, isTrue);
      expect(value.error, isA<ServiceChainExhaustedException>(),
          reason: 'when neither search nor route holds the id, the chain error '
              'must surface so the screen shows its error/retry branch — the '
              'cache fallback only fires when state holds it');
    });
  });
}

/// A station service whose detail fetch never completes — models a
/// non-resolvable / stale deep-link id (the old `debug-test-station`, or a
/// retired widget-row station).
class _HangingStationService implements StationService {
  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String stationId) =>
      Completer<ServiceResult<StationDetail>>().future;

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

// --- helpers ----------------------------------------------------------

ProviderContainer _container({
  required List<Station> cachedSearchResults,
  required ServiceResult<StationDetail>? apiResult,
  List<Station> cachedRouteResults = const [],
  void Function()? onGetStationDetail,
  Object? apiError,
}) {
  return ProviderContainer(
    overrides: [
      stationServiceProvider.overrideWith(
        (_) => _FakeStationService(
          apiResult: apiResult,
          onGetStationDetail: onGetStationDetail,
          apiError: apiError,
        ),
      ),
      searchStateProvider.overrideWith(
        () => _SeededSearchState(cachedSearchResults),
      ),
      routeSearchStateProvider.overrideWith(
        () => _SeededRouteState(cachedRouteResults),
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

/// Seeds `routeSearchStateProvider` with a [RouteSearchResult] whose
/// `stations` are the given fuel stations — models a tap from the
/// "cheapest along my route" list (#2763).
class _SeededRouteState extends RouteSearchState {
  final List<Station> seeded;
  _SeededRouteState(this.seeded);

  @override
  AsyncValue<RouteSearchResult?> build() => _resultFor(seeded);

  /// Models a route search that resolves AFTER the provider's fast-path
  /// read — the #2763 Fix-3 cold-deep-link race.
  void seedLate(Station station) {
    state = _resultFor([station]);
  }

  static AsyncValue<RouteSearchResult?> _resultFor(List<Station> stations) {
    if (stations.isEmpty) return const AsyncValue.data(null);
    return AsyncValue.data(
      RouteSearchResult(
        route: const RouteInfo(
          geometry: <LatLng>[],
          distanceKm: 0,
          durationMinutes: 0,
          samplePoints: <LatLng>[],
        ),
        stations: stations.map((s) => FuelStationResult(s)).toList(),
      ),
    );
  }
}

class _FakeStationService implements StationService {
  final ServiceResult<StationDetail>? apiResult;
  final void Function()? onGetStationDetail;
  final Object? apiError;
  _FakeStationService({this.apiResult, this.onGetStationDetail, this.apiError});

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(
      String stationId) async {
    onGetStationDetail?.call();
    if (apiError != null) throw apiError!;
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
