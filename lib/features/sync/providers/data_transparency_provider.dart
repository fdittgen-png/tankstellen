import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/sync/supabase_client.dart';
import '../../../core/sync/sync_provider.dart';
import '../../../core/sync/alerts_sync.dart';
import '../../../core/sync/favorites_sync.dart';
import '../../../core/sync/user_data_sync.dart';
import '../../alerts/providers/alert_provider.dart';
import '../../favorites/providers/favorites_provider.dart';

part 'data_transparency_provider.g.dart';

/// UI state for the "My server data" (data transparency) screen.
/// Holds the fetched server payload plus loading/error state so the
/// screen can be a [ConsumerWidget] instead of using setState.
class DataTransparencyState {
  final Map<String, dynamic>? data;
  final bool loading;
  final String? error;

  const DataTransparencyState({
    this.data,
    this.loading = true,
    this.error,
  });

  DataTransparencyState copyWith({
    Map<String, dynamic>? data,
    bool? loading,
    String? error,
    bool clearError = false,
    bool clearData = false,
  }) {
    return DataTransparencyState(
      data: clearData ? null : (data ?? this.data),
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

@riverpod
class DataTransparencyController extends _$DataTransparencyController {
  @override
  DataTransparencyState build() {
    // Kick off initial load.
    Future.microtask(load);
    return const DataTransparencyState();
  }

  Future<void> load() async {
    final syncConfig = ref.read(syncStateProvider);
    final storedUserId = syncConfig.userId;
    final sessionUserId = TankSyncClient.client?.auth.currentUser?.id;

    debugPrint(
      'DataTransparency.load: storedUserId=$storedUserId, '
      'sessionUserId=$sessionUserId, isConnected=${TankSyncClient.isConnected}',
    );

    if (storedUserId == null && sessionUserId == null) {
      state = state.copyWith(
        loading: false,
        error:
            'No user ID found. Try disconnecting and reconnecting TankSync.',
      );
      return;
    }

    state = state.copyWith(loading: true, clearError: true);
    try {
      final data = await UserDataSync.fetchAll();
      if (data.containsKey('error')) {
        state = state.copyWith(
          loading: false,
          error: data['error'] as String,
        );
      } else {
        state = DataTransparencyState(data: data, loading: false);
      }
    } catch (e, st) { // ignore: unused_catch_stack
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> forceSyncAndReload() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final favoriteIds = ref.read(favoritesProvider);
      debugPrint(
        'DataTransparency: forcing sync of ${favoriteIds.length} local favorites',
      );
      debugPrint(
        'DataTransparency: auth user = ${TankSyncClient.client?.auth.currentUser?.id}',
      );
      debugPrint(
        'DataTransparency: client initialized = ${TankSyncClient.isConnected}',
      );

      if (!TankSyncClient.isConnected) {
        debugPrint('DataTransparency: not connected, attempting re-auth...');
        await TankSyncClient.signInAnonymously();
        debugPrint(
          'DataTransparency: re-auth result = ${TankSyncClient.client?.auth.currentUser?.id}',
        );
      } else {
        final uid = TankSyncClient.client?.auth.currentUser?.id;
        if (uid != null) {
          try {
            await TankSyncClient.client!
                .from('users')
                .upsert({'id': uid}, onConflict: 'id');
          } catch (e, st) {
            debugPrint('DataTransparency: users upsert failed: $e\n$st');
          }
        }
      }

      await FavoritesSync.merge(favoriteIds);

      final alerts = ref.read(alertProvider);
      debugPrint('DataTransparency: syncing ${alerts.length} local alerts');
      await AlertsSync.merge(alerts);
    } catch (e, st) {
      debugPrint('DataTransparency: force sync failed: $e\n$st');
    }

    await load();
  }

  Future<void> deleteAllData() async {
    final syncConfig = ref.read(syncStateProvider);
    if (syncConfig.userId == null) return;

    state = state.copyWith(loading: true, clearError: true);
    try {
      await UserDataSync.deleteAll();
      await load();
    } catch (e, st) { // ignore: unused_catch_stack
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}
