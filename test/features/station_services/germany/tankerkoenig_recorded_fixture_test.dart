// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3197 — Germany (the reference implementation) pinned by RECORDED live
// Tankerkönig payloads.
//
// Fixtures, recorded 2026-06-11 with the public demo API key
// (`creativecommons.tankerkoenig.de`), structure untouched:
//  - `test/fixtures/de_tankerkoenig_list_slice.json` —
//    `list.php?lat=52.52&lng=13.405&rad=3&type=all&sort=dist` (Berlin,
//    10 stations as served).
//  - `test/fixtures/de_tankerkoenig_detail_openingtimes.json` —
//    `detail.php?id=946c589c-…` (Esso Würzburg: a station with a non-empty
//    `openingTimes[]` and `wholeDay:false`).
//
// NOTE on prices: the demo key serves the REAL field layout but pins every
// price to 1.009 — these tests therefore pin the field/shape contract
// (id/brand/postCode-int/isOpen/openingTimes), not price plausibility.
//
// They drive the REAL [TankerkoenigStationService] (the #2776 /
// feedback_fake_services_false_green lesson: hand-built MockDio maps can
// never catch a field the real feed doesn't send — e.g. `houseNumber`,
// which the real list.php sends and the old synthetic stub omitted).

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/constants/api_constants.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/features/station_services/germany/tankerkoenig_station_service.dart';

/// Routes `list.php` / `detail.php` to their recorded bodies.
class _TankerkoenigRouteAdapter implements HttpClientAdapter {
  _TankerkoenigRouteAdapter({required this.listBody, required this.detailBody});
  final String listBody;
  final String detailBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;
    final body = path.endsWith('/list.php')
        ? listBody
        : path.endsWith('/detail.php')
            ? detailBody
            : null;
    if (body == null) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.unknown,
        error: 'no recorded route for $path',
      );
    }
    return ResponseBody.fromString(body, 200, headers: {
      'content-type': ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late TankerkoenigStationService service;

  setUpAll(() {
    final listBody =
        File('test/fixtures/de_tankerkoenig_list_slice.json')
            .readAsStringSync();
    final detailBody =
        File('test/fixtures/de_tankerkoenig_detail_openingtimes.json')
            .readAsStringSync();
    final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl))
      ..httpClientAdapter = _TankerkoenigRouteAdapter(
        listBody: listBody,
        detailBody: detailBody,
      );
    service = TankerkoenigStationService(dio);
  });

  group('recorded list.php Berlin slice through the REAL service (#3197)',
      () {
    test('all 10 recorded stations parse with the de- id prefix', () async {
      final result = await service.searchStations(
        const SearchParams(lat: 52.52, lng: 13.405, radiusKm: 3),
      );
      expect(result.data, hasLength(10));
      expect(result.data.map((s) => s.id), everyElement(startsWith('de-')));
    });

    test('real field layout maps onto Station (incl. int postCode)',
        () async {
      final result = await service.searchStations(
        const SearchParams(lat: 52.52, lng: 13.405, radiusKm: 3),
      );
      final aral = result.data
          .firstWhere((s) => s.id == 'de-278130b1-e062-4a0f-80cc-19e486b4c024');
      expect(aral.name, 'Aral Tankstelle');
      expect(aral.brand, 'ARAL');
      expect(aral.street, 'Holzmarktstraße');
      // The real feed sends postCode as an INT (10179) — the codec must
      // string-ify it, not drop it.
      expect(aral.postCode, '10179');
      expect(aral.place, 'Berlin');
      expect(aral.lat, closeTo(52.514153, 1e-6));
      expect(aral.lng, closeTo(13.421487, 1e-6));
      expect(aral.isOpen, isTrue);
      // Demo-key price pin (see header note): values are demo-fixed but the
      // three slots must land in the right fields.
      expect(aral.e5, 1.009);
      expect(aral.e10, 1.009);
      expect(aral.diesel, 1.009);
    });
  });

  group('recorded detail.php payload through the REAL service (#3197)', () {
    test('openingTimes[] + wholeDay:false parse into structured hours',
        () async {
      final result = await service
          .getStationDetail('de-946c589c-b13d-4f83-bb5c-f12269ea34ef');
      final detail = result.data;
      // The recorded Esso Würzburg payload carries three real ranges:
      // Mo-Fr 06:30–00:00, Samstag 07:00–00:00, Sonntag/Feiertag 08:00–00:00.
      expect(detail.openingTimes, hasLength(3));
      expect(detail.openingTimes.first.text, 'Mo-Fr');
      expect(detail.wholeDay, isFalse);
      expect(detail.openingHours, isNotNull,
          reason: 'the structured weekly schedule is the canonical signal '
              '(#2712) and must survive the real detail.php shape');
      // The detail Station keeps the de- prefix and the int postCode.
      expect(detail.station.id, 'de-946c589c-b13d-4f83-bb5c-f12269ea34ef');
      expect(detail.station.postCode, '97072');
    });
  });
}
