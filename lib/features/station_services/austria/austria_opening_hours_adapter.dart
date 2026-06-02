// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../station_detail/domain/opening_hours.dart';
import '../opening_hours/opening_hours_adapter.dart';

/// Normalises the Austrian E-Control (Spritpreisrechner) opening-hours feed
/// into the common [WeeklyOpeningHours] model (Epic C4, #2711).
///
/// ## Accepted input shapes
/// E-Control emits one row per day in an `openingHours[]` array; each row is
/// a map `{day, label, order, from, to}` where `label` is the full German
/// day name (`Montag` … `Sonntag`, plus `Feiertag` for public holidays),
/// `day` is the two-letter code (`MO,DI,MI,DO,FR,SA,SO,FE`), and `from`/`to`
/// are `HH:MM` 24-hour clock strings. This adapter accepts:
///   - the **structured** `List` of day rows (preferred), or its enclosing
///     `Map` (`{'openingHours': [...]}`), and
///   - the **joined German paragraph** the service historically produced
///     (`"Montag: 06:30-20:30, Dienstag: …, Feiertag: 06:30-20:30"`) as a
///     `String` fallback.
///
/// ## Time-range semantics (grounded on the live feed, not the issue text)
///   - `00:00-24:00` → [DayState.open24h] (the feed's whole-day marker).
///   - `00:00-00:00` → [DayState.closed]. The live feed uses an equal-bounds
///     pair to mean "not open that day" (verified against eni Floragasse's
///     Sunday/holiday rows), so a degenerate range is **closed**, never a
///     24-hour wrap. (#feedback_fake_services_false_green — honour the real
///     API, not the requested shape.)
///   - any other `HH:MM-HH:MM` → [DayState.openRanges] with one [TimeRange].
///   - a `geschlossen` / `closed` token → [DayState.closed].
///
/// ## Contract
/// Pure, total, never throws, never returns `null` — unparseable / empty
/// input degrades to [WeeklyOpeningHours.notAvailable] (the
/// [OpeningHoursAdapter] contract).
class AustriaOpeningHoursAdapter extends OpeningHoursAdapter {
  const AustriaOpeningHoursAdapter();

  /// Full German day labels → [OpeningDay]. `Feiertag` is the OSM `PH`
  /// public-holiday pseudo-day.
  static const Map<String, OpeningDay> _germanDayLabels = {
    'montag': OpeningDay.mon,
    'dienstag': OpeningDay.tue,
    'mittwoch': OpeningDay.wed,
    'donnerstag': OpeningDay.thu,
    'freitag': OpeningDay.fri,
    'samstag': OpeningDay.sat,
    'sonntag': OpeningDay.sun,
    'feiertag': OpeningDay.publicHoliday,
  };

  /// E-Control two-letter `day` codes → [OpeningDay] (secondary path when a
  /// row carries the code but no usable `label`).
  static const Map<String, OpeningDay> _germanDayCodes = {
    'mo': OpeningDay.mon,
    'di': OpeningDay.tue,
    'mi': OpeningDay.wed,
    'do': OpeningDay.thu,
    'fr': OpeningDay.fri,
    'sa': OpeningDay.sat,
    'so': OpeningDay.sun,
    'fe': OpeningDay.publicHoliday,
  };

  @override
  WeeklyOpeningHours parse(dynamic rawProviderData) {
    try {
      final rows = _extractRows(rawProviderData);
      if (rows == null || rows.isEmpty) return WeeklyOpeningHours.notAvailable;

      final byDay = <OpeningDay, DayHours>{};
      for (final row in rows) {
        final parsed = _parseRow(row);
        if (parsed == null) continue;
        // First occurrence of a day wins (the feed is one row per day).
        byDay.putIfAbsent(parsed.day, () => parsed);
      }

      if (byDay.isEmpty) return WeeklyOpeningHours.notAvailable;

      final coversAllWeekdays =
          kRegularWeekdays.every(byDay.containsKey);
      return WeeklyOpeningHours(
        days: byDay.values.toList(),
        availability: coversAllWeekdays
            ? OpeningHoursAvailability.full
            : OpeningHoursAvailability.partial,
        rawSource: rawProviderData is String ? rawProviderData : null,
      );
    } catch (e, st) {
      // The adapter must never propagate a fault to the station-detail UI.
      assert(() {
        // ignore: avoid_print
        print('AustriaOpeningHoursAdapter.parse failed: $e\n$st');
        return true;
      }());
      return WeeklyOpeningHours.notAvailable;
    }
  }

