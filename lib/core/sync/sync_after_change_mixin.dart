import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sync_provider.dart';
import 'sync_service.dart';

/// Mixin for providers that need to sync changes to the server after local mutations.
///
/// Eliminates duplicated sync-after-change pattern in favorites and alerts providers.
mixin SyncAfterChangeMixin {
  Future<void> syncFavoritesIfConnected(Ref ref, List<String> favoriteIds) async {
    try {
      final syncState = ref.read(syncStateProvider);
      if (syncState.enabled) {
        await SyncService.syncFavorites(favoriteIds);
      }
    } catch (e) {
      debugPrint('SyncAfterChange: favorites sync failed: $e');
    }
  }

  Future<void> syncAlertsIfConnected<T>(Ref ref, List<T> alerts) async {
    try {
      final syncState = ref.read(syncStateProvider);
      if (syncState.enabled) {
        await SyncService.syncAlerts(alerts as dynamic);
      }
    } catch (e) {
      debugPrint('SyncAfterChange: alerts sync failed: $e');
    }
  }
}
