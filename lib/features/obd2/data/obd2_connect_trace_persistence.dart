// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:hive_flutter/hive_flutter.dart';

import 'obd2_connect_trace.dart';
import 'obd2_connect_trace_log.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/telemetry/storage/trace_storage.dart';

/// #3184 — persistence for the OBD2 connect-trace ring.
///
/// The #2969 ring is in-memory only (`static _ring`, max 10): every trace
/// died with the app process, so the canonical field flow — "it won't
/// connect" → user force-quits → relaunches → exports the error log —
/// shipped an EMPTY ring. This layer:
///
///   * appends each finalised trace to its own small Hive box (one JSON
///     STRING per trace — strings round-trip Hive without the #1388
///     `Map<dynamic,dynamic>` coercion trap), capped at [maxPersisted]
///     traces / [maxAge] days (the [TraceStorage] retention shape);
///   * hydrates the in-memory ring from the box at startup, so the dev
///     health screen shows pre-kill attempts;
///   * registers the `obd2ConnectTraces` section on the standard error-log
///     export ([TraceStorage.extraExportSections]) — UNGATED by debugMode,
///     deliberately, like the ring itself (#2969): the user must never
///     have to reproduce a field failure with developer mode on.
///
/// Best-effort throughout: persistence must never derail a connect or the
/// export (#1103) — every failure is logged and swallowed.
class Obd2ConnectTracePersistence {
  /// Dedicated box: the trace ring must not bloat the hot `settings` box,
  /// and its own box prunes independently.
  static const String boxName = 'obd2_connect_traces';

  /// Caps mirroring the #3184 design: ~20 traces / 7 days is plenty for
  /// "the last few failed attempts" while bounding disk to a few KB.
  static const int maxPersisted = 20;
  static const Duration maxAge = Duration(days: 7);

  final DateTime Function() _now;

  Obd2ConnectTracePersistence({DateTime Function()? clock})
      : _now = clock ?? DateTime.now;

  Box<dynamic> get _box => Hive.box(boxName);

  /// Open the box, hydrate the in-memory ring, and register the persist
  /// hook + the error-log export section. Called once from
  /// `AppInitializer` (after `Hive.initFlutter`). Best-effort: a failure
  /// degrades to the pre-#3184 in-memory-only behaviour.
  static Future<void> init() async {
    try {
      await Hive.openBox<dynamic>(boxName);
      final persistence = Obd2ConnectTracePersistence();
      Obd2ConnectTraceLog.hydrateFromPersisted(persistence.load());
      Obd2ConnectTraceLog.onTracePersist =
          (trace) => unawaited(persistence.append(trace));
      TraceStorage.extraExportSections['obd2ConnectTraces'] =
          () => [for (final t in persistence.load().reversed) t.toJson()];
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
        'where': 'Obd2ConnectTracePersistence.init failed — connect traces '
            'stay in-memory only this session',
      }));
    }
  }

  /// Persist one finalised [trace] and prune to the caps. Best-effort.
  Future<void> append(Obd2ConnectTrace trace) async {
    try {
      await _box.put(trace.attemptId, jsonEncode(trace.toJson()));
      await _prune();
    } catch (e, st) {
      // debugPrint, not errorLogger: an errorLogger write here could
      // recurse through trace storage on a sick Hive.
      debugPrint('Obd2ConnectTracePersistence.append failed (ignored): '
          '$e\n$st');
    }
  }

  /// Load every persisted trace inside the [maxAge] window, oldest-first.
  /// A corrupt / drifted entry is skipped (never poisons the rest).
  List<Obd2ConnectTrace> load() {
    if (!Hive.isBoxOpen(boxName)) return const [];
    final cutoff = _now().subtract(maxAge).millisecondsSinceEpoch;
    final out = <Obd2ConnectTrace>[];
    for (final raw in _box.values) {
      if (raw is! String) continue;
      try {
        final trace = Obd2ConnectTrace.fromJson(
            jsonDecode(raw) as Map<String, dynamic>);
        if (trace.startedAtMs >= cutoff) out.add(trace);
      } catch (e, st) {
        debugPrint('Obd2ConnectTracePersistence: skipping corrupt trace '
            '(ignored): $e\n$st');
      }
    }
    out.sort((a, b) => a.startedAtMs.compareTo(b.startedAtMs));
    return out;
  }

  /// Drop aged-out / unreadable entries, then the oldest beyond
  /// [maxPersisted].
  Future<void> _prune() async {
    final cutoff = _now().subtract(maxAge).millisecondsSinceEpoch;
    final kept = <(dynamic key, int startedAtMs)>[];
    for (final key in _box.keys.toList()) {
      final raw = _box.get(key);
      int? started;
      if (raw is String) {
        try {
          started = (jsonDecode(raw) as Map<String, dynamic>)['st'] as int?;
        } catch (_) {
          // ignore: silent_catch — unreadable — treated as aged-out below.
        }
      }
      if (started == null || started < cutoff) {
        await _box.delete(key);
      } else {
        kept.add((key, started));
      }
    }
    if (kept.length <= maxPersisted) return;
    kept.sort((a, b) => a.$2.compareTo(b.$2));
    for (final entry in kept.sublist(0, kept.length - maxPersisted)) {
      await _box.delete(entry.$1);
    }
  }
}
