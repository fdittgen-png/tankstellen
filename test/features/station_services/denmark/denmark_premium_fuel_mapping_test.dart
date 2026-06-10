// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3187 — Denmark premium-fuel mapping, driven by RECORDED REAL feed slices
// (test/fixtures/dk_shell_prices_slice.json / dk_ok_prices_slice.json,
// captured 2026-06-10 from shellpumpepriser.geoapp.me / mobility-prices.ok.dk).
//
// The live Shell feed lists "V-Power Diesel" BEFORE "FuelSave Diesel" for
// ~76% of stations; the old `name.contains('diesel')` + `diesel ??=` matcher
// stamped the PREMIUM price as regular diesel. These tests drive the REAL
// [DenmarkStationService.searchStations] over the recorded payloads (the
// #2776 lesson: never assert against a parser copy or a synthetic fixture
// that echoes the parser's expectations).

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/station_services/denmark/denmark_station_service.dart';

const _okUrl = 'https://mobility-prices.ok.dk/api/v1/fuel-prices';
const _shellUrl = 'https://shellpumpepriser.geoapp.me/v1/prices';

/// Routes the OK and Shell feed URLs to their recorded bodies.
class _DkFeedAdapter implements HttpClientAdapter {
  _DkFeedAdapter({required this.okBody, required this.shellBody});
  final String okBody;
  final String shellBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final url = options.uri.toString();
    final body = url == _okUrl
        ? okBody
        : url == _shellUrl
            ? shellBody
            : null;
    if (body == null) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.unknown,
        error: 'no recorded route for $url',
      );
    }
    return ResponseBody.fromString(body, 200, headers: {
      'content-type': ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

Future<List<Station>> _search({
  required String okBody,
  required String shellBody,
}) async {
  final dio = Dio()
    ..httpClientAdapter = _DkFeedAdapter(okBody: okBody, shellBody: shellBody);
  final service = DenmarkStationService(dio: dio);
  // Centre between Copenhagen and Odense; wide radius covers the whole slice.
  final result = await service.searchStations(
    const SearchParams(lat: 55.4, lng: 11.5, radiusKm: 200),
  );
  return result.data;
}

void main() {
  late String shellFixture;
  late String okFixture;

  setUpAll(() {
    shellFixture =
        File('test/fixtures/dk_shell_prices_slice.json').readAsStringSync();
    okFixture =
        File('test/fixtures/dk_ok_prices_slice.json').readAsStringSync();
  });

  group('DK Shell feed premium-fuel mapping (#3187)', () {
    test(
        'V-Power Diesel listed BEFORE FuelSave Diesel does NOT overwrite '
        'regular diesel (the recorded real ordering)', () async {
      final stations =
          await _search(okBody: '{"items":[]}', shellBody: shellFixture);

      // D002 lists: V-Power Diesel 16.59, V-Power 18.29, FuelSave Diesel
      // 15.59, Blyfri 95 15.79 — the recorded real ordering.
      final s = stations.singleWhere((s) => s.id == 'shell-D002');
      expect(s.diesel, closeTo(15.59, 0.001),
          reason: 'regular diesel must be the FuelSave Diesel price, not the '
              'V-Power Diesel premium listed first in the feed');
      expect(s.dieselPremium, closeTo(16.59, 0.001),
          reason: 'V-Power Diesel must land in dieselPremium');
    });

    test('V-Power (octane 98 petrol) maps to e98, Blyfri 95 stays e5',
        () async {
      final stations =
          await _search(okBody: '{"items":[]}', shellBody: shellFixture);

      final s = stations.singleWhere((s) => s.id == 'shell-D002');
      expect(s.e98, closeTo(18.29, 0.001));
      expect(s.e5, closeTo(15.79, 0.001));
    });

    test('every recorded Shell station maps each grade exactly', () async {
      final stations =
          await _search(okBody: '{"items":[]}', shellBody: shellFixture);

      expect(stations, hasLength(6));
      for (final s in stations) {
        expect(s.diesel, closeTo(15.59, 0.001),
            reason: '${s.id}: FuelSave Diesel is 15.59 at every recorded '
                'station');
        expect(s.e5, closeTo(15.79, 0.001));
      }
      // D001 carries no V-Power Diesel in the recording.
      final d001 = stations.singleWhere((s) => s.id == 'shell-D001');
      expect(d001.dieselPremium, isNull);
    });

    test(
        'defensive default: a station with ONLY premium diesel leaves regular '
        'diesel null (never substitutes premium)', () async {
      // Recorded D002 payload with the FuelSave Diesel row removed — the
      // minimal mutation of the real recording that produces the
      // premium-only case.
      final rows = jsonDecode(shellFixture) as List<dynamic>;
      final d002 = rows
          .cast<Map<String, dynamic>>()
          .singleWhere((r) => r['stationId'] == 'D002');
      d002['prices'] = (d002['prices'] as List)
          .where((p) => p['productName'] != 'FuelSave Diesel')
          .toList();

      final stations = await _search(
          okBody: '{"items":[]}', shellBody: jsonEncode([d002]));

      final s = stations.singleWhere((s) => s.id == 'shell-D002');
      expect(s.diesel, isNull,
          reason: 'premium-only station must not report a regular diesel '
              'price');
      expect(s.dieselPremium, closeTo(16.59, 0.001));
    });
  });

  group('DK OK feed premium-fuel mapping (#3187)', () {
    test('Oktan 100 maps to e98; Blyfri 95 / Svovlfri Diesel stay regular',
        () async {
      final stations = await _search(okBody: okFixture, shellBody: '[]');

      expect(stations, hasLength(3));
      for (final s in stations) {
        expect(s.e5, closeTo(15.79, 0.001));
        expect(s.diesel, closeTo(15.59, 0.001));
        expect(s.e98, closeTo(17.99, 0.001),
            reason: '${s.id}: Oktan 100 is the 98+ octane grade');
      }
    });
  });
}
