// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/dio_factory.dart';
import '../../../core/utils/json_extensions.dart';
import 'uk_fuel_finder_auth.dart';

/// Statutory **Fuel Finder** feed client (#3190).
///
/// Under the *Motor Fuel Price (Open Data) Regulations 2025* every UK motor
/// fuel trader must report prices to the Fuel Finder aggregator (VE3 Global
/// Ltd, for DESNZ) within 30 minutes of a change; the aggregated data is
/// openly available to registered third parties (free registration, Open
/// Government Licence v3.0). CMA enforcement started 2026-05-01, replacing
/// the withdrawn voluntary retailer-feed scheme.
///
/// ## Live REST contract (research evidence, 2026-07-03)
///
/// ```
/// base   https://www.fuel-finder.service.gov.uk
/// token  POST /api/v1/oauth/generate_access_token   (see UkFuelFinderAuth)
/// info   GET  /api/v1/pfs?batch-number=<n>          Bearer <token>
/// prices GET  /api/v1/pfs/fuel-prices?batch-number=<n>
/// ```
///
/// Both data resources are paginated with a 1-based `batch-number` query
/// parameter; a 404 past the last batch (or an empty batch) ends the paging.
/// An optional `effective-start-timestamp=<yyyy-MM-dd>` narrows either
/// resource to records changed since that date (incremental refresh — not
/// used here; the whole dataset persists via the bulk service's
/// PersistentDataset and re-downloads only per its soft TTL). The published
/// rate limit is roughly one request per 2 s with `429` + `Retry-After` on
/// excess — the default Dio carries a 2.1 s rate-limit interceptor.
///
/// Sources: GOV.UK guidance "Access the latest fuel prices and forecourt
/// data via API or email", the developer portal REST API pages
/// (`developer.fuel-finder.service.gov.uk/public-api`, `/apicontent`,
/// `/api-authentication`), cross-checked against a working third-party
/// consumer of the live API. Field names below mirror that live contract.
///
/// ## Record shapes
///
/// Forecourt info (`/api/v1/pfs`) records:
///
/// ```json
/// {
///   "node_id": "...", "trading_name": "...", "brand_name": "...",
///   "location": {"address_line_1": "...", "address_line_2": "...",
///                "city": "...", "county": "...", "country": "...",
///                "postcode": "...", "latitude": 51.5, "longitude": -0.12},
///   "fuel_types": ["E10", "E5", "B7"], "amenities": [...],
///   "opening_times": {...}
/// }
/// ```
///
/// Price (`/api/v1/pfs/fuel-prices`) records: `node_id` plus a `fuel_prices`
/// list of `{fuel_type, price, price_last_updated,
/// price_change_effective_timestamp}` entries. Grades are `E10`, `E5`,
/// `B7`/`B7_STANDARD` (diesel) and `SDV`/`B7_PREMIUM` (super diesel); prices
/// are pence per litre.
///
/// [mergeToCmaRecords] adapts the two resources into the standardized CMA
/// record shape (`{site_id, brand, address, postcode, location:{latitude,
/// longitude}, prices:{E5,E10,B7,SDV}}`) so the whole existing UK
/// parse/persist/filter pipeline ([UkStationService.parseCmaStations] via
/// [UkCmaBulkStationService]) is reused unchanged — one parser, one result
/// set, regardless of source.
///
/// The feed's `opening_times` object is carried through on the merged record
/// (key `opening_times`, shape passed verbatim) but is not yet mapped to the
/// app's structured opening-hours model: its exact schema is not published
/// and cannot be confirmed without a live registered sample. Tracked in the
/// #3190 closing notes.
class UkFuelFinderFeed {
  /// Live statutory API host. Injectable for tests / host moves.
  // i18n-ignore: gov.uk API endpoint URL, not user-facing text
  static const String defaultBaseUrl = 'https://www.fuel-finder.service.gov.uk';

