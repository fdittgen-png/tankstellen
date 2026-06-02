// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/station_detail/domain/opening_hours.dart';
import 'package:tankstellen/features/station_services/austria/austria_opening_hours_adapter.dart';
import 'package:tankstellen/features/station_services/opening_hours/opening_hours_adapter.dart';

/// A recorded E-Control `openingHours[]` payload (live-feed shape verified
/// against `api.e-control.at/sprit/1.0`): one row per day, German full
/// `label` + two-letter `day` code + `order` + `HH:MM` `from`/`to`. Mon–Fri
/// 06:30-20:30, Sat 08:00-20:30, Sun closed (00:00-00:00), Feiertag a real
/// range — exercises the German-day mapping, Feiertag→publicHoliday and the
/// closed-day convention in one fixture.
final List<Map<String, dynamic>> _eControlFullWeekFixture = [
  {'day': 'MO', 'label': 'Montag', 'order': 1, 'from': '06:30', 'to': '20:30'},
  {'day': 'DI', 'label': 'Dienstag', 'order': 2, 'from': '06:30', 'to': '20:30'},
  {'day': 'MI', 'label': 'Mittwoch', 'order': 3, 'from': '06:30', 'to': '20:30'},
  {
    'day': 'DO',
    'label': 'Donnerstag',
    'order': 4,
    'from': '06:30',
    'to': '20:30',
  },
  {'day': 'FR', 'label': 'Freitag', 'order': 5, 'from': '06:30', 'to': '20:30'},
  {'day': 'SA', 'label': 'Samstag', 'order': 6, 'from': '08:00', 'to': '20:30'},
  {'day': 'SO', 'label': 'Sonntag', 'order': 7, 'from': '00:00', 'to': '00:00'},
  {
    'day': 'FE',
    'label': 'Feiertag',
    'order': 8,
    'from': '08:00',
    'to': '13:00',
  },
];

/// A 24/7 station: every day `00:00-24:00`, the live feed's whole-day marker.
final List<Map<String, dynamic>> _eControl24hFixture = [
  for (final label in const [
    'Montag',
    'Dienstag',
    'Mittwoch',
    'Donnerstag',
    'Freitag',
    'Samstag',
    'Sonntag',
    'Feiertag',
  ])
    {'label': label, 'from': '00:00', 'to': '24:00'},
];

