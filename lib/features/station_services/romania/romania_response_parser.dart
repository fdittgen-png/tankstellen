// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Pure parsing helpers for the Monitorul Prețurilor single-product
/// envelope (#3193 — same split shape as the KR parser, #563). Lives
/// separately from `RomaniaStationService` so the JSON-shape contract —
/// which is what the live endpoint typically breaks first — can be
/// exercised with the recorded fixtures
/// (`test/fixtures/ro_monitorul_*_slice.json`) without touching Dio or
/// any network state. Adding network or storage imports here defeats
/// the point of the split.
///
/// Public surface:
///  - [MonitorulStationAccumulator]: in-flight merge target while the
///    service walks the five catalog-product calls.
///  - [mergeMonitorulProductResponse]: drains one product's envelope
///    (`Stations[]` + `Products[]`) into a
///    `Map<stationId, MonitorulStationAccumulator>`.
library;

import '../../search/domain/entities/fuel_type.dart';
import '../../search/domain/entities/station.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/utils/geo_utils.dart';
import 'romania_observatory_keys.dart';

/// Drain one single-product envelope into [byId], merging on the
/// station id (`Products[].stationid` joins `Stations[].id`).
///
/// Throws [ApiException] on:
///  - a top-level payload that is neither the envelope map nor the
///    backend's bare empty list,
///  - a backend error body (`Message` / `ExceptionMessage`).
void mergeMonitorulProductResponse(
  dynamic data,
  Map<String, MonitorulStationAccumulator> byId,
  FuelType fuelType,
) {
  // Live-verified: certain parameter shapes make the backend answer
  // `200 []`. Treat the bare empty list as "no stations".
  if (data is List && data.isEmpty) return;

  if (data is! Map) {
    throw const ApiException(
      message: 'Monitorul Prețurilor returned unparseable body',
      kind: FailureKind.parse,
    );
  }

  // The WebAPI error envelope carries Message/ExceptionMessage and no
  // station payload (live-verified Npgsql error shape).
  if (data['Stations'] == null &&
      (data['Message'] != null || data['ExceptionMessage'] != null)) {
    throw ApiException(
      message: 'Monitorul Prețurilor error: '
          '${data['ExceptionMessage'] ?? data['Message']}',
    );
  }

  final stations = data['Stations'];
  if (stations is List) {
    for (final raw in stations) {
      if (raw is! Map) continue;
      final id = raw['id']?.toString();
      if (id == null || id.isEmpty) continue;
      byId
          .putIfAbsent(id, () => MonitorulStationAccumulator(id))
          .absorbStation(raw);
    }
  }

  final products = data['Products'];
  if (products is List) {
    for (final raw in products) {
      if (raw is! Map) continue;
      final stationId = raw['stationid']?.toString();
      if (stationId == null || stationId.isEmpty) continue;
      final acc = byId[stationId];
      if (acc == null) continue; // product without a station row
      final price = RomaniaObservatoryKeys.parseLeiPerLitre(raw['price']);
      if (price != null) acc.prices[fuelType] = price;
    }
  }
}

/// In-flight accumulator while merging the per-product observatory
/// responses into one [Station] per station id.
class MonitorulStationAccumulator {
  final String id;
  String? name;
  String? brand;
  String? street;
  String? postCode;
  String? place;
  double? lat;
  double? lng;
  String? updatedAt;
  final Map<FuelType, double> prices = <FuelType, double>{};

  MonitorulStationAccumulator(this.id);

  /// Pull the base fields off the first product-call payload that
  /// carries them; later calls for the same station only add prices.
  void absorbStation(Map raw) {
    name ??= raw['name']?.toString().trim();

    final network = raw['network'];
    if (network is Map) brand ??= network['name']?.toString().trim();

    final addr = raw['addr'];
    if (addr is Map) {
      street ??= addr['addrstring']?.toString().trim();
      postCode ??= addr['zipcode']?.toString().trim();
      // The address string's last comma segment is the locality
      // ("..., sector 3, 030327, Bucuresti" → "Bucuresti").
      if (place == null) {
        final segments = street?.split(',');
        if (segments != null && segments.length > 1) {
          place = segments.last.trim();
        }
      }
      final location = addr['location'];
      if (location is Map) {
        lat ??= _parseDouble(location['Lat']);
        lng ??= _parseDouble(location['Lon']);
      }
    }

    final updated = raw['updatedate']?.toString().trim();
    if (updated != null && updated.isNotEmpty) updatedAt ??= updated;
  }

  /// Materialize into a [Station]; `null` when coordinates are missing
  /// or no recognised fuel carries a price (nothing actionable).
  Station? toStation(double fromLat, double fromLng) {
    final resolvedLat = lat;
    final resolvedLng = lng;
    if (resolvedLat == null || resolvedLng == null) return null;
    if (resolvedLat == 0 && resolvedLng == 0) return null;
    if (prices.isEmpty) return null;

    final resolvedBrand = brand ?? '';
    final resolvedName = (name?.isNotEmpty ?? false) ? name! : resolvedBrand;

    return Station(
      id: 'ro-$id',
      name: resolvedName,
      brand: resolvedBrand,
      street: street ?? '',
      postCode: postCode ?? '',
      place: place ?? '',
      lat: resolvedLat,
      lng: resolvedLng,
      dist: _roundedDistance(fromLat, fromLng, resolvedLat, resolvedLng),
      e5: prices[FuelType.e5],
      e98: prices[FuelType.e98],
      diesel: prices[FuelType.diesel],
      dieselPremium: prices[FuelType.dieselPremium],
      lpg: prices[FuelType.lpg],
      // #3198 — the observatory exposes no open/closed flag: honest
      // unknown instead of the old hard-coded `true`.
      isOpen: null,
      updatedAt: updatedAt,
    );
  }

  static double? _parseDouble(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw.trim());
    return null;
  }
}

/// Haversine distance in km, rounded to one decimal — mirrors
/// `StationServiceHelpers.roundedDistance` so the accumulator stays
/// free of the mixin's HTTP/result-wrapping baggage (same pattern as
/// the KR parser).
double _roundedDistance(double lat1, double lng1, double lat2, double lng2) {
  final d = distanceKm(lat1, lng1, lat2, lng2);
  return double.parse(d.toStringAsFixed(1));
}
