// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../logging/error_logger.dart';
import '../storage/hive_boxes.dart';

/// Rolling journal of background alert-scan runs (#3147).
///
/// Alert delivery previously had no persisted audit trail: scans
/// ran/skipped (lock contention, cooldown), stations fetched and
/// "N alerts triggered" were all debugPrint-only, so a field report of
/// "my alerts never fire" yielded an export showing only *errors* — not
/// whether scans ran at all, were skipped, or fired. This journal makes
/// the standing alert SLA (1-3x/day, ≤3-4h) field-verifiable: every
/// trigger appends one compact row, the last [maxEntries] rows are kept,
/// and the rows ride inside the existing `TraceStorage.exportAsJson()`
/// payload under `diagnostics.alertScanJournal`.
///
/// Rows are PII-free by construction: timestamps, trigger tags,
/// skip reasons, counts and error *types* — never station ids, prices,
/// or coordinates.
///
/// Persists under the already-encrypted [HiveBoxes.alerts] box (open in
/// both the main and background isolates), alongside the
/// `BackgroundScanDedupStore` rows — no extra box in the WorkManager
/// isolate, and the export read happens in the foreground where the box
/// is open anyway. Like the dedup store, every method degrades to a
/// no-op when the box is unavailable — journalling must never break a
/// scan. Local-only: deliberately NOT a synced TankSync table.
class AlertScanJournal {
  /// Hive key holding the rolling `List` of journal rows.
  static const String journalKey = 'bg_scan_journal';

  /// Rows kept, newest last. ~20 rows ≈ 1-2 weeks of twice-daily scans
  /// plus their skipped siblings — enough to answer "did scans run this
  /// week?" while staying tiny in the alerts box and the export.
  static const int maxEntries = 20;

  Box? _boxOrNull() {
    try {
      if (!Hive.isBoxOpen(HiveBoxes.alerts)) return null;
      return Hive.box(HiveBoxes.alerts);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
        'where': 'AlertScanJournal: alerts box unavailable',
      }));
      return null;
    }
  }

  /// Append one scan-run row, rotating out the oldest beyond
  /// [maxEntries]. Exactly one of the optional groups is expected:
  /// [skippedReason] for a skipped trigger, [error] for a failed scan,
  /// or the [stationsScanned]/[alertsFired] counts for a completed one.
  /// Never throws — a journalling fault must never fail the scan.
  Future<void> append({
    required DateTime at,
    required String trigger,
    String? skippedReason,
    int? stationsScanned,
    int? alertsFired,
    String? error,
  }) async {
    try {
      final box = _boxOrNull();
      if (box == null) {
        debugPrint('AlertScanJournal.append: alerts box closed, '
            'dropping ($trigger)');
        return;
      }
      final rows = entries()
        ..add(<String, Object?>{
          'at': at.toUtc().toIso8601String(),
          'trigger': trigger,
          'skipped': ?skippedReason,
          'stations': ?stationsScanned,
          'alertsFired': ?alertsFired,
          'error': ?error,
        });
      final start = rows.length > maxEntries ? rows.length - maxEntries : 0;
      await box.put(journalKey, rows.sublist(start));
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
        'where': 'AlertScanJournal.append failed',
      }));
    }
  }

  /// The persisted rows, oldest first. Empty when the box is closed or
  /// the key is missing/malformed. Never throws.
  List<Map<String, Object?>> entries() {
    try {
      final raw = _boxOrNull()?.get(journalKey);
      if (raw is! List) return <Map<String, Object?>>[];
      return raw
          .whereType<Map>()
          .map((row) => row.map((k, v) => MapEntry('$k', v as Object?)))
          .toList();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
        'where': 'AlertScanJournal.entries failed',
      }));
      return <Map<String, Object?>>[];
    }
  }

  /// Export-ready section for `TraceStorage.exportAsJson()` —
  /// newest-first so the most recent scans lead the payload.
  static List<Map<String, Object?>> exportSection() =>
      AlertScanJournal().entries().reversed.toList();

  /// Clear the journal. Test-only / "clear all data" troubleshoot path.
  @visibleForTesting
  Future<void> clear() async {
    await _boxOrNull()?.delete(journalKey);
  }
}
