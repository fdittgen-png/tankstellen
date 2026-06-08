// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/storage_repository.dart';
import '../storage/storage_providers.dart';
import 'community_config.dart';
import 'supabase_client.dart';
import 'sync_config.dart';
import 'favorites_sync.dart';
import 'ignored_stations_sync.dart';
import 'ratings_sync.dart';
import 'user_data_sync.dart';
import '../../core/logging/error_logger.dart';

part 'sync_provider.g.dart';

/// Signature for a sync-merge that takes the device's local ids and
/// returns the union (server ∪ local) — exactly the shape of
/// [FavoritesSync.merge] / [IgnoredStationsSync.merge]. Injected as a
/// seam so the pull-persist wiring (#3076) is unit-testable without a
/// live Supabase session.
typedef IdMergeFn = Future<List<String>> Function(List<String> localIds);

/// Signature for an email auth call (sign-up / sign-in / anonymous-upgrade)
/// returning the resulting user id (or `null`). Mirrors the static
/// `TankSyncClient.*` methods so the auth-branch selection in
/// [SyncState.signInWithEmail] is unit-testable without a live Supabase
/// session — the same seam shape #3076 introduced with [IdMergeFn].
typedef EmailAuthFn = Future<String?> Function(String email, String password);

/// Outcome of an email auth attempt, so the UI can distinguish a completed
/// sign-in from an anonymous upgrade whose email change is still
/// **pending server-side confirmation** (#3079). The UUID is already the
/// user's in every case, so data is never orphaned.
enum EmailAuthResult {
  /// Auth completed and the session now carries the email.
  completed,

  /// The anonymous account was upgraded in place but the server requires
  /// the user to click a confirmation link before the email is active.
  /// Their data is already safe under the unchanged UUID.
  confirmationPending,

