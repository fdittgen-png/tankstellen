import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tankstellen/core/feedback/auto_record_badge_provider.dart';
import 'package:tankstellen/core/feedback/auto_record_badge_service.dart';

/// Unit tests for `auto_record_badge_provider.dart` (#561 zero-coverage
/// epic; service is already covered by
/// `auto_record_badge_service_test.dart` so we only exercise the
/// provider-side build/refresh/markAllAsRead orchestration here).
///
/// The Future-returning `autoRecordBadgeServiceProvider` is overridden
/// per-test so we never reach `SharedPreferences.getInstance()` from
/// the provider itself — except for the one resolution test at the
/// bottom which proves the real wiring still produces a service.
class _FakeAutoRecordBadgeService implements AutoRecordBadgeService {
  _FakeAutoRecordBadgeService({int initialCount = 0, this.throwOnMark = false})
      : _count = initialCount;

  int _count;
  int markAllCallCount = 0;
  bool throwOnMark;

  /// Allow tests to bump the underlying counter to simulate the
  /// service-side `increment` happening between provider reads.
  void setCount(int value) {
    _count = value;
  }

  @override
  int get count => _count;

  @override
  Future<void> markAllAsRead() async {
    markAllCallCount++;
    if (throwOnMark) {
      throw StateError('launcher rejected');
    }
    _count = 0;
  }

  // Unused by AutoRecordBadgeCount, but the interface requires them.
  @override
  Future<void> increment() async {
    _count++;
  }

  @override
  Future<void> decrement() async {
    if (_count > 0) _count--;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AutoRecordBadgeCount.build', () {
    test('returns 0 while the service future is still loading', () {
      // A never-completing future keeps the AsyncValue in the loading
      // state, exercising the `orElse: () => 0` branch in build().
      final pending = Completer<AutoRecordBadgeService>();
      addTearDown(() => pending.complete(_FakeAutoRecordBadgeService()));

      final container = ProviderContainer(
        overrides: [
          autoRecordBadgeServiceProvider
              .overrideWith((ref) => pending.future),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(autoRecordBadgeCountProvider), 0);
    });

    test('returns 0 once the service resolves with count == 0', () async {
      final fake = _FakeAutoRecordBadgeService();
      final container = ProviderContainer(
        overrides: [
          autoRecordBadgeServiceProvider.overrideWith((ref) async => fake),
        ],
      );
      addTearDown(container.dispose);

      // Drive the future to completion so the AsyncValue moves into
      // the data state.
      await container.read(autoRecordBadgeServiceProvider.future);
      expect(container.read(autoRecordBadgeCountProvider), 0);
    });

    test('returns the service count once the service resolves with 5',
        () async {
      final fake = _FakeAutoRecordBadgeService(initialCount: 5);
      final container = ProviderContainer(
        overrides: [
          autoRecordBadgeServiceProvider.overrideWith((ref) async => fake),
        ],
      );
      addTearDown(container.dispose);

      await container.read(autoRecordBadgeServiceProvider.future);
      expect(container.read(autoRecordBadgeCountProvider), 5);
    });

    test('rebuilds when the service future errors (orElse: 0)', () async {
      // Error case for the AsyncValue — the build() switch falls
      // through to `orElse: () => 0` instead of propagating.
      final container = ProviderContainer(
        overrides: [
          autoRecordBadgeServiceProvider
              .overrideWith((ref) async => throw StateError('prefs unavailable')),
        ],
      );
      addTearDown(container.dispose);

      // Wait for the future to settle into the error state.
      try {
        await container.read(autoRecordBadgeServiceProvider.future);
      } catch (_) {
        // Expected — we want the error state, not the value.
      }
      expect(container.read(autoRecordBadgeCountProvider), 0);
    });
  });

