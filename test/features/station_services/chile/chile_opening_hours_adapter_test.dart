// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/station_detail/domain/opening_hours.dart';
import 'package:tankstellen/features/station_services/chile/chile_opening_hours_adapter.dart';
import 'package:tankstellen/features/station_services/opening_hours/opening_hours_adapter.dart';

/// Recorded CNE `horario_atencion` values (grounded on the live "Bencina en
/// Línea" feed — the field is a short free-form string; see the
/// `ChileStationService` envelope docstring and the existing
/// `chile_response_parser.dart` `isOpen` derivation, which keys on the same
/// `24_horas` / `cerrado` tokens). These exercise every branch the adapter
/// owns without touching Dio/Hive.
const String _open24Fixture = '24_horas';
const String _closedFixture = 'Temporalmente CERRADO por mantenimiento';
const String _freeTextFullWeek =
    'Lunes a Viernes 07:00-22:00, Sábado 08:00-14:00, Domingo 09:00-13:00';
const String _freeTextNoDayLabels = '07:00-22:00';

void main() {
  const adapter = ChileOpeningHoursAdapter();

  test('is an OpeningHoursAdapter', () {
    expect(adapter, isA<OpeningHoursAdapter>());
  });

  group('24_horas → whole-week open24h', () {
    test('"24_horas" → all regular weekdays open24h, full', () {
      final result = adapter.parse(_open24Fixture);
      for (final d in kRegularWeekdays) {
        expect(result.dayFor(d)?.state, DayState.open24h, reason: '$d');
      }
      expect(result.availability, OpeningHoursAvailability.full);
      expect(result.rawSource, _open24Fixture);
    });

    test('spacing / casing variants ("24 horas", "24Horas") also → open24h',
        () {
      for (final v in const ['24 horas', '24Horas', '24_HORAS']) {
        final result = adapter.parse(v);
        expect(result.dayFor(OpeningDay.mon)?.state, DayState.open24h,
            reason: v);
        expect(result.availability, OpeningHoursAvailability.full);
      }
    });
  });

  group('cerrado → whole-week closed', () {
    test('a "cerrado" token → every regular weekday closed, full', () {
      final result = adapter.parse(_closedFixture);
      for (final d in kRegularWeekdays) {
        expect(result.dayFor(d)?.state, DayState.closed, reason: '$d');
        expect(result.dayFor(d)?.ranges, isEmpty);
      }
      expect(result.availability, OpeningHoursAvailability.full);
    });

    test('bare lowercase "cerrado" → closed', () {
      final result = adapter.parse('cerrado');
      expect(result.dayFor(OpeningDay.mon)?.state, DayState.closed);
    });
  });

  group('free-text schedule → best-effort ranges', () {
    late WeeklyOpeningHours result;
    setUp(() => result = adapter.parse(_freeTextFullWeek));

    test('"Lunes a Viernes 07:00-22:00" spans Mon–Fri with that range', () {
      for (final d in const [
        OpeningDay.mon,
        OpeningDay.tue,
        OpeningDay.wed,
        OpeningDay.thu,
        OpeningDay.fri,
      ]) {
        final day = result.dayFor(d);
        expect(day?.state, DayState.openRanges, reason: '$d');
        expect(day!.ranges.single.startMinutes, 7 * 60);
        expect(day.ranges.single.endMinutes, 22 * 60);
      }
    });

    test('Sábado / Domingo get their own distinct ranges', () {
      expect(result.dayFor(OpeningDay.sat)?.ranges.single.startMinutes, 8 * 60);
      expect(result.dayFor(OpeningDay.sat)?.ranges.single.endMinutes, 14 * 60);
      expect(result.dayFor(OpeningDay.sun)?.ranges.single.startMinutes, 9 * 60);
      expect(result.dayFor(OpeningDay.sun)?.ranges.single.endMinutes, 13 * 60);
    });

    test('all seven weekdays resolved → full availability', () {
      expect(result.availability, OpeningHoursAvailability.full);
      expect(result.rawSource, _freeTextFullWeek);
    });

    test('a range with no day labels applies to the whole week', () {
      final r = adapter.parse(_freeTextNoDayLabels);
      for (final d in kRegularWeekdays) {
        expect(r.dayFor(d)?.state, DayState.openRanges, reason: '$d');
        expect(r.dayFor(d)?.ranges.single.startMinutes, 7 * 60);
      }
      expect(r.availability, OpeningHoursAvailability.full);
    });

    test('a partial schedule (only some days) → partial availability', () {
      final r = adapter.parse('Lunes a Miércoles 06:00-12:00');
      expect(r.dayFor(OpeningDay.mon)?.state, DayState.openRanges);
      expect(r.dayFor(OpeningDay.wed)?.state, DayState.openRanges);
      expect(r.dayFor(OpeningDay.thu), isNull);
      expect(r.availability, OpeningHoursAvailability.partial);
    });
  });

  group('Map station-row convenience shape', () {
    test('a {horario_atencion: …} row is unwrapped and parsed', () {
      final r = adapter.parse(const {'horario_atencion': '24_horas'});
      expect(r.dayFor(OpeningDay.mon)?.state, DayState.open24h);
    });
  });

  group('graceful no-data → notAvailable / notProvided', () {
    test('the "HH" placeholder the API docs ship → notAvailable', () {
      // node-cne / energiaabierta sample responses carry a literal "HH"
      // placeholder; it has no clock and must degrade, not crash.
      expect(adapter.parse('HH'), WeeklyOpeningHours.notAvailable);
    });

    test('empty string → notAvailable', () {
      expect(adapter.parse(''), WeeklyOpeningHours.notAvailable);
    });

    test('a non-schedule free-text string → notAvailable', () {
      expect(adapter.parse('Consultar en estación'),
          WeeklyOpeningHours.notAvailable);
    });

    test('null → notAvailable', () {
      expect(adapter.parse(null), WeeklyOpeningHours.notAvailable);
    });
  });

  group('never throws (fault injection — #2349 never_throws contract)', () {
    test('int / null / list inputs return normally → notAvailable', () {
      expect(() => adapter.parse(42), returnsNormally);
      expect(() => adapter.parse(null), returnsNormally);
      expect(() => adapter.parse(const <dynamic>[1, 2, 3]), returnsNormally);
      expect(adapter.parse(42), WeeklyOpeningHours.notAvailable);
      expect(adapter.parse(const <dynamic>[1, 2, 3]),
          WeeklyOpeningHours.notAvailable);
    });

    test('a Map whose horario_atencion is itself a Map returns normally', () {
      // A nested non-string value would blow up a naive parse; the adapter
      // narrows via toString() and degrades.
      expect(
        () => adapter.parse(const {
          'horario_atencion': {'unexpected': 'nested'},
        }),
        returnsNormally,
      );
    });

    test('an unexpected scalar shape (double) returns normally', () {
      expect(() => adapter.parse(3.14), returnsNormally);
      expect(adapter.parse(3.14), WeeklyOpeningHours.notAvailable);
    });
  });
}
