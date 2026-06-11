// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/collectors/breadcrumb_collector.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/obd2/data/obd2_connection_errors.dart';
import 'package:tankstellen/features/obd2/presentation/obd2_connect_telemetry.dart';

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

  // #2763 — error-log #15: `readVin`'s best-effort one-shot 0902 read times out
  // on a flaky/slow ELM327 and the contract is to swallow it. The dedicated
  // read-failure router routes an EXPECTED transient to a breadcrumb and a
  // GENUINE fault to an ERROR — mirroring `recordObd2ConnectFailure`.
  group('recordObd2ReadFailure (#2763)', () {
    test('a readVin TimeoutException is a breadcrumb, NOT an ERROR', () async {
      recordObd2ReadFailure(
        TimeoutException('ELM327 did not respond within 2.5s'),
        StackTrace.current,
        where: 'OBD2 readVin',
      );

      await Future<void>.delayed(Duration.zero);
      expect(rec.errors, isEmpty,
          reason: 'a flaky-comms timeout on the best-effort VIN read is the '
              'documented #2428 swallow-and-return-null contract');
      expect(
        BreadcrumbCollector.snapshot().map((b) => b.action),
        contains('OBD2 read failed — expected transient'),
      );
    });

    test('a StateError (concurrent-sendCommand race) is a breadcrumb',
        () async {
      recordObd2ReadFailure(
        StateError('Bad state: sendCommand already in flight'),
        StackTrace.current,
        where: 'OBD2 readVin',
      );

      await Future<void>.delayed(Duration.zero);
      expect(rec.errors, isEmpty);
      expect(BreadcrumbCollector.snapshot(), isNotEmpty);
    });

    test('an expected mid-read Obd2DisconnectedException is a breadcrumb',
        () async {
      recordObd2ReadFailure(
        const Obd2DisconnectedException(),
        StackTrace.current,
        where: 'OnboardingObd2Connector.readVin',
      );

      await Future<void>.delayed(Duration.zero);
      expect(rec.errors, isEmpty);
      expect(BreadcrumbCollector.snapshot(), isNotEmpty);
    });

    test('a genuine non-transient FormatException STILL ERROR-logs (the guard)',
        () async {
      recordObd2ReadFailure(
        const FormatException('garbled VIN frame'),
        StackTrace.current,
        where: 'OBD2 readVin',
      );

      await Future<void>.delayed(Duration.zero);
      expect(rec.errors, hasLength(1),
          reason: 'a real parse/IO fault must stay visible — only the '
              'documented transients are de-noised');
      expect(rec.errors.single.toString(), contains('OBD2 readVin'));
      expect(BreadcrumbCollector.snapshot(), isEmpty);
    });

    test('isExpectedObd2ReadTransient classifies the documented families',
        () {
      expect(isExpectedObd2ReadTransient(TimeoutException('x')), isTrue);
      expect(isExpectedObd2ReadTransient(StateError('x')), isTrue);
      expect(
          isExpectedObd2ReadTransient(const Obd2DisconnectedException()), isTrue);
      // A genuinely user-actionable connect error that is NOT a mid-read
      // disconnect (permission denied) stays a genuine fault.
      expect(isExpectedObd2ReadTransient(const Obd2PermissionDenied()), isFalse);
      expect(isExpectedObd2ReadTransient(const FormatException('x')), isFalse);
    });
  });
}
