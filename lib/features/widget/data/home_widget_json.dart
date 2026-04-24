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
