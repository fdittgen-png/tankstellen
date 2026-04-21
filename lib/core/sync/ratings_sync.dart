import 'package:flutter/foundation.dart';

import '../utils/json_extensions.dart';
import 'supabase_client.dart';

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
    } catch (e) {
      debugPrint('RatingsSync.upsert FAILED: $e');
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
      debugPrint('RatingsSync.delete: $stationId removed');
    } catch (e) {
      debugPrint('RatingsSync.delete FAILED: $e');
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
      final result = <String, int>{};
      for (final r in rows) {
        final stationId = r.getString('station_id');
        final rating = r.getInt('rating');
        if (stationId != null && rating != null) {
          result[stationId] = rating;
        }
      }
      return result;
    } catch (e) {
      debugPrint('RatingsSync.fetchAll FAILED: $e');
      return {};
    }
  }
}
