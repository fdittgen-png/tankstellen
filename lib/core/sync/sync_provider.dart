import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../storage/hive_storage.dart';
import 'community_config.dart';
import 'supabase_client.dart';
import 'sync_config.dart';
import 'sync_service.dart';

part 'sync_provider.g.dart';

/// Manages the cloud sync connection state.
///
/// ## Reusability
/// This provider is app-agnostic. It manages Supabase connection lifecycle
/// and persists credentials to Hive. The sync mode (community/private/join)
/// is a UI concept stored alongside the credentials.
///
/// Any app can use this by:
/// 1. Providing its own `CommunityConfig` (or skipping community mode)
/// 2. Calling `connect()` with URL + key
/// 3. Reading `syncStateProvider` to check connection status
@Riverpod(keepAlive: true)
class SyncState extends _$SyncState {
  @override
  SyncConfig build() {
    final storage = ref.watch(hiveStorageProvider);
    final modeStr = storage.getSetting('sync_mode') as String?;
    return SyncConfig(
      enabled: storage.getSetting('sync_enabled') as bool? ?? false,
      supabaseUrl: storage.getSetting('supabase_url') as String?,
      supabaseAnonKey: storage.getSetting('supabase_anon_key') as String?,
      userId: storage.getSetting('sync_user_id') as String?,
      userEmail: TankSyncClient.currentEmail,
      mode: _parseMode(modeStr),
    );
  }

  /// Connect to the Tankstellen Community database (pre-configured).
  /// No URL/key input needed — uses `CommunityConfig`.
  Future<void> connectCommunity() async {
    await connect(
      CommunityConfig.supabaseUrl,
      CommunityConfig.supabaseAnonKey,
      mode: SyncMode.community,
    );
  }

  /// Connect to a Supabase database with explicit credentials.
  Future<void> connect(String url, String anonKey, {
    SyncMode mode = SyncMode.private,
  }) async {
    final cleanUrl = url.replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'/+$'), '');
    final cleanKey = anonKey.replaceAll(RegExp(r'\s+'), '');

    final storage = ref.read(hiveStorageProvider);
    try {
      await TankSyncClient.init(url: cleanUrl, anonKey: cleanKey);
      final userId = await TankSyncClient.signInAnonymously();

      await storage.putSetting('sync_enabled', true);
      await storage.putSetting('supabase_url', cleanUrl);
      await storage.putSetting('supabase_anon_key', cleanKey);
      await storage.putSetting('sync_mode', mode.name);
      if (userId != null) {
        await storage.putSetting('sync_user_id', userId);
      }

      state = SyncConfig(
        enabled: true,
        supabaseUrl: cleanUrl,
        supabaseAnonKey: cleanKey,
        userId: userId,
        mode: mode,
        userEmail: TankSyncClient.currentEmail,
      );

      // Initial sync: upload local data to server (non-blocking)
      _performInitialSync(storage);
    } catch (e) {
      debugPrint('TankSync connect failed: $e');
      rethrow;
    }
  }

  /// Sign in with email (upgrade from anonymous or fresh sign-in).
  Future<void> signInWithEmail(String email, String password, {bool isSignUp = true}) async {
    String? userId;
    if (isSignUp) {
      userId = await TankSyncClient.signUpWithEmail(email, password);
    } else {
      userId = await TankSyncClient.signInWithEmail(email, password);
    }

    if (userId != null) {
      final storage = ref.read(hiveStorageProvider);
      await storage.putSetting('sync_user_id', userId);
      state = SyncConfig(
        enabled: state.enabled,
        supabaseUrl: state.supabaseUrl,
        supabaseAnonKey: state.supabaseAnonKey,
        userId: userId,
        mode: state.mode,
        userEmail: email,
      );
    }
  }

  /// Delete the user's account: wipe server data, sign out, clear local sync state.
  Future<void> deleteAccount() async {
    try {
      await SyncService.deleteAllUserData();
      await TankSyncClient.signOut();
    } catch (e) {
      debugPrint('Delete account failed: $e');
    }
    await disconnect();
  }

  /// Disconnect and clear all sync settings. Local data is preserved.
  Future<void> disconnect() async {
    final storage = ref.read(hiveStorageProvider);
    try {
      await TankSyncClient.signOut();
    } catch (e) {
      debugPrint('TankSync signOut failed: $e');
    }

    await storage.putSetting('sync_enabled', false);
    await storage.putSetting('supabase_url', null);
    await storage.putSetting('supabase_anon_key', null);
    await storage.putSetting('sync_user_id', null);
    await storage.putSetting('sync_mode', null);

    state = const SyncConfig();
  }

  void _performInitialSync(HiveStorage storage) {
    Future.microtask(() async {
      try {
        final favIds = storage.getFavoriteIds();
        if (favIds.isNotEmpty) await SyncService.syncFavorites(favIds);
        final ignoredIds = storage.getIgnoredIds();
        if (ignoredIds.isNotEmpty) await SyncService.syncIgnoredStations(ignoredIds);
        final ratings = storage.getRatings();
        for (final entry in ratings.entries) {
          await SyncService.syncRating(entry.key, entry.value);
        }
        debugPrint('InitialSync: complete');
      } catch (e) {
        debugPrint('InitialSync failed (non-fatal): $e');
      }
    });
  }

  static SyncMode _parseMode(String? value) => switch (value) {
    'community' => SyncMode.community,
    'joinExisting' => SyncMode.joinExisting,
    'private' => SyncMode.private,
    _ => SyncMode.none,
  };
}
