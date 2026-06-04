// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #2780 (Epic #2776 D4) — Austria is a polled-API source with NO detail
// endpoint, so the search-result Station is the ONLY carrier of opening hours.
// This drives the REAL EControlStationService.searchStations through the shared
// real-service helper (not a divergent _TestableEControlParser copy) and asserts
// the production parse populates the structured Station.openingHours AND that it
// survives the search-list codec round-trip — the cache-hit path that rendered
// empty hours before #2777.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/station_service_chain_codec.dart';
import 'package:tankstellen/features/station_detail/domain/opening_hours.dart';

import '../support/real_service_search.dart';

void main() {
  test('AT searchStations populates structured hours + survives the codec (#2780)',
      () async {
    // One station with a full structured weekly schedule (06:30-20:30 Mon-Sat,
    // closed Sunday) — the real E-Control `openingHours[]` shape.
    final result = await searchEcontrolStations([
      {
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

    final s = result.firstWhere((st) => st.id == 'at-123');
    expect(s.openingHours, isNotNull,
        reason: 'the REAL AT search parse must populate structured hours — '
            'AT has no detail endpoint, so the search Station is the only carrier');

    final restored = deserializeStationList(serializeStationList([s]))!.single;
    expect(restored.openingHours, isNotNull,
        reason: 'structured hours must survive the cache round-trip (#2777)');
    expect(restored.openingHours!.availability,
        isNot(OpeningHoursAvailability.notProvided));
    expect(restored.openingHours!.dayFor(OpeningDay.mon)?.state,
        DayState.openRanges);
  });
}
