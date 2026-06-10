// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../station_detail/domain/opening_hours.dart';
import '../opening_hours/opening_hours_adapter.dart';

/// Normalises the German Tankerkönig (`detail.php`) opening-hours payload into
/// the common [WeeklyOpeningHours] model (Epic #2707 C5, #2712).
///
/// ## Accepted input shapes
/// Tankerkönig's detail response carries opening hours in an `openingTimes[]`
/// array plus a `wholeDay` boolean. Each `openingTimes` entry is a map
/// `{text, start, end}` where `start`/`end` are **`HH:MM:SS`** 24-hour clocks
/// and `text` is a German day-range label. [parse] accepts, in order of
/// preference:
///   - the wrapping `Map` `{'openingTimes': [...], 'wholeDay': bool}` — the
///     shape closest to the raw `detail.php` `station` object, so the
///     `wholeDay` flag is honoured; or
///   - a bare `List` of `openingTimes` entries (each an [OpeningTime]-shaped
///     `Map`), with no `wholeDay` signal.
///
/// (`overrides[]` are free-form temporary-closure date ranges, e.g.
/// `"13.04.2017, 15:00:00 - 13.11.2017, 15:00:00: geschlossen"`; they are not
/// a weekly schedule and are intentionally not mapped onto the Mon–Sun cycle.)
///
/// ## `text` day-range grammar (verified against the live `detail.php` feed)
/// The `text` field is a comma-separated list of day tokens; each token is a
/// single day or a `<from>-<to>` range, mixing short codes and full German
/// names within one feed:
///   - short codes `Mo Di Mi Do Fr Sa So` (and ranges `Mo-Fr`, `Mo-Sa`);
///   - full names `Montag … Sonntag` (and ranges `Montag-Freitag`);
///   - `Feiertag` / `Feiertage` → the OSM `PH` [OpeningDay.publicHoliday];
///   - `täglich` / `Täglich` → all seven regular weekdays;
///   - a combined `"Samstag, Sonntag, Feiertag"` list → {sat, sun, PH}.
/// Every day a token resolves to gets that entry's [TimeRange].
///
/// ## Time-range semantics (grounded on the feed, not assumed)
///   - `wholeDay == true` → [WeeklyOpeningHours.allWeek24h] outright (the
///     station's around-the-clock marker wins over any per-row range).
///   - a row `00:00:00-24:00:00` (or whole-day `00:00:00-00:00:00`) →
///     [DayState.open24h] for its days.
///   - any other valid `HH:MM:SS-HH:MM:SS` → [DayState.openRanges]; split
///     shifts (two rows touching the same day) coalesce into that day's
///     [DayHours.ranges].
///
/// ## Contract
/// Pure, total, never throws, never returns `null` — unparseable / empty
/// input degrades to [WeeklyOpeningHours.notAvailable] (the
/// [OpeningHoursAdapter] contract).
class GermanyOpeningHoursAdapter extends OpeningHoursAdapter {
  const GermanyOpeningHoursAdapter();

  /// Short Tankerkönig day codes → [OpeningDay].
  static const Map<String, OpeningDay> _shortCodes = {
    'mo': OpeningDay.mon,
    'di': OpeningDay.tue,
    'mi': OpeningDay.wed,
    'do': OpeningDay.thu,
    'fr': OpeningDay.fri,
    'sa': OpeningDay.sat,
    'so': OpeningDay.sun,
  };

  /// Full German day names → [OpeningDay]. `feiertag(e)` is the OSM `PH`
  /// public-holiday pseudo-day; `täglich` expands to all seven weekdays
  /// (handled in [_daysFromToken]).
  static const Map<String, OpeningDay> _fullNames = {
    'montag': OpeningDay.mon,
    'dienstag': OpeningDay.tue,
    'mittwoch': OpeningDay.wed,
    'donnerstag': OpeningDay.thu,
    'freitag': OpeningDay.fri,
    'samstag': OpeningDay.sat,
    'sonntag': OpeningDay.sun,
    'feiertag': OpeningDay.publicHoliday,
    'feiertage': OpeningDay.publicHoliday,
  };

  @override
  WeeklyOpeningHours parse(dynamic rawProviderData) {
    try {
      final (rows, wholeDay) = _narrow(rawProviderData);

      // The around-the-clock flag wins outright.
      if (wholeDay) return WeeklyOpeningHours.allWeek24h();
      if (rows == null || rows.isEmpty) {
        return WeeklyOpeningHours.notAvailable;
      }

      // Accumulate per day: a 24h marker, or coalesced ranges (split shifts).
      final open24h = <OpeningDay>{};
      final ranges = <OpeningDay, List<TimeRange>>{};
      final seen = <OpeningDay>{};

      for (final row in rows) {
        final days = _daysFromText(row.text);
        if (days.isEmpty) continue;

        final start = _minutesFromClock(row.start);
        final end = _minutesFromClock(row.end);
        if (start == null || end == null) continue;

        final is24h = _isWholeDayRange(start, end);
        TimeRange? range;
        if (!is24h) {
          range = TimeRange(startMinutes: start, endMinutes: end);
          if (range.isDegenerate) range = null; // no real interval → skip
        }

        for (final day in days) {
          seen.add(day);
          if (is24h) {
            open24h.add(day);
          } else if (range != null) {
            (ranges[day] ??= <TimeRange>[]).add(range);
          }
        }
      }

      if (seen.isEmpty) return WeeklyOpeningHours.notAvailable;

      final days = <DayHours>[];
      for (final day in _daysInDisplayOrder(seen)) {
        if (open24h.contains(day)) {
          days.add(DayHours.allDay(day));
          continue;
        }
        final dayRanges = ranges[day];
        if (dayRanges == null || dayRanges.isEmpty) {
          // The day appeared but carried only a degenerate / no-interval row.
          days.add(DayHours(day: day, state: DayState.unknown));
        } else {
          days.add(
            DayHours(day: day, state: DayState.openRanges, ranges: dayRanges),
          );
        }
      }

      if (days.isEmpty) return WeeklyOpeningHours.notAvailable;

      final coversAllWeekdays = kRegularWeekdays.every(seen.contains);
      return WeeklyOpeningHours(
        days: days,
        availability: coversAllWeekdays
            ? OpeningHoursAvailability.full
            : OpeningHoursAvailability.partial,
      );
    } catch (e, st) {
      // Contract: the adapter must never propagate a fault to the
      // station-detail UI — degrade to no-data, release-visibly (#3148).
      reportParseFailure('DE', e, st);
      return WeeklyOpeningHours.notAvailable;
    }
  }

