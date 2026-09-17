// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4162 — KILL: the OS ends the process mid-recording.
///
/// A kill runs no teardown, so each test captures the disk at the instant
/// the kill lands, winds the old process down, and relaunches from the
/// captured image through the production launch recovery passes. The
/// assertion is always about what the relaunched app hands the user.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/obd2/data/active_trip_repository.dart';
import 'package:tankstellen/features/trips/domain/entities/trip_termination.dart';
import 'package:tankstellen/features/trips/domain/trip_recorder.dart';
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

  /// Wind the killed process down so none of its later writes reach the
  /// disk the relaunch restores.
  Future<void> windDown(ProviderContainer old) async {
    final notifier = old.read(tripRecordingProvider.notifier);
    await notifier.stop();
    await RecordingDisk.settle();
    old.dispose();
  }

  /// Relaunch on [image] and End the recovered trip the way the pause
  /// banner does, returning the relaunched container.
  Future<ProviderContainer> relaunchAndEnd(
    RecordingDiskImage image, {
    required int expectedSamples,
  }) async {
    final next = await disk.relaunch(image, overrides: driver.overrides);
    addTearDown(next.dispose);
    final trace = PhaseTrace(next);
    addTearDown(trace.close);
    expect(next.read(tripRecordingProvider).phase,
        TripRecordingPhase.pausedDueToDrop,
        reason: 'a trip whose process died comes back as a pause to end');
    await next.read(tripRecordingProvider.notifier).stop();
    final saved = disk.historyRepo.loadAll();
    expect(saved, hasLength(1));
    expect(saved.single.samples, hasLength(expectedSamples),
        reason: 'every sample the dead process captured reaches history');
    expect(saved.single.termination?.reason,
        TripTerminationReason.recoveredAfterProcessDeath);
    expect(disk.activeRepo.loadSnapshot(), isNull,
        reason: 'the finalised trip must not be recovered a second time');
    trace.expectLawful();
    return next;
  }

  group('an OBD2 trip killed mid-recording is recovered whole', () {
    Future<void> killIn(
      Future<void> Function(TripRecording notifier) enterPhase,
      TripRecordingPhase expected,
    ) async {
      final old = driver.container();
      final trace = PhaseTrace(old);
      final notifier = await RecordingSessionDriver.startObd2(old);
      RecordingSessionDriver.captureObd2Samples(notifier, 12);
      await enterPhase(notifier);
      await notifier.onAppBackgrounded();
      expect(old.read(tripRecordingProvider).phase, expected);
      trace
        ..expectLawful()
        ..close();

      final image = await disk.capture();
      expect(image.active, isNotEmpty, reason: 'the WAL row is on disk');
      expect(image.walBytes, isNotNull,
          reason: 'the samples live in the append-only WAL, not the row');
      await windDown(old);

      await relaunchAndEnd(image, expectedSamples: 12);
    }

    test('while recording', () async {
      await killIn((_) async {}, TripRecordingPhase.recording);
    });

    test('while paused by the user', () async {
      await killIn((n) async {
        n.pause();
        await RecordingDisk.settle();
      }, TripRecordingPhase.paused);
    });

    test('while paused by a link drop (GPS gone too)', () async {
      await killIn((n) async {
        n.debugController!
            .debugTriggerDrop(reason: TripDropReason.silentFailure);
        await RecordingDisk.settle();
      }, TripRecordingPhase.pausedDueToDrop);
    });

    test('while degraded onto GPS (#2565)', () async {
      await killIn((n) async {
        n.debugController!
          ..updateGpsFix(latitude: 48, longitude: 7, speedKmh: 50)
          ..debugTriggerDrop(reason: TripDropReason.silentFailure);
        await RecordingDisk.settle();
      }, TripRecordingPhase.degradedGpsOnly);
    });

    test('while paused by the user AND degraded (reachable: 10101)',
        () async {
      await killIn((n) async {
        n.debugController!
          ..updateGpsFix(latitude: 48, longitude: 7, speedKmh: 50)
          ..debugTriggerDrop(reason: TripDropReason.silentFailure);
        await RecordingDisk.settle();
        n.pause();
        await RecordingDisk.settle();
      }, TripRecordingPhase.paused);
    });
  });

  group('#4314 — a trip killed while degraded has a paused row AND a WAL '
      'row under one id, and is still recovered exactly once', () {
    /// Kill an OBD2 trip degraded onto GPS: the drop wrote a paused-trip
    /// row next to the WAL row.
    Future<RecordingDiskImage> killWhileDegraded() async {
      final old = driver.container();
      final notifier = await RecordingSessionDriver.startObd2(old);
      RecordingSessionDriver.captureObd2Samples(notifier, 12);
      notifier.debugController!
        ..updateGpsFix(latitude: 48, longitude: 7, speedKmh: 50)
        ..debugTriggerDrop(reason: TripDropReason.silentFailure);
      await RecordingDisk.settle();
      await notifier.onAppBackgrounded();
      final image = await disk.capture();
      expect(image.paused, hasLength(1));
      expect(image.active, hasLength(1));
      final activeId =
          ActiveTripSnapshot.fromJson(jsonDecode(image.active.values.single)
                  as Map<String, dynamic>)
              .id;
      expect(image.paused.keys.single, activeId,
          reason: 'the precondition: two rows, one trip');
      await windDown(old);
      return image;
    }

    DateTime Function() minutesLater(int m) =>
        () => const SystemClock().now().add(Duration(minutes: m));

    void expectOneCompleteTrip() {
      final saved = disk.historyRepo.loadAll();
      expect(saved, hasLength(1));
      expect(saved.single.samples, hasLength(12),
          reason: 'the sample-less paused copy must never win');
      expect(saved.single.termination?.reason,
          TripTerminationReason.recoveredAfterProcessDeath);
    }

    test('relaunched after the sweep threshold: the sweep leaves the '
        'recoverable trip alone', () async {
      final image = await killWhileDegraded();

      final next = await disk.relaunch(image,
          overrides: driver.overrides, now: minutesLater(10));
      addTearDown(next.dispose);
      expect(disk.historyRepo.loadAll(), isEmpty,
          reason: 'the active row is still recoverable — the paused sweep '
              'must not save a sample-less copy of it');
      expect(next.read(tripRecordingProvider).phase,
          TripRecordingPhase.pausedDueToDrop);

      await next.read(tripRecordingProvider.notifier).stop();
      expectOneCompleteTrip();
      expect(disk.pausedBox.isEmpty, isTrue);
    });

    test('ended at once, then a later launch sweeps: the good row survives',
        () async {
      final image = await killWhileDegraded();
      final first = await disk.relaunch(image, overrides: driver.overrides);
      await first.read(tripRecordingProvider.notifier).stop();
      expectOneCompleteTrip();
      expect(disk.pausedBox.isEmpty, isTrue,
          reason: 'finalising the recovered trip deletes its paused row');
      final afterEnd = await disk.capture();
      first.dispose();

      final later = await disk.relaunch(afterEnd,
          overrides: driver.overrides, now: minutesLater(30));
      addTearDown(later.dispose);
      expectOneCompleteTrip();
    });

    test('discarding the recovered trip (reset) deletes its paused row too',
        () async {
      final image = await killWhileDegraded();
      final next = await disk.relaunch(image, overrides: driver.overrides);
      addTearDown(next.dispose);

      next.read(tripRecordingProvider.notifier).reset();
      await RecordingDisk.settle();

      expect(disk.activeBox.isEmpty, isTrue);
      expect(disk.pausedBox.isEmpty, isTrue,
          reason: 'a discarded trip must not come back as a sweep row');
    });
  });

  test('a GPS-only trip killed mid-recording is recovered whole', () async {
    final old = driver.container();
    final notifier = await RecordingSessionDriver.startGpsOnly(old);
    for (var i = 0; i < 5; i++) {
      driver.emitFix(index: i);
    }
    await RecordingDisk.settle();
    await notifier.onAppBackgrounded();

    final image = await disk.capture();
    await windDown(old);

    await relaunchAndEnd(image, expectedSamples: 5);
  });

  test('#4313 — a GPS-only trip killed while its stop waits on the history '
      'write is recovered, and ends as a GPS-only trip', () async {
    final gated = GatedTripHistoryRepository(box: disk.historyBox);
    final old = ProviderContainer(overrides: [
      ...driver.overrides,
      tripHistoryRepositoryProvider.overrideWithValue(gated),
    ]);
    final notifier = await RecordingSessionDriver.startGpsOnly(old);
    for (var i = 0; i < 5; i++) {
      driver.emitFix(index: i);
    }
    await RecordingDisk.settle();
    final stopping = notifier.stop();
    await gated.reached;

    final image = await disk.capture();
    expect(image.active, isNotEmpty,
        reason: 'the trip is not in history yet, so its WAL row must be');
    gated.release();
    await stopping;
    await RecordingDisk.settle();
    old.dispose();

    final next = await relaunchAndEnd(image, expectedSamples: 5);
    expect(disk.historyRepo.loadAll().single.summary.kind, TripKind.gpsOnly,
        reason: 'a dongle-less trip stays dongle-less through a recovery');
    expect(next.read(tripRecordingProvider).phase,
        TripRecordingPhase.finished);
  });

  test('a kill while still connecting leaves nothing to recover', () async {
    final old = driver.container();
    old.read(tripRecordingProvider.notifier).enterConnecting();

    final image = await disk.capture();
    old.dispose();

    final next = await disk.relaunch(image, overrides: driver.overrides);
    addTearDown(next.dispose);
    expect(next.read(tripRecordingProvider).phase, TripRecordingPhase.idle,
        reason: 'no trip existed yet, so there is nothing to hand back');
    expect(disk.activeRepo.loadSnapshot(), isNull);
    expect(disk.historyRepo.loadAll(), isEmpty);
  });
}
