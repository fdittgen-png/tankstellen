// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../logging/error_logger.dart';
import '../storage/hive_boxes.dart';

/// Cross-trigger dedup ledger for the on-device background scan (#2415).
///
/// ## Why?
/// Tier-1 background scanning is fed by *several* triggers that the OS may
/// fire close together:
///   * the WorkManager twice-daily periodic scan (`priceRefresh`, #2866),
///   * the Android home-widget refresh (#2412), and
///   * the iOS BGAppRefreshTask (#2414).
///
/// Without a shared gate, two wakeups seconds apart would each fetch prices
/// from the station API and re-run the alert evaluators — doubling network
/// traffic against the Tankerkönig "requests on demand" budget and risking
/// duplicate notifications. This store records the timestamp of the last
/// *completed* scan so [BackgroundAlertScanCoordinator] can skip a scan that
/// would land inside a short cooldown window.
///
/// This is deliberately a coarse scan-level cooldown — it does NOT replace
/// the per-alert throttles (RadiusAlertRunner's frequency gate, the price-
/// alert re-trigger cooldown, the velocity cooldown). Those still own the
/// "don't re-notify the same alert too often" decision; this store only
/// prevents two *triggers* from doing redundant work back-to-back.
///
/// Persists under the already-encrypted [HiveBoxes.alerts] box (open in both
/// the main and background isolates) so no extra box has to be opened in the
/// WorkManager isolate. The single-key footprint sits alongside the radius
/// alert dedup rows.
class BackgroundScanDedupStore {
  /// Hive key holding the ISO-8601 timestamp of the last completed scan.
  static const String lastScanKey = 'bg_scan_last_at';

  /// Hive key holding the name of the trigger that ran the last scan.
  /// Diagnostic only — surfaced in debug logs so a maintainer can tell
  /// whether the widget path or WorkManager actually drove the most
  /// recent refresh.
  static const String lastTriggerKey = 'bg_scan_last_trigger';

  Box<dynamic>? _boxOrNull() {
    try {
      if (!Hive.isBoxOpen(HiveBoxes.alerts)) return null;
      return Hive.box(HiveBoxes.alerts);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: const {
            'where': 'BackgroundScanDedupStore: alerts box unavailable'
          }));
      return null;
    }
  }

  /// Timestamp of the last completed scan, or null when none recorded
  /// (fresh install, or the row was cleared).
  Future<DateTime?> lastScanAt() async {
    final box = _boxOrNull();
    if (box == null) return null;
    final raw = box.get(lastScanKey);
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  /// Whether a scan triggered at [now] should run, given [cooldown].
  ///
  /// Returns `true` when no scan has ever been recorded, or the last scan
  /// is older than [cooldown]. A clock that jumps backwards (last scan
  /// "in the future") is treated as stale → allowed, so a bad device clock
  /// never wedges scanning permanently off.
  Future<bool> shouldScan({
    required DateTime now,
    required Duration cooldown,
  }) async {
    final last = await lastScanAt();
    if (last == null) return true;
    final elapsed = now.difference(last);
    if (elapsed.isNegative) return true;
    return elapsed >= cooldown;
  }

  /// Stamp a completed scan so the next trigger inside [cooldown] is
  /// suppressed. [trigger] is recorded for diagnostics only.
  Future<void> recordScan({
    required DateTime now,
    required String trigger,
  }) async {
    final box = _boxOrNull();
    if (box == null) {
      debugPrint(
          'BackgroundScanDedupStore.recordScan: alerts box closed, dropping ($trigger)');
      return;
    }
    await box.put(lastScanKey, now.toIso8601String());
    await box.put(lastTriggerKey, trigger);
  }

  /// Clear the dedup row. Test-only / "clear all data" troubleshoot path.
  @visibleForTesting
  Future<void> clear() async {
    final box = _boxOrNull();
    if (box == null) return;
    await box.delete(lastScanKey);
    await box.delete(lastTriggerKey);
  }
}
