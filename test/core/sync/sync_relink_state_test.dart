// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';

import '../../fakes/fake_hive_storage.dart';
import '../../helpers/silence_error_logger.dart';

/// #3449 — the relink-required state on the sync model: set by the launch
/// identity guard via [SyncState.markRelinkRequired], cleared by BOTH
/// exits (email sign-in re-links; "start fresh" mints a new anonymous
/// identity) because each constructs a fresh `SyncConfig`.
void main() {
  silenceErrorLoggerSpool();

  late FakeHiveStorage storage;
  late ProviderContainer container;

  setUp(() async {
    storage = FakeHiveStorage();
    await storage.putSetting('sync_enabled', true);
    await storage.putSetting('sync_user_id', 'old-uuid');
    container = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(storage),
    ]);
    addTearDown(container.dispose);
  });

  test('defaults to false and markRelinkRequired sets it, preserving the '
      'rest of the config', () {
    final before = container.read(syncStateProvider);
    expect(before.relinkRequired, isFalse);

    container.read(syncStateProvider.notifier).markRelinkRequired();

    final after = container.read(syncStateProvider);
    expect(after.relinkRequired, isTrue);
    expect(after.enabled, before.enabled);
    expect(after.userId, 'old-uuid',
        reason: 'the guard never rewrites the stored identity');
    expect(after.mode, before.mode);
  });

  test('an email sign-in (the re-link path) clears the flag', () async {
    final notifier = container.read(syncStateProvider.notifier);
    notifier.markRelinkRequired();
    expect(container.read(syncStateProvider).relinkRequired, isTrue);

    final result = await notifier.signInWithEmail(
      'driver@example.com',
      'secret',
      isSignUp: false,
      isAnonymous: false,
      signIn: (email, password) async => 'old-uuid',
    );

    expect(result, EmailAuthResult.completed);
    expect(container.read(syncStateProvider).relinkRequired, isFalse,
        reason: 'signing in re-links the identity — the warning must drop');
  });

  test('"start fresh" (switchToAnonymous) clears the flag knowingly',
      () async {
    final notifier = container.read(syncStateProvider.notifier);
    notifier.markRelinkRequired();
    expect(container.read(syncStateProvider).relinkRequired, isTrue);

    // No live Supabase in unit tests: signOut/signInAnonymously are safe
    // no-ops on the uninitialised client; the state transition is what
    // this test pins.
    await notifier.switchToAnonymous();

    expect(container.read(syncStateProvider).relinkRequired, isFalse);
    // Give the fire-and-forget _performInitialSync microtask a beat so it
    // finishes inside the test body (it no-ops unauthenticated).
    await Future<void>.delayed(Duration.zero);
  });
}
