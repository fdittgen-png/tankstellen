// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';
import '../../search/data/models/search_params.dart';
import '../../search/domain/entities/station.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/services/mixins/station_service_helpers.dart';
import '../../../core/services/service_result.dart';
import '../../../core/services/station_service.dart';
import '../../station_detail/domain/opening_hours.dart';
import 'germany_opening_hours_adapter.dart';
import 'tankerkoenig_batch_price_fetcher.dart';

// Key für den Zugriff auf die freie Tankerkönig-Spritpreis-API
// Für eigenen Key bitte hier https://onboarding.tankerkoenig.de
// registrieren.
//
// Compliance notes (#713):
// - No API key is bundled in source — the user supplies their own via
//   Settings → API keys. See [SettingsHiveStore.getApiKey].
// - Attribution "Daten von Tankerkoenig.de (CC BY 4.0)" is shown on the
//   About screen (see [AboutSection]).
// - Rate limiting: 2s + 500ms random jitter on every request (see
//   [RateLimitInterceptor] + [tankerkoenigDioProvider]).
// - Bulk endpoints: favourites + alerts go through
//   [TankerkoenigBatchPriceFetcher] which batches 10 IDs per request
//   via `prices.php`.
// - Background refresh only fires when the user has configured
//   favourites or active alerts (user-initiated intent).
// - No implicit result filtering — user-selected brand, amenity, and
//   open-status filters are opt-in (MTS-K rule).

/// Concrete StationService implementation for the Tankerkoenig API.
///
/// Handles:
/// - Connection: Dio HTTP client with pre-configured base URL and headers
/// - Document: Tankerkoenig-specific JSON parsing and field mapping
///   (postCode int→String, price false→null, openingTimes array)
/// - Wraps all results in ServiceResult with source metadata
class TankerkoenigStationService with StationServiceHelpers implements StationService {
  final Dio _dio;
  final TankerkoenigBatchPriceFetcher _priceFetcher;

