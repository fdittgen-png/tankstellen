// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4180 — the per-country `search<Country>Stations` helpers that drive each
// REAL station service over the recorded responses already checked in under
// `test/fixtures/`, so `runStationServiceContract` (#4157) can run against
// real data. The AT / ES helpers live next door in `real_service_search.dart`.
//
// Every helper constructs the production service class (the same one the
// country's `buildService` factory returns on the keyed / keyless path the
// recording exercises) and answers its HTTP calls from recorded bytes only.
// A request with no recorded route FAILS loudly rather than being answered
// with an invented body — a hand-written stand-in is exactly the
// `feedback_fake_services_false_green` trap the contract exists to avoid.
// The one hand-written body is RO's labelled no-rows envelope (see
// [monitorulNoRowsEnvelope]), which carries no station and no price.

import 'package:dio/dio.dart';
import 'package:tankstellen/core/constants/api_constants.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/station_services/denmark/denmark_station_service.dart';
import 'package:tankstellen/features/station_services/france/prix_carburants_station_service.dart';
import 'package:tankstellen/features/station_services/germany/tankerkoenig_station_service.dart';
import 'package:tankstellen/features/station_services/greece/greece_station_service.dart';
import 'package:tankstellen/features/station_services/italy/mise_station_service.dart';
import 'package:tankstellen/features/station_services/luxembourg/luxembourg_station_service.dart';
import 'package:tankstellen/features/station_services/mexico/mexico_station_service.dart';
import 'package:tankstellen/features/station_services/portugal/portugal_station_service.dart';
import 'package:tankstellen/features/station_services/romania/romania_station_service.dart';
import 'package:tankstellen/features/station_services/slovenia/slovenia_station_service.dart';
import 'package:tankstellen/features/station_services/uk/uk_station_service.dart';

/// Answers each request with the recorded body [bodyFor] picks for it, and
/// throws for any request it has no recording for.
class RecordedRouteAdapter implements HttpClientAdapter {
  RecordedRouteAdapter(this.bodyFor, {this.contentType = 'application/json'});