  group('AutoRecordBadgeCount.refresh', () {
    test('pushes the latest service.count into provider state', () async {
      final fake = _FakeAutoRecordBadgeService(initialCount: 2);
      final container = ProviderContainer(
        overrides: [
          autoRecordBadgeServiceProvider.overrideWith((ref) async => fake),
        ],
      );
      addTearDown(container.dispose);

      await container.read(autoRecordBadgeServiceProvider.future);
      expect(container.read(autoRecordBadgeCountProvider), 2);

      // Simulate the service-side counter changing (e.g. a background
      // increment from the trip-save path) and assert refresh() picks
      // it up.
      fake.setCount(7);
      await container.read(autoRecordBadgeCountProvider.notifier).refresh();
      expect(container.read(autoRecordBadgeCountProvider), 7);

      // And again — refresh is idempotent against a stable count and
      // tracks downward edges too.
      fake.setCount(3);
      await container.read(autoRecordBadgeCountProvider.notifier).refresh();
      expect(container.read(autoRecordBadgeCountProvider), 3);
    });

    test('swallows + logs errors when the service future fails', () async {
      // The service future resolves to an error from the start; build()
      // settles on 0 via `orElse`, and the subsequent refresh() must
      // catch the rethrown error from `await ref.read(...future)` and
      // log via debugPrint instead of propagating.
      final container = ProviderContainer(
        overrides: [
          autoRecordBadgeServiceProvider.overrideWith(
            (ref) async => throw StateError('prefs gone'),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Wait for the future to settle into the error state so the
      // initial build() observes it.
      try {
        await container.read(autoRecordBadgeServiceProvider.future);
      } catch (_) {
        // Expected.
      }
      expect(container.read(autoRecordBadgeCountProvider), 0);

      // refresh() must not propagate the error — that's the entire
      // contract of the catch branch.
      await expectLater(
        container.read(autoRecordBadgeCountProvider.notifier).refresh(),
        completes,
      );
      expect(container.read(autoRecordBadgeCountProvider), 0);
    });
  });

  group('AutoRecordBadgeCount.markAllAsRead', () {
    test('calls service.markAllAsRead exactly once and zeroes state',
        () async {
      final fake = _FakeAutoRecordBadgeService(initialCount: 6);
      final container = ProviderContainer(
        overrides: [
          autoRecordBadgeServiceProvider.overrideWith((ref) async => fake),
        ],
      );
      addTearDown(container.dispose);

      await container.read(autoRecordBadgeServiceProvider.future);
      expect(container.read(autoRecordBadgeCountProvider), 6);

      await container
          .read(autoRecordBadgeCountProvider.notifier)
          .markAllAsRead();

      expect(fake.markAllCallCount, 1);
      // The fake's markAllAsRead resets count to 0 (mirroring the real
      // service); the provider must reflect that immediately.
      expect(container.read(autoRecordBadgeCountProvider), 0);
    });

    test('swallows + logs when markAllAsRead throws — state unchanged',
        () async {
      final fake = _FakeAutoRecordBadgeService(
        initialCount: 9,
        throwOnMark: true,
      );
      final container = ProviderContainer(
        overrides: [
          autoRecordBadgeServiceProvider.overrideWith((ref) async => fake),
        ],
      );
      addTearDown(container.dispose);

      await container.read(autoRecordBadgeServiceProvider.future);
      expect(container.read(autoRecordBadgeCountProvider), 9);

      // Must not throw — markAllAsRead wraps service errors in a
      // debugPrint-only swallow to keep the trip-save path safe.
      await expectLater(
        container
            .read(autoRecordBadgeCountProvider.notifier)
            .markAllAsRead(),
        completes,
      );
      expect(fake.markAllCallCount, 1);
      // Service threw before mutating its counter, and the provider's
      // catch branch never reassigns state — so we stay at 9.
      expect(container.read(autoRecordBadgeCountProvider), 9);
    });

    test('swallows + logs when the service future itself fails', () async {
      // Distinct error path: the await on the service future throws
      // before we ever reach `service.markAllAsRead`. Guards the same
      // catch branch from a different angle. Build() settles on 0
      // because the error path falls through `orElse: () => 0`.
      final container = ProviderContainer(
        overrides: [
          autoRecordBadgeServiceProvider.overrideWith(
            (ref) async => throw StateError('prefs corrupted'),
          ),
        ],
      );
      addTearDown(container.dispose);

      try {
        await container.read(autoRecordBadgeServiceProvider.future);
      } catch (_) {
        // Expected.
      }
      expect(container.read(autoRecordBadgeCountProvider), 0);

      await expectLater(
        container
            .read(autoRecordBadgeCountProvider.notifier)
            .markAllAsRead(),
        completes,
      );
      // State is unchanged — the catch branch in markAllAsRead does
      // not reassign state when the service future fails.
      expect(container.read(autoRecordBadgeCountProvider), 0);
    });
  });

  group('autoRecordBadgeServiceProvider (real wiring)', () {
    test('resolves to a real AutoRecordBadgeService backed by SharedPreferences',
        () async {
      // Smoke test the real provider body — proves the
      // SharedPreferences.getInstance() path produces a usable service
      // without leaning on the override machinery.
      SharedPreferences.setMockInitialValues(const {});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service =
          await container.read(autoRecordBadgeServiceProvider.future);
      expect(service, isA<AutoRecordBadgeService>());
      // Fresh prefs => count starts at 0, exercising the real getter.
      expect(service.count, 0);
    });
  });
}
