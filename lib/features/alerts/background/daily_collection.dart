// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Computes the station-id set the background task should fetch prices for
/// (#2212).
///
/// [favorites] and [alerts] are always included — they are the
/// user-consented, frequently-refreshed sets. [viewed] is the set of
/// stations the user has previously collected (any station with recorded
/// price history); each is included only when it has NOT already been
/// collected today, so a viewed station's prices are gathered **once per
/// day** rather than on every hourly run. [collectedToday] returns true
/// when the station already has a price-history record for the current
/// calendar day.
List<String> stationsToCollect({
  required List<String> favorites,
  required List<String> alerts,
  required List<String> viewed,
  required bool Function(String id) collectedToday,
}) {
  final ids = <String>{...favorites, ...alerts};
  for (final id in viewed) {
    if (!collectedToday(id)) ids.add(id);
  }
  return ids.toList();
}

/// Whether two timestamps fall on the same calendar day (local time).
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
