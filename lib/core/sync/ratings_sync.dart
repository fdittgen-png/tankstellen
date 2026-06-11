// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/logging/error_logger.dart';
import '../utils/json_extensions.dart';
import 'deletions_sync.dart';
import 'entity_sync.dart';
import 'sync_transport.dart';

/// Station-rating sync with Supabase, pulled out of [SyncService] (#727).
///
/// Ratings keep a bespoke read/write surface (an explicit-column table
/// with no union merge), but since #3127 all I/O rides the injectable
/// [SyncTransport] seam and the delete shares [EntitySync.deleteRow]:
///
/// - [upsert] — add or update a rating (owner-private by default,
///   shareable when [shared] is true).
/// - [delete] — remove a rating (called when the station is
///   unfavorited).
/// - [fetchAll] — pull every rating owned by the authenticated user
///   for initial hydration on login.
///
/// Every method is gated on an authenticated Supabase session
/// because RLS policies on `station_ratings` require
/// `user_id = auth.uid()`. When unauthenticated, operations become
/// no-ops / empty results rather than throwing — callers can retry
/// after auth.
class RatingsSync {
  RatingsSync._();

  static const _table = 'station_ratings';

  /// Upsert a single station rating. Safe to call for both new and
  /// existing ratings — `onConflict` resolves by `(user_id, station_id)`.
  static Future<void> upsert(
    String stationId,
    int rating, {
    bool shared = false,
    SyncTransport? transport,
  }) async {
    final t = transport ?? SupabaseSyncTransport.currentOrNull();
    if (t == null) return;

    try {
      await t.upsert(
        _table,
        [
          {
            'user_id': t.userId,
            'station_id': stationId,
            'rating': rating,
            'is_shared': shared,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
        ],
        onConflict: 'user_id,station_id',
      );
      debugPrint(
          'RatingsSync.upsert: $stationId = $rating stars (shared=$shared)');
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st,
          context: const {'where': 'RatingsSync.upsert FAILED'}));
    }
  }

  /// Upsert many station ratings in a SINGLE round-trip (#2319).
  ///
  /// Mirrors [FavoritesSync.merge]'s batch-upsert pattern for the same
  /// `(user_id, station_id)` table shape: instead of N serial
  /// `upsert` calls on initial sync, build one row list and ship it in
  /// one request. No-op when the map is empty or the session isn't
  /// authenticated. All ratings default to owner-private
  /// (`is_shared = false`) — the per-rating share toggle still goes
  /// through [upsert].
  static Future<void> upsertAll(
    Map<String, int> ratings, {
    SyncTransport? transport,
  }) async {
    if (ratings.isEmpty) return;
    final t = transport ?? SupabaseSyncTransport.currentOrNull();
    if (t == null) return;

    final now = DateTime.now().toUtc().toIso8601String();
    final rows = ratings.entries
        .map((e) => {
              'user_id': t.userId,
              'station_id': e.key,
              'rating': e.value,
              'is_shared': false,
              'updated_at': now,
            })
        .toList();

    try {
      await t.upsert(_table, rows, onConflict: 'user_id,station_id');
      debugPrint('RatingsSync.upsertAll: ${rows.length} ratings in 1 round-trip');
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st,
          context: const {'where': 'RatingsSync.upsertAll FAILED'}));
    }
  }

  /// Delete a rating from the server. Typically called when the
  /// station is unfavorited (ratings live alongside favorites).
  /// Tombstone-first (journal-backed, #3078/#3123) via the shared
  /// [EntitySync.deleteRow], so another device's re-upload / fetch
  /// can't resurrect the deleted rating even when the row delete
  /// fails transiently.
  static Future<void> delete(String stationId, {SyncTransport? transport}) =>
      EntitySync.deleteRow(
        table: _table,
        idColumn: 'station_id',
        recordId: stationId,
        logContext: 'RatingsSync.delete',
        transport: transport,
      );

  /// Fetch every rating owned by the authenticated user. Returns a
  /// `stationId → rating` map. Empty map when the session isn't
  /// authenticated or the query fails.
  static Future<Map<String, int>> fetchAll({SyncTransport? transport}) async {
    final t = transport ?? SupabaseSyncTransport.currentOrNull();
    if (t == null) return {};

    try {
      final rows = await t.select(_table, 'station_id, rating');
      // #3078 — never re-hydrate a rating the user deleted on another device.
      final tombstoned =
          await DeletionsSync.fetchTombstonedIds(_table, transport: t);
      final result = <String, int>{};
      for (final r in rows) {
        final stationId = r.getString('station_id');
        final rating = r.getInt('rating');
        if (stationId != null &&
            rating != null &&
            !tombstoned.contains(stationId)) {
          result[stationId] = rating;
        }
      }
      return result;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st,
          context: const {'where': 'RatingsSync.fetchAll FAILED'}));
      return {};
    }
  }
}
