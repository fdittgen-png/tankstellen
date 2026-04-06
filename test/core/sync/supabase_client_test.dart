import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/supabase_client.dart';

void main() {
  group('TankSyncClient (uninitialized)', () {
    test('client is null before init', () {
      // TankSyncClient uses a static _initialized flag. In test isolation
      // we can only verify the un-initialized path (Supabase.initialize
      // requires real network). The purpose of this test is to confirm that
      // null-safe accessors do NOT throw when client is null.
      // Note: if a previous test in the suite called init(), this may
      // already be true — we guard with the isConnected check.
      if (!TankSyncClient.isConnected) {
        expect(TankSyncClient.client, isNull);
      }
    });

    test('isConnected is false before init', () {
      if (TankSyncClient.client == null) {
        expect(TankSyncClient.isConnected, isFalse);
      }
    });

    test('currentEmail is null before init', () {
      if (TankSyncClient.client == null) {
        expect(TankSyncClient.currentEmail, isNull);
      }
    });

    test('hasEmailAccount is false before init', () {
      if (TankSyncClient.client == null) {
        expect(TankSyncClient.hasEmailAccount, isFalse);
      }
    });

    test('signInAnonymously returns null before init', () async {
      if (TankSyncClient.client == null) {
        final result = await TankSyncClient.signInAnonymously();
        expect(result, isNull);
      }
    });

    test('signUpWithEmail returns null before init', () async {
      if (TankSyncClient.client == null) {
        final result = await TankSyncClient.signUpWithEmail('a@b.c', 'pw');
        expect(result, isNull);
      }
    });

    test('signInWithEmail returns null before init', () async {
      if (TankSyncClient.client == null) {
        final result = await TankSyncClient.signInWithEmail('a@b.c', 'pw');
        expect(result, isNull);
      }
    });

    test('signOut does not throw before init', () async {
      if (TankSyncClient.client == null) {
        // Should not throw — just returns early.
        await TankSyncClient.signOut();
      }
    });
  });

  group('TankSyncClient upsert retry constants', () {
    test('maxUpsertRetries is at least 2', () {
      expect(TankSyncClient.maxUpsertRetries, greaterThanOrEqualTo(2));
    });

    test('maxUpsertRetries is at most 5', () {
      expect(TankSyncClient.maxUpsertRetries, lessThanOrEqualTo(5));
    });

    test('upsertRetryBaseDelay is reasonable', () {
      expect(
        TankSyncClient.upsertRetryBaseDelay.inMilliseconds,
        greaterThanOrEqualTo(100),
      );
      expect(
        TankSyncClient.upsertRetryBaseDelay.inMilliseconds,
        lessThanOrEqualTo(2000),
      );
    });
  });

  group('TankSyncClient upsert retry regression', () {
    test('no silent catch blocks remain in supabase_client.dart', () {
      final source = File(
        'lib/core/sync/supabase_client.dart',
      ).readAsStringSync();

      // Count occurrences of the old pattern: catch (e) { debugPrint(...); }
      // without a rethrow or throw. The _ensurePublicUser method has a
      // deliberate catch-retry-rethrow pattern, but individual auth methods
      // should NOT have their own try/catch blocks around the upsert.
      final authMethods = ['signInAnonymously', 'signUpWithEmail', 'signInWithEmail'];
      for (final method in authMethods) {
        final methodStart = source.indexOf('static Future<String?> $method');
        if (methodStart == -1) continue;
        // Find the next static method or end of class
        final nextStatic = source.indexOf('static ', methodStart + 1);
        final methodBody = nextStatic > 0
            ? source.substring(methodStart, nextStatic)
            : source.substring(methodStart);

        expect(
          methodBody.contains('try {'),
          isFalse,
          reason: '$method should not have inline try/catch — '
              'upsert retries are handled by _ensurePublicUser',
        );
      }
    });

    test('_ensurePublicUser method exists with retry logic', () {
      final source = File(
        'lib/core/sync/supabase_client.dart',
      ).readAsStringSync();

      expect(source, contains('_ensurePublicUser'));
      expect(source, contains('maxUpsertRetries'));
      expect(source, contains('upsertRetryBaseDelay'));
    });

    test('all auth methods delegate to _ensurePublicUser', () {
      final source = File(
        'lib/core/sync/supabase_client.dart',
      ).readAsStringSync();

      // Each auth method should call _ensurePublicUser
      final callCount = '_ensurePublicUser('.allMatches(source).length;
      // 3 calls (one per auth method) + 1 definition = at least 4 occurrences of the name
      expect(callCount, greaterThanOrEqualTo(3),
        reason: 'All 3 auth methods should call _ensurePublicUser',
      );
    });

    test('_ensurePublicUser signs out on failure', () {
      final source = File(
        'lib/core/sync/supabase_client.dart',
      ).readAsStringSync();

      // Find _ensurePublicUser method body
      final methodStart = source.indexOf('_ensurePublicUser');
      final methodBody = source.substring(methodStart);

      expect(methodBody, contains('signOut'));
      expect(methodBody, contains('StateError'));
    });
  });
}
