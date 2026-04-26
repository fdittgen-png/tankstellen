import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../trace_recorder.dart';
import 'isolate_error_spool_entry.dart';

/// Hive ring buffer used by background isolates to spool errors that
/// would otherwise be invisible to the foreground `TraceRecorder` /
/// Sentry pipeline (#1105).
///
/// ## Why
/// `lib/core/background/background_service.dart` runs in a separate
/// Dart isolate (WorkManager) so it cannot reach Riverpod and the
/// keep-alive `traceRecorderProvider`. Until this spool existed every
/// failure in radius alerts, velocity detection, price fetching, and
/// widget refresh disappeared with a `debugPrint` line that nobody
/// ever saw.
///
/// ## Contract
/// - `enqueue` is callable from any isolate; it opens its own Hive
///   box on first use, ring-buffer trims to [maxEntries], and **never
///   throws** — if Hive is unavailable the call falls back to
///   `debugPrint` so the calling task can keep running.
/// - `drain` runs in the main isolate after `TraceRecorder` is
///   initialised. It replays every stored entry through
///   `recorder.record(error, stack, ...)` and clears the box.
/// - Box name is exposed via [boxName] so `HiveBoxes.init` /
///   `initInIsolate` can pre-open it under the unencrypted-init path.
///   The spool intentionally lives outside the encrypted set so it
///   keeps working before consent / encryption keys are available
///   (background isolates may run before the user has unlocked the
///   keychain on Android).
///
/// ## Lock awareness
/// Background callers should hold a [HiveIsolateLock] while writing —
/// the spool itself does not acquire the lock. If the lock is
/// unavailable the audit guidance is to drop the entry and
/// `debugPrint`; better to lose one error than block the isolate
/// task.
class IsolateErrorSpool {
  IsolateErrorSpool._();

  /// Hive box name for the spool. Added to `HiveBoxes` so the box is
  /// opened during the normal init paths, but [enqueue] also opens it
  /// lazily so an isolate that hasn't gone through the init dance
  /// (e.g. a fresh WorkManager wake-up) still works.
  static const String boxName = 'isolate_error_spool';

  /// Maximum entries retained. New writes evict the oldest entry once
  /// the ring buffer is full (FIFO eviction).
  static const int maxEntries = 50;

  /// Test seam: replace the box accessor to inject failures.
  @visibleForTesting
  static Future<Box<String>> Function() boxFactory = _defaultOpenBox;

