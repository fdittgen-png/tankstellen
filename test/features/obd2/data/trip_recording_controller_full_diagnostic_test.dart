// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/diagnostics/obd2_diagnostic_trace.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/session/trip_full_diagnostics.dart';
import 'package:tankstellen/features/obd2/data/session/trip_recording_controller.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_transport.dart';

import '../../../helpers/silence_error_logger.dart';

/// #4548 / #4549 / #4550 — end to end through a real controller and
/// service: with full diagnostic recording on, every adapter command of
/// the trip lands in the trace, the health plan is polled, and the
/// start/stop snapshot runs with the headers restored.
const _responses = {
  'ATZ': 'ELM327 v1.5>',
  'ATE0': 'OK>',
  'ATL0': 'OK>',
  'ATH0': 'OK>',
  'ATH1': 'OK>',
  'ATSP0': 'OK>',
  'ATRV': '13.9V>',
  '0100': '41 00 BE 3E B8 11>',
  '010C': '41 0C 1A F8>',
  '010D': '41 0D 32>',
  '0142': '41 42 36 B0>',
  '03': '43 01 07 30>',
};

void main() {
  silenceErrorLoggerSpool();
  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('ctlfull'));
  tearDown(() async {
    await Obd2DiagnosticTrace.end();
    await dir.delete(recursive: true);
  });

  Future<(TripRecordingController, FakeObd2Transport)> controller(
      {required bool full}) async {
    final transport = FakeObd2Transport({..._responses});
    final svc = Obd2Service(transport);
    await svc.connect();
    final ctl = TripRecordingController(
      service: svc,
      pollInterval: const Duration(minutes: 1),
      schedulerTickRate: const Duration(milliseconds: 2),
      fullDiag: full
          ? TripFullDiagnostics(
              header: const {'automatic': false},
              beginTrace: (h) =>
                  Obd2DiagnosticTrace.begin(header: h, directory: dir),
            )
          : null,
    );
    return (ctl, transport);
  }

  test('on: trace holds the trip commands, the health plan, the snapshot '
      'and a decoded DTC; ATH0 always follows ATH1', () async {
    final (ctl, transport) = await controller(full: true);
    await ctl.start();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await ctl.stop();

    final files = dir.listSync().whereType<File>().toList();
    expect(files, hasLength(1));
    final lines = [
      for (final l in const LineSplitter().convert(files.single.readAsStringSync()))
        jsonDecode(l) as Map<String, dynamic>,
    ];
    final cmds = lines.where((l) => l['k'] == 'cmd').map((l) => l['c']).toSet();
    expect(cmds, containsAll(['010C', '010D', '0142', '03', '0902', 'ATH1', 'ATH0']));
    final phases = lines.where((l) => l['k'] == 'mark').map((l) => l['p']);
    expect(phases, containsAll(['snapshot-start', 'snapshot-stop', 'health-plan', 'end']));
    expect(
        lines.any((l) => l['p'] == 'dtc' && (l['codes'] as List).contains('P0730')),
        isTrue);
    final sent = transport.sentCommands;
    expect(sent.lastIndexOf('ATH0'), greaterThan(sent.lastIndexOf('ATH1')));
  });

  test('off: no trace, no health commands, no header switching', () async {
    final (ctl, transport) = await controller(full: false);
    await ctl.start();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await ctl.stop();
    expect(dir.listSync(), isEmpty);
    expect(transport.sentCommands, isNot(contains('ATH1')));
    expect(transport.sentCommands, isNot(contains('03')));
  });
}
