// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4162 — SUSPEND: the app is backgrounded, and may never come back.
///
/// Backgrounding is the last moment the app is guaranteed to run before
/// the OS may kill it, so whatever the disk says at that moment is what a
/// relaunch will believe. Each test backgrounds the recording in one phase
/// and reads the disk: the phase on disk must be the phase on the wire,
/// and every captured sample must already be there.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/trips/domain/recording_phase_codec.dart';
import 'package:tankstellen/features/trips/providers/trip_recording_provider.dart';

import '../../../helpers/silence_error_logger.dart';
import '../support/gated_trip_history_repository.dart';
import '../support/phase_trace.dart';
import '../support/recording_disk_image.dart';
import '../support/recording_session_driver.dart';

void main() {
  silenceErrorLoggerSpool();

  late RecordingDisk disk;
  late RecordingSessionDriver driver;

  setUp(() async {
    disk = await RecordingDisk.open();
    driver = RecordingSessionDriver();
  });

  tearDown(() async {
    await driver.dispose();
    await disk.close();
  });

  Future<void> background(TripRecording notifier) async {
    notifier.onAppLifecycleStateChanged(AppLifecycleState.paused);
    await notifier.onAppBackgrounded();
    await RecordingDisk.settle();
  }

  group('backgrounding an OBD2 trip leaves the disk telling the truth', () {
    Future<void> suspendIn(
      Future<void> Function(TripRecording notifier) enterPhase,
      TripRecordingPhase expected,
    ) async {
      final container = driver.container();
      addTearDown(container.dispose);
      final trace = PhaseTrace(container);
      addTearDown(trace.close);
      final notifier = await RecordingSessionDriver.startObd2(container);
      addTearDown(notifier.stop);
      RecordingSessionDriver.captureObd2Samples(notifier, 9);
      await enterPhase(notifier);
      expect(container.read(tripRecordingProvider).phase, expected);

      await background(notifier);

      final row = await disk.activeRepo.loadSnapshotWithSamples();
      expect(row, isNotNull);
      expect(row!.phase,
          recordingPhaseToWire(notifier.debugController!.currentState),
          reason: 'the phase on disk is the phase a relaunch will believe');
      expect(row.samples, hasLength(9),
          reason: 'backgrounding flushes every captured sample');
      trace.expectLawful();
    }

    test('recording', () async {
      await suspendIn((_) async {}, TripRecordingPhase.recording);
    });

    test('paused', () async {
      await suspendIn((n) async {
        n.pause();
        await RecordingDisk.settle();
      }, TripRecordingPhase.paused);
    });

    test('paused by a drop', () async {
      await suspendIn((n) async {
        n.debugController!
            .debugTriggerDrop(reason: TripDropReason.silentFailure);
        await RecordingDisk.settle();
      }, TripRecordingPhase.pausedDueToDrop);
    });

    test('degraded onto GPS — persisted as recording (#2565)', () async {
      await suspendIn((n) async {
        n.debugController!
          ..updateGpsFix(latitude: 48, longitude: 7, speedKmh: 50)
          ..debugTriggerDrop(reason: TripDropReason.silentFailure);
        await RecordingDisk.settle();
      }, TripRecordingPhase.degradedGpsOnly);
    });
  });

  test('backgrounding a GPS-only trip flushes its fixes', () async {
    final container = driver.container();
    addTearDown(container.dispose);
    final notifier = await RecordingSessionDriver.startGpsOnly(container);
    addTearDown(notifier.stop);
    for (var i = 0; i < 3; i++) {
      driver.emitFix(index: i);
    }
    await RecordingDisk.settle();

    await background(notifier);

    final row = await disk.activeRepo.loadSnapshotWithSamples();
    expect(row?.phase, 'recording');
    expect(row?.samples, hasLength(3));
  });

  test('backgrounding while connecting writes nothing', () async {
    final container = driver.container();
    addTearDown(container.dispose);
    final notifier = container.read(tripRecordingProvider.notifier)
      ..enterConnecting();

    await background(notifier);

    expect(disk.activeBox.isEmpty, isTrue,
        reason: 'no trip exists yet — a row would be a phantom');
  });

  test('backgrounding while saving writes nothing', () async {
    final gated = GatedTripHistoryRepository(box: disk.historyBox);
    final container = ProviderContainer(overrides: [
      ...driver.overrides,
      tripHistoryRepositoryProvider.overrideWithValue(gated),
    ]);
    addTearDown(container.dispose);
    final notifier = await RecordingSessionDriver.startObd2(container);
    RecordingSessionDriver.captureObd2Samples(notifier, 6);
    final stopping = notifier.stop();
    await gated.reached;
    await RecordingDisk.settle();
    expect(container.read(tripRecordingProvider).phase,
        TripRecordingPhase.saving);
    final before = Map.of(disk.activeBox.toMap());

    await background(notifier);

    expect(disk.activeBox.toMap(), before,
        reason: 'the trip has left the live loop — saving is not a phase '
            'that writes the WAL');
    gated.release();
    await stopping;
  });
}
