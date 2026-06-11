// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';

import '../../../../core/services/dio_factory.dart';
import '../../../../core/services/mixins/station_service_helpers.dart';
import '../../../../core/services/service_result.dart';
import '../../../ev/data/services/ocm_poi_parser.dart';
import '../../../ev/domain/entities/charging_station.dart';

/// OpenChargeMap API client for EV charging station search.
///
/// Free API, user-provided key. Returns charging stations with
/// connectors, power, operator, and availability status.
class EVChargingService with StationServiceHelpers {
  final String apiKey;
  final Dio _dio;

  /// Default Dio factory — separate so tests can inject a capturing
  /// Dio without re-implementing the service's BaseOptions.
  static Dio _defaultDio() => DioFactory.create(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
      );

  EVChargingService({required this.apiKey, Dio? dio})
      : _dio = dio ?? _defaultDio();

  static const _baseUrl = 'https://api.openchargemap.io/v3/poi/';

  /// Search for EV charging stations near a location.
  ///
  /// OCM filters strictly by `countrycode` when the parameter is set,
  /// which can silently drop results in border regions and (#697) was
  /// suspected of missing legitimate ES chargers whose `country_code`
  /// metadata didn't match the query. Dropping the filter keeps the
  /// geographic constraint (lat/lng + distance) — which is enough for
  /// practical fuel-search use — without falsely zero-ing the result
  /// set. Callers that still need country-filtered data can filter
  /// post-hoc on [ChargingStation.countryCode].
  Future<ServiceResult<List<ChargingStation>>> searchStations({
    required double lat,
    required double lng,
    required double radiusKm,
    @Deprecated('OCM countrycode filter was dropping legitimate results '
        'in border regions (#697). Kept as a parameter for call-site '
        'backwards compatibility but no longer sent to the API.')
    String? countryCode,
    int maxResults = 50,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        _baseUrl,
        queryParameters: {
          'output': 'json',
          'latitude': lat,
          'longitude': lng,
          'distance': radiusKm,
          'distanceunit': 'KM',
          'maxresults': maxResults,
          'compact': true,
          'verbose': false,
          // 'countrycode' intentionally omitted — see doc above (#697).
          'key': apiKey,
        },
        cancelToken: cancelToken,
      );

      if (response.data is! List) {
        return ServiceResult(
          data: const [],
          source: ServiceSource.openChargeMapApi,
          fetchedAt: DateTime.now(),
        );
      }

      final stations =
          OcmPoiParser.parsePoiList(response.data as List, lat, lng);

      // Sort by distance
      stations.sort((a, b) => a.dist.compareTo(b.dist));

      return ServiceResult(
        data: stations,
        source: ServiceSource.openChargeMapApi,
        fetchedAt: DateTime.now(),
      );
    } on DioException catch (e, st) {
      throwApiException(e, defaultMessage: 'EV charging search failed', stackTrace: st);
    }
  }
}