void main() {
  const adapter = AustriaOpeningHoursAdapter();

  test('is an OpeningHoursAdapter', () {
    expect(adapter, isA<OpeningHoursAdapter>());
  });

  group('structured openingHours[] — full Mon–Sun + Feiertag', () {
    late WeeklyOpeningHours result;

    setUp(() => result = adapter.parse(_eControlFullWeekFixture));

    test('maps every German weekday label to the right OpeningDay', () {
      expect(result.dayFor(OpeningDay.mon)?.state, DayState.openRanges);
      expect(result.dayFor(OpeningDay.tue)?.state, DayState.openRanges);
      expect(result.dayFor(OpeningDay.wed)?.state, DayState.openRanges);
      expect(result.dayFor(OpeningDay.thu)?.state, DayState.openRanges);
      expect(result.dayFor(OpeningDay.fri)?.state, DayState.openRanges);
      expect(result.dayFor(OpeningDay.sat)?.state, DayState.openRanges);
    });

    test('Montag → mon with the right 06:30-20:30 range', () {
      final mon = result.dayFor(OpeningDay.mon);
      expect(mon, isNotNull);
      expect(mon!.state, DayState.openRanges);
      expect(mon.ranges, hasLength(1));
      expect(mon.ranges.single.startMinutes, 6 * 60 + 30);
      expect(mon.ranges.single.endMinutes, 20 * 60 + 30);
    });

    test('Samstag → sat with its distinct 08:00-20:30 range', () {
      final sat = result.dayFor(OpeningDay.sat);
      expect(sat!.ranges.single.startMinutes, 8 * 60);
      expect(sat.ranges.single.endMinutes, 20 * 60 + 30);
    });

    test('Sonntag 00:00-00:00 → closed', () {
      final sun = result.dayFor(OpeningDay.sun);
      expect(sun, isNotNull);
      expect(sun!.state, DayState.closed);
      expect(sun.ranges, isEmpty);
    });

    test('Feiertag → publicHoliday (OSM PH) with its own range', () {
      final ph = result.dayFor(OpeningDay.publicHoliday);
      expect(ph, isNotNull);
      expect(ph!.day, OpeningDay.publicHoliday);
      expect(ph.state, DayState.openRanges);
      expect(ph.ranges.single.startMinutes, 8 * 60);
      expect(ph.ranges.single.endMinutes, 13 * 60);
    });

    test('availability is full (all seven regular weekdays covered)', () {
      expect(result.availability, OpeningHoursAvailability.full);
    });
  });

  group('24h detection', () {
    test('00:00-24:00 on every day → all days open24h', () {
      final result = adapter.parse(_eControl24hFixture);
      for (final d in kRegularWeekdays) {
        expect(result.dayFor(d)?.state, DayState.open24h,
            reason: '$d should be open24h');
      }
      expect(result.dayFor(OpeningDay.publicHoliday)?.state, DayState.open24h);
      expect(result.availability, OpeningHoursAvailability.full);
    });
  });

  group('joined German string fallback', () {
    test('parses the legacy "Montag: 06:30-20:30, …, Feiertag: …" paragraph',
        () {
      const joined = 'Montag: 06:30-20:30, Dienstag: 06:30-20:30, '
          'Mittwoch: 06:30-20:30, Donnerstag: 06:30-20:30, '
          'Freitag: 06:30-20:30, Samstag: 08:00-20:30, '
          'Sonntag: 00:00-00:00, Feiertag: 08:00-13:00';
      final result = adapter.parse(joined);

      expect(result.dayFor(OpeningDay.mon)?.ranges.single.startMinutes,
          6 * 60 + 30);
      expect(result.dayFor(OpeningDay.sun)?.state, DayState.closed);
      expect(result.dayFor(OpeningDay.publicHoliday)?.state,
          DayState.openRanges);
      expect(result.availability, OpeningHoursAvailability.full);
      expect(result.rawSource, joined);
    });

    test('"geschlossen" token → closed day', () {
      final result = adapter.parse('Sonntag: geschlossen');
      expect(result.dayFor(OpeningDay.sun)?.state, DayState.closed);
    });
  });

  group('graceful no-data (never throws, never null)', () {
    test('empty list → notAvailable', () {
      expect(adapter.parse(const <dynamic>[]), WeeklyOpeningHours.notAvailable);
    });

    test('empty string → notAvailable', () {
      expect(adapter.parse(''), WeeklyOpeningHours.notAvailable);
    });

    test('null → notAvailable', () {
      expect(adapter.parse(null), WeeklyOpeningHours.notAvailable);
    });

    test('unrecognised shape → notAvailable, returns normally', () {
      expect(() => adapter.parse(42), returnsNormally);
      expect(adapter.parse(42), WeeklyOpeningHours.notAvailable);
      expect(adapter.parse(const {'unexpected': true}),
          WeeklyOpeningHours.notAvailable);
    });

    test('rows with only unrecognised day labels → notAvailable', () {
      final result = adapter.parse([
        {'label': 'Funday', 'from': '06:00', 'to': '22:00'},
      ]);
      expect(result, WeeklyOpeningHours.notAvailable);
    });

    test('partial coverage (subset of weekdays) → partial availability', () {
      final result = adapter.parse([
        {'label': 'Montag', 'from': '06:00', 'to': '22:00'},
        {'label': 'Dienstag', 'from': '06:00', 'to': '22:00'},
      ]);
      expect(result.availability, OpeningHoursAvailability.partial);
      expect(result.dayFor(OpeningDay.mon)?.state, DayState.openRanges);
    });
  });

  group('enclosing map shape', () {
    test('{"openingHours": [...]} is unwrapped and parsed', () {
      final result =
          adapter.parse({'openingHours': _eControlFullWeekFixture});
      expect(result.dayFor(OpeningDay.publicHoliday)?.state,
          DayState.openRanges);
    });
  });
}
