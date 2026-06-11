// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/station_detail/domain/open_now.dart';
import 'package:tankstellen/core/domain/opening_hours.dart';

void main() {
  group('TimeRange', () {
    test('fromClock maps to minutes-from-midnight', () {
      final r = TimeRange.fromClock(
        startHour: 8,
        startMinute: 30,
        endHour: 19,
        endMinute: 30,
      );
      expect(r.startMinutes, 8 * 60 + 30);
      expect(r.endMinutes, 19 * 60 + 30);
      expect(r.isDegenerate, isFalse);
      expect(r.wrapsPastMidnight, isFalse);
    });

    test('degenerate range (FR 01:00-01:00) is flagged, never a wrap', () {
      const r = TimeRange(startMinutes: 60, endMinutes: 60);
      expect(r.isDegenerate, isTrue);
      expect(r.wrapsPastMidnight, isFalse);
    });

    test('wrapsPastMidnight when end <= start', () {
      final r = TimeRange.fromClock(
        startHour: 22,
        startMinute: 0,
        endHour: 4,
        endMinute: 0,
      );
      expect(r.wrapsPastMidnight, isTrue);
    });
  });

  group('WeeklyOpeningHours', () {
    test('notAvailable is the empty / notProvided sentinel', () {
      expect(WeeklyOpeningHours.notAvailable.days, isEmpty);
      expect(
        WeeklyOpeningHours.notAvailable.availability,
        OpeningHoursAvailability.notProvided,
      );
    });

    test('allWeek24h covers all seven regular weekdays as open24h', () {
      final w = WeeklyOpeningHours.allWeek24h();
      expect(w.days.length, 7);
      expect(w.availability, OpeningHoursAvailability.full);
      for (final d in kRegularWeekdays) {
        expect(w.dayFor(d)!.state, DayState.open24h);
      }
      expect(w.dayFor(OpeningDay.publicHoliday), isNull);
    });

    test('dayFor returns null for an uncovered day', () {
      const w = WeeklyOpeningHours(
        days: [DayHours(day: OpeningDay.mon, state: DayState.open24h)],
        availability: OpeningHoursAvailability.partial,
      );
      expect(w.dayFor(OpeningDay.tue), isNull);
    });

    test('json round-trips losslessly', () {
      final w = WeeklyOpeningHours(
        days: [
          DayHours(
            day: OpeningDay.mon,
            state: DayState.openRanges,
            ranges: [
              TimeRange.fromClock(
                startHour: 6,
                startMinute: 30,
                endHour: 19,
                endMinute: 30,
              ),
            ],
          ),
        ],
        availability: OpeningHoursAvailability.partial,
      );
      expect(WeeklyOpeningHours.fromJson(w.toJson()), w);
    });
  });

  group('openingDayFromIsoWeekday', () {
    test('maps ISO 1..7 onto Mon..Sun', () {
      expect(openingDayFromIsoWeekday(DateTime.monday), OpeningDay.mon);
      expect(openingDayFromIsoWeekday(DateTime.sunday), OpeningDay.sun);
    });
  });

  group('computeOpenNow', () {
    // 2026-06-01 10:00; we derive the weekday rather than assume it.
    final mid = DateTime(2026, 6, 1, 10, 0);
    final today = openingDayFromIsoWeekday(mid.weekday);

    DayHours dayRange(OpeningDay d, int sh, int sm, int eh, int em) => DayHours(
          day: d,
          state: DayState.openRanges,
          ranges: [
            TimeRange.fromClock(
              startHour: sh,
              startMinute: sm,
              endHour: eh,
              endMinute: em,
            ),
          ],
        );

    test('no data → unknown', () {
      expect(
        computeOpenNow(WeeklyOpeningHours.notAvailable, mid).status,
        OpenStatus.unknown,
      );
    });

    test('24/7 → open', () {
      expect(
        computeOpenNow(WeeklyOpeningHours.allWeek24h(), mid).status,
        OpenStatus.open,
      );
    });

    test('inside today range → open, closes at the range end', () {
      final w = WeeklyOpeningHours(
        days: [dayRange(today, 6, 30, 19, 30)],
        availability: OpeningHoursAvailability.full,
      );
      final r = computeOpenNow(w, mid);
      expect(r.status, OpenStatus.open);
      expect(r.nextChangeDay, today);
      expect(r.nextChangeMinutes, 19 * 60 + 30);
    });

    test('before today opening → closed, opens today at start', () {
      final early = DateTime(2026, 6, 1, 5, 0); // before 06:30
      final t = openingDayFromIsoWeekday(early.weekday);
      final w = WeeklyOpeningHours(
        days: [dayRange(t, 6, 30, 19, 30)],
        availability: OpeningHoursAvailability.full,
      );
      final r = computeOpenNow(w, early);
      expect(r.status, OpenStatus.closed);
      expect(r.nextChangeDay, t);
      expect(r.nextChangeMinutes, 6 * 60 + 30);
    });

    test('one closed day among unknown → closed (not unknown)', () {
      final w = WeeklyOpeningHours(
        days: [DayHours.closedDay(today)],
        availability: OpeningHoursAvailability.partial,
      );
      expect(computeOpenNow(w, mid).status, OpenStatus.closed);
    });

    test('overnight range from yesterday still covers early morning', () {
      // now = the day AFTER `mid`, at 02:00; yesterday has a 22:00-04:00 wrap.
      final nextDay = mid.add(const Duration(days: 1));
      final at0200 = DateTime(nextDay.year, nextDay.month, nextDay.day, 2, 0);
      final yesterday = openingDayFromIsoWeekday(mid.weekday);
      final w = WeeklyOpeningHours(
        days: [dayRange(yesterday, 22, 0, 4, 0)],
        availability: OpeningHoursAvailability.partial,
      );
      final r = computeOpenNow(w, at0200);
      expect(r.status, OpenStatus.open);
      expect(r.nextChangeMinutes, 4 * 60);
    });

    test('degenerate-only day is not open', () {
      const w = WeeklyOpeningHours(
        days: [
          DayHours(
            day: OpeningDay.mon,
            state: DayState.openRanges,
            ranges: [TimeRange(startMinutes: 60, endMinutes: 60)],
          ),
        ],
        availability: OpeningHoursAvailability.full,
      );
      // 01:00-01:00 carries no duration → never reports open.
      final at0100 = DateTime(2026, 6, 1, 1, 0);
      expect(computeOpenNow(w, at0100).status, isNot(OpenStatus.open));
    });
  });
}
