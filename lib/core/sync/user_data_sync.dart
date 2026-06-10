// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'supabase_client.dart';
import 'trips_sync.dart';
import '../../core/logging/error_logger.dart';

/// GDPR data-management operations over the user's full server-side
/// footprint, pulled out of [SyncService] (#727).
///
/// Two paths:
///
/// - [fetchAll] — gather every row the user owns across every sync
///   table (favorites, alerts, push tokens, price reports,
///   itineraries) into a single `Map<String, dynamic>` for the
///   Privacy Dashboard's "Export my data" button.
/// - [deleteAll] — wipe every row across the same tables on explicit
///   account deletion. Silent on partial failure — the UI already
///   confirmed the destructive action and a transient Supabase hiccup
///   shouldn't block the user's intent.
class UserDataSync {
  UserDataSync._();

  /// Fetch every row the user owns, grouped by table name. Returns
  /// `{'error': message}` on failure so the Privacy Dashboard can
  /// surface the reason instead of silently showing an empty card.
  static Future<Map<String, dynamic>> fetchAll() async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      return {'error': 'Not authenticated (userId=$userId)'};
    }

    debugPrint('UserDataSync.fetchAll: userId=$userId');

    try {
      final favorites =
          await client.from('favorites').select().eq('user_id', userId);
      final alerts =
          await client.from('alerts').select().eq('user_id', userId);
      final pushTokens =
          await client.from('push_tokens').select().eq('user_id', userId);
      final reports = await client
          .from('price_reports')
          .select()
          .eq('reporter_id', userId);
      final itineraries =
          await client.from('itineraries').select().eq('user_id', userId);
      // #2107 — surface trip sync state in "My server data".
      // Summaries are the canonical row-per-trip count; details are
      // queried only for size accounting (the encoder weighs both).
      // Both tables tolerate a missing row (RLS would return an empty
      // list on a fresh account).
      final tripSummaries = await client
          .from('trip_summaries')
          .select()
          .eq('user_id', userId);
      final tripDetails =
          await client.from('trip_details').select().eq('user_id', userId);

      debugPrint('UserDataSync.fetchAll: favorites=${favorites.length}, '
          'alerts=${alerts.length}, trips=${tripSummaries.length}');

      return {
        'favorites': favorites,
        'alerts': alerts,
        'push_tokens': pushTokens,
        'reports': reports,
        'itineraries': itineraries,
        'trip_summaries': tripSummaries,
        'trip_details': tripDetails,
      };
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'UserDataSync.fetchAll FAILED'}));
      return {'error': e.toString()};
    }
  }

  /// Every server-side table [deleteAll] must wipe for the GDPR
  /// right-to-be-forgotten path, paired with the column the user's id
  /// lives in (most are `user_id`; `price_reports` keys on
  /// `reporter_id`). `trip_summaries` / `trip_details` are wiped via
  /// [TripsSync.forgetAllForUser] rather than listed here, so they are
  /// pinned by the `forgetAllForUser` helper instead.
  ///
  /// Kept `@visibleForTesting` and asserted against [fetchAll]'s read
  /// set so a future table that becomes exportable but not deletable is
  /// caught — the #2292 regression where trip history, itineraries,
  /// OBD2 baselines and station ratings survived account deletion.
  @visibleForTesting
  static const deletableTables = <String, String>{
    'favorites': 'user_id',
    'alerts': 'user_id',
    'push_tokens': 'user_id',
    'price_reports': 'reporter_id',
    'vehicles': 'user_id',
    'fill_ups': 'user_id',
    'itineraries': 'user_id',
    'obd2_baselines': 'user_id',
    'station_ratings': 'user_id',
    'deletions': 'user_id', // #3078 — wipe the user's tombstones too
  };

  /// Delete every row the user owns across every sync table (GDPR
  /// right-to-be-forgotten). No-op when unauthenticated.
  ///
  /// Each table is deleted independently so a transient failure on one
  /// (e.g. RLS hiccup on a table the user has no rows in) doesn't abort
  /// the rest of the wipe — the user already confirmed the destructive
  /// action.
  static Future<void> deleteAll() async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;

    for (final entry in deletableTables.entries) {
      try {
        await client.from(entry.key).delete().eq(entry.value, userId);
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.other, e, st,
            context: {'where': 'UserDataSync.deleteAll FAILED for ${entry.key}'}));
      }
    }

    // trip_summaries + trip_details — delegate to the canonical
    // trip-wipe helper so the column contract stays in one place.
    await TripsSync.forgetAllForUser();
  }
}
