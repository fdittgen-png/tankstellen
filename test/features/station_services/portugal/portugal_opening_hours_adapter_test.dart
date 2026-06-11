// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/opening_hours.dart';
import 'package:tankstellen/features/station_services/opening_hours/opening_hours_adapter.dart';
import 'package:tankstellen/features/station_services/portugal/portugal_opening_hours_adapter.dart';

/// Recorded DGEG `HorarioPosto` payloads, verified against the live
/// `GetDadosPostoMapa?id=&f=json` endpoint (#2714). The object always carries
/// four period keys — `DiasUteis` (Mon–Fri), `Sabado`, `Domingo`, `Feriado`
/// (the OSM `PH` public-holiday pseudo-day). Each value is one of
/// `'Aberto 24 horas'`, a `'HH:MM-HH:MM'` range, `'Fechado'`, or null/missing.

/// id 93159 (TRANSFORPEL Chão de Sapo) — open 24h every period.
const Map<String, dynamic> _open24Fixture = {
  'DiasUteis': 'Aberto 24 horas',
  'Sabado': 'Aberto 24 horas',
  'Domingo': 'Aberto 24 horas',
  'Feriado': 'Aberto 24 horas',
};

/// id 94138 — weekday 07:00-19:00, Sat 07:00-18:00, Sun + Feriado closed.
/// Exercises per-period variation, a real range, and the Fechado→closed path
/// (incl. Feriado→publicHoliday).
const Map<String, dynamic> _weekdayPlusFeriadoFixture = {
  'DiasUteis': '07:00-19:00',
  'Sabado': '07:00-18:00',
  'Domingo': 'Fechado',
  'Feriado': 'Fechado',
};

/// id 80797 (RECHEIO Portimão) — 07:00-18:00 weekday/Sat, Sun + holiday closed.
const Map<String, dynamic> _closedSundayFixture = {
  'DiasUteis': '07:00-18:00',
  'Sabado': '07:00-18:00',
  'Domingo': 'Fechado',
  'Feriado': 'Fechado',
};

/// The enclosing `resultado` object (the adapter unwraps `HorarioPosto`).
const Map<String, dynamic> _resultadoWrapper = {
  'Nome': 'Posto X',
  'Marca': 'GALP',
  'HorarioPosto': _open24Fixture,
};

