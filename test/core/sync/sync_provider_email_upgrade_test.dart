// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';

import '../../fakes/fake_hive_storage.dart';

/// Tests for #3079 — email-based cross-device identity.
///
/// The cross-device bug was that Community mode uses a PER-DEVICE anonymous
/// UUID, so a second device never sees the first device's favorites/trips.
/// The fix attaches an email to the CURRENT anonymous account, upgrading it
/// **in place** so the SAME UUID is reusable on every device. The old
/// `signUpWithEmail` minted a brand-new UUID and orphaned the data.
///
/// These tests drive the REAL [SyncState.signInWithEmail] (no override of
/// the method under test) through its injectable [EmailAuthFn] seams — the
/// same seam shape #3076 used for [IdMergeFn] — and assert the branch
/// selection deterministically:
///
/// - anonymous + sign-up  → UPGRADE in place (UUID preserved)
/// - not anonymous + sign-up → fresh signUp (no anon session to upgrade)
/// - sign-in (existing account) → signIn (second device)
///
/// The post-auth `_performInitialSync` is a safe no-op here: with no live
/// Supabase client `FavoritesSync.merge` / `IgnoredStationsSync.merge`
/// return their input unchanged, so nothing networks and local data is
/// untouched. `TankSyncClient.currentEmail` is `null` in the test isolate,
/// so an anonymous in-place upgrade reports [EmailAuthResult.confirmationPending]
/// — exactly the "server requires confirmation" UX path — while sign-up
/// and sign-in (where the session email is not gating) report
/// [EmailAuthResult.completed].
void main() {
  late FakeHiveStorage fakeStorage;

  setUp(() {
    fakeStorage = FakeHiveStorage();
  });

  ProviderContainer createContainer(SyncConfig config) {
    final c = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(fakeStorage),
      syncStateProvider.overrideWith(() => _FixedSyncState(config)),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('SyncState.signInWithEmail branch selection (#3079)', () {
    test('anonymous + sign-up → UPGRADE in place, preserves the UUID',
        () async {
      final calls = <String>[];
      final container = createContainer(const SyncConfig(
        enabled: true,
        supabaseUrl: 'https://test.supabase.co',
        supabaseAnonKey: 'key',
        userId: 'anon-uuid-96a8bbd7',
        mode: SyncMode.community,
      ));
      final notifier = container.read(syncStateProvider.notifier);

      final result = await notifier.signInWithEmail(
        'me@example.com',
        'pw',
        isSignUp: true,
        isAnonymous: true,
        // The upgrade PRESERVES the existing UUID.
        upgrade: (e, p) async {
          calls.add('upgrade');
          return 'anon-uuid-96a8bbd7';
        },
        signUp: (e, p) async {
          calls.add('signUp');
          return 'WRONG-fresh-uuid';
        },
        signIn: (e, p) async {
          calls.add('signIn');
          return 'WRONG-signin-uuid';
        },
      );

      expect(calls, ['upgrade'],
          reason: 'anonymous sign-up must upgrade in place, not signUp');
      // UUID preserved end-to-end — the data stays owned by this id.
      final state = container.read(syncStateProvider);
      expect(state.userId, 'anon-uuid-96a8bbd7');
      expect(fakeStorage.getSetting('sync_user_id'), 'anon-uuid-96a8bbd7');
      // No live session email in the test isolate → confirmation-pending,
      // and the entered email is shown so the user knows what to confirm.
      expect(result, EmailAuthResult.confirmationPending);
      expect(state.userEmail, 'me@example.com');
    });

    test('NOT anonymous + sign-up → signUp (no anon session to upgrade)',
        () async {
      final calls = <String>[];
      final container = createContainer(const SyncConfig(
        enabled: true,
        supabaseUrl: 'https://test.supabase.co',
        supabaseAnonKey: 'key',
        mode: SyncMode.community,
      ));
      final notifier = container.read(syncStateProvider.notifier);

      final result = await notifier.signInWithEmail(
        'new@example.com',
        'pw',
        isSignUp: true,
        isAnonymous: false,
        upgrade: (e, p) async {
          calls.add('upgrade');
          return 'WRONG-upgrade-uuid';
        },
        signUp: (e, p) async {
          calls.add('signUp');
          return 'fresh-uuid';
        },
        signIn: (e, p) async {
          calls.add('signIn');
          return 'WRONG-signin-uuid';
        },
      );

      expect(calls, ['signUp'],
          reason: 'with no anon session, sign-up creates a fresh account');
      expect(result, EmailAuthResult.completed);
      expect(container.read(syncStateProvider).userId, 'fresh-uuid');
    });

    test('sign-in (existing account, second device) → signIn', () async {
      final calls = <String>[];
      final container = createContainer(const SyncConfig(
        enabled: true,
        supabaseUrl: 'https://test.supabase.co',
        supabaseAnonKey: 'key',
        // A transient anon session on device 2, but the user has an
        // EXISTING email account from device 1 → they sign IN.
        userId: 'device2-anon',
        mode: SyncMode.community,
      ));
      final notifier = container.read(syncStateProvider.notifier);

      final result = await notifier.signInWithEmail(
        'me@example.com',
        'pw',
        isSignUp: false,
        isAnonymous: true, // even with a transient anon session present
        upgrade: (e, p) async {
          calls.add('upgrade');
          return 'WRONG-upgrade-uuid';
        },
        signUp: (e, p) async {
          calls.add('signUp');
          return 'WRONG-fresh-uuid';
        },
        signIn: (e, p) async {
          calls.add('signIn');
          return 'shared-account-uuid';
        },
      );

      expect(calls, ['signIn'],
          reason: 'sign-in must reuse the existing shared account UUID');
      expect(result, EmailAuthResult.completed);
      // Device 2 adopts the shared account id — cross-device identity.
      expect(container.read(syncStateProvider).userId, 'shared-account-uuid');
      expect(fakeStorage.getSetting('sync_user_id'), 'shared-account-uuid');
    });

    test('null user id from the auth call → failed, no state change',
        () async {
      final calls = <String>[];
      final container = createContainer(const SyncConfig(
        enabled: true,
        supabaseUrl: 'https://test.supabase.co',
        supabaseAnonKey: 'key',
        userId: 'anon-uuid',
        mode: SyncMode.community,
      ));
      final notifier = container.read(syncStateProvider.notifier);

      final result = await notifier.signInWithEmail(
        'me@example.com',
        'pw',
        isSignUp: true,
        isAnonymous: true,
        upgrade: (e, p) async {
          calls.add('upgrade');
          return null;
        },
        signUp: (e, p) async => 'WRONG',
        signIn: (e, p) async => 'WRONG',
      );

      expect(calls, ['upgrade']);
      expect(result, EmailAuthResult.failed);
      // Original anon id untouched.
      expect(container.read(syncStateProvider).userId, 'anon-uuid');
      expect(fakeStorage.getSetting('sync_user_id'), isNull);
    });
  });
}

/// Fake [SyncState] that returns a fixed [SyncConfig] without touching
/// Supabase. The method under test, [SyncState.signInWithEmail], is
/// **inherited unmodified** — only the seam args are injected — so the
/// production branch-selection logic is exercised verbatim.
class _FixedSyncState extends SyncState {
  final SyncConfig _config;
  _FixedSyncState(this._config);

  @override
  SyncConfig build() => _config;
}
