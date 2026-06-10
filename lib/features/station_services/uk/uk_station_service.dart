// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../search/data/models/search_params.dart';
import '../../search/domain/entities/station.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../core/utils/json_extensions.dart';
import '../../../core/services/dio_factory.dart';
import '../../../core/services/service_result.dart';
import '../../../core/services/station_service.dart';
import '../../../core/services/mixins/station_service_helpers.dart';
import '../../../core/logging/error_logger.dart';

/// UK Competition and Markets Authority (CMA) fuel price service.
///
/// Under the CMA Fuel Finder scheme, major UK fuel retailers publish
/// their station list and prices as a standardized JSON feed hosted on
/// their own domain. There is no single aggregated endpoint — each
/// retailer serves its own file. This service fans out across the known
/// retailer feeds in parallel, tolerates per-retailer failures (a 404
/// or timeout on one retailer does not kill the whole search), and
/// aggregates the results client-side.
///
/// Feed format (standardized by the CMA):
/// ```json
/// {
///   "last_updated": "2025-01-01 08:00:00",
///   "stations": [
///     {
///       "site_id": "...",
///       "brand": "...",
///       "address": "...",
///       "postcode": "...",
///       "location": {"latitude": 51.5, "longitude": -0.12},
///       "prices": {"E5": 145.9, "E10": 142.9, "B7": 151.9, "SDV": 160.9}
///     }
///   ]
/// }
/// ```
///
/// Prices are in pence per litre — [_parsePence] converts values above
/// 10 back to pounds.
class UkStationService with StationServiceHelpers implements StationService {
  final Dio _dio;
  final List<String> _feedUrls;

