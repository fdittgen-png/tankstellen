// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// How old a published price is, and the words for saying so
/// (#3905, #4092).
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
///
/// #4092 — this moved out of `features/favorites` into core so the
/// results list can speak the same language as the favorites list
/// without one feature importing another. `features/favorites/domain/
/// stale_price_policy.dart` re-exports it, so its callers and tests are
/// unchanged.
library;

/// How old a price is, in the four bands a driver actually reacts to.
///
/// #4092 — a green dot that means "something good" is a dot the user has
/// to decode, and price age, price freshness and forecourt availability
/// were all being read off the same one. Freshness gets WORDS, and they
/// stay separate from availability in the model as well as in the UI.
///
/// The bands are deliberately coarse. The underlying stamp is a lossy,
/// per-country pre-formatted string — "14:22" with no date, in some
/// countries — so a precise "3 h 12 min" would be a precision the data
/// does not have. Four bands are what it can honestly support.
enum PriceFreshness {
  /// Published within [PriceFreshnessBands.fresh]. Today's price.
  fresh,

  /// Within [PriceFreshnessBands.recent] — yesterday's, near enough.
  recent,

  /// Within [kStalePriceThreshold]. Worth a glance, not a warning.
  aging,

  /// Older than [kStalePriceThreshold] — the #3905 threshold.
  stale,

  /// No stamp, or one in a shape the reader does not know. NEVER
  /// presented as fresh, and never as stale either: an unknown age is
  /// its own answer.
  unknown,
}

/// The band boundaries. Named so a test can state them.
abstract final class PriceFreshnessBands {
  /// Up to this old counts as [PriceFreshness.fresh].
  static const Duration fresh = Duration(hours: 6);

  /// Up to this old counts as [PriceFreshness.recent].
  static const Duration recent = Duration(days: 1);
}

/// Classify a service-formatted `Station.updatedAt`.
///
/// A stamp in the FUTURE is [PriceFreshness.fresh]: clock skew between
/// the device and the provider is routine, and reporting a price as
/// aging because the phone is three minutes behind would be a lie in the
/// less useful direction.
PriceFreshness priceFreshness(String? updatedAt, {required DateTime now}) {
  if (updatedAt == null) return PriceFreshness.unknown;
  final stamp = parseStationUpdatedAt(updatedAt, now: now);
  if (stamp == null) return PriceFreshness.unknown;
  final age = now.difference(stamp);
  if (age.isNegative || age <= PriceFreshnessBands.fresh) {
    return PriceFreshness.fresh;
  }
  if (age <= PriceFreshnessBands.recent) return PriceFreshness.recent;
  if (age <= kStalePriceThreshold) return PriceFreshness.aging;
  return PriceFreshness.stale;
}

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
