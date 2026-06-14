// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/opening_hours.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/station_services/france/prix_carburants_parsers.dart';

/// Regression lock for the recurring FR opening-hours loss (Epic #2776 / #2781):
/// the structured `Station.openingHours` used to be `@JsonKey`-excluded, so it
/// survived the SEARCH parse but was dropped on the FIRST `toJson`/`fromJson`
/// round-trip — i.e. the moment a search result was cached to Hive and the
/// detail page's fast path rehydrated it. Every cached/favorited/widget tap
/// then rendered "Horaires d'ouverture non disponibles".
///
/// The unit-on-the-adapter and the search-parse tests were BOTH green through
/// that bug (false-green: neither exercised the codec). This drives the REAL
/// data.economie.gouv.fr record shapes (Pézenas 34120) through the full
/// `parse → Station → toJson → fromJson` path and asserts the structured
/// schedule is intact after the round-trip — so a future re-exclusion of the
/// field fails HERE instead of silently in production.
void main() {
  // The REAL Esso 34120008 (28 Faubourg des cordeliers, Pézenas) record from
  // the live feed: a 24/7 automate WITH staffed boutique hours.
  Map<String, dynamic> staffedRecord() => <String, dynamic>{
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

  test('structured FR opening hours survive the Station JSON round-trip '
      '(#2781 regression lock)', () {
    final parsed = parsePrixCarburantsStation(staffedRecord(), 43.46, 3.42);
    expect(parsed, isNotNull);
    expect(parsed!.openingHours, isNotNull,
        reason: 'search parse must carry the structured schedule');

    // The cache path: encode to JSON and back, exactly like Hive does.
    final roundTripped = Station.fromJson(parsed.toJson());

    final oh = roundTripped.openingHours;
    expect(oh, isNotNull,
        reason: 'openingHours must SURVIVE toJson/fromJson — the #2776/#2781 '
            'regression dropped it here, so the detail fast path rehydrated a '
            'hours-less station and rendered "non disponibles"');

    // The real schedule is intact, not collapsed to all-week 24h.
    expect(oh!.automate24h, isTrue);
    expect(oh.dayFor(OpeningDay.mon)?.state, DayState.openRanges);
    expect(oh.dayFor(OpeningDay.mon)?.ranges.first.startMinutes, 7 * 60);
    expect(oh.dayFor(OpeningDay.mon)?.ranges.first.endMinutes, 18 * 60 + 30);
    expect(oh.dayFor(OpeningDay.sat)?.ranges.first.startMinutes, 8 * 60);
    expect(oh.dayFor(OpeningDay.sun)?.state, DayState.closed);
    expect(oh.availability, isNot(OpeningHoursAvailability.notProvided));

    // The flattened back-compat text also survives (the legacy bridge fallback).
    expect(roundTripped.openingHoursText, isNotNull);
    expect(roundTripped.is24h, isTrue);
  });

  test('a genuinely hours-less FR record (all 01:00-01:00, automate off) '
      'round-trips as not-available — honest, not a parse loss', () {
    // The REAL 34120007 (18 AVENUE DE VERDUN, Pézenas) record: every day is
    // the degenerate `01.00-01.00` sentinel and the automate flag is off, so
    // the source genuinely carries NO usable hours.
    final record = <String, dynamic>{
      'id': '34120007',
      'geom': <String, dynamic>{'lat': 43.46, 'lon': 3.42},
      'adresse': '18 AVENUE DE VERDUN',
      'ville': 'Pézenas',
      'cp': '34120',
      'gazole_prix': 1.999,
      'horaires_automate_24_24': 'Non',
      'horaires_jour':
          'Lundi01.00-01.00, Mardi01.00-01.00, Mercredi01.00-01.00, '
              'Jeudi01.00-01.00, Vendredi01.00-01.00, Samedi01.00-01.00, '
              'Dimanche01.00-01.00',
    };
    final parsed = parsePrixCarburantsStation(record, 43.46, 3.42);
    final oh = Station.fromJson(parsed!.toJson()).openingHours;
    // No staffed ranges anywhere — every day is the degenerate sentinel.
    final anyOpen = kRegularWeekdays
        .any((d) => oh?.dayFor(d)?.state == DayState.openRanges);
    expect(anyOpen, isFalse,
        reason: 'the source data has no real intervals for this station — '
            '"non disponibles" is the honest render, not a parse regression');
  });
}
