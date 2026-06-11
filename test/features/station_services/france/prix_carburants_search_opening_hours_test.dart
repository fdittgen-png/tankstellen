// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/opening_hours.dart';
import 'package:tankstellen/features/station_services/france/prix_carburants_parsers.dart';

/// #2751 — the search→detail fast path (station_detail_provider) serves
/// `StationDetail.openingHours = fromSearch.station.openingHours`. So the FR
/// SEARCH parse MUST carry the structured schedule, or the staffed boutique
/// hours are lost (an automate station collapses to "Open 24 hours" via the
/// legacy bridge). RED on master (search Station.openingHours == null),
/// GREEN after. Reuse-fidelity: the record is the REAL Esso 34120008 (Pézenas)
/// shape from the live data.economie.gouv.fr feed.
void main() {
  Map<String, dynamic> essoRecord() => <String, dynamic>{
        'id': '34120008',
        'geom': <String, dynamic>{'lat': 43.4607, 'lon': 3.4203},
        'adresse': '28 faubourg des cordeliers, route de montpellier',
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

  test('FR search parse carries the structured staffed schedule (#2751)', () {
    final s = parsePrixCarburantsStation(essoRecord(), 43.46, 3.42);
    expect(s, isNotNull);

    final oh = s!.openingHours;
    expect(oh, isNotNull,
        reason: 'search Station must carry structured hours so the detail '
            'fast path renders them instead of the legacy bridge');

    // 24/7 automate is an orthogonal badge, NOT a replacement for staffed hours.
    expect(oh!.automate24h, isTrue);

    // Mon–Fri 07:00–18:30 staffed.
    expect(oh.dayFor(OpeningDay.mon)?.state, DayState.openRanges);
    expect(oh.dayFor(OpeningDay.mon)?.ranges.first.startMinutes, 7 * 60);
    expect(oh.dayFor(OpeningDay.mon)?.ranges.first.endMinutes, 18 * 60 + 30);
    // Sat 08:00–14:00.
    expect(oh.dayFor(OpeningDay.sat)?.ranges.first.startMinutes, 8 * 60);
    expect(oh.dayFor(OpeningDay.sat)?.ranges.first.endMinutes, 14 * 60);
    // Sun closed (bare "Dimanche" with no range → Fermé).
    expect(oh.dayFor(OpeningDay.sun)?.state, DayState.closed);

    // NOT collapsed to all-week 24h (the bug this fixes).
    expect(oh.availability, isNot(OpeningHoursAvailability.notProvided));
    final allOpen24 = kRegularWeekdays
        .every((d) => oh.dayFor(d)?.state == DayState.open24h);
    expect(allOpen24, isFalse,
        reason: 'staffed hours must survive — not collapse to Open 24 hours');
  });

  test('non-automate FR station still carries its staffed schedule (#2751)',
      () {
    final r = essoRecord()
      ..['horaires_automate_24_24'] = 'Non'
      ..['horaires_jour'] =
          'Lundi08.00-12.00 et 14.00-19.00, Mardi08.00-19.00, Dimanche';
    final s = parsePrixCarburantsStation(r, 43.46, 3.42);
    final oh = s!.openingHours;
    expect(oh, isNotNull);
    expect(oh!.automate24h, isFalse);
    // Split shift on Monday → two ranges.
    expect(oh.dayFor(OpeningDay.mon)?.ranges.length, 2);
    expect(oh.dayFor(OpeningDay.sun)?.state, DayState.closed);
  });
}
