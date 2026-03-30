import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/core/sync/sync_helper.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';

/// Helper to run SyncHelper methods with a controlled SyncConfig.
///
/// We create a ProviderContainer with syncStateProvider overridden,
/// then use a temporary provider to extract a Ref for SyncHelper.
Future<void> _runWithSyncConfig(
  SyncConfig config,
  Future<void> Function(Ref ref) action,
) async {
  final container = ProviderContainer(
    overrides: [
      syncStateProvider.overrideWith(() => _FakeSyncState(config)),
    ],
  );
  // Force-read to initialize the override
  container.read(syncStateProvider);

  // We need a Ref, so we use a FutureProvider trick
  late Ref capturedRef;
  final refCapture = Provider<int>((ref) {
    capturedRef = ref;
    return 0;
  });
  container.read(refCapture);

  try {
    await action(capturedRef);
  } finally {
    container.dispose();
  }
}

void main() {
  group('SyncHelper.syncIfEnabled', () {
    test('calls syncFn with userId when sync is enabled and userId is set',
        () async {
      String? receivedUserId;

      await _runWithSyncConfig(
        const SyncConfig(
          enabled: true,
          userId: 'user-123',
          supabaseUrl: 'https://test.supabase.co',
          supabaseAnonKey: 'test-key',
        ),
        (ref) => SyncHelper.syncIfEnabled(
          ref,
          'test-context',
          (userId) async {
            receivedUserId = userId;
          },
        ),
      );

      expect(receivedUserId, 'user-123');
    });

    test('does NOT call syncFn when sync is disabled', () async {
      bool wasCalled = false;

      await _runWithSyncConfig(
        const SyncConfig(
          enabled: false,
          userId: 'user-123',
        ),
        (ref) => SyncHelper.syncIfEnabled(
          ref,
          'test-context',
          (userId) async {
            wasCalled = true;
          },
        ),
      );

      expect(wasCalled, isFalse);
    });

    test('does NOT call syncFn when userId is null', () async {
      bool wasCalled = false;

      await _runWithSyncConfig(
        const SyncConfig(
          enabled: true,
          userId: null,
          supabaseUrl: 'https://test.supabase.co',
          supabaseAnonKey: 'test-key',
        ),
        (ref) => SyncHelper.syncIfEnabled(
          ref,
          'test-context',
          (userId) async {
            wasCalled = true;
          },
        ),
      );

      expect(wasCalled, isFalse);
    });

    test('catches syncFn exception silently without rethrowing', () async {
      // Should complete without throwing
      await _runWithSyncConfig(
        const SyncConfig(
          enabled: true,
          userId: 'user-123',
          supabaseUrl: 'https://test.supabase.co',
          supabaseAnonKey: 'test-key',
        ),
        (ref) => SyncHelper.syncIfEnabled(
          ref,
          'test-context',
          (userId) async {
            throw Exception('Sync failed!');
          },
        ),
      );

      // If we reach here, the exception was caught silently
      expect(true, isTrue);
    });

    test('does NOT call syncFn when enabled but userId empty string treated as set',
        () async {
      // Edge case: userId is empty string (truthy but empty)
      String? receivedUserId;

      await _runWithSyncConfig(
        const SyncConfig(
          enabled: true,
          userId: '',
          supabaseUrl: 'https://test.supabase.co',
          supabaseAnonKey: 'test-key',
        ),
        (ref) => SyncHelper.syncIfEnabled(
          ref,
          'test-context',
          (userId) async {
            receivedUserId = userId;
          },
        ),
      );

      // Empty string is not null, so syncFn should be called
      expect(receivedUserId, '');
    });
  });

  group('SyncHelper.fireAndForget', () {
    test('calls syncFn when sync is enabled and userId is set', () async {
      bool wasCalled = false;

      await _runWithSyncConfig(
        const SyncConfig(
          enabled: true,
          userId: 'user-123',
          supabaseUrl: 'https://test.supabase.co',
          supabaseAnonKey: 'test-key',
        ),
        (ref) => SyncHelper.fireAndForget(
          ref,
          'test-context',
          () async {
            wasCalled = true;
          },
        ),
      );

      expect(wasCalled, isTrue);
    });

    test('does NOT call syncFn when sync is disabled', () async {
      bool wasCalled = false;

      await _runWithSyncConfig(
        const SyncConfig(
          enabled: false,
          userId: 'user-123',
        ),
        (ref) => SyncHelper.fireAndForget(
          ref,
          'test-context',
          () async {
            wasCalled = true;
          },
        ),
      );

      expect(wasCalled, isFalse);
    });

    test('does NOT call syncFn when userId is null', () async {
      bool wasCalled = false;

      await _runWithSyncConfig(
        const SyncConfig(
          enabled: true,
          userId: null,
          supabaseUrl: 'https://test.supabase.co',
          supabaseAnonKey: 'test-key',
        ),
        (ref) => SyncHelper.fireAndForget(
          ref,
          'test-context',
          () async {
            wasCalled = true;
          },
        ),
      );

      expect(wasCalled, isFalse);
    });

    test('catches syncFn exception silently without rethrowing', () async {
      // Should complete without throwing
      await _runWithSyncConfig(
        const SyncConfig(
          enabled: true,
          userId: 'user-123',
          supabaseUrl: 'https://test.supabase.co',
          supabaseAnonKey: 'test-key',
        ),
        (ref) => SyncHelper.fireAndForget(
          ref,
          'test-context',
          () async {
            throw Exception('Fire and forget failed!');
          },
        ),
      );

      // If we reach here, the exception was caught silently
      expect(true, isTrue);
    });
  });
}

/// Fake implementation of SyncState that returns a fixed SyncConfig.
class _FakeSyncState extends SyncState {
  final SyncConfig _config;
  _FakeSyncState(this._config);

  @override
  SyncConfig build() => _config;
}
