// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/background/background_price_source.dart';
import 'package:tankstellen/core/services/country_service_registry.dart';
import 'package:tankstellen/core/services/fuel_service_policy.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

import '../../fakes/fake_storage_repository.dart';

/// A recording fake [StationService] for one country: counts how many times
/// `getPrices` / `searchStations` are called and returns canned data so the
/// #2862 source's per-country fan-out + Tankerkönig-shape adaptation can be
/// asserted without any network.
class _RecordingService implements StationService {
  _RecordingService(this.code);

  final String code;
  int priceCalls = 0;
  int searchCalls = 0;
  final List<List<String>> idsSeen = [];

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
      List<String> ids) async {
    priceCalls++;
    idsSeen.add(ids);
    return ServiceResult(
      data: {
        for (final id in ids)
          id: const StationPrices(
            e5: 1.5,
            e10: 1.4,
            diesel: 1.6,
            status: 'open',
          ),
      },
      source: ServiceSource.tankerkoenigApi,
      fetchedAt: DateTime(2026),
    );
  }

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    searchCalls++;
    return ServiceResult(
      data: const [],
      source: ServiceSource.tankerkoenigApi,
      fetchedAt: DateTime(2026),
    );
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String stationId) =>
      throw UnimplementedError();
}

/// A [StationService] whose calls all throw — for the #2349 never-throws
/// fault-injection: the BG isolate must spool, never rethrow, a provider fault.
class _ThrowingService implements StationService {
  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
          List<String> ids) async =>
      throw const SocketException('injected fault');
  @override
  Future<ServiceResult<List<Station>>> searchStations(SearchParams params,
          {CancelToken? cancelToken}) async =>
      throw const SocketException('injected fault');
  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String stationId) =>
      throw UnimplementedError();
}

