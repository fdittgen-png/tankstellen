import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../search/data/models/search_params.dart';
import '../../search/domain/entities/station.dart';
import '../../../core/services/dio_factory.dart';
import '../../../core/services/mixins/station_service_helpers.dart';
import '../../../core/services/service_result.dart';
import '../../../core/services/station_service.dart';

/// Luxembourg fuel prices — government-regulated, uniform nationally.
///
/// Unlike every other country supported by Tankstellen, Luxembourg does not
/// have per-station price variation: the Ministry of the Economy publishes
/// official maximum retail prices by decree (roughly weekly), and every
/// filling station in the country charges the same figure. Because there is
/// no station-level variance, there is also no public price API — the
/// numbers live on two government / motoring-club pages:
///   - https://gouvernement.lu/en/service-citoyen/gestion-crise-energie/prix-petroliers.html
///   - https://www.acl.lu/en/mobility/fuel-prices/
///
/// The pages are heavyweight HTML/SPAs and the ACL page embeds prices in a
/// minified Vue `window.__INITIAL_STATE__` blob that loses its variable
/// names under their bundler, so a robust parser would be a project in
/// itself. The pragmatic trade-off (see issue #574) is to ship a fixed set
/// of "virtual" stations covering the largest Luxembourg cities, each
/// stamped with the same officially-decreed prices held in
/// [_regulatedPrices]. When the Ministry updates the decree, bump the
/// constants here — no new API calls, no cached dataset, no background
/// refresh race conditions.
///
/// If later we want live prices, the plan is:
///   1. Scrape the ACL `__INITIAL_STATE__` JSON at service load
///   2. Fall back to [_regulatedPrices] on any parse failure
/// but the static constants alone satisfy the "uniform country-wide price"
/// contract the issue asks for.
class LuxembourgStationService
    with StationServiceHelpers
    implements StationService {
  /// Injectable Dio for tests. The service does not currently make HTTP
  /// calls — the parameter is accepted so future scrape work can wire in
  /// a mock without changing the constructor signature.
  // ignore: unused_field
  final Dio _dio;

  LuxembourgStationService({Dio? dio})
      : _dio = dio ??
            DioFactory.create(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            );

  /// Officially decreed maximum retail prices in EUR/L.
  ///
  /// Source: Ministère de l'Économie, arrêté ministériel fixant les prix
  /// maxima de vente au détail des produits pétroliers.
  ///
  /// Last checked 2026-04 — update when a new arrêté is published. The
  /// figures are conservative baselines so the app still shows sensible
  /// data even if the decree falls behind the calendar by a few days.
  static const Map<String, double> _regulatedPrices = {
    'e5': 1.552,
    'e10': 1.524,
    'e98': 1.697,
    'diesel': 1.487,
    'lpg': 0.863,
  };

  /// Representative cities used as virtual stations. Coordinates come
  /// from OpenStreetMap; postal codes are the CAP of each city centre.
  ///
  /// The set is deliberately small and evenly distributed so a user
  /// searching from any part of Luxembourg hits at least one "station"
  /// within a sensible radius without cluttering the map. The same four
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
    try {
      final e5 = _regulatedPrices['e5'];
      final e10 = _regulatedPrices['e10'];
      final e98 = _regulatedPrices['e98'];
      final diesel = _regulatedPrices['diesel'];
      final lpg = _regulatedPrices['lpg'];

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
            e5: e5,
            e10: e10,
            e98: e98,
            diesel: diesel,
            lpg: lpg,
            isOpen: true,
          ),
      ];

      final filtered = filterByRadius(stations, params.radiusKm);
      sortStations(filtered, params);

      return wrapStations(filtered, ServiceSource.luxembourgApi);
    } on DioException catch (e, st) {
      // No HTTP call is made today, but the catch keeps the signature
      // stable if a future scrape is added.
      debugPrint('LU search failed: $e\n$st');
      throwApiException(e, defaultMessage: 'Network error', stackTrace: st);
    }
  }

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
