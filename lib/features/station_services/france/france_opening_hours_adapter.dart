// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/domain/opening_hours.dart';
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
/// ## Normalisation rules (the feed quirks this adapter owns)
/// 1. **`Automate : 24/24`** — the unattended pump runs 24/7. This is an
///    *orthogonal* indicator surfaced as [WeeklyOpeningHours.automate24h];
///    the **staffed boutique/guichet per-day ranges are still parsed and
///    kept** (#2742). Only when the automate flag is set *and there is no
///    staffed schedule at all* does the whole week fall back to
///    [WeeklyOpeningHours.allWeek24h] (pump-only).
/// 2. **The missing-space bug** — the feed glues the day name onto the first
///    clock (`Lundi07.00-18.30`). The parser tokenises on the seven day
///    words, so the day label is split off its clock by construction (#2710).
/// 3. **A day name with NO range** — a bare `Lundi` / a trailing `Dimanche`
///    means *closed that day* (Prix-Carburants `Fermé`). It resolves to
///    [DayState.closed], never dropped (#2742).
/// 4. **The `01:00-01:00` degenerate sentinel** — the feed emits an
///    open==close range to mean "no real interval". A day whose only token is
///    such a range resolves to [DayState.unknown] (the literal range is
///    dropped), never a real interval and never 24h ([TimeRange.isDegenerate]).
/// 5. **Split shifts / lunch breaks** — a day publishes two ranges joined by
///    ` et ` (`Lundi 08.00-12.00 et 14.00-18.00`) or, rarely, as two same-day
///    entries; both ranges coalesce into that day's [DayHours.ranges].
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

  /// Matches a French weekday word anywhere in the string (case/accent
  /// tolerated by the alternation + the `i` flag). Used to tokenise the feed
  /// into one segment per day — the structural split that survives the
  /// missing-space glue (`Lundi07.00`), bare days (`Lundi,`), and ` et `
  /// split shifts alike (#2710, #2742).
  static final RegExp _dayWordRe = RegExp(
    'lundi|mardi|mercredi|jeudi|vendredi|samedi|dimanche',
    caseSensitive: false,
  );

  /// Matches one `HH.MM-HH.MM` (or `HH:MM-HH:MM`) clock range within a day's
  /// segment. `allMatches` picks up both halves of a ` et `-joined split
  /// shift.
  static final RegExp _clockRangeRe = RegExp(
    r'(\d{1,2})[.:](\d{2})\s*-\s*(\d{1,2})[.:](\d{2})',
  );

  @override
  WeeklyOpeningHours parse(dynamic rawProviderData) {
    try {
      final (raw, automate24h) = _narrow(rawProviderData);

      final trimmed = raw?.trim() ?? '';
      // No usable schedule text. A pure automate flag with no schedule still
      // means the pump is open 24/7 (#2742) — and that must hold for a NULL
      // `horaires_jour` exactly like an empty one (#3219: a null column used
      // to discard the automate flag, so the structured path lost the 24/7
      // signal the feed DID publish and only the legacy `is24h` bridge saved
      // the display). Without the flag there is no data.
      if (trimmed.isEmpty) {
        return automate24h
            ? WeeklyOpeningHours.allWeek24h(rawSource: raw, automate24h: true)
            : WeeklyOpeningHours.notAvailable;
      }

      // Tokenise on the day words: each day's segment runs from just after its
      // label to the start of the next day label (or end of string). This
      // splits `Lundi07.00-18.30` (glued), `Lundi,` (bare → closed), and
      // `Lundi 08.00-12.00 et 14.00-18.00` (split shift) uniformly.
      final matches = _dayWordRe.allMatches(trimmed).toList();
      // Per-day accumulators. `closed` = a bare day token with no clock at
      // all; `unknown` = a day whose only clock was the degenerate sentinel.
      final ranges = <OpeningDay, List<TimeRange>>{};
      final closed = <OpeningDay>{};
      final degenerateOnly = <OpeningDay>{};

      for (var i = 0; i < matches.length; i++) {
        final m = matches[i];
        final day = _dayByLabel[_fold(m.group(0)!)];
        if (day == null) continue;
        final segEnd =
            i + 1 < matches.length ? matches[i + 1].start : trimmed.length;
        final segment = trimmed.substring(m.end, segEnd);

        var sawClock = false;
        var sawUsable = false;
        for (final c in _clockRangeRe.allMatches(segment)) {
          sawClock = true;
          final range = TimeRange.fromClock(
            startHour: int.parse(c.group(1)!),
            startMinute: int.parse(c.group(2)!),
            endHour: int.parse(c.group(3)!),
            endMinute: int.parse(c.group(4)!),
          );
          // Degenerate `01:00-01:00` carries no real interval — drop it.
          if (range.isDegenerate) continue;
          sawUsable = true;
          (ranges[day] ??= <TimeRange>[]).add(range);
        }

        if (sawUsable) {
          continue; // real ranges recorded above
        } else if (sawClock) {
          // Only a degenerate sentinel → "no real interval" → unknown.
          degenerateOnly.add(day);
        } else {
          // Bare day name, no clock at all → closed (Fermé).
          closed.add(day);
        }
      }

      final days = <DayHours>[];
      for (final day in kRegularWeekdays) {
        final dayRanges = ranges[day];
        if (dayRanges != null && dayRanges.isNotEmpty) {
          days.add(
            DayHours(day: day, state: DayState.openRanges, ranges: dayRanges),
          );
        } else if (closed.contains(day)) {
          days.add(DayHours(day: day, state: DayState.closed));
        } else if (degenerateOnly.contains(day)) {
          days.add(DayHours(day: day, state: DayState.unknown));
        }
        // else: omitted → implicitly unknown (left out of `days`).
      }

      // Whether any staffed signal at all was resolved (open/closed/unknown).
      final hasSchedule = days.isNotEmpty;
      final hasStaffedRanges = days.any((d) => d.state == DayState.openRanges);

      // Automate-only: the flag is set but the feed gave no real staffed
      // ranges (every day is closed/unknown/omitted) → pump-only 24/7.
      if (automate24h && !hasStaffedRanges) {
        return WeeklyOpeningHours.allWeek24h(rawSource: raw, automate24h: true);
      }

      if (!hasSchedule) return WeeklyOpeningHours.notAvailable;

      // `full` when every regular weekday is resolved, else `partial`.
      final availability = days.length == kRegularWeekdays.length
          ? OpeningHoursAvailability.full
          : OpeningHoursAvailability.partial;
      return WeeklyOpeningHours(
        days: days,
        availability: availability,
        rawSource: raw,
        automate24h: automate24h,
      );
    } catch (e, st) {
      // Contract: never throw — degrade to no-data, release-visibly
      // (#3148 parity: FR was the one adapter skipped by that wave, so an
      // FR format change degraded every station with zero field signal —
      // exactly the blindness #3219's triage ran into).
      reportParseFailure('FR', e, st);
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
