// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4378 — a trip whose history write failed is kept under its OWN id, so
/// the next recording (which overwrites the single active-trip WAL row)
/// cannot be the end of it: the next launch retries the kept trip, and both
/// drives end up in history exactly once.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/active_trip_repository.dart';
import 'package:tankstellen/features/trips/data/pending_trip_saves.dart';
import 'package:tankstellen/features/trips/data/trip_history_repository.dart';
import 'package:tankstellen/features/trips/domain/trip_recorder.dart';
import 'package:tankstellen/features/trips/providers/trip_recording_provider.dart';

import '../../../helpers/silence_error_logger.dart';
import '../support/recording_disk_image.dart';
import '../support/recording_session_driver.dart';

/// A history repository whose FIRST save fails the way a full disk does —
/// logged and swallowed inside the repository — and whose later saves land.
class _FailsFirstSaveRepository extends TripHistoryRepository {
  _FailsFirstSaveRepository({required super.box});

  bool _failed = false;

  @override
  Future<bool> save(TripHistoryEntry entry) async {
    if (_failed) return super.save(entry);
    _failed = true;
    return false;
  }
}

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

  test('a failed save survives the NEXT recording: the relaunch retries it '
      'and both trips are in history exactly once', () async {
    final repo = _FailsFirstSaveRepository(box: disk.historyBox);
    final container = ProviderContainer(overrides: [
      ...driver.overrides,
      tripHistoryRepositoryProvider.overrideWithValue(repo),
    ]);
    final notifier = container.read(tripRecordingProvider.notifier);

    // Trip 1 — its history write fails; the screen resets after every stop.
    final first = await RecordingSessionDriver.startObd2(container);
    RecordingSessionDriver.captureObd2Samples(first, 10);
    await notifier.stop();
    notifier.reset();
    await RecordingDisk.settle();
    expect(disk.historyRepo.loadAll(), isEmpty);
    expect(PendingTripSaves.resolve()!.loadAll(), hasLength(1),
        reason: 'the unsaved trip is kept under its own id');

    // Trip 2 — the same process, so its WAL seed overwrites the single
    // active-trip row. Its own save lands.
    final second = await RecordingSessionDriver.startObd2(container);
    RecordingSessionDriver.captureObd2Samples(second, 7);
    await notifier.stop();
    notifier.reset();
    await RecordingDisk.settle();
    expect(disk.historyRepo.loadAll(), hasLength(1),
        reason: 'only the second trip has been written so far');

    final image = await disk.capture();
    container.dispose();

    final next = await disk.relaunch(image, overrides: driver.overrides);
    addTearDown(next.dispose);

    final saved = disk.historyRepo.loadAll();
    expect(saved, hasLength(2), reason: 'the launch retry saved the kept trip');
    expect(saved.map((e) => e.samples.length).toList()..sort(), [7, 10]);
    expect(PendingTripSaves.resolve()!.loadAll(), isEmpty,
        reason: 'a trip that landed is no longer pending');
    expect(next.read(tripRecordingProvider).phase, TripRecordingPhase.idle,
        reason: 'nothing is handed back: both trips are in history');
  });

  test('retryPendingTripSaves retires the WAL row of the trip it saves, and '
      'leaves a different trip alone', () async {
    final pending = PendingTripSaves.resolve()!;
    await pending.keep(const TripHistoryEntry(
      id: 'trip-kept',
      vehicleId: 'veh-1',
      summary: _summary,
    ));
    await disk.activeRepo.saveSnapshot(_walRowFor('another-trip'));

    expect(await retryPendingTripSaves(), 1);
    expect(disk.historyRepo.loadAll().single.id, 'trip-kept');
    expect(pending.loadAll(), isEmpty);
    expect(disk.activeRepo.loadSnapshot()?.id, 'another-trip',
        reason: "another trip's recovery row is not this trip's to retire");

    await pending.keep(const TripHistoryEntry(
      id: 'trip-kept-2',
      vehicleId: 'veh-1',
      summary: _summary,
    ));
    await disk.activeRepo.saveSnapshot(_walRowFor('trip-kept-2'));
    expect(await retryPendingTripSaves(), 1);
    expect(disk.activeRepo.loadSnapshot(), isNull,
        reason: 'the saved trip no longer needs its WAL row (#4328)');
  });
}

final DateTime _start = RecordingSessionDriver.tripStart;

const TripSummary _summary = TripSummary(
  distanceKm: 4.2,
  maxRpm: 2600,
  highRpmSeconds: 0,
  idleSeconds: 3,
  harshBrakes: 0,
  harshAccelerations: 0,
);

ActiveTripSnapshot _walRowFor(String id) => ActiveTripSnapshot(
      id: id,
      vehicleId: 'veh-1',
      vin: null,
      automatic: false,
      phase: 'recording',
      summary: _summary,
      samples: const [],
      odometerStartKm: null,
      odometerLatestKm: null,
      startedAt: _start,
      lastFlushedAt: _start,
    );
