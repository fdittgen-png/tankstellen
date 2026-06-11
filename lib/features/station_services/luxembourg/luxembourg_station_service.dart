// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../search/data/models/search_params.dart';
import '../../search/domain/entities/fuel_type.dart';
import '../../search/domain/entities/station.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/services/dio_factory.dart';
import '../../../core/services/mixins/station_service_helpers.dart';
import '../../../core/services/service_result.dart';
import '../../../core/services/station_service.dart';
import 'lustat_parser.dart' as lustat;
import 'lustat_parser.dart' show LustatObservation;
import '../../../core/logging/error_logger.dart';

/// Luxembourg fuel prices — government-regulated, uniform nationally.
///
/// Unlike every other country supported by Tankstellen, Luxembourg does not
/// have per-station price variation: the Ministry of the Economy publishes
/// official maximum retail prices by decree (roughly weekly), and every
/// filling station in the country charges the same figure. There is no
/// station-level API; the model is a fixed set of "virtual" stations
/// covering the largest Luxembourg cities, each stamped with the same
/// officially-decreed prices.
///
/// **Live prices (#3195)**: the decree figures are fetched from
/// **LUSTAT**, STATEC's official statistics API (the national statistics
/// institute republishes the ministerial *prix maxima* per decree date).
/// The two SDMX dataflows consumed — both live-verified and recorded as
/// fixtures (`test/fixtures/lu_lustat_{essence,diesel}_slice.json`,
/// recorded 2026-06-10):
///
/// ```
/// GET https://lustat.statec.lu/rest/data/LU1,DSD_PRIX_ESSENCE@DF_E5301,1.0/
///     all?lastNObservations=1&dimensionAtObservation=AllDimensions&format=jsondata
///       → MOTOR_ENERGY SP95 / SP98 (EUR/L petrol maxima + decree date)
/// GET .../LU1,DSD_PRIX_ESSENCE@DF_E5302,1.0/...
///       → MOTOR_ENERGY DIE (EUR/L road-diesel maximum + decree date)
/// ```
///
/// Mapping: `SP95 → e5 + e10` (the decree publishes one 95-octane
/// figure), `SP98 → e98`, `DIE → diesel`. The decree's effective date
/// (SDMX `TIME_PERIOD`) is surfaced as the stations' `updatedAt`. LPG
/// has no daily LUSTAT flow (only a quarterly price-structure table) and
/// is therefore only present on the stale fallback below.
///
/// **Fallback (#3195)**: when LUSTAT is unreachable or unparseable the
/// service falls back to the compile-time [_fallbackPrices] constants —
/// explicitly marked stale via `ServiceResult.isStale` and an attached
/// [ServiceError], so the UI/chain can tell decree-fresh figures from
/// the conservative baseline. The previous behaviour (constants always,
/// silently ~15–18 % stale within weeks) was the bug this fixes.
class LuxembourgStationService
    with StationServiceHelpers
    implements StationService {
  /// LUSTAT SDMX REST root.
  static const String defaultBaseUrl = 'https://lustat.statec.lu/rest/data';

  /// Dataflow id for *Prix maxima de l'essence* (SP95 / SP98).
  static const String essenceFlow = 'LU1,DSD_PRIX_ESSENCE@DF_E5301,1.0';

  /// Dataflow id for *Prix maxima du gasoil routier* (DIE).
  static const String dieselFlow = 'LU1,DSD_PRIX_ESSENCE@DF_E5302,1.0';

  /// Query suffix asking for only the latest observation per series in
  /// flat SDMX-JSON.
  static const String _query =
      'all?lastNObservations=1&dimensionAtObservation=AllDimensions&format=jsondata';

  final Dio _dio;
  final String _baseUrl;

  LuxembourgStationService({Dio? dio, String? baseUrl})
      : _dio = dio ??
            DioFactory.create(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ),
        _baseUrl = baseUrl ?? defaultBaseUrl;

  /// Last-resort fallback prices in EUR/L (officially decreed maxima).
  ///
  /// Source: Ministère de l'Économie via LUSTAT, recorded 2026-06-10
  /// (petrol decree of 2026-06-05, diesel decree of 2026-06-03; LPG from
  /// the older 2026-04 check — no daily LUSTAT flow exists for it).
  /// Served **only** when the live LUSTAT fetch fails, and always marked
  /// stale via `ServiceResult.isStale` (#3195).
  static const Map<String, double> _fallbackPrices = {
    'e5': 1.720,
    'e10': 1.720,
    'e98': 1.848,
    'diesel': 1.782,
    'lpg': 0.863,
  };

  /// Representative cities used as virtual stations. Coordinates come
  /// from OpenStreetMap; postal codes are the CAP of each city centre.
  ///
  /// The set is deliberately small and evenly distributed so a user
  /// searching from any part of Luxembourg hits at least one "station"
  /// within a sensible radius without cluttering the map. The same
  /// regulated prices are stamped on every entry.
  static const List<_LuxembourgCity> _cities = [
    _LuxembourgCity(
      id: 'lu-luxembourg-ville',
      name: 'Luxembourg-Ville',
      street: 'Centre',
      postCode: '1009',
      place: 'Luxembourg',
      lat: 49.6116,
      lng: 6.1319,
    ),
    _LuxembourgCity(
      id: 'lu-esch-sur-alzette',
      name: 'Esch-sur-Alzette',
      street: 'Centre',
      postCode: '4002',
      place: 'Esch-sur-Alzette',
      lat: 49.4960,
      lng: 5.9806,
    ),
    _LuxembourgCity(
      id: 'lu-differdange',
      name: 'Differdange',
      street: 'Centre',
      postCode: '4501',
      place: 'Differdange',
      lat: 49.5244,
      lng: 5.8914,
    ),
    _LuxembourgCity(
      id: 'lu-dudelange',
      name: 'Dudelange',
      street: 'Centre',
      postCode: '3402',
      place: 'Dudelange',
      lat: 49.4807,
      lng: 6.0875,
    ),
    _LuxembourgCity(
      id: 'lu-ettelbruck',
      name: 'Ettelbruck',
      street: 'Centre',
      postCode: '9002',
      place: 'Ettelbruck',
      lat: 49.8479,
      lng: 6.1033,
    ),
    _LuxembourgCity(
      id: 'lu-diekirch',
      name: 'Diekirch',
      street: 'Centre',
      postCode: '9202',
      place: 'Diekirch',
      lat: 49.8686,
      lng: 6.1551,
    ),
    _LuxembourgCity(
      id: 'lu-wiltz',
      name: 'Wiltz',
      street: 'Centre',
      postCode: '9501',
      place: 'Wiltz',
      lat: 49.9664,
      lng: 5.9331,
    ),
    _LuxembourgCity(
      id: 'lu-remich',
      name: 'Remich',
      street: 'Centre',
      postCode: '5501',
      place: 'Remich',
      lat: 49.5450,
      lng: 6.3678,
    ),
  ];

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    Map<FuelType, double> prices;
    String? effectiveDate;
    var isStale = false;
    final errors = <ServiceError>[];

    try {
      final responses = await Future.wait([
        _dio.get('$_baseUrl/$essenceFlow/$_query', cancelToken: cancelToken),
        _dio.get('$_baseUrl/$dieselFlow/$_query', cancelToken: cancelToken),
      ]);

      final latest = <String, LustatObservation>{};
      for (final r in responses) {
        parseLustatLatest(r.data, into: latest);
      }

      final sp95 = latest['SP95'];
      final sp98 = latest['SP98'];
      final die = latest['DIE'];

      prices = <FuelType, double>{
        if (sp95 != null) FuelType.e5: sp95.value,
        if (sp95 != null) FuelType.e10: sp95.value,
        if (sp98 != null) FuelType.e98: sp98.value,
        if (die != null) FuelType.diesel: die.value,
      };
      if (prices.isEmpty) {
        throw const ApiException(
          message: 'LUSTAT returned no motor-fuel observations',
          kind: FailureKind.parse,
        );
      }

      // Surface the newest decree date among the fuels we actually use.
      effectiveDate = [sp95, sp98, die]
          .whereType<LustatObservation>()
          .map((o) => o.period)
          .reduce((a, b) => a.compareTo(b) >= 0 ? a : b);
    } catch (e, st) {
      // Never-throws fallback (#3195): any fetch/parse failure degrades
      // to the compile-time constants, clearly marked stale.
      unawaited(errorLogger.log(ErrorLayer.other, e, st,
          context: const {'where': 'LU LUSTAT fetch failed → stale fallback'}));
      isStale = true;
      errors.add(ServiceError(
        source: ServiceSource.luxembourgApi,
        message: 'LUSTAT prix-maxima fetch failed; serving compile-time '
            'fallback decree prices (#3195): $e',
        kind: e is ApiException ? e.kind : FailureKind.network,
        occurredAt: DateTime.now(),
      ));
      prices = <FuelType, double>{
        FuelType.e5: _fallbackPrices['e5']!,
        FuelType.e10: _fallbackPrices['e10']!,
        FuelType.e98: _fallbackPrices['e98']!,
        FuelType.diesel: _fallbackPrices['diesel']!,
        FuelType.lpg: _fallbackPrices['lpg']!,
      };
    }

    final stations = <Station>[
      for (final c in _cities)
        Station(
          id: c.id,
          name: c.name,
          brand: 'Luxembourg',
          street: c.street,
          postCode: c.postCode,
          place: c.place,
          lat: c.lat,
          lng: c.lng,
          dist: roundedDistance(params.lat, params.lng, c.lat, c.lng),
          e5: prices[FuelType.e5],
          e10: prices[FuelType.e10],
          e98: prices[FuelType.e98],
          diesel: prices[FuelType.diesel],
          lpg: prices[FuelType.lpg],
          isOpen: true,
          updatedAt: effectiveDate,
        ),
    ];

    final filtered = filterByRadius(stations, params.radiusKm);
    sortStations(filtered, params);

    return ServiceResult(
      data: filtered,
      source: ServiceSource.luxembourgApi,
      fetchedAt: DateTime.now(),
      isStale: isStale,
      errors: errors,
    );
  }

  /// Thin delegate over the pure [parseLustatLatest] in
  /// `lustat_parser.dart` (#3195 split) — kept on the service so tests
  /// drive the exact parser the live call uses.
  @visibleForTesting
  Map<String, LustatObservation> parseLustatLatest(
    dynamic data, {
    Map<String, LustatObservation>? into,
  }) =>
      lustat.parseLustatLatest(data, into: into);

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(
    String stationId,
  ) async {
    throwDetailUnavailable('Luxembourg regulated prices');
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) async {
    return emptyPricesResult(ServiceSource.luxembourgApi);
  }
}

/// Internal representation of a Luxembourg city used as a virtual station.
/// Kept private — callers only ever see fully-built [Station] objects.
class _LuxembourgCity {
  final String id;
  final String name;
  final String street;
  final String postCode;
  final String place;
  final double lat;
  final double lng;

  const _LuxembourgCity({
    required this.id,
    required this.name,
    required this.street,
    required this.postCode,
    required this.place,
    required this.lat,
    required this.lng,
  });
}
