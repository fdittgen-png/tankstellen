// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/obd2/data/active_trip_sample_wal.dart';
import 'package:tankstellen/features/trips/api.dart' show TripSample;

/// #4357 — a WAL write that failed must be observable.
///
/// An [IOSink] is fire-and-forget: `writeln` returns void, and the only
/// place a failed write is ever reported is the sink's `done` future.
/// Nothing read that future, so a full disk, a deleted container or an
/// iOS file-protection refusal left the WAL reporting `isWritable:
/// true` and an `appendedCount` climbing towards a number of samples
/// that were never on disk. The repository strips those samples out of
/// the Hive snapshot row on the strength of that answer — which is the
/// literal definition of "unacknowledged buffering labelled durable".
///
/// The fault is injected the way the platform produces it: the WAL's
/// file path is occupied by a DIRECTORY, so `openWrite` succeeds
/// (it is lazy) and the underlying open fails later, asynchronously,
/// exactly like a protected-data refusal after the sink was created.
void main() {
  late Directory tempDir;
  late ActiveTripSampleWal wal;

  TripSample sample(int i) => TripSample(
        timestamp: DateTime.utc(2026, 9, 20, 7, 0, i),
        speedKmh: 40.0 + i,
        rpm: 1500.0 + i,
      );

  setUp(() {
    errorLogger.resetForTest();
    errorLogger.testRecorderOverride = _SilentRecorder();
    tempDir = Directory.systemTemp.createTempSync('wal_fault_test');
    wal = ActiveTripSampleWal(supportDirOverride: () => tempDir);
  });

  tearDown(() async {
    errorLogger.testRecorderOverride = null;
    errorLogger.resetForTest();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// Occupy the WAL's own path with a directory — every write to it
  /// fails at the OS level.
  void blockThePath() {
    Directory('${tempDir.path}/${ActiveTripSampleWal.fileName}')
        .createSync(recursive: true);
  }

  test('a healthy WAL is writable AND durable, with no fault', () async {
    await wal.openFresh();
    wal.append(sample(0));
    await wal.close();

    expect(wal.lastFault, isNull);
    expect(wal.isDurable, isFalse,
        reason: 'closed: there is no open sink to be durable through');
    expect(await wal.readAll(), hasLength(1));
  });

  test('a write that never reaches the file surfaces on the faults stream '
      'and takes isDurable down with it', () async {
    blockThePath();
    final seen = <ActiveTripWalFault>[];
    final sub = wal.faults.listen(seen.add);

    await wal.openFresh();
    expect(wal.isWritable, isTrue, reason: 'openWrite is lazy — it succeeded');
    expect(wal.isDurable, isTrue, reason: 'nothing has failed yet');

    wal.append(sample(0));
    // The sink reports the failed open on `done`, asynchronously.
    await wal.faults.first.timeout(const Duration(seconds: 5));
    await sub.cancel();

    expect(seen, hasLength(1));
    expect(seen.single.kind, ActiveTripWalFaultKind.write);
    expect(seen.single.error, isA<FileSystemException>());
    expect(wal.lastFault, same(seen.single));
    expect(wal.isDurable, isFalse,
        reason: 'the one predicate that may be read as "this is on disk"');
  });

  test('the failure is never reported as durable, even though the sink '
      'looks open', () async {
    blockThePath();
    await wal.openFresh();
    wal.append(sample(0));
    await wal.faults.first.timeout(const Duration(seconds: 5));

    expect(wal.isDurable, isFalse);
    // isWritable stays true on purpose: it is the ROUTING answer, and
    // flipping it mid-trip would make the stop path fall back to an
    // in-memory list that starts at the fault, discarding the lines
    // that DID reach the file. Wiring isDurable into the snapshot-strip
    // and read-back decisions is S6's persistence observation (#4354).
    expect(wal.isWritable, isTrue);
    expect(wal.isDurable, isNot(wal.isWritable),
        reason: 'the two answers must be able to disagree — a single flag '
            'is how "enqueued" came to mean "durable"');
  });

  test('appending after the sink died records a fault and does not inflate '
      'appendedCount', () async {
    blockThePath();
    await wal.openFresh();
    wal.append(sample(0));
    await wal.faults.first.timeout(const Duration(seconds: 5));
    final afterFirst = wal.appendedCount;

    wal.append(sample(1));
    wal.append(sample(2));

    expect(wal.appendedCount, afterFirst,
        reason: 'a sample the sink refused was never appended to anything');
    expect(wal.lastFault, isNotNull);
  });

  test('a failed close is a fault too — a trip is not persisted on a sink '
      'that could not drain', () async {
    blockThePath();
    await wal.openFresh();
    wal.append(sample(0));

    await wal.close();

    expect(wal.lastFault, isNotNull);
    expect(wal.lastFault!.kind,
        anyOf(ActiveTripWalFaultKind.write, ActiveTripWalFaultKind.close));
    expect(wal.isDurable, isFalse);
  });

  test('reopening a healthy path clears the fault — a recovered WAL is '
      'durable again', () async {
    blockThePath();
    await wal.openFresh();
    wal.append(sample(0));
    await wal.faults.first.timeout(const Duration(seconds: 5));
    expect(wal.lastFault, isNotNull);

    await wal.close();
    Directory('${tempDir.path}/${ActiveTripSampleWal.fileName}')
        .deleteSync(recursive: true);
    await wal.openFresh();

    expect(wal.lastFault, isNull);
    expect(wal.isDurable, isTrue);
    wal.append(sample(1));
    await wal.close();
    expect(await wal.readAll(), hasLength(1));
  });

  test('every method still keeps its never-throws contract under the '
      'fault', () async {
    blockThePath();
    await expectLater(wal.openFresh(), completes);
    expect(() => wal.append(sample(0)), returnsNormally);
    await expectLater(wal.readAll(), completes);
    await expectLater(wal.close(), completes);
    await expectLater(wal.clear(), completes);
  });
}

class _SilentRecorder implements TraceRecorder {
  @override
  Future<void> record(Object error, StackTrace stackTrace,
      {ServiceChainSnapshot? serviceChainState}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
