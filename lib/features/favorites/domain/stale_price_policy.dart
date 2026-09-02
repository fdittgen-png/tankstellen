// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Stale-price policy for the Favorites list (#3905).
///
/// A favorite whose upstream price timestamp is older than
/// [kStalePriceThreshold] used to read exactly like a fresh one — the
/// card said "Updated 16/07 11:00" in the same muted grey six weeks
/// later, so a July price looked current in September. The Favorites
/// card now flags it (amber "Old price" badge); this file holds the
/// threshold and the timestamp reading so both are unit-testable.
///
/// `Station.updatedAt` is a lossy, per-country PRE-FORMATTED string
/// (`dd/MM HH:mm` for FR / DK / IT, `dd/MM/yyyy` for OCM, ISO for the
/// test fixtures and a few bulk sources). The reader below accepts the
/// shapes the services emit and answers `null` for anything else, so an
/// unknown format never produces a false "old price" — the badge is
/// strictly opt-in evidence, never a guess.
library;

/// A price older than this is flagged as stale on the Favorites cards.
const Duration kStalePriceThreshold = Duration(days: 7);

/// True when [updatedAt] parses to an instant more than
/// [kStalePriceThreshold] before [now]. Unknown / unparseable stamps
/// answer `false` (no badge).
bool isStalePrice(String? updatedAt, {required DateTime now}) {
  if (updatedAt == null) return false;
  final stamp = parseStationUpdatedAt(updatedAt, now: now);
  if (stamp == null) return false;
  return now.difference(stamp) > kStalePriceThreshold;
}

final _dayMonthYear = RegExp(
  r'^(\d{1,2})[./](\d{1,2})[./](\d{4})(?:[ T](\d{1,2}):(\d{2}))?$',
);
final _dayMonthOnly = RegExp(r'^(\d{1,2})[./](\d{1,2})(?: (\d{1,2}):(\d{2}))?$');

/// Reads a service-formatted `Station.updatedAt` into a local
/// [DateTime], or `null` when the shape is unknown.
///
/// Supported shapes:
///  * ISO-8601 (`2026-03-27T10:00:00+01:00`, `2026-03-27 10:00`) — the
///    fixture / bulk-source form, via [DateTime.tryParse];
///  * `dd/MM/yyyy`, `dd.MM.yyyy`, optionally followed by ` HH:mm`;
///  * `dd/MM HH:mm` / `dd/MM` — the year-less FR / DK / IT form. The
///    year is resolved to the most recent occurrence of that day that is
///    not after [now] (a one-day grace for clock skew), so a stamp of
///    "16/07 11:00" read on 1 September maps to 16 July of the same
///    year, and "28/12 09:00" read on 3 January to the previous year.
DateTime? parseStationUpdatedAt(String raw, {required DateTime now}) {
  final text = raw.trim();
  if (text.isEmpty) return null;

  final iso = DateTime.tryParse(text);
  if (iso != null) return iso.toLocal();

  final withYear = _dayMonthYear.firstMatch(text);
  if (withYear != null) {
    return _build(
      year: int.parse(withYear.group(3)!),
      month: int.parse(withYear.group(2)!),
      day: int.parse(withYear.group(1)!),
      hour: int.tryParse(withYear.group(4) ?? '') ?? 0,
      minute: int.tryParse(withYear.group(5) ?? '') ?? 0,
    );
  }

  final yearless = _dayMonthOnly.firstMatch(text);
  if (yearless != null) {
    final day = int.parse(yearless.group(1)!);
    final month = int.parse(yearless.group(2)!);
    final hour = int.tryParse(yearless.group(3) ?? '') ?? 0;
    final minute = int.tryParse(yearless.group(4) ?? '') ?? 0;
    final thisYear = _build(
      year: now.year,
      month: month,
      day: day,
      hour: hour,
      minute: minute,
    );
    if (thisYear == null) return null;
    // Anything more than a day in the future cannot be this year's
    // occurrence — it is last year's.
    if (thisYear.isAfter(now.add(const Duration(days: 1)))) {
      return _build(
        year: now.year - 1,
        month: month,
        day: day,
        hour: hour,
        minute: minute,
      );
    }
    return thisYear;
  }
  return null;
}

/// Builds a local [DateTime], rejecting out-of-range calendar fields so
/// a garbled stamp ("99/99 00:00") answers `null` instead of rolling
/// over into a real-looking date.
DateTime? _build({
  required int year,
  required int month,
  required int day,
  required int hour,
  required int minute,
}) {
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  if (hour > 23 || minute > 59) return null;
  final dt = DateTime(year, month, day, hour, minute);
  // DateTime normalises 31/02 to 3 March; treat that as malformed.
  if (dt.month != month || dt.day != day) return null;
  return dt;
}
