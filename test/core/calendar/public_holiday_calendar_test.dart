// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/calendar/public_holiday_calendar.dart';

/// Verifies every fixed-date holiday documented in
/// [PublicHolidayCalendar] resolves correctly per supported country
/// and that null/unknown countries fall through safely.
void main() {
  group('PublicHolidayCalendar — universal holidays', () {
    test('Jan 1 is a holiday everywhere, even with null country', () {
      expect(
        PublicHolidayCalendar.isPublicHoliday(DateTime(2026, 1, 1), null),
        isTrue,
      );
      expect(
        PublicHolidayCalendar.isPublicHoliday(DateTime(2026, 1, 1), 'DE'),
        isTrue,
      );
      expect(
        PublicHolidayCalendar.isPublicHoliday(DateTime(2026, 1, 1), 'FR'),
        isTrue,
      );
    });

    test('Dec 25 is a holiday everywhere, even with null country', () {
      expect(
        PublicHolidayCalendar.isPublicHoliday(DateTime(2026, 12, 25), null),
        isTrue,
      );
      expect(
        PublicHolidayCalendar.isPublicHoliday(DateTime(2026, 12, 25), 'IT'),
        isTrue,
      );
    });
  });

  group('PublicHolidayCalendar — national fixed dates', () {
    final cases = <(String code, DateTime date, String label)>[
      ('DE', DateTime(2026, 10, 3), 'Tag der Deutschen Einheit'),
      ('FR', DateTime(2026, 7, 14), 'Bastille Day'),
      ('IT', DateTime(2026, 6, 2), 'Festa della Repubblica'),
      ('ES', DateTime(2026, 10, 12), 'Fiesta Nacional'),
      ('AT', DateTime(2026, 10, 26), 'Nationalfeiertag'),
      ('BE', DateTime(2026, 7, 21), 'Nationale feestdag'),
      ('NL', DateTime(2026, 4, 27), 'Koningsdag'),
      ('LU', DateTime(2026, 6, 23), 'National Day'),
      ('PL', DateTime(2026, 5, 3), 'Constitution Day'),
    ];

    for (final c in cases) {
      test('${c.$1}: ${c.$3} on ${c.$2.year}-${c.$2.month}-${c.$2.day}', () {
        expect(
          PublicHolidayCalendar.isPublicHoliday(c.$2, c.$1),
          isTrue,
          reason: '${c.$3} should be a holiday in ${c.$1}',
        );
      });

      test('${c.$1}: ${c.$3} is NOT a holiday in another country', () {
        // National holidays are country-specific. Jul 14 in DE is not a
        // holiday, etc. Use a country that has no fixed date on the same
        // day to avoid coincidental overlap.
        final foreign = c.$1 == 'DE' ? 'FR' : 'DE';
        // Skip when the foreign country shares the universal Jan 1 / Dec 25.
        final isUniversal = (c.$2.month == 1 && c.$2.day == 1) ||
            (c.$2.month == 12 && c.$2.day == 25);
        if (isUniversal) return;
        expect(
          PublicHolidayCalendar.isPublicHoliday(c.$2, foreign),
          isFalse,
          reason: '${c.$3} is not a public holiday in $foreign',
        );
      });
    }
  });

  group('PublicHolidayCalendar — non-holidays', () {
    test('returns false for an arbitrary mid-week non-holiday date', () {
      // 2026-03-17 (Tuesday) — no fixed-date holiday in any supported
      // country.
      expect(
        PublicHolidayCalendar.isPublicHoliday(DateTime(2026, 3, 17), 'DE'),
        isFalse,
      );
      expect(
        PublicHolidayCalendar.isPublicHoliday(DateTime(2026, 3, 17), 'FR'),
        isFalse,
      );
    });

    test('returns false when countryCode is null and date is not universal',
        () {
      // Jul 14 is FR-only; without a country we cannot tell.
      expect(
        PublicHolidayCalendar.isPublicHoliday(DateTime(2026, 7, 14), null),
        isFalse,
      );
    });

    test('returns false for an unknown country code', () {
      // 'XX' is not a registered country; the lookup table should miss
      // and return false rather than throw.
      expect(
        PublicHolidayCalendar.isPublicHoliday(DateTime(2026, 7, 14), 'XX'),
        isFalse,
      );
    });
  });

  group('PublicHolidayCalendar — case insensitivity', () {
    test('lowercase country code resolves the same as uppercase', () {
      expect(
        PublicHolidayCalendar.isPublicHoliday(DateTime(2026, 10, 3), 'de'),
        isTrue,
      );
      expect(
        PublicHolidayCalendar.isPublicHoliday(DateTime(2026, 10, 3), 'De'),
        isTrue,
      );
    });
  });

  group('PublicHolidayCalendar — year-agnostic', () {
    test('Bastille Day works in any year', () {
      for (final y in [1999, 2025, 2030]) {
        expect(
          PublicHolidayCalendar.isPublicHoliday(DateTime(y, 7, 14), 'FR'),
          isTrue,
          reason: 'Jul 14 $y should be a holiday in FR',
        );
      }
    });
  });
}
