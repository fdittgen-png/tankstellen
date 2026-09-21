// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4348 — reference prices and unavailable providers must not pose as
/// navigable live stations.
///
/// Every case drives the REAL station service over its recorded response
/// (`recorded_country_search.dart`, #4180) and then the REAL production
/// consumer — the gated launcher, the decision provider, the plan
/// provider, the search chain. A hand-built `Station(lat: …)` would prove
/// the gate reads a flag; it would not prove the flag is set on what the
/// Luxembourg adapter actually emits (the `feedback_fake_services_false_
/// green` trap).
///
/// Mutation proof: set `kLuCapability.coordinates` (or `kGrCapability`'s)
/// to true and the reference-point groups below fail.
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/refuel_economics.dart';
import 'package:tankstellen/core/domain/refuel_profile_provider.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/domain/tank_state_provider.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/country_service_registry.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_offer.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/services/station_service_chain.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/core/utils/navigation_utils.dart';
import 'package:tankstellen/core/utils/station_extensions.dart';
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';
import 'package:tankstellen/features/route_search/providers/route_search_provider.dart';
import 'package:tankstellen/features/search/providers/refuel_decision_provider.dart';
import 'package:tankstellen/features/search/providers/refuel_plan_provider.dart';
import 'package:tankstellen/features/search/providers/search_filters_provider.dart';
import 'package:tankstellen/features/search/providers/station_travel_estimates_provider.dart';

import '../../features/station_services/support/recorded_country_search.dart';
import '../../helpers/silence_error_logger.dart';

