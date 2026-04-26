import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../features/search/data/models/search_params.dart';
import '../../../features/search/domain/entities/station.dart';
import '../dio_factory.dart';
import '../mixins/cached_dataset_mixin.dart';
import '../mixins/station_service_helpers.dart';
import '../service_result.dart';
import '../station_service.dart';

/// Danish fuel prices aggregated from 3 free public APIs:
/// - OK (ok.dk) — ~350 stations
/// - Shell (geoapp.me) — ~200 stations
/// - Q8/F24 (q8.dk) — ~250 stations
///
/// All APIs are free, require no API key, and return all stations nationally.
/// We download all, calculate distances locally, and filter by radius.
/// Prices are in DKK (Danish Kroner).
class DenmarkStationService with StationServiceHelpers, CachedDatasetMixin implements StationService {
  final Dio _dio = DioFactory.create(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  );

  // In-memory cache
  List<Station>? _cachedStations;

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    try {
      await _ensureDataLoaded(cancelToken: cancelToken);

      // Calculate distances from search center
      final allWithDist = <Station>[];
      for (final s in _cachedStations!) {
        allWithDist.add(s.copyWith(
          dist: roundedDistance(params.lat, params.lng, s.lat, s.lng),
        ));
      }

      // Filter by radius; if nothing found, return nearest 20 instead
      final stations = filterByRadius(allWithDist, params.radiusKm);

      // Sort
      sortStations(stations, params);

      return wrapStations(stations, ServiceSource.denmarkApi);
    } on DioException catch (e, st) {
      throwApiException(e, defaultMessage: 'Netværksfejl', stackTrace: st);
    }
  }

  Future<void> _ensureDataLoaded({CancelToken? cancelToken}) async {
    if (_cachedStations != null && isDatasetFresh(const Duration(minutes: 5))) {
      return;
    }

    // Fetch all 3 sources in parallel
    final results = await Future.wait([
      _fetchOk(cancelToken: cancelToken),
      _fetchShell(cancelToken: cancelToken),
      _fetchQ8(),
    ]);

    _cachedStations = [...results[0], ...results[1], ...results[2]];
    markDatasetRefreshed();
  }

  /// OK — https://mobility-prices.ok.dk/api/v1/fuel-prices
  Future<List<Station>> _fetchOk({CancelToken? cancelToken}) async {
    try {
      final response = await _dio.get(
        'https://mobility-prices.ok.dk/api/v1/fuel-prices',
        cancelToken: cancelToken,
      );
      if (response.data is! Map) return [];
      final items = response.data['items'] as List<dynamic>? ?? [];

      return items.map((r) {
        final coords = r['coordinates'] as Map<String, dynamic>? ?? {};
        final lat = (coords['latitude'] as num?)?.toDouble() ?? 0;
        final lng = (coords['longitude'] as num?)?.toDouble() ?? 0;
        if (lat == 0 || lng == 0) return null;

        final prices = r['prices'] as List<dynamic>? ?? [];
        double? e5, diesel;
        for (final p in prices) {
          final name = (p['product_name']?.toString() ?? '').toLowerCase();
          final price = (p['price'] as num?)?.toDouble();
          if (name.contains('95') || name.contains('blyfri')) {
            e5 ??= price;
          } else if (name.contains('diesel')) {
            diesel ??= price;
          }
        }

        final street = r['street']?.toString() ?? '';
        final houseNr = r['house_number']?.toString() ?? '';
        final city = r['city']?.toString() ?? '';

        return Station(
          id: 'ok-${r['facility_number'] ?? ''}',
          name: 'OK',
          brand: 'OK',
          street: '$street $houseNr'.trim(),
          postCode: r['postal_code']?.toString() ?? '',
          place: city,
          lat: lat,
          lng: lng,
          dist: 0,
          e5: e5,
          e10: e5,
          diesel: diesel,
          isOpen: true,
          updatedAt: _formatIsoTime(r['last_updated_time']?.toString()),
        );
      }).whereType<Station>().toList();
    } on DioException catch (e, st) {
      debugPrint('DK OK fetch failed: $e\n$st');
      return [];
    }
  }

  /// Shell — https://shellpumpepriser.geoapp.me/v1/prices
  Future<List<Station>> _fetchShell({CancelToken? cancelToken}) async {
    try {
      final response = await _dio.get(
        'https://shellpumpepriser.geoapp.me/v1/prices',
        cancelToken: cancelToken,
      );
      if (response.data is! List) return [];

      return (response.data as List).map((r) {
        final coords = r['coordinates'] as Map<String, dynamic>? ?? {};
        final lat = double.tryParse(coords['latitude']?.toString() ?? '') ?? 0;
        final lng = double.tryParse(coords['longitude']?.toString() ?? '') ?? 0;
        if (lat == 0 || lng == 0) return null;

        final prices = r['prices'] as List<dynamic>? ?? [];
        double? e5, diesel;
        for (final p in prices) {
          final name = (p['productName']?.toString() ?? '').toLowerCase();
          final price = double.tryParse(p['price']?.toString() ?? '');
          if (name.contains('95') || name.contains('blyfri')) {
            e5 ??= price;
          } else if (name.contains('diesel')) {
            diesel ??= price;
          }
        }

        return Station(
          id: 'shell-${r['stationId'] ?? ''}',
          name: r['brand']?.toString() ?? 'Shell',
          brand: r['brand']?.toString() ?? 'Shell',
          street: '${r['street'] ?? ''} ${r['houseNumber'] ?? ''}'.trim(),
          postCode: r['postalCode']?.toString() ?? '',
          place: r['city']?.toString() ?? '',
          lat: lat,
          lng: lng,
          dist: 0,
          e5: e5,
          e10: e5,
          diesel: diesel,
          isOpen: true,
          updatedAt: _formatIsoTime(
            (prices.isNotEmpty ? prices.first['lastUpdated'] : null)?.toString(),
          ),
        );
      }).whereType<Station>().toList();
    } on DioException catch (e, st) {
      debugPrint('DK Shell fetch failed: $e\n$st');
      return [];
    }
  }

  /// Q8/F24 — no coordinates in API response, skip for now.
  Future<List<Station>> _fetchQ8() async {
    // Q8's API (beta.q8.dk) returns station prices but no lat/lng coordinates.
    // Without coordinates we cannot calculate distances or show on map.
    return [];
  }

  String? _formatIsoTime(String? iso) {
    if (iso == null) return null;
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } on FormatException catch (e, st) {
      debugPrint('DK date parse failed: $e\n$st');
      return null;
    }
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String stationId) async {
    throwDetailUnavailable('Danish APIs');
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(List<String> ids) async {
    return emptyPricesResult(ServiceSource.denmarkApi);
  }
}
