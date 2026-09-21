// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4162 — THROTTLE: the OS starves a source the recording depends on.
///
/// Location updates get batched, errored or stopped outright; the OBD2
/// link goes silent. None of that is a crash, and none of it may lose the
/// trip: the recording either keeps going on what it still has, or pauses
/// with its data on disk.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_service.dart';
import 'package:tankstellen/features/trips/providers/trip_recording_provider.dart';

import '../../../helpers/silence_error_logger.dart';
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

  group('GPS-only', () {
    test('a location stream error keeps the trip recording, WAL on disk',
        () async {
      final container = driver.container();
      addTearDown(container.dispose);
      final notifier = await RecordingSessionDriver.startGpsOnly(container);
      addTearDown(notifier.stop);
      driver.emitFix();
      await RecordingDisk.settle();

      driver.geo.emitError(StateError('location updates throttled'));
      await RecordingDisk.settle();

      expect(container.read(tripRecordingProvider).phase,
          TripRecordingPhase.recording);
      expect(disk.activeRepo.loadSnapshot(), isNotNull,
          reason: 'the seeded WAL row survives the stream error');
    });

    test('no fixes at all: the trip stays recording (no stall phase exists)',
        () async {
      // Pins today's behaviour: a GPS-only trip starved of fixes has no
      // state of its own — it reads `recording` with a seeded, empty WAL.
      final container = driver.container();
      addTearDown(container.dispose);
      final notifier = await RecordingSessionDriver.startGpsOnly(container);
      addTearDown(notifier.stop);
      await RecordingDisk.settle();
      await notifier.onAppBackgrounded();

      expect(container.read(tripRecordingProvider).phase,
          TripRecordingPhase.recording);
      final row = await disk.activeRepo.loadSnapshotWithSamples();
      expect(row?.phase, 'recording');
      expect(row?.samples, isEmpty);
    });
  });

  group('OBD2', () {
    test('#4312 — the controller says whether its pause happened', () async {
      final container = driver.container();
      addTearDown(container.dispose);
      final notifier = await RecordingSessionDriver.startObd2(container);
      addTearDown(notifier.stop);
      final ctl = notifier.debugController!;

      expect(ctl.pause(), isTrue, reason: 'running → paused');
      expect(ctl.pause(), isFalse, reason: 'already paused');
      ctl.resume();
      ctl.debugTriggerDrop(reason: TripDropReason.silentFailure);
      expect(ctl.pause(), isFalse, reason: 'a drop pause is not the user\'s');
    });

    test('C1 — a hands-free start does not take over a manual start that is '
        'still connecting', () async {
      final container = driver.container();
      addTearDown(container.dispose);
      final notifier = container.read(tripRecordingProvider.notifier)
        ..enterConnecting();
      final auto = Obd2Service(SlowOdometerTransport());
      await auto.connect();

      final outcome =
          await notifier.startTrip(service: auto, automatic: true);
      addTearDown(notifier.stop);

      expect(outcome, StartTripOutcome.alreadyActive,
          reason: 'the user already asked for this recording');
      expect(container.read(tripRecordingProvider).phase,
          TripRecordingPhase.connecting);
    });

    test('a silent link degrades onto GPS while GPS lives, pauses when not',
        () async {
      for (final gpsAlive in [true, false]) {
        final container = driver.container();
        final trace = PhaseTrace(container);
        final notifier = await RecordingSessionDriver.startObd2(container);
        final ctl = notifier.debugController!;
        if (gpsAlive) {
          ctl.updateGpsFix(latitude: 48, longitude: 7, speedKmh: 60);
        }
        ctl.debugTriggerDrop(reason: TripDropReason.silentFailure);
        await RecordingDisk.settle();

        expect(
          container.read(tripRecordingProvider).phase,
          gpsAlive
              ? TripRecordingPhase.degradedGpsOnly
              : TripRecordingPhase.pausedDueToDrop,
          reason: 'gpsAlive=$gpsAlive',
        );
        expect(disk.pausedRepo.loadAll(), hasLength(1),
            reason: 'either way the partial trip is parked on disk');
        trace.expectLawful();
        trace.close();
        await notifier.stop();
        container.dispose();
        await disk.pausedBox.clear();
        await disk.historyBox.clear();
      }
    });

    test('#4312 — pausing during a drop pause changes nothing: the banner '
        'stays and the grace window keeps running', () async {
      final container = driver.container();
      addTearDown(container.dispose);
      final trace = PhaseTrace(container);
      addTearDown(trace.close);
      final notifier = await RecordingSessionDriver.startObd2(container);
      addTearDown(notifier.stop);
      notifier.debugController!
          .debugTriggerDrop(reason: TripDropReason.silentFailure);
      await RecordingDisk.settle();

      // The recording screen's toggle and the tile both read "not paused"
      // off a drop pause and call pause().
      notifier.pause();
      await RecordingDisk.settle();

      final ctl = notifier.debugController!;
      expect(ctl.isPausedDueToDrop, isTrue);
      expect(container.read(tripRecordingProvider).phase,
          TripRecordingPhase.pausedDueToDrop,
          reason: 'a refused pause must not publish paused — that hides the '
              'drop banner while the grace timer runs on');
      expect(trace.saw(TripRecordingPhase.pausedDueToDrop,
          TripRecordingPhase.paused), isFalse);
      // The grace window is still armed: expiring it finalises the trip.
      await ctl.debugExpireGraceWindow();
      await RecordingDisk.settle();
      expect(container.read(tripRecordingProvider).phase,
          TripRecordingPhase.finished);
      expect(disk.historyRepo.loadAll(), hasLength(1));
      trace.expectLawful();
    });

    test('degraded, then GPS stalls past its window: the trip pauses and '
        'the WAL says so', () async {
      final container = driver.container();
      addTearDown(container.dispose);
      final trace = PhaseTrace(container);
      addTearDown(trace.close);
      final notifier = await RecordingSessionDriver.startObd2(container);
      addTearDown(notifier.stop);
      final ctl = notifier.debugController!
        ..updateGpsFix(latitude: 48, longitude: 7, speedKmh: 60)
        ..debugTriggerDrop(reason: TripDropReason.silentFailure);
      await RecordingDisk.settle();
      expect(container.read(tripRecordingProvider).phase,
          TripRecordingPhase.degradedGpsOnly);

      // The last fix the OS delivered is now older than the 15 s window.
      ctl
        ..updateGpsFix(
          latitude: 48,
          longitude: 7,
          speedKmh: 60,
          fixAt: const SystemClock().now().subtract(const Duration(seconds: 20)),
        )
        ..debugEmitNow();
      await RecordingDisk.settle();

      expect(container.read(tripRecordingProvider).phase,
          TripRecordingPhase.pausedDueToDrop);
      expect(ctl.isPausedDueToDrop, isTrue,
          reason: 'the grace window now runs on the controller');
      expect(disk.activeRepo.loadSnapshot()?.phase, 'pausedDueToDrop',
          reason: 'the escalation forces a flush');
      trace.expectLawful();
    });
  });
}
