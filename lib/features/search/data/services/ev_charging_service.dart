import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/dio_factory.dart';
import '../../../../core/services/mixins/station_service_helpers.dart';
import '../../../../core/services/service_result.dart';
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
      final response = await _dio.get(
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

      final stations = <ChargingStation>[];
      for (final item in response.data as List) {
        final parsed = _parseStation(item, lat, lng);
        if (parsed != null) stations.add(parsed);
      }

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

  ChargingStation? _parseStation(Map<String, dynamic> item, double searchLat, double searchLng) {
    try {
      final addr = item['AddressInfo'] as Map<String, dynamic>?;
      if (addr == null) return null;

      final lat = (addr['Latitude'] as num?)?.toDouble();
      final lng = (addr['Longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;

      final dist = roundedDistance(searchLat, searchLng, lat, lng);

      final stationId = 'ocm-${item['ID']}';

      // Parse connectors
      final connections = item['Connections'] as List<dynamic>? ?? [];
      final connectors = <EvConnector>[];
      for (var i = 0; i < connections.length; i++) {
        final conn = connections[i] as Map<String, dynamic>;
        final rawLabel = _mapConnectionType(conn['ConnectionTypeID'] as int?);
        final statusLabel = _mapStatusType(conn['StatusTypeID'] as int?);
        connectors.add(EvConnector(
          id: '$stationId-c$i',
          type: connectorTypeFromLabel(rawLabel),
          rawType: rawLabel,
          maxPowerKw: (conn['PowerKW'] as num?)?.toDouble() ?? 0,
          quantity: (conn['Quantity'] as int?) ?? 1,
          currentType: _mapCurrentType(conn['CurrentTypeID'] as int?),
          status: statusLabel == null
              ? ConnectorStatus.unknown
              : ConnectorStatus.fromLabel(statusLabel),
          statusLabel: statusLabel,
        ));
      }

      // Parse operator
      final operatorInfo = item['OperatorInfo'] as Map<String, dynamic>?;
      final operatorName = operatorInfo?['Title']?.toString() ?? '';

      // Parse status
      final statusType = item['StatusType'] as Map<String, dynamic>?;
      final isOperational = statusType?['IsOperational'] as bool? ?? true;

      return ChargingStation(
        id: stationId,
        name: addr['Title']?.toString() ?? operatorName,
        operator: operatorName,
        latitude: lat,
        longitude: lng,
        dist: dist,
        address: addr['AddressLine1']?.toString() ?? '',
        postCode: addr['Postcode']?.toString() ?? '',
        place: addr['Town']?.toString() ?? '',
        connectors: connectors,
        totalPoints: (item['NumberOfPoints'] as int?) ?? connectors.length,
        isOperational: isOperational,
        usageCost: item['UsageCost']?.toString(),
        updatedAt: _formatDate(item['DateLastStatusUpdate']?.toString()),
        countryCode: addr['Country']?['ISOCode']?.toString(),
      );
    } catch (e, st) {
      debugPrint('EV station parse failed: $e\n$st');
      return null;
    }
  }

  /// Map OpenChargeMap ConnectionTypeID to human-readable name.
  String _mapConnectionType(int? typeId) => switch (typeId) {
    1 => 'Type 1',
    2 => 'CHAdeMO',
    25 => 'Type 2',
    27 => 'Tesla Supercharger',
    32 => 'CCS Type 1',
    33 => 'CCS Type 2',
    1036 => 'Type 2',
    _ => 'Unknown',
  };

  /// Map OpenChargeMap StatusTypeID to human-readable status.
  String? _mapStatusType(int? statusId) => switch (statusId) {
    0 => 'Unknown',
    10 => 'Currently Available',
    20 => 'In Use',
    30 => 'Temporarily Unavailable',
    50 => 'Operational',
    75 => 'Partly Operational',
    100 => 'Not Operational',
    150 => 'Planned',
    200 => 'Removed',
    _ => null,
  };

  /// Map OpenChargeMap CurrentTypeID.
  String? _mapCurrentType(int? currentId) => switch (currentId) {
    10 => 'AC',
    20 => 'DC',
    30 => 'AC/DC',
    _ => null,
  };

  String? _formatDate(String? iso) {
    if (iso == null) return null;
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (e, st) {
      debugPrint('EV date parse failed: $e\n$st');
      return null;
    }
  }
}
