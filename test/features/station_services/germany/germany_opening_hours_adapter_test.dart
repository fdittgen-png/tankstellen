// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/station_detail/domain/opening_hours.dart';
import 'package:tankstellen/features/station_services/germany/germany_opening_hours_adapter.dart';
import 'package:tankstellen/features/station_services/opening_hours/opening_hours_adapter.dart';

/// A recorded Tankerkönig `detail.php` `station` slice (live-feed shape: the
/// `openingTimes[]` `{text,start,end}` rows + the `wholeDay` flag + the
/// free-form `overrides[]`). The `text` field mixes a short-code range
/// (`Mo-Fr`) with the combined `"Samstag, Sonntag, Feiertag"` list and uses
/// `HH:MM:SS` clocks — exercises the day-range expansion, the comma-list
/// expansion and Feiertag→publicHoliday in one fixture.
const Map<String, dynamic> _tankerkoenigStation = {
  'id': '24a381e3-0d72-416d-bfd8-b2f65f6e5802',
  'name': 'Aral Tankstelle',
  'openingTimes': [
    {'text': 'Mo-Fr', 'start': '06:00:00', 'end': '22:00:00'},
    {'text': 'Samstag, Sonntag, Feiertag', 'start': '07:00:00', 'end': '21:00:00'},
  ],
  'overrides': ['13.04.2017, 15:00:00 - 13.11.2017, 15:00:00: geschlossen'],
  'wholeDay': false,
};

/// A whole-day station: `wholeDay: true` — the around-the-clock marker.
const Map<String, dynamic> _wholeDayStation = {
  'openingTimes': [
    {'text': 'Mo-So', 'start': '00:00:00', 'end': '00:00:00'},
  ],
  'wholeDay': true,
};

