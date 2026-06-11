// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Always-on, persisted, named health counters (#3146).
///
/// The app previously had ZERO production metrics: the only counting
/// infrastructure (DataAccessRecorder, Obd2CommDiagnostics) is debug-
/// gated, so a country API that silently degrades (empty lists, stale
/// fallbacks, soft-429s), a 1-in-10-failing sync table, or a slowly
/// dying BLE adapter produced no field signal at all — the chain falls
/// back to stale cache and the maintainer finds out from app reviews.
///
/// This is a deliberately tiny counter box:
///   - [increment] is an in-memory map bump (hot-path safe, never
///     throws) that debounce-schedules a flush;
///   - [flush] merges the pending deltas into a per-day Hive row
///     (`yyyy-MM-dd` → `{name: count}`) and prunes rows older than
///     [retainDays];
///   - the rows ride inside the existing `TraceStorage.exportAsJson()`
///     payload under `diagnostics.healthCounters`, so the existing
///     error-log export action is the only consent/export surface (no
///     new SaaS, the no-paid-services constraint is untouched).
///
/// Counter names are dot-namespaced, low-cardinality and PII-free by
/// construction (country codes, sync-table names, `ble.connect.*`) —
/// never station ids, coordinates or user data.
///
/// ## Isolate model
/// Only the foreground isolate calls [init] (AppInitializer's storage
/// phase), so only the foreground ever opens the box — a background
/// isolate's increments stay in memory and die with the isolate. That
/// is intentional: lazily opening the box from the WorkManager isolate
/// would bypass the HiveIsolateLock that serialises cross-isolate box
/// access.
class HealthCounters {
  /// [clock] is a test seam for the day-bucket key and prune cutoff.
  HealthCounters({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static const String boxName = 'health_counters';

  /// Days of per-day rows kept on flush. Two weeks covers the "user
  /// reports an issue a few days later" window while keeping the box
  /// (and the export payload) tiny.
  static const int retainDays = 14;

  /// Debounce window between the first pending increment and the
  /// automatic flush, so a burst of increments costs one Hive write.
  static const Duration flushDebounce = Duration(seconds: 30);

  final DateTime Function() _clock;
  final Map<String, int> _pending = <String, int>{};
  Timer? _flushTimer;

  /// Open the counter box. Foreground-only, called once from
  /// AppInitializer's storage phase alongside `TraceStorage.init()`.
  static Future<void> init() async {
    await Hive.openBox<dynamic>(boxName);
  }

  /// Whether a debounced flush is currently scheduled (test hook).
  @visibleForTesting
  bool get hasScheduledFlush => _flushTimer?.isActive ?? false;

  /// Drop pending deltas + cancel the scheduled flush (test hook).
  @visibleForTesting
  void resetForTest() {
    _flushTimer?.cancel();
    _flushTimer = null;
    _pending.clear();
  }

  /// Bump counter [name] by [by]. Hot-path safe: an in-memory map merge
  /// plus (at most) one Timer arm. Never throws — a metrics fault must
  /// not derail the instrumented caller.
  void increment(String name, {int by = 1}) {
    try {
      _pending[name] = (_pending[name] ?? 0) + by;
      // Arm the debounce only once the box is actually open: a closed
      // box can't be flushed anyway (background isolate / pre-init
      // startup / widget tests, where a stray pending Timer would trip
      // the pending-timer assertion). Pre-init increments stay pending
      // and ride along with the first post-init flush.
      if (Hive.isBoxOpen(boxName)) {
        _flushTimer ??= Timer(flushDebounce, () {
          _flushTimer = null;
          unawaited(flush());
        });
      }
    } catch (e, st) {
      debugPrint('HealthCounters.increment failed: $e\n$st');
    }
  }

  /// Merge the pending deltas into today's persisted row and prune
  /// rows older than [retainDays]. A closed box (background isolate,
  /// or pre-[init] startup) keeps the deltas pending for a later
  /// flush. Never throws.
  Future<void> flush() async {
    try {
      _flushTimer?.cancel();
      _flushTimer = null;
      if (_pending.isEmpty) return;
      if (!Hive.isBoxOpen(boxName)) return; // keep pending — see docstring
      final box = Hive.box<dynamic>(boxName);
      final today = _dayKey(_clock());
      final row = _rowFrom(box.get(today));
      for (final entry in _pending.entries) {
        row[entry.key] = (row[entry.key] ?? 0) + entry.value;
      }
      _pending.clear();
      await box.put(today, row);
      await _prune(box, today);
    } catch (e, st) {
      debugPrint('HealthCounters.flush failed: $e\n$st');
    }
  }

  /// Serialise-ready snapshot for the error-log export: every persisted
  /// per-day row, with today's row merged with the still-pending
  /// in-memory deltas so an export taken right after an increment is
  /// complete. Never throws — returns whatever is readable.
  Map<String, Object?> exportSnapshot() {
    try {
      final days = <String, Map<String, int>>{};
      if (Hive.isBoxOpen(boxName)) {
        final box = Hive.box<dynamic>(boxName);
        for (final key in box.keys) {
          days['$key'] = _rowFrom(box.get(key));
        }
      }
      if (_pending.isNotEmpty) {
        final today = days.putIfAbsent(_dayKey(_clock()), () => {});
        for (final entry in _pending.entries) {
          today[entry.key] = (today[entry.key] ?? 0) + entry.value;
        }
      }
      return <String, Object?>{'days': days};
    } catch (e, st) {
      debugPrint('HealthCounters.exportSnapshot failed: $e\n$st');
      return const <String, Object?>{};
    }
  }

  /// Delete rows older than [retainDays] before [today]'s date. Day
  /// keys sort lexicographically, so a plain string compare suffices.
  Future<void> _prune(Box<dynamic> box, String today) async {
    final cutoff = _dayKey(_clock().subtract(const Duration(days: retainDays)));
    final stale =
        box.keys.where((k) => '$k'.compareTo(cutoff) < 0).toList(growable: false);
    for (final key in stale) {
      await box.delete(key);
    }
  }

  static String _dayKey(DateTime at) {
    final d = at.toUtc();
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  /// Coerce a Hive-returned value (untyped `Map<dynamic, dynamic>`)
  /// into a fresh `{name: count}` row, dropping anything malformed.
  static Map<String, int> _rowFrom(Object? raw) {
    final row = <String, int>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        if (value is int) row['$key'] = value;
      });
    }
    return row;
  }
}

/// Process-wide singleton, mirroring `errorLogger` / `log`: callable
/// from any isolate and from pre-container startup phases.
final HealthCounters healthCounters = HealthCounters();
