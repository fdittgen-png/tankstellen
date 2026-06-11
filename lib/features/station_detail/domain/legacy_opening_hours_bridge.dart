// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/domain/station.dart';
import '../../../core/domain/opening_hours.dart';

/// Synthesises a [WeeklyOpeningHours] from a [StationDetail]'s *legacy*
/// opening-hours fields (`Station.is24h` + `StationDetail.openingTimes`).
///
/// This is the migration bridge (Epic C1): country services that have not
/// yet shipped a dedicated [opening-hours adapter] keep populating only the
/// legacy fields, and the display layer (C2) can still render a structured
/// schedule via this synthesiser — so no country regresses before its
/// adapter lands.
///
/// The 11 countries with no opening-hours data today (GB, IT, DK, GR, RO,
/// SI, LU, AU, MX, AR, KR) carry none of these legacy fields either, so they
/// fall through to [WeeklyOpeningHours.notAvailable] and render the graceful
/// "Opening hours not available" line. That no-data path is locked by
/// `opening_hours_no_data_test.dart`; see `docs/guides/opening-hours.md` for
/// the per-country deferral list and when to revisit each one (#2716).
///
/// Mapping, in priority order:
///   1. If [StationDetail.openingHours] is already populated (an adapter ran)
///      and is not the no-data sentinel, it is returned unchanged.
///   2. `Station.is24h == true` → all seven regular weekdays [DayState.open24h]
///      ([WeeklyOpeningHours.allWeek24h], availability `full`).
///   3. Non-empty `openingTimes` → each parseable `start`/`end` becomes a
///      [TimeRange] applied to every regular weekday. The legacy
///      `OpeningTime.text` label is free-form / localized and not reliably
///      day-tagged across countries, so the bridge deliberately does **not**
///      try to map it to specific weekdays — it produces a best-effort
///      whole-week schedule flagged [OpeningHoursAvailability.partial].
///   4. Otherwise → [WeeklyOpeningHours.notAvailable].
///
/// Pure and total — never throws, never returns `null`.
WeeklyOpeningHours legacyOpeningHoursBridge(StationDetail detail) {
  final existing = detail.openingHours;
  if (existing != null &&
      existing.availability != OpeningHoursAvailability.notProvided) {
    return existing;
  }

  if (detail.station.is24h) {
    return WeeklyOpeningHours.allWeek24h();
  }

  final ranges = <TimeRange>[];
  for (final ot in detail.openingTimes) {
    final start = _minutesFromClock(ot.start);
    final end = _minutesFromClock(ot.end);
    if (start == null || end == null) continue;
    ranges.add(TimeRange(startMinutes: start, endMinutes: end));
  }

  if (ranges.isEmpty) return WeeklyOpeningHours.notAvailable;

  return WeeklyOpeningHours(
    days: [
      for (final day in kRegularWeekdays)
        DayHours(day: day, state: DayState.openRanges, ranges: ranges),
    ],
    availability: OpeningHoursAvailability.partial,
  );
}

/// Parses a legacy `HH:mm` or `HH:mm:ss` clock string into minutes-from
/// -midnight (0..1439), or `null` when it cannot be parsed. Never throws.
int? _minutesFromClock(String clock) {
  final parts = clock.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return hour * 60 + minute;
}
