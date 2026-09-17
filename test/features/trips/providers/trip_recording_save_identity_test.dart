// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4328 — a trip's history write is the only thing that may retire its
/// recovery rows, and the trip keeps ONE identity from start to history.
///
/// Two defects on the stop path, each walked through a real notifier on a
/// real disk: a failed history write deleted the WAL row anyway (the only
/// remaining copy of the drive), and the stop saved under a different id
/// than the WAL row it cleared — so a kill between the save and the clear
/// relaunched onto a trip that was already in history and saved it again.
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/trips/data/trip_history_repository.dart';
import 'package:tankstellen/features/trips/domain/entities/trip_termination.dart';
import 'package:tankstellen/features/trips/providers/trip_recording_provider.dart';

import '../../../helpers/silence_error_logger.dart';
import '../support/gated_trip_history_repository.dart';
import '../support/recording_disk_image.dart';
import '../support/recording_session_driver.dart';

/// One way of recording a trip: how to start it and feed it, and how many
/// samples the finished trip must carry.
typedef _Recording = ({
  String name,
  Future<TripRecording> Function(ProviderContainer, RecordingSessionDriver)
      record,
  int samples,
});

final List<_Recording> _recordings = [
  (
    name: 'an OBD2 trip',
    record: (container, _) async {
      final notifier = await RecordingSessionDriver.startObd2(container);
      RecordingSessionDriver.captureObd2Samples(notifier, 10);
      return notifier;
    },
    samples: 10,
  ),
  (
    name: 'a GPS-only trip',
    record: (container, driver) async {
      final notifier = await RecordingSessionDriver.startGpsOnly(container);
      for (var i = 0; i < 5; i++) {
        driver.emitFix(index: i);
      }
      await RecordingDisk.settle();
      return notifier;
    },
    samples: 5,
  ),
];

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

  ProviderContainer processWith(TripHistoryRepository repo) =>
      ProviderContainer(overrides: [
        ...driver.overrides,
        tripHistoryRepositoryProvider.overrideWithValue(repo),
      ]);

  /// Two shapes a failed history write takes: the repository throws, or
  /// it logs and swallows a Hive write on a closed box.
  final failures = <String, Future<TripHistoryRepository> Function()>{
    'the repository throws': () async => GatedTripHistoryRepository(
          box: disk.historyBox,
          fault: const FileSystemException('No space left on device'),
        )..release(),
    'the Hive write fails inside the repository': () async {
      final closed = await Hive.openBox<String>('history_that_closed');
      await closed.close();
      return TripHistoryRepository(box: closed);
    },
  };

  for (final recording in _recordings) {
    group('${recording.name} (#4328)', () {
      for (final failure in failures.entries) {
        test('a failed history write keeps the WAL row — ${failure.key}; '
            'the relaunch recovers the trip and End saves it once', () async {
          final old = processWith(await failure.value());
          final notifier = await recording.record(old, driver);
          await notifier.stop();
          // The recording screen resets the provider after every stop.
          notifier.reset();
          await RecordingDisk.settle();

          expect(disk.historyRepo.loadAll(), isEmpty);
          expect(disk.activeRepo.loadSnapshot(), isNotNull,
              reason: 'the trip never reached history, so its WAL row is '
                  'the only copy of the drive');
          final image = await disk.capture();
          old.dispose();

          final next = await disk.relaunch(image, overrides: driver.overrides);
          addTearDown(next.dispose);
          expect(next.read(tripRecordingProvider).phase,
              TripRecordingPhase.pausedDueToDrop);
          await next.read(tripRecordingProvider.notifier).stop();

          final saved = disk.historyRepo.loadAll();
          expect(saved, hasLength(1));
          expect(saved.single.samples, hasLength(recording.samples));
          expect(disk.activeRepo.loadSnapshot(), isNull,
              reason: 'saved once: nothing is left to recover again');
        });
      }

      test('a kill after the history write but before the WAL clear leaves '
          'exactly one history row', () async {
        final gated =
            GatedTripHistoryRepository(box: disk.historyBox, afterWrite: true);
        final old = processWith(gated);
        final notifier = await recording.record(old, driver);
        final stopping = notifier.stop();
        await gated.reached;

        final image = await disk.capture();
        expect(image.history, isNotEmpty, reason: 'the row is written');
        expect(image.active, isNotEmpty, reason: 'the WAL is not cleared yet');
        gated.release();
        await stopping;
        await RecordingDisk.settle();
        old.dispose();

        final next = await disk.relaunch(image, overrides: driver.overrides);
        addTearDown(next.dispose);
        expect(next.read(tripRecordingProvider).phase, TripRecordingPhase.idle,
            reason: 'the trip is already in history: nothing to hand back');
        expect(disk.activeRepo.loadSnapshot(), isNull,
            reason: 'the recovery retires the WAL row of a saved trip');
        // The pause banner's End, had the trip been handed back.
        await next.read(tripRecordingProvider.notifier).stop();

        final saved = disk.historyRepo.loadAll();
        expect(saved, hasLength(1), reason: 'one drive, one history row');
        expect(saved.single.samples, hasLength(recording.samples));
        expect(saved.single.termination?.reason,
            isNot(TripTerminationReason.recoveredAfterProcessDeath),
            reason: 'the row the stop wrote is the one that stays');
      });
    });
  }
}
