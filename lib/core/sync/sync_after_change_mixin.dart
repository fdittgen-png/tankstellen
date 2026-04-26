import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'alerts_sync.dart';
import 'favorites_sync.dart';
import 'sync_provider.dart';

/// Mixin for providers that need to sync changes to the server after local mutations.
///
/// Eliminates duplicated sync-after-change pattern in favorites and alerts providers.
mixin SyncAfterChangeMixin {
  Future<void> syncFavoritesIfConnected(Ref ref, List<String> favoriteIds) async {
    try {
      final syncState = ref.read(syncStateProvider);
      if (syncState.enabled) {
        await FavoritesSync.merge(favoriteIds);
      }
    } catch (e, st) {
      debugPrint('SyncAfterChange: favorites sync failed: $e\n$st');
    }
  }

  Future<void> syncAlertsIfConnected<T>(Ref ref, List<T> alerts) async {
    try {
      final syncState = ref.read(syncStateProvider);
      if (syncState.enabled) {
        await AlertsSync.merge(alerts as dynamic);
      }
    } catch (e, st) {
      debugPrint('SyncAfterChange: alerts sync failed: $e\n$st');
    }
  }
}
