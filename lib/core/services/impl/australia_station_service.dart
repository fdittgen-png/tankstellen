import 'package:dio/dio.dart';

import '../../../features/search/data/models/search_params.dart';
import '../../../features/search/domain/entities/station.dart';
import '../../error/exceptions.dart';
import '../../utils/geo_utils.dart';
import '../dio_factory.dart';
import '../service_result.dart';
import '../station_service.dart';
import '../mixins/station_service_helpers.dart';

/// NSW FuelCheck API — Australian fuel price service.
///
/// Uses the NSW Government's FuelCheck API which provides real-time
/// fuel prices for New South Wales. Other states may be added later.
///
/// API: https://api.onegov.nsw.gov.au/FuelCheckApp/v2/fuel/prices
/// Auth: Requires free API key from api.nsw.gov.au
class AustraliaStationService with StationServiceHelpers implements StationService {
  final Dio _dio = DioFactory.create(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  );

  static const _baseUrl = 'https://api.onegov.nsw.gov.au/FuelCheckApp/v2';

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    try {
      // FuelCheck API: search by GPS coordinates
      final response = await _dio.get(
        '$_baseUrl/fuel/prices/nearby',
        queryParameters: {
          'latitude': params.lat,
          'longitude': params.lng,
          'radius': params.radiusKm,
          'sortby': 'price',
        },
        options: Options(headers: {
          'Content-Type': 'application/json',
          'apikey': 'empty', // NSW may require registration
        }),
        cancelToken: cancelToken,
      );

      final data = response.data;
      List<dynamic> stationList;
      if (data is Map<String, dynamic>) {
        stationList = data['stations'] as List<dynamic>? ?? [];
      } else if (data is List) {
        stationList = data;
      } else {
        throw const ApiException(message: 'Invalid FuelCheck response');
      }

      final stations = <Station>[];
      for (final item in stationList) {
        try {
          final lat = (item['location']?['latitude'] ?? item['lat'] as num?)?.toDouble();
          final lng = (item['location']?['longitude'] ?? item['lng'] as num?)?.toDouble();
          if (lat == null || lng == null) continue;

          final dist = distanceKm(params.lat, params.lng, lat, lng);
          if (dist > params.radiusKm) continue;

          // Parse fuel prices
          final prices = item['prices'] as List<dynamic>? ?? [];
          double? u91, u95, u98, diesel, lpg;
          for (final p in prices) {
            final fuelType = p['fueltype']?.toString() ?? '';
            final price = (p['price'] as num?)?.toDouble();
            if (fuelType.contains('U91') || fuelType.contains('91')) u91 = price;
            if (fuelType.contains('P95') || fuelType.contains('95')) u95 = price;
            if (fuelType.contains('P98') || fuelType.contains('98')) u98 = price;
            if (fuelType.contains('DL') || fuelType.toLowerCase().contains('diesel')) diesel = price;
            if (fuelType.contains('LPG')) lpg = price;
          }

          // Australian prices in cents per litre — convert to dollars
          stations.add(Station(
            id: 'au-${item['code'] ?? item['id'] ?? stations.length}',
            name: item['name']?.toString() ?? item['station']?.toString() ?? '',
            brand: item['brand']?.toString() ?? '',
            street: item['address']?.toString() ?? '',
            postCode: item['postcode']?.toString() ?? '',
            place: item['suburb']?.toString() ?? item['locality']?.toString() ?? '',
            lat: lat,
            lng: lng,
            dist: dist,
            e5: u91 != null ? u91 / 10 : null,  // cents/10 → $/L
            e10: u95 != null ? u95 / 10 : null,
            e98: u98 != null ? u98 / 10 : null,
            diesel: diesel != null ? diesel / 10 : null,
            lpg: lpg != null ? lpg / 10 : null,
            isOpen: true,
          ));
        } catch (_) {
          continue;
        }
      }

      stations.sort((a, b) => a.dist.compareTo(b.dist));

      return ServiceResult(
        data: stations.take(50).toList(),
        source: ServiceSource.australiaApi,
        fetchedAt: DateTime.now(),
      );
    } on DioException catch (e) {
      throw ApiException(
        message: e.message ?? 'FuelCheck API error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String stationId) async {
    throw const ApiException(message: 'Station detail not supported for Australia');
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(List<String> ids) async {
    return ServiceResult(data: {}, source: ServiceSource.australiaApi, fetchedAt: DateTime.now());
  }
}
