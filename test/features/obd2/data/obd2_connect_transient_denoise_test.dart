// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/collectors/breadcrumb_collector.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/obd2/data/obd2_connection_errors.dart';
import 'package:tankstellen/features/obd2/data/obd2_read_telemetry.dart';

/// #2892 part C — the connect-log flood de-noiser. Error-log #22 spooled an
/// EXPECTED `Obd2AdapterUnresponsive` ("turn the ignition on and retry") 20×
/// as ERROR traces from the in-trip reconnect storm (a parked car). The new
/// `recordObd2ConnectTransient` routes the expected, user-surfaced connect
/// conditions to a breadcrumb while genuine faults stay ERROR traces — the
/// connect-path twin of the #2745/#2763 read de-noiser.
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

  group('isExpectedObd2ConnectTransient classifies the connect families', () {
    test('the user-surfaced connect family is expected', () {
      expect(isExpectedObd2ConnectTransient(const Obd2AdapterUnresponsive()),
          isTrue);
      expect(isExpectedObd2ConnectTransient(const Obd2ScanTimeout()), isTrue);
      expect(isExpectedObd2ConnectTransient(const Obd2BluetoothOff()), isTrue);
      expect(
          isExpectedObd2ConnectTransient(const Obd2DisconnectedException()),
          isTrue);
      expect(isExpectedObd2ConnectTransient(TimeoutException('connect')),
          isTrue);
      expect(
          isExpectedObd2ConnectTransient(StateError('transport closed')),
          isTrue);
      expect(
          isExpectedObd2ConnectTransient(StateError('not connected')), isTrue);
    });

    test('genuine faults are NOT expected (stay ERROR)', () {
      expect(isExpectedObd2ConnectTransient(const Obd2PermissionDenied()),
          isFalse);
      expect(
          isExpectedObd2ConnectTransient(const Obd2ProtocolInitFailed('garble')),
          isFalse);
      // A bare StateError that is NOT a transport race is a genuine bug.
      expect(isExpectedObd2ConnectTransient(StateError('bad index')), isFalse);
      expect(isExpectedObd2ConnectTransient(Exception('boom')), isFalse);
    });
  });

  group('recordObd2ConnectTransient routing', () {
    test('an expected Obd2AdapterUnresponsive is a breadcrumb, NOT an ERROR',
        () async {
      recordObd2ConnectTransient(const Obd2AdapterUnresponsive(),
          StackTrace.current,
          where: 'reconnect');

      await Future<void>.delayed(Duration.zero);
      expect(rec.errors, isEmpty);
      expect(
        BreadcrumbCollector.snapshot().map((b) => b.action),
        contains('OBD2 connect failed — expected transient'),
      );
    });

    test('a genuine Obd2PermissionDenied STILL ERROR-logs (the guard)',
        () async {
      recordObd2ConnectTransient(const Obd2PermissionDenied(),
          StackTrace.current,
          where: 'reconnect');

      await Future<void>.delayed(Duration.zero);
      expect(rec.errors, hasLength(1));
      expect(rec.errors.single.toString(), contains('reconnect'));
      expect(BreadcrumbCollector.snapshot(), isEmpty);
    });
  });
}
