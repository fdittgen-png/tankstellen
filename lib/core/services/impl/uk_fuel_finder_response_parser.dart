/// Pure parsing helpers for the GOV.UK Fuel Finder JSON envelope
/// (#573, #563 split). Lives separately from [UkFuelFinderService] so
/// the JSON-shape contract — which is what the live endpoint typically
/// breaks first — can be exercised with recorded fixtures, without
/// touching Dio or any OAuth state. Adding network or storage imports
/// here defeats the point of the split.
///
/// Public surface:
///  - [UkFuelFinderResponseParser.extractStationList] — coerce the
///    raw response body into a `List<dynamic>` of station records,
///    tolerating list-at-root, `{stations: […]}`, `{data: […]}`,
///    `{items: […]}`, or anything unrecognized (empty list).
///  - [UkFuelFinderResponseParser.parseFuelFinderStations] — parse
///    station records into [Station] entities, filter by radius,
///    dedupe by `site_id`, sort by distance, cap at 50.
///  - [UkFuelFinderResponseParser.parsePence] — UK pence-or-pound
///    coercion: anything > 10 is treated as pence and divided by 100.
library;

import 'package:flutter/foundation.dart';

import '../../../features/search/domain/entities/station.dart';
import '../../utils/geo_utils.dart';

/// Static helpers for turning Fuel Finder JSON into [Station] entities.
class UkFuelFinderResponseParser {
  UkFuelFinderResponseParser._();

  /// Coerce the raw decoded response into the station-record list.
  ///
  /// Accepts a top-level list, or one of `{stations,data,items}: […]`.
  /// Anything else degrades to an empty list rather than throwing — the
  /// service layer prefers "no stations" over a hard error when the
  /// envelope shape drifts.
  static List<dynamic> extractStationList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final list = data['stations'] as List<dynamic>? ??
          data['data'] as List<dynamic>? ??
          data['items'] as List<dynamic>? ??
          const <dynamic>[];
      return List<dynamic>.from(list);
    }
    return const <dynamic>[];
  }

  /// Parses Fuel Finder station records into [Station] entities, filters
  /// by radius, dedupes by `site_id`, sorts by distance, caps at 50.
  static List<Station> parseFuelFinderStations(
    List<dynamic> items, {
    required double lat,
    required double lng,
    required double radiusKm,
  }) {
    final seenIds = <String>{};
    final stations = <Station>[];

    for (final item in items) {
      if (item is! Map) continue;
      try {
        final loc = item['location'];
        final locMap = loc is Map ? loc : null;
        final itemLat = (locMap?['latitude'] as num?)?.toDouble() ??
            (item['latitude'] as num?)?.toDouble() ??
            (item['lat'] as num?)?.toDouble();
        final itemLng = (locMap?['longitude'] as num?)?.toDouble() ??
            (item['longitude'] as num?)?.toDouble() ??
            (item['lng'] as num?)?.toDouble();
        if (itemLat == null || itemLng == null) continue;

        final dist = distanceKm(lat, lng, itemLat, itemLng);
        if (dist > radiusKm) continue;

        final rawId = item['site_id']?.toString() ??
            item['id']?.toString() ??
            '${itemLat.toStringAsFixed(5)}_${itemLng.toStringAsFixed(5)}';
        final stationId = 'uk-$rawId';
        if (!seenIds.add(stationId)) continue;

        final prices = item['prices'] is Map
            ? Map<String, dynamic>.from(item['prices'] as Map)
            : <String, dynamic>{};

        stations.add(Station(
          id: stationId,
          name: item['site_name']?.toString() ??
              item['name']?.toString() ??
              item['brand']?.toString() ??
              '',
          brand: item['brand']?.toString() ?? '',
          street: item['address']?.toString() ?? '',
          postCode: item['postcode']?.toString() ?? '',
          place:
              item['town']?.toString() ?? item['locality']?.toString() ?? '',
          lat: itemLat,
          lng: itemLng,
          dist: dist,
          // E5 → FuelType.e5 (Super Unleaded 95 octane)
          e5: parsePence(prices['E5'] ?? prices['unleaded']),
          // E10 → FuelType.e10 (95 octane, 10% ethanol)
          e10: parsePence(prices['E10']),
          // E98 / Super Unleaded → FuelType.e98 (97/98 octane premium petrol)
          e98: parsePence(
            prices['E98'] ?? prices['super_unleaded'] ?? prices['E5_97'],
          ),
          // B7 / Diesel → FuelType.diesel (7% biodiesel blend, standard UK spec)
          diesel: parsePence(prices['B7'] ?? prices['diesel']),
          // SDV / Premium Diesel → FuelType.dieselPremium
          dieselPremium: parsePence(
            prices['SDV'] ?? prices['premium_diesel'] ?? prices['B7_plus'],
          ),
          isOpen: true,
        ));
      } catch (e, st) {
        debugPrint('UK Fuel Finder parse failed: $e\n$st');
        continue;
      }
    }

    stations.sort((a, b) => a.dist.compareTo(b.dist));
    return stations.take(50).toList();
  }

  /// UK prices are published in pence per litre. Anything above 10
  /// is treated as pence and divided by 100; anything at or below 10
  /// is assumed to already be in pounds.
  static double? parsePence(dynamic value) {
    if (value == null) return null;
    final price = double.tryParse(value.toString());
    if (price == null) return null;
    return price > 10 ? price / 100 : price;
  }
}
