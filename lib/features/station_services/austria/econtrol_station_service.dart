// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../search/data/models/search_params.dart';
import '../../search/domain/entities/station.dart';
import '../../../core/services/dio_factory.dart';
import '../../../core/services/mixins/station_service_helpers.dart';
import '../../../core/services/service_result.dart';
import '../../../core/services/station_service.dart';
import '../../../core/logging/error_logger.dart';
import '../../station_detail/domain/opening_hours.dart';
import 'austria_opening_hours_adapter.dart';

/// Austrian fuel prices from E-Control Spritpreisrechner.
/// Free, no API key, no registration.
///
/// The API only supports 3 fuel types: DIE (Diesel), SUP (Super 95), GAS (CNG).
/// We query DIE + SUP to get both diesel and gasoline prices, then merge results.
class EControlStationService with StationServiceHelpers implements StationService {
  static const _baseUrl = 'https://api.e-control.at/sprit/1.0';

  final Dio _dio;

  /// #2181 — Dio is injectable so tests can assert request shape;
  /// defaults to the standard factory in production.
  EControlStationService({Dio? dio})
      : _dio = dio ??
            DioFactory.create(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            );

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    try {
      // Query both diesel and super to get all prices
      final results = await Future.wait([
        _queryByCoordinates(params.lat, params.lng, 'DIE', cancelToken: cancelToken),
        _queryByCoordinates(params.lat, params.lng, 'SUP', cancelToken: cancelToken),
      ]);

      final dieselStations = results[0];
      final superStations = results[1];

      // Merge: combine prices from both queries by station ID.
      // The merge key parses the (possibly-prefixed) id back to its
      // numeric upstream form so the diesel-query and super-query
      // results merge cleanly regardless of where the `at-` prefix
      // lands in the chain (added by `_parseStation`).
      final merged = <int, Station>{};

      for (final s in dieselStations) {
        final id = int.tryParse(_stripCountryPrefix(s.id)) ?? 0;
        merged[id] = s;
      }

      for (final s in superStations) {
        final id = int.tryParse(_stripCountryPrefix(s.id)) ?? 0;
        final existing = merged[id];
        if (existing != null) {
          // Merge e5 from super query into existing diesel station
          merged[id] = existing.copyWith(
            e5: s.e5,
            e10: s.e5, // Austrian "Super 95" maps to both E5 and E10
          );
        } else {
          merged[id] = s.copyWith(
            e5: s.e5,
            e10: s.e5,
          );
        }
      }

      // Filter by radius; if nothing found, return all (API already limits to nearest ~10)
      final allStations = merged.values.toList();
      final stations = filterByRadius(allStations, params.radiusKm);

      sortStations(stations, params);

      return wrapStations(stations, ServiceSource.eControlApi);
    } on DioException catch (e, st) {
      throwApiException(e, stackTrace: st);
    }
  }

  Future<List<Station>> _queryByCoordinates(
    double lat, double lng, String fuelType, {CancelToken? cancelToken}
  ) async {
    final response = await _dio.get(
      '$_baseUrl/search/gas-stations/by-address',
      queryParameters: {
        'latitude': lat,
        'longitude': lng,
        'fuelType': fuelType,
        'includeClosed': 'true',
      },
      cancelToken: cancelToken,
    );

    if (response.data is! List) return [];

    final stations = <Station>[];
    for (final r in response.data as List) {
      final station = _parseStation(r, lat, lng, fuelType);
      if (station != null) stations.add(station);
    }
    return stations;
  }

  /// #3196 — test seam for the per-fuel-type slot mapping. [_parseStation]
  /// is private and the live search only queries DIE/SUP, so the GAS→cng
  /// branch is only reachable for tests through this.
  @visibleForTesting
  Station? parseStationForTest(
    Map<String, dynamic> r, double searchLat, double searchLng, String fuelType,
  ) =>
      _parseStation(r, searchLat, searchLng, fuelType);

  Station? _parseStation(
    Map<String, dynamic> r, double searchLat, double searchLng, String fuelType,
  ) {
    try {
      final location = r['location'] as Map<String, dynamic>? ?? {};
      final lat = (location['latitude'] as num?)?.toDouble() ?? 0;
      final lng = (location['longitude'] as num?)?.toDouble() ?? 0;

      // Distance from API or calculated
      final apiDist = (r['distance'] as num?)?.toDouble();

      // Parse price
      double? price;
      final prices = r['prices'] as List<dynamic>? ?? [];
      for (final p in prices) {
        if (p is Map<String, dynamic>) {
          price = (p['amount'] as num?)?.toDouble();
        }
      }

      // Opening hours — parse the structured E-Control `openingHours[]`
      // rows into the common [WeeklyOpeningHours] (Epic C4, #2711) instead of
      // the legacy German paragraph. The structured `weeklyHours` is the
      // canonical signal; `openingHoursText` is kept (best-effort) for
      // back-compat with any consumer still reading the legacy string.
      final openingHours = r['openingHours'] as List<dynamic>? ?? [];
      final weeklyHours = const AustriaOpeningHoursAdapter().parse(openingHours);
      final hoursText = openingHours.map((oh) {
        if (oh is Map<String, dynamic>) {
          return '${oh['label'] ?? oh['day']}: ${oh['from']}-${oh['to']}';
        }
        return '';
      }).where((s) => s.isNotEmpty).join(', ');

      final name = r['name']?.toString() ?? '';
      final isOpen = r['open'] as bool? ?? true;

      // #753 — `at-` prefix so a numeric E-Control id can never collide
      // with another country's numeric id space when widget JSON or
      // search-state cache crosses a country switch.
      final rawId = r['id']?.toString() ?? '';
      return Station(
        id: rawId.isEmpty
            ? ''
            : (rawId.startsWith('at-') ? rawId : 'at-$rawId'),
        name: name,
        brand: _extractBrand(name),
        street: location['address']?.toString() ?? '',
        postCode: location['postalCode']?.toString() ?? '',
        place: location['city']?.toString() ?? '',
        lat: lat,
        lng: lng,
        dist: apiDist ?? roundedDistance(searchLat, searchLng, lat, lng),
        e5: fuelType == 'SUP' ? price : null,
        e10: fuelType == 'SUP' ? price : null,
        diesel: fuelType == 'DIE' ? price : null,
        // #3196 — E-Control's GAS fuel type is CNG (Erdgas/Methan), not LPG.
        cng: fuelType == 'GAS' ? price : null,
        isOpen: isOpen,
        openingHoursText: hoursText.isNotEmpty ? hoursText : null,
        openingHours: weeklyHours.availability ==
                OpeningHoursAvailability.notProvided
            ? null
            : weeklyHours,
      );
    } on FormatException catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'E-Control station parse failed'}));
      return null;
    }
  }

  /// Extract brand name from station name.
  /// E-Control names are like "BP", "Shell Austria", "AVANTI - Wien Platz 1".
  String _extractBrand(String name) {
    const brands = [
      'OMV', 'BP', 'Shell', 'Jet', 'Eni', 'Avanti', 'Turmöl',
      'IQ', 'Avia', 'A1', 'Genol', 'Lagerhaus', 'SB',
    ];
    final upper = name.toUpperCase();
    for (final b in brands) {
      if (upper.startsWith(b.toUpperCase())) return b;
    }
    // Use first word as brand
    final firstWord = name.split(RegExp(r'[\s\-]')).first;
    return firstWord.isNotEmpty ? firstWord : name;
  }

  /// Strip the `at-` prefix when round-tripping ids back into integer
  /// form (E-Control upstream ids are bare integers). Tolerant of legacy
  /// unprefixed favorites.
  static String _stripCountryPrefix(String id) =>
      id.startsWith('at-') ? id.substring(3) : id;

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(
    String stationId,
  ) async {
    throwDetailUnavailable('E-Control API');
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) async {
    return emptyPricesResult(ServiceSource.eControlApi);
  }
}
