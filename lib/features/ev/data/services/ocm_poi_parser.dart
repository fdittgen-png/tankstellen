// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import '../../../../core/logging/error_logger.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../../../core/domain/ev/charging_station.dart';

/// Shared OpenChargeMap POI-list parser.
///
/// Single source of truth for turning a raw OCM `/poi/` JSON array into
/// [ChargingStation] entities — including the `UsageType` access-cost
/// signal (#2618). Extracted (#2634) so the map-side
/// `OpenChargeMapService` and the search-side `EVChargingService` parse
/// the *identical* shape rather than each re-implementing it. Every
/// malformed record is logged + skipped, never crashes the batch.
class OcmPoiParser {
  const OcmPoiParser._();

  /// Parse a raw OCM `/poi/` response [items] list into stations, each
  /// stamped with its haversine distance from [searchLat]/[searchLng].
  /// Non-map / malformed entries are dropped.
  static List<ChargingStation> parsePoiList(
    List<dynamic> items,
    double searchLat,
    double searchLng,
  ) {
    final stations = <ChargingStation>[];
    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;
      final parsed = parseStation(item, searchLat, searchLng);
      if (parsed != null) stations.add(parsed);
    }
    return stations;
  }

  /// Parse a single OCM POI [item]. Returns `null` (and logs) when the
  /// record is malformed or missing coordinates.
  static ChargingStation? parseStation(
    Map<String, dynamic> item,
    double searchLat,
    double searchLng,
  ) {
    try {
      final addr = item['AddressInfo'] as Map<String, dynamic>?;
      if (addr == null) return null;

      final lat = (addr['Latitude'] as num?)?.toDouble();
      final lng = (addr['Longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;

      final dist = _roundedDistance(searchLat, searchLng, lat, lng);

      final stationId = 'ocm-${item['ID']}';

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

      final operatorInfo = item['OperatorInfo'] as Map<String, dynamic>?;
      final operatorName = operatorInfo?['Title']?.toString() ?? '';

      final statusType = item['StatusType'] as Map<String, dynamic>?;
      final isOperational = statusType?['IsOperational'] as bool? ?? true;

      // OCM already returns this structured object; surface its flags +
      // title so the UI can render a free/paid/membership badge with zero
      // extra network (#2618).
      final usageType = item['UsageType'] as Map<String, dynamic>?;

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
        usageTypeId: (usageType?['ID'] as num?)?.toInt(),
        usageTypeTitle: usageType?['Title']?.toString(),
        isPayAtLocation: usageType?['IsPayAtLocation'] as bool?,
        isMembershipRequired: usageType?['IsMembershipRequired'] as bool?,
        updatedAt: _formatDate(item['DateLastStatusUpdate']?.toString()),
        countryCode: addr['Country']?['ISOCode']?.toString(),
      );
    } catch (e, st) {
      // #2146 — silent parse failures used to never reach the exportable
      // log; route via errorLogger so a malformed OCM record is
      // recoverable from a bug report.
      unawaited(errorLogger.log(ErrorLayer.services, e, st, context: const {
        'where': 'OcmPoiParser: station parse',
      }));
      return null;
    }
  }

  static double _roundedDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) =>
      double.parse(distanceKm(lat1, lng1, lat2, lng2).toStringAsFixed(1));

  /// Map OpenChargeMap ConnectionTypeID to human-readable name.
  static String _mapConnectionType(int? typeId) => switch (typeId) {
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
  static String? _mapStatusType(int? statusId) => switch (statusId) {
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
  static String? _mapCurrentType(int? currentId) => switch (currentId) {
        10 => 'AC',
        20 => 'DC',
        30 => 'AC/DC',
        _ => null,
      };

  static String? _formatDate(String? iso) {
    if (iso == null) return null;
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (e, st) {
      // #2146 — route to the exportable log; date drift surfaces as a
      // broken EV station detail otherwise.
      unawaited(errorLogger.log(ErrorLayer.services, e, st, context: {
        'where': 'OcmPoiParser: date parse',
        'iso': iso,
      }));
      return null;
    }
  }
}
