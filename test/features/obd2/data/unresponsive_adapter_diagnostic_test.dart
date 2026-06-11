// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/obd2/data/obd2_connection_errors.dart';
import 'package:tankstellen/features/obd2/data/unresponsive_adapter_diagnostic.dart';
import '../../../helpers/silence_error_logger.dart';

/// Captures every `errorLogger.log` call routed through the foreground
/// recorder seam, without standing up Hive / Riverpod. Mirrors the fake in
/// `pid_scheduler_test.dart`.
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

void main() {
  silenceErrorLoggerSpool();

  late _CaptureRecorder recorder;
  var fakeNow = DateTime(2026, 1, 1, 12);

  UnresponsiveAdapterDiagnostic build() => UnresponsiveAdapterDiagnostic(
        backoffThreshold: 3,
        window: const Duration(seconds: 30),
        clock: () => fakeNow,
      );

  setUp(() {
    errorLogger.resetForTest();
    recorder = _CaptureRecorder();
    errorLogger.testRecorderOverride = recorder;
    fakeNow = DateTime(2026, 1, 1, 12);
  });

  tearDown(() {
    errorLogger.resetForTest();
    errorLogger.spoolEnqueueOverride = ({
      required String isolateTaskName,
      required Object error,
      StackTrace? stack,
      Map<String, dynamic>? contextMap,
      DateTime? timestamp,
    }) async {};
  });

  // Let the fire-and-forget `unawaited(errorLogger.log(...))` settle.
  Future<void> drain() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  group('UnresponsiveAdapterDiagnostic — typed-disconnect suppression (#2671)',
      () {
    test(
        'a genuine timeout episode (threshold reached) STILL logs ONE error '
        '— guarding the suppression does not break the real diagnostic',
        () async {
      final diag = build();
      diag.onFailure(3, Exception('timeout'), StackTrace.current);
      await drain();

      expect(recorder.calls, hasLength(1),
          reason: 'a non-disconnect episode transition logs one ERROR');
    });

    test(
        'a typed Obd2DisconnectedException at threshold logs NOTHING — a '
        'drop episode must never spool the not-connected ERROR', () async {
      final diag = build();
      diag.onFailure(
          3, const Obd2DisconnectedException(), StackTrace.current);
      await drain();

      expect(recorder.calls, isEmpty,
          reason: 'a typed disconnect is a recoverable drop, not an '
              'unresponsive-adapter ERROR');
    });

    test(
        'a PlatformException(state, not connected) at threshold logs NOTHING '
        '— the exact field error must be suppressed', () async {
      final diag = build();
      diag.onFailure(
        3,
        PlatformException(code: 'state', message: 'not connected'),
        StackTrace.current,
      );
      await drain();

      expect(recorder.calls, isEmpty,
          reason: 'the not-connected platform error is the drop itself, '
              'not an adapter-unresponsive episode');
    });

    test(
        'after a suppressed disconnect, a later genuine timeout episode '
        'still logs (the episode latch was not consumed)', () async {
      final diag = build();
      // Suppressed: must not arm/consume the episode latch.
      diag.onFailure(
          3, const Obd2DisconnectedException(), StackTrace.current);
      await drain();
      expect(recorder.calls, isEmpty);

      // A genuine timeout episode now logs exactly once.
      diag.onFailure(3, Exception('timeout'), StackTrace.current);
      await drain();
      expect(recorder.calls, hasLength(1),
          reason: 'the suppressed disconnect must not have latched the '
              'episode, so a real timeout still logs');
    });
  });
}
