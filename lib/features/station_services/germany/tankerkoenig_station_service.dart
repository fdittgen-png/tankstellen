import 'package:dio/dio.dart';
import '../../search/data/models/search_params.dart';
import '../../search/domain/entities/station.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/services/mixins/station_service_helpers.dart';
import '../../../core/services/service_result.dart';
import '../../../core/services/station_service.dart';
import 'tankerkoenig_batch_price_fetcher.dart';

// Key für den Zugriff auf die freie Tankerkönig-Spritpreis-API
// Für eigenen Key bitte hier https://creativecommons.tankerkoenig.de
// registrieren.
//
// Compliance notes (#713):
// - No API key is bundled in source — the user supplies their own via
//   Settings → API keys. See [SettingsHiveStore.getApiKey].
// - Attribution "Daten von Tankerkoenig.de (CC BY 4.0)" is shown on the
//   About screen (see [AboutSection]).
// - Rate limiting: 2s + 500ms random jitter on every request (see
//   [RateLimitInterceptor] + [tankerkoenigDioProvider]).
// - Bulk endpoints: favourites + alerts go through
//   [TankerkoenigBatchPriceFetcher] which batches 10 IDs per request
//   via `prices.php`.
// - Background refresh only fires when the user has configured
//   favourites or active alerts (user-initiated intent).
// - No implicit result filtering — user-selected brand, amenity, and
//   open-status filters are opt-in (MTS-K rule).

/// Concrete StationService implementation for the Tankerkoenig API.
///
/// Handles:
/// - Connection: Dio HTTP client with pre-configured base URL and headers
/// - Document: Tankerkoenig-specific JSON parsing and field mapping
///   (postCode int→String, price false→null, openingTimes array)
/// - Wraps all results in ServiceResult with source metadata
class TankerkoenigStationService with StationServiceHelpers implements StationService {
  final Dio _dio;
  final TankerkoenigBatchPriceFetcher _priceFetcher;

  TankerkoenigStationService(this._dio)
      : _priceFetcher = TankerkoenigBatchPriceFetcher(
          dio: _dio,
          batchSize: ApiConstants.maxPriceQueryIds,
        );

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
    } on DioException catch (e, st) {
      throwApiException(e, stackTrace: st);
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
    } on DioException catch (e, st) {
      throwApiException(e, stackTrace: st);
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

    // The batch fetcher chunks `ids` into Tankerkoenig's per-call cap and
    // merges the responses, so callers (e.g. favorites refresh with >10
    // stations) get prices for *every* requested station instead of just
    // the first 10. The API key is added by the Dio interceptor in
    // service_providers.dart, so we don't pass it here.
    try {
      final raw = await _priceFetcher.fetchBatch(ids: ids);
      final prices = raw.map(
        (id, data) => MapEntry(id, StationPrices.fromJson(data)),
      );

      return ServiceResult(
        data: prices,
        source: ServiceSource.tankerkoenigApi,
        fetchedAt: DateTime.now(),
      );
    } on DioException catch (e, st) {
      throwApiException(e, stackTrace: st);
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
