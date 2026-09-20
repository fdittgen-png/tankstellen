// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/services/service_providers.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/favorites/providers/favorite_stations_provider.dart';

import '../../../fakes/fake_hive_storage.dart';
import '../../../helpers/silence_error_logger.dart';
import '../../../mocks/mocks.dart';

/// Records every `state =` so the test can prove the resume wrote none.
class _SpyFavoriteStations extends FavoriteStations {
  final writes = <AsyncValue<ServiceResult<List<Station>>>>[];

  @override
  set state(AsyncValue<ServiceResult<List<Station>>> value) {
    writes.add(value);
    super.state = value;
  }
}

/// Collects everything `errorLogger.log` routes, so the test can assert
/// that the resume did not *throw and get swallowed* either. Without it
/// the guard is indistinguishable from the broad `catch` that used to
/// hide the disposed-Ref `StateError` (#4388).
class _RecordingRecorder implements TraceRecorder {
  final errors = <Object>[];

  @override
  Future<void> record(Object error, StackTrace stackTrace,
      {ServiceChainSnapshot? serviceChainState}) async {
    errors.add(error);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// #4388 — `FavoriteStations` is `@riverpod` (auto-dispose) and its
/// `loadAndRefresh` awaits a connectivity probe before it reads
/// `activeCountryProvider` and `stationServiceProvider`. Popping the
/// favorites screen during that probe used to resume into
/// `ref.read(...)` on a disposed element and throw.
///
/// The probe itself is the injection point: the mocked method channel
/// disposes the container from inside its reply, so the resume is
/// guaranteed to run against a disposed `Ref` — no timing luck.
void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  const connectivityChannel =
      MethodChannel('dev.fluttercommunity.plus/connectivity');

  late _RecordingRecorder recorder;

  setUp(() {
    recorder = _RecordingRecorder();
    errorLogger.testRecorderOverride = recorder;
  });

  tearDown(() {
    errorLogger.resetForTest();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, null);
  });

  test('disposed while probing connectivity: no throw, no state write, '
      'no station fetch', () async {
    final storage = FakeHiveStorage();
    await storage.setFavoriteIds(['de-1']);
    final service = MockStationService();
    final spy = _SpyFavoriteStations();

    final container = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(storage),
      stationServiceProvider.overrideWithValue(service),
      favoriteStationsProvider.overrideWith(() => spy),
    ]);

    // The user pops the favorites screen while the connectivity probe is
    // still in flight.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, (call) async {
      if (call.method != 'check') return null;
      container.dispose();
      return <String>['wifi'];
    });

    final pending =
        container.read(favoriteStationsProvider.notifier).loadAndRefresh();
    await expectLater(pending, completes);

    // Every write below the guard is dropped; the cached-favorites write
    // that happens BEFORE the probe is the only one allowed.
    expect(spy.writes, hasLength(lessThanOrEqualTo(1)),
        reason: 'only the pre-await cached paint may have been written');
    verifyNever(() => service.getPrices(any()));
    verifyNever(() => service.getStationDetail(any()));
    expect(recorder.errors, isEmpty,
        reason: 'the resume must RETURN, not throw a disposed-Ref '
            'StateError into the broad catch that then swallows it — that '
            'silent no-op is the #4388 failure mode, and it looks '
            'identical from the outside without this assertion');
  });

  test('a live container still refreshes — the guard is not a short-circuit',
      () async {
    final storage = FakeHiveStorage();
    await storage.setFavoriteIds(['de-1']);
    final service = MockStationService();
    when(() => service.getStationDetail(any())).thenThrow(
        StateError('no detail in this test — the call itself is the proof'));

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            connectivityChannel, (call) async => <String>['wifi']);

    final container = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(storage),
      stationServiceProvider.overrideWithValue(service),
    ]);
    addTearDown(container.dispose);

    await container.read(favoriteStationsProvider.notifier).loadAndRefresh();

    // The refresh got past the probe and reached the per-country fetch.
    verify(() => service.getStationDetail('de-1')).called(1);
    expect(container.read(favoriteStationsProvider),
        isA<AsyncValue<ServiceResult<Object?>>>());
  });
}
