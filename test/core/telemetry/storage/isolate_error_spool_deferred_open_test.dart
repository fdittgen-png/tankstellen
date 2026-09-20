// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/storage/hive_first_frame_boxes.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/storage/isolate_error_spool.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';

import '../../../helpers/hive_temp_dir.dart';

/// #4318 — the isolate error spool left the first-frame batch. The reason
/// it was there (#1105: pre-bind errors must land somewhere) still holds,
/// so this RUNS the pre-bind path with the spool box closed, exactly as a
/// cold start now has it.
class _Recorder implements TraceRecorder {
  final replayed = <Object>[];

  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    ServiceChainSnapshot? serviceChainState,
  }) async =>
      replayed.add(error);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Directory dir;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('spool_deferred_');
    Hive.init(dir.path);
    errorLogger.resetForTest();
    await HiveFirstFrameBoxes.openAll(null);
  });

  tearDown(() async {
    errorLogger.resetForTest();
    await closeHiveAndDeleteTemp(dir);
  });

  test('a pre-bind error with the spool box closed is still persisted, and '
      'the post-frame drain replays it', () async {
    expect(Hive.isBoxOpen(HiveBoxes.isolateErrorSpool), isFalse,
        reason: 'the first-frame batch no longer opens it');

    await errorLogger.log(ErrorLayer.storage, StateError('before bind'), null,
        context: const {'where': 'storage phase'});

    expect(await IsolateErrorSpool.length(), 1,
        reason: 'the spool opens its own box on first write');

    final recorder = _Recorder();
    expect(await IsolateErrorSpool.drain(recorder), 1);
    expect(recorder.replayed.single.toString(), contains('before bind'));
  });

  test('the drain on a launch with no pre-bind errors opens the box and '
      'replays nothing', () async {
    expect(await IsolateErrorSpool.drain(_Recorder()), 0);
    expect(Hive.isBoxOpen(HiveBoxes.isolateErrorSpool), isTrue);
  });
}
