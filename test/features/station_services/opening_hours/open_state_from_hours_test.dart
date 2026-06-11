// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/station_detail/domain/opening_hours.dart';
import 'package:tankstellen/features/station_services/opening_hours/open_state_from_hours.dart';

void main() {
  // Wednesday 2026-06-10; minutes chosen against a 07:00-19:00 day.
  final wedMorning = DateTime(2026, 6, 10, 10, 0);
  final wedNight = DateTime(2026, 6, 10, 3, 0);

  WeeklyOpeningHours weekday7to19() => WeeklyOpeningHours(
        days: [
          for (final d in kRegularWeekdays)
            DayHours(
              day: d,
              state: DayState.openRanges,
              ranges: const [
                TimeRange(startMinutes: 7 * 60, endMinutes: 19 * 60),
              ],
            ),
        ],
        availability: OpeningHoursAvailability.full,
      );

  group('openStateFromHours (#3198)', () {
    test('null hours → null (honest unknown, never true)', () {
      expect(openStateFromHours(null, wedMorning), isNull);
    });

    test('inside the schedule → true', () {
      expect(openStateFromHours(weekday7to19(), wedMorning), isTrue);
    });

    test('outside the schedule → false', () {
      expect(openStateFromHours(weekday7to19(), wedNight), isFalse);
    });

    test('24/7 schedule → true at any instant', () {
      final allWeek = WeeklyOpeningHours.allWeek24h();
      expect(openStateFromHours(allWeek, wedNight), isTrue);
      expect(openStateFromHours(allWeek, wedMorning), isTrue);
    });

    test('no-data sentinel → null (unknown), not closed', () {
      expect(
        openStateFromHours(WeeklyOpeningHours.notAvailable, wedMorning),
        isNull,
      );
    });

    test('all-days-unknown schedule → null', () {
      final unknownWeek = WeeklyOpeningHours(
        days: [
          for (final d in kRegularWeekdays)
            DayHours(day: d, state: DayState.unknown),
        ],
        availability: OpeningHoursAvailability.partial,
      );
      expect(openStateFromHours(unknownWeek, wedMorning), isNull);
    });

    // Fault injection for the documented never-throws contract: feed the
    // degenerate / adversarial shapes adapters can emit (empty schedule
    // flagged full, degenerate FR 01:00-01:00 sentinel ranges, a
    // publicHoliday-only schedule) and assert the call returns normally.
    test('never throws on degenerate or adversarial schedules', () {
      final degenerate = WeeklyOpeningHours(
        days: [
          DayHours(
            day: OpeningDay.mon,
            state: DayState.openRanges,
            // The FR `01:00-01:00` no-interval sentinel.
            ranges: const [TimeRange(startMinutes: 60, endMinutes: 60)],
          ),
          const DayHours(day: OpeningDay.publicHoliday, state: DayState.closed),
        ],
        availability: OpeningHoursAvailability.full,
      );
      expect(() => openStateFromHours(degenerate, wedMorning),
          returnsNormally);
      const emptyButFull =
          WeeklyOpeningHours(availability: OpeningHoursAvailability.full);
      expect(() => openStateFromHours(emptyButFull, wedNight),
          returnsNormally);
      expect(openStateFromHours(emptyButFull, wedNight), isNull);
    });

    test('an overnight wrap from yesterday counts as open', () {
      // Tue 22:00 - Wed 04:00; probe Wednesday 03:00.
      final overnight = WeeklyOpeningHours(
        days: const [
          DayHours(
            day: OpeningDay.tue,
            state: DayState.openRanges,
            ranges: [TimeRange(startMinutes: 22 * 60, endMinutes: 4 * 60)],
          ),
        ],
        availability: OpeningHoursAvailability.partial,
      );
      expect(openStateFromHours(overnight, wedNight), isTrue);
    });
  });
}