void main() {
  const adapter = GermanyOpeningHoursAdapter();

  test('is an OpeningHoursAdapter', () {
    expect(adapter, isA<OpeningHoursAdapter>());
  });

  group('recorded detail.php payload — Mo-Fr + combined Sa/So/Feiertag', () {
    late WeeklyOpeningHours result;
    setUp(() => result = adapter.parse(_tankerkoenigStation));

    test('Mo-Fr range expands to all five weekdays with the right hours', () {
      for (final d in const [
        OpeningDay.mon,
        OpeningDay.tue,
        OpeningDay.wed,
        OpeningDay.thu,
        OpeningDay.fri,
      ]) {
        final day = result.dayFor(d);
        expect(day, isNotNull, reason: '$d should be covered');
        expect(day!.state, DayState.openRanges);
        expect(day.ranges.single.startMinutes, 6 * 60);
        expect(day.ranges.single.endMinutes, 22 * 60);
      }
    });

    test('"Samstag, Sonntag, Feiertag" expands to {sat, sun, publicHoliday}',
        () {
      for (final d in const [OpeningDay.sat, OpeningDay.sun]) {
        final day = result.dayFor(d);
        expect(day, isNotNull, reason: '$d should be covered');
        expect(day!.state, DayState.openRanges);
        expect(day.ranges.single.startMinutes, 7 * 60);
        expect(day.ranges.single.endMinutes, 21 * 60);
      }
    });

    test('Feiertag → publicHoliday (OSM PH) with its own range', () {
      final ph = result.dayFor(OpeningDay.publicHoliday);
      expect(ph, isNotNull);
      expect(ph!.day, OpeningDay.publicHoliday);
      expect(ph.state, DayState.openRanges);
      expect(ph.ranges.single.startMinutes, 7 * 60);
      expect(ph.ranges.single.endMinutes, 21 * 60);
    });

    test('availability is full (all seven regular weekdays covered)', () {
      expect(result.availability, OpeningHoursAvailability.full);
    });

    test('overrides are not folded into the weekly cycle', () {
      // Only the seven weekdays + publicHoliday — no extra/garbage day rows.
      expect(result.days.map((d) => d.day).toSet(), {
        ...kRegularWeekdays,
        OpeningDay.publicHoliday,
      });
    });
  });

  group('wholeDay → 24/7', () {
    test('wholeDay:true → every regular weekday open24h, full', () {
      final result = adapter.parse(_wholeDayStation);
      for (final d in kRegularWeekdays) {
        expect(result.dayFor(d)?.state, DayState.open24h,
            reason: '$d should be open24h');
      }
      expect(result.availability, OpeningHoursAvailability.full);
    });

    test('wholeDay:true wins even with a partial openingTimes list', () {
      final result = adapter.parse({
        'wholeDay': true,
        'openingTimes': [
          {'text': 'Mo-Fr', 'start': '06:00:00', 'end': '20:00:00'},
        ],
      });
      expect(result.dayFor(OpeningDay.sun)?.state, DayState.open24h);
      expect(result.availability, OpeningHoursAvailability.full);
    });
  });

  group('per-row 24h marker', () {
    test('00:00:00-24:00:00 → open24h for its days', () {
      final result = adapter.parse({
        'openingTimes': [
          {'text': 'Mo-Fr', 'start': '00:00:00', 'end': '24:00:00'},
        ],
      });
      expect(result.dayFor(OpeningDay.mon)?.state, DayState.open24h);
      expect(result.dayFor(OpeningDay.fri)?.state, DayState.open24h);
    });
  });

  group('day-token grammar', () {
    test('"täglich" → all seven weekdays open for the row range', () {
      final result = adapter.parse({
        'openingTimes': [
          {'text': 'täglich', 'start': '05:00:00', 'end': '23:00:00'},
        ],
      });
      for (final d in kRegularWeekdays) {
        expect(result.dayFor(d)?.state, DayState.openRanges);
        expect(result.dayFor(d)?.ranges.single.startMinutes, 5 * 60);
      }
      expect(result.availability, OpeningHoursAvailability.full);
    });

    test('full German name range "Montag-Freitag" expands like Mo-Fr', () {
      final result = adapter.parse({
        'openingTimes': [
          {'text': 'Montag-Freitag', 'start': '08:00:00', 'end': '18:00:00'},
        ],
      });
      expect(result.dayFor(OpeningDay.mon)?.state, DayState.openRanges);
      expect(result.dayFor(OpeningDay.fri)?.state, DayState.openRanges);
      expect(result.dayFor(OpeningDay.sat), isNull);
      expect(result.availability, OpeningHoursAvailability.partial);
    });

    test('single full-name token "Samstag" maps to sat only', () {
      final result = adapter.parse({
        'openingTimes': [
          {'text': 'Samstag', 'start': '08:00:00', 'end': '14:00:00'},
        ],
      });
      expect(result.dayFor(OpeningDay.sat)?.ranges.single.endMinutes, 14 * 60);
      expect(result.dayFor(OpeningDay.mon), isNull);
    });

    test('split shifts (two rows, same day) coalesce into one DayHours', () {
      final result = adapter.parse({
        'openingTimes': [
          {'text': 'Mo', 'start': '08:00:00', 'end': '12:00:00'},
          {'text': 'Mo', 'start': '14:00:00', 'end': '18:00:00'},
        ],
      });
      final mon = result.dayFor(OpeningDay.mon);
      expect(mon!.state, DayState.openRanges);
      expect(mon.ranges, hasLength(2));
      expect(mon.ranges[0].startMinutes, 8 * 60);
      expect(mon.ranges[1].startMinutes, 14 * 60);
    });

    test('bare openingTimes List (no wholeDay) still parses', () {
      final result = adapter.parse([
        {'text': 'Mo-So', 'start': '06:00:00', 'end': '22:00:00'},
      ]);
      expect(result.dayFor(OpeningDay.sun)?.ranges.single.startMinutes, 6 * 60);
      expect(result.availability, OpeningHoursAvailability.full);
    });
  });

  group('graceful no-data (never throws, never null)', () {
    test('empty wrapping map → notAvailable', () {
      expect(adapter.parse(const <String, dynamic>{}),
          WeeklyOpeningHours.notAvailable);
    });

    test('empty openingTimes list → notAvailable', () {
      expect(adapter.parse({'openingTimes': const <dynamic>[]}),
          WeeklyOpeningHours.notAvailable);
    });

    test('null → notAvailable', () {
      expect(adapter.parse(null), WeeklyOpeningHours.notAvailable);
    });

    test('rows with only unrecognised day labels → notAvailable', () {
      final result = adapter.parse({
        'openingTimes': [
          {'text': 'Funday', 'start': '06:00:00', 'end': '22:00:00'},
        ],
      });
      expect(result, WeeklyOpeningHours.notAvailable);
    });

    // Mandatory never-throws fault-injection (#2349): garbage of every wrong
    // type must return normally AND degrade to notAvailable.
    test('garbage shapes (int / list / nested junk) return normally', () {
      expect(() => adapter.parse(42), returnsNormally);
      expect(() => adapter.parse('a bare string'), returnsNormally);
      expect(() => adapter.parse([1, 2, 3]), returnsNormally);
      expect(() => adapter.parse({'openingTimes': 'not a list'}),
          returnsNormally);
      expect(
        () => adapter.parse({
          'openingTimes': [
            {'text': null, 'start': 123, 'end': const <dynamic>[]},
            'not even a map',
          ],
          'wholeDay': 'maybe',
        }),
        returnsNormally,
      );
    });

    test('garbage shapes degrade to notAvailable', () {
      expect(adapter.parse(42), WeeklyOpeningHours.notAvailable);
      expect(adapter.parse([1, 2, 3]), WeeklyOpeningHours.notAvailable);
      expect(adapter.parse({'openingTimes': 'not a list'}),
          WeeklyOpeningHours.notAvailable);
      expect(
        adapter.parse({
          'openingTimes': [
            {'text': 'Mo-Fr', 'start': 'garbage', 'end': 'junk'},
          ],
        }),
        WeeklyOpeningHours.notAvailable,
      );
    });
  });
}