  /// No user id came back (e.g. client not initialised) — nothing changed.
  failed,
}

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
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'TankSync connect failed'}));
      rethrow;
    }
  }

  /// Attach an email to the current account (cross-device identity, #3079).
  ///
  /// Branch selection — the crux of the cross-device fix:
  /// - **Anonymous session + sign-up** → [TankSyncClient.upgradeAnonymousToEmail]:
  ///   the current UUID-only user is converted to a permanent email user
  ///   **in place, keeping the same id**, so the 18 favorites / 80 trips
  ///   already owned by that UUID stay owned by the now-email account and
  ///   become reachable from every device. (The old [signUpWithEmail]
  ///   minted a brand-new UUID, orphaning all of that.)
  /// - **Sign-in (existing account, e.g. a second device)** →
  ///   [TankSyncClient.signInWithEmail].
  /// - **Sign-up with no anonymous session to upgrade** (fresh install,
  ///   signed out) → fall back to [TankSyncClient.signUpWithEmail].
  ///
  /// After the auth transition, [_performInitialSync] uploads + pulls local
  /// data (favorites/ignored via the #3076 [syncAndPersistIds], ratings)
  /// under the now-email identity. Trips reconcile via
  /// `AppInitializer._runTripsSyncMerge` on the next launch.
  ///
  /// Returns an [EmailAuthResult] so the UI can surface the
  /// confirmation-pending state when the server requires the user to click
  /// an email link before the upgrade activates — in which case the email
  /// is not yet on the session, but the UUID (and its data) is already the
  /// user's, so nothing is orphaned.
  Future<EmailAuthResult> signInWithEmail(
    String email,
    String password, {
    bool isSignUp = true,
    bool? isAnonymous,
    EmailAuthFn? upgrade,
    EmailAuthFn? signUp,
    EmailAuthFn? signIn,
  }) async {
    final anonymous = isAnonymous ?? TankSyncClient.isAnonymous;
    final upgradeFn = upgrade ?? TankSyncClient.upgradeAnonymousToEmail;
    final signUpFn = signUp ?? TankSyncClient.signUpWithEmail;
    final signInFn = signIn ?? TankSyncClient.signInWithEmail;

    final String? userId;
    if (isSignUp && anonymous) {
      // Preserve the UUID: upgrade the anonymous user in place.
      userId = await upgradeFn(email, password);
    } else if (isSignUp) {
      // No anonymous session to upgrade → fresh sign-up.
      userId = await signUpFn(email, password);
    } else {
      // Existing account (second device) → sign in.
      userId = await signInFn(email, password);
    }

    if (userId == null) return EmailAuthResult.failed;

    final storage = ref.read(storageRepositoryProvider);
    await storage.putSetting('sync_user_id', userId);

    // After an in-place upgrade the email is only live on the session once
    // the server confirms it (when confirmation is enabled). Read it back
    // rather than assuming the supplied address is active yet.
    final activeEmail = TankSyncClient.currentEmail;
    final pending = isSignUp &&
        anonymous &&
        (activeEmail == null || activeEmail.isEmpty);

    state = SyncConfig(
      enabled: state.enabled,
      supabaseUrl: state.supabaseUrl,
      supabaseAnonKey: state.supabaseAnonKey,
      userId: userId,
      mode: state.mode,
      // Keep the address shown so the user knows what to confirm; once the
      // session reports it, currentEmail rehydrates it on the next build.
      userEmail: activeEmail ?? email,
    );

    // Sync local data under the (unchanged) identity — non-blocking.
    // Critical: without this, favorites/ratings added during the anonymous
    // session would never appear under the email account on other devices.
    _performInitialSync(storage);

    return pending
        ? EmailAuthResult.confirmationPending
        : EmailAuthResult.completed;
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
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'switchToAnonymous failed'}));
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
      await UserDataSync.deleteAll();
      await TankSyncClient.signOut();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'Delete account failed'}));
    }
    await disconnect();
  }

  /// Disconnect and clear all sync settings. Local data is preserved.
  Future<void> disconnect() async {
    final storage = ref.read(storageRepositoryProvider);
    try {
      await TankSyncClient.signOut();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'TankSync signOut failed'}));
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
        await syncAndPersistIds(storage);
        // #2319 — batch every local rating into one upsert round-trip
        // instead of N serial calls on connect. (Ratings pull is #3077.)
        await RatingsSync.upsertAll(storage.getRatings());
        debugPrint('InitialSync: complete');
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'InitialSync failed (non-fatal)'}));
      }
    });
  }

  /// Bidirectionally sync favorites + ignored stations and **persist the
  /// union back to local storage** (#3076).
  ///
  /// Previously the [FavoritesSync.merge] / [IgnoredStationsSync.merge]
  /// return values (server ∪ local) were discarded, so a device only
  /// ever uploaded — server-side rows added on another device never
  /// reached this one. We now write the merged superset back via
  /// [StorageRepository.setFavoriteIds] / [StorageRepository.setIgnoredIds].
  ///
  /// The merges run unconditionally (no `isNotEmpty` guard): a fresh
  /// device with no local favorites must still *pull* the server's set.
  ///
  /// [mergeFavorites] / [mergeIgnored] default to the real syncs and are
  /// injectable so the pull-persist wiring is unit-testable without a
  /// live Supabase session (the real merges return the input unchanged
  /// when unauthenticated, masking the wiring under test).
  @visibleForTesting
  Future<void> syncAndPersistIds(
    StorageRepository storage, {
    IdMergeFn mergeFavorites = FavoritesSync.merge,
    IdMergeFn mergeIgnored = IgnoredStationsSync.merge,
  }) async {
    await storage.setFavoriteIds(await mergeFavorites(storage.getFavoriteIds()));
    await storage.setIgnoredIds(await mergeIgnored(storage.getIgnoredIds()));
  }

  static SyncMode _parseMode(String? value) => switch (value) {
    'community' => SyncMode.community,
    'joinExisting' => SyncMode.joinExisting,
    'private' => SyncMode.private,
    _ => SyncMode.none,
  };
}