class _CountingPrimary implements StationService {
  int searches = 0;
  Exception? failWith;

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    searches++;
    final error = failWith;
    if (error != null) throw error;
    return ServiceResult(
      data: const [],
      source: ServiceSource.tankerkoenigApi,
      fetchedAt: DateTime.utc(2026, 9, 16),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockCache extends Mock implements CacheManager {}

class _FixedFuel extends SelectedFuelType {
  @override
  FuelType build() => FuelType.e10;
}

class _FixedRoute extends RouteSearchState {
  _FixedRoute(this._result);
  final RouteSearchResult _result;

  @override
  AsyncValue<RouteSearchResult?> build() => AsyncValue.data(_result);
}

void main() {
  silenceErrorLoggerSpool();

  late List<Station> lu;
  late List<Station> gr;
  late List<Station> de;
  late List<Station> fr;
  late List<Station> dk;
  final launched = <Uri>[];

  String fixture(String name) =>
      File('test/fixtures/$name').readAsStringSync();

  setUpAll(() async {
    lu = await searchLuxembourgStations(
      essenceBody: fixture('lu_lustat_essence_slice.json'),
      dieselBody: fixture('lu_lustat_diesel_slice.json'),
      params: const SearchParams(lat: 49.6116, lng: 6.1319, radiusKm: 50),
    );
    gr = await searchGreeceStations(
      fixture('gr_selfpublished_latest.json'),
      params: const SearchParams(lat: 37.9838, lng: 23.7275, radiusKm: 200),
      now: DateTime(2026, 7, 14),
    );
    de = await searchGermanyStations(
      fixture('de_tankerkoenig_list_slice.json'),
      params: const SearchParams(lat: 52.52, lng: 13.405, radiusKm: 3),
    );
    fr = await searchFranceStations(
      fixture('prix_carburants_paris_geo_ordered.json'),
      params: const SearchParams(lat: 48.8566, lng: 2.3522, radiusKm: 10),
    );
    dk = await searchDenmarkStations(
      okBody: fixture('dk_ok_prices_slice.json'),
      shellBody: fixture('dk_shell_prices_slice.json'),
      params: const SearchParams(lat: 55.4, lng: 11.5, radiusKm: 200),
    );
  });

  setUp(() {
    launched.clear();
    NavigationUtils.launcher = (uri, mode) async {
      launched.add(uri);
      return true;
    };
  });
  tearDown(NavigationUtils.resetLauncher);

  StationOffer offerOf(Station s) =>
      StationOffer.forStation(stationId: s.id, lat: s.lat, lng: s.lng);

  group('a reference price is a price, never a place (LU, GR)', () {
    test('the recorded fixtures are non-empty, so the loops below bite', () {
      expect(lu, isNotEmpty);
      expect(gr, isNotEmpty);
    });

    for (final (name, stationsOf) in [
      ('Luxembourg decree centroids', () => lu),
      ('Greek prefecture averages', () => gr),
    ]) {
      test('$name resolve as reference points with no drive-to action',
          () {
        for (final s in stationsOf()) {
          final offer = offerOf(s);
          expect(offer.locationKind, StationLocationKind.referencePoint,
              reason: '${s.id} is a stand-in point');
          expect(offer.canNavigate, isFalse);
          expect(offer.canRouteTo, isFalse);
          expect(offer.canHoldStationRanking, isFalse);
        }
      });

      test('$name keep their real price', () {
        expect(stationsOf().any((s) => (s.priceFor(FuelType.diesel) ?? 0) > 0),
            isTrue,
            reason: 'the gate removes the action, never the price');
      });

      test('$name launch nothing through the shared launcher', () async {
        for (final s in stationsOf()) {
          final ok = await NavigationUtils.openStation(
              stationId: s.id, lat: s.lat, lng: s.lng, label: s.name);
          expect(ok, isFalse);
        }
        expect(launched, isEmpty,
            reason: 'a town square is not a destination');
      });
    }
  });

  group('a real forecourt keeps every action (DE, FR)', () {
    for (final (name, stationsOf) in [
      ('Tankerkönig Berlin', () => de),
      ('Prix-Carburants Paris', () => fr),
    ]) {
      test('$name resolve as physical stations', () {
        expect(stationsOf(), isNotEmpty);
        for (final s in stationsOf()) {
          final offer = offerOf(s);
          expect(offer.locationKind, StationLocationKind.physicalStation,
              reason: s.id);
          expect(offer.canNavigate, isTrue);
          expect(offer.canRouteTo, isTrue);
          expect(offer.coverageComplete, isTrue);
        }
      });

      test('$name launch the maps app at the station coordinates', () async {
        final s = stationsOf().first;
        final ok = await NavigationUtils.openStation(
            stationId: s.id, lat: s.lat, lng: s.lng, label: s.name);
        expect(ok, isTrue);
        expect(launched, hasLength(1));
        expect(launched.single.scheme, 'geo');
        expect(launched.single.path, '${s.lat},${s.lng}');
      });
    }
  });

  group('the decision provider — mixed cross-border results', () {
    ProviderContainer container() => ProviderContainer(overrides: [
          selectedFuelTypeProvider.overrideWith(_FixedFuel.new),
          refuelProfileProvider.overrideWithValue(const RefuelProfile(
              consumptionLPer100km: 7, litresIntended: 40)),
          appClockProvider
              .overrideWithValue(FixedClock(DateTime(2026, 9, 16, 12))),
        ]);

    test('a reference price that WOULD win every ranking holds none', () {
      // The LU centroid is placed nearest and priced cheapest, so if the
      // capability were ignored it would be cheapest, closest AND best
      // value. Each result resolves through its OWN country.
      final luRef = lu.first.copyWith(dist: 0.1, e10: 0.5);
      final deReal = de.first.copyWith(dist: 2.0);
      final items = [FuelStationResult(luRef), FuelStationResult(deReal)];
      final c = container();
      addTearDown(c.dispose);

      final decision = c.read(refuelDecisionProvider(items));

      expect(decision.quotes, hasLength(2),
          reason: 'the reference price stays visible');
      final luQuote = decision.quotes
          .firstWhere((q) => q.candidate.stationId == luRef.id);
      expect(luQuote.candidate.isPhysicalStation, isFalse);
      expect(luQuote.cost, isNull, reason: 'no detour to a stand-in point');
      for (final pick in [
        decision.cheapest,
        decision.closest,
        decision.bestValue,
      ]) {
        expect(pick?.candidate.stationId, deReal.id);
      }
      expect(decision.rankingsFor(luRef.id), isEmpty);
    });

    test('Denmark qualifies its picks as partial coverage; DE does not', () {
      final c = container();
      addTearDown(c.dispose);
      final dkItems = [
        for (final s in dk.take(3)) FuelStationResult(s),
      ];
      final deItems = [
        for (final s in de.take(3)) FuelStationResult(s),
      ];
      expect(dkItems, isNotEmpty);
      expect(c.read(refuelDecisionProvider(dkItems)).coverageIncomplete,
          isTrue);
      expect(c.read(refuelDecisionProvider(deItems)).coverageIncomplete,
          isFalse);
    });
  });

  group('the route plan never stops at a reference point', () {
    test('an LU centroid on the route is not a candidate stop', () {
      final luRef = lu.first.copyWith(e10: 0.5);
      final deReal = de.first;
      // The route starts ~35 km west of the centroid, so the centroid sits
      // AHEAD on it — cheap, in range, and the obvious greedy first stop if
      // the capability were ignored.
      final geometry = [
        LatLng(luRef.lat, luRef.lng - 0.5),
        LatLng(luRef.lat, luRef.lng),
        LatLng(deReal.lat, deReal.lng),
      ];
      final c = ProviderContainer(overrides: [
        routeSearchStateProvider.overrideWith(() => _FixedRoute(
              RouteSearchResult(
                route: RouteInfo(
                  geometry: geometry,
                  distanceKm: 600,
                  durationMinutes: 360,
                  samplePoints: geometry,
                ),
                stations: [FuelStationResult(luRef), FuelStationResult(deReal)],
              ),
            )),
        refuelProfileProvider.overrideWithValue(
            const RefuelProfile(consumptionLPer100km: 7)),
        tankStateProvider.overrideWithValue(
            const TankState(capacityL: 60, currentL: 12)),
        selectedFuelTypeProvider.overrideWith(_FixedFuel.new),
        travelEstimateFetcherProvider
            .overrideWithValue((context, stops) async => const []),
      ]);
      addTearDown(c.dispose);

      final plans = c.read(refuelPlanProvider).plans;
      expect(plans, isNotNull);
      final stops = [
        ...?plans!.cheapest?.stops,
        ...?plans.fastest?.stops,
      ];
      expect(plans.isFeasible, isFalse,
          reason: 'without a real forecourt in range a 12 L tank cannot '
              'reach Berlin — the honest answer is the gap, not a stop at '
              'a town square');
      expect(stops.map((s) => s.candidate.stationId), isNot(contains(luRef.id)));
    });
  });

  group('an unavailable provider is structural, not a failed request', () {
    setUpAll(() {
      registerFallbackValue(Duration.zero);
      registerFallbackValue(ServiceSource.values.first);
    });

    test('Australia (coverage: none) is refused before any fetch, every time',
        () async {
      final primary = _CountingPrimary();
      final chain = StationServiceChain(primary, _MockCache(),
          countryCode: 'AU',
          capability: CountryServiceRegistry.capabilityFor('AU'));
      const params = SearchParams(lat: -33.87, lng: 151.21, radiusKm: 5);
      for (var i = 0; i < 3; i++) {
        await expectLater(chain.searchStations(params),
            throwsA(isA<ProviderUnavailableException>()
                .having((e) => e.countryCode, 'country', 'AU')));
      }
      expect(primary.searches, 0,
          reason: 'no futile request loop against a retired endpoint');
    });

    test('a transient network failure in a live country is NOT reported as '
        'unavailable', () async {
      final primary = _CountingPrimary()
        ..failWith = DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionTimeout,
        );
      final cache = _MockCache();
      when(() => cache.getFresh(any())).thenReturn(null);
      when(() => cache.get(any())).thenReturn(null);
      StationServiceChain.transientRetryDelay = const Duration(milliseconds: 1);
      addTearDown(() => StationServiceChain.transientRetryDelay =
          const Duration(milliseconds: 500));
      final chain = StationServiceChain(primary, cache,
          countryCode: 'DE',
          capability: CountryServiceRegistry.capabilityFor('DE'));
      await expectLater(
        chain.searchStations(
            const SearchParams(lat: 52.52, lng: 13.405, radiusKm: 3)),
        throwsA(isNot(isA<ProviderUnavailableException>())),
      );
      expect(primary.searches, greaterThan(0),
          reason: 'a live provider is still asked');
    });
  });
}
