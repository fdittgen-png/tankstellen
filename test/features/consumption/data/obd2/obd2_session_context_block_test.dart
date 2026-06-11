// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_comm_diagnostics.dart'
    show Obd2CommDiagnostics, redactObd2Mac;
import 'package:tankstellen/features/consumption/data/obd2/obd2_response_class.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_session_context_block.dart';

/// Coverage for the #2472 error-log enrichment — the compact obd2Session
/// block stamped into the context map of OBD2-related errorLogger.log
/// calls so it rides INSIDE the existing TraceStorage envelope.
///
/// The contract that protects production exports:
///   * diagnostics OFF → the builder returns null → the export context is
///     byte-unchanged (no obd2Session key);
///   * an empty (no-session) collector → null too;
///   * enabled + a recorded session → the block is present, the MAC is
///     redacted, and it round-trips cleanly through jsonEncode (so it sits
///     happily inside the error-trace JSON the maintainer mails).
void main() {
  Obd2CommDiagnostics armed() {
    final collector = Obd2CommDiagnostics(enabled: true);
    collector
      ..beginSession(linkKind: 'ble', redactedMac: redactObd2Mac('AA:BB:CC:DD:EE:FF'))
      ..recordAdapterIdentity(elmVersion: 'ELM327 v1.5', protocolDigit: '6')
      ..noteConnectionEvent(attempt: true, success: true, timeToConnectMs: 900)
      ..noteConnectionEvent(drop: true)
      ..noteDispatch('010C')
      ..noteResult('010C', ResponseClass.ok, rttMs: 42)
      ..noteDispatch('0105')
      ..noteResult('0105', ResponseClass.timeout);
    return collector;
  }

  group('buildObd2SessionContextBlock', () {
    test('returns null when the collector is disabled', () {
      final collector = Obd2CommDiagnostics(enabled: false);
      expect(buildObd2SessionContextBlock(collector: collector), isNull);
    });

    test('returns null when enabled but no session was recorded', () {
      final collector = Obd2CommDiagnostics(enabled: true);
      expect(buildObd2SessionContextBlock(collector: collector), isNull);
    });

    test('returns an obd2Session block for a recorded session', () {
      final block = buildObd2SessionContextBlock(collector: armed());
      expect(block, isNotNull);
      expect(block!.keys, contains('obd2Session'));

      final session = block['obd2Session'] as Map<String, Object?>;
      // Compact short keys carried from the model's toJson.
      expect(session['pid'], isA<Map<dynamic, dynamic>>());
      expect((session['pid'] as Map).keys, containsAll(['010C', '0105']));
      expect((session['conn'] as Map)['dr'], 1); // one drop
    });

    test('redacts the MAC (no full address ever reaches the export)', () {
      final block = buildObd2SessionContextBlock(collector: armed())!;
      final session = block['obd2Session'] as Map<String, Object?>;
      final mac = session['mac'] as String;

      // Last four chars kept, everything before is the middle-dot mask.
      expect(mac, endsWith('E:FF'));
      expect(mac, contains('·'));
      expect(mac, isNot(contains('AA:BB')));
      expect(mac, isNot(contains('CC:DD')));
    });

    test('the block round-trips cleanly through jsonEncode', () {
      final block = buildObd2SessionContextBlock(collector: armed())!;
      // Must not throw — proves the block is JSON-safe inside the export.
      final encoded = jsonEncode(block);
      expect(encoded, contains('obd2Session'));
      expect(jsonDecode(encoded), isA<Map<dynamic, dynamic>>());
    });
  });

  group('production export contract (#2472)', () {
    test(
        'with diagnostics OFF the trace context is byte-unchanged '
        '(no obd2Session key)', () {
      final collector = Obd2CommDiagnostics(enabled: false);
      final context = obd2DisconnectTraceContext(collector: collector);

      // Byte-identical to the legacy context with no enrichment.
      expect(
        jsonEncode(context),
        equals(jsonEncode(<String, Object?>{
          'where': 'Obd2RecordingPipeline.stop: service disconnect failed',
        })),
      );
      expect(context.containsKey('obd2Session'), isFalse);
    });

    test('with an enabled session the context gains the obd2Session key', () {
      final context = obd2DisconnectTraceContext(collector: armed());
      expect(context.containsKey('obd2Session'), isTrue);
      expect(context['where'], isNotNull);
    });
  });
}
