// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4162 — PARTIAL RESTORE: the disk a relaunch finds is not the disk a
/// clean shutdown would have left.
///
/// A kill lands between two writes, so the WAL row and the sample file
/// can disagree: a row whose samples never reached the file, a file whose
/// row was never written, a final line torn in half. Each image here is
/// built by hand in exactly one of those shapes and relaunched through the
/// production recovery passes. The already-covered shapes — an unknown
/// phase (#4243), a snapshot older than 24 h, a restore while a trip runs
/// — live in their own suites.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/telemetry/process_death_context.dart';
import 'package:tankstellen/features/obd2/data/active_trip_repository.dart';
import 'package:tankstellen/features/trips/data/trip_sample_codec.dart';
import 'package:tankstellen/features/trips/domain/entities/trip_termination.dart';
import 'package:tankstellen/features/trips/domain/trip_recorder.dart';
import 'package:tankstellen/features/trips/providers/trip_recording_provider.dart';

import '../../../helpers/silence_error_logger.dart';
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

  final start = RecordingSessionDriver.tripStart;

  List<TripSample> samples(int n, {bool engine = true}) => [
        for (var i = 0; i < n; i++)
          TripSample(
            timestamp: start.add(Duration(seconds: i)),
            speedKmh: 50,
            rpm: engine ? 2000 : null,
            fuelRateLPerHour: engine ? 5.0 : null,
            latitude: 43.4 + i * 0.0002,
            longitude: 3.5,
          ),
      ];

  /// A WAL row as the writer leaves it: meta only (samples in the file),
  /// flushed by a process that is not this one — unless [pid] says so.
  Map<dynamic, String> row({
    List<TripSample> inRow = const [],
    String pid = 'p-a-process-that-died',
    String distanceSource = 'real',
  }) =>
      {
        'active': jsonEncode(ActiveTripSnapshot(
          id: start.toIso8601String(),
          vehicleId: null,
          vin: null,
          automatic: false,
          phase: 'recording',
          summary: TripSummary(
            distanceKm: 1.2,
            maxRpm: 2000,
            highRpmSeconds: 0,
            idleSeconds: 0,
            harshBrakes: 0,
            harshAccelerations: 0,
            startedAt: start,
            distanceSource: distanceSource,
          ),
          samples: inRow,
          odometerStartKm: null,
          odometerLatestKm: null,
          startedAt: start,
          // Recent enough for recovery: a relaunch minutes after the kill.
          lastFlushedAt: start,
          processInstanceId: pid,
        ).toJson()),
      };

  List<int> ndjson(List<TripSample> s, {String tail = ''}) => utf8.encode(
      '${s.map((x) => jsonEncode(sampleToJson(x))).join('\n')}\n$tail');

  RecordingDiskImage image({
    Map<dynamic, String> active = const {},
    List<int>? walBytes,
  }) =>
      RecordingDiskImage(
        active: active,
        paused: const {},
        history: const {},
        walBytes: walBytes,
      );

  DateTime minutesAfterStart() => start.add(const Duration(minutes: 3));

  Future<TripHistoryEntryView> relaunchAndEnd(
    RecordingDiskImage img, {
    bool sameProcess = false,
  }) async {
    final next = await disk.relaunch(img,
        overrides: driver.overrides,
        now: minutesAfterStart,
        sameProcess: sameProcess);
    addTearDown(next.dispose);
    expect(next.read(tripRecordingProvider).phase,
        TripRecordingPhase.pausedDueToDrop);
    await next.read(tripRecordingProvider.notifier).stop();
    final saved = disk.historyRepo.loadAll();
    expect(saved, hasLength(1));
    expect(disk.activeBox.isEmpty, isTrue);
    return (
      samples: saved.single.samples.length,
      termination: saved.single.termination?.reason,
      kind: saved.single.summary.kind,
    );
  }

  test('a row whose samples never reached the file ends as a sample-less '
      'trip rather than no trip', () async {
    final saved = await relaunchAndEnd(image(active: row()));
    expect(saved.samples, 0);
  });

  test('a sample file with no row is not a trip', () async {
    final next = await disk.relaunch(
      image(walBytes: ndjson(samples(8))),
      overrides: driver.overrides,
      now: minutesAfterStart,
    );
    addTearDown(next.dispose);
    expect(next.read(tripRecordingProvider).phase, TripRecordingPhase.idle,
        reason: 'the row is the recovery gate; orphan samples have no '
            'identity to be saved under');
    expect(disk.historyRepo.loadAll(), isEmpty);
  });

  test('a torn final line costs that line and nothing else', () async {
    final saved = await relaunchAndEnd(image(
      active: row(),
      walBytes: ndjson(samples(10), tail: '{"t":"2026-09-16T08:00:1'),
    ));
    expect(saved.samples, 10);
    expect(saved.termination, TripTerminationReason.recoveredAfterProcessDeath);
  });

  test('a legacy fat row wins over a sample file beside it', () async {
    final saved = await relaunchAndEnd(image(
      active: row(inRow: samples(4)),
      walBytes: ndjson(samples(9)),
    ));
    expect(saved.samples, 4,
        reason: 'pinned: a row that carries samples is the pre-#3758 '
            'layout, and the reader trusts it over the file');
  });

  test('a GPS-only row restores as a pause and ends with its fixes',
      () async {
    final saved = await relaunchAndEnd(image(
      active: row(distanceSource: 'gps'),
      walBytes: ndjson(samples(6, engine: false)),
    ));
    expect(saved.samples, 6);
  });

  test('a row written by THIS process is not a death', () async {
    final saved = await relaunchAndEnd(
      image(
        active: row(pid: ProcessDeathContext.instanceId),
        walBytes: ndjson(samples(3)),
      ),
      sameProcess: true,
    );
    expect(saved.termination, TripTerminationReason.userStopped,
        reason: 'the #3796 attribution needs a foreign process id');
  });
}

/// What [relaunchAndEnd] reports about the one saved trip.
typedef TripHistoryEntryView = ({
  int samples,
  TripTerminationReason? termination,
  TripKind kind,
});
