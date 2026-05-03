import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/error_trace.dart';

part 'trace_storage.g.dart';

@Riverpod(keepAlive: true)
TraceStorage traceStorage(Ref ref) => TraceStorage();

class TraceStorage {
  static const String _boxName = 'error_traces';
  static const int maxTraces = 50;
  static const Duration maxAge = Duration(days: 7);

  static Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  Box get _box => Hive.box(_boxName);

  Future<void> store(ErrorTrace trace) async {
    await _box.put(trace.id, trace.toJson());
    await _prune();
  }

  List<ErrorTrace> getAll() {
    return _box.values
        .map((raw) {
          if (raw is! Map) return null;
          try {
            return ErrorTrace.fromJson(_jsonMapFrom(raw));
          } on Object catch (e, st) {
            // #1301 — schema migrations can leave entries that throw
            // TypeError (missing required field) rather than the
            // narrower FormatException the original code expected.
            // Catch broadly so a single drift entry doesn't poison
            // export — `unparsedRaw` in `exportAsJson` ships the raw
            // payload for offline debugging.
            debugPrint('TraceStorage: trace parse failed: $e\n$st');
            return null;
          }
        })
        .whereType<ErrorTrace>()
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  ErrorTrace? getById(String id) {
    final raw = _box.get(id);
    if (raw is! Map) return null;
    try {
      return ErrorTrace.fromJson(_jsonMapFrom(raw));
    } on Object catch (e, st) {
      // See [getAll] for the rationale behind the broad catch (#1301).
      debugPrint('TraceStorage: trace parse failed: $e\n$st');
      return null;
    }
  }

  Future<void> delete(String id) => _box.delete(id);
  Future<void> clearAll() => _box.clear();

  /// Number of persisted traces, or 0 when the box is not yet open.
  /// Returning 0 instead of throwing lets widgets read `count` during
  /// their first build in environments (tests, headless builds) where
  /// `TraceStorage.init()` hasn't been called — production goes through
  /// AppInitializer which always calls `init()`.
  ///
  /// NOTE: This is the RAW box length and includes entries that fail to
  /// parse via [ErrorTrace.fromJson] after a schema migration. Use
  /// [parsedCount] to get the count of successfully decoded entries and
  /// [unparsedCount] to surface drift to the user (see #1301).
  int get count => Hive.isBoxOpen(_boxName) ? _box.length : 0;

  /// Number of stored entries that successfully parse via
  /// [ErrorTrace.fromJson]. Equals [count] when the schema is current,
  /// drops to 0 after a breaking schema change. (#1301)
  int get parsedCount => getAll().length;

  /// Number of stored entries that FAIL to parse — the gap between
  /// [count] and [parsedCount]. When non-zero the privacy-dashboard
  /// "copy error log" action surfaces this so users know why the
  /// payload looks empty after a migration. (#1301)
  int get unparsedCount {
    final raw = count;
    final parsed = parsedCount;
    return raw > parsed ? raw - parsed : 0;
  }

  /// Returns the raw Hive maps for entries that fail [ErrorTrace.fromJson].
  /// Used by [exportAsJson] so a maintainer can debug schema drift even
  /// when every stored trace is unreadable. Each entry is converted to a
  /// plain `Map<String, dynamic>` so it round-trips cleanly through
  /// [JsonEncoder]. (#1301)
  List<Map<String, dynamic>> getUnparsedRaw() {
    if (!Hive.isBoxOpen(_boxName)) return const [];
    final unparsed = <Map<String, dynamic>>[];
    for (final raw in _box.values) {
      if (raw is! Map) continue;
      final asMap = _jsonMapFrom(raw);
      try {
        ErrorTrace.fromJson(asMap);
      } on Object catch (e, st) {
        debugPrint('TraceStorage: capturing unparsed entry: $e\n$st');
        unparsed.add(asMap);
      }
    }
    return unparsed;
  }

  /// Recursively coerces a Hive-returned [Map] (which is typed
  /// `Map<dynamic, dynamic>` for every nested map and `List<dynamic>` for
  /// nested lists) into a JSON-compatible structure where every map is
  /// `Map<String, dynamic>` and every list of maps is
  /// `List<Map<String, dynamic>>`. Without this, `_$ErrorTraceFromJson`
  /// (and every nested `_$XFromJson`) throws `TypeError` on the first
  /// `as Map<String, dynamic>` cast against a Hive-shaped nested map —
  /// see #1388.
  Map<String, dynamic> _jsonMapFrom(Map raw) {
    final result = <String, dynamic>{};
    raw.forEach((key, value) {
      result[key.toString()] = _coerceJsonValue(value);
    });
    return result;
  }

  dynamic _coerceJsonValue(dynamic value) {
    if (value is Map) return _jsonMapFrom(value);
    if (value is List) return value.map(_coerceJsonValue).toList();
    return value;
  }

  /// Serialises every persisted trace into a single JSON document the
  /// user can email or attach to a GitHub issue. Used by the privacy
  /// dashboard's "Export error log" action (#476, #1301).
  ///
  /// Format:
  /// ```json
  /// {
  ///   "exportedAt": "<iso8601>",
  ///   "traceCount": 12,
  ///   "parsedCount": 11,
  ///   "unparsedCount": 1,
  ///   "traces": [ <ErrorTrace.toJson()>, ... ],
  ///   "unparsedRaw": [ <raw Hive map>, ... ]
  /// }
  /// ```
  ///
  /// `traceCount` mirrors the raw [count] so the legacy field stays
  /// stable; `parsedCount` and `unparsedCount` were added in #1301 to
  /// surface schema-drift to the user (and to keep the unreadable
  /// payload available under `unparsedRaw` for offline debugging).
  String exportAsJson() {
    final traces = getAll();
    final unparsed = getUnparsedRaw();
    return const JsonEncoder.withIndent('  ').convert({
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'traceCount': traces.length + unparsed.length,
      'parsedCount': traces.length,
      'unparsedCount': unparsed.length,
      'traces': traces.map((t) => t.toJson()).toList(),
      'unparsedRaw': unparsed,
    });
  }

  Future<void> _prune() async {
    final cutoff = DateTime.now().subtract(maxAge);
    final all = getAll();
    for (final t in all) {
      if (t.timestamp.isBefore(cutoff)) await _box.delete(t.id);
    }
    final remaining = getAll();
    if (remaining.length > maxTraces) {
      for (final t in remaining.sublist(maxTraces)) {
        await _box.delete(t.id);
      }
    }
  }
}
