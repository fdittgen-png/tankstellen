// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Pure-Dart helper for resolving fixed-date European public holidays.
///
/// Used by the [PriceFeatureExtractor] (#1117 phase 1) to mark records
/// observed on a public holiday so the future TFLite model (phase 2)
/// can learn a holiday premium / discount.
///
/// ## Scope (phase 1)
///
/// Covers the two pan-European fixed dates and one canonical national
/// fixed-date holiday per supported country:
///
/// - **All countries:** New Year's Day (Jan 1), Christmas Day (Dec 25)
/// - **DE:** Tag der Deutschen Einheit (Oct 3)
/// - **FR:** Fête nationale / Bastille Day (Jul 14)
/// - **IT:** Festa della Repubblica (Jun 2)
/// - **ES:** Fiesta Nacional (Oct 12)
/// - **AT:** Nationalfeiertag (Oct 26)
/// - **BE:** Nationale feestdag (Jul 21)
/// - **NL:** Koningsdag (Apr 27)
/// - **LU:** National Day (Jun 23)
/// - **PL:** Constitution Day (May 3)
///
/// ## Out of scope (deferred to phase 2)
///
/// Variable / computed holidays (Easter Monday, Pentecost, Ascension,
/// Corpus Christi, regional holidays, religious holidays in countries
/// with multi-confessional calendars) are deliberately omitted. Phase 1
/// proves the contract end-to-end with cheap fixed dates; phase 2 will
/// either extend this calendar or import a vetted holidays package.
class PublicHolidayCalendar {
  const PublicHolidayCalendar._();

  /// Returns `true` when [date] is a fixed-date public holiday in
  /// [countryCode]. Returns `false` when [countryCode] is `null` or
  /// unknown — the caller does not have country information, so we
  /// must not invent one.
  ///
  /// [countryCode] is matched case-insensitively against ISO-3166
  /// alpha-2 codes (e.g. `'DE'`, `'fr'`).
  static bool isPublicHoliday(DateTime date, String? countryCode) {
    // New Year's Day and Christmas are universal across the supported
    // EU/Schengen set; treat them as country-agnostic so a record from
    // any country (including unknown country) gets the holiday flag.
    if (date.month == 1 && date.day == 1) return true;
    if (date.month == 12 && date.day == 25) return true;

    if (countryCode == null) return false;
    final code = countryCode.toUpperCase();

    final national = _nationalFixedDates[code];
    if (national == null) return false;
    return date.month == national.month && date.day == national.day;
  }

  /// Country-specific fixed-date national holidays, expressed as
  /// `(month, day)` so the date check is year-agnostic.
  static const Map<String, _MonthDay> _nationalFixedDates = {
    'DE': _MonthDay(10, 3),  // Tag der Deutschen Einheit
    'FR': _MonthDay(7, 14),  // Bastille Day
    'IT': _MonthDay(6, 2),   // Festa della Repubblica
    'ES': _MonthDay(10, 12), // Fiesta Nacional
    'AT': _MonthDay(10, 26), // Nationalfeiertag
    'BE': _MonthDay(7, 21),  // Nationale feestdag
    'NL': _MonthDay(4, 27),  // Koningsdag
    'LU': _MonthDay(6, 23),  // National Day
    'PL': _MonthDay(5, 3),   // Constitution Day
  };
}

/// Compact `(month, day)` pair used by the calendar lookup table.
class _MonthDay {
  final int month;
  final int day;
  const _MonthDay(this.month, this.day);
}