  /// Forecourt (station) details resource.
  static const String pfsPath = '/api/v1/pfs';

  /// Fuel prices resource.
  static const String pricesPath = '/api/v1/pfs/fuel-prices';

  /// Hard paging cap so a server-side paging fault can never turn into an
  /// unbounded request loop (~80 batches comfortably covers the ~8 500 UK
  /// forecourts at the observed batch sizes).
  static const int maxBatches = 80;

  final Dio _dio;
  final UkFuelFinderAuth _auth;
  final String _baseUrl;

  UkFuelFinderFeed({
    required UkFuelFinderAuth auth,
    Dio? dio,
    String? baseUrl,
  })  : _auth = auth,
        _dio = dio ??
            DioFactory.create(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              // Published limit ≈ 1 request / 2 s — stay just above it.
              rateLimit: const Duration(milliseconds: 2100),
              rateLimitJitterRangeMs: 200,
            ),
        _baseUrl = baseUrl ?? defaultBaseUrl;

  /// Downloads the whole-country dataset (forecourt info + prices, all
  /// batches), merged into legacy-CMA-shaped records ready for
  /// `UkStationService.parseCmaStations`.
  ///
  /// A 401/403 (token rotated / revoked server-side) invalidates the cached
  /// token and retries the whole download ONCE with a fresh one.
  Future<List<Map<String, dynamic>>> downloadCmaShapedRecords({
    CancelToken? cancelToken,
  }) async {
    try {
      return await _download(cancelToken: cancelToken);
    } on DioException catch (e) { // ignore: catch_no_st — rethrow preserves the stack; the 401/403 branch retries
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        _auth.invalidate();
        return _download(cancelToken: cancelToken);
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _download({
    CancelToken? cancelToken,
  }) async {
    final info = await _fetchBatched(pfsPath, cancelToken: cancelToken);
    final prices = await _fetchBatched(pricesPath, cancelToken: cancelToken);
    return mergeToCmaRecords(info, prices);
  }

  Future<List<Map<String, dynamic>>> _fetchBatched(
    String path, {
    CancelToken? cancelToken,
  }) async {
    final records = <Map<String, dynamic>>[];
    for (var batch = 1; batch <= maxBatches; batch++) {
      final token = await _auth.accessToken(cancelToken: cancelToken);
      Response<dynamic> response;
      try {
        response = await _dio.get<dynamic>(
          '$_baseUrl$path',
          queryParameters: {'batch-number': batch},
          options: Options(
            responseType: ResponseType.json,
            headers: {'Authorization': 'Bearer $token'},
          ),
          cancelToken: cancelToken,
        );
      } on DioException catch (e) { // ignore: catch_no_st — a 404 past the last batch is the documented end-of-pages signal
        if (e.response?.statusCode == 404 && batch > 1) break;
        rethrow;
      }
      final rows = extractRecords(response.data);
      if (rows.isEmpty) break;
      records.addAll(rows);
      final total = extractTotalBatches(response.data);
      if (total != null && batch >= total) break;
    }
    return records;
  }

  /// Extracts the record list from a batched response envelope. The exact
  /// envelope key is not published, so this is deliberately tolerant (like
  /// the token envelope in [UkFuelFinderAuth]): a bare top-level list, or the
  /// first list-of-objects found at the top level or one `data` level down.
  @visibleForTesting
  static List<Map<String, dynamic>> extractRecords(dynamic data) {
    List<Map<String, dynamic>> asRecordList(dynamic value) {
      if (value is! List) return const [];
      final out = <Map<String, dynamic>>[];
      for (final row in value) {
        if (row is Map) out.add(Map<String, dynamic>.from(row));
      }
      return out;
    }

    final direct = asRecordList(data);
    if (direct.isNotEmpty) return direct;

    Map<String, dynamic>? envelope;
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      envelope =
          inner is Map ? Map<String, dynamic>.from(inner) : data;
    }
    if (envelope == null) return const [];
    for (final value in envelope.values) {
      final rows = asRecordList(value);
      if (rows.isNotEmpty) return rows;
    }
    return const [];
  }

  /// Reads a total-batch-count hint from a response envelope, when the server
  /// sends one (checked at the top level and one `data`/`meta` level down).
  @visibleForTesting
  static int? extractTotalBatches(dynamic data) {
    if (data is! Map) return null;
    int? read(dynamic scope) {
      if (scope is! Map) return null;
      for (final key in const [
        'total_batches', 'totalBatches', 'total-batches',
      ]) {
        final value = scope[key];
        if (value is num) return value.toInt();
        final parsed = int.tryParse(value?.toString() ?? '');
        if (parsed != null) return parsed;
      }
      return null;
    }

    return read(data) ?? read(data['data']) ?? read(data['meta']);
  }

  /// Merges forecourt-info + price records (matched on the station
  /// identifier) into legacy-CMA-shaped records so the shared
  /// `parseCmaStations` pipeline consumes them unchanged. Pure — exposed for
  /// fixture-driven tests.
  @visibleForTesting
  static List<Map<String, dynamic>> mergeToCmaRecords(
    List<Map<String, dynamic>> info,
    List<Map<String, dynamic>> prices,
  ) {
    final byId = <String, Map<String, dynamic>>{};

    for (final row in info) {
      final id = _stationId(row);
      if (id.isEmpty) continue;
      final location = row.getMap('location') ?? const <String, dynamic>{};
      byId[id] = {
        'site_id': id,
        'site_name': row['trading_name']?.toString() ?? '',
        'brand': row['brand_name']?.toString() ??
            row['trading_name']?.toString() ??
            '',
        'address': _streetAddress(location),
        'postcode': location['postcode']?.toString() ?? '',
        'town': location['city']?.toString() ?? '',
        'location': {
          'latitude': location['latitude'],
          'longitude': location['longitude'],
        },
        'prices': <String, dynamic>{},
        // Carried verbatim for a future structured mapping (schema not yet
        // confirmable without a live registered sample — see class docs).
        if (row['opening_times'] is Map) 'opening_times': row['opening_times'],
      };
    }

    for (final row in prices) {
      final id = _stationId(row);
      if (id.isEmpty) continue;
      // A price row without a matching info row has no coordinates;
      // parseCmaStations drops coordinate-less records, so skip it here.
      final record = byId[id];
      if (record == null) continue;
      final target = record['prices'] as Map<String, dynamic>;
      final entries = row['fuel_prices'];
      if (entries is! List) continue;
      for (final entry in entries) {
        if (entry is! Map) continue;
        final grade = cmaGradeFor(entry['fuel_type']?.toString());
        final price = entry['price'];
        if (grade == null || price is! num) continue;
        target[grade] = price;
      }
    }

    return byId.values.toList();
  }

  /// Maps a Fuel Finder grade to the standardized CMA price key the shared
  /// parser reads (`E5`/`E10`/`B7`/`SDV`), or null for an unknown grade.
  @visibleForTesting
  static String? cmaGradeFor(String? fuelType) {
    switch (fuelType?.trim().toUpperCase()) {
      case 'E10':
        return 'E10';
      case 'E5':
        return 'E5';
      case 'B7':
      case 'B7_STANDARD':
        return 'B7';
      case 'SDV':
      case 'B7_PREMIUM':
        return 'SDV';
      default:
        return null;
    }
  }

  static String _stationId(Map<String, dynamic> row) {
    for (final key in const ['node_id', 'site_id', 'id', 'station_id']) {
      final value = row[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static String _streetAddress(Map<String, dynamic> location) {
    final parts = <String>[
      for (final key in const ['address_line_1', 'address_line_2'])
        location[key]?.toString().trim() ?? '',
    ]..removeWhere((part) => part.isEmpty);
    return parts.join(', ');
  }
}
