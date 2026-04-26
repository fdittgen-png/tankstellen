import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';
import 'package:tankstellen/features/sync/providers/data_transparency_provider.dart';

/// Unit tests for `data_transparency_provider.dart`.
///
/// Coverage scope:
///   - `DataTransparencyState` constructor + `copyWith` (fully unit-testable,
///     no external deps).
///   - `DataTransparencyController.build()` — default returned state.
///
/// Out-of-scope (deferred / future-work):
///   - `load()`, `forceSyncAndReload()`, `deleteAllData()` — these all call
///     into static `TankSyncClient` / `UserDataSync` / `FavoritesSync` /
///     `AlertsSync` methods that cannot be cleanly faked at the call site
///     without invasive refactoring. Documented as future-work for #561.
void main() {
  group('DataTransparencyState constructor', () {
    test('default loading is true, data and error are null', () {
      const s = DataTransparencyState();
      expect(s.loading, isTrue);
      expect(s.data, isNull);
      expect(s.error, isNull);
    });

    test('stores all fields when provided', () {
      const s = DataTransparencyState(
        data: {'k': 'v'},
        loading: false,
        error: 'oops',
      );
      expect(s.data, {'k': 'v'});
      expect(s.loading, isFalse);
      expect(s.error, 'oops');
    });
  });

  group('DataTransparencyState.copyWith', () {
    const base = DataTransparencyState(
      data: {'k': 'v'},
      loading: true,
      error: 'boom',
    );

    test('with no overrides preserves all fields', () {
      final next = base.copyWith();
      expect(next.data, {'k': 'v'});
      expect(next.loading, isTrue);
      expect(next.error, 'boom');
    });

    test('updates loading independently', () {
      final next = base.copyWith(loading: false);
      expect(next.loading, isFalse);
      expect(next.data, {'k': 'v'});
      expect(next.error, 'boom');
    });

    test('updates data independently', () {
      final next = base.copyWith(data: {'new': 1});
      expect(next.data, {'new': 1});
      expect(next.loading, isTrue);
      expect(next.error, 'boom');
    });

    test('updates error independently', () {
      final next = base.copyWith(error: 'new error');
      expect(next.error, 'new error');
      expect(next.data, {'k': 'v'});
      expect(next.loading, isTrue);
    });

    test('clearError nulls error even when an override is provided', () {
      // clearError trumps an explicit error override — the implementation
      // returns null when clearError is true, regardless of the error param.
      final next = base.copyWith(error: 'should be ignored', clearError: true);
      expect(next.error, isNull);
    });

    test('clearError nulls error when no override is provided', () {
      final next = base.copyWith(clearError: true);
      expect(next.error, isNull);
      expect(next.data, {'k': 'v'});
      expect(next.loading, isTrue);
    });

    test('clearData nulls data even when an override is provided', () {
      final next = base.copyWith(data: {'should': 'be ignored'}, clearData: true);
      expect(next.data, isNull);
    });

    test('clearData nulls data when no override is provided', () {
      final next = base.copyWith(clearData: true);
      expect(next.data, isNull);
      expect(next.loading, isTrue);
      expect(next.error, 'boom');
    });

    test('clearError defaults to false — error override is applied', () {
      final next = base.copyWith(error: 'replaced');
      expect(next.error, 'replaced');
    });

    test('clearData defaults to false — data override is applied', () {
      final next = base.copyWith(data: {'replaced': true});
      expect(next.data, {'replaced': true});
    });

    test('combined clearError + clearData wipes both', () {
      final next = base.copyWith(clearError: true, clearData: true);
      expect(next.data, isNull);
      expect(next.error, isNull);
      expect(next.loading, isTrue);
    });
  });

  group('DataTransparencyController.build', () {
    test('returns the default DataTransparencyState (loading=true)', () {
      // Override syncStateProvider so the kicked-off microtask, which calls
      // load() and reads syncStateProvider, finds a disabled config and
      // short-circuits at the "no user ID" branch — without ever touching
      // the static UserDataSync / TankSyncClient methods.
      final container = ProviderContainer(overrides: [
        syncStateProvider.overrideWith(_DisabledSync.new),
      ]);
      addTearDown(container.dispose);

      // Read SYNCHRONOUSLY before the microtask runs to capture initial state.
      final initial = container.read(dataTransparencyControllerProvider);
      expect(initial.loading, isTrue);
      expect(initial.data, isNull);
      expect(initial.error, isNull);
    });

    test(
      'after microtask runs with no user ID, state shows the expected error',
      () async {
        final container = ProviderContainer(overrides: [
          syncStateProvider.overrideWith(_DisabledSync.new),
        ]);
        addTearDown(container.dispose);

        // Subscribe so the provider isn't auto-disposed between the build
        // and the microtask that flips state out of loading.
        final sub = container.listen<DataTransparencyState>(
          dataTransparencyControllerProvider,
          (_, _) {},
          fireImmediately: true,
        );

        // Pump the microtask queue. `Future.microtask(load)` schedules load,
        // which (with no userId/session) sync-sets the error state and
        // returns before yielding.
        await Future<void>.delayed(Duration.zero);

        final after = sub.read();
        expect(after.loading, isFalse);
        expect(after.error, isNotNull);
        expect(after.error, contains('No user ID'));
        expect(after.data, isNull);
      },
    );
  });
}

class _DisabledSync extends SyncState {
  @override
  SyncConfig build() => const SyncConfig();
}
