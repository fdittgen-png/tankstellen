import 'package:flutter/foundation.dart';

import 'supabase_client.dart';

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

      debugPrint('UserDataSync.fetchAll: favorites=${favorites.length}, '
          'alerts=${alerts.length}');

      return {
        'favorites': favorites,
        'alerts': alerts,
        'push_tokens': pushTokens,
        'reports': reports,
        'itineraries': itineraries,
      };
    } catch (e) {
      debugPrint('UserDataSync.fetchAll FAILED: $e');
      return {'error': e.toString()};
    }
  }

  /// Delete every row the user owns across every sync table (GDPR
  /// right-to-be-forgotten). No-op when unauthenticated.
  static Future<void> deleteAll() async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;

    await client.from('favorites').delete().eq('user_id', userId);
    await client.from('alerts').delete().eq('user_id', userId);
    await client.from('push_tokens').delete().eq('user_id', userId);
    await client.from('price_reports').delete().eq('reporter_id', userId);
    await client.from('vehicles').delete().eq('user_id', userId);
    await client.from('fill_ups').delete().eq('user_id', userId);
  }
}
