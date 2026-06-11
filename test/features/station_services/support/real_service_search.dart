// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #2780 (Epic #2776 D4) — ONE shared test helper that drives the REAL country
// `searchStations` pipeline through an injected Dio, replacing the per-file
// divergent `_TestableMitecoParser` / `_TestableEControlParser` copies.
//
// Why this exists: those copies re-implemented the production parse but quietly
// diverged from it — they never set the structured `Station.openingHours`, nor
// the `es-`/`at-` id prefix. So every assertion they powered was false-green:
// it proved the *copy* worked, not the production code a real tap exercises
// (the #2776 lesson — drive the REAL search→codec path, not an adapter unit
// that echoes the request). Routing every parsing test through the real
// service + a fixed Dio means a JsonKey-drop / prefix / OH-adapter regression
// is actually caught.

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/station_services/austria/econtrol_station_service.dart';
import 'package:tankstellen/features/station_services/spain/miteco_station_service.dart';

/// A [HttpClientAdapter] that returns one fixed JSON [body] for every request,
/// regardless of path or query, with no live network call. The body is the raw
/// upstream payload shape (NOT a parsed Station), so the REAL service parse runs
/// over it.
class FixedJsonAdapter implements HttpClientAdapter {
  final String body;
  FixedJsonAdapter(this.body);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromString(body, 200, headers: {
        'content-type': ['application/json'],
      });

  @override
  void close({bool force = false}) {}
}

/// A [HttpClientAdapter] that picks a response body from [bodyFor] using the
/// request's `fuelType` query parameter — used for E-Control, which queries the
/// same endpoint twice (DIE, then SUP) and merges by station id.
class FuelTypeAdapter implements HttpClientAdapter {
  final String Function(String fuelType) bodyFor;
  FuelTypeAdapter(this.bodyFor);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final fuelType = options.uri.queryParameters['fuelType'] ?? '';
    return ResponseBody.fromString(bodyFor(fuelType), 200, headers: {
      'content-type': ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

/// Wrap a list of MITECO `ListaEESSPrecio` raw rows in the upstream
/// `FiltroProvincia` envelope the real [MitecoStationService] expects.
String mitecoEnvelope(List<Map<String, dynamic>> records) => jsonEncode({
      'ResultadoConsulta': 'OK',
      'ListaEESSPrecio': records,
    });

/// Drive the REAL [MitecoStationService.searchStations] over [records] (raw
/// `ListaEESSPrecio` rows) through a fixed Dio. The `cache` is omitted, so there
/// is no Hive read-through — the service hits the injected adapter directly.
///
/// [lat]/[lng] are the search centre; pick coordinates inside Spain so the
/// per-province request actually fires (the adapter answers every province).
/// [now] is the #3189 clock seam for the schedule-derived `isOpen`; defaults
/// to the wall clock (pass a fixed instant when asserting on `isOpen`).
Future<List<Station>> searchMitecoStations(
  List<Map<String, dynamic>> records, {
  double lat = 40.42,
  double lng = -3.70,
  double radiusKm = 50.0,
  DateTime Function()? now,
}) async {
  final dio = Dio()..httpClientAdapter = FixedJsonAdapter(mitecoEnvelope(records));
  final service = MitecoStationService(dio: dio, now: now);
  final result = await service.searchStations(
    SearchParams(lat: lat, lng: lng, radiusKm: radiusKm),
  );
  return result.data;
}

/// Drive the REAL [EControlStationService.searchStations] through a fixed Dio.
/// E-Control queries DIE then SUP; [dieselRecords] answers the DIE query and
/// [superRecords] the SUP query (defaults to [dieselRecords] when omitted, so a
/// single station list carries both prices like a typical OMV).
/// Drive the REAL [EControlStationService.searchStations] over two RAW
/// recorded response bodies (#3197) — [dieselBody] answers the DIE query and
/// [superBody] the SUP query, byte-for-byte as the live API sent them.
Future<List<Station>> searchEcontrolRecordedStations({
  required String dieselBody,
  required String superBody,
  double lat = 48.2,
  double lng = 16.37,
  double radiusKm = 10.0,
}) async {
  final dio = Dio()
    ..httpClientAdapter = FuelTypeAdapter(
      (fuelType) => fuelType == 'SUP' ? superBody : dieselBody,
    );
  final service = EControlStationService(dio: dio);
  final result = await service.searchStations(
    SearchParams(lat: lat, lng: lng, radiusKm: radiusKm),
  );
  return result.data;
}

Future<List<Station>> searchEcontrolStations(
  List<Map<String, dynamic>> dieselRecords, {
  List<Map<String, dynamic>>? superRecords,
  double lat = 48.2,
  double lng = 16.37,
  double radiusKm = 10.0,
}) async {
  final dieselBody = jsonEncode(dieselRecords);
  final superBody = jsonEncode(superRecords ?? dieselRecords);
  final dio = Dio()
    ..httpClientAdapter = FuelTypeAdapter(
      (fuelType) => fuelType == 'SUP' ? superBody : dieselBody,
    );
  final service = EControlStationService(dio: dio);
  final result = await service.searchStations(
    SearchParams(lat: lat, lng: lng, radiusKm: radiusKm),
  );
  return result.data;
}