void main() {
  group('isPolled', () {
    test('the 11 polled providers are recognised; bulk + stub are not', () {
      for (final code in ['DE', 'AT', 'PT', 'GB', 'LU', 'SI', 'GR', 'RO',
        'MX', 'KR', 'CL']) {
        expect(BackgroundPriceSource.isPolled(code), isTrue,
            reason: '$code must be polled');
      }
      // Bulk-dataset countries (child #2863) + the AU stub are NOT scanned.
      for (final code in ['ES', 'IT', 'AR', 'DK', 'FR', 'AU', 'ZZ']) {
        expect(BackgroundPriceSource.isPolled(code), isFalse,
            reason: '$code must NOT be polled by this source');
      }
    });
  });

  group('fetchPricesGrouped — one provider hit per country', () {
    late Map<String, _RecordingService> built;
    late BackgroundPriceSource source;

    setUp(() {
      built = {};
      source = BackgroundPriceSource(
        storage: FakeStorageRepository(),
        serviceBuilder: (code, {String? apiKey}) {
          // Each country's service is built lazily; count builds per code.
          return built.putIfAbsent(code, () => _RecordingService(code));
        },
      );
    });

    test('alerts in DE + AT + PT fetch each via its OWN service, ONCE each',
        () async {
      final prices = await source.fetchPricesGrouped(
        stationIds: [
          'de-1', 'de-2', // DE — two stations
          'at-1', // AT
          'pt-1', 'pt-2', 'pt-3', // PT — three stations
        ],
      );

      // Three providers built, each exactly once.
      expect(built.keys.toSet(), {'DE', 'AT', 'PT'});
      expect(built['DE']!.priceCalls, 1, reason: 'DE provider hit once');
      expect(built['AT']!.priceCalls, 1, reason: 'AT provider hit once');
      expect(built['PT']!.priceCalls, 1, reason: 'PT provider hit once');

      // Each provider received exactly its own country's ids.
      expect(built['DE']!.idsSeen.single.toSet(), {'de-1', 'de-2'});
      expect(built['AT']!.idsSeen.single, ['at-1']);
      expect(built['PT']!.idsSeen.single.toSet(), {'pt-1', 'pt-2', 'pt-3'});

      // The merged result spans all six stations in Tankerkönig shape.
      expect(prices.keys.toSet(),
          {'de-1', 'de-2', 'at-1', 'pt-1', 'pt-2', 'pt-3'});
      expect(prices['pt-1']!['status'], 'open');
      expect(prices['pt-1']!['e5'], 1.5);
      expect(prices['pt-1']!['diesel'], 1.6);
    });

    test('a fetch + a radius search for the same country reuse one service',
        () async {
      await source.fetchPricesGrouped(stationIds: ['de-1']);
      await source.searchStations(
        countryCode: 'DE',
        params: const SearchParams(lat: 52.5, lng: 13.4, radiusKm: 5),
      );
      // ONE DE service, used for both — not rebuilt for the search.
      expect(built.keys, ['DE']);
      expect(built['DE']!.priceCalls, 1);
      expect(built['DE']!.searchCalls, 1);
    });

    test('ids for an unpolled (bulk) country are skipped — no service built',
        () async {
      final prices = await source.fetchPricesGrouped(
        stationIds: ['es-1', 'it-1'], // ES + IT are bulk (child #2863)
      );
      expect(prices, isEmpty);
      expect(built, isEmpty, reason: 'no bulk-country provider may be built');
    });

    test('a prefix-less id falls back to the active country', () async {
      await source.fetchPricesGrouped(
        stationIds: ['rawuuid-no-prefix'],
        fallbackCountryCode: 'DE',
      );
      expect(built.keys, ['DE']);
      expect(built['DE']!.idsSeen.single, ['rawuuid-no-prefix']);
    });

    test('a prefix-less id with no fallback is dropped', () async {
      final prices =
          await source.fetchPricesGrouped(stationIds: ['rawuuid']);
      expect(prices, isEmpty);
      expect(built, isEmpty);
    });
  });

  group('minInterval is honoured per country (#2862)', () {
    test('every polled country carries a positive minInterval the chain uses',
        () {
      for (final code in kBackgroundPolledCountries) {
        final policy = CountryServiceRegistry.policyFor(code);
        expect(policy, isNotNull, reason: '$code must have a policy');
        expect(policy!.minInterval, greaterThan(Duration.zero),
            reason: '$code minInterval must throttle the BG scan');
        expect(policy.model, SourceModel.polledApi,
            reason: '$code is a polled provider, not bulk');
      }
    });

    test('50 DE alerts → ONE provider request per scan (rate bounded by the '
        'scan cadence, not the alert count)', () async {
      // The chain/fetcher batches internally, so a scan with many same-country
      // stations is still a single provider call — the per-provider request
      // rate cannot breach minInterval just because the user has more alerts.
      final services = <String, _RecordingService>{};
      final source = BackgroundPriceSource(
        storage: FakeStorageRepository(),
        serviceBuilder: (code, {String? apiKey}) =>
            services.putIfAbsent(code, () => _RecordingService(code)),
      );
      await source.fetchPricesGrouped(
        stationIds: List.generate(50, (i) => 'de-$i'),
      );
      expect(services['DE']!.priceCalls, 1);
    });
  });

  group('never throws — a provider fault is spooled, not propagated (#2349)', () {
    BackgroundPriceSource throwingSource() => BackgroundPriceSource(
          storage: FakeStorageRepository(),
          serviceBuilder: (code, {String? apiKey}) => _ThrowingService(),
        );

    test('fetchPricesGrouped completes (spools the fault) when the provider '
        'throws — never rethrows into the OS-spawned isolate', () async {
      // The documented never-throws boundary (background_price_source.dart):
      // a throwing per-country service must be caught + spooled, never bubble.
      await expectLater(
        throwingSource().fetchPricesGrouped(stationIds: ['de-1', 'at-1']),
        completes,
      );
      final prices =
          await throwingSource().fetchPricesGrouped(stationIds: ['de-1']);
      expect(prices, isEmpty,
          reason: 'a thrown fetch yields no prices, not a crash');
    });

    test('searchStations swallows a throwing provider', () {
      expect(
        () => throwingSource().searchStations(
          countryCode: 'DE',
          params: const SearchParams(lat: 52.5, lng: 13.4, radiusKm: 5),
        ),
        returnsNormally,
      );
    });
  });
}
