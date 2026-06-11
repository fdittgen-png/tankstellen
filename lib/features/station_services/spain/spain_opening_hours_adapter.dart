// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../station_detail/domain/opening_hours.dart';
import '../opening_hours/opening_hours_adapter.dart';

/// Normalises the Spanish MITECO (geoportalgasolineras) `Horario` string into
/// the common [WeeklyOpeningHours] model (Epic #2707 C6, #2713).
///
/// ## Input shape (verified against live geoportalgasolineras station pages)
/// MITECO publishes opening hours as a single `Horario` **string**, not a
/// structured array. Each `;`-separated segment is `<days>: <hours>`, where
/// `<days>` is a Spanish day token or an inclusive range and `<hours>` is one
/// of `24H`, `Cerrado`, or one `HH:MM-HH:MM` clock range. Confirmed live forms:
///   - `'L-D: 24H'` — open all week, 24h.
///   - `'L-V: 06:00-23:00; S-D: 08:00-23:00'` — weekday + weekend ranges.
///   - `'L-V: 05:30-23:00; S: 06:30-22:30; D: 07:30-21:00'` — single-day
///     segments mixed with a range.
///   - `'Cerrado'` / a `…: Cerrado` segment — closed.
///
/// ## Spanish day tokens
/// `L`=lunes(mon), `M`=martes(tue), `X`=miércoles(wed), `J`=jueves(thu),
/// `V`=viernes(fri), `S`=sábado(sat), `D`=domingo(sun). A `A-B` token is the
/// inclusive Mon-first run from `A` to `B` (`L-V` → mon..fri, `S-D` → sat,sun,
/// `L-D` → the whole week). A backwards range (`B` before `A`) is ignored.
///
/// ## Hours semantics
///   - `24H` (any case) → [DayState.open24h].
///   - `Cerrado` (any case) → [DayState.closed].
///   - `HH:MM-HH:MM` → [DayState.openRanges] with one [TimeRange]; `24:00` is
///     accepted as the end-of-day marker. A degenerate equal-bounds range is
///     dropped (the day resolves to [DayState.unknown]), never a 24h wrap.
///   - Multiple segments touching the same day coalesce their ranges; the
///     first explicit 24h / closed marker for a day wins.
///
/// ## Contract
/// Pure, total, never throws, never returns `null` — empty / unparseable input
/// degrades to [WeeklyOpeningHours.notAvailable] (the [OpeningHoursAdapter]
/// contract). The adapter feeds the station-detail UI, so a malformed
/// `Horario` must degrade gracefully, never crash the screen.
class SpainOpeningHoursAdapter extends OpeningHoursAdapter {
  const SpainOpeningHoursAdapter();

  /// Single Spanish day token → [OpeningDay]. Lower-cased before lookup.
  static const Map<String, OpeningDay> _dayByToken = {
    'l': OpeningDay.mon,
    'm': OpeningDay.tue,
    'x': OpeningDay.wed,
    'j': OpeningDay.thu,
    'v': OpeningDay.fri,
    's': OpeningDay.sat,
    'd': OpeningDay.sun,
  };

  /// The whole-day open marker (any case).
  // i18n-ignore: MITECO feed enum token, not user-facing text
  static const String _open24hToken = '24h';

  /// The closed marker (any case).
  // i18n-ignore: MITECO feed enum token, not user-facing text
  static const String _closedToken = 'cerrado';

  @override
  WeeklyOpeningHours parse(dynamic rawProviderData) {
    try {
      if (rawProviderData is! String) return WeeklyOpeningHours.notAvailable;
      final raw = rawProviderData;
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return WeeklyOpeningHours.notAvailable;

      // A bare `Cerrado` (no day prefix) means the whole week is closed.
      if (trimmed.toLowerCase() == _closedToken) {
        return WeeklyOpeningHours(
          days: [for (final d in kRegularWeekdays) DayHours.closedDay(d)],
          availability: OpeningHoursAvailability.full,
          rawSource: raw,
        );
      }

      // A bare `24H` (no day prefix) means open all week.
      if (trimmed.toLowerCase() == _open24hToken) {
        return WeeklyOpeningHours.allWeek24h(rawSource: raw);
      }

      final states = <OpeningDay, DayState>{};
      final ranges = <OpeningDay, List<TimeRange>>{};
      var matchedAny = false;

      for (final segment in trimmed.split(';')) {
        if (!_applySegment(segment, states, ranges)) continue;
        matchedAny = true;
      }

      if (!matchedAny) return WeeklyOpeningHours.notAvailable;

      final days = <DayHours>[];
      for (final day in kRegularWeekdays) {
        final state = states[day];
        if (state == null) continue; // not covered → implicitly unknown
        if (state == DayState.openRanges) {
          final dayRanges = ranges[day] ?? const <TimeRange>[];
          // The day appeared only as a degenerate range → unknown.
          days.add(dayRanges.isEmpty
              ? DayHours(day: day, state: DayState.unknown)
              : DayHours(
                  day: day, state: DayState.openRanges, ranges: dayRanges));
        } else {
          days.add(DayHours(day: day, state: state));
        }
      }

      if (days.isEmpty) return WeeklyOpeningHours.notAvailable;

      final availability = days.length == kRegularWeekdays.length
          ? OpeningHoursAvailability.full
          : OpeningHoursAvailability.partial;
      return WeeklyOpeningHours(
        days: days,
        availability: availability,
        rawSource: raw,
      );
    } catch (e, st) {
      // Contract: the adapter must never propagate a fault to the
      // station-detail UI — degrade to no-data, release-visibly (#3148).
      reportParseFailure('ES', e, st);
      return WeeklyOpeningHours.notAvailable;
    }
  }

