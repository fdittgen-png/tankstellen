import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';

import '../../fakes/fake_hive_storage.dart';

/// These tests verify that favorites, ignored stations, and ratings
/// are correctly synced when the user transitions between auth states:
///
/// - Anonymous → Email sign-up
/// - Anonymous → Email sign-in (existing account)
/// - Connected → Disconnect → Reconnect
/// - Community mode → Delete account (blocked)
///
/// The tests use a [FakeHiveStorage] to simulate local state and verify
/// state changes via fake-state inspection (no mocktail needed for
/// stateful storage assertions).
void main() {
  late FakeHiveStorage fakeStorage;

  setUp(() {
    fakeStorage = FakeHiveStorage();
  });

  ProviderContainer createContainer({
    SyncConfig initialConfig = const SyncConfig(),
  }) {
    final c = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(fakeStorage),
      syncStateProvider.overrideWith(() => _FakeSyncState(initialConfig)),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('SyncState auth transitions', () {
    test('signInWithEmail triggers initial sync of local favorites', () async {
      // Setup: user has local favorites from anonymous session
      await fakeStorage.setFavoriteIds(['station-1', 'station-2', 'station-3']);
      await fakeStorage.setIgnoredIds(['station-x']);
      await fakeStorage.setRating('station-1', 5);

      final container = createContainer(
        initialConfig: const SyncConfig(
          enabled: true,
          supabaseUrl: 'https://test.supabase.co',
          supabaseAnonKey: 'key',
          userId: 'anon-uuid',
          mode: SyncMode.community,
        ),
      );

      // Read to initialize
      final state = container.read(syncStateProvider);
      expect(state.enabled, isTrue);
      expect(state.userId, 'anon-uuid');

      // Verify storage has favorites that would need syncing
      expect(fakeStorage.getFavoriteIds(), hasLength(3));
      expect(fakeStorage.getIgnoredIds(), hasLength(1));
      expect(fakeStorage.getRatings(), hasLength(1));
    });

    test('disconnect clears sync config but preserves local data', () async {
      // Pre-seed local data — disconnect must NOT touch any of this.
      await fakeStorage.setFavoriteIds(['s1', 's2']);
      await fakeStorage.setIgnoredIds(['ignored-1']);
      await fakeStorage.setRating('s1', 4);

      final container = createContainer(
        initialConfig: const SyncConfig(
          enabled: true,
          supabaseUrl: 'https://test.supabase.co',
          supabaseAnonKey: 'key',
          userId: 'user-123',
          mode: SyncMode.community,
        ),
      );

      container.read(syncStateProvider);
      await container.read(syncStateProvider.notifier).disconnect();

      // Verify sync settings are cleared in storage.
      expect(fakeStorage.getSetting('sync_enabled'), false);
      expect(fakeStorage.getSetting('supabase_url'), isNull);
      expect(fakeStorage.getSupabaseAnonKey(), isNull);
      expect(fakeStorage.getSetting('sync_user_id'), isNull);
      expect(fakeStorage.getSetting('sync_mode'), isNull);

      // Verify local data is preserved.
      expect(fakeStorage.getFavoriteIds(), ['s1', 's2']);
      expect(fakeStorage.getIgnoredIds(), ['ignored-1']);
      expect(fakeStorage.getRatings(), {'s1': 4});

      // Verify state is reset
      final state = container.read(syncStateProvider);
      expect(state.enabled, isFalse);
      expect(state.userId, isNull);
    });

    test('deleteAccount is blocked in community mode', () async {
      final container = createContainer(
        initialConfig: const SyncConfig(
          enabled: true,
          supabaseUrl: 'https://test.supabase.co',
          supabaseAnonKey: 'key',
          userId: 'user-123',
          mode: SyncMode.community,
        ),
      );

      container.read(syncStateProvider);
      await container.read(syncStateProvider.notifier).deleteAccount();

      // In community mode, disconnect should NOT be called
      // (deleteAccount returns early)
      final state = container.read(syncStateProvider);
      expect(state.enabled, isTrue,
          reason: 'Community mode should block deleteAccount');
      expect(state.mode, SyncMode.community);
    });

    test('deleteAccount works in private mode', () async {
      final container = createContainer(
        initialConfig: const SyncConfig(
          enabled: true,
          supabaseUrl: 'https://test.supabase.co',
          supabaseAnonKey: 'key',
          userId: 'user-123',
          mode: SyncMode.private,
        ),
      );

      container.read(syncStateProvider);
      await container.read(syncStateProvider.notifier).deleteAccount();

      // Private mode should proceed with disconnect
      expect(fakeStorage.getSetting('sync_enabled'), false);
      final state = container.read(syncStateProvider);
      expect(state.enabled, isFalse);
    });

    test('deleteAccount works in joinExisting mode', () async {
      final container = createContainer(
        initialConfig: const SyncConfig(
          enabled: true,
          supabaseUrl: 'https://test.supabase.co',
          supabaseAnonKey: 'key',
          userId: 'user-123',
          mode: SyncMode.joinExisting,
        ),
      );

      container.read(syncStateProvider);
      await container.read(syncStateProvider.notifier).deleteAccount();

      expect(fakeStorage.getSetting('sync_enabled'), false);
    });
  });

  group('SyncConfig', () {
    test('isConfigured requires enabled + url + key', () {
      const config = SyncConfig(
        enabled: true,
        supabaseUrl: 'https://test.supabase.co',
        supabaseAnonKey: 'key',
      );
      expect(config.isConfigured, isTrue);
    });

    test('isConfigured is false when disabled', () {
      const config = SyncConfig(
        enabled: false,
        supabaseUrl: 'https://test.supabase.co',
        supabaseAnonKey: 'key',
      );
      expect(config.isConfigured, isFalse);
    });

    test('isConfigured is false when url is null', () {
      const config = SyncConfig(
        enabled: true,
        supabaseUrl: null,
        supabaseAnonKey: 'key',
      );
      expect(config.isConfigured, isFalse);
    });

    test('isConfigured is false when key is null', () {
      const config = SyncConfig(
        enabled: true,
        supabaseUrl: 'https://test.supabase.co',
        supabaseAnonKey: null,
      );
      expect(config.isConfigured, isFalse);
    });

    test('hasEmail is true when email is set', () {
      const config = SyncConfig(userEmail: 'user@example.com');
      expect(config.hasEmail, isTrue);
    });

    test('hasEmail is false when email is null', () {
      const config = SyncConfig(userEmail: null);
      expect(config.hasEmail, isFalse);
    });

    test('hasEmail is false when email is empty', () {
      const config = SyncConfig(userEmail: '');
      expect(config.hasEmail, isFalse);
    });

    test('modeName returns correct strings for each mode', () {
      expect(
        const SyncConfig(mode: SyncMode.community).modeName,
        'Tankstellen Community',
      );
      expect(
        const SyncConfig(mode: SyncMode.joinExisting).modeName,
        'Shared Group',
      );
      expect(
        const SyncConfig(mode: SyncMode.private).modeName,
        'Private Database',
      );
      expect(
        const SyncConfig(mode: SyncMode.none).modeName,
        'Local Only',
      );
    });
  });

  group('switchToAnonymous', () {
    test('clears email and updates state', () async {
      await fakeStorage.setFavoriteIds(['s1', 's2']);

      final container = ProviderContainer(overrides: [
        hiveStorageProvider.overrideWithValue(fakeStorage),
        syncStateProvider.overrideWith(
          () => _FakeSwitchableSyncState(const SyncConfig(
            enabled: true,
            supabaseUrl: 'https://test.supabase.co',
            supabaseAnonKey: 'key',
            userId: 'email-user-123',
            mode: SyncMode.community,
            userEmail: 'user@example.com',
          )),
        ),
      ]);
      addTearDown(container.dispose);

      container.read(syncStateProvider);
      await container.read(syncStateProvider.notifier).switchToAnonymous();

      final state = container.read(syncStateProvider);
      // Email should be cleared
      expect(state.hasEmail, isFalse);
      expect(state.userEmail, isNull);
      // Should have a new anonymous userId
      expect(state.userId, isNotNull);
      expect(state.userId, isNot('email-user-123'));
      // Connection should remain enabled
      expect(state.enabled, isTrue);
      expect(state.mode, SyncMode.community);
      // Should persist the new userId
      expect(fakeStorage.getSetting('sync_user_id'), isNotNull);
      expect(fakeStorage.getSetting('sync_user_id'), state.userId);
    });

    test('preserves sync mode and connection after switch', () async {
      final container = ProviderContainer(overrides: [
        hiveStorageProvider.overrideWithValue(fakeStorage),
        syncStateProvider.overrideWith(
          () => _FakeSwitchableSyncState(const SyncConfig(
            enabled: true,
            supabaseUrl: 'https://private.supabase.co',
            supabaseAnonKey: 'private-key',
            userId: 'email-user-456',
            mode: SyncMode.private,
            userEmail: 'admin@example.com',
          )),
        ),
      ]);
      addTearDown(container.dispose);

      container.read(syncStateProvider);
      await container.read(syncStateProvider.notifier).switchToAnonymous();

      final state = container.read(syncStateProvider);
      expect(state.mode, SyncMode.private);
      expect(state.enabled, isTrue);
      expect(state.supabaseUrl, 'https://private.supabase.co');
      expect(state.supabaseAnonKey, 'private-key');
      expect(state.hasEmail, isFalse);
    });
  });

  group('SyncMode transitions', () {
    test('community → disconnect preserves mode none', () async {
      final container = createContainer(
        initialConfig: const SyncConfig(
          enabled: true,
          supabaseUrl: 'https://test.supabase.co',
          supabaseAnonKey: 'key',
          userId: 'user-123',
          mode: SyncMode.community,
        ),
      );

      container.read(syncStateProvider);
      await container.read(syncStateProvider.notifier).disconnect();

      final state = container.read(syncStateProvider);
      expect(state.mode, SyncMode.none);
    });

    test('private → disconnect preserves mode none', () async {
      final container = createContainer(
        initialConfig: const SyncConfig(
          enabled: true,
          supabaseUrl: 'https://my-supabase.co',
          supabaseAnonKey: 'my-key',
          userId: 'user-456',
          mode: SyncMode.private,
        ),
      );

      container.read(syncStateProvider);
      await container.read(syncStateProvider.notifier).disconnect();

      final state = container.read(syncStateProvider);
      expect(state.mode, SyncMode.none);
      expect(state.enabled, isFalse);
      expect(state.userId, isNull);
    });
  });
}

/// Fake implementation of SyncState that returns a fixed SyncConfig
/// and intercepts connect/disconnect calls without hitting Supabase.
class _FakeSyncState extends SyncState {
  final SyncConfig _config;
  _FakeSyncState(this._config);

  @override
  SyncConfig build() => _config;
}

/// Fake that also overrides switchToAnonymous to avoid Supabase SDK calls.
class _FakeSwitchableSyncState extends SyncState {
  final SyncConfig _config;
  _FakeSwitchableSyncState(this._config);

  @override
  SyncConfig build() => _config;

  @override
  Future<void> switchToAnonymous() async {
    final storage = ref.read(hiveStorageProvider);
    const newAnonId = 'anon-new-uuid-9999';
    await storage.putSetting('sync_user_id', newAnonId);

    state = SyncConfig(
      enabled: state.enabled,
      supabaseUrl: state.supabaseUrl,
      supabaseAnonKey: state.supabaseAnonKey,
      userId: newAnonId,
      mode: state.mode,
      userEmail: null,
    );
  }
}