  TankerkoenigStationService(this._dio)
      : _priceFetcher = TankerkoenigBatchPriceFetcher(
          dio: _dio,
          batchSize: ApiConstants.maxPriceQueryIds,
        );

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.listEndpoint,
        queryParameters: {
          'lat': params.lat,
          'lng': params.lng,
          'rad': params.radiusKm.clamp(1, ApiConstants.maxRadiusKm),
          'type': params.fuelType.apiValue,
          // Tankerkoenig: 'sort' only allowed when type='all'
          if (params.fuelType.apiValue == 'all')
            'sort': params.sortBy.apiValue
          else
            'sort': 'dist',
        },
        cancelToken: cancelToken,
      );
      _checkOk(response.data);

      final stationsJson = response.data['stations'] as List<dynamic>? ?? [];
      // #1775 — apply the `de-` country prefix to the id *inside* the
      // decoded map, so each entry decodes to its final `Station` in a
      // single `fromJson` — no second `.map` + per-station `copyWith`
      // shell. (A `compute()` isolate, as the Argentina CSV service
      // uses, is not worth it here: isolate spawn + result
      // serialisation would cost more than parsing ~100 small JSON
      // objects on the UI isolate.)
      final stations = stationsJson.map((j) {
        final map = Map<String, dynamic>.from(j as Map);
        // #753 — scope ids with the `de-` country prefix so a German
        // UUID can never collide with another country's numeric id
        // (FR `12345`, AT `12345`, ES `IDEESS`, IT registry id). The
        // prefix is stripped before any call back out to Tankerkönig.
        map['id'] = _withCountryPrefix(map['id'] as String);
        return Station.fromJson(map);
      }).toList();

      return ServiceResult(
        data: stations,
        source: ServiceSource.tankerkoenigApi,
        fetchedAt: DateTime.now(),
      );
    } on DioException catch (e, st) {
      throwApiException(e, stackTrace: st);
    }
  }

  // #2778 — Tankerkönig list.php (search) carries no hours; openingTimes live
  // only on detail.php, parsed below. The station-detail fast path fetches
  // detail for a DE search tap (see _detailOnlyOpeningHoursCountries in
  // station_detail_provider.dart) instead of serving the hours-less station.
  @override
  Future<ServiceResult<StationDetail>> getStationDetail(
    String stationId,
  ) async {
    try {
      final response = await _dio.get(
        ApiConstants.detailEndpoint,
        // #753 — accept either `de-<uuid>` (new prefix) or a bare UUID
        // (legacy favorite from before the prefix scheme); the upstream
        // server only knows the bare UUID so we always strip.
        queryParameters: {'id': _stripCountryPrefix(stationId)},
      );
      _checkOk(response.data);

      final stationJson = response.data['station'] as Map<String, dynamic>;
      final parsed = Station.fromJson(stationJson);
      // Re-apply the `de-` prefix so the Station emitted from detail
      // matches the prefixed shape used everywhere else (search results,
      // favorites, widget rows). Without this, legacy favorites would
      // round-trip back to bare UUIDs and the next save would re-poison
      // the storage with two ids for the same station.
      final station = parsed.copyWith(id: _withCountryPrefix(parsed.id));

      // Parse opening times
      final openingTimesRaw = stationJson['openingTimes'];
      final openingTimes = <OpeningTime>[];
      if (openingTimesRaw is List) {
        for (final ot in openingTimesRaw) {
          openingTimes.add(
            OpeningTime.fromJson(Map<String, dynamic>.from(ot as Map)),
          );
        }
      }

      // Parse overrides
      final overridesRaw = stationJson['overrides'];
      final overrides = <String>[];
      if (overridesRaw is List) {
        for (final o in overridesRaw) {
          overrides.add(o.toString());
        }
      }

      // Epic #2707 C5 (#2712) — normalise the structured `openingTimes[]` +
      // `wholeDay` flag into the common [WeeklyOpeningHours] via the per-country
      // adapter. The legacy `openingTimes` / `wholeDay` fields stay populated
      // for back-compat; `openingHours` is the canonical structured signal and
      // is left null when the adapter found no usable data so the display layer
      // falls back through `legacyOpeningHoursBridge`.
      final weeklyHours =
          const GermanyOpeningHoursAdapter().parse(stationJson);

      return ServiceResult(
        data: StationDetail(
          station: station,
          openingTimes: openingTimes,
          overrides: overrides,
          wholeDay: stationJson['wholeDay'] as bool? ?? false,
          state: stationJson['state'] as String?,
          openingHours: weeklyHours.availability ==
                  OpeningHoursAvailability.notProvided
              ? null
              : weeklyHours,
        ),
        source: ServiceSource.tankerkoenigApi,
        fetchedAt: DateTime.now(),
      );
    } on DioException catch (e, st) {
      throwApiException(e, stackTrace: st);
    }
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) async {
    if (ids.isEmpty) {
      return ServiceResult(
        data: {},
        source: ServiceSource.tankerkoenigApi,
        fetchedAt: DateTime.now(),
      );
    }

    // The batch fetcher chunks `ids` into Tankerkoenig's per-call cap and
    // merges the responses, so callers (e.g. favorites refresh with >10
    // stations) get prices for *every* requested station instead of just
    // the first 10. The API key is added by the Dio interceptor in
    // service_providers.dart, so we don't pass it here.
    //
    // #753 — the fetcher transparently strips the `de-` prefix before
    // calling Tankerkönig and re-keys the response with the caller's
    // original id shape, so prefixed/bare ids round-trip cleanly.
    try {
      final raw = await _priceFetcher.fetchBatch(ids: ids);
      final prices = raw.map(
        (id, data) => MapEntry(id, StationPrices.fromJson(data)),
      );

      return ServiceResult(
        data: prices,
        source: ServiceSource.tankerkoenigApi,
        fetchedAt: DateTime.now(),
      );
    } on DioException catch (e, st) {
      throwApiException(e, stackTrace: st);
    }
  }

  /// `de-<id>` if [id] is unprefixed, otherwise [id] unchanged. Idempotent so
  /// detail re-parses don't double-prefix.
  static String _withCountryPrefix(String id) =>
      id.startsWith('de-') ? id : 'de-$id';

  /// Strip the `de-` prefix when passing an id back to Tankerkönig. Tolerant
  /// of legacy bare-UUID favorites (returns the id unchanged in that case).
  static String _stripCountryPrefix(String id) =>
      id.startsWith('de-') ? id.substring(3) : id;

  void _checkOk(dynamic data) {
    if (data is Map<String, dynamic> && data['ok'] != true) {
      throw ApiException(
        message: data['message']?.toString() ?? 'Unknown API error',
      );
    }
  }
}
