import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../features/search/data/models/search_params.dart';
import '../../../features/search/domain/entities/station.dart';
import '../../error/exceptions.dart';
import '../../utils/geo_utils.dart';
import '../dio_factory.dart';
import '../service_result.dart';
import '../station_service.dart';
import '../mixins/station_service_helpers.dart';

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

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final list = data['stations'] as List<dynamic>? ??
            data['data'] as List<dynamic>? ??
            const [];
        return List<dynamic>.from(list);
      }
      if (data is List) return List<dynamic>.from(data);
      return null;
    } on DioException catch (e) {
      debugPrint('UK feed $url failed: ${e.type.name}');
      return null;
    } catch (e) {
      debugPrint('UK feed $url parse error: $e');
      return null;
    }
  }

  /// Parses a merged list of CMA station records into [Station] entities,
  /// filters to the search radius, dedupes by `site_id`, sorts by
  /// distance, and caps at 50 results.
  ///
  /// Exposed for tests.
  @visibleForTesting
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
        final location = item['location'];
        final locMap = location is Map ? location : null;
        final itemLat = (locMap?['latitude'] as num?)?.toDouble() ??
            (item['lat'] as num?)?.toDouble();
        final itemLng = (locMap?['longitude'] as num?)?.toDouble() ??
            (item['lng'] as num?)?.toDouble();
        if (itemLat == null || itemLng == null) continue;

        final dist = distanceKm(lat, lng, itemLat, itemLng);
        if (dist > radiusKm) continue;

        final rawId = item['site_id']?.toString() ??
            item['id']?.toString() ??
            '${itemLat.toStringAsFixed(5)}_${itemLng.toStringAsFixed(5)}';
        final stationId = 'uk-$rawId';
        if (!seenIds.add(stationId)) continue;

        final prices = item['prices'] is Map
            ? Map<String, dynamic>.from(item['prices'] as Map)
            : <String, dynamic>{};

        stations.add(Station(
          id: stationId,
          name: item['site_name']?.toString() ??
              item['name']?.toString() ??
              item['brand']?.toString() ??
              '',
          brand: item['brand']?.toString() ?? '',
          street: item['address']?.toString() ?? '',
          postCode: item['postcode']?.toString() ?? '',
          place: item['town']?.toString() ?? item['locality']?.toString() ?? '',
          lat: itemLat,
          lng: itemLng,
          dist: dist,
          e5: _parsePence(prices['E5'] ?? prices['unleaded']),
          e10: _parsePence(prices['E10']),
          e98: _parsePence(prices['super_unleaded'] ?? prices['E5_97']),
          diesel: _parsePence(prices['B7'] ?? prices['diesel']),
          isOpen: true,
        ));
      } catch (e) {
        debugPrint('UK station parse failed: $e');
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

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String stationId) async {
    throw const ApiException(message: 'Station detail not supported for UK');
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) async {
    return ServiceResult(
      data: const {},
      source: ServiceSource.ukApi,
      fetchedAt: DateTime.now(),
    );
  }
}
