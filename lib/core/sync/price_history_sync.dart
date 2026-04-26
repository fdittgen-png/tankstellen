import 'package:flutter/foundation.dart';

import 'supabase_client.dart';

/// Server-side price history queries, pulled out of [SyncService] (#727).
///
/// Price history is a read-only path for clients — Supabase writes
/// happen server-side via scheduled Edge Functions. Splitting this
/// method into its own class removes ~28 LOC from `sync_service.dart`
/// and keeps each sync concern in a file that answers a single
/// question (*"what do I write back?"* for SyncService, *"what do I
/// read?"* here).
///
/// No authentication gating: `price_snapshots` is readable by anon
/// clients (RLS policy grants SELECT to `authenticated` and `anon`),
/// so the only failure modes are network and Supabase being offline
/// — both handled by returning an empty list.
class PriceHistorySync {
  PriceHistorySync._();

  /// Fetch price history snapshots for [stationId] over the last
  /// [days] days (default 30). Returns an empty list when the client
  /// isn't configured or the fetch fails — callers must treat empty
  /// as "no data" rather than "zero-price stations".
  static Future<List<Map<String, dynamic>>> fetch(
    String stationId, {
    int days = 30,
  }) async {
    final client = TankSyncClient.client;
    if (client == null) return [];

    try {
      final cutoff =
          DateTime.now().subtract(Duration(days: days)).toIso8601String();
      final rows = await client
          .from('price_snapshots')
          .select()
          .eq('station_id', stationId)
          .gte('recorded_at', cutoff)
          .order('recorded_at', ascending: true);
      return List<Map<String, dynamic>>.from(rows);
    } catch (e, st) {
      debugPrint('PriceHistorySync.fetch FAILED: $e\n$st');
      return [];
    }
  }
}