  UkStationService({Dio? dio, List<String>? feedUrls})
      : _dio = dio ??
            DioFactory.create(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 12),
            ),
        _feedUrls = feedUrls ?? defaultCmaFeedUrls;

  /// Canonical list of CMA-compliant retailer feeds.
  ///
  /// Published at https://www.gov.uk/guidance/access-fuel-price-data. The
  /// list is intentionally permissive — missing or broken URLs degrade
  /// gracefully because each fetch is isolated in [_fetchFeed].
  static const List<String> defaultCmaFeedUrls = [
    'https://applegreenstores.com/fuel-prices/data.json',
    'https://fuelprices.asconagroup.co.uk/newfuel.json',
    'https://storelocator.asda.com/fuel_prices_data.json',
    'https://www.bp.com/en_gb/united-kingdom/home/fuelprices/fuel_prices_data.json',
    'https://fuelprices.esso.co.uk/latestdata.json',
    'https://jetlocal.co.uk/fuel_prices_data.json',
    'https://api2.krlmedia.com/integration/live_price/krl',
    'https://www.morrisons.com/fuel-prices/fuel.json',
    'https://moto-way.com/fuel-price/fuel_prices.json',
    'https://fuel.motorfuelgroup.com/fuel_prices_data.json',
    'https://www.rontec-servicestations.co.uk/fuel-prices/data/fuel_prices_data.json',
    'https://api.sainsburys.co.uk/v1/exports/latest/fuel_prices_data.json',
    'https://www.sgnretail.uk/files/data/SGN_daily_fuel_prices.json',
    // #3191 — Shell's CMA entry point. The .html URL 302-redirects to a
    // SAS-tokened Azure blob (prodpricinghubstrgacct.blob.core.windows.net)
    // whose token rotates, so the stable page URL is listed and Dio's
    // default followRedirects handles the hop. The blob answers
    // `application/octet-stream`, which [_fetchFeed] decodes itself.
    'https://www.shell.co.uk/fuel-prices-data.html',
    'https://www.tesco.com/fuel_prices/fuel_prices_data.json',
  ];

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    final results = await Future.wait(
      _feedUrls.map((url) => _fetchFeed(url, cancelToken)),
    );

    final merged = <dynamic>[];
    var failureCount = 0;
    for (final list in results) {
      if (list == null) {
        failureCount++;
      } else {
        merged.addAll(list);
      }
    }

    if (merged.isEmpty && failureCount == _feedUrls.length) {
      throw const ApiException(
        message: 'All CMA retailer feeds unreachable',
      );
    }

    final stations = parseCmaStations(
      merged,
      lat: params.lat,
      lng: params.lng,
      radiusKm: params.radiusKm,
    );

    return ServiceResult(
      data: stations,
      source: ServiceSource.ukApi,
      fetchedAt: DateTime.now(),
    );
  }

  Future<List<dynamic>?> _fetchFeed(
    String url,
    CancelToken? cancelToken,
  ) async {
    try {
      final response = await _dio.get<dynamic>(
        url,
        cancelToken: cancelToken,
        options: Options(
          // Tolerate 404 / 410 — a dead retailer feed must not poison the
          // whole search. Only network / 5xx failures bubble up.
          validateStatus: (status) => status != null && status < 500,
          responseType: ResponseType.json,
        ),
      );
      if (response.statusCode == null || response.statusCode! >= 400) {
        debugPrint('UK feed $url → HTTP ${response.statusCode}');
        return null;
      }

      // #3191 — Dio only auto-decodes JSON mime types; the Shell feed's
      // Azure blob answers `application/octet-stream`, leaving a raw String
      // body. Decode it ourselves before the shape checks.
      var data = response.data;
      if (data is String && data.trimLeft().startsWith(RegExp(r'[\[{]'))) {
        data = jsonDecode(data);
      }
      if (data is Map<String, dynamic>) {
        final list = data['stations'] as List<dynamic>? ??
            data['data'] as List<dynamic>? ??
            const [];
        return List<dynamic>.from(list);
      }
      if (data is List) return List<dynamic>.from(data);
      return null;
    } on DioException catch (e, st) {
      // #2301 — log per-feed failures through errorLogger (release-safe).
      // debugPrint is stripped in release, so with 14 parallel feeds a
      // silent partial failure produced sparse results with no breadcrumb.
      unawaited(errorLogger.log(ErrorLayer.other, e, st,
          context: {'where': 'UK feed', 'type': e.type.name}));
      return null;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: {'where': 'UK feed $url parse error'}));
      return null;
    }
  }

  /// Parses a merged list of CMA station records into [Station] entities,
  /// filters to the search radius, dedupes by `site_id`, sorts by
  /// distance, and caps at 50 results.
  ///
  /// Public shared parser: the legacy per-search fan-out and the #2277 bulk
  /// consolidated path ([UkCmaBulkStationService]) both run their records
  /// through this so a given area returns identical stations regardless of
  /// which source delivered them.
  static List<Station> parseCmaStations(
    List<dynamic> items, {
    required double lat,
    required double lng,
    required double radiusKm,
  }) {
    final seenIds = <String>{};
    final stations = <Station>[];

    for (final item in items) {
      if (item is! Map) continue;
      try {
        final m = Map<String, dynamic>.from(item);
        final locMap = m.getMap('location');
        // #2199 — SafeJsonAccessors: getDouble accepts num OR numeric-string
        // and returns null on missing/non-numeric. The previous `as num?`
        // cast threw a CastError on a string-typed coordinate, which the
        // per-item catch swallowed into a skipped station; getDouble parses
        // it instead. Records with numeric coords (every CMA feed today)
        // parse identically.
        final itemLat = locMap?.getDouble('latitude') ?? m.getDouble('lat');
        final itemLng = locMap?.getDouble('longitude') ?? m.getDouble('lng');
        if (itemLat == null || itemLng == null) continue;

        final dist = distanceKm(lat, lng, itemLat, itemLng);
        if (dist > radiusKm) continue;

        final rawId = m['site_id']?.toString() ??
            m['id']?.toString() ??
            '${itemLat.toStringAsFixed(5)}_${itemLng.toStringAsFixed(5)}';
        final stationId = 'uk-$rawId';
        if (!seenIds.add(stationId)) continue;

        final prices = m.getMap('prices') ?? <String, dynamic>{};

        stations.add(Station(
          id: stationId,
          name: m['site_name']?.toString() ??
              m['name']?.toString() ??
              m['brand']?.toString() ??
              '',
          brand: m['brand']?.toString() ?? '',
          street: m['address']?.toString() ?? '',
          postCode: m['postcode']?.toString() ?? '',
          place: m['town']?.toString() ?? m['locality']?.toString() ?? '',
          lat: itemLat,
          lng: itemLng,
          dist: dist,
          e5: _parsePence(prices['E5'] ?? prices['unleaded']),
          e10: _parsePence(prices['E10']),
          // #3191 — the CMA schema's premium-diesel key is `SDV`. The old
          // `super_unleaded` / `E5_97` keys exist in NO live feed and were
          // wrongly mapped to e98 (no CMA feed publishes premium petrol).
          diesel: _parsePence(prices['B7'] ?? prices['diesel']),
          dieselPremium: _parsePence(prices['SDV']),
          isOpen: true,
        ));
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'UK station parse failed'}));
        continue;
      }
    }

    stations.sort((a, b) => a.dist.compareTo(b.dist));
    return stations.take(50).toList();
  }

  /// UK CMA prices are published in pence per litre. Anything above 10
  /// is treated as pence and divided by 100; anything at or below 10 is
  /// assumed to already be in pounds.
  @visibleForTesting
  static double? parsePenceForTest(dynamic value) => _parsePence(value);

  static double? _parsePence(dynamic value) {
    if (value == null) return null;
    final price = double.tryParse(value.toString());
    if (price == null) return null;
    return price > 10 ? price / 100 : price;
  }

  // #2264 — route the unsupported endpoints through the shared helpers
  // (throwDetailUnavailable / emptyPricesResult) like the other services.
  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String stationId) async {
    throwDetailUnavailable('CMA Fuel Finder');
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) async {
    return emptyPricesResult(ServiceSource.ukApi);
  }
}
