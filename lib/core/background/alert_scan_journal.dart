// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../logging/error_logger.dart';
import '../storage/hive_boxes.dart';
import 'scan_run_phase.dart';

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

  Box<dynamic>? _boxOrNull() {
    try {
      if (!Hive.isBoxOpen(HiveBoxes.alerts)) return null;
      return Hive.box<dynamic>(HiveBoxes.alerts);
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
  ///
  /// A row for the run whose [markInFlight] marker is the newest row
  /// REPLACES that marker (#4333): a finished run is one row, not two.
  /// Never throws — a journalling fault must never fail the scan.
  Future<void> append({
    required DateTime at,
    required String trigger,
    String? skippedReason,
    int? stationsScanned,
    int? alertsFired,
    String? error,
  }) =>
      _write(<String, Object?>{
        'at': at.toUtc().toIso8601String(),
        'trigger': trigger,
        'skipped': ?skippedReason,
        'stations': ?stationsScanned,
        'alertsFired': ?alertsFired,
        'error': ?error,
      });

  /// The key a started-but-unfinished run's marker row carries.
  static const String inFlightKey = 'inFlight';

  /// The key a marker the run never replaced is resolved into.
  static const String interruptedKey = 'interrupted';

  /// Record that a scan has started its body (#4333).
  ///
  /// The terminal row replaces it. When the OS ends the run first — an iOS
  /// expiry, a WorkManager stop, a kill — the marker is what is left, and
  /// the next run turns it into an `interrupted` row ([resolveInterrupted]),
  /// so the export's "did scans run?" counts the killed run too. Before
  /// this, a run killed after notifying left no row at all. Never throws.
  Future<void> markInFlight({required DateTime at, required String trigger}) =>
      _write(<String, Object?>{
        'at': at.toUtc().toIso8601String(),
        'trigger': trigger,
        inFlightKey: true,
      });

  /// Turn every marker a previous run left into an `interrupted` row, and
  /// return how many there were. Called by the next run once it holds the
  /// lock — the only moment no other run can own a marker. Never throws.
  Future<int> resolveInterrupted() async {
    try {
      final box = _boxOrNull();
      if (box == null) return 0;
      var resolved = 0;
      final rows = [
        for (final row in entries())
          if (row[inFlightKey] == true)
            () {
              resolved++;
              return <String, Object?>{
                'at': row['at'],
                'trigger': row['trigger'],
                interruptedKey: true,
              };
            }()
          else
            row,
      ];
      if (resolved > 0) await box.put(journalKey, rows);
      return resolved;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
        'where': 'AlertScanJournal.resolveInterrupted failed',
      }));
      return 0;
    }
  }

  Future<void> _write(Map<String, Object?> row) async {
    try {
      final box = _boxOrNull();
      if (box == null) {
        debugPrint('AlertScanJournal.append: alerts box closed, '
            'dropping (${row['trigger']})');
        return;
      }
      final rows = entries();
      if (rows.isNotEmpty &&
          rows.last[inFlightKey] == true &&
          rows.last['at'] == row['at'] &&
          rows.last['trigger'] == row['trigger']) {
        rows.removeLast();
      }
      rows.add(row);
      final start = rows.length > maxEntries ? rows.length - maxEntries : 0;
      await box.put(journalKey, rows.sublist(start));
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
        'where': 'AlertScanJournal.append failed',
      }));
    }
  }

  /// Append the row for a run that ended with [outcome] (#4162).
  ///
  /// The typed door to [append]: each [ScanOutcome] writes exactly the
  /// optional group its row has always carried — `skipped: hive_lock` /
  /// `skipped: cooldown`, `error: <type>`, or the counts — so a row reads
  /// byte for byte as it did before the outcome had a name. Never throws.
  Future<void> record(
    ScanOutcome outcome, {
    required DateTime at,
    required String trigger,
    int? stationsScanned,
    int? alertsFired,
    String? error,
  }) =>
      switch (outcome) {
        ScanOutcome.completed => append(
            at: at,
            trigger: trigger,
            stationsScanned: stationsScanned,
            alertsFired: alertsFired,
          ),
        ScanOutcome.skippedLock =>
          append(at: at, trigger: trigger, skippedReason: skippedHiveLock),
        ScanOutcome.skippedCooldown =>
          append(at: at, trigger: trigger, skippedReason: skippedCooldown),
        ScanOutcome.failed =>
          append(at: at, trigger: trigger, error: error),
      };

  /// The `skipped` value of a [ScanOutcome.skippedLock] row.
  static const String skippedHiveLock = 'hive_lock';

  /// The `skipped` value of a [ScanOutcome.skippedCooldown] row.
  static const String skippedCooldown = 'cooldown';

  /// The persisted rows, oldest first. Empty when the box is closed or
  /// the key is missing/malformed. Never throws.
  List<Map<String, Object?>> entries() {
    try {
      final raw = _boxOrNull()?.get(journalKey);
      if (raw is! List) return <Map<String, Object?>>[];
      return raw
          .whereType<Map<dynamic, dynamic>>()
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
