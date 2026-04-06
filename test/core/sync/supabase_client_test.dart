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
}
