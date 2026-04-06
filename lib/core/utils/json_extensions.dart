/// Safe typed accessors for `Map<String, dynamic>` JSON payloads.
///
/// Replaces fragile `data['key'] as Type?` casts that throw at runtime if the
/// API returns an unexpected type. Every getter returns `null` (or a default)
/// instead of crashing.
///
/// Usage:
/// ```dart
/// final json = response.data as Map<String, dynamic>;
/// final name = json.getString('name');           // String?
/// final lat  = json.getDouble('lat');             // double?
/// final ids  = json.getList<String>('ids');       // List<String>
/// final addr = json.getMap('address');             // Map<String, dynamic>?
/// ```
extension SafeJsonAccessors on Map<String, dynamic> {
  /// Returns the value at [key] as a [String], or `null` if missing or wrong type.
  String? getString(String key) {
    final v = this[key];
    if (v is String) return v;
    // Accept num/bool and convert to string (some APIs return numeric IDs).
    if (v != null) return v.toString();
    return null;
  }

  /// Returns the value at [key] as a [double], or `null` if missing or not numeric.
  double? getDouble(String key) {
    final v = this[key];
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  /// Returns the value at [key] as an [int], or `null` if missing or not numeric.
  int? getInt(String key) {
    final v = this[key];
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  /// Returns the value at [key] as a [bool], or `null` if missing.
  /// Accepts `true`/`false`, `1`/`0`, `'true'`/`'false'`.
  bool? getBool(String key) {
    final v = this[key];
    if (v is bool) return v;
    if (v is int) return v != 0;
    if (v is String) {
      if (v.toLowerCase() == 'true') return true;
      if (v.toLowerCase() == 'false') return false;
    }
    return null;
  }

  /// Returns the value at [key] as a `List<T>`, or an empty list if missing
  /// or wrong type. Elements that don't match `T` are filtered out.
  List<T> getList<T>(String key) {
    final v = this[key];
    if (v is List) return v.whereType<T>().toList();
    return <T>[];
  }

  /// Returns the value at [key] as a `Map<String, dynamic>`, or `null`.
  Map<String, dynamic>? getMap(String key) {
    final v = this[key];
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }
}
