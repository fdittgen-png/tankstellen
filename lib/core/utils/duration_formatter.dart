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
