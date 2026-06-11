// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_transport.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import '../../../helpers/silence_error_logger.dart';

/// Regression tests for #1932 — `TripRecording.start` must reject a
/// second start that races into the window before `state` is marked
/// active. Without the `_startInProgress` guard the second call passes
/// the `state.isActive` check and orphans a `TripRecordingController`.
void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('trip_reentry_test_');
    Hive.init(tmpDir.path);
    await Hive.openBox<String>(HiveBoxes.obd2TripHistory);
  });

  tearDown(() async {
    await Hive.box<String>(HiveBoxes.obd2TripHistory).deleteFromDisk();
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  test('a start racing into the window does not replace the controller',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final svc1 = Obd2Service(FakeObd2Transport(_elmOk()));
    final svc2 = Obd2Service(FakeObd2Transport(_elmOk()));
    await svc1.connect();
    await svc2.connect();
    final notifier = container.read(tripRecordingProvider.notifier);

    // Fire the first start without awaiting it — its controller is
    // built synchronously before the first `await`.
    final f1 = notifier.start(svc1);
    final controllerAfterFirst = notifier.debugController;
    expect(controllerAfterFirst, isNotNull);

    // The second start races into the pre-`isActive` window.
    final f2 = notifier.start(svc2);
    await Future.wait([f1, f2]);

    expect(notifier.debugController, same(controllerAfterFirst),
        reason: 'the second start must be rejected by the re-entrancy '
            'guard, not overwrite _controller with a second one');
    expect(container.read(tripRecordingProvider).phase,
        TripRecordingPhase.recording);
    await notifier.stop();
  });

  test('startTrip is rejected while a start is in progress', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final svc1 = Obd2Service(FakeObd2Transport(_elmOk()));
    final svc2 = Obd2Service(FakeObd2Transport(_elmOk()));
    await svc1.connect();
    await svc2.connect();
    final notifier = container.read(tripRecordingProvider.notifier);

    // start() sets `_startInProgress` synchronously before its first
    // await, so a startTrip() call made before awaiting it sees it.
    final startFuture = notifier.start(svc1);
    final outcome = await notifier.startTrip(service: svc2);
    expect(outcome, StartTripOutcome.alreadyActive);
    await startFuture;
    await notifier.stop();
  });

  test('the guard clears after a start completes — a later start works',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final svc1 = Obd2Service(FakeObd2Transport(_elmOk()));
    final svc2 = Obd2Service(FakeObd2Transport(_elmOk()));
    await svc1.connect();
    await svc2.connect();
    final notifier = container.read(tripRecordingProvider.notifier);

    await notifier.start(svc1);
    await notifier.stop();
    // A fresh start must not be blocked by a stuck `_startInProgress`.
    await notifier.start(svc2);
    expect(container.read(tripRecordingProvider).phase,
        TripRecordingPhase.recording);
    await notifier.stop();
  });
}

Map<String, String> _elmOk() => const {
      'ATZ': 'ELM327 v1.5>',
      'ATE0': 'OK>',
      'ATL0': 'OK>',
      'ATH0': 'OK>',
      'ATSP0': 'OK>',
      '01A6': '41 A6 00 01 6A 2C>',
    };
