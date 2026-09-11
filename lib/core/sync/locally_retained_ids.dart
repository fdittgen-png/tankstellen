// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:hive/hive.dart';

import '../storage/hive_boxes.dart';
import 'sync_context_key.dart';
import 'sync_transport.dart';

/// Ids this device tombstoned as part of a server-side wipe and
/// deliberately KEPT locally (#4046).
///
/// ## The promise this exists to keep
///
/// The delete-synced-data dialog says, in every locale:
///
/// > "This removes the selected data from your sync database and it will
/// >  not re-sync from your other devices. **Data stored locally on this
/// >  device is kept.**"
///
/// Three claims, and the tombstone delivers only two of them. It stops
/// the re-upload and it makes other devices drop their copies — but
/// `EntitySync.merge` filtered tombstoned ids out of the local set too,
/// and then persisted that filtered set. So the device that was promised
/// its copy was the device that deleted it, on the very next sync.
///
/// A tombstone therefore means two different things depending on who
/// wrote it, and nothing recorded which:
///
///  * written because the USER DELETED A RECORD — every device should
///    drop it locally. Correct, unchanged.
///  * written because the user WIPED THE SERVER and kept local — the
///    record stays on this device and simply never goes back up.
///
/// This set is the missing distinction, and it is deliberately LOCAL: it
/// is a statement about this device's copy, not a fact to replicate. It
/// is scoped by backend + account for the same reason the deletion
/// journal is (#4047) — an id here is meaningful only against the
/// account whose server rows were wiped.
class LocallyRetainedIds {
  LocallyRetainedIds._();

  /// The `settings`-box key the retention set persists under.
  static const settingsKey = 'locally_retained_after_server_wipe';

  /// Persistence seams — injectable for unit tests.
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
  static void resetForTest() {
    load = _loadFromSettings;
    persist = _persistToSettings;
  }

  static final ScopedIdSets _sets =
      ScopedIdSets(() => load(), (json) => persist(json));

  static SyncContextKey _context(SyncTransport? transport) {
    final t = transport;
    if (t == null) return const SyncContextKey('(unbound)|(unbound)');
    return SyncContextKey.of(backendUrl: t.backendUrl, userId: t.userId);
  }

  /// Ids of [table] this device wiped server-side but kept locally.
  static Set<String> forTable(String table, {SyncTransport? transport}) =>
      _sets.idsFor(_context(transport), table);

  /// Record that [ids] of [table] were wiped from the server and must
  /// survive locally. Never throws.
  static Future<void> retain(
    String table,
    Iterable<String> ids, {
    SyncTransport? transport,
  }) =>
      _sets.add(_context(transport), table, ids);

  /// Forget the retention for [ids] — used when the rows genuinely go
  /// away locally too (full account erasure), so the set cannot grow
  /// without bound across the life of an install.
  static Future<void> release(
    String table,
    Iterable<String> ids, {
    SyncTransport? transport,
  }) =>
      _sets.remove(_context(transport), table, ids);

  /// Drop every retention for this context — account erasure.
  static Future<void> clearContext({SyncTransport? transport}) =>
      _sets.clearContext(_context(transport));
}
