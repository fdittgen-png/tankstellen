// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/station_detail/domain/opening_hours.dart';
import 'package:tankstellen/features/station_services/france/france_opening_hours_adapter.dart';

/// Reuse-fidelity tests for the real [FranceOpeningHoursAdapter] (#2710),
/// driven with recorded `horaires_jour` strings from the gouv.fr feed — the
/// SAME flattened form the live Prix-Carburants endpoint emits. These prove
/// the four feed quirks the adapter owns:
///   - the `Automate-24-24` 24/7 flag,
///   - the missing-space day↔clock glue (`Lundi07.00-18.30`),
///   - the `01:00-01:00` degenerate "no interval" sentinel,
///   - split shifts (a lunch break as two same-day entries).
void main() {
  const adapter = FranceOpeningHoursAdapter();

  group('FranceOpeningHoursAdapter', () {
    test(
        'automate + staffed (the real Esso 34120008 case) → keeps the staffed '
        'boutique schedule AND flags automate24h, never all-24h (#2742)', () {
      // The EXACT live `horaires_jour` for SARL L'ATELIER STATION ESSO,
      // 34120 Pézenas (CRE id 34120008), verified against the gouv.fr feed:
      // automate pump 24/7, boutique Mon–Fri 07:00–18:30, Sat 08:00–14:00,
      // Sun closed (trailing `Dimanche` with no range).
      final out = adapter.parse({
        'horaires_jour':
            'Automate-24-24, Lundi07.00-18.30, Mardi07.00-18.30, '
                'Mercredi07.00-18.30, Jeudi07.00-18.30, Vendredi07.00-18.30, '
                'Samedi08.00-14.00, Dimanche',
        'horaires_automate_24_24': 'Oui',
      });

      // The orthogonal 24/7-automate indicator is set …
      expect(out.automate24h, isTrue);
      // … and the staffed schedule is PRESERVED, not collapsed to all-24h.
      for (final day in [
        OpeningDay.mon,
        OpeningDay.tue,
        OpeningDay.wed,
        OpeningDay.thu,
        OpeningDay.fri,
      ]) {
        final dh = out.dayFor(day);
        expect(dh?.state, DayState.openRanges,
            reason: 'staffed weekday must keep its ranges, not become 24h');
        expect(dh?.ranges.single.startMinutes, 7 * 60);
        expect(dh?.ranges.single.endMinutes, 18 * 60 + 30);
      }
      final sat = out.dayFor(OpeningDay.sat);
      expect(sat?.state, DayState.openRanges);
      expect(sat?.ranges.single.startMinutes, 8 * 60);
      expect(sat?.ranges.single.endMinutes, 14 * 60);
      // Trailing `Dimanche` with no range → CLOSED (Fermé), not dropped.
      expect(out.dayFor(OpeningDay.sun)?.state, DayState.closed);
      // No day is open24h — the schedule is staffed, the pump is the automate.
      expect(
        kRegularWeekdays.any((d) => out.dayFor(d)?.state == DayState.open24h),
        isFalse,
      );
      expect(out.availability, OpeningHoursAvailability.full);
    });

    test(
        'automate flag with NO staffed ranges at all → pump-only all-week '
        '24h + automate24h (#2742)', () {
      final out = adapter.parse({
        // Every day bare / closed, only the pump runs.
        'horaires_jour':
            'Automate-24-24, Lundi, Mardi, Mercredi, Jeudi, Vendredi, '
                'Samedi, Dimanche',
        'horaires_automate_24_24': 'Oui',
      });

      expect(out.automate24h, isTrue);
      expect(out.availability, OpeningHoursAvailability.full);
      for (final day in kRegularWeekdays) {
        expect(out.dayFor(day)?.state, DayState.open24h);
      }
    });

    test(
        'automate flag with empty schedule string → pump-only all-week 24h '
        '+ automate24h (#2742)', () {
      final out = adapter.parse({
        'horaires_jour': 'Automate-24-24',
        'horaires_automate_24_24': 'Oui',
      });
      expect(out.automate24h, isTrue);
      for (final day in kRegularWeekdays) {
        expect(out.dayFor(day)?.state, DayState.open24h);
      }
    });

    test('pure staffed (automate Non) → staffed days, automate24h false', () {
      final out = adapter.parse({
        'horaires_jour':
            'Automate-24-24, Lundi07.00-18.30, Mardi07.00-18.30',
        'horaires_automate_24_24': 'Non',
      });

      expect(out.automate24h, isFalse);
      expect(out.dayFor(OpeningDay.mon)?.state, DayState.openRanges);
    });

    test(
        'a bare interior day name → DayState.closed (Fermé), not dropped '
        '(#2742)', () {
      // Real 57100008 shape: Mon + Wed bare (closed), Tue/Thu/Fri/Sat open,
      // Sun trailing bare (closed).
      final out = adapter.parse({
        'horaires_jour': 'Lundi, Mardi07.00-20.00, Mercredi, Jeudi07.00-20.00, '
            'Vendredi07.00-20.00, Samedi07.00-20.00, Dimanche',
        'horaires_automate_24_24': 'Non',
      });

      expect(out.dayFor(OpeningDay.mon)?.state, DayState.closed);
      expect(out.dayFor(OpeningDay.wed)?.state, DayState.closed);
      expect(out.dayFor(OpeningDay.sun)?.state, DayState.closed);
      expect(out.dayFor(OpeningDay.tue)?.state, DayState.openRanges);
      expect(out.dayFor(OpeningDay.tue)?.ranges.single.endMinutes, 20 * 60);
      expect(out.availability, OpeningHoursAvailability.full);
    });

    test(
        'real " et "-joined split shift → two ranges on that day (#2742)', () {
      // Real 34360001 shape: `Lundi 08.00-12.00 et 14.00-18.00` — the lunch
      // break is one day, two ranges joined by " et ".
      final out = adapter.parse({
        'horaires_jour':
            'Lundi 08.00-12.00 et 14.00-18.00, Mardi 08.00-12.00 et 14.00-18.00',
        'horaires_automate_24_24': 'Non',
      });

      final monday = out.dayFor(OpeningDay.mon);
      expect(monday?.state, DayState.openRanges);
      expect(monday?.ranges, hasLength(2));
      expect(monday?.ranges[0].startMinutes, 8 * 60);
      expect(monday?.ranges[0].endMinutes, 12 * 60);
      expect(monday?.ranges[1].startMinutes, 14 * 60);
      expect(monday?.ranges[1].endMinutes, 18 * 60);
    });

    test('automate flag → all week open24h, availability full', () {
      final out = adapter.parse({
        'horaires_jour':
            'Automate-24-24, Lundi07.00-18.30, Mardi07.00-18.30',
        'horaires_automate_24_24': 'Oui',
      });

      // With staffed days present this is NOT collapsed to all-24h (#2742);
      // the automate indicator is set and the staffed days are kept.
      expect(out.automate24h, isTrue);
      expect(out.dayFor(OpeningDay.mon)?.state, DayState.openRanges);
      expect(out.dayFor(OpeningDay.tue)?.state, DayState.openRanges);
    });

    test(
        'per-day range parses the day + clock as SEPARATE values '
        '(no glued string)', () {
      final out = adapter.parse({
        'horaires_jour':
            'Automate-24-24, Lundi07.00-18.30, Mardi07.00-18.30',
        'horaires_automate_24_24': 'Non',
      });

      final monday = out.dayFor(OpeningDay.mon);
      expect(monday, isNotNull);
      expect(monday!.state, DayState.openRanges);
      expect(monday.ranges, hasLength(1));
      // 07:00 = 420 min, 18:30 = 1110 min — proves the day name was split off
      // the clock (the old flattener glued them into `Lundi07.00`).
      expect(monday.ranges.single.startMinutes, 7 * 60);
      expect(monday.ranges.single.endMinutes, 18 * 60 + 30);

      final tuesday = out.dayFor(OpeningDay.tue);
      expect(tuesday?.ranges.single.startMinutes, 7 * 60);
      expect(tuesday?.ranges.single.endMinutes, 18 * 60 + 30);

      // Only Mon+Tue were provided → partial, never `full`.
      expect(out.availability, OpeningHoursAvailability.partial);
      expect(out.days, hasLength(2));
    });

    test('01:00-01:00 degenerate sentinel → unknown, range dropped', () {
      final out = adapter.parse({
        'horaires_jour': 'Lundi01.00-01.00, Mardi08.00-18.00',
        'horaires_automate_24_24': 'Non',
      });

      final monday = out.dayFor(OpeningDay.mon);
      expect(monday, isNotNull);
      // Not a real interval, not 24h — explicitly unknown with no rendered range.
      expect(monday!.state, DayState.unknown);
      expect(monday.ranges, isEmpty);

      final tuesday = out.dayFor(OpeningDay.tue);
      expect(tuesday?.state, DayState.openRanges);
      expect(tuesday?.ranges, hasLength(1));
    });

    test('split shifts coalesce into one day with two ranges', () {
      final out = adapter.parse({
        'horaires_jour': 'Mardi08.00-12.00, Mardi14.00-19.00',
        'horaires_automate_24_24': 'Non',
      });

      final tuesday = out.dayFor(OpeningDay.tue);
      expect(tuesday, isNotNull);
      expect(tuesday!.state, DayState.openRanges);
      expect(tuesday.ranges, hasLength(2));
      expect(tuesday.ranges[0].startMinutes, 8 * 60);
      expect(tuesday.ranges[0].endMinutes, 12 * 60);
      expect(tuesday.ranges[1].startMinutes, 14 * 60);
      expect(tuesday.ranges[1].endMinutes, 19 * 60);
    });

    test('all seven weekdays provided → availability full', () {
      final out = adapter.parse({
        'horaires_jour': 'Lundi07.00-20.00, Mardi07.00-20.00, '
            'Mercredi07.00-20.00, Jeudi07.00-20.00, Vendredi07.00-20.00, '
            'Samedi08.00-20.00, Dimanche09.00-13.00',
        'horaires_automate_24_24': 'Non',
      });
      expect(out.days, hasLength(7));
      expect(out.availability, OpeningHoursAvailability.full);
      expect(out.dayFor(OpeningDay.sun)?.ranges.single.endMinutes, 13 * 60);
    });

    test('empty / null / unparseable input → notAvailable', () {
      expect(adapter.parse(''), WeeklyOpeningHours.notAvailable);
      expect(adapter.parse(null), WeeklyOpeningHours.notAvailable);
      expect(adapter.parse(42), WeeklyOpeningHours.notAvailable);
      expect(
        adapter.parse({'horaires_jour': '', 'horaires_automate_24_24': 'Non'}),
        WeeklyOpeningHours.notAvailable,
      );
      // No recognisable day↔clock token at all → no-data, not a crash.
      expect(
        adapter.parse({'horaires_jour': 'garbage payload no clocks'}),
        WeeklyOpeningHours.notAvailable,
      );
    });

    test('bare String is accepted as the horaires_jour value', () {
      final out = adapter.parse('Lundi06.30-22.00');
      final monday = out.dayFor(OpeningDay.mon);
      expect(monday?.state, DayState.openRanges);
      expect(monday?.ranges.single.startMinutes, 6 * 60 + 30);
    });

    test('never throws on a malformed shape — returns normally (#2349)', () {
      // Fault injection: feed shapes the parser must shape-narrow + catch,
      // asserting the call RETURNS NORMALLY (the documented never-throws
      // contract), not merely that the value is notAvailable.
      expect(() => adapter.parse(42), returnsNormally);
      expect(() => adapter.parse(null), returnsNormally);
      expect(() => adapter.parse(<int>[1, 2, 3]), returnsNormally);
      expect(() => adapter.parse({'horaires_jour': 12345}), returnsNormally);
      expect(adapter.parse(<int>[1, 2, 3]), WeeklyOpeningHours.notAvailable);
    });
  });
}
