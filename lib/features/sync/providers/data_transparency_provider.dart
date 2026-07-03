// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/storage_providers.dart';
import '../../../core/sync/supabase_client.dart';
import '../../../core/sync/sync_events.dart';
import '../../../core/sync/sync_provider.dart';
import '../../../core/sync/favorites_sync.dart';
import '../../../core/sync/trips_sync_enabled_provider.dart';
import '../../../core/sync/user_data_sync.dart';
import '../../alerts/providers/alert_provider.dart';
import '../../consumption/providers/consumption_providers.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../vehicle/providers/vehicle_providers.dart';
import '../../../core/logging/error_logger.dart';

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
    unawaited(Future.microtask(load));
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
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: const {
        'where': 'DataTransparencyController.load: fetchAll failed'
      }));
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
            unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'DataTransparency: users upsert failed'}));
          }
        }
      }

      // #3076 — persist the union (server ∪ local) back to local storage
      // instead of discarding the merge result, so favorites added on
      // another device are pulled down here. The #3446 sync-events emit
      // (AFTER the persist) replaces the old one-off
      // `ref.invalidate(favoritesProvider)` — the `Favorites` notifier
      // subscribes to its table and re-reads storage on the event.
      final storage = ref.read(storageRepositoryProvider);
      final favBefore = storage.getFavoriteIds();
      await storage.setFavoriteIds(await FavoritesSync.merge(favoriteIds));
      SyncEvents.instance.emitIdSetDelta(
          SyncTables.favorites, favBefore, storage.getFavoriteIds());

      // #3077 — pull server-only ratings into local storage (local wins on
      // collision). The station_rating provider re-reads storage on rebuild.
      await ref.read(syncStateProvider.notifier).syncAndPersistRatings(storage);

      // #3077 — alerts: an explicit upload + download pass. The
      // add/toggle hooks already pull on every edit, but the "sync now"
      // gesture must also pull alerts created on another device for a
      // device that never edits one locally.
      final alerts = ref.read(alertProvider);
      debugPrint('DataTransparency: syncing ${alerts.length} local alerts');
      await ref.read(alertProvider.notifier).pullFromServer();

      // #3077 — fill-ups + vehicles are trip-data adjacent, so they ride
      // the same trip-sync consent gate (cloudSync ∧ syncTrips ∧ email).
      // Off → upload-only stays the contract, nothing is pulled.
      if (ref.read(tripsSyncEnabledProvider)) {
        await ref.read(vehicleProfileListProvider.notifier).pullFromServer();
        // #3446 — fill-ups' persist site lives in the length-frozen
        // consumption_providers.dart (#3138), so this call site emits.
        final fillUpsPulled =
            await ref.read(fillUpListProvider.notifier).pullFromServer();
        SyncEvents.instance
            .emit(SyncTableChanged(SyncTables.fillUps, fillUpsPulled));
      }
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'DataTransparency: force sync failed'}));
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
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: const {
        'where': 'DataTransparencyController.deleteAllData: delete failed'
      }));
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}