  /// Narrows [raw] to the list of per-day rows, or `null` when there is no
  /// usable shape. Accepts a `List`, a wrapping `Map`, or a joined String.
  List<Map<String, String>>? _extractRows(dynamic raw) {
    if (raw is List) return _rowsFromList(raw);
    if (raw is Map) {
      final inner = raw['openingHours'];
      if (inner is List) return _rowsFromList(inner);
      return null;
    }
    if (raw is String) return _rowsFromJoinedString(raw);
    return null;
  }

  /// Maps a structured E-Control `openingHours[]` list into normalised
  /// `{day,from,to}` string rows. Non-map / empty entries are skipped.
  List<Map<String, String>> _rowsFromList(List<dynamic> list) {
    final rows = <Map<String, String>>[];
    for (final entry in list) {
      if (entry is! Map) continue;
      final label = (entry['label'] ?? entry['day'])?.toString().trim() ?? '';
      final from = entry['from']?.toString().trim() ?? '';
      final to = entry['to']?.toString().trim() ?? '';
      if (label.isEmpty) continue;
      rows.add({'day': label, 'from': from, 'to': to});
    }
    return rows;
  }

  /// Parses the joined German paragraph
  /// (`"Montag: 06:30-20:30, Dienstag: …, Feiertag: …"`) into `{day,from,to}`
  /// rows. Each `,`-separated segment is `"<Label>: <from>-<to>"`.
  List<Map<String, String>> _rowsFromJoinedString(String raw) {
    final rows = <Map<String, String>>[];
    for (final segment in raw.split(',')) {
      final colon = segment.indexOf(':');
      if (colon < 0) continue;
      final label = segment.substring(0, colon).trim();
      final value = segment.substring(colon + 1).trim();
      if (label.isEmpty) continue;
      final dash = value.indexOf('-');
      if (dash < 0) {
        // No range marker → carry the token (e.g. "geschlossen") as `from`.
        rows.add({'day': label, 'from': value, 'to': ''});
        continue;
      }
      rows.add({
        'day': label,
        'from': value.substring(0, dash).trim(),
        'to': value.substring(dash + 1).trim(),
      });
    }
    return rows;
  }

  /// Resolves one normalised row into a [DayHours], or `null` when its day
  /// label is unrecognised.
  DayHours? _parseRow(Map<String, String> row) {
    final day = _dayFromLabel(row['day'] ?? '');
    if (day == null) return null;

    final from = row['from'] ?? '';
    final to = row['to'] ?? '';

    if (_isClosedToken(from) || _isClosedToken(to)) {
      return DayHours.closedDay(day);
    }

    final start = _minutesFromClock(from);
    final end = _minutesFromClock(to);
    if (start == null || end == null) {
      // No usable clock pair → no signal for this day; omit it (treated as
      // unknown by the model) rather than inventing a state.
      return null;
    }

    // 00:00-24:00 (end == 1440) → whole-day open.
    if (start == 0 && end == 1440) return DayHours.allDay(day);
    // 00:00-00:00 (equal bounds) → closed, per the live feed's convention.
    if (start == end) return DayHours.closedDay(day);

    return DayHours(
      day: day,
      state: DayState.openRanges,
      ranges: [TimeRange(startMinutes: start, endMinutes: end)],
    );
  }

  OpeningDay? _dayFromLabel(String label) {
    final key = label.toLowerCase().trim();
    return _germanDayLabels[key] ?? _germanDayCodes[key];
  }

  bool _isClosedToken(String value) {
    final v = value.toLowerCase().trim();
    return v == 'geschlossen' || v == 'closed';
  }

  /// `HH:MM` → minutes-from-midnight (0..1440; 24:00 → 1440), or `null`.
  /// `24:00` is accepted as the feed's whole-day end marker.
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
