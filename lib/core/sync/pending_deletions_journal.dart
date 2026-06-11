// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../storage/hive_boxes.dart';
import '../../core/logging/error_logger.dart';

/// Durable journal of tombstones that have not (yet) been confirmed
/// server-side (#3123).
///
/// Tombstone writes used to be fail-open: `DeletionsSync.recordAll`
/// swallowed every failure with a log, and each `delete()` ran the
/// tombstone write inside the same `try` AFTER the server delete — so a
/// network blip skipped the tombstone entirely and the next union merge
/// resurrected exactly the row #3078 was built to keep dead.
///
/// This journal is the durable "these ids are dead" intent. The flow:
/// 1. `DeletionsSync.recordAll` journals the ids **before** any network
///    attempt and removes them only after the server confirmed the
///    tombstone upsert.
/// 2. `DeletionsSync.fetchTombstonedIds` drains the journal at the start
///    of every merge (so pending tombstones land server-side *before* the
///    union runs) and unions any still-pending ids into the returned set —
///    a journaled delete is honoured locally even while the server write
///    keeps failing.
///
/// Persistence is the always-open `settings` Hive box (one JSON-encoded
/// `table → [ids]` map under [settingsKey]); the [load]/[persist] seams
/// are injectable so unit tests run against an in-memory store.
///
/// **Contract: no method ever throws** — journalling is a sync-resilience
/// concern and must never derail the local delete that already happened.
/// A persistence fault degrades to the pre-#3123 fail-open behaviour and
/// is logged via [errorLogger].
class PendingDeletionsJournal {
  PendingDeletionsJournal._();

  /// The `settings`-box key the journal persists under.
  static const settingsKey = 'pending_deletions_journal';

  /// Persistence seams — default to the `settings` Hive box, injectable
  /// for unit tests (an in-memory string) and fault-injection (#2349).
  static String? Function() load = _loadFromSettings;
  static Future<void> Function(String json) persist = _persistToSettings;

  static String? _loadFromSettings() => Hive.isBoxOpen(HiveBoxes.settings)
      ? Hive.box<dynamic>(HiveBoxes.settings).get(settingsKey) as String?
      : null;

  static Future<void> _persistToSettings(String json) async {
    if (!Hive.isBoxOpen(HiveBoxes.settings)) return;
    await Hive.box<dynamic>(HiveBoxes.settings).put(settingsKey, json);
  }

  /// Restore the real Hive-backed seams after a test injected fakes.
  @visibleForTesting
  static void resetForTest() {
    load = _loadFromSettings;
    persist = _persistToSettings;
  }

  /// The journalled `table → pending record ids` map. Empty on any
  /// load/decode fault (never throws).
  static Map<String, Set<String>> snapshot() {
    try {
      final raw = load();
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return {
        for (final entry in decoded.entries)
          if (entry.value is List && (entry.value as List).isNotEmpty)
            '${entry.key}': {for (final id in entry.value as List) '$id'},
      };
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: const {
        'where': 'PendingDeletionsJournal.snapshot load failed'
      }));
      return {};
    }
  }

  /// The pending (unconfirmed) tombstone ids for [tableName].
  static Set<String> pendingIds(String tableName) =>
      snapshot()[tableName] ?? const {};

  /// Journal [recordIds] as pending tombstones for [tableName].
  /// Idempotent; never throws.
  static Future<void> addAll(
    String tableName,
    Iterable<String> recordIds,
  ) =>
      _mutate(tableName, (ids) => ids.addAll(recordIds));

  /// Remove confirmed tombstone ids for [tableName]. Never throws.
  static Future<void> removeAll(
    String tableName,
    Iterable<String> recordIds,
  ) =>
      _mutate(tableName, (ids) => ids.removeAll(recordIds));

  static Future<void> _mutate(
    String tableName,
    void Function(Set<String> ids) change,
  ) async {
    try {
      final journal = snapshot();
      final ids = journal[tableName] ?? <String>{};
      change(ids);
      if (ids.isEmpty) {
        journal.remove(tableName);
      } else {
        journal[tableName] = ids;
      }
      await persist(jsonEncode({
        for (final entry in journal.entries) entry.key: [...entry.value],
      }));
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: const {
        'where': 'PendingDeletionsJournal persist failed'
      }));
    }
  }
}
