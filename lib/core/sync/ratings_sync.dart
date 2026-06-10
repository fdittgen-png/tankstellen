// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../utils/json_extensions.dart';
import 'deletions_sync.dart';
import 'supabase_client.dart';
import '../../core/logging/error_logger.dart';

/// Station-rating sync with Supabase, pulled out of [SyncService] (#727).
///
/// Three read/write paths on the `station_ratings` table:
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

  /// Upsert a single station rating. Safe to call for both new and
  /// existing ratings — `onConflict` resolves by `(user_id, station_id)`.
  static Future<void> upsert(
    String stationId,
    int rating, {
    bool shared = false,
  }) async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;

    try {
      await client.from('station_ratings').upsert({
        'user_id': userId,
        'station_id': stationId,
        'rating': rating,
        'is_shared': shared,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,station_id');
      debugPrint(
          'RatingsSync.upsert: $stationId = $rating stars (shared=$shared)');
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'RatingsSync.upsert FAILED'}));
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
  static Future<void> upsertAll(Map<String, int> ratings) async {
    if (ratings.isEmpty) return;
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;

    final now = DateTime.now().toIso8601String();
    final rows = ratings.entries
        .map((e) => {
              'user_id': userId,
              'station_id': e.key,
              'rating': e.value,
              'is_shared': false,
              'updated_at': now,
            })
        .toList();

    try {
      await client
          .from('station_ratings')
          .upsert(rows, onConflict: 'user_id,station_id');
      debugPrint('RatingsSync.upsertAll: ${rows.length} ratings in 1 round-trip');
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'RatingsSync.upsertAll FAILED'}));
    }
  }

  /// Delete a rating from the server. Typically called when the
  /// station is unfavorited (ratings live alongside favorites).
  static Future<void> delete(String stationId) async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;

    try {
      await client
          .from('station_ratings')
          .delete()
          .eq('user_id', userId)
          .eq('station_id', stationId);
      // #3078 — tombstone so another device's re-upload / fetch can't
      // resurrect the deleted rating.
      await DeletionsSync.record('station_ratings', stationId);
      debugPrint('RatingsSync.delete: $stationId removed');
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'RatingsSync.delete FAILED'}));
    }
  }

  /// Fetch every rating owned by the authenticated user. Returns a
  /// `stationId → rating` map. Empty map when the session isn't
  /// authenticated or the query fails.
  static Future<Map<String, int>> fetchAll() async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return {};

    try {
      final rows = await client
          .from('station_ratings')
          .select('station_id, rating')
          .eq('user_id', userId);
      // #3078 — never re-hydrate a rating the user deleted on another device.
      final tombstoned =
          await DeletionsSync.fetchTombstonedIds('station_ratings');
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
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'RatingsSync.fetchAll FAILED'}));
      return {};
    }
  }
}