  /// Narrows [raw] to `(rows, wholeDay)`. Accepts the wrapping `Map`
  /// (`{openingTimes, wholeDay}`) or a bare `List` of `{text,start,end}`
  /// entries; anything else → `(null, false)`.
  (List<_Row>?, bool) _narrow(dynamic raw) {
    if (raw is Map) {
      final inner = raw['openingTimes'];
      final wholeDay = raw['wholeDay'] == true;
      return (inner is List ? _rowsFromList(inner) : null, wholeDay);
    }
    if (raw is List) return (_rowsFromList(raw), false);
    return (null, false);
  }

  /// Maps a list of `openingTimes` entries into `{text,start,end}` rows.
  /// Non-map / blank-text entries are skipped.
  List<_Row> _rowsFromList(List<dynamic> list) {
    final rows = <_Row>[];
    for (final entry in list) {
      if (entry is! Map) continue;
      final text = entry['text']?.toString().trim() ?? '';
      if (text.isEmpty) continue;
      rows.add(_Row(
        text: text,
        start: entry['start']?.toString().trim() ?? '',
        end: entry['end']?.toString().trim() ?? '',
      ));
    }
    return rows;
  }

  /// Expands a `text` label (`"Mo-Fr"`, `"Samstag, Sonntag, Feiertag"`,
  /// `"täglich"`, …) into the set of [OpeningDay] it covers. Unrecognised
  /// tokens are ignored.
  Set<OpeningDay> _daysFromText(String text) {
    final out = <OpeningDay>{};
    for (final token in text.split(',')) {
      out.addAll(_daysFromToken(token.trim()));
    }
    return out;
  }

  /// One comma-separated token → its day set. A single day, a `from-to` range,
  /// or `täglich` (all weekdays). Empty on an unrecognised token.
  Set<OpeningDay> _daysFromToken(String token) {
    final key = token.toLowerCase();
    if (key.isEmpty) return const {};
    if (key == 'täglich' || key == 'taeglich') {
      return kRegularWeekdays.toSet();
    }

    final dash = token.indexOf('-');
    if (dash > 0 && dash < token.length - 1) {
      return _daysInRange(
        token.substring(0, dash).trim(),
        token.substring(dash + 1).trim(),
      );
    }

    final single = _dayFromName(key);
    return single == null ? const {} : {single};
  }

  /// Expands a `from`-`to` weekday range (`Mo-Fr`, `Montag-Freitag`) into the
  /// inclusive set of regular weekdays it spans (Mon-first cycle, no wrap).
  /// Empty when either bound is unrecognised or not a regular weekday.
  Set<OpeningDay> _daysInRange(String from, String to) {
    final start = _dayFromName(from.toLowerCase());
    final end = _dayFromName(to.toLowerCase());
    if (start == null || end == null) return const {};
    final si = kRegularWeekdays.indexOf(start);
    final ei = kRegularWeekdays.indexOf(end);
    if (si < 0 || ei < 0 || ei < si) return const {};
    return {for (var i = si; i <= ei; i++) kRegularWeekdays[i]};
  }

  /// A single day name (short code or full German name) → [OpeningDay].
  OpeningDay? _dayFromName(String key) =>
      _shortCodes[key] ?? _fullNames[key];

  /// The covered days in canonical display order: Mon..Sun, then publicHoliday.
  List<OpeningDay> _daysInDisplayOrder(Set<OpeningDay> seen) => [
        for (final d in kRegularWeekdays)
          if (seen.contains(d)) d,
        if (seen.contains(OpeningDay.publicHoliday)) OpeningDay.publicHoliday,
      ];

  /// True when `[start,end]` spans the whole day: `00:00:00-24:00:00`
  /// (`end == 1440`) or the `00:00:00-00:00:00` whole-day marker.
  bool _isWholeDayRange(int start, int end) =>
      (start == 0 && end == 1440) || (start == 0 && end == 0);

  /// `HH:MM:SS` (seconds optional) → minutes-from-midnight (0..1440; `24:00`
  /// → 1440), or `null` on a malformed clock. Seconds are accepted and
  /// dropped (the feed's per-second precision is irrelevant to weekly hours).
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

/// A normalised `{text,start,end}` opening-times row (internal to the adapter).
class _Row {
  const _Row({required this.text, required this.start, required this.end});
  final String text;
  final String start;
  final String end;
}
