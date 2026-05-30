// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';

import '../../features/search/data/models/search_params.dart';
import '../../features/search/domain/entities/station.dart';
import 'service_result.dart';

/// Prices for a single station, returned by the batch price refresh endpoint.
///
/// Carries a nullable price field for **every** priced fuel the [Station]
/// entity exposes — e5, e10, e98, diesel, dieselPremium, e85, lpg, cng (#2249).
/// Before this widening the model only held e5/e10/diesel, so a favorites /
/// alerts price refresh silently dropped LPG / CNG / E98 / diesel-premium /
/// E85 for fuel-rich countries (FR, IT, ES …): the fresh value existed on the
/// wire but had nowhere to land and the old price was kept instead.
///
/// A null value means the station does not sell that fuel or the price is
/// unavailable. The [status] field indicates whether the station is currently
/// open. (Electric / hydrogen are not modelled here because they are not
/// priced on the [Station] entity either — they would need their own units.)
class StationPrices {
  final double? e5;
  final double? e10;
  final double? e98;
  final double? diesel;
  final double? dieselPremium;
  final double? e85;
  final double? lpg;
  final double? cng;
  final String status;

  const StationPrices({
    this.e5,
    this.e10,
    this.e98,
    this.diesel,
    this.dieselPremium,
    this.e85,
    this.lpg,
    this.cng,
    required this.status,
  });

  bool get isOpen => status == 'open';

  Map<String, dynamic> toJson() => {
        'e5': e5,
        'e10': e10,
        'e98': e98,
        'diesel': diesel,
        'dieselPremium': dieselPremium,
        'e85': e85,
        'lpg': lpg,
        'cng': cng,
        'status': status,
      };

  factory StationPrices.fromJson(Map<String, dynamic> json) => StationPrices(
        e5: _price(json['e5']),
        e10: _price(json['e10']),
        e98: _price(json['e98']),
        diesel: _price(json['diesel']),
        dieselPremium: _price(json['dieselPremium']),
        e85: _price(json['e85']),
        lpg: _price(json['lpg']),
        cng: _price(json['cng']),
        status: json['status'] as String? ?? 'closed',
      );

  /// Coerce a raw JSON value to a `double?`: numbers become doubles, anything
  /// else (null, `false` closed-sentinel, stray strings) becomes null. Shared
  /// by every fuel field so the defensive contract is identical across them.
  static double? _price(dynamic value) =>
      value is num ? value.toDouble() : null;
}

/// Abstract interface for station data providers.
///
/// Any data source that can answer "what stations are near here?" and
/// "what are the current prices?" implements this interface. Each
/// country-specific API has its own implementation (Tankerkoenig for DE,
/// Prix-Carburants for FR, E-Control for AT, etc.).
///
/// The document format (JSON structure, field names, coordinate encoding)
/// is handled inside each implementation -- consumers only see domain
/// objects ([Station], [StationDetail], [StationPrices]).
///
/// All implementations are wrapped in [StationServiceChain] which adds
/// caching, fallback, and request deduplication on top.
///
/// To add a new country, implement this interface and register it in
/// `service_providers.dart`. See docs/CONTRIBUTING.md for the full guide.
abstract class StationService {
  /// Search for stations near a geographic location.
  ///
  /// [params] specifies the search center (lat/lng), radius, fuel type
  /// filter, sort order, and optional postal code. Returns a list of
  /// [Station] objects sorted according to [SearchParams.sortBy].
  ///
  /// Throws [ApiException] on network or API errors. The caller
  /// ([StationServiceChain]) catches these and falls back to cache.
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  });

  /// Get full details for a single station by its ID.
  ///
  /// Returns extended data including opening times, overrides, and state.
  /// Not all country APIs support this -- unsupported implementations
  /// throw [ApiException] with an appropriate message.
  Future<ServiceResult<StationDetail>> getStationDetail(String stationId);

  /// Refresh current prices for up to 10 stations in a single request.
  ///
  /// [ids] is the list of station IDs to query. Returns a map from
  /// station ID to [StationPrices]. Used by the favorites screen to
  /// update prices without performing a full search.
  ///
  /// Not all country APIs support batch price queries. Unsupported
  /// implementations return an empty map.
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  );
}
