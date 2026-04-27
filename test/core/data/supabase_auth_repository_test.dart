import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/auth_repository.dart';
import 'package:tankstellen/core/data/impl/supabase_auth_repository.dart';

/// Tests that [SupabaseAuthRepository] is a thin adapter delegating to
/// [TankSyncClient]'s static methods. Since TankSyncClient is not initialized
/// in tests, all methods hit the "no client" fallback path — returning
/// null / false / no-op. This verifies the delegation works end-to-end.
void main() {
  late SupabaseAuthRepository repo;

  setUp(() {
    repo = SupabaseAuthRepository();
  });

  group('SupabaseAuthRepository implements AuthRepository', () {
    test('is an AuthRepository', () {
      expect(repo, isA<AuthRepository>());
    });

    test('isConnected returns false when TankSyncClient not initialized', () {
      expect(repo.isConnected, isFalse);
    });

    test('currentEmail returns null when not connected', () {
      expect(repo.currentEmail, isNull);
    });

    test('hasEmailAccount returns false when not connected', () {
      expect(repo.hasEmailAccount, isFalse);
    });
  });

  group('SupabaseAuthRepository - unauthenticated delegation', () {
    // All methods delegate to TankSyncClient static methods.
    // Without an initialized client, sign-in methods return null
    // and signOut is a no-op.

    test('signInAnonymously returns null when client not initialized',
        () async {
      final result = await repo.signInAnonymously();
      expect(result, isNull);
    });

    test('signUpWithEmail returns null when client not initialized', () async {
      final result = await repo.signUpWithEmail(
        'test@example.com',
        'password123',
      );
      expect(result, isNull);
    });

    test('signInWithEmail returns null when client not initialized', () async {
      final result = await repo.signInWithEmail(
        'test@example.com',
        'password123',
      );
      expect(result, isNull);
    });

    test('signOut completes without error when client not initialized',
        () async {
      // Should not throw — just no-ops when client is null
      await expectLater(repo.signOut(), completes);
    });
  });

  group('SupabaseAuthRepository - init validation', () {
    // init() delegates to TankSyncClient.init, which validates the URL
    // before touching Supabase. Invalid URLs should throw ArgumentError.

    test('init throws ArgumentError on invalid URL', () async {
      await expectLater(
        repo.init(url: 'not-a-url', anonKey: 'anon'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('init throws ArgumentError on empty URL', () async {
      await expectLater(
        repo.init(url: '', anonKey: 'anon'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