  /// Applies one `<days>: <hours>` segment to [states] / [ranges]. Returns
  /// `true` when the segment yielded at least one recognised day, else
  /// `false` (the caller tracks whether anything matched at all).
  bool _applySegment(
    String segment,
    Map<OpeningDay, DayState> states,
    Map<OpeningDay, List<TimeRange>> ranges,
  ) {
    final colon = segment.indexOf(':');
    if (colon < 0) return false;
    final daysPart = segment.substring(0, colon).trim();
    final hoursPart = segment.substring(colon + 1).trim();
    if (daysPart.isEmpty || hoursPart.isEmpty) return false;

    final days = _expandDays(daysPart);
    if (days.isEmpty) return false;

    final hoursLower = hoursPart.toLowerCase();
    var applied = false;

    if (hoursLower == _open24hToken) {
      for (final d in days) {
        states.putIfAbsent(d, () => DayState.open24h);
        applied = true;
      }
      return applied;
    }
    if (hoursLower == _closedToken) {
      for (final d in days) {
        states.putIfAbsent(d, () => DayState.closed);
        applied = true;
      }
      return applied;
    }

    final range = _parseRange(hoursPart);
    if (range == null) return false;
    for (final d in days) {
      states.putIfAbsent(d, () => DayState.openRanges);
      // Only coalesce ranges onto a day that is still range-typed (an earlier
      // explicit 24h / closed marker wins).
      if (states[d] != DayState.openRanges) continue;
      if (range.isDegenerate) {
        // No real interval: keep the day range-typed with no range so it
        // resolves to `unknown`, never a 24h wrap.
        ranges.putIfAbsent(d, () => <TimeRange>[]);
      } else {
        (ranges[d] ??= <TimeRange>[]).add(range);
      }
      applied = true;
    }
    return applied;
  }

  /// Expands a `<days>` token into the [OpeningDay]s it covers. A single token
  /// (`L`) → one day; an inclusive `A-B` range (`L-V`, `S-D`, `L-D`) → the
  /// Mon-first run from `A` to `B`. Unknown tokens / backwards ranges → empty.
  List<OpeningDay> _expandDays(String token) {
    final t = token.toLowerCase();
    final dash = t.indexOf('-');
    if (dash < 0) {
      final day = _dayByToken[t];
      return day == null ? const [] : [day];
    }
    final start = _dayByToken[t.substring(0, dash).trim()];
    final end = _dayByToken[t.substring(dash + 1).trim()];
    if (start == null || end == null) return const [];
    final from = kRegularWeekdays.indexOf(start);
    final to = kRegularWeekdays.indexOf(end);
    if (from < 0 || to < 0 || to < from) return const []; // backwards → ignore
    return kRegularWeekdays.sublist(from, to + 1);
  }

  /// Parses an `HH:MM-HH:MM` clock range, or `null` when malformed. `24:00`
  /// is accepted as the end-of-day marker (→ minute 1440).
  TimeRange? _parseRange(String hours) {
    final dash = hours.indexOf('-');
    if (dash < 0) return null;
    final start = _minutesFromClock(hours.substring(0, dash).trim());
    final end = _minutesFromClock(hours.substring(dash + 1).trim());
    if (start == null || end == null) return null;
    return TimeRange(startMinutes: start, endMinutes: end);
  }

  /// `HH:MM` → minutes-from-midnight (0..1440; `24:00` → 1440), or `null`.
  int? _minutesFromClock(String clock) {
    final parts = clock.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour == 24 && minute == 0) return 1440;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return hour * 60 + minute;
  }
}
