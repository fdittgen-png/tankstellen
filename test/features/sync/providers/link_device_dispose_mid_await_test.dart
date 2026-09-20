// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/sync/supabase_client.dart';
import 'package:tankstellen/core/sync/tanksync_session_gate.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/sync/providers/link_device_provider.dart';

import '../../../core/sync/support/fake_tanksync_backend.dart';
import '../../../fakes/fake_hive_storage.dart';
import '../../../helpers/silence_error_logger.dart';

class _SpyLinkDeviceController extends LinkDeviceController {
  final writes = <LinkDeviceState>[];

  @override
  set state(LinkDeviceState value) {
    writes.add(value);
    super.state = value;
  }
}

/// Collects what `errorLogger.log` routes. `linkDevice`'s outer `catch`
/// logs before it decides anything, so a disposed-Ref failure that the
/// catch swallows still shows up here — which is what makes "the guard
/// returned" distinguishable from "the guard was missing and the error
/// was eaten" (#4388).
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

/// #4388 — `LinkDeviceController` is `@riverpod` (auto-dispose) and its
/// `linkDevice` merges four datasets, each step reaching back through
/// `ref`. Dismissing the link sheet while the first Supabase round-trip
/// is in flight used to resume into `ref.read(favoritesProvider)` on a
/// disposed element. Several of those reads sit inside broad `catch`
/// blocks, so the failure was a silent dropped import rather than a
/// visible crash — hence the recorder assertion below.
void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  const host = 'a-project.supabase.co';
  late FakeTankSyncBackend backend;
  late _RecordingRecorder recorder;

  setUp(() async {
    recorder = _RecordingRecorder();
    errorLogger.testRecorderOverride = recorder;
    backend = FakeTankSyncBackend();
    TankSyncClient.debugSdk = backend;
    await TankSyncClient.init(url: 'https://$host', anonKey: 'anon-key');
  });

  tearDown(() {
    TankSyncClient.resetForTest();
    TankSyncSessionGate.instance.resetForTest();
    errorLogger.resetForTest();
  });

  test('disposed while the first Supabase fetch is in flight: no throw, '
      'no state write, nothing swallowed', () async {
    backend.project(host).rows('favorites').add({
      'user_id': 'other-device-0001',
      'station_id': 'de-42',
    });

    final spy = _SpyLinkDeviceController();
    final container = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(FakeHiveStorage()),
      linkDeviceControllerProvider.overrideWith(() => spy),
    ]);

    final parked = Completer<void>();
    backend.hang = parked;

    final pending = container
        .read(linkDeviceControllerProvider.notifier)
        .linkDevice('other-device-0001');
    await Future<void>.delayed(Duration.zero);

    final writesBeforeDispose = spy.writes.length;
    expect(writesBeforeDispose, greaterThan(0),
        reason: 'the isLinking write happens before the first await');
    expect(backend.requests, isNotEmpty,
        reason: 'the run must actually be parked on a Supabase request, '
            'otherwise this test never reaches the guarded resume');

    // The user dismisses the link sheet while the fetch is parked.
    container.dispose();
    parked.complete();

    await expectLater(pending, completes);
    expect(spy.writes, hasLength(writesBeforeDispose),
        reason: 'no outcome may be written into a disposed notifier');
    expect(recorder.errors, isEmpty,
        reason: 'the resume must RETURN — a disposed-Ref failure eaten by '
            'linkDevice\'s broad catch is the silent variant of #4388');
    expect(backend.project(host).writes, isEmpty,
        reason: 'the merge must stop at the guard, so nothing is pushed '
            'back to the account either');
  });

  test('a live container still completes the link — the guard is not a '
      'short-circuit', () async {
    final container = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(FakeHiveStorage()),
    ]);
    addTearDown(container.dispose);

    await container
        .read(linkDeviceControllerProvider.notifier)
        .linkDevice('other-device-0002');

    expect(container.read(linkDeviceControllerProvider).outcome,
        LinkDeviceOutcome.linked);
  });
}
