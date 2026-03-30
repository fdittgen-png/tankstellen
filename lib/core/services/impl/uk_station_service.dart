import 'package:dio/dio.dart';

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
/// Uses the CMA's open fuel prices API launched in 2024.
/// Free, no API key required for basic access.
///
/// Primary: https://www.fuel-finder.service.gov.uk/api/v1/pfs
/// Alternative (no auth): CSV from gov.uk or checkfuelprices.co.uk
///
/// The CMA API requires OAuth 2.0 (client credentials). For MVP we use
/// the free checkfuelprices.co.uk wrapper which provides the same data
/// without authentication. Can be upgraded to official OAuth later.
class UkStationService with StationServiceHelpers implements StationService {
  final Dio _dio = DioFactory.create(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  );

  // Free wrapper API — same CMA data, no auth required
  static const _baseUrl = 'https://checkfuelprices.co.uk/api';

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/stations',
        queryParameters: {
          'lat': params.lat,
          'lng': params.lng,
          'radius': params.radiusKm,
        },
        cancelToken: cancelToken,
      );

      final data = response.data;
      List<dynamic> stationList;
      if (data is Map<String, dynamic>) {
        stationList = data['stations'] as List<dynamic>? ?? data['data'] as List<dynamic>? ?? [];
      } else if (data is List) {
        stationList = data;
      } else {
        throw const ApiException(message: 'Invalid UK fuel price response');
      }

      final stations = <Station>[];
      for (final item in stationList) {
        try {
          final lat = (item['location']?['latitude'] ?? item['lat'] as num?)?.toDouble();
          final lng = (item['location']?['longitude'] ?? item['lng'] as num?)?.toDouble();
          if (lat == null || lng == null) continue;

          final dist = distanceKm(params.lat, params.lng, lat, lng);
          if (dist > params.radiusKm) continue;

          final prices = item['prices'] as Map<String, dynamic>? ?? {};

          stations.add(Station(
            id: 'uk-${item['id'] ?? item['site_id'] ?? stations.length}',
            name: item['name']?.toString() ?? item['site_name']?.toString() ?? '',
            brand: item['brand']?.toString() ?? '',
            street: item['address']?.toString() ?? '',
            postCode: item['postcode']?.toString() ?? '',
            place: item['town']?.toString() ?? item['locality']?.toString() ?? '',
            lat: lat,
            lng: lng,
            dist: dist,
            // UK prices in pence per litre — convert to pounds
            e5: _parsePence(prices['E5'] ?? prices['unleaded']),
            e10: _parsePence(prices['E10']),
            e98: _parsePence(prices['super_unleaded'] ?? prices['E5_97']),
            diesel: _parsePence(prices['B7'] ?? prices['diesel']),
            isOpen: true,
          ));
        } catch (_) {
          continue;
        }
      }

      stations.sort((a, b) => a.dist.compareTo(b.dist));

      return ServiceResult(
        data: stations.take(50).toList(),
        source: ServiceSource.ukApi,
        fetchedAt: DateTime.now(),
      );
    } on DioException catch (e) {
      throw ApiException(
        message: e.message ?? 'UK fuel price API error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// UK prices may be in pence — convert to pounds if > 10.
  double? _parsePence(dynamic value) {
    if (value == null) return null;
    final price = double.tryParse(value.toString());
    if (price == null) return null;
    // If price > 10, it's likely in pence — convert to pounds
    return price > 10 ? price / 100 : price;
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String stationId) async {
    throw const ApiException(message: 'Station detail not supported for UK');
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(List<String> ids) async {
    return ServiceResult(data: {}, source: ServiceSource.ukApi, fetchedAt: DateTime.now());
  }
}
