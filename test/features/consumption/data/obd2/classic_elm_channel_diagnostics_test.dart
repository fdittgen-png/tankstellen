// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/consumption/data/obd2/classic_elm_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/classic_method_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_comm_diagnostics.dart';

/// Captures every `errorLogger.log` call routed through the foreground
/// recorder seam, retaining the [ContextualError] so the test can assert
/// its [ErrorLayer]. Mirrors `obd2_connection_service_test.dart`.
class _CaptureRecorder implements TraceRecorder {
  final calls = <Object>[];

  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    ServiceChainSnapshot? serviceChainState,
  }) async {
    calls.add(error);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// In-memory double for [Obd2ClassicMethodChannel] — connect can return
/// false (clean RFCOMM miss) or throw (bonding / permission), and the
/// incoming stream can be driven to push bytes / errors.
class _FakeClassicPlugin extends Obd2ClassicMethodChannel {
  _FakeClassicPlugin();

  bool connectResult = true;
  Object? connectThrows;

  @override
  Future<bool> connect({required String address, required String uuid}) async {
    if (connectThrows != null) throw connectThrows!;
    return connectResult;
  }

  @override
  Future<void> write(List<int> bytes) async {}

  int disconnectCalls = 0;
  Object? disconnectError;

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
    if (disconnectError != null) throw disconnectError!;
  }

  final StreamController<List<int>> incomingController =
      StreamController<List<int>>.broadcast();

  @override
  Stream<List<int>> get incoming => incomingController.stream;

  Future<void> dispose() async {
    if (!incomingController.isClosed) await incomingController.close();
  }
}

void main() {
  late _FakeClassicPlugin fake;
  late _CaptureRecorder recorder;

  setUp(() {
    fake = _FakeClassicPlugin();
    Obd2CommDiagnostics.instance.reset();
    errorLogger.resetForTest();
    recorder = _CaptureRecorder();
    errorLogger.testRecorderOverride = recorder;
  });

  tearDown(() async {
    Obd2CommDiagnostics.instance.enabled = false;
    Obd2CommDiagnostics.instance.reset();
    errorLogger.resetForTest();
    await fake.dispose();
  });

  group('ClassicElmChannel connect-lifecycle counters (#2466)', () {
    test(
        'debugMode ON: a successful open records attempt + success + '
        'time-to-connect', () async {
      Obd2CommDiagnostics.instance
        ..enabled = true
        ..beginSession(linkKind: 'classic');

      final channel = ClassicElmChannel(address: 'AA:BB', plugin: fake);
      await channel.open();

      final conn = Obd2CommDiagnostics.instance.snapshot().connection;
      expect(conn.attempts, 1);
      expect(conn.successes, 1);
      expect(conn.failuresByReason, isEmpty);
      expect(conn.timeToConnectP50Ms, isNotNull);

      await channel.close();
    });

    test(
        'debugMode ON: a clean connect→false bins as rfcomm-open-fail '
        '(attempt counted, success not)', () async {
      Obd2CommDiagnostics.instance
        ..enabled = true
        ..beginSession(linkKind: 'classic');
      fake.connectResult = false;

      final channel = ClassicElmChannel(address: 'AA:BB', plugin: fake);
      await expectLater(channel.open(), throwsA(isA<StateError>()));

      final conn = Obd2CommDiagnostics.instance.snapshot().connection;
      expect(conn.attempts, 1);
      expect(conn.successes, 0);
      expect(conn.failuresByReason['rfcomm-open-fail'], 1);
    });

    test('debugMode ON: a bonding throw bins as not-bonded', () async {
      Obd2CommDiagnostics.instance
        ..enabled = true
        ..beginSession(linkKind: 'classic');
      fake.connectThrows = StateError('device not bonded — pair it first');

      final channel = ClassicElmChannel(address: 'AA:BB', plugin: fake);
      await expectLater(channel.open(), throwsA(isA<StateError>()));

      final conn = Obd2CommDiagnostics.instance.snapshot().connection;
      expect(conn.attempts, 1);
      expect(conn.failuresByReason['not-bonded'], 1);
    });

    test('debugMode OFF: open records nothing and still connects', () async {
      expect(Obd2CommDiagnostics.instance.enabled, isFalse);

      final channel = ClassicElmChannel(address: 'AA:BB', plugin: fake);
      await channel.open();

      expect(channel.isOpen, isTrue,
          reason: 'connect behaviour is unchanged when the gate is off');
      // No session begun + gate off ⇒ empty sentinel, zero counters.
      final conn = Obd2CommDiagnostics.instance.snapshot().connection;
      expect(conn.attempts, 0);
      expect(conn.successes, 0);

      await channel.close();
    });
  });

  group('ClassicElmChannel ErrorLayer tagging fix (#2466 / #2379)', () {
    test(
        'a forwarded socket error logs under ErrorLayer.other, never '
        'storage', () async {
      final channel = ClassicElmChannel(address: 'AA:BB', plugin: fake);
      await channel.open();

      // Drive a socket error up the plugin's incoming stream.
      final sub = channel.incoming.listen((_) {}, onError: (_) {});
      fake.incomingController.addError(Exception('socket reset'));
      await Future<void>.delayed(Duration.zero);

      final logged = recorder.calls.whereType<ContextualError>().toList();
      expect(logged, isNotEmpty,
          reason: 'the forwarded socket drop stays in release triage');
      expect(
        logged.where((e) => e.layer == ErrorLayer.storage),
        isEmpty,
        reason: 'a recoverable OBD2/BT transient must NOT carry storage — '
            'this was the FBP-vs-Classic inconsistency #2466 fixes',
      );
      expect(logged.every((e) => e.layer == ErrorLayer.other), isTrue);

      await sub.cancel();
      await channel.close();
    });

    test('a disconnect error on close also logs under ErrorLayer.other',
        () async {
      final channel = ClassicElmChannel(address: 'AA:BB', plugin: fake);
      await channel.open();
      fake.disconnectError = Exception('boom on disconnect');

      await channel.close();

      final logged = recorder.calls.whereType<ContextualError>().toList();
      expect(logged, isNotEmpty);
      expect(logged.where((e) => e.layer == ErrorLayer.storage), isEmpty);
      expect(logged.every((e) => e.layer == ErrorLayer.other), isTrue);
    });
  });
}
