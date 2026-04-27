import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/auth_repository.dart';
import 'package:tankstellen/core/data/data_providers.dart';
import 'package:tankstellen/core/data/impl/supabase_auth_repository.dart';
import 'package:tankstellen/core/data/impl/supabase_sync_repository.dart';
import 'package:tankstellen/core/data/sync_repository.dart';

/// Tests the Riverpod factory providers in [data_providers.dart].
///
/// These providers are `@Riverpod(keepAlive: true)` — they wire the abstract
/// repository interfaces to concrete Supabase implementations. The test
/// verifies the factory wiring, the type erasure to the abstract interface,
/// and the keepAlive caching contract (same instance on second read).
void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('syncRepositoryProvider', () {
    test('returns a SupabaseSyncRepository instance', () {
      final repo = container.read(syncRepositoryProvider);
      expect(repo, isA<SupabaseSyncRepository>());
    });

    test('exposes the SyncRepository abstract interface', () {
      final repo = container.read(syncRepositoryProvider);
      expect(repo, isA<SyncRepository>());
    });

    test('returns the same instance on second read (keepAlive caching)', () {
      final first = container.read(syncRepositoryProvider);
      final second = container.read(syncRepositoryProvider);
      expect(identical(first, second), isTrue);
    });
  });

  group('authRepositoryProvider', () {
    test('returns a SupabaseAuthRepository instance', () {
      final repo = container.read(authRepositoryProvider);
      expect(repo, isA<SupabaseAuthRepository>());
    });

    test('exposes the AuthRepository abstract interface', () {
      final repo = container.read(authRepositoryProvider);
      expect(repo, isA<AuthRepository>());
    });

    test('returns the same instance on second read (keepAlive caching)', () {
      final first = container.read(authRepositoryProvider);
      final second = container.read(authRepositoryProvider);
      expect(identical(first, second), isTrue);
    });
  });

  group('provider isolation', () {
    test('sync and auth providers return different instances', () {
      final sync = container.read(syncRepositoryProvider);
      final auth = container.read(authRepositoryProvider);
      expect(identical(sync, auth), isFalse);
    });

    test('a fresh container produces a fresh sync repository', () {
      final repoA = container.read(syncRepositoryProvider);

      final containerB = ProviderContainer();
      addTearDown(containerB.dispose);
      final repoB = containerB.read(syncRepositoryProvider);

      expect(identical(repoA, repoB), isFalse);
    });

    test('a fresh container produces a fresh auth repository', () {
      final repoA = container.read(authRepositoryProvider);

      final containerB = ProviderContainer();
      addTearDown(containerB.dispose);
      final repoB = containerB.read(authRepositoryProvider);

      expect(identical(repoA, repoB), isFalse);
    });
  });
}
