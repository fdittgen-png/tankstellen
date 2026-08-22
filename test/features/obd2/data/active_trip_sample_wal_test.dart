// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/trips/api.dart'
    show TripSample, TripSummary;
import 'package:tankstellen/features/obd2/data/active_trip_repository.dart';
import 'package:tankstellen/features/obd2/data/active_trip_sample_wal.dart';

/// #3758 — append-only sample WAL: the fix for the ~40 min recording
/// crash (whole-list re-serialization + compute() spawn every 5 s).
void main() {
  late Directory tempDir;
  late ActiveTripSampleWal wal;

  TripSample sample(int i) => TripSample(
        timestamp: DateTime.utc(2026, 8, 22, 9, 0, i),
        speedKmh: 50.0 + i,
        rpm: 1800.0 + i,
      );

  setUp(() {
    errorLogger.resetForTest();
    errorLogger.testRecorderOverride = _SilentRecorder();
    tempDir = Directory.systemTemp.createTempSync('wal_test');
    wal = ActiveTripSampleWal(supportDirOverride: () => tempDir);
  });

  tearDown(() async {
    await wal.clear();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    errorLogger.testRecorderOverride = null;
    errorLogger.resetForTest();
  });

  test('append writes one line per sample; readAll round-trips', () async {
    await wal.openFresh();
    for (var i = 0; i < 12; i++) {
      wal.append(sample(i));
    }
    final back = await wal.readAll();
    expect(back, hasLength(12));
    expect(back.first.speedKmh, 50.0);
    expect(back.last.rpm, 1811.0);
  });

  test('a torn final line (hard kill mid-write) is skipped — every '
      'other sample survives', () async {
    await wal.openFresh();
    for (var i = 0; i < 5; i++) {
      wal.append(sample(i));
    }
    await wal.close();
    final file = File('${tempDir.path}/${ActiveTripSampleWal.fileName}');
    file.writeAsStringSync('{"t":"torn', mode: FileMode.append);
    final back = await wal.readAll();
    expect(back, hasLength(5));
  });

  test('openFresh truncates a stale file; openAppend continues it',
      () async {
    await wal.openFresh();
    wal.append(sample(0));
    await wal.close();
    await wal.openAppend();
    wal.append(sample(1));
    expect(await wal.readAll(), hasLength(2));

    await wal.openFresh();
    wal.append(sample(9));
    final back = await wal.readAll();
    expect(back, hasLength(1));
    expect(back.single.speedKmh, 59.0);
  });

  test('clear deletes the file — recovery never resurrects a finished '
      'trip', () async {
    await wal.openFresh();
    wal.append(sample(0));
    await wal.clear();
    expect(await wal.readAll(), isEmpty);
    expect(
        File('${tempDir.path}/${ActiveTripSampleWal.fileName}').existsSync(),
        isFalse);
  });

  test('never-throws (#2349): a broken support dir degrades every '
      'operation to a logged no-op', () async {
    final broken = ActiveTripSampleWal(
        supportDirOverride: () => throw StateError('no disk'));
    await expectLater(broken.openFresh(), completes);
    expect(() => broken.append(sample(0)), returnsNormally);
    expect(await broken.readAll(), isEmpty);
    await expectLater(broken.clear(), completes);
  });

  group('ActiveTripRepository + WAL merge', () {
    late Box<String> box;

    setUp(() async {
      Hive.init('${tempDir.path}/hive');
      box = await Hive.openBox<String>('wal_merge_test');
    });

    tearDown(() async {
      await box.deleteFromDisk();
    });

    test('saveSnapshot persists meta-only; loadSnapshotWithSamples '
        'merges the WAL back — the recovery contract survives a kill',
        () async {
      final repo = ActiveTripRepository(box: box, sampleWal: wal);
      await wal.openFresh();
      final samples = [for (var i = 0; i < 8; i++) sample(i)];
      for (final s in samples) {
        wal.append(s);
      }
      await repo.saveSnapshot(ActiveTripSnapshot(
        id: 'trip-1',
        vehicleId: 'v1',
        vin: null,
        automatic: false,
        phase: 'recording',
        summary: const TripSummary(
          distanceKm: 3.2,
          maxRpm: 2400,
          highRpmSeconds: 0,
          idleSeconds: 4,
          harshBrakes: 0,
          harshAccelerations: 0,
        ),
        samples: samples,
        odometerStartKm: null,
        odometerLatestKm: null,
        startedAt: DateTime.utc(2026, 8, 22, 9),
        lastFlushedAt: DateTime.utc(2026, 8, 22, 9, 5),
      ));

      // The Hive ROW must not contain the samples (O(1) flush).
      final meta = repo.loadSnapshot();
      expect(meta, isNotNull);
      expect(meta!.samples, isEmpty,
          reason: 'meta-only row: the whole-list re-serialization that '
              'crashed 40-min recordings is gone');
      expect(meta.summary.distanceKm, 3.2);

      // Recovery path sees the full pre-#3758 contract.
      final merged = await repo.loadSnapshotWithSamples();
      expect(merged!.samples, hasLength(8));
      expect(merged.samples.last.rpm, 1807.0);

      // clearSnapshot drops row AND file.
      await repo.clearSnapshot();
      expect(repo.loadSnapshot(), isNull);
      expect(await wal.readAll(), isEmpty);
    });
  });
}

class _SilentRecorder implements TraceRecorder {
  @override
  Future<void> record(Object error, StackTrace stackTrace,
      {ServiceChainSnapshot? serviceChainState}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
