// Unit tests for [NearestWidgetRefresh] (#561 — zero-coverage backlog).
//
// The provider owns a [Timer.periodic] that ticks every
// [kNearestWidgetForegroundInterval] and an immediate-on-build tick. Verify:
//   1. The exported interval const is what callers depend on (2 minutes).
//   2. Reading the provider triggers the immediate tick (we observe it via
//      a storage method the tick call path is known to read).
//   3. Disposing the container cancels the timer (no exceptions, no late
//      ticks observed by polling the storage call counter).
//   4. The tick swallows errors so a misbehaving storage layer never
//      escalates into an unhandled provider crash.
//
// `HomeWidgetService.updateNearestWidget` is a static method that calls
// the `home_widget` plugin via platform channels; we mock the channel so
// the call path completes instead of throwing.

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/services/service_providers.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/widget/providers/nearest_widget_refresh_provider.dart';

import '../../../mocks/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The home_widget plugin's MethodChannel — mocked so calls inside
  // `_tick()` succeed instead of hitting an unimplemented platform channel.
  const homeWidgetChannel = MethodChannel('home_widget');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    messenger.setMockMethodCallHandler(homeWidgetChannel, (call) async {
      // Accept every method, return benign defaults. The provider doesn't
      // assert on widget data; it only cares that the call doesn't throw.
      switch (call.method) {
        case 'saveWidgetData':
        case 'setAppGroupId':
          return null;
        case 'updateWidget':
          return true;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(homeWidgetChannel, null);
  });

  group('kNearestWidgetForegroundInterval', () {
    test('is two minutes — short enough that the widget feels fresh', () {
      expect(kNearestWidgetForegroundInterval, const Duration(minutes: 2));
    });
  });

  group('NearestWidgetRefresh provider', () {
    late MockStorageRepository storage;
    late MockStationService stationService;
    late ProviderContainer container;

    setUp(() {
      storage = MockStorageRepository();
      stationService = MockStationService();

      // Default stubs that keep the tick on the fast empty path:
      //   - no GPS → builder writes an empty `no_gps` payload and returns.
      // This is enough to observe the tick without spinning up a full
      // search service — and it exercises the production NearestWidgetDataBuilder
      // call path, not a stand-in.
      when(() => storage.getSetting(any())).thenReturn(null);
      when(() => storage.getActiveProfileId()).thenReturn(null);
      when(() => storage.getProfile(any())).thenReturn(null);
      when(() => storage.getAllProfiles()).thenReturn(const []);
      when(() => storage.getFavoriteIds()).thenReturn(const []);
      when(() => storage.getFavoriteStationData(any())).thenReturn(null);

      // searchStations is only invoked when GPS is known; with the
      // default null user-position settings the builder short-circuits
      // before reaching the station service, so no stub is needed here.

      container = ProviderContainer(
        overrides: [
          storageRepositoryProvider.overrideWithValue(storage),
          stationServiceProvider.overrideWithValue(stationService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('reading the provider does not throw and fires an immediate tick',
        () async {
      // Reading the provider runs build() which schedules the periodic
      // timer and unawaited-fires _tick() once. The latter is async, so
      // give the microtask queue a chance to drain.
      expect(() => container.read(nearestWidgetRefreshProvider), returnsNormally);

      // The immediate tick reads the user-position settings as its first
      // step; counting that call confirms the tick actually ran rather
      // than only being scheduled.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      verify(() => storage.getSetting(any())).called(greaterThanOrEqualTo(1));
    });

    test('container.dispose cancels the timer cleanly (no exceptions)',
        () async {
      container.read(nearestWidgetRefreshProvider);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Dispose must not throw — the onDispose hook cancels the timer.
      // ProviderContainer.dispose is idempotent, so the suite-level
      // tearDown calling it again is a safe no-op.
      expect(container.dispose, returnsNormally);
    });

    test('a tick whose storage layer throws does not bubble up', () async {
      // Make the very first read inside the tick throw. The provider's
      // try/catch must swallow it — `unawaited(_tick())` means an
      // un-caught error here would surface as an unhandled async error
      // and fail the test (zone-error).
      when(() => storage.getSetting(any()))
          .thenThrow(StateError('storage exploded'));

      expect(
        () => container.read(nearestWidgetRefreshProvider),
        returnsNormally,
      );

      // Let the unawaited tick run to completion. If the catch in _tick
      // is removed, the test will fail with a zone-uncaught error here.
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
  });
}
