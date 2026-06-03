// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/collectors/breadcrumb_collector.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connection_errors.dart';
import 'package:tankstellen/features/consumption/presentation/obd2_connect_telemetry.dart';

/// #2745 — error-log #14 trace #5: `recordObd2ConnectFailure` is the shared
/// connect-flow telemetry router for the pinned-connect picker AND the
/// live-trip recording-start path. An EXPECTED, already-user-surfaced
/// condition → breadcrumb; a genuine fault → ERROR.
class _CapturingRecorder implements TraceRecorder {
  final errors = <Object>[];
  @override
  Future<void> record(Object error, StackTrace stackTrace,
      {ServiceChainSnapshot? serviceChainState}) async {
    errors.add(error);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _CapturingRecorder rec;

  setUp(() {
    errorLogger.resetForTest();
    rec = _CapturingRecorder();
    errorLogger.testRecorderOverride = rec;
    BreadcrumbCollector.clear();
  });

  tearDown(errorLogger.resetForTest);

  group('recordObd2ConnectFailure (#2745)', () {
    test('an expected Obd2AdapterUnresponsive is a breadcrumb, NOT an ERROR',
        () async {
      recordObd2ConnectFailure(const Obd2AdapterUnresponsive(),
          StackTrace.current,
          where: 'pinned connect');

      // Allow the fire-and-forget log path (if any) to settle.
      await Future<void>.delayed(Duration.zero);
      expect(rec.errors, isEmpty);
      expect(
        BreadcrumbCollector.snapshot().map((b) => b.action),
        contains('OBD2 connect failed — expected user condition'),
      );
    });

    test('an expected Obd2ScanTimeout is a breadcrumb, NOT an ERROR',
        () async {
      recordObd2ConnectFailure(const Obd2ScanTimeout(), StackTrace.current,
          where: 'pinned connect');

      await Future<void>.delayed(Duration.zero);
      expect(rec.errors, isEmpty);
      expect(BreadcrumbCollector.snapshot(), isNotEmpty);
    });

    test('a genuine Obd2PermissionDenied STILL ERROR-logs (the guard)',
        () async {
      recordObd2ConnectFailure(const Obd2PermissionDenied(), StackTrace.current,
          where: 'pinned connect');

      await Future<void>.delayed(Duration.zero);
      expect(rec.errors, hasLength(1));
      expect(rec.errors.single.toString(), contains('pinned connect'));
      expect(BreadcrumbCollector.snapshot(), isEmpty);
    });

    test('a non-OBD2 exception STILL ERROR-logs (the guard)', () async {
      recordObd2ConnectFailure(Exception('unexpected'), StackTrace.current,
          where: 'connectAndStart');

      await Future<void>.delayed(Duration.zero);
      expect(rec.errors, hasLength(1));
      expect(rec.errors.single.toString(), contains('connectAndStart'));
    });
  });
}
