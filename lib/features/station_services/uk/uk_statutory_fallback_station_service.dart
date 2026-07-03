// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';

import '../../../core/domain/search_params.dart';
import '../../../core/domain/station.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/services/service_result.dart';
import '../../../core/services/station_service.dart';

/// GB primary/fallback composition for the statutory Fuel Finder migration
/// (#3190).
///
/// Once OAuth2 credentials are configured the statutory Fuel Finder bulk
/// path ([UkCmaBulkStationService] in feed mode) is the PRIMARY GB source,
/// and the legacy per-search retailer fan-out ([UkStationService]) is
/// demoted to an in-service fallback: it answers only when the statutory
/// path throws (endpoint outage, auth rejection after the feed's own
/// 401-retry, parse failure) **or** returns zero stations (an empty
/// statutory dataset must not silently blank the country while retailer
/// feeds still serve — the retailer feeds are themselves dying post-scheme,
/// so an honest empty from both is still possible).
///
/// The fallback fires per-search and is cheap in aggregate: the surrounding
/// [StationServiceChain] caches each search result, so a broken primary does
/// not multiply the legacy fan-out beyond the legacy path's historical rate.
///
/// Detail/prices delegate to the primary — both wrapped services expose the
/// same unsupported surface there (`throwDetailUnavailable` /
/// `emptyPricesResult`), so no fallback is meaningful.
class UkStatutoryFallbackStationService implements StationService {
  UkStatutoryFallbackStationService({
    required StationService primary,
    required StationService fallback,
  })  : _primary = primary,
        _fallback = fallback;

  final StationService _primary;
  final StationService _fallback;

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    ServiceResult<List<Station>> primaryResult;
    try {
      primaryResult =
          await _primary.searchStations(params, cancelToken: cancelToken);
    } on Exception catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
        'where': 'GB statutory Fuel Finder primary failed — legacy fallback',
      }));
      return _fallback.searchStations(params, cancelToken: cancelToken);
    }
    if (primaryResult.data.isEmpty) {
      // Whole-radius empty from the statutory dataset: cross-check against
      // the legacy fan-out so a broken/empty feed can't fake a fuel desert.
      // If the fan-out itself fails, the primary's honest empty stands.
      try {
        return await _fallback.searchStations(params,
            cancelToken: cancelToken);
      } on Exception catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
          'where': 'GB legacy fallback failed after empty statutory result',
        }));
        return primaryResult;
      }
    }
    return primaryResult;
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String stationId) =>
      _primary.getStationDetail(stationId);

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) =>
      _primary.getPrices(ids);
}
