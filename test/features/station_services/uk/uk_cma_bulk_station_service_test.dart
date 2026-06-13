// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/features/station_services/uk/uk_cma_bulk_station_service.dart';
import 'package:tankstellen/features/station_services/uk/uk_fuel_finder_auth.dart';
import 'package:tankstellen/features/station_services/uk/uk_station_service.dart';

/// #2277 — the UK consolidated CMA bulk-file path: ONE download, persisted,
/// local-filtered. These cover bulk-parse (consolidated envelope → records),
/// results-preserved-vs-legacy (same parser → same stations for an area), and
/// the download-once-then-serve-locally contract.

/// Counts requests and serves one canned consolidated body for every URL.
class _CountingAdapter implements HttpClientAdapter {
  final String body;
  int requestCount = 0;

  _CountingAdapter(this.body);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount++;
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioServing(String body) {
  final dio = Dio();
  dio.httpClientAdapter = _CountingAdapter(body);
  return dio;
}

/// A consolidated file holds the SAME standardized records the retailer feeds
/// publish — just unioned into one envelope.
String _consolidated(List<Map<String, dynamic>> stations) =>
    jsonEncode({'last_updated': '2026-05-29 08:00:00', 'stations': stations});

Map<String, dynamic> _record({
  required String siteId,
  required String brand,
  required double lat,
  required double lng,
  double e5 = 155.9,
  double e10 = 145.9,
  double diesel = 152.9,
}) =>
    {
      'site_id': siteId,
      'brand': brand,
      'site_name': '$brand $siteId',
      'address': '1 Test St',
      'postcode': 'SW1E 6DE',
      'town': 'London',
      'location': {'latitude': lat, 'longitude': lng},
      'prices': {'E5': e5, 'E10': e10, 'B7': diesel},
    };

const _london = SearchParams(lat: 51.5, lng: -0.12, radiusKm: 50);

void main() {
  group('UkCmaBulkStationService (public surface)', () {
    test('implements StationService', () {
      expect(UkCmaBulkStationService(), isA<StationService>());
    });

    test('default consolidated URL targets the gov.uk Fuel Finder scheme', () {
      expect(
        UkCmaBulkStationService.defaultConsolidatedUrl,
        contains('fuel-finder.service.gov.uk'),
      );
    });

    test('getStationDetail throws (unsupported)', () {
      expect(
        () => UkCmaBulkStationService().getStationDetail('uk-1'),
        throwsA(isA<Exception>()),
      );
    });

    test('getPrices returns empty map with ukApi source', () async {
      final r = await UkCmaBulkStationService().getPrices(['uk-1']);
      expect(r.data, isEmpty);
      expect(r.source, ServiceSource.ukApi);
    });
  });

  group('extractConsolidatedRecords (bulk-parse)', () {
    test('reads the {stations:[...]} envelope', () {
      final recs = UkCmaBulkStationService.extractConsolidatedRecords({
        'stations': [
          {'site_id': 'A'},
          {'site_id': 'B'},
        ],
      });
      expect(recs, hasLength(2));
      expect(recs[0]['site_id'], 'A');
    });

    test('reads the {data:[...]} envelope variant', () {
      final recs = UkCmaBulkStationService.extractConsolidatedRecords({
        'data': [
          {'site_id': 'A'},
        ],
      });
      expect(recs, hasLength(1));
    });

    test('reads a bare top-level list', () {
      final recs = UkCmaBulkStationService.extractConsolidatedRecords([
        {'site_id': 'A'},
        {'site_id': 'B'},
        {'site_id': 'C'},
      ]);
      expect(recs, hasLength(3));
    });

    test('returns empty for an unexpected shape', () {
      expect(
        UkCmaBulkStationService.extractConsolidatedRecords('nonsense'),
        isEmpty,
      );
    });
  });

  group('searchStations (download once → local-filter)', () {
    test('parses the consolidated file and local-filters by radius', () async {
      final body = _consolidated([
        _record(siteId: 'LON', brand: 'BP', lat: 51.5, lng: -0.12),
        // Edinburgh — far outside a 50 km London radius.
        _record(siteId: 'EDI', brand: 'Shell', lat: 55.9533, lng: -3.1883),
      ]);
      final service =
          UkCmaBulkStationService(dio: _dioServing(body));

      final result = await service.searchStations(_london);

      expect(result.source, ServiceSource.ukApi);
      expect(result.data, hasLength(1));
      expect(result.data.first.id, 'uk-LON');
    });

    test('downloads ONCE then serves later searches from memory (no fan-out)',
        () async {
      final adapter = _CountingAdapter(_consolidated([
        _record(siteId: 'LON', brand: 'BP', lat: 51.5, lng: -0.12),
      ]));
      final dio = Dio()..httpClientAdapter = adapter;
      final service = UkCmaBulkStationService(dio: dio);

      await service.searchStations(_london);
      await service.searchStations(_london);
      await service.searchStations(
        const SearchParams(lat: 51.51, lng: -0.13, radiusKm: 10),
      );

      expect(adapter.requestCount, 1,
          reason: 'one consolidated download serves every search');
    });

    test('results are PRESERVED: bulk == legacy parser for the same records',
        () async {
      final records = [
        _record(siteId: 'A', brand: 'BP', lat: 51.501, lng: -0.121),
        _record(siteId: 'B', brand: 'Tesco', lat: 51.49, lng: -0.14),
        _record(siteId: 'C', brand: 'Esso', lat: 51.6, lng: -0.05),
      ];

      // Bulk path: persist all, local-filter.
      final bulk = UkCmaBulkStationService(
        dio: _dioServing(_consolidated(records)),
      );
      final bulkResult = await bulk.searchStations(_london);

      // Legacy parser over the identical records.
      final legacy = UkStationService.parseCmaStations(
        records,
        lat: _london.lat,
        lng: _london.lng,
        radiusKm: _london.radiusKm,
      );

      expect(
        bulkResult.data.map((s) => s.id).toList(),
        legacy.map((s) => s.id).toList(),
        reason: 'bulk path must return the same stations, same order',
      );
      expect(bulkResult.data.first.e5, legacy.first.e5);
    });
  });

  group('OAuth2 client-credentials auth (#3190)', () {
    test('fetches a token then sends the consolidated GET with a Bearer header',
        () async {
      final adapter = _OAuthRoutingAdapter(
        consolidatedBody: _consolidated([
          _record(siteId: 'gb-1', brand: 'BP', lat: 51.5, lng: -0.12),
        ]),
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final auth = UkFuelFinderAuth(
        dio: dio,
        tokenUrl: 'https://developer.fuel-finder.service.gov.uk/oauth/token',
        clientId: 'client-abc',
        clientSecret: 'secret-xyz',
      );
      final bulk = UkCmaBulkStationService(dio: dio, auth: auth);

      final result = await bulk.searchStations(_london);

      expect(result.data, isNotEmpty);
      // Token POST happened, then the data GET carried the Bearer token.
      expect(adapter.tokenRequests, 1);
      expect(adapter.dataAuthHeaders, ['Bearer tok-1']);
    });

    test('on a 401 it invalidates the token and retries the download once',
        () async {
      final adapter = _OAuthRoutingAdapter(
        consolidatedBody: _consolidated([
          _record(siteId: 'gb-1', brand: 'BP', lat: 51.5, lng: -0.12),
        ]),
        failDataOnceWith401: true,
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final auth = UkFuelFinderAuth(
        dio: dio,
        tokenUrl: 'https://developer.fuel-finder.service.gov.uk/oauth/token',
        clientId: 'c',
        clientSecret: 's',
      );
      final bulk = UkCmaBulkStationService(dio: dio, auth: auth);

      final result = await bulk.searchStations(_london);

      // The 401 forced a fresh token (2 token fetches) and the retry succeeded.
      expect(result.data, isNotEmpty);
      expect(adapter.tokenRequests, 2);
      expect(adapter.dataAuthHeaders, ['Bearer tok-1', 'Bearer tok-2']);
    });
  });
}

/// Routes the OAuth2 token POST vs the consolidated data GET by path, captures
/// the data request's Authorization header, and can fail the first data GET
/// with a 401 to exercise the invalidate-and-retry path.
class _OAuthRoutingAdapter implements HttpClientAdapter {
  _OAuthRoutingAdapter({
    required this.consolidatedBody,
    this.failDataOnceWith401 = false,
  });

  final String consolidatedBody;
  final bool failDataOnceWith401;

  int tokenRequests = 0;
  final List<String> dataAuthHeaders = [];
  bool _dataFailed = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final isToken = options.path.contains('/oauth/token');
    if (isToken) {
      tokenRequests++;
      return ResponseBody.fromString(
        jsonEncode({'access_token': 'tok-$tokenRequests', 'expires_in': 3600}),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    // Data GET — record the bearer the service attached.
    dataAuthHeaders.add(options.headers['Authorization']?.toString() ?? '');
    if (failDataOnceWith401 && !_dataFailed) {
      _dataFailed = true;
      return ResponseBody.fromString('{}', 401, headers: {
        Headers.contentTypeHeader: ['application/json'],
      });
    }
    return ResponseBody.fromString(
      consolidatedBody,
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
