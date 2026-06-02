// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/network/connectivity_service.dart';
import 'package:tankstellen/core/services/service_providers.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/widget/providers/nearest_widget_refresh_provider.dart';
import '../../../helpers/silence_error_logger.dart';

import '../../../fakes/fake_hive_storage.dart';
import '../../../fakes/fake_storage_repository.dart';
import '../../../mocks/mocks.dart';

void main() {
  silenceErrorLoggerSpool();
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
    late _SettingsCountingFake countingStorage;
    late FakeStorageRepository storage;
    late MockStationService stationService;
    late ProviderContainer container;

    setUp(() {
      countingStorage = _SettingsCountingFake();
      storage = FakeStorageRepository(inner: countingStorage);
      stationService = MockStationService();

      // The default empty fake state already short-circuits the
      // NearestWidgetDataBuilder on the no-GPS path (no profile, no
      // favourites, no user-position settings) so the tick path is
      // exercised end-to-end without needing the station service.

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
      expect(() => container.read(nearestWidgetRefreshProvider),
          returnsNormally);

      // The immediate tick reads the user-position settings as its first
      // step; counting that call confirms the tick actually ran rather
      // than only being scheduled.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(countingStorage.getSettingCalls, greaterThanOrEqualTo(1));
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

    // #2703 — the nearest-widget refresh hits the network. When the device
    // is offline the call is doomed and ERROR-logged (the field-log offline
    // home-widget refresh). `_tick` must read connectivity and skip the
    // nearest-widget network refresh while offline, WITHOUT touching the
    // station service — but the local-only favorites `updateWidget` still
    // runs (it never errored).
    group('offline guard (#2703)', () {
      late _CountingStationService countingService;

      ProviderContainer makeContainer({required bool online}) {
        countingService = _CountingStationService();
        // A profile + a known GPS fix so the nearest builder WOULD call
        // searchStations when online (otherwise the no-GPS path
        // short-circuits and the test proves nothing).
        final fake = FakeHiveStorage();
        fake.putSetting(StorageKeys.userPositionLat, 43.44);
        fake.putSetting(StorageKeys.userPositionLng, 3.44);
        fake.saveProfile('p1', const {
          'id': 'p1',
          'name': 'Std',
          'preferredFuelType': 'e10',
          'defaultSearchRadius': 10.0,
        });
        fake.setActiveProfileId('p1');
        final repo = FakeStorageRepository(inner: fake);

        return ProviderContainer(
          overrides: [
            storageRepositoryProvider.overrideWithValue(repo),
            stationServiceProvider.overrideWithValue(countingService),
            currentConnectivityProvider.overrideWith((ref) async => online),
          ],
        );
      }

      test('offline tick does NOT call the station service', () async {
        final c = makeContainer(online: false);
        addTearDown(c.dispose);

        c.read(nearestWidgetRefreshProvider);
        await Future<void>.delayed(const Duration(milliseconds: 80));

        expect(countingService.searchCalls, 0,
            reason: 'an offline tick must skip the nearest-widget network '
                'refresh (the doomed offline call, #2703)');
      });

      test('online tick DOES call the station service (control)', () async {
        final c = makeContainer(online: true);
        addTearDown(c.dispose);

        c.read(nearestWidgetRefreshProvider);
        await Future<void>.delayed(const Duration(milliseconds: 80));

        expect(countingService.searchCalls, greaterThanOrEqualTo(1),
            reason: 'when online the nearest-widget refresh still runs');
      });
    });

    test('a tick whose storage layer throws does not bubble up', () async {
      // Wire a fake whose getSetting throws on every call. The provider's
      // try/catch must swallow it — `unawaited(_tick())` means an
      // un-caught error here would surface as an unhandled async error
      // and fail the test (zone-error).
      final throwingStorage = FakeStorageRepository(inner: _ThrowingFake());

      final localContainer = ProviderContainer(
        overrides: [
          storageRepositoryProvider.overrideWithValue(throwingStorage),
          stationServiceProvider.overrideWithValue(stationService),
        ],
      );
      addTearDown(localContainer.dispose);

      expect(
        () => localContainer.read(nearestWidgetRefreshProvider),
        returnsNormally,
      );

      // Let the unawaited tick run to completion. If the catch in _tick
      // is removed, the test will fail with a zone-uncaught error here.
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
  });
}

/// Fake variant that counts how many times `getSetting` is called — the
/// proxy used here for "did the tick fire?".
class _SettingsCountingFake extends FakeHiveStorage {
  int getSettingCalls = 0;

  @override
  dynamic getSetting(String key) {
    getSettingCalls++;
    return super.getSetting(key);
  }
}

/// Fake variant whose getSetting throws — used to exercise the tick's
/// outer catch.
class _ThrowingFake extends FakeHiveStorage {
  @override
  dynamic getSetting(String key) {
    throw StateError('storage exploded');
  }
}

/// #2703 — counts `searchStations` calls so the offline guard can be proven:
/// 0 while offline (the nearest refresh is skipped), ≥1 while online.
class _CountingStationService implements StationService {
  int searchCalls = 0;

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    searchCalls++;
    return ServiceResult(
      data: const [],
      source: ServiceSource.cache,
      fetchedAt: DateTime.now(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}