  final String? Function(RequestOptions options) bodyFor;
  final String contentType;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = bodyFor(options);
    if (body == null) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.unknown,
        error: 'no recorded route for ${options.uri}',
      );
    }
    return ResponseBody.fromString(body, 200, headers: {
      Headers.contentTypeHeader: [contentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

Future<List<Station>> _search(
  StationService service,
  SearchParams params,
) async =>
    (await service.searchStations(params)).data;

/// FR — the per-search Prix-Carburants service (`frFluxBulk` is off, so this
/// is what `buildFrStationService` returns). No OSM enricher: brand
/// enrichment is a network side-channel, not part of the recorded feed.
Future<List<Station>> searchFranceStations(
  String geoBody, {
  required SearchParams params,
}) {
  final dio = Dio(BaseOptions(baseUrl: ''))
    ..httpClientAdapter = RecordedRouteAdapter((o) =>
        o.uri.queryParameters['where']?.contains('within_distance') == true
            ? geoBody
            : null);
  return _search(PrixCarburantsStationService(dio: dio), params);
}

/// DE — Tankerkönig `list.php` (the demo-key recording; see its fixture test).
Future<List<Station>> searchGermanyStations(
  String listBody, {
  required SearchParams params,
}) {
  final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl))
    ..httpClientAdapter = RecordedRouteAdapter(
        (o) => o.uri.path.endsWith('/list.php') ? listBody : null);
  return _search(TankerkoenigStationService(dio), params);
}

/// PT — DGEG `PesquisarPostos` (one call for the whole fuel-id set).
Future<List<Station>> searchPortugalStations(
  String postosBody, {
  required SearchParams params,
}) {
  final dio = Dio()
    ..httpClientAdapter = RecordedRouteAdapter(
        (o) => o.uri.path.endsWith('/PesquisarPostos') ? postosBody : null);
  return _search(PortugalStationService(dio: dio), params);
}

/// IT — the MIMIT registry + price CSVs, no dataset cache.
Future<List<Station>> searchItalyStations({
  required String anagraficaCsv,
  required String prezzoCsv,
  required SearchParams params,
}) {
  final dio = Dio(BaseOptions(responseType: ResponseType.plain))
    ..httpClientAdapter = RecordedRouteAdapter(
      (o) => o.uri.path.contains('anagrafica')
          ? anagraficaCsv
          : o.uri.path.contains('prezzo')
              ? prezzoCsv
              : null,
      contentType: 'text/csv',
    );
  return _search(MiseStationService(dio: dio), params);
}

/// The observatory's answer for a catalog product with no rows in the
/// search buffer: an envelope with empty arrays.
///
/// **HAND-WRITTEN, NOT RECORDED.** It mirrors the empty body the existing
/// `romania_station_service_test.dart` documents for the same case. It
/// exists only because [RomaniaStationService] fails the whole search when
/// any of its five product calls fails, and only products 11 and 21 were
/// recorded. It adds no station and no price, so nothing the contract
/// inspects comes from it.
const String monitorulNoRowsEnvelope = '{"Stations":[],"Products":[]}';

/// RO — Monitorul Prețurilor, one call per catalog product id.
///
/// [recordedBodyByProductId] maps a `CSVGasCatalogProductIds` value to its
/// recorded body. Every id in [emptyProductIds] is answered with the
/// hand-written [monitorulNoRowsEnvelope]; any other product fails the
/// search.
Future<List<Station>> searchRomaniaStations({
  required Map<String, String> recordedBodyByProductId,
  Set<String> emptyProductIds = const {},
  required SearchParams params,
}) {
  final dio = Dio()
    ..httpClientAdapter = RecordedRouteAdapter((o) {
      final id = o.uri.queryParameters['CSVGasCatalogProductIds'];
      if (emptyProductIds.contains(id)) return monitorulNoRowsEnvelope;
      return recordedBodyByProductId[id];
    });
  return _search(RomaniaStationService(dio: dio), params);
}

/// GR — the self-published primary asset (the production default path);
/// no mirror recording is served, so a stale-asset fall-through fails.
Future<List<Station>> searchGreeceStations(
  String selfPublishedBody, {
  required SearchParams params,
  required DateTime now,
}) {
  final dio = Dio()
    ..httpClientAdapter = RecordedRouteAdapter((o) =>
        o.uri.path.endsWith('latest.json') ? selfPublishedBody : null);
  return _search(
    GreeceStationService(
      dio: dio,
      selfPublishedUrl: 'https://releases.example/fuel-gr/latest.json',
      now: () => now,
    ),
    params,
  );
}

/// DK — the OK and Shell brand feeds (Q8 makes no request), no disk cache.
Future<List<Station>> searchDenmarkStations({
  required String okBody,
  required String shellBody,
  required SearchParams params,
}) {
  final dio = Dio()
    ..httpClientAdapter = RecordedRouteAdapter((o) => switch (o.uri.host) {
          'mobility-prices.ok.dk' => okBody,
          'shellpumpepriser.geoapp.me' => shellBody,
          _ => null,
        });
  return _search(DenmarkStationService(dio: dio), params);
}

/// GB — the keyless production path (`UkStationService`, the CMA retailer
/// fan-out), restricted to the one retailer feed that was recorded.
Future<List<Station>> searchUkStations(
  String feedBody, {
  required String feedUrl,
  required SearchParams params,
}) {
  final dio = Dio()
    ..httpClientAdapter = RecordedRouteAdapter(
        (o) => o.uri.toString() == feedUrl ? feedBody : null);
  return _search(
    UkStationService(dio: dio, feedUrls: [feedUrl]),
    params,
  );
}

/// LU — the two LUSTAT decree dataflows.
Future<List<Station>> searchLuxembourgStations({
  required String essenceBody,
  required String dieselBody,
  required SearchParams params,
}) {
  final dio = Dio()
    ..httpClientAdapter = RecordedRouteAdapter((o) {
      // `options.path` is the unencoded string the service built — the
      // dataflow ids carry `,` and `@`, which `uri` percent-encodes.
      if (o.path.contains(LuxembourgStationService.essenceFlow)) {
        return essenceBody;
      }
      if (o.path.contains(LuxembourgStationService.dieselFlow)) {
        return dieselBody;
      }
      return null;
    });
  return _search(LuxembourgStationService(dio: dio), params);
}

/// MX — the CRE `/places` and `/prices` XML feeds, no disk cache.
Future<List<Station>> searchMexicoStations({
  required String placesXml,
  required String pricesXml,
  required SearchParams params,
}) {
  final dio = Dio()
    ..httpClientAdapter = RecordedRouteAdapter(
      (o) => o.uri.path.endsWith('/places')
          ? placesXml
          : o.uri.path.endsWith('/prices')
              ? pricesXml
              : null,
      contentType: 'application/xml; charset=utf-8',
    );
  return _search(MexicoStationService(dio: dio), params);
}

/// SI — the goriva.si search endpoint.
Future<List<Station>> searchSloveniaStations(
  String searchBody, {
  required SearchParams params,
}) {
  final dio = Dio()
    ..httpClientAdapter = RecordedRouteAdapter(
        (o) => o.uri.host == 'goriva.si' ? searchBody : null);
  return _search(SloveniaStationService(dio: dio), params);
}
