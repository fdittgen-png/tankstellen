// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Schema-version stamping + on-upgrade migration for the persistent Hive
/// boxes (#1686 stamp, #2922 cache eviction). Extracted from `hive_boxes.dart`
/// so the box-lifecycle file stays under the file-length norm; the contract is
/// unchanged — `HiveBoxes.init()` delegates here after the boxes are open.
///
/// These are pure, stateless helpers that operate on already-open boxes, so
/// they live cleanest as static methods on a small dedicated class.
class HiveSchemaMigration {
  HiveSchemaMigration._();

  /// Network-cache key prefixes in the shared cache box holding refetchable,
  /// schema-versioned API data (#2922): search/bulk lists, detail payloads,
  /// bulk prices, favourited-station snapshots, persisted national datasets (FR
  /// serializes full `Station`s) and geo/city lookups. On a schema bump
  /// [evictStaleCacheOnUpgrade] clears **only** entries whose key starts with
  /// one of these (each maps to a `CacheKey.*` / `PersistentDataset` producer,
  /// safe to drop + refetch).
  ///
  /// ⚠️ An **allowlist**, not a denylist: any non-matching key — chiefly the
  /// user's saved `itineraries`, the only non-cache key in the cache box — is
  /// left untouched. Favorites, profiles, settings, price-history and alerts
  /// live in their own boxes and are never involved.
  @visibleForTesting
  static const Set<String> evictableCachePrefixes = {
    'search:',
    'bulk:',
    'detail:',
    'prices:',
    'station:',
    'dataset:',
    'geo:',
    'city:',
  };

  /// Stamps + migrates [encryptedBoxes] against [currentSchemaVersion],
  /// reading/writing the [boxSchema] meta box (#1686 stamp + #2922 migrate):
  ///
  ///   * A box with **no** stamp is a fresh install (or a pre-#1686 box whose
  ///     on-disk shape already matches the current code) — it is simply
  ///     stamped at [currentSchemaVersion]; there is nothing to migrate.
  ///   * A box stamped **below** [currentSchemaVersion] needs migration. The
  ///     only schema-versioned migration today is the [cacheBox]: its
  ///     network-cache entries are evicted ([evictStaleCacheOnUpgrade]) so the
  ///     old-format `Station` blobs (#2776/#2777) refetch fresh instead of being
  ///     served stale. The box is then re-stamped at the current version.
  ///   * A box stamped **at or above** [currentSchemaVersion] is up to date and
  ///     is left untouched.
  static Future<void> ensureSchemaVersions({
    required String boxSchema,
    required Iterable<String> encryptedBoxes,
    required String cacheBox,
    required int currentSchemaVersion,
  }) async {
    final schema = Hive.box<int>(boxSchema);
    for (final boxName in encryptedBoxes) {
      final stamped = schema.get(boxName);
      if (stamped == null) {
        await schema.put(boxName, currentSchemaVersion);
        continue;
      }
      if (stamped >= currentSchemaVersion) continue;

      // #2922 — an existing stamp below the current version: migrate.
      if (boxName == cacheBox) {
        await evictStaleCacheOnUpgrade(cacheBox: cacheBox);
      }
      // Other boxes have no schema-versioned migration yet; bumping their
      // stamp is enough. Add a branch above when one is introduced.
      await schema.put(boxName, currentSchemaVersion);
    }
  }

  /// Evicts the schema-versioned **network-cache** entries from [cacheBox] on a
  /// schema-version upgrade (#2922).
  ///
  /// Only keys whose prefix is in [evictableCachePrefixes] are deleted — the
  /// user's saved `itineraries` and any other non-cache key are preserved (the
  /// cache box is shared). Each delete is independent and best-effort; a delete
  /// failure must never abort startup, so the loop swallows + logs per-key
  /// errors rather than letting one bad key block the rest.
  ///
  /// Called only from [ensureSchemaVersions] after the cache box is open.
  static Future<void> evictStaleCacheOnUpgrade({required String cacheBox}) async {
    if (!Hive.isBoxOpen(cacheBox)) return;
    final box = Hive.box(cacheBox);
    // Snapshot the keys first — deleting while iterating box.keys is unsafe.
    final stale = box.keys
        .whereType<String>()
        .where((k) => evictableCachePrefixes.any(k.startsWith))
        .toList();
    for (final key in stale) {
      try {
        await box.delete(key);
      } catch (e, st) {
        debugPrint(
            'HiveSchemaMigration: failed to evict stale cache key "$key": $e\n$st');
      }
    }
  }
}
