// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/diagnostics/obd2_diagnostic_trace.dart';
import 'package:tankstellen/features/obd2/data/session/trip_full_diagnostics.dart';
import 'package:tankstellen/features/obd2/domain/pid_scheduler.dart';

import '../../../../helpers/silence_error_logger.dart';

/// #4549 / #4550 — the full-diagnostic collaborator.
void main() {
  silenceErrorLoggerSpool();
  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('fulldiag'));
  tearDown(() async {
    await Obd2DiagnosticTrace.end();
    await dir.delete(recursive: true);
  });

  Future<TripFullDiagnostics> traced({Duration? timeout}) async {
    final d = TripFullDiagnostics(
      header: const {},
      commandTimeout: timeout ?? const Duration(seconds: 3),
      beginTrace: (h) => Obd2DiagnosticTrace.begin(header: h, directory: dir),
    );
    await d.begin();
    return d;
  }

  PidScheduler scheduler() =>
      PidScheduler(transport: (_) async => 'NO DATA', tickRate: const Duration(hours: 1));

  test('subscribes the health plan in the diagnosticSweep tier, skipping '
      'what the trip already polls', () {
    final s = scheduler()
      ..subscribe('0142', ScheduledPid(hz: 1), (_) {});
    final diag = TripFullDiagnostics(header: const {});
    diag.subscribe(s);
    expect(diag.subscribedCommands, isNot(contains('0142')));
    expect(diag.subscribedCommands, containsAll(['01A4', '0101', '03', '07']));
    expect(s.subscribedCommands, containsAll(diag.subscribedCommands));
  });

  test('three NO DATA in a row drop a command; a real reply resets', () {
    final s = scheduler();
    final calls = <String, void Function(String)>{};
    // Capture the callbacks the collaborator registers.
    final diag = TripFullDiagnostics(header: const {});
    diag.subscribe(_Capturing(s, calls));
    final gear = calls['01A4']!;
    gear('NO DATA');
    gear('41 A4 02 20 0F A0');
    gear('NO DATA');
    gear('NO DATA');
    expect(diag.subscribedCommands, contains('01A4'));
    gear('NO DATA');
    expect(diag.subscribedCommands, isNot(contains('01A4')));
  });

  group('snapshot', () {
    TripFullDiagnostics opened() => TripFullDiagnostics(
          header: const {},
          beginTrace: (_) async => null,
        );

    test('without a trace it sends nothing', () async {
      final sent = <String>[];
      await opened().snapshot('start', (c) async {
        sent.add(c);
        return 'OK';
      });
      expect(sent, isEmpty);
    });
  });

  test('snapshot sends the identity sequence, then ATH1 … ATH0, and '
      'restores ATH0 even when the scan throws (fault injection)', () async {
    final sent = <String>[];
    final diag = await traced();
    await diag.snapshot('start', (c) async {
      sent.add(c);
      if (c == '0100') throw StateError('bus fault');
      return 'OK';
    });
    expect(sent.first, 'ATDP');
    expect(sent, containsAllInOrder(['0A', '0902', 'ATH1', '0100', 'ATH0']));
    expect(sent.last, 'ATH0');
  });

  test('a silent bus ends the snapshot after two failures — a stop never '
      'hangs on a dead ECU — and never throws', () async {
    final sent = <String>[];
    final diag = await traced(timeout: const Duration(milliseconds: 5));
    await expectLater(
      diag.snapshot('stop', (c) async {
        sent.add(c);
        throw StateError('timeout');
      }),
      completes,
    );
    expect(sent, ['ATDP', 'ATRV']);
    await diag.end(reason: 'userStop');
    final text = File(diag.debugTraceFile!.path).readAsStringSync();
    expect(text, contains('"p":"snapshot-stop-done"'));
    expect(text, contains('"aborted":true'));
    expect(text, contains('"reason":"userStop"'));
  });
}

/// Records the callbacks a subscriber registers, forwarding to [inner].
class _Capturing implements PidScheduler {
  _Capturing(this.inner, this.calls);
  final PidScheduler inner;
  final Map<String, void Function(String)> calls;

  @override
  void subscribe(String command, ScheduledPid config,
      void Function(String response) onResult) {
    calls[command] = onResult;
    inner.subscribe(command, config, onResult);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);

  @override
  Set<String> get subscribedCommands => inner.subscribedCommands;

  @override
  void unsubscribe(String command) => inner.unsubscribe(command);
}
