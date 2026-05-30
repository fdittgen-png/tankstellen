// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_comm_diagnostics.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';

// Mirrors the shared AT-init boilerplate the other Obd2Service tests use.
const _initResponses = {
  'ATZ': 'ELM327 v1.5>',
  'ATE0': 'OK>',
  'ATL0': 'OK>',
  'ATH0': 'OK>',
  'ATSP0': 'OK>',
  // ATI firmware probe — drives the elmVersion + capability tier.
  'ATI': 'ELM327 v1.5>',
};

/// Build a service whose adapter MAC + link kind are stamped the way
/// `buildObd2Session` does in production, then run the init handshake.
Future<Obd2Service> _connect({
  Map<String, String> extra = const {},
  String mac = 'AA:BB:CC:DD:EE:FF',
  String linkKind = 'ble',
}) async {
  final transport = FakeObd2Transport({..._initResponses, ...extra});
  final service = Obd2Service(transport)
    ..adapterMac = mac
    ..linkKind = linkKind;
  await service.connect();
  return service;
}

void main() {
  // The connect path tees into the process-wide singleton (mirrors
  // Obd2DebugSessionRecorder). Reset it around every test so state never
  // leaks between cases.
  setUp(Obd2CommDiagnostics.instance.reset);
  tearDown(() {
    Obd2CommDiagnostics.instance.enabled = false;
    Obd2CommDiagnostics.instance.reset();
  });

  group('Obd2Service init → Obd2CommDiagnostics tee (#2465)', () {
    test(
        'debugMode ON: the collector snapshot carries the per-line init '
        'transcript + adapter identity + redacted MAC', () async {
      Obd2CommDiagnostics.instance.enabled = true;

      await _connect();
      final snap = Obd2CommDiagnostics.instance.snapshot();

      // Session identity: link kind + redacted MAC (no raw MAC anywhere).
      expect(snap.linkKind, 'ble');
      expect(snap.redactedMac, redactObd2Mac('AA:BB:CC:DD:EE:FF'));
      expect(snap.redactedMac, isNot(contains('AA:BB:CC:DD')));
      expect(snap.redactedMac, endsWith('E:FF'));

      // Adapter identity resolved during the handshake.
      expect(snap.elmVersion, 'ELM327 v1.5');
      expect(snap.warmStart, isFalse); // cold connect, no protocol cache
      expect(snap.capabilityTier, 'standardOnly'); // ELM327 v1.5 → standard

      // Per-line transcript: every AT line + the ATI probe, in order.
      final cmds = snap.initTranscript.map((l) => l.cmd).toList();
      expect(cmds, containsAllInOrder(<String>['ATZ', 'ATE0', 'ATSP0', 'ATI']));
      // The ATZ line carried the firmware banner reply.
      final atz = snap.initTranscript.firstWhere((l) => l.cmd == 'ATZ');
      expect(atz.response, contains('ELM327 v1.5'));
      // Latency is captured (a real Stopwatch — non-negative).
      expect(atz.latencyMs, greaterThanOrEqualTo(0));
    });

    test('debugMode ON: a genuine v2.2 firmware lands on the oemPids tier',
        () async {
      Obd2CommDiagnostics.instance.enabled = true;
      await _connect(extra: const {
        'ATZ': 'ELM327 v2.2>',
        'ATI': 'ELM327 v2.2>',
      });
      final snap = Obd2CommDiagnostics.instance.snapshot();
      expect(snap.elmVersion, 'ELM327 v2.2');
      expect(snap.capabilityTier, 'oemPidsCapable');
    });

    test(
        'debugMode OFF: the init path records nothing — pure no-op, the '
        'snapshot stays the empty sentinel', () async {
      // enabled defaults to false; the connect path teas must all
      // early-return.
      expect(Obd2CommDiagnostics.instance.enabled, isFalse);

      final service = await _connect();

      // Connect/init behaviour is unchanged — the service connected.
      expect(service.isConnected, isTrue);
      expect(service.adapterFirmware, 'ELM327 v1.5');

      // Nothing was collected.
      expect(Obd2CommDiagnostics.instance.snapshot().linkKind, isNull);
      expect(
        Obd2CommDiagnostics.instance.snapshot().initTranscript,
        isEmpty,
      );
      expect(Obd2CommDiagnostics.instance.finishedSessions, isEmpty);
    });
  });

  group('redactObd2Mac (#2465)', () {
    test('hides all but the last four characters', () {
      expect(redactObd2Mac('AA:BB:CC:DD:EE:FF'), '·············E:FF');
    });

    test('null and short inputs pass through', () {
      expect(redactObd2Mac(null), isNull);
      expect(redactObd2Mac('AB'), 'AB');
    });
  });
}
