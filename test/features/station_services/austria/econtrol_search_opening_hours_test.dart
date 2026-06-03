// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #2780 (Epic #2776 D4) — Austria is a polled-API source with NO detail
// endpoint, so the search-result Station is the ONLY carrier of opening hours.
// This drives the REAL EControlStationService.searchStations through an
// injected Dio (not the divergent _TestableEControlParser copy) and asserts the
// production parse populates the structured Station.openingHours AND that it
// survives the search-list codec round-trip — the cache-hit path that rendered
// empty hours before #2777.
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/station_service_chain_codec.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/station_detail/domain/opening_hours.dart';
import 'package:tankstellen/features/station_services/austria/econtrol_station_service.dart';

/// Returns a fixed E-Control `by-address` payload (a JSON list of station
/// records) for every request, so the production search pipeline runs without
/// a live network call.
class _FixedAdapter implements HttpClientAdapter {
  final String body;
  _FixedAdapter(this.body);

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

void main() {
  test('AT searchStations populates structured hours + survives the codec (#2780)',
      () async {
    // One station with a full structured weekly schedule (06:30-20:30 Mon-Sat,
    // closed Sunday) — the real E-Control `openingHours[]` shape.
    final body = jsonEncode([
      <String, dynamic>{
        'id': '123',
        'name': 'OMV Wien Ring',
        'open': true,
        'location': <String, dynamic>{
          'latitude': 48.2,
          'longitude': 16.37,
          'address': 'Ringstraße 1',
          'postalCode': '1010',
          'city': 'Wien',
        },
        'prices': [
          <String, dynamic>{'amount': 1.59}
        ],
        'openingHours': [
          for (final d in const [
            ['MO', 'Montag'],
            ['DI', 'Dienstag'],
            ['MI', 'Mittwoch'],
            ['DO', 'Donnerstag'],
            ['FR', 'Freitag'],
            ['SA', 'Samstag'],
          ])
            <String, dynamic>{
              'day': d[0],
              'label': d[1],
              'from': '06:30',
              'to': '20:30',
            },
        ],
      }
    ]);

    final dio = Dio()..httpClientAdapter = _FixedAdapter(body);
    final service = EControlStationService(dio: dio);

    final result = await service.searchStations(
      const SearchParams(lat: 48.2, lng: 16.37, radiusKm: 10.0),
    );

    final s = result.data.firstWhere((st) => st.id == 'at-123');
    expect(s.openingHours, isNotNull,
        reason: 'the REAL AT search parse must populate structured hours — '
            'AT has no detail endpoint, so the search Station is the only carrier');

    final restored =
        deserializeStationList(serializeStationList([s]))!.single;
    expect(restored.openingHours, isNotNull,
        reason: 'structured hours must survive the cache round-trip (#2777)');
    expect(restored.openingHours!.availability,
        isNot(OpeningHoursAvailability.notProvided));
    expect(restored.openingHours!.dayFor(OpeningDay.mon)?.state,
        DayState.openRanges);
  });
}
