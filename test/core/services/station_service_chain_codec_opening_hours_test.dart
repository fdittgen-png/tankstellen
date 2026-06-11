// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #2777 (Epic #2776 D1) — the search-list cache codec MUST round-trip the
// structured Station.openingHours. Before the fix the field was
// @JsonKey(includeFromJson:false,includeToJson:false), so a cache-HIT search
// (the dominant repeat path for the polled FR/AT/CL sources) rehydrated
// stations with openingHours==null and the detail fast path rendered empty
// hours. This drives the REAL France production parse through the REAL codec —
// it was RED on master (e4c500bb) and is GREEN after the field serializes.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/station_service_chain_codec.dart';
import 'package:tankstellen/core/domain/opening_hours.dart';
import 'package:tankstellen/features/station_services/france/prix_carburants_parsers.dart';

void main() {
  // The REAL Esso 34120008 (Pézenas) shape from the live data.economie.gouv.fr
  // feed: a 24/7 automate plus distinct staffed boutique hours.
  Map<String, dynamic> essoRecord() => <String, dynamic>{
        'id': '34120008',
        'geom': <String, dynamic>{'lat': 43.4607, 'lon': 3.4203},
        'adresse': '28 faubourg des cordeliers',
        'ville': 'Pézenas',
        'cp': '34120',
        'sp95_prix': 1.899,
        'gazole_prix': 1.799,
        'horaires_automate_24_24': 'Oui',
        'horaires_jour':
            'Automate-24-24, Lundi07.00-18.30, Mardi07.00-18.30, '
                'Mercredi07.00-18.30, Jeudi07.00-18.30, Vendredi07.00-18.30, '
                'Samedi08.00-14.00, Dimanche',
      };

  group('search-list codec opening-hours round-trip (#2777)', () {
    test('structured Station.openingHours survives serialize -> deserialize',
        () {
      final fresh = parsePrixCarburantsStation(essoRecord(), 43.46, 3.42)!;
      expect(fresh.openingHours, isNotNull,
          reason: 'precondition — the fresh FR parse populates structured hours');

      // Simulate StationServiceChain Step 1 (cache HIT): the search list is
      // persisted via serializeStationList and rehydrated via
      // deserializeStationList exactly as _executeChain does on a cache hit.
      final restored = deserializeStationList(serializeStationList([fresh]))!.single;

      expect(restored.openingHours, isNotNull,
          reason: 'structured weekly hours must survive the cache round-trip — '
              'the detail fast path serves StationDetail(openingHours: '
              'station.openingHours)');

      // Not just non-null — the actual schedule must be intact.
      final oh = restored.openingHours!;
      expect(oh.automate24h, isTrue);
      expect(oh.dayFor(OpeningDay.mon)?.state, DayState.openRanges);
      expect(oh.dayFor(OpeningDay.mon)?.ranges.first.startMinutes, 7 * 60);
      expect(oh.dayFor(OpeningDay.mon)?.ranges.first.endMinutes, 18 * 60 + 30);
      expect(oh.dayFor(OpeningDay.sat)?.ranges.first.startMinutes, 8 * 60);
      expect(oh.dayFor(OpeningDay.sat)?.ranges.first.endMinutes, 14 * 60);
      expect(oh.dayFor(OpeningDay.sun)?.state, DayState.closed);
      expect(oh.availability, isNot(OpeningHoursAvailability.notProvided));
    });

    test('a station with no hours round-trips as null (back-compat, no crash)',
        () {
      final noHours = parsePrixCarburantsStation(
        <String, dynamic>{
          'id': '99999999',
          'geom': <String, dynamic>{'lat': 48.0, 'lon': 2.0},
          'ville': 'Nowhere',
          'gazole_prix': 1.7,
        },
        48.0,
        2.0,
      )!;
      final restored =
          deserializeStationList(serializeStationList([noHours]))!.single;
      // Either null or a notProvided availability — never a thrown parse.
      expect(
          restored.openingHours == null ||
              restored.openingHours!.availability ==
                  OpeningHoursAvailability.notProvided,
          isTrue);
    });
  });
}