  static Future<Box<String>> _defaultOpenBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<String>(boxName);
    }
    return Hive.openBox<String>(boxName);
  }

  /// Reset the test seam back to the default. Call from `tearDown`.
  @visibleForTesting
  static void resetBoxFactoryForTest() {
    boxFactory = _defaultOpenBox;
  }

  /// Append a new entry to the ring buffer.
  ///
  /// Never throws: any Hive failure (locked file, missing init,
  /// disk full, JSON encode error) is swallowed and logged via
  /// `debugPrint`. The contract is "best-effort" because the calling
  /// background task must not be derailed by an observability
  /// failure.
  ///
  /// [contextMap] should contain Hive-safe primitives only (string,
  /// num, bool, null, List, Map) — anything else is coerced via
  /// `toString()` to keep the ring buffer durable across schema
  /// drift.
  static Future<void> enqueue({
    required String isolateTaskName,
    required Object error,
    StackTrace? stack,
    Map<String, dynamic>? contextMap,
    DateTime? timestamp,
  }) async {
    try {
      final entry = IsolateErrorSpoolEntry(
        timestamp: timestamp ?? DateTime.now(),
        isolateTaskName: isolateTaskName,
        errorMessage: error.toString(),
        stack: (stack ?? StackTrace.current).toString(),
        contextMap: _sanitizeContext(contextMap),
      );
      final box = await boxFactory();
      // Encode to JSON string so the box stays string-typed (matches
      // the other unencrypted JSON-string boxes in HiveBoxes) and the
      // Hive type adapter dance stays simple.
      final encoded = jsonEncode(entry.toJson());
      // Synthetic monotonic key so FIFO ordering is preserved even if
      // two writes share a millisecond.
      final key = '${entry.timestamp.microsecondsSinceEpoch}-'
          '${box.length}';
      await box.put(key, encoded);

      // FIFO eviction: keep only the newest [maxEntries].
      if (box.length > maxEntries) {
        final keys = box.keys.toList();
        final toDrop = keys.length - maxEntries;
        for (var i = 0; i < toDrop; i++) {
          await box.delete(keys[i]);
        }
      }
    } catch (e, st) {
      // Never re-throw from the spool. The whole point of #1105 is
      // that observability must not break the BG task.
      debugPrint('IsolateErrorSpool: enqueue failed ($isolateTaskName): $e\n$st');
    }
  }

  /// Number of stored entries (0 if the box can't be opened).
  static Future<int> length() async {
    try {
      final box = await boxFactory();
      return box.length;
    } catch (e, st) {
      debugPrint('IsolateErrorSpool: length read failed: $e\n$st');
      return 0;
    }
  }

  /// Read every stored entry without modifying the box.
  static Future<List<IsolateErrorSpoolEntry>> peek() async {
    try {
      final box = await boxFactory();
      final entries = <IsolateErrorSpoolEntry>[];
      // Sort by Hive insertion order — which is `box.keys`.
      for (final key in box.keys) {
        final raw = box.get(key);
        if (raw == null) continue;
        try {
          final json = jsonDecode(raw) as Map<String, dynamic>;
          entries.add(IsolateErrorSpoolEntry.fromJson(json));
        } catch (e, st) {
          debugPrint('IsolateErrorSpool: skipping unreadable entry ($key): $e\n$st');
        }
      }
      return entries;
    } catch (e, st) {
      debugPrint('IsolateErrorSpool: peek failed: $e\n$st');
      return const <IsolateErrorSpoolEntry>[];
    }
  }

  /// Drain every stored entry through [recorder] and clear the
  /// ring buffer.
  ///
  /// Returns the number of entries successfully replayed. Failures in
  /// individual `recorder.record` calls are logged and swallowed so
  /// one bad entry can't block the rest of the drain (and so the
  /// box still gets cleared — otherwise we'd re-replay the same
  /// failure on every cold start).
  static Future<int> drain(TraceRecorder recorder) async {
    final entries = await peek();
    var replayed = 0;
    for (final entry in entries) {
      try {
        await recorder.record(
          _IsolateBackgroundError(
            taskName: entry.isolateTaskName,
            message: entry.errorMessage,
            contextMap: entry.contextMap,
          ),
          StackTrace.fromString(entry.stack),
        );
        replayed++;
      } catch (e, st) {
        debugPrint('IsolateErrorSpool: replay failed for ${entry.isolateTaskName}: $e\n$st');
      }
    }
    try {
      final box = await boxFactory();
      await box.clear();
    } catch (e, st) {
      debugPrint('IsolateErrorSpool: clear after drain failed: $e\n$st');
    }
    return replayed;
  }

  /// Test helper: clear the spool without replaying.
  @visibleForTesting
  static Future<void> clearForTest() async {
    try {
      final box = await boxFactory();
      await box.clear();
    } catch (e, st) {
      debugPrint('IsolateErrorSpool: clearForTest failed: $e\n$st');
    }
  }

  static Map<String, dynamic> _sanitizeContext(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return const <String, dynamic>{};
    final out = <String, dynamic>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value == null ||
          value is String ||
          value is num ||
          value is bool ||
          value is List ||
          value is Map) {
        out[entry.key] = value;
      } else {
        // Coerce anything Hive can't serialize natively. Keeps the
        // box durable across schema drift / unexpected payloads.
        out[entry.key] = value.toString();
      }
    }
    return out;
  }
}

/// Wrapper error type used when replaying spooled entries through
/// [TraceRecorder]. Carrying the original task name + context map on
/// the error keeps the foreground trace pipeline (which classifies by
/// `error.toString()` and `runtimeType`) able to identify
/// background-origin failures distinctly from foreground exceptions.
class _IsolateBackgroundError implements Exception {
  final String taskName;
  final String message;
  final Map<String, dynamic> contextMap;

  _IsolateBackgroundError({
    required this.taskName,
    required this.message,
    required this.contextMap,
  });

  @override
  String toString() {
    if (contextMap.isEmpty) {
      return 'IsolateBackgroundError($taskName): $message';
    }
    return 'IsolateBackgroundError($taskName): $message [context=$contextMap]';
  }
}
