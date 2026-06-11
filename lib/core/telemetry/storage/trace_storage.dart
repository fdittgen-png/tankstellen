// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/error_trace.dart';
import '../pii_scrubber.dart';

part 'trace_storage.g.dart';

@Riverpod(keepAlive: true)
TraceStorage traceStorage(Ref ref) => TraceStorage();

class TraceStorage {
  static const String _boxName = 'error_traces';
  static const int maxTraces = 50;
  static const Duration maxAge = Duration(days: 7);

  /// #3184 — pluggable EXTRA sections for [exportAsJson], registered by
  /// feature modules at init (e.g. `obd2ConnectTraces`, registered by
  /// `Obd2ConnectTracePersistence.init`). Keeps core free of feature
  /// imports while the ONE exportable error log carries feature
  /// diagnostics — UNGATED by debugMode (the user must never have to
  /// reproduce a field failure with developer mode on). Each supplier is
  /// best-effort: a throw is captured into the section instead of
  /// killing the whole export.
  static final Map<String, Object? Function()> extraExportSections = {};

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
  ///
  /// #3145 — every exported entry runs through [PiiScrubber]: this
  /// document leaves the device (email attachments, GitHub issues), so
  /// it must honour the same redaction policy as the Sentry uploader.
  /// Parsed traces use [PiiScrubber.scrubErrorTrace]; the unparsed raw
  /// maps get a deep string scrub via [_scrubRawDeep].
  String exportAsJson() {
    // #2310 — single deserialise pass: partition the box into parsed
    // traces + unparsed raw maps once, instead of the former
    // getAll()+getUnparsedRaw() double walk (each re-ran
    // ErrorTrace.fromJson over every entry).
    final (:traces, :unparsed) = _partition();
    traces.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final doc = <String, dynamic>{
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'traceCount': traces.length + unparsed.length,
      'parsedCount': traces.length,
      'unparsedCount': unparsed.length,
      'traces': traces
          .map((t) => PiiScrubber.scrubErrorTrace(t).toJson())
          .toList(),
      'unparsedRaw': unparsed.map(_scrubRawDeep).toList(),
    };
    // #3184 — feature-registered sections (e.g. obd2ConnectTraces). A
    // throwing supplier must never kill the export the user is mid-way
    // through attaching to an issue; its failure is recorded in-line.
    extraExportSections.forEach((key, supplier) {
      try {
        doc[key] = supplier();
      } catch (e, st) {
        debugPrint('TraceStorage: export section "$key" failed: $e\n$st');
        doc[key] = 'unavailable: $e';
      }
    });
    return const JsonEncoder.withIndent('  ').convert(doc);
  }

  /// Recursively applies [PiiScrubber.scrubText] to every string value
  /// in a raw (schema-drifted) trace map so the #1301 `unparsedRaw`
  /// escape hatch honours the same redaction policy as parsed traces
  /// (#3145). Keys are left intact — they are schema, not user data.
  Map<String, dynamic> _scrubRawDeep(Map<String, dynamic> raw) {
    dynamic scrubValue(dynamic value) {
      if (value is String) return PiiScrubber.scrubText(value);
      if (value is Map<String, dynamic>) {
        return value.map((k, v) => MapEntry(k, scrubValue(v)));
      }
      if (value is List) return value.map(scrubValue).toList();
      return value;
    }

    return raw.map((k, v) => MapEntry(k, scrubValue(v)));
  }

  /// Single walk over `_box.values` that splits every entry into the
  /// ones that decode via [ErrorTrace.fromJson] and the ones that don't
  /// (returned as their coerced raw maps for offline debugging — #1301).
  /// The shared seam behind [exportAsJson], so a corrupt-vs-valid box is
  /// deserialised exactly once. The `traces` list is UNSORTED; callers
  /// that need newest-first sort it themselves.
  ({List<ErrorTrace> traces, List<Map<String, dynamic>> unparsed})
      _partition() {
    final traces = <ErrorTrace>[];
    final unparsed = <Map<String, dynamic>>[];
    for (final raw in _box.values) {
      if (raw is! Map) continue;
      final asMap = _jsonMapFrom(raw);
      try {
        traces.add(ErrorTrace.fromJson(asMap));
      } on Object catch (e, st) {
        // See [getAll] for the broad-catch rationale (#1301 / #1388).
        debugPrint('TraceStorage: trace parse failed: $e\n$st');
        unparsed.add(asMap);
      }
    }
    return (traces: traces, unparsed: unparsed);
  }

  /// Prune on every error write. The common case (box at or under
  /// [maxTraces] after the age filter) does exactly ONE deserialise +
  /// sort pass: the age filter walks the single [getAll] list, then the
  /// over-cap check is the O(1) [_box.length] — only when the box is
  /// still over [maxTraces] do we re-fetch for the timestamp sort (#2310,
  /// was two unconditional `getAll()` passes).
  Future<void> _prune() async {
    final cutoff = DateTime.now().subtract(maxAge);
    final all = getAll();
    for (final t in all) {
      if (t.timestamp.isBefore(cutoff)) await _box.delete(t.id);
    }
    // O(1) box-length check — re-deserialise only when still over cap.
    if (_box.length <= maxTraces) return;
    final remaining = getAll();
    if (remaining.length > maxTraces) {
      for (final t in remaining.sublist(maxTraces)) {
        await _box.delete(t.id);
      }
    }
  }
}
