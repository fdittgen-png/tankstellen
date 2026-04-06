import 'package:dio/dio.dart';
import '../../../features/search/data/models/search_params.dart';
import '../../../features/search/domain/entities/station.dart';
import '../../constants/api_constants.dart';
import '../../error/exceptions.dart';
import '../mixins/station_service_helpers.dart';
import '../service_result.dart';
import '../station_service.dart';

/// Concrete StationService implementation for the Tankerkoenig API.
///
/// Handles:
/// - Connection: Dio HTTP client with pre-configured base URL and headers
/// - Document: Tankerkoenig-specific JSON parsing and field mapping
///   (postCode int→String, price false→null, openingTimes array)
/// - Wraps all results in ServiceResult with source metadata
class TankerkoenigStationService with StationServiceHelpers implements StationService {
  final Dio _dio;

  TankerkoenigStationService(this._dio);

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.listEndpoint,
        queryParameters: {
          'lat': params.lat,
          'lng': params.lng,
          'rad': params.radiusKm.clamp(1, ApiConstants.maxRadiusKm),
          'type': params.fuelType.apiValue,
          // Tankerkoenig: 'sort' only allowed when type='all'
          if (params.fuelType.apiValue == 'all')
            'sort': params.sortBy.apiValue
          else
            'sort': 'dist',
        },
        cancelToken: cancelToken,
      );
      _checkOk(response.data);

      final stationsJson = response.data['stations'] as List<dynamic>? ?? [];
      final stations = stationsJson
          .map((j) => Station.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();

      return ServiceResult(
        data: stations,
        source: ServiceSource.tankerkoenigApi,
        fetchedAt: DateTime.now(),
      );
    } on DioException catch (e) {
      throwApiException(e);
    }
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(
    String stationId,
  ) async {
    try {
      final response = await _dio.get(
        ApiConstants.detailEndpoint,
        queryParameters: {'id': stationId},
      );
      _checkOk(response.data);

      final stationJson = response.data['station'] as Map<String, dynamic>;
      final station = Station.fromJson(stationJson);

      // Parse opening times
      final openingTimesRaw = stationJson['openingTimes'];
      final openingTimes = <OpeningTime>[];
      if (openingTimesRaw is List) {
        for (final ot in openingTimesRaw) {
          openingTimes.add(
            OpeningTime.fromJson(Map<String, dynamic>.from(ot as Map)),
          );
        }
      }

      // Parse overrides
      final overridesRaw = stationJson['overrides'];
      final overrides = <String>[];
      if (overridesRaw is List) {
        for (final o in overridesRaw) {
          overrides.add(o.toString());
        }
      }

      return ServiceResult(
        data: StationDetail(
          station: station,
          openingTimes: openingTimes,
          overrides: overrides,
          wholeDay: stationJson['wholeDay'] as bool? ?? false,
          state: stationJson['state'] as String?,
        ),
        source: ServiceSource.tankerkoenigApi,
        fetchedAt: DateTime.now(),
      );
    } on DioException catch (e) {
      throwApiException(e);
    }
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) async {
    if (ids.isEmpty) {
      return ServiceResult(
        data: {},
        source: ServiceSource.tankerkoenigApi,
        fetchedAt: DateTime.now(),
      );
    }

    final queryIds = ids.length > ApiConstants.maxPriceQueryIds
        ? ids.take(ApiConstants.maxPriceQueryIds).toList()
        : ids;

    try {
      final response = await _dio.get(
        ApiConstants.pricesEndpoint,
        queryParameters: {'ids': queryIds.join(',')},
      );
      _checkOk(response.data);

      final pricesJson = response.data['prices'] as Map<String, dynamic>? ?? {};
      final prices = pricesJson.map((id, data) {
        final p = data as Map<String, dynamic>;
        return MapEntry(id, StationPrices.fromJson(p));
      });

      return ServiceResult(
        data: prices,
        source: ServiceSource.tankerkoenigApi,
        fetchedAt: DateTime.now(),
      );
    } on DioException catch (e) {
      throwApiException(e);
    }
  }

  void _checkOk(dynamic data) {
    if (data is Map<String, dynamic> && data['ok'] != true) {
      throw ApiException(
        message: data['message']?.toString() ?? 'Unknown API error',
      );
    }
  }
}
