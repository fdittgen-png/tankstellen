// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/opening_hours.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/opening_hours_view.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  // A Wednesday — `DateTime.weekday == 3`. Used as the fixed `now` so the
  // status line and today-emphasis are deterministic.
  final wednesday = DateTime(2026, 6, 3, 10, 0); // 2026-06-03 is a Wed.

  // Mon–Fri 06:30–19:30, Sat 07:00–13:00, Sun closed.
  WeeklyOpeningHours businessWeek() => WeeklyOpeningHours(
        availability: OpeningHoursAvailability.full,
        days: [
          for (final d in const [
            OpeningDay.mon,
            OpeningDay.tue,
            OpeningDay.wed,
            OpeningDay.thu,
            OpeningDay.fri,
          ])
            DayHours(
              day: d,
              state: DayState.openRanges,
              ranges: const [
                TimeRange(startMinutes: 6 * 60 + 30, endMinutes: 19 * 60 + 30),
              ],
            ),
          const DayHours(
            day: OpeningDay.sat,
            state: DayState.openRanges,
            ranges: [TimeRange(startMinutes: 7 * 60, endMinutes: 13 * 60)],
          ),
          DayHours.closedDay(OpeningDay.sun),
        ],
      );

  group('OpeningHoursView — status line', () {
    testWidgets('open → "Open · Closes 19:30"', (tester) async {
      await pumpApp(
        tester,
        SingleChildScrollView(
          child: OpeningHoursView(hours: businessWeek(), now: wednesday),
        ),
      );

      expect(find.byKey(const ValueKey('opening-hours-status-line')),
          findsOneWidget);
      // RichText splits the headline + detail across spans; assert on the
      // composed text via the rich-text matcher.
      expect(
        find.textContaining('Open', findRichText: true),
        findsWidgets,
      );
      expect(
        find.textContaining('Closes 19:30', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('closing soon → amber, still "Closes …"', (tester) async {
      // 19:00 on a Wednesday → closes 19:30, i.e. 30 min away (< 60).
      final soon = DateTime(2026, 6, 3, 19, 0);
      await pumpApp(
        tester,
        SingleChildScrollView(
          child: OpeningHoursView(hours: businessWeek(), now: soon),
        ),
      );
      expect(
        find.textContaining('Closes 19:30', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('closed today, opens later same day → "Opens 06:30"',
        (tester) async {
      // 05:00 Wednesday → before today's 06:30 open.
      final early = DateTime(2026, 6, 3, 5, 0);
      await pumpApp(
        tester,
        SingleChildScrollView(
          child: OpeningHoursView(hours: businessWeek(), now: early),
        ),
      );
      expect(
        find.textContaining('Closed', findRichText: true),
        findsWidgets,
      );
      expect(
        find.textContaining('Opens 06:30', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('closed, opens another day → "Opens Mon 06:30"',
        (tester) async {
      // Sunday 12:00 — Sunday is closed, next opening is Monday 06:30.
      final sunday = DateTime(2026, 6, 7, 12, 0); // 2026-06-07 is a Sunday.
      await pumpApp(
        tester,
        SingleChildScrollView(
          child: OpeningHoursView(hours: businessWeek(), now: sunday),
        ),
      );
      expect(
        find.textContaining('Opens Mon 06:30', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('unknown schedule → status line hidden', (tester) async {
      // Every regular day unknown, but a holiday row keeps the view off the
      // no-data path → the status line must hide while the table renders.
      final unknown = WeeklyOpeningHours(
        availability: OpeningHoursAvailability.partial,
        days: [
          for (final d in kRegularWeekdays)
            DayHours(day: d, state: DayState.unknown),
          DayHours.closedDay(OpeningDay.publicHoliday),
        ],
      );
      await pumpApp(
        tester,
        SingleChildScrollView(
          child: OpeningHoursView(hours: unknown, now: wednesday),
        ),
      );
      expect(find.byKey(const ValueKey('opening-hours-status-line')),
          findsNothing);
    });
  });

  group('OpeningHoursView — 24 hours', () {
    testWidgets('all-day-24h → single row + badge, not 7 rows',
        (tester) async {
      await pumpApp(
        tester,
        SingleChildScrollView(
          child: OpeningHoursView(
            hours: WeeklyOpeningHours.allWeek24h(),
            now: wednesday,
          ),
        ),
      );

      expect(find.byKey(const ValueKey('opening-hours-24h-row')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('opening-hours-24h-badge')),
          findsOneWidget);
      expect(find.text('Open 24 hours'), findsOneWidget);
      expect(find.text('24h'), findsOneWidget);
      // No collapsed-week expand affordance for a 24/7 station.
      expect(find.byKey(const ValueKey('opening-hours-expand-toggle')),
          findsNothing);
    });
  });

  group('OpeningHoursView — collapsed week', () {
    testWidgets('groups Mon–Fri into one row', (tester) async {
      await pumpApp(
        tester,
        SingleChildScrollView(
          child: OpeningHoursView(hours: businessWeek(), now: wednesday),
        ),
      );

      // Collapsed: a "Mon – Fri" span, a "Sat" row, and a "Sun" row.
      expect(find.text('Mon – Fri'), findsOneWidget);
      expect(find.text('Sat'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
      // The grouped weekdays render their joined range.
      expect(find.text('06:30–19:30'), findsOneWidget);
      expect(find.text('07:00–13:00'), findsOneWidget);
      // Sunday is closed.
      expect(find.text('Closed'), findsOneWidget);
      // The full per-day names are NOT shown until expanded.
      expect(find.text('Monday'), findsNothing);
    });

    testWidgets('expanding shows the full per-day table', (tester) async {
      await pumpApp(
        tester,
        SingleChildScrollView(
          child: OpeningHoursView(hours: businessWeek(), now: wednesday),
        ),
      );

      await tester.tap(
          find.byKey(const ValueKey('opening-hours-expand-toggle')));
      await tester.pumpAndSettle();

      // Every weekday now has its own full-name row.
      expect(find.text('Monday'), findsOneWidget);
      expect(find.text('Friday'), findsOneWidget);
      expect(find.text('Sunday'), findsOneWidget);
      // The Mon–Fri span is gone now that days are individual.
      expect(find.text('Mon – Fri'), findsNothing);
    });

    testWidgets('split-shift day joins ranges with " · "', (tester) async {
      final lunchBreak = WeeklyOpeningHours(
        availability: OpeningHoursAvailability.full,
        days: [
          for (final d in kRegularWeekdays)
            DayHours(
              day: d,
              state: DayState.openRanges,
              ranges: const [
                TimeRange(startMinutes: 8 * 60, endMinutes: 12 * 60),
                TimeRange(startMinutes: 14 * 60, endMinutes: 18 * 60),
              ],
            ),
        ],
      );
      await pumpApp(
        tester,
        SingleChildScrollView(
          child: OpeningHoursView(hours: lunchBreak, now: wednesday),
        ),
      );
      expect(find.text('08:00–12:00 · 14:00–18:00'), findsOneWidget);
    });
  });

  group('OpeningHoursView — holiday + no-data', () {
    testWidgets('public-holiday row rendered from publicHoliday day',
        (tester) async {
      final withHoliday = businessWeek().copyWith(
        days: [
          ...businessWeek().days,
          DayHours.closedDay(OpeningDay.publicHoliday),
        ],
      );
      await pumpApp(
        tester,
        SingleChildScrollView(
          child: OpeningHoursView(hours: withHoliday, now: wednesday),
        ),
      );
      expect(find.byKey(const ValueKey('opening-hours-holiday-row')),
          findsOneWidget);
      expect(find.text('Public holidays'), findsOneWidget);
    });

    testWidgets('notProvided → muted "Opening hours not available"',
        (tester) async {
      await pumpApp(
        tester,
        SingleChildScrollView(
          child: OpeningHoursView(
            hours: WeeklyOpeningHours.notAvailable,
            now: wednesday,
          ),
        ),
      );
      expect(find.byKey(const ValueKey('opening-hours-not-available')),
          findsOneWidget);
      expect(find.text('Opening hours not available'), findsOneWidget);
      // It is NOT a fake table — no expand affordance, no day rows.
      expect(find.byKey(const ValueKey('opening-hours-expand-toggle')),
          findsNothing);
    });
  });

  group('OpeningHoursView — 24/7 automate (#2742)', () {
    testWidgets(
        'automate + staffed → "24/7 automate" line AND the staffed schedule '
        'AND Sunday "Closed", never a lone "Open 24 hours" row', (tester) async {
      // The Esso 34120008 shape: pump 24/7, boutique Mon–Sat staffed, Sun
      // closed. automate24h is the orthogonal indicator.
      final esso = businessWeek().copyWith(automate24h: true);
      await pumpApp(
        tester,
        SingleChildScrollView(
          child: OpeningHoursView(hours: esso, now: wednesday),
        ),
      );

      // The new 24/7-automate line is present …
      expect(find.byKey(const ValueKey('opening-hours-automate-24h')),
          findsOneWidget);
      expect(find.text('24/7 automate'), findsOneWidget);
      // … alongside the staffed schedule (not collapsed to a single row) …
      expect(find.byKey(const ValueKey('opening-hours-24h-row')), findsNothing);
      expect(find.text('06:30–19:30'), findsOneWidget);
      expect(find.text('07:00–13:00'), findsOneWidget);
      // … and Sunday renders as Closed (Fermé).
      expect(find.text('Closed'), findsOneWidget);
    });

    testWidgets('pump-only all-week-24h + automate → single row + both badges',
        (tester) async {
      await pumpApp(
        tester,
        SingleChildScrollView(
          child: OpeningHoursView(
            hours: WeeklyOpeningHours.allWeek24h(automate24h: true),
            now: wednesday,
          ),
        ),
      );
      // Pump-only: the single 24h row + 24h badge are kept …
      expect(find.byKey(const ValueKey('opening-hours-24h-row')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('opening-hours-24h-badge')),
          findsOneWidget);
      // … plus the explicit automate line.
      expect(find.byKey(const ValueKey('opening-hours-automate-24h')),
          findsOneWidget);
    });

    testWidgets('no automate → no "24/7 automate" line', (tester) async {
      await pumpApp(
        tester,
        SingleChildScrollView(
          child: OpeningHoursView(hours: businessWeek(), now: wednesday),
        ),
      );
      expect(find.byKey(const ValueKey('opening-hours-automate-24h')),
          findsNothing);
    });
  });

  group('OpeningHoursView — today emphasis', () {
    testWidgets('today (Wed) row is bold via its accent bar', (tester) async {
      await pumpApp(
        tester,
        SingleChildScrollView(
          child: OpeningHoursView(hours: businessWeek(), now: wednesday),
        ),
      );
      // Wednesday falls inside the collapsed "Mon – Fri" span → that row is
      // the emphasised one. Its value text renders in bold weight.
      final rangeText = tester.widget<Text>(find.text('06:30–19:30'));
      expect(rangeText.style?.fontWeight, FontWeight.w700);
    });
  });
}
