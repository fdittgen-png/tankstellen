import 'package:flutter/foundation.dart';

import '../../features/alerts/data/models/price_alert.dart';
import '../utils/json_extensions.dart';
import 'supabase_client.dart';

/// Price-alert sync with Supabase, pulled out of [SyncService] (#727).
///
/// Bidirectional merge:
///   - local-only alerts upload to the `alerts` table (`id`-conflict
///     upsert so replaying an already-synced alert is a no-op).
///   - server-only alerts download and the caller returns a merged
///     `[localAlerts, ...downloaded]` list.
///
/// Unauthenticated / offline paths return the input list unchanged —
/// the alert UI keeps working on pure-local state.
class AlertsSync {
  AlertsSync._();

  /// Merge [localAlerts] with the user's `alerts` rows on Supabase.
  /// Returns the superset ([local] + server-only downloaded).
  static Future<List<PriceAlert>> merge(List<PriceAlert> localAlerts) async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      debugPrint('AlertsSync.merge: not authenticated');
      return localAlerts;
    }

    try {
      final serverRows =
          await client.from('alerts').select().eq('user_id', userId);
      final serverAlertIds = serverRows
          .map((r) => r.getString('id'))
          .whereType<String>()
          .toSet();
      final localAlertIds = localAlerts.map((a) => a.id).toSet();

      debugPrint('AlertsSync.merge: local=${localAlertIds.length}, '
          'server=${serverAlertIds.length}');

      // Upload local-only alerts.
      final localOnly =
          localAlerts.where((a) => !serverAlertIds.contains(a.id)).toList();
      if (localOnly.isNotEmpty) {
        final rows = localOnly
            .map((a) => {
                  'id': a.id,
                  'user_id': userId,
                  'station_id': a.stationId,
                  'station_name': a.stationName,
                  'fuel_type': a.fuelType.name,
                  'target_price': a.targetPrice,
                  'is_active': a.isActive,
                  'created_at': a.createdAt.toIso8601String(),
                })
            .toList();
        await client.from('alerts').upsert(rows, onConflict: 'id');
        debugPrint('AlertsSync.merge: uploaded ${localOnly.length} alerts');
      }

      // Download server-only alerts.
      final serverOnly = serverRows
          .where((r) => !localAlertIds.contains(r.getString('id')));
      final downloaded = serverOnly.map((r) {
        return PriceAlert.fromJson({
          'id': r.getString('id') ?? '',
          'stationId': r.getString('station_id') ?? '',
          'stationName': r.getString('station_name') ?? '',
          'fuelType': r.getString('fuel_type') ?? '',
          'targetPrice': r.getDouble('target_price') ?? 0.0,
          'isActive': r.getBool('is_active') ?? true,
          'createdAt': r.getString('created_at') ?? '',
        });
      }).toList();

      return [...localAlerts, ...downloaded];
    } catch (e, st) {
      debugPrint('AlertsSync.merge FAILED: $e\n$st');
      return localAlerts;
    }
  }
}
