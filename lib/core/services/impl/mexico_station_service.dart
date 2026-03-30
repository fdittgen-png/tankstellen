import 'package:dio/dio.dart';

import '../../../features/search/data/models/search_params.dart';
import '../../../features/search/domain/entities/station.dart';
import '../../error/exceptions.dart';
import '../../utils/geo_utils.dart';
import '../dio_factory.dart';
import '../service_result.dart';
import '../station_service.dart';
import '../mixins/station_service_helpers.dart';
import '../mixins/cached_dataset_mixin.dart';

/// CRE (Comisión Reguladora de Energía) Mexican fuel price service.
///
/// Uses Mexico's open data portal (datos.gob.mx) for fuel station prices.
/// Free, no API key required. Data updated ~6 times daily.
///
/// API: https://datos.gob.mx/busca/dataset/ubicacion-de-gasolineras-y-precios-comerciales-de-gasolina-y-diesel
class MexicoStationService with StationServiceHelpers, CachedDatasetMixin implements StationService {
  final Dio _dio = DioFactory.create(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 60), // Large dataset
  );

  /// datos.gob.mx public fuel prices endpoint — no API key required.
  /// Returns station names, municipalities, states, and prices for
  /// Regular, Premium, and Diesel. Updated 6 times daily by CRE.
  static const _pricesUrl = 'https://api.datos.gob.mx/v2/precio.gasolina.publico';

  List<Map<String, dynamic>>? _cachedResults;
  DateTime? _lastFetch;

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    try {
      await _ensureDataLoaded(cancelToken);

      final stations = <Station>[];

      for (final item in _cachedResults ?? []) {
        // datos.gob.mx doesn't always include lat/lng — use Nominatim geocoding
        // as fallback when coordinates aren't available.
        // For now, filter by state/municipality matching if no coordinates.
        final regular = (item['precioRegular'] as num?)?.toDouble();
        final premium = (item['precioPremium'] as num?)?.toDouble();
        final diesel = (item['precioDiesel'] as num?)?.toDouble();

        // Try to get coordinates (may not be in this dataset)
        final lat = (item['latitud'] as num?)?.toDouble();
        final lng = (item['longitud'] as num?)?.toDouble();

        // If no coordinates, skip distance-based filtering
        double dist = 0;
        if (lat != null && lng != null) {
          dist = distanceKm(params.lat, params.lng, lat, lng);
          if (dist > params.radiusKm) continue;
        } else {
          // Without coordinates, include all results (user filters by municipality)
          continue; // Skip stations without coordinates
        }

        final permiso = item['permiso']?.toString() ?? '${stations.length}';

        stations.add(Station(
          id: 'mx-$permiso',
          name: item['nombre']?.toString() ?? '',
          brand: item['nombre']?.toString().split(' ').first ?? '',
          street: '',
          postCode: '',
          place: '${item['municipio'] ?? ''}, ${item['estado'] ?? ''}',
          lat: lat,
          lng: lng,
          dist: dist,
          e5: regular,
          e10: premium,
          diesel: diesel,
          isOpen: true,
        ));
      }

      stations.sort((a, b) => a.dist.compareTo(b.dist));

      return ServiceResult(
        data: stations.take(50).toList(),
        source: ServiceSource.mexicoApi,
        fetchedAt: DateTime.now(),
      );
    } on DioException catch (e) {
      throw ApiException(
        message: e.message ?? 'CRE API error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> _ensureDataLoaded(CancelToken? cancelToken) async {
    // Cache for 4 hours (data updates 6x daily)
    if (_cachedResults != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!).inHours < 4) {
      return;
    }

    // Fetch from datos.gob.mx — paginated, up to 1000 per page
    final allResults = <Map<String, dynamic>>[];
    int page = 1;
    bool hasMore = true;

    while (hasMore && page <= 20) { // Safety cap at 20 pages
      final response = await _dio.get(
        _pricesUrl,
        queryParameters: {'page': page, 'pageSize': 1000},
        cancelToken: cancelToken,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final results = data['results'] as List<dynamic>? ?? [];
        if (results.isEmpty) {
          hasMore = false;
        } else {
          allResults.addAll(results.cast<Map<String, dynamic>>());
          page++;
        }
      } else {
        hasMore = false;
      }
    }

    _cachedResults = allResults;
    _lastFetch = DateTime.now();
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String stationId) async {
    throw const ApiException(message: 'Station detail not supported for Mexico');
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(List<String> ids) async {
    return ServiceResult(data: {}, source: ServiceSource.mexicoApi, fetchedAt: DateTime.now());
  }
}
