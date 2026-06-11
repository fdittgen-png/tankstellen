// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

/// Testable seam for the JSON the home-screen widget reads (#753).
///
/// `HomeWidgetService` writes the stations list into SharedPreferences
/// under `stations_json` / `nearest_json`, and the native Android widget
/// reads that string back, parses row ids from each entry, and wires
/// them into the row's PendingIntent. If the list encoding ever drops,
/// reorders, duplicates, or malforms an `id`, a tap on row N opens the
/// wrong station — exactly the symptom reported in #753.
///
/// Keeping the encoding in a standalone top-level function (no Flutter
/// or platform-channel dependency) lets a pure Dart test prove the
/// contract that matters: one id per entry, ids are unique, ids match
/// the caller's input, and order is preserved.
///
/// This is intentionally a thin `jsonEncode` wrapper — the value is the
/// testability, not the encoding logic.
String encodeStationsForWidget(List<Map<String, dynamic>> stations) {
  return jsonEncode(stations);
}

/// #2600 / #3171 — mark the cheapest priced row(s) with `isCheapest: true`
/// so the native renderers (Kotlin `StationWidgetRenderer`, Swift
/// `StationRow`) colour their price green. Operates in place on the
/// already-built [rows]. Rows with a null/absent `preferred_fuel_price`
/// are ignored (never the cheapest). When two rows tie at the minimum,
/// both are flagged — honest, and a rare edge anyway.
///
/// Shared between the nearest payload (`NearestWidgetDataBuilder`) and the
/// favorites payload (`HomeWidgetService._buildStationList`, #3171 — the
/// iOS favorites variant reads the same flag) so the two JSON shapes stay
/// in lock-step.
void flagCheapestRows(List<Map<String, dynamic>> rows) {
  double? minPrice;
  for (final row in rows) {
    final p = (row['preferred_fuel_price'] as num?)?.toDouble();
    if (p == null) continue;
    if (minPrice == null || p < minPrice) minPrice = p;
  }
  // Always write the key (false when no row is priced) so the field is a
  // predictable bool the native renderer reads with a `false` default.
  for (final row in rows) {
    final p = (row['preferred_fuel_price'] as num?)?.toDouble();
    row['isCheapest'] = minPrice != null && p != null && p == minPrice;
  }
}
