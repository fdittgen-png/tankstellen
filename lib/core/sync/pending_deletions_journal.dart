// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../storage/hive_boxes.dart';
import '../../core/logging/error_logger.dart';
import '../../core/logging/app_log.dart';
import 'sync_context_key.dart';
import 'sync_transport.dart';

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
    _lastSeen = null;
  }

  /// #4047 — the journal is scoped to the backend + account that created
  /// each entry. It used to be one global `table → ids` map, so a delete
  /// queued under account A replayed under whichever account signed in
  /// next; favourites made that concrete, because a favourite's id is the
  /// station id — the same string for every user.
  static final ScopedIdSets _sets = ScopedIdSets(
    () => load(),
    (json) => persist(json),
  );

  /// The context entries are recorded against and replayed in. Falls back
  /// to the last context a transport was seen in, because the journal is
  /// deliberately written BEFORE the auth check (#3123): an offline
  /// delete has no live transport, but it still belongs to the account
  /// the user was working in.
  static SyncContextKey contextFor(SyncTransport? transport) {
    final t = transport ?? SupabaseSyncTransport.currentOrNull();
    if (t != null) {
      final key = SyncContextKey.of(
        backendUrl: t.backendUrl,
        userId: t.userId,
      );
      _rememberContext(key);
      return key;
    }
    return _lastKnownContext();
  }

  /// Persisted so an offline delete lands in the right context.
  static const lastContextKey = 'pending_deletions_last_context';

  /// Where a delete queued before any sign-in goes.
  static const unboundContext = SyncContextKey('(unbound)|(unbound)');

  /// In-memory mirror of [lastContextKey]. Consulted BEFORE the box: it
  /// is fresher, it survives a settings box that is not open (unit tests,
  /// pre-init startup), and it means the fallback works the moment a
  /// transport has been seen once this run.
  static SyncContextKey? _lastSeen;

  static void _rememberContext(SyncContextKey key) {
    _lastSeen = key;
    try {
      if (!Hive.isBoxOpen(HiveBoxes.settings)) return;
      final box = Hive.box<dynamic>(HiveBoxes.settings);
      if (box.get(lastContextKey) == key.value) return;
      unawaited(box.put(lastContextKey, key.value));
      _migrateLegacyGlobalJournal(key);
    } catch (e, st) {
      log.warn(
          'PendingDeletionsJournal: could not remember the sync context — '
          'a delete queued before the next sign-in falls back to unbound',
          tag: 'sync',
          error: e,
          stack: st,
          layer: ErrorLayer.sync);
    }
  }

  static SyncContextKey _lastKnownContext() {
    final seen = _lastSeen;
    if (seen != null) return seen;
    try {
      if (Hive.isBoxOpen(HiveBoxes.settings)) {
        final raw =
            Hive.box<dynamic>(HiveBoxes.settings).get(lastContextKey) as String?;
        if (raw != null && raw.isNotEmpty) return SyncContextKey(raw);
      }
    } catch (e, st) {
      log.warn(
          'PendingDeletionsJournal: last-context lookup failed — queueing '
          'against the unbound context instead',
          tag: 'sync',
          error: e,
          stack: st,
          layer: ErrorLayer.sync);
    }
    // Nothing has signed in yet this run. The delete is real and must be
    // journaled (#3123), but it cannot be attributed to an account yet,
    // so it lands in the UNBOUND context — adopted by the first identity
    // that drains (see [adoptUnbound]), never replayed under a DIFFERENT
    // one, because "no identity yet" and "someone else's identity" are
    // not the same thing.
    return unboundContext;
  }

  /// One-time adoption of a pre-#4047 global journal into [key]. The
  /// entries belonged to the only account that could have written them,
  /// so dropping them would lose real queued deletes; leaving them global
  /// would keep the defect.
  static void _migrateLegacyGlobalJournal(SyncContextKey key) {
    try {
      final raw = load();
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded.isEmpty) return;
      // Legacy shape is `table -> [ids]`; scoped shape is
      // `context -> table -> [ids]`. A List value means legacy.
      final legacy = <String, List<String>>{
        for (final e in decoded.entries)
          if (e.value is List)
            '${e.key}': [for (final id in e.value as List) '$id'],
      };
      if (legacy.isEmpty) return;
      for (final e in legacy.entries) {
        unawaited(_sets.add(key, e.key, e.value));
      }
      log.warn('PendingDeletionsJournal: adopted ${legacy.length} legacy '
          'table(s) of queued deletions into the current sync context',
          layer: ErrorLayer.sync);
    } catch (e, st) {
      log.error(e, st, layer: ErrorLayer.sync, context: const {
        'where': 'PendingDeletionsJournal legacy adoption failed'
      });
    }
  }

  /// The journalled `table → pending record ids` map for [transport]'s
  /// context. Empty on any load/decode fault (never throws).
  static Map<String, Set<String>> snapshot({SyncTransport? transport}) =>
      _sets.tablesFor(contextFor(transport));

  /// The pending (unconfirmed) tombstone ids for [tableName] in the
  /// current context.
  static Set<String> pendingIds(String tableName,
          {SyncTransport? transport}) =>
      _sets.idsFor(contextFor(transport), tableName);

  /// Journal [recordIds] as pending tombstones for [tableName], against
  /// the context they were created in. Idempotent; never throws.
  static Future<void> addAll(
    String tableName,
    Iterable<String> recordIds, {
    SyncTransport? transport,
  }) =>
      _sets.add(contextFor(transport), tableName, recordIds);

  /// Remove confirmed tombstone ids for [tableName]. Never throws.
  static Future<void> removeAll(
    String tableName,
    Iterable<String> recordIds, {
    SyncTransport? transport,
  }) =>
      _sets.remove(contextFor(transport), tableName, recordIds);

  /// Adopt anything queued before an identity was known into [current].
  ///
  /// This is the ordinary offline case — the user deleted a favourite
  /// with no session, then signed in — and it must NOT be confused with
  /// a foreign account's leftovers: those stay quarantined.
  static Future<void> adoptUnbound(SyncContextKey current) async {
    if (current.value == unboundContext.value) return;
    final orphaned = _sets.tablesFor(unboundContext);
    if (orphaned.isEmpty) return;
    for (final entry in orphaned.entries) {
      await _sets.add(current, entry.key, entry.value);
    }
    await _sets.clearContext(unboundContext);
  }

  /// Contexts OTHER than the current one that still hold queued
  /// deletions — a previous account's intents, deliberately kept (not
  /// silently discarded) but never replayed here.
  static Iterable<String> quarantinedContexts({SyncTransport? transport}) =>
      _sets
          .foreignContexts(contextFor(transport))
          .where((c) => c != unboundContext.value);

  /// Drop everything this context queued — used when the account is
  /// erased, so its intents do not outlive it.
  static Future<void> clearContext({SyncTransport? transport}) =>
      _sets.clearContext(contextFor(transport));
}
