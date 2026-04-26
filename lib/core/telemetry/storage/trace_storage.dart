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
          try {
            return ErrorTrace.fromJson(Map<String, dynamic>.from(raw as Map));
          } on FormatException catch (e, st) {
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
    if (raw == null) return null;
    try {
      return ErrorTrace.fromJson(Map<String, dynamic>.from(raw as Map));
    } on FormatException catch (e, st) {
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
  int get count => Hive.isBoxOpen(_boxName) ? _box.length : 0;

  /// Serialises every persisted trace into a single JSON document the
  /// user can email or attach to a GitHub issue. Used by the privacy
  /// dashboard's "Export error log" action (#476).
  ///
  /// Format:
  /// ```json
  /// {
  ///   "exportedAt": "<iso8601>",
  ///   "traceCount": 12,
  ///   "traces": [ <ErrorTrace.toJson()>, ... ]
  /// }
  /// ```
  String exportAsJson() {
    final traces = getAll();
    return const JsonEncoder.withIndent('  ').convert({
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'traceCount': traces.length,
      'traces': traces.map((t) => t.toJson()).toList(),
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
