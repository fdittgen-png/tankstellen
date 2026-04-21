import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/storage_repository.dart';
import '../storage/storage_providers.dart';
import 'community_config.dart';
import 'supabase_client.dart';
import 'sync_config.dart';
import 'ratings_sync.dart';
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
    final storage = ref.watch(storageRepositoryProvider);
    final modeStr = storage.getSetting('sync_mode') as String?;
    return SyncConfig(
      enabled: storage.getSetting('sync_enabled') as bool? ?? false,
      supabaseUrl: storage.getSetting('supabase_url') as String?,
      supabaseAnonKey: storage.getSupabaseAnonKey(),
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

    final storage = ref.read(storageRepositoryProvider);
    try {
      await TankSyncClient.init(url: cleanUrl, anonKey: cleanKey);
      final userId = await TankSyncClient.signInAnonymously();

      await storage.putSetting('sync_enabled', true);
      await storage.putSetting('supabase_url', cleanUrl);
      await storage.setSupabaseAnonKey(cleanKey);
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
  ///
  /// After auth transition, triggers a full sync to upload local data
  /// (favorites, ignored stations, ratings) to the new user account.
  /// Without this, favorites added during the anonymous session would
  /// be orphaned on the server under the old anonymous UUID.
  Future<void> signInWithEmail(String email, String password, {bool isSignUp = true}) async {
    String? userId;
    if (isSignUp) {
      userId = await TankSyncClient.signUpWithEmail(email, password);
    } else {
      userId = await TankSyncClient.signInWithEmail(email, password);
    }

    if (userId != null) {
      final storage = ref.read(storageRepositoryProvider);
      await storage.putSetting('sync_user_id', userId);
      state = SyncConfig(
        enabled: state.enabled,
        supabaseUrl: state.supabaseUrl,
        supabaseAnonKey: state.supabaseAnonKey,
        userId: userId,
        mode: state.mode,
        userEmail: email,
      );

      // Sync local data to the new user account (non-blocking).
      // Critical: without this, favorites/ratings added during the
      // anonymous session would never appear under the email account.
      _performInitialSync(storage);
    }
  }

  /// Switch from email account back to anonymous.
  ///
  /// Signs out the current email session, re-authenticates anonymously,
  /// and syncs local data to the new anonymous account. Local data is
  /// preserved — only the server-side identity changes.
  Future<void> switchToAnonymous() async {
    final storage = ref.read(storageRepositoryProvider);

    try {
      // Sign out current email session
      await TankSyncClient.signOut();

      // Re-initialize (signOut resets the _initialized flag)
      if (state.supabaseUrl != null && state.supabaseAnonKey != null) {
        await TankSyncClient.init(
          url: state.supabaseUrl!,
          anonKey: state.supabaseAnonKey!,
        );
      }

      // Sign in anonymously — gets a fresh UUID
      final userId = await TankSyncClient.signInAnonymously();

      if (userId != null) {
        await storage.putSetting('sync_user_id', userId);
      }

      state = SyncConfig(
        enabled: state.enabled,
        supabaseUrl: state.supabaseUrl,
        supabaseAnonKey: state.supabaseAnonKey,
        userId: userId,
        mode: state.mode,
        userEmail: null,
      );

      // Sync local data to the new anonymous account
      _performInitialSync(storage);
    } catch (e) {
      debugPrint('switchToAnonymous failed: $e');
      rethrow;
    }
  }

  /// Delete the user's account: wipe server data, sign out, clear local sync state.
  ///
  /// Blocked in community mode to prevent accidental mass deletion
  /// of the shared database. Users must disconnect first.
  Future<void> deleteAccount() async {
    if (state.mode == SyncMode.community) {
      debugPrint('deleteAccount: blocked in community mode');
      return;
    }
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
    final storage = ref.read(storageRepositoryProvider);
    try {
      await TankSyncClient.signOut();
    } catch (e) {
      debugPrint('TankSync signOut failed: $e');
    }

    await storage.putSetting('sync_enabled', false);
    await storage.putSetting('supabase_url', null);
    await storage.deleteSupabaseAnonKey();
    await storage.putSetting('sync_user_id', null);
    await storage.putSetting('sync_mode', null);

    state = const SyncConfig();
  }

  void _performInitialSync(StorageRepository storage) {
    Future.microtask(() async {
      try {
        final favIds = storage.getFavoriteIds();
        if (favIds.isNotEmpty) await SyncService.syncFavorites(favIds);
        final ignoredIds = storage.getIgnoredIds();
        if (ignoredIds.isNotEmpty) await SyncService.syncIgnoredStations(ignoredIds);
        final ratings = storage.getRatings();
        for (final entry in ratings.entries) {
          await RatingsSync.upsert(entry.key, entry.value);
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
