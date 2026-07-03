// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/sync/supabase_client.dart';
import '../../../core/sync/sync_provider.dart';
import '../../../core/sync/sync_pull_coordinator.dart';
import '../../../core/sync/user_data_sync.dart';
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
      debugPrint(
        'DataTransparency: auth user = ${TankSyncClient.client?.auth.currentUser?.id}',
      );

      if (!TankSyncClient.isConnected) {
        // #3449 — identity guard: only re-auth anonymously when NO
        // identity is stored. A stored id with no session is the
        // relink-required state; minting a fresh UUID here would orphan
        // the stored identity's server rows (the pulls below no-op
        // unauthenticated instead).
        if (ref.read(syncStateProvider).userId == null) {
          debugPrint('DataTransparency: not connected, attempting re-auth...');
          await TankSyncClient.signInAnonymously();
        }
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

      // #3447 — "sync now" replays the SAME registered pull matrix as
      // launch and app-resume (every synced table, parallel, per-table
      // consent gates + timeouts + #3446 emits inside — see
      // `LaunchSyncPulls`). Replaces the hand-maintained per-entity list
      // that had drifted out of full coverage.
      await SyncPullCoordinator.instance.pullAll();
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
