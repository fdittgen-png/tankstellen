// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// JSON-shape coercion for values read back out of a Hive box.
///
/// Hive returns nested maps as `Map<dynamic, dynamic>`; every JSON codec
/// in the app wants `Map<String, dynamic>` all the way down. This is that
/// one conversion, extracted from `HiveBoxes` (#4057 decomposition): it
/// is a fact about the shape of a value on its way out of storage, not
/// about which boxes exist or who owns them, and sixteen call sites
/// across storage, alerts, charging, EV, fill-ups and vehicles use it
/// without ever touching box lifecycle.
library;

/// Safely converts any Hive map to a typed map.
/// Returns null if input is not a Map.
Map<String, dynamic>? toStringDynamicMap(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return _deepConvert(value);
  if (value is Map) {
    return _deepConvert(Map<String, dynamic>.fromEntries(
      value.entries.map((e) => MapEntry(e.key.toString(), e.value)),
    ));
  }
  return null;
}

/// Recursively convert nested Hive `_Map` to `Map<String, dynamic>`.
Map<String, dynamic> _deepConvert(Map<String, dynamic> map) {
  return map.map((key, value) {
    if (value is Map && value is! Map<String, dynamic>) {
      return MapEntry(key, toStringDynamicMap(value));
    }
    if (value is List) {
      return MapEntry(key, value.map((e) {
        if (e is Map) return toStringDynamicMap(e);
        return e;
      }).toList());
    }
    return MapEntry(key, value);
  });
}
