// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../l10n/app_localizations.dart';
import '../../domain/open_now.dart';
import '../../../../core/domain/opening_hours.dart';

/// Pure formatting helpers shared by the opening-hours display widgets
/// (Epic #2707 C2, #2709). Kept separate from the widget tree so the
/// formatting logic is unit-friendly and the view files stay within the
/// 400-line cap.

/// Minutes-from-midnight → a zero-padded `HH:mm` 24h clock string. Wraps a
/// value ≥ 1440 back into the day so an overnight `endMinutes` formats
/// sanely.
String formatHhmm(int minutes) {
  final m = minutes % minutesPerDay;
  final h = (m ~/ 60).toString().padLeft(2, '0');
  final mm = (m % 60).toString().padLeft(2, '0');
  return '$h:$mm';
}

/// A single interval rendered as `06:30–19:30` (en-dash, no spaces — the
/// design-system separator for a same-row time span).
String formatRange(TimeRange r) =>
    '${formatHhmm(r.startMinutes)}–${formatHhmm(r.endMinutes)}';

/// The localized full weekday name (e.g. "Monday"), falling back to English
/// when [l10n] is null. [OpeningDay.publicHoliday] maps to the holidays
/// label.
String fullDayName(OpeningDay day, AppLocalizations l10n) {
  switch (day) {
    case OpeningDay.mon:
      return l10n.dayMon;
    case OpeningDay.tue:
      return l10n.dayTue;
    case OpeningDay.wed:
      return l10n.dayWed;
    case OpeningDay.thu:
      return l10n.dayThu;
    case OpeningDay.fri:
      return l10n.dayFri;
    case OpeningDay.sat:
      return l10n.daySat;
    case OpeningDay.sun:
      return l10n.daySun;
    case OpeningDay.publicHoliday:
      return l10n.publicHolidays;
  }
}

/// The localized abbreviated weekday name (e.g. "Mon"), falling back to
/// English when [l10n] is null.
String shortDayName(OpeningDay day, AppLocalizations l10n) {
  switch (day) {
    case OpeningDay.mon:
      return l10n.dayShortMon;
    case OpeningDay.tue:
      return l10n.dayShortTue;
    case OpeningDay.wed:
      return l10n.dayShortWed;
    case OpeningDay.thu:
      return l10n.dayShortThu;
    case OpeningDay.fri:
      return l10n.dayShortFri;
    case OpeningDay.sat:
      return l10n.dayShortSat;
    case OpeningDay.sun:
      return l10n.dayShortSun;
    case OpeningDay.publicHoliday:
      return l10n.publicHolidays;
  }
}

/// One day's hours as a single display string: "Closed" / "Open 24 hours" /
/// the joined intervals (split-shift days joined with " · "), or "Hours
/// unknown" for a missing/empty/unknown day.
String dayValueText(DayHours? day, AppLocalizations l10n) {
  if (day == null || day.state == DayState.unknown) {
    return l10n.openHoursUnknown;
  }
  switch (day.state) {
    case DayState.closed:
      return l10n.closedLabel;
    case DayState.open24h:
      return l10n.open24Hours;
    case DayState.openRanges:
      final usable = day.ranges.where((r) => !r.isDegenerate).toList();
      if (usable.isEmpty) {
        return l10n.openHoursUnknown;
      }
      return usable.map(formatRange).join(' · ');
    case DayState.unknown:
      return l10n.openHoursUnknown;
  }
}
