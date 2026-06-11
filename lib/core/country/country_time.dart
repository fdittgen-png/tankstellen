// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Country-anchored wall clock for opening-hours evaluation (#3198).
///
/// Weekly schedules (`WeeklyOpeningHours`) are *local* to the station:
/// `Mon 07:00-19:00` means 07:00 at the pump, not on the user's phone.
/// Evaluating them against the device-local `DateTime.now()` is correct
/// in-country but wrong when browsing a foreign country from home (a
/// Berlin user checking Seoul stations is 7-8 h off — every open/closed
/// badge flips). [nowInCountry] returns a [DateTime] whose *components*
/// (weekday / hour / minute) read as the target country's current wall
/// time, which is exactly what `computeOpenNow` consumes.
///
/// Implementation: a small static UTC-offset table with the three DST
/// rules that cover the supported countries — deliberately NOT a full
/// IANA database (no paid/heavyweight dependency; the rules below are
/// stable EU/UK law and the fixed-offset countries don't observe DST).
/// Multi-zone countries (MX, CL) use their main population zone; the
/// error for the remote zones is bounded and strictly smaller than the
/// device-clock error this replaces.
library;

/// Minutes east of UTC for [countryCode] at the UTC instant [utcNow].
///
/// Unknown / null country codes return `null` — the caller falls back
/// to the device-local clock (the pre-#3198 behaviour).
int? utcOffsetMinutesFor(String? countryCode, DateTime utcNow) {
  switch (countryCode) {
    // Central European Time: CET (+60) / CEST (+120).
    case 'DE':
    case 'FR':
    case 'AT':
    case 'IT':
    case 'ES': // mainland; Canaries are WET (-60 from this) — main zone.
    case 'DK':
    case 'LU':
    case 'SI':
      return _euDstActive(utcNow) ? 120 : 60;
    // Western European Time: WET (0) / WEST (+60) — same EU change dates.
    case 'PT': // mainland; Azores are -60 from this — main zone.
    case 'GB': // UK GMT/BST follows the same last-Sunday rule.
      return _euDstActive(utcNow) ? 60 : 0;
    // Eastern European Time: EET (+120) / EEST (+180).
    case 'GR':
    case 'RO':
      return _euDstActive(utcNow) ? 180 : 120;
    // Fixed offsets — no DST observed.
    case 'KR':
      return 9 * 60; // KST
    case 'AR':
      return -3 * 60; // ART
    case 'MX':
      return -6 * 60; // central zone; MX abolished DST in 2022.
    // Southern-hemisphere DST.
    case 'CL':
      // Continental Chile: -4 standard, -3 in (southern) summer —
      // DST runs from the first Sunday of September to the first
      // Sunday of April.
      return _southernDstActive(utcNow) ? -3 * 60 : -4 * 60;
    case 'AU':
      // NSW (the FuelCheck coverage area): +10 standard, +11 from the
      // first Sunday of October to the first Sunday of April.
      return _auDstActive(utcNow) ? 11 * 60 : 10 * 60;
    default:
      return null;
  }
}

/// The current wall-clock time in [countryCode], as a [DateTime] whose
/// weekday/hour/minute components read in that country's local time.
///
/// Falls back to the device-local clock when the country is unknown.
/// [utcNow] is the injectable clock seam for tests; it defaults to
/// `DateTime.now().toUtc()`.
DateTime nowInCountry(String? countryCode, {DateTime? utcNow}) {
  final utc = (utcNow ?? DateTime.now()).toUtc();
  final offsetMinutes = utcOffsetMinutesFor(countryCode, utc);
  if (offsetMinutes == null) {
    // Unknown country — device-local time (pre-#3198 behaviour).
    return utcNow?.toLocal() ?? DateTime.now();
  }
  return utc.add(Duration(minutes: offsetMinutes));
}

/// EU/UK DST rule: active from 01:00 UTC on the last Sunday of March
/// until 01:00 UTC on the last Sunday of October.
bool _euDstActive(DateTime utc) {
  final start = _lastSundayUtc(utc.year, DateTime.march, hourUtc: 1);
  final end = _lastSundayUtc(utc.year, DateTime.october, hourUtc: 1);
  return !utc.isBefore(start) && utc.isBefore(end);
}

/// Chilean DST rule (continental): active from the first Sunday of
/// September until the first Sunday of April. Evaluated on the UTC
/// calendar — the few-hour boundary fuzz is irrelevant at the
/// open/closed-badge granularity this feeds.
bool _southernDstActive(DateTime utc) {
  final aprilEnd = _firstSundayUtc(utc.year, DateTime.april);
  final septemberStart = _firstSundayUtc(utc.year, DateTime.september);
  return utc.isBefore(aprilEnd) || !utc.isBefore(septemberStart);
}

/// NSW DST rule: active from the first Sunday of October until the
/// first Sunday of April.
bool _auDstActive(DateTime utc) {
  final aprilEnd = _firstSundayUtc(utc.year, DateTime.april);
  final octoberStart = _firstSundayUtc(utc.year, DateTime.october);
  return utc.isBefore(aprilEnd) || !utc.isBefore(octoberStart);
}

/// 00:00/[hourUtc] UTC on the last Sunday of [month] in [year].
DateTime _lastSundayUtc(int year, int month, {int hourUtc = 0}) {
  // Last day of the month, then walk back to Sunday.
  var d = DateTime.utc(year, month + 1, 0);
  while (d.weekday != DateTime.sunday) {
    d = d.subtract(const Duration(days: 1));
  }
  return DateTime.utc(year, month, d.day, hourUtc);
}

/// 00:00 UTC on the first Sunday of [month] in [year].
DateTime _firstSundayUtc(int year, int month) {
  var d = DateTime.utc(year, month, 1);
  while (d.weekday != DateTime.sunday) {
    d = d.add(const Duration(days: 1));
  }
  return DateTime.utc(year, month, d.day);
}
