// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../l10n/app_localizations.dart';

/// The one travel-duration format (#3993).
///
/// A duration is user-facing text, so its unit abbreviations come from
/// ARB like every other string (HARD RULE #1) — `'${m.round()} min'`
/// hard-codes an English abbreviation into 23 locales.
///
/// Under an hour: `45 min`. At or above: `1 h 20 min`. Zero and
/// negative inputs render as `0 min` rather than an empty string, so a
/// row never loses its second field.
String formatTravelDuration(AppLocalizations l, double minutes) {
  final total = minutes.isFinite && minutes > 0 ? minutes.round() : 0;
  if (total < 60) return l.durationMinutesShort(total);
  return l.durationHoursMinutes(total ~/ 60, total % 60);
}

/// The one elapsed-time format with seconds (#4063) — live recording,
/// trip cards, anything under an hour where seconds carry meaning.
///
/// Under a minute: `42 s`. Under an hour: `14 min 12 s`. At an hour or
/// more: `1 h 14 min` (seconds are noise at that scale, and the shape
/// joins [formatTravelDuration]). Negative input renders as `0 s`.
///
/// Three widgets carried their own `'${m}m ${s}s'` before this — English
/// abbreviations baked into 23 locales, invisible to the HARD RULE #1
/// lint because the literal was interpolated. This is their one home.
String formatElapsedDuration(AppLocalizations l, Duration d) {
  final total = d.isNegative ? Duration.zero : d;
  final h = total.inHours;
  final m = total.inMinutes % 60;
  final s = total.inSeconds % 60;
  if (h >= 1) return l.durationHoursMinutes(h, m);
  if (total.inMinutes >= 1) return l.durationMinutesSeconds(m, s);
  return l.durationSecondsShort(s);
}

/// Drive time for a NARROW numeric column (#4063) — the monthly insights
/// table, where the full `1 h 19 min` wraps at 320 dp / 1.3× text and
/// breaks the column's tabular alignment.
///
/// Under an hour: `45 min`. At or above: `1h 19` — hour abbreviation
/// glued to the number, minutes zero-padded and unit-less, exactly the
/// shape the table's layout tests pin. Still ARB-driven: the `h` is the
/// locale's (de: `1 Std. 19`).
String formatDriveTimeCompact(AppLocalizations l, Duration d) {
  final total = d.isNegative ? 0 : d.inMinutes;
  if (total < 60) return l.durationMinutesShort(total);
  return l.durationHoursMinutesCompact(
      total ~/ 60, (total % 60).toString().padLeft(2, '0'));
}
