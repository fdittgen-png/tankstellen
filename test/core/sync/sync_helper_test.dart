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
    test('calls syncFn when sync is enabled', () async {
      bool wasCalled = false;

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
        (ref) => SyncHelper.syncIfEnabled(
          ref,
          'test-context',
          () async {
            wasCalled = true;
          },
        ),
      );

      expect(wasCalled, isFalse);
    });

    test('calls syncFn when enabled even if Hive userId is null', () async {
      // This is the key fix: SyncService uses session userId, not Hive's.
      // SyncHelper should not block sync just because Hive userId is null.
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
          () async {
            wasCalled = true;
          },
        ),
      );

      expect(wasCalled, isTrue,
          reason: 'SyncService checks session auth independently — '
              'SyncHelper should not duplicate that check');
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
          () async {
            throw Exception('Sync failed!');
          },
        ),
      );

      // Reaching here without throwing confirms the exception was caught
    });
  });

  group('SyncHelper.fireAndForget', () {
    test('calls syncFn when sync is enabled', () async {
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

    test('catches syncFn exception silently without rethrowing', () async {
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
