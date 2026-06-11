// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/opening_hours.dart';
import 'package:tankstellen/features/station_services/opening_hours/opening_hours_adapter.dart';
import 'package:tankstellen/features/station_services/spain/spain_opening_hours_adapter.dart';

/// Recorded MITECO `Horario` strings, verified literally against live
/// geoportalgasolineras station pages (Epic C6, #2713):
///   - `'L-D: 24H'` — open all week, 24h (the common form).
///   - `'L-V: 06:00-23:00; S-D: 08:00-23:00'` — weekday + weekend ranges
///     (repsol-avenida-peinador-49).
///   - `'L-V: 05:30-23:00; S: 06:30-22:30; D: 07:30-21:00'` — single-day
///     segments mixed with a range (cepsa-poligono-campollano-55).
const _horario24h = 'L-D: 24H';
const _horarioWeekdayWeekend = 'L-V: 06:00-23:00; S-D: 08:00-23:00';
const _horarioPerDay = 'L-V: 05:30-23:00; S: 06:30-22:30; D: 07:30-21:00';

void main() {
  const adapter = SpainOpeningHoursAdapter();

  test('is an OpeningHoursAdapter', () {
    expect(adapter, isA<OpeningHoursAdapter>());
  });

  group('L-D: 24H → open all week', () {
    late WeeklyOpeningHours result;
    setUp(() => result = adapter.parse(_horario24h));

    test('every regular weekday is open24h', () {
      for (final d in kRegularWeekdays) {
        expect(result.dayFor(d)?.state, DayState.open24h,
            reason: '$d should be open24h');
      }
    });

    test('availability is full', () {
      expect(result.availability, OpeningHoursAvailability.full);
    });

    test('keeps the raw Horario string', () {
      expect(result.rawSource, _horario24h);
    });
  });

  group('L-V / S-D day-range mapping', () {
    late WeeklyOpeningHours result;
    setUp(() => result = adapter.parse(_horarioWeekdayWeekend));

    test('L-V expands to Mon–Fri with the 06:00-23:00 range', () {
      for (final d in const [
        OpeningDay.mon,
        OpeningDay.tue,
        OpeningDay.wed,
        OpeningDay.thu,
        OpeningDay.fri,
      ]) {
        final day = result.dayFor(d);
        expect(day?.state, DayState.openRanges, reason: '$d');
        expect(day!.ranges.single.startMinutes, 6 * 60, reason: '$d');
        expect(day.ranges.single.endMinutes, 23 * 60, reason: '$d');
      }
    });

    test('S-D expands to Sat+Sun with the 08:00-23:00 range', () {
      for (final d in const [OpeningDay.sat, OpeningDay.sun]) {
        final day = result.dayFor(d);
        expect(day?.state, DayState.openRanges, reason: '$d');
        expect(day!.ranges.single.startMinutes, 8 * 60, reason: '$d');
        expect(day.ranges.single.endMinutes, 23 * 60, reason: '$d');
      }
    });

    test('availability is full (whole week covered)', () {
      expect(result.availability, OpeningHoursAvailability.full);
    });
  });

  group('single-day segments mixed with a range', () {
    late WeeklyOpeningHours result;
    setUp(() => result = adapter.parse(_horarioPerDay));

    test('Saturday gets its distinct 06:30-22:30 range', () {
      final sat = result.dayFor(OpeningDay.sat);
      expect(sat!.ranges.single.startMinutes, 6 * 60 + 30);
      expect(sat.ranges.single.endMinutes, 22 * 60 + 30);
    });

    test('Sunday gets its distinct 07:30-21:00 range', () {
      final sun = result.dayFor(OpeningDay.sun);
      expect(sun!.ranges.single.startMinutes, 7 * 60 + 30);
      expect(sun.ranges.single.endMinutes, 21 * 60);
    });

    test('Mon–Fri keep the 05:30-23:00 range', () {
      final mon = result.dayFor(OpeningDay.mon);
      expect(mon!.ranges.single.startMinutes, 5 * 60 + 30);
      expect(mon.ranges.single.endMinutes, 23 * 60);
    });
  });

  group('Cerrado → closed', () {
    test('bare "Cerrado" closes the whole week', () {
      final result = adapter.parse('Cerrado');
      for (final d in kRegularWeekdays) {
        expect(result.dayFor(d)?.state, DayState.closed, reason: '$d');
      }
      expect(result.availability, OpeningHoursAvailability.full);
    });

    test('a per-day "…: Cerrado" segment closes just that day', () {
      final result = adapter.parse('L-S: 06:00-22:00; D: Cerrado');
      expect(result.dayFor(OpeningDay.sat)?.state, DayState.openRanges);
      expect(result.dayFor(OpeningDay.sun)?.state, DayState.closed);
    });
  });

  group('partial coverage', () {
    test('a subset of days → partial availability', () {
      final result = adapter.parse('L-V: 08:00-20:00');
      expect(result.availability, OpeningHoursAvailability.partial);
      expect(result.dayFor(OpeningDay.mon)?.state, DayState.openRanges);
      expect(result.dayFor(OpeningDay.sat), isNull);
    });
  });

  group('24:00 end marker', () {
    test('00:00-24:00 is the whole-day end marker (1440 minutes)', () {
      final result = adapter.parse('L-D: 00:00-24:00');
      final mon = result.dayFor(OpeningDay.mon);
      expect(mon!.ranges.single.startMinutes, 0);
      expect(mon.ranges.single.endMinutes, 1440);
    });
  });

  group('graceful no-data (never throws, never null)', () {
    test('empty string → notAvailable', () {
      expect(adapter.parse(''), WeeklyOpeningHours.notAvailable);
    });

    test('whitespace-only → notAvailable', () {
      expect(adapter.parse('   '), WeeklyOpeningHours.notAvailable);
    });

    test('null → notAvailable', () {
      expect(adapter.parse(null), WeeklyOpeningHours.notAvailable);
    });

    test('a segment with only unknown day tokens → notAvailable', () {
      expect(adapter.parse('Z-Q: 06:00-22:00'), WeeklyOpeningHours.notAvailable);
    });

    // Fault-injection for `never_throws_contract_test` (#2349): the adapter
    // documents "never throws", so a non-String / structurally-broken input
    // must return normally with the no-data sentinel, never propagate.
    test('non-String / broken inputs return normally → notAvailable', () {
      expect(() => adapter.parse(42), returnsNormally);
      expect(() => adapter.parse(<int>[1, 2, 3]), returnsNormally);
      expect(() => adapter.parse(const {'unexpected': true}), returnsNormally);
      expect(() => adapter.parse(null), returnsNormally);
      expect(adapter.parse(42), WeeklyOpeningHours.notAvailable);
      expect(adapter.parse(<int>[1, 2, 3]), WeeklyOpeningHours.notAvailable);
      expect(
        adapter.parse(const {'unexpected': true}),
        WeeklyOpeningHours.notAvailable,
      );
    });

    test('malformed clock segments are dropped, do not throw', () {
      expect(() => adapter.parse('L-V: 99:99-aa:bb'), returnsNormally);
      expect(
        adapter.parse('L-V: 99:99-aa:bb'),
        WeeklyOpeningHours.notAvailable,
      );
    });
  });
}
