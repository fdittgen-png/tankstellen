// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../station_detail/domain/opening_hours.dart';
import '../opening_hours/opening_hours_adapter.dart';

/// Maps the French Prix-Carburants (gouv.fr) opening-hours payload onto the
/// common [WeeklyOpeningHours] model (Epic #2707 C3, #2710).
///
/// ## Input shape
/// [parse] accepts a `Map` carrying the two raw feed fields:
///   - `horaires_jour` — the flattened, comma-joined per-day string, e.g.
///     `"Automate-24-24, Lundi07.00-18.30, Mardi08.00-12.00, Mardi14.00-19.00"`.
///   - `horaires_automate_24_24` — the 24/7-automate flag, the string `'Oui'`
///     when the site has a 24-hour unattended pump.
///
/// A bare `String` is also accepted as a convenience (treated as the
/// `horaires_jour` value with no automate flag).
///
/// ## Normalisation rules (the four feed quirks this adapter owns)
/// 1. **`Automate-24-24` prefix** — stripped. When the automate flag is set
///    the whole week is [WeeklyOpeningHours.allWeek24h] regardless of the
///    per-day ranges (the unattended pump is open 24/7).
/// 2. **The missing-space bug** — the feed glues the day name onto the first
///    clock (`Lundi07.00-18.30`). The legacy `replaceAll(', ', '\n')` flattener
///    never separated them. Here a single regex captures the day name and the
///    `HH.MM-HH.MM` range as **separate groups**, so the structural split is
///    correct by construction.
/// 3. **The `01:00-01:00` degenerate sentinel** — the feed emits an
///    open==close range to mean "no real interval". Such a day resolves to
///    [DayState.unknown] (the literal range is dropped), never a real interval
///    and never 24h ([TimeRange.isDegenerate]).
/// 4. **Split shifts** — a lunch break is published as two entries for the
///    same day (`Mardi08.00-12.00, Mardi14.00-19.00`); both ranges coalesce
///    into that day's [DayHours.ranges].
///
/// A day the feed omits is left out of [WeeklyOpeningHours.days] (implicitly
/// unknown). Empty / unparseable input returns [WeeklyOpeningHours.notAvailable].
///
/// Honours the [OpeningHoursAdapter] contract: pure, never throws, never
/// returns `null`.
class FranceOpeningHoursAdapter extends OpeningHoursAdapter {
  const FranceOpeningHoursAdapter();

  /// The automate flag's truthy value in the gouv.fr feed.
  // i18n-ignore: gouv.fr feed enum value, not user-facing text
  static const String _automateYes = 'Oui';

  /// French weekday label → [OpeningDay]. Lower-cased + accent-folded before
  /// lookup so `Mardi`, `mardi` and a stray accented variant all resolve.
  static const Map<String, OpeningDay> _dayByLabel = {
    'lundi': OpeningDay.mon,
    'mardi': OpeningDay.tue,
    'mercredi': OpeningDay.wed,
    'jeudi': OpeningDay.thu,
    'vendredi': OpeningDay.fri,
    'samedi': OpeningDay.sat,
    'dimanche': OpeningDay.sun,
  };

  /// Captures `<DayName><HH.MM>-<HH.MM>` (the glued feed form) in three
  /// groups: day label, start clock, end clock. The day label is letters only
  /// (incl. accents), so the regex cleanly splits `Lundi07.00-18.30` without a
  /// separating space — the structural fix for the missing-space bug (#2710).
  static final RegExp _dayRangeRe = RegExp(
    r'([A-Za-zÀ-ÿ]+)\s*(\d{1,2})[.:](\d{2})\s*-\s*(\d{1,2})[.:](\d{2})',
  );

  @override
  WeeklyOpeningHours parse(dynamic rawProviderData) {
    try {
      final (raw, automate24h) = _narrow(rawProviderData);
      if (raw == null) return WeeklyOpeningHours.notAvailable;

      // The 24/7-automate flag wins outright: the unattended pump is open all
      // week regardless of the staffed per-day ranges.
      if (automate24h) {
        return WeeklyOpeningHours.allWeek24h(rawSource: raw);
      }

      final trimmed = raw.trim();
      if (trimmed.isEmpty) return WeeklyOpeningHours.notAvailable;

      // Accumulate ranges per day (split shifts coalesce). A day that appears
      // only as a degenerate `01:00-01:00` sentinel lands here with an empty
      // range list → resolved to `unknown` below.
      final ranges = <OpeningDay, List<TimeRange>>{};
      final seen = <OpeningDay>{};
      var matchedAny = false;

      for (final m in _dayRangeRe.allMatches(trimmed)) {
        matchedAny = true;
        final day = _dayByLabel[_fold(m.group(1)!)];
        if (day == null) continue;
        seen.add(day);

        final range = TimeRange.fromClock(
          startHour: int.parse(m.group(2)!),
          startMinute: int.parse(m.group(3)!),
          endHour: int.parse(m.group(4)!),
          endMinute: int.parse(m.group(5)!),
        );
        // Degenerate `01:00-01:00` → no real interval. Drop the range; the day
        // is recorded as `seen` so it resolves to `unknown`, never 24h.
        if (range.isDegenerate) continue;
        (ranges[day] ??= <TimeRange>[]).add(range);
      }

      if (!matchedAny) return WeeklyOpeningHours.notAvailable;

      final days = <DayHours>[];
      for (final day in kRegularWeekdays) {
        if (!seen.contains(day)) continue; // omitted → implicitly unknown
        final dayRanges = ranges[day];
        if (dayRanges == null || dayRanges.isEmpty) {
          // The day appeared but carried only a degenerate sentinel.
          days.add(DayHours(day: day, state: DayState.unknown));
        } else {
          days.add(
            DayHours(day: day, state: DayState.openRanges, ranges: dayRanges),
          );
        }
      }

      if (days.isEmpty) return WeeklyOpeningHours.notAvailable;

      // `full` when every regular weekday is resolved, else `partial`.
      final availability = days.length == kRegularWeekdays.length
          ? OpeningHoursAvailability.full
          : OpeningHoursAvailability.partial;
      return WeeklyOpeningHours(
        days: days,
        availability: availability,
        rawSource: raw,
      );
    } catch (_) {
      // Contract: never throw — degrade to no-data.
      return WeeklyOpeningHours.notAvailable;
    }
  }

  /// Narrow [rawProviderData] to `(horairesJour, automate24h)`. Accepts a
  /// `Map` with the two feed keys, or a bare `String` (the `horaires_jour`
  /// value with no automate flag). Anything else → `(null, false)`.
  (String?, bool) _narrow(dynamic raw) {
    if (raw is String) return (raw, false);
    if (raw is Map) {
      final hours = raw['horaires_jour'];
      final automate = raw['horaires_automate_24_24'];
      return (
        hours?.toString(),
        automate?.toString() == _automateYes,
      );
    }
    return (null, false);
  }

  /// Lower-case + strip the few accented French day-label letters so the map
  /// lookup is robust to casing / accent drift in the feed.
  String _fold(String s) => s
      .toLowerCase()
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('î', 'i')
      .replaceAll('ô', 'o')
      .replaceAll('û', 'u')
      .replaceAll('ç', 'c');
}
