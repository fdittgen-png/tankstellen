// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/features/station_services/uk/uk_cma_bulk_station_service.dart';
import 'package:tankstellen/features/station_services/uk/uk_fuel_finder_auth.dart';
import 'package:tankstellen/features/station_services/uk/uk_fuel_finder_feed.dart';
import 'package:tankstellen/features/station_services/uk/uk_station_service.dart';

/// #3190 — the statutory Fuel Finder feed (token → paged `/api/v1/pfs` +
/// `/api/v1/pfs/fuel-prices` → CMA-shaped merge → shared parseCmaStations).
///
/// Fixture provenance: `test/fixtures/uk_fuel_finder_pfs_slice.json` and
/// `uk_fuel_finder_pfs_prices_slice.json` are **contract-derived**, NOT live
/// recordings — the statutory API requires registered OAuth2 credentials that
/// this repo does not (and must not) hold, so a live capture is impossible
/// here. Field names, envelope shape, grade codes and pence-per-litre pricing
/// were cross-checked against the GOV.UK developer-portal documentation and a
/// working open-source consumer of the live API (2026-07-03). The first live
/// credentialed run must replace these with trimmed real recordings — see the
/// #3190 closing notes.
dynamic _fixture(String name) => jsonDecode(
      File('test/fixtures/$name').readAsStringSync(),
    );

/// Serves the token endpoint plus per-path batch queues, capturing every
/// request (URL, headers, body) for shape assertions.
class _FuelFinderAdapter implements HttpClientAdapter {
  _FuelFinderAdapter({
    required this.pfsBatches,
    required this.priceBatches,
    this.failFirstDataRequestWith = 0,
  });

  /// Batch bodies (JSON-encodable) served in order per resource path;
  /// requests past the queue answer 404 (the documented end-of-pages).
  final List<dynamic> pfsBatches;
  final List<dynamic> priceBatches;

  /// When non-zero, the first data GET fails with this HTTP status once.
  final int failFirstDataRequestWith;
  bool _dataFailed = false;

  int tokenRequests = 0;
  final List<String> tokenBodies = [];
  final List<Uri> dataRequests = [];
  final List<String?> dataAuthHeaders = [];

  ResponseBody _json(dynamic body, [int status = 200]) =>
      ResponseBody.fromString(jsonEncode(body), status, headers: {
        Headers.contentTypeHeader: ['application/json'],
      });

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.contains('/oauth/')) {
      tokenRequests++;
      if (requestStream != null) {
        final chunks = await requestStream.toList();
        tokenBodies.add(utf8.decode(chunks.expand((c) => c).toList()));
      } else {
        tokenBodies.add(options.data == null ? '' : jsonEncode(options.data));
      }
      return _json({
        'data': {'access_token': 'tok-$tokenRequests', 'expires_in': 3600},
      });
    }

    dataRequests.add(options.uri);
    dataAuthHeaders.add(options.headers['Authorization']?.toString());
    if (failFirstDataRequestWith != 0 && !_dataFailed) {
      _dataFailed = true;
      return _json({'message': 'forced failure'}, failFirstDataRequestWith);
    }

    final isPrices = options.path.endsWith(UkFuelFinderFeed.pricesPath);
    final queue = isPrices ? priceBatches : pfsBatches;
    final batch =
        int.tryParse(options.uri.queryParameters['batch-number'] ?? '') ?? 1;
    if (batch > queue.length) return _json({'message': 'not found'}, 404);
    return _json(queue[batch - 1]);
  }

  @override
  void close({bool force = false}) {}
}

UkFuelFinderFeed _feed(_FuelFinderAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  return UkFuelFinderFeed(
    auth: UkFuelFinderAuth(dio: dio, clientId: 'cid', clientSecret: 'csec'),
    dio: dio,
    baseUrl: 'https://test.fuel-finder.example',
  );
}

const _london = SearchParams(lat: 51.5, lng: -0.13, radiusKm: 25);

