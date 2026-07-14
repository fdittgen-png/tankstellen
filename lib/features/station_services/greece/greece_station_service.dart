// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/domain/search_params.dart';
import '../../../core/domain/fuel_type.dart';
import '../../../core/domain/station.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/services/dio_factory.dart';
import '../../../core/services/mixins/station_service_helpers.dart';
import '../../../core/services/service_result.dart';
import '../../../core/services/station_service.dart';
import 'greece_prefectures.dart';
import '../../../core/logging/error_logger.dart';

/// Greece fuel prices — Paratiritirio Timon (Fuel Price Observatory) via the
/// community [fuelpricesgr](https://github.com/mavroprovato/fuelpricesgr)
/// FastAPI wrapper (#576).
///
/// Greece's government-run *Paratiritirio Timon Υγρών Καυσίμων* publishes
/// mandatory daily / weekly fuel price data, but only as brittle PDFs on
/// `catalog.data.gov.gr`. The community wrapper parses those PDFs into a
/// well-formed JSON API with no authentication.
///
/// **Crucial caveat**: unlike CNE (Chile) or OPINET (Korea), the Greek
/// feed is **not station-level** — the finest granularity published by
/// the Observatory (and therefore by the community API) is the
/// *prefecture* (νομός). Greek law requires each station to print its
/// prices on public-facing boards but there is no central per-station
/// registry open to the public.
///
/// We model this the same way [LuxembourgStationService] models its
/// uniform regulated prices: one synthetic "virtual station" per
/// representative prefecture, stamped with that prefecture's latest
/// daily mean price. The user sees a short list of `gr-attica`,
/// `gr-thessaloniki`, ... entries around the Greek mainland / islands,
/// each showing the prefecture-level average. For a pay-less-at-the-pump
/// decision this is not as sharp as a station-level feed, but it at
/// least surfaces regional variance (Attica vs. Thrace vs. Crete, which
/// can differ by 10–15 cents/L) and keeps the app usable in Greece
/// until — or unless — a station-level feed becomes available.
///
/// **Endpoint contract** (#3539 — restored on the community
/// [FuelPricesGreeceAPI](https://github.com/emvouvakis/FuelPricesGreeceAPI)
/// mirror after `fuelpricesgr.com` went NXDOMAIN, #3194; that project
/// scrapes the SAME official ministry bulletins daily):
///
/// ```
/// GET {base}/data?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD&offset=0
/// x-api-key: <public key from the project README>
/// ```
///
/// returns ONE flat list with one row per prefecture per day — a single
/// request covers the whole country (no per-prefecture fan-out):
///
/// ```json
/// [
///   { "DATE": "2026-07-09", "REGION": "N. ATHINON",
///     "UNLEADED_95_Octane": 1.943, "UNLEADED_100_OCTANE": 2.16,
///     "AUTOMOTIVE_DIESEL": 1.787, "AUTOGAS": 0.907,
///     "HOME_HEATING_DIESEL": null, "Super": null },
///   …
/// ]
/// ```
///
/// Fuel-column mapping lives on [GreeceObservatoryKeys] in
/// `greece_prefectures.dart`:
///
/// ```
/// UNLEADED_95_Octane   → FuelType.e5
/// UNLEADED_100_OCTANE  → FuelType.e98
/// AUTOMOTIVE_DIESEL    → FuelType.diesel
/// HOME_HEATING_DIESEL  → (skipped — not a motoring fuel)
/// AUTOGAS              → FuelType.lpg    (Υγραέριο)
/// Super                → (skipped — leaded; phased out)
/// ```
///
/// The API key is the PUBLIC one the project publishes in its README —
/// free, shared, rate-limited; not a paid credential and not a secret.
/// The service still round-trips `_baseUrl` / `_apiKey` so operators can
/// point Tankstellen at a self-hosted deployment (of either upstream) if
/// the hosted endpoint dies again; the parser is fully fixture-driven so
/// a shape drift at upstream is a one-line fix.
///
/// **Durable primary (#3549)**: since the mirror is hobbyist-run (the
/// exact single-maintainer failure mode that killed fuelpricesgr.com),
/// the PRIMARY source is now the project's own SELF-PUBLISHED JSON —
/// `gr-fuel-publish.yml` parses the official ministry PDF bulletins
/// business-daily (vendored `tool/gr_fuel/` MIT parser) into rows shaped
/// EXACTLY like the mirror's `/v2/data` response, uploaded to the rolling
/// `fuel-gr` release. Both sources therefore share one codec; the mirror
/// stays as the automatic fallback whenever the self-published asset is
/// unreachable, unparseable, or stale (no row within [lookback]).
class GreeceStationService
    with StationServiceHelpers
    implements StationService {
  /// Self-published rows (#3549) — a release asset fully under the
  /// project's control, updated daily from the official ministry PDFs.
  /// (A release asset, not GitHub Pages, so the pages.yml full-replace
  /// deploy — the #3072 trap — can never wipe it.)
  static const String defaultSelfPublishedUrl =
      'https://github.com/fdittgen-png/tankstellen/releases/download/'
      'fuel-gr/latest.json';

  /// Community mirror base URL (#3539, live-verified 2026-07-11 with
  /// data through 2026-07-09 — matching the latest official bulletin).
  /// The old `fuelpricesgr.com` default has been NXDOMAIN since
  /// 2026-06-10 (#3194) with no public replacement instance.
  static const String defaultBaseUrl =
      'https://5fcbs3i0z4.execute-api.eu-west-3.amazonaws.com/v2';

  /// The PUBLIC shared API key from the FuelPricesGreeceAPI README —
  /// published by the project for anyone's use (free tier, rate-limited).
  /// Deliberately NOT a repo secret: it is upstream's own public
  /// credential, exactly like an unauthenticated endpoint with extra
  /// steps. Overridable for self-hosted deployments.
  static const String defaultApiKey =
      'VH5AaWqgBchJw3a8yOkq5i5nVJ0hNMl5mwzkPMm1';

  /// How far back the single ranged query looks. The ministry publishes
  /// business-daily and can lag a day or two around holidays — a week
  /// guarantees at least one row per prefecture without over-fetching
  /// (51 prefectures × 7 days ≈ 360 rows, well under the API's
  /// 10 000-row default limit).
  static const Duration lookback = Duration(days: 7);

  final Dio _dio;
  final String _selfPublishedUrl;
  final String _baseUrl;
  final String _apiKey;

  /// Test seam for the ranged query's end date — defaults to wall clock.
  final DateTime Function() _now;

  GreeceStationService({
    Dio? dio,
    String? selfPublishedUrl,
    String? baseUrl,
    String? apiKey,
    DateTime Function()? now,
  })  : _dio = dio ??
            DioFactory.create(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
            ),
        _selfPublishedUrl = selfPublishedUrl ?? defaultSelfPublishedUrl,
        _baseUrl = baseUrl ?? defaultBaseUrl,
        _apiKey = apiKey ?? defaultApiKey,
        _now = now ?? DateTime.now;

  /// Public delegator: case-insensitive lookup for the Observatory
  /// `fuel_type` enum. Kept on the class so existing tests keep
  /// working without rewrites.
  @visibleForTesting
  static FuelType? fuelForObservatoryKey(String key) =>
      GreeceObservatoryKeys.lookup(key);

  /// Public delegator: keys the parser intentionally drops.
  static Set<String> get droppedObservatoryKeys =>
      GreeceObservatoryKeys.droppedObservatoryKeys;

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    // The user's nearest prefectures — the single ranged query below
    // returns the whole country, but only the closest few surface as
    // synthetic pins (same anti-clutter policy as before #3539).
    final candidates = prefecturesForQuery(params, kGreekPrefectures);

    final end = _now();
    final start = end.subtract(GreeceStationService.lookback);
    String d(DateTime t) => '${t.year.toString().padLeft(4, '0')}-'
        '${t.month.toString().padLeft(2, '0')}-'
        '${t.day.toString().padLeft(2, '0')}';

    // #3549 — PRIMARY: the self-published rows (our own release asset,
    // parsed from the official ministry PDFs). Falls through to the
    // community mirror on ANY miss — unreachable, unparseable, or stale
    // (no row within the lookback window). Both share one row shape, so
    // the per-prefecture parse below is source-agnostic.
    List<dynamic>? rows =
        await _fetchSelfPublished(freshCutoff: d(start), cancelToken: cancelToken);

    if (rows == null) {
      try {
        final response = await _dio.get<dynamic>(
          '$_baseUrl/data',
          queryParameters: {
            'start_date': d(start),
            'end_date': d(end),
            'offset': 0,
          },
          options: Options(headers: {'x-api-key': _apiKey}),
          cancelToken: cancelToken,
        );
        final data = response.data;
        if (data is! List) {
          throw const ApiException(
            message: 'Paratiritirio mirror returned unparseable body',
          );
        }
        rows = data;
      } on DioException catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.other, e, st,
            context: const {'where': 'GR ranged fetch failed (#3539)'}));
        final status = e.response?.statusCode;
        // 401/403 = the shared public key was revoked / a self-hosted
        // deployment is behind different auth — a hard, actionable error.
        throw ApiException(
          message: status == 401 || status == 403
              ? 'Paratiritirio mirror rejected request (HTTP $status) — '
                  'API key revoked?'
              : 'Paratiritirio mirror unreachable: ${e.type.name}',
          statusCode: status,
        );
      }
    }

    final stations = <Station>[];
    final errors = <ServiceError>[];
    for (final pref in candidates) {
      try {
        final s = parsePrefectureResponse(
          rows,
          regionKey: pref.apiName,
          stationId: pref.id,
          displayName: pref.displayName,
          place: pref.place,
          prefectureLat: pref.lat,
          prefectureLng: pref.lng,
          fromLat: params.lat,
          fromLng: params.lng,
        );
        if (s != null) stations.add(s);
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.other, e, st, context: {
          'where': 'GR parse failed for ${pref.apiName} (#3539)',
        }));
        errors.add(ServiceError(
          source: ServiceSource.greeceApi,
          message: 'parse ${pref.apiName}: $e',
          occurredAt: DateTime.now(),
        ));
      }
    }

    final filtered = filterByRadius(stations, params.radiusKm);
    sortStations(filtered, params);

    return ServiceResult(
      data: filtered,
      source: ServiceSource.greeceApi,
      fetchedAt: DateTime.now(),
      errors: errors,
    );
  }

  /// #3549 — fetch the self-published rows. Returns null (never throws)
  /// on ANY miss so the caller falls back to the mirror: network error,
  /// non-list body, or staleness — no row's `DATE` at/after
  /// [freshCutoff] (ISO date, lexicographic compare), which covers a
  /// silently broken publish pipeline leaving an old asset behind.
  Future<List<dynamic>?> _fetchSelfPublished({
    required String freshCutoff,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        _selfPublishedUrl,
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data is! List || data.isEmpty) return null;
      final fresh = data.any((row) =>
          row is Map &&
          (row['DATE']?.toString() ?? '').compareTo(freshCutoff) >= 0);
      if (!fresh) {
        unawaited(errorLogger.log(
          ErrorLayer.other,
          const ApiException(message: 'GR self-published rows stale (#3549)'),
          StackTrace.current,
          context: const {'where': 'GR self-published freshness gate'},
        ));
        return null;
      }
      return data;
    } on DioException catch (e, st) {
      // Expected fallback path (asset not yet published, GitHub hiccup):
      // log at breadcrumb-weight via debugPrint, not an ERROR trace — the
      // mirror fallback keeps the feature working.
      debugPrint('GR self-published fetch missed (#3549): ${e.type.name}\n$st');
      return null;
    }
  }

  /// Parse the mirror's flat country-wide row list into ONE
  /// prefecture's synthetic [Station] (#3539). Exposed for tests so the
  /// parser is driven by recorded fixtures independent of any Dio mock.
  ///
  /// [data] is the whole `/data` response (one row per prefecture per
  /// day); rows whose `REGION` differs from [regionKey] are skipped,
  /// and the newest `DATE` among the matches wins. Null when the
  /// prefecture has no row in the ranged window or no recognised fuel
  /// column carries a positive price.
  ///
  /// The prefecture is addressed by its stable `stationId` so tests do
  /// not need access to the [GreekPrefecture] type.
  @visibleForTesting
  Station? parsePrefectureResponse(
    dynamic data, {
    required String regionKey,
    required String stationId,
    required String displayName,
    required String place,
    required double prefectureLat,
    required double prefectureLng,
    required double fromLat,
    required double fromLng,
  }) {
    if (data is! List) {
      throw const ApiException(
        message: 'Paratiritirio mirror returned unparseable body',
      );
    }

    // Empty list is valid — just means no recent data. Drop the station
    // (a synthetic entry with no prices would clutter the list).
    if (data.isEmpty) return null;

    // Newest row for THIS prefecture. Rows arrive one-per-day over the
    // ranged window; pick the greatest `DATE` string (ISO-8601
    // lexicographic order works) among matching `REGION`s.
    Map<dynamic, dynamic>? newest;
    String newestDate = '';
    for (final item in data) {
      if (item is! Map) continue;
      if (item['REGION']?.toString() != regionKey) continue;
      final date = item['DATE']?.toString() ?? '';
      if (date.compareTo(newestDate) > 0) {
        newestDate = date;
        newest = item;
      }
    }
    if (newest == null) return null;

    final prices = GreeceObservatoryKeys.parsePrices(newest);
    // A prefecture with zero recognised fuel rows is dropped — no
    // synthetic pin for "nothing to show".
    if (prices.isEmpty) return null;

    return Station(
      id: stationId,
      name: displayName,
      brand: 'Paratiritirio',
      street: '',
      postCode: '',
      place: place,
      lat: prefectureLat,
      lng: prefectureLng,
      dist: roundedDistance(fromLat, fromLng, prefectureLat, prefectureLng),
      e5: prices[FuelType.e5],
      e98: prices[FuelType.e98],
      diesel: prices[FuelType.diesel],
      lpg: prices[FuelType.lpg],
      // #3198 — prefecture-level virtual stations have no open/closed
      // notion at all: honest unknown.
      isOpen: null,
      updatedAt: newestDate.isEmpty ? null : newestDate,
    );
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(
    String stationId,
  ) async {
    throwDetailUnavailable('Paratiritirio Timon');
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) async {
    return emptyPricesResult(ServiceSource.greeceApi);
  }
}