void main() {
  const adapter = PortugalOpeningHoursAdapter();

  test('is an OpeningHoursAdapter', () {
    expect(adapter, isA<OpeningHoursAdapter>());
  });

  group("'Aberto 24 horas' → open24h", () {
    late WeeklyOpeningHours result;
    setUp(() => result = adapter.parse(_open24Fixture));

    test('every regular weekday is open24h', () {
      for (final d in kRegularWeekdays) {
        expect(result.dayFor(d)?.state, DayState.open24h, reason: '$d');
      }
    });

    test('Feriado → publicHoliday open24h', () {
      final ph = result.dayFor(OpeningDay.publicHoliday);
      expect(ph, isNotNull);
      expect(ph!.day, OpeningDay.publicHoliday);
      expect(ph.state, DayState.open24h);
    });

    test('availability is full', () {
      expect(result.availability, OpeningHoursAvailability.full);
    });
  });

  group('weekday + Feriado ranges and Fechado', () {
    late WeeklyOpeningHours result;
    setUp(() => result = adapter.parse(_weekdayPlusFeriadoFixture));

    test('DiasUteis 07:00-19:00 fans out across Mon–Fri', () {
      for (final d in const [
        OpeningDay.mon,
        OpeningDay.tue,
        OpeningDay.wed,
        OpeningDay.thu,
        OpeningDay.fri,
      ]) {
        final dh = result.dayFor(d);
        expect(dh?.state, DayState.openRanges, reason: '$d');
        expect(dh!.ranges.single.startMinutes, 7 * 60);
        expect(dh.ranges.single.endMinutes, 19 * 60);
      }
    });

    test('Sabado has its own distinct 07:00-18:00 range', () {
      final sat = result.dayFor(OpeningDay.sat);
      expect(sat!.state, DayState.openRanges);
      expect(sat.ranges.single.startMinutes, 7 * 60);
      expect(sat.ranges.single.endMinutes, 18 * 60);
    });

    test('Domingo "Fechado" → closed', () {
      expect(result.dayFor(OpeningDay.sun)?.state, DayState.closed);
      expect(result.dayFor(OpeningDay.sun)?.ranges, isEmpty);
    });

    test('Feriado "Fechado" → publicHoliday closed', () {
      final ph = result.dayFor(OpeningDay.publicHoliday);
      expect(ph?.day, OpeningDay.publicHoliday);
      expect(ph?.state, DayState.closed);
    });

    test('availability is full (all seven regular weekdays covered)', () {
      expect(result.availability, OpeningHoursAvailability.full);
    });
  });

  group('closed-Sunday fixture (80797)', () {
    test('weekday + Sat open, Sun + Feriado closed', () {
      final r = adapter.parse(_closedSundayFixture);
      expect(r.dayFor(OpeningDay.mon)?.state, DayState.openRanges);
      expect(r.dayFor(OpeningDay.sat)?.state, DayState.openRanges);
      expect(r.dayFor(OpeningDay.sun)?.state, DayState.closed);
      expect(r.dayFor(OpeningDay.publicHoliday)?.state, DayState.closed);
    });
  });

  group('input shapes', () {
    test('unwraps HorarioPosto from the enclosing resultado map', () {
      final r = adapter.parse(_resultadoWrapper);
      expect(r.dayFor(OpeningDay.mon)?.state, DayState.open24h);
      expect(r.dayFor(OpeningDay.publicHoliday)?.state, DayState.open24h);
    });

    test('lower-cased period keys still resolve', () {
      final r = adapter.parse(const {
        'diasuteis': 'Aberto 24 horas',
        'sabado': 'Aberto 24 horas',
        'domingo': 'Aberto 24 horas',
        'feriado': 'Aberto 24 horas',
      });
      expect(r.dayFor(OpeningDay.mon)?.state, DayState.open24h);
    });

    test('only some periods present → partial availability', () {
      final r = adapter.parse(const {
        'DiasUteis': '07:00-22:00',
        // Sabado/Domingo/Feriado absent → Sat/Sun omitted (unknown)
      });
      expect(r.availability, OpeningHoursAvailability.partial);
      expect(r.dayFor(OpeningDay.mon)?.state, DayState.openRanges);
      expect(r.dayFor(OpeningDay.sat), isNull);
    });
  });

  group('graceful no-data (never throws, never null)', () {
    test('empty map → notAvailable', () {
      expect(adapter.parse(const <String, dynamic>{}),
          WeeklyOpeningHours.notAvailable);
    });

    test('null → notAvailable', () {
      expect(adapter.parse(null), WeeklyOpeningHours.notAvailable);
    });

    test('all periods null → notAvailable', () {
      final r = adapter.parse(const {
        'DiasUteis': null,
        'Sabado': null,
        'Domingo': null,
        'Feriado': null,
      });
      expect(r, WeeklyOpeningHours.notAvailable);
    });

    test('unrecognised period token → notAvailable', () {
      final r = adapter.parse(const {'DiasUteis': 'n.d.'});
      expect(r, WeeklyOpeningHours.notAvailable);
    });
  });

  // Fault-injection (#2349 never_throws_contract_test): the adapter documents a
  // never-throws contract, so a malformed / unexpected shape must return
  // normally with the no-data sentinel — never propagate.
  group('never throws — fault injection (#2349)', () {
    test('an int returns normally → notAvailable', () {
      expect(() => adapter.parse(42), returnsNormally);
      expect(adapter.parse(42), WeeklyOpeningHours.notAvailable);
    });

    test('a list returns normally → notAvailable', () {
      expect(() => adapter.parse(const [1, 2, 3]), returnsNormally);
      expect(adapter.parse(const [1, 2, 3]), WeeklyOpeningHours.notAvailable);
    });

    test('a null period value inside the map returns normally', () {
      expect(
        () => adapter.parse(const {'HorarioPosto': null}),
        returnsNormally,
      );
    });

    test('a non-string period value (a nested list) returns normally', () {
      expect(
        () => adapter.parse(const {
          'DiasUteis': ['unexpected', 'list'],
        }),
        returnsNormally,
      );
    });

    test('a deeply-malformed nested shape returns normally', () {
      expect(
        () => adapter.parse({
          'HorarioPosto': {
            'DiasUteis': {'unexpected': 'object'},
            'Sabado': 999,
          },
        }),
        returnsNormally,
      );
    });
  });
}