void main() {
  final pfsSlice = _fixture('uk_fuel_finder_pfs_slice.json');
  final pricesSlice = _fixture('uk_fuel_finder_pfs_prices_slice.json');

  group('UkFuelFinderFeed — live-contract constants (#3190)', () {
    test('base URL + resource paths match the statutory API', () {
      expect(UkFuelFinderFeed.defaultBaseUrl,
          'https://www.fuel-finder.service.gov.uk');
      expect(UkFuelFinderFeed.pfsPath, '/api/v1/pfs');
      expect(UkFuelFinderFeed.pricesPath, '/api/v1/pfs/fuel-prices');
      expect(UkFuelFinderAuth.defaultTokenUrl,
          'https://www.fuel-finder.service.gov.uk'
          '/api/v1/oauth/generate_access_token');
    });

    test('bulk service default consolidated URL targets the statutory host',
        () {
      expect(UkCmaBulkStationService.defaultConsolidatedUrl,
          startsWith('https://www.fuel-finder.service.gov.uk/'));
    });
  });

  group('record extraction (envelope tolerance)', () {
    test('reads the {data:{<list>}} envelope of both fixtures', () {
      expect(UkFuelFinderFeed.extractRecords(pfsSlice), hasLength(3));
      expect(UkFuelFinderFeed.extractRecords(pricesSlice), hasLength(3));
    });

    test('reads a bare top-level list and an un-enveloped map', () {
      expect(
        UkFuelFinderFeed.extractRecords([
          {'node_id': 'x'},
        ]),
        hasLength(1),
      );
      expect(
        UkFuelFinderFeed.extractRecords({
          'stations': [
            {'node_id': 'x'},
          ],
        }),
        hasLength(1),
      );
      expect(UkFuelFinderFeed.extractRecords('nonsense'), isEmpty);
    });

    test('reads the total-batches hint from the envelope', () {
      expect(UkFuelFinderFeed.extractTotalBatches(pfsSlice), 1);
      expect(UkFuelFinderFeed.extractTotalBatches({'total_batches': 7}), 7);
      expect(UkFuelFinderFeed.extractTotalBatches(const <Map<String, dynamic>>[]), isNull);
    });
  });

  group('mergeToCmaRecords (fixture-driven adaptation)', () {
    test('adapts info+prices into CMA-shaped records the shared parser reads',
        () {
      final records = UkFuelFinderFeed.mergeToCmaRecords(
        UkFuelFinderFeed.extractRecords(pfsSlice),
        UkFuelFinderFeed.extractRecords(pricesSlice),
      );

      expect(records, hasLength(3));
      final victoria =
          records.singleWhere((r) => r['site_id'] == 'PFS-100001');
      expect(victoria['brand'], 'Applegreen');
      expect(victoria['site_name'], 'APPLEGREEN LONDON VICTORIA');
      expect(victoria['address'], '123 Victoria Street');
      expect(victoria['postcode'], 'SW1E 6DE');
      expect(victoria['town'], 'London');
      expect((victoria['location'] as Map)['latitude'], 51.4966);
      final prices = victoria['prices'] as Map<String, dynamic>;
      // Grade mapping: E10→E10, E5→E5, B7_STANDARD→B7, B7_PREMIUM→SDV.
      expect(prices, {
        'E10': 141.9,
        'E5': 154.9,
        'B7': 148.9,
        'SDV': 162.9,
      });

      // Two-line address joins street parts only (city/postcode have their
      // own CMA fields).
      final kensington =
          records.singleWhere((r) => r['site_id'] == 'PFS-100002');
      expect(kensington['address'], '22a Warwick Road, Kensington');
    });

    test('end-to-end: merged records flow through parseCmaStations with '
        'pence→pounds conversion and radius filtering', () {
      final records = UkFuelFinderFeed.mergeToCmaRecords(
        UkFuelFinderFeed.extractRecords(pfsSlice),
        UkFuelFinderFeed.extractRecords(pricesSlice),
      );
      final stations = UkStationService.parseCmaStations(
        records,
        lat: _london.lat,
        lng: _london.lng,
        radiusKm: _london.radiusKm,
      );

      // Edinburgh (PFS-200001) is outside the 25 km London radius.
      expect(stations.map((s) => s.id),
          unorderedEquals(['uk-PFS-100001', 'uk-PFS-100002']));
      final victoria = stations.singleWhere((s) => s.id == 'uk-PFS-100001');
      expect(victoria.e10, closeTo(1.419, 1e-9));
      expect(victoria.e5, closeTo(1.549, 1e-9));
      expect(victoria.diesel, closeTo(1.489, 1e-9));
      expect(victoria.dieselPremium, closeTo(1.629, 1e-9));
      expect(victoria.brand, 'Applegreen');
    });

    test('a price row without a matching info row is dropped (no coordinates)',
        () {
      final records = UkFuelFinderFeed.mergeToCmaRecords(
        const [],
        UkFuelFinderFeed.extractRecords(pricesSlice),
      );
      expect(records, isEmpty);
    });

    test('grade mapping covers both diesel aliases and rejects unknowns', () {
      expect(UkFuelFinderFeed.cmaGradeFor('B7'), 'B7');
      expect(UkFuelFinderFeed.cmaGradeFor('B7_STANDARD'), 'B7');
      expect(UkFuelFinderFeed.cmaGradeFor('SDV'), 'SDV');
      expect(UkFuelFinderFeed.cmaGradeFor('B7_PREMIUM'), 'SDV');
      expect(UkFuelFinderFeed.cmaGradeFor('LPG'), isNull);
      expect(UkFuelFinderFeed.cmaGradeFor(null), isNull);
    });
  });

  group('download (auth + paging + retry)', () {
    test('fetches ONE token, pages both resources with batch-number, and '
        'sends the Bearer on every data GET', () async {
      final adapter = _FuelFinderAdapter(
        // Two pfs batches (no total hint on the second shape) + one prices
        // batch; paging must stop on the 404 past the last pfs batch.
        pfsBatches: [
          {
            'data': {
              'pfs': UkFuelFinderFeed.extractRecords(pfsSlice).sublist(0, 2),
            },
          },
          {
            'data': {
              'pfs': UkFuelFinderFeed.extractRecords(pfsSlice).sublist(2),
            },
          },
        ],
        priceBatches: [pricesSlice],
      );

      final records = await _feed(adapter).downloadCmaShapedRecords();

      expect(records, hasLength(3));
      expect(adapter.tokenRequests, 1);
      // 2 pfs batches + the end-of-pages 404 probe + 1 prices batch
      // (total_batches:1 hint stops the prices paging without a probe).
      expect(adapter.dataRequests, hasLength(4));
      expect(
        adapter.dataRequests.map((u) => u.queryParameters['batch-number']),
        ['1', '2', '3', '1'],
      );
      expect(adapter.dataAuthHeaders, everyElement('Bearer tok-1'));
      // Token POST carries the JSON credential body of the live contract.
      expect(adapter.tokenBodies.single, contains('"client_id":"cid"'));
      expect(adapter.tokenBodies.single, contains('"client_secret":"csec"'));
      expect(adapter.tokenBodies.single, isNot(contains('grant_type')));
    });

    test('honours the total_batches hint (no trailing 404 probe)', () async {
      final adapter = _FuelFinderAdapter(
        pfsBatches: [pfsSlice],
        priceBatches: [pricesSlice],
      );

      await _feed(adapter).downloadCmaShapedRecords();

      expect(
        adapter.dataRequests.map((u) => u.queryParameters['batch-number']),
        ['1', '1'],
      );
    });

    test('a 401 invalidates the token and retries the download once',
        () async {
      final adapter = _FuelFinderAdapter(
        pfsBatches: [pfsSlice],
        priceBatches: [pricesSlice],
        failFirstDataRequestWith: 401,
      );

      final records = await _feed(adapter).downloadCmaShapedRecords();

      expect(records, hasLength(3));
      expect(adapter.tokenRequests, 2, reason: 'fresh token after the 401');
      expect(adapter.dataAuthHeaders.first, 'Bearer tok-1');
      expect(adapter.dataAuthHeaders.last, 'Bearer tok-2');
    });
  });

  group('UkCmaBulkStationService in feed mode', () {
    test('searchStations answers from the statutory feed via the shared '
        'parser', () async {
      final adapter = _FuelFinderAdapter(
        pfsBatches: [pfsSlice],
        priceBatches: [pricesSlice],
      );
      final service = UkCmaBulkStationService(feed: _feed(adapter));

      final result = await service.searchStations(_london);

      expect(result.source, ServiceSource.ukApi);
      expect(result.data.map((s) => s.id),
          unorderedEquals(['uk-PFS-100001', 'uk-PFS-100002']));
    });

    test('downloads the dataset ONCE then serves later searches locally',
        () async {
      final adapter = _FuelFinderAdapter(
        pfsBatches: [pfsSlice],
        priceBatches: [pricesSlice],
      );
      final service = UkCmaBulkStationService(feed: _feed(adapter));

      await service.searchStations(_london);
      await service.searchStations(
        const SearchParams(lat: 55.95, lng: -3.19, radiusKm: 25),
      );

      expect(adapter.dataRequests, hasLength(2),
          reason: 'one pfs + one prices download serves every search');
      expect(adapter.tokenRequests, 1);
    });
  });
}
