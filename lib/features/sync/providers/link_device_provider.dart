import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/sync/supabase_client.dart';
import '../../../core/sync/sync_service.dart';
import '../../alerts/data/models/price_alert.dart';
import '../../alerts/providers/alert_provider.dart';
import '../../favorites/providers/favorites_provider.dart';

part 'link_device_provider.g.dart';

/// UI state for the "Link device" screen. The text controller itself
/// is owned by the screen; this provider only tracks loading + result.
class LinkDeviceState {
  final bool isLinking;
  final String? result;

  const LinkDeviceState({this.isLinking = false, this.result});

  LinkDeviceState copyWith({
    bool? isLinking,
    String? result,
    bool clearResult = false,
  }) {
    return LinkDeviceState(
      isLinking: isLinking ?? this.isLinking,
      result: clearResult ? null : (result ?? this.result),
    );
  }

  bool get isError => result != null && result!.startsWith('Link failed');
}

@riverpod
class LinkDeviceController extends _$LinkDeviceController {
  @override
  LinkDeviceState build() => const LinkDeviceState();

  Future<void> linkDevice(String otherUserId) async {
    final trimmed = otherUserId.trim();
    if (trimmed.isEmpty || trimmed.length < 10) {
      state = state.copyWith(result: 'Please enter a valid device code');
      return;
    }

    state = const LinkDeviceState(isLinking: true);

    try {
      final client = TankSyncClient.client;
      if (client == null) {
        state = const LinkDeviceState(result: 'Not connected to TankSync');
        return;
      }

      // 1. Fetch the other device's favorites
      final otherFavorites = await client
          .from('favorites')
          .select('station_id')
          .eq('user_id', trimmed);

      final importedFavIds = (otherFavorites as List)
          .map((r) => r['station_id'] as String)
          .toList();

      // 2. Fetch the other device's alerts
      final otherAlerts =
          await client.from('alerts').select().eq('user_id', trimmed);

      // 3. Merge favorites locally
      int addedFavorites = 0;
      final currentFavs = ref.read(favoritesProvider);
      for (final stationId in importedFavIds) {
        if (!currentFavs.contains(stationId)) {
          await ref.read(favoritesProvider.notifier).add(stationId);
          addedFavorites++;
        }
      }

      // 4. Merge alerts locally
      int addedAlerts = 0;
      final currentAlerts = ref.read(alertProvider);
      final currentAlertIds = currentAlerts.map((a) => a.id).toSet();
      for (final row in otherAlerts as List) {
        if (!currentAlertIds.contains(row['id'])) {
          try {
            final alert = PriceAlert.fromJson({
              'id': row['id'],
              'stationId': row['station_id'],
              'stationName': row['station_name'] ?? '',
              'fuelType': row['fuel_type'] ?? 'e10',
              'targetPrice': (row['target_price'] as num).toDouble(),
              'isActive': row['is_active'] ?? true,
              'createdAt':
                  row['created_at'] ?? DateTime.now().toIso8601String(),
            });
            await ref.read(alertProvider.notifier).addAlert(alert);
            addedAlerts++;
          } catch (e) {
            debugPrint('Alert import failed: $e');
          }
        }
      }

      // 5. Sync merged data back to our server account
      await SyncService.syncFavorites(ref.read(favoritesProvider));
      await SyncService.syncAlerts(ref.read(alertProvider));

      state = LinkDeviceState(
        result:
            'Linked! Imported $addedFavorites favorites and $addedAlerts alerts.',
      );
    } catch (e) {
      state = LinkDeviceState(result: 'Link failed: $e');
    }
  }
}
