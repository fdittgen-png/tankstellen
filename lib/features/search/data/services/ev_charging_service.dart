import 'package:dio/dio.dart';

import '../../../../core/services/dio_factory.dart';
import '../../../../core/services/mixins/station_service_helpers.dart';
import '../../../../core/services/service_result.dart';
import '../../domain/entities/charging_station.dart';

/// OpenChargeMap API client for EV charging station search.
///
/// Free API, user-provided key. Returns charging stations with
/// connectors, power, operator, and availability status.
class EVChargingService with StationServiceHelpers {
  final String apiKey;

  EVChargingService({required this.apiKey});

  final Dio _dio = DioFactory.create(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  );

  static const _baseUrl = 'https://api.openchargemap.io/v3/poi/';

  /// Search for EV charging stations near a location.
  Future<ServiceResult<List<ChargingStation>>> searchStations({
    required double lat,
    required double lng,
    required double radiusKm,
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
          if (countryCode != null) 'countrycode': countryCode,
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
    } on DioException catch (e) {
      throwApiException(e, defaultMessage: 'EV charging search failed');
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

      // Parse connectors
      final connections = item['Connections'] as List<dynamic>? ?? [];
      final connectors = connections.map((c) {
        final conn = c as Map<String, dynamic>;
        return Connector(
          type: _mapConnectionType(conn['ConnectionTypeID'] as int?),
          powerKW: (conn['PowerKW'] as num?)?.toDouble() ?? 0,
          quantity: (conn['Quantity'] as int?) ?? 1,
          currentType: _mapCurrentType(conn['CurrentTypeID'] as int?),
          status: _mapStatusType(conn['StatusTypeID'] as int?),
        );
      }).toList();

      // Parse operator
      final operatorInfo = item['OperatorInfo'] as Map<String, dynamic>?;
      final operatorName = operatorInfo?['Title']?.toString() ?? '';

      // Parse status
      final statusType = item['StatusType'] as Map<String, dynamic>?;
      final isOperational = statusType?['IsOperational'] as bool? ?? true;

      return ChargingStation(
        id: 'ocm-${item['ID']}',
        name: addr['Title']?.toString() ?? operatorName,
        operator: operatorName,
        lat: lat,
        lng: lng,
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
    } catch (_) {
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
    } catch (_) {
      return null;
    }
  }
}
