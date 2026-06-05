// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_comm_diagnostics.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_diagnostics_summary.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_reconnect_telemetry.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_session_context_block.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_session_diagnostic.dart';

/// Structural tests for the #2905 reconnect/error telemetry: per-attempt
/// records, session-state transitions, the typed-drop + fallback markers,
/// the reason classifier, and that all of it reaches the compact export.
void main() {
  group('Obd2ReconnectReason.classifyReconnectReason (#2905)', () {
    test('folds connect errors into the compact taxonomy', () {
      expect(classifyReconnectReason(StateError('GATT_ERROR 133')),
          Obd2ReconnectReason.gatt133.code);
      expect(classifyReconnectReason('rfcomm-open-fail'),
          Obd2ReconnectReason.rfcommOpenFail.code);
      expect(classifyReconnectReason(StateError('socket closed')),
          Obd2ReconnectReason.rfcommOpenFail.code);
      expect(classifyReconnectReason(StateError('device not connected')),
          Obd2ReconnectReason.deviceNotConnected.code);
      expect(classifyReconnectReason('A connect timeout elapsed'),
          Obd2ReconnectReason.timeout.code);
      expect(classifyReconnectReason(const FormatException('weird parse')),
          Obd2ReconnectReason.other.code);
    });
  });

  group('Obd2CommDiagnostics.noteReconnectAttempt (#2905)', () {
    test('records a FAILED attempt with the right reason/backoff/path', () {
      final c = Obd2CommDiagnostics(enabled: true)..beginSession();
      c.noteReconnectAttempt(
        attemptNumber: 2,
        succeeded: false,
        reasonCode: Obd2ReconnectReason.gatt133.code,
        backoffMs: 5000,
        rssi: -72,
        latencyMs: 410,
        path: 'scan',
      );

      final rows = c.snapshot().reconnectAttempts;
      expect(rows, hasLength(1));
      final a = rows.single;
      expect(a.attemptNumber, 2);
      expect(a.succeeded, isFalse);
      expect(a.reasonCode, 'gatt-133');
      expect(a.backoffMs, 5000);
      expect(a.rssi, -72);
      expect(a.latencyMs, 410);
      expect(a.path, 'scan');
      expect(a.timestampMs, greaterThan(0));
    });

    test('a SUCCEEDED attempt forces the reason null', () {
      final c = Obd2CommDiagnostics(enabled: true)..beginSession();
      c.noteReconnectAttempt(
        attemptNumber: 1,
        succeeded: true,
        reasonCode: 'gatt-133', // should be dropped on success
        path: 'direct',
      );
      final a = c.snapshot().reconnectAttempts.single;
      expect(a.succeeded, isTrue);
      expect(a.reasonCode, isNull);
    });

    test('FIFO-caps the attempt list at maxReconnectAttempts', () {
      final c = Obd2CommDiagnostics(enabled: true)..beginSession();
      const n = Obd2SessionDiagnostic.maxReconnectAttempts + 10;
      for (var i = 0; i < n; i++) {
        c.noteReconnectAttempt(attemptNumber: i, succeeded: false,
            reasonCode: 'timeout');
      }
      final rows = c.snapshot().reconnectAttempts;
      expect(rows, hasLength(Obd2SessionDiagnostic.maxReconnectAttempts));
      // Oldest dropped first ⇒ the first retained ordinal is `10`.
      expect(rows.first.attemptNumber, 10);
      expect(rows.last.attemptNumber, n - 1);
    });

    test('disabled is a pure no-op', () {
      final c = Obd2CommDiagnostics()..beginSession();
      c.noteReconnectAttempt(attemptNumber: 1, succeeded: false,
          reasonCode: 'timeout');
      expect(c.snapshot(), const Obd2SessionDiagnostic());
    });
  });

  group('session-state transitions + markers (#2905)', () {
    test('records connected→dropped→reconnecting→reconnected transitions', () {
      final c = Obd2CommDiagnostics(enabled: true)..beginSession();
      c.noteSessionTransition(Obd2SessionState.connected);
      c.noteSessionTransition(Obd2SessionState.dropped,
          detail: 'transportError');
      c.noteSessionTransition(Obd2SessionState.reconnecting);
      c.noteSessionTransition(Obd2SessionState.reconnected);

      final t = c.snapshot().transitions;
      expect(t.map((e) => e.state).toList(),
          ['connected', 'dropped', 'reconnecting', 'reconnected']);
      expect(t[1].detail, 'transportError');
      expect(t.every((e) => e.timestampMs > 0), isTrue);
    });

    test('noteDisconnectException counts + marks the typed drop', () {
      final c = Obd2CommDiagnostics(enabled: true)..beginSession();
      c.noteDisconnectException();
      c.noteDisconnectException();
      final s = c.snapshot();
      expect(s.disconnectExceptions, 2);
      expect(s.transitions.map((e) => e.state),
          everyElement('disconnectedException'));
    });

    test('noteFallbackActivated stamps the marker ONCE (first wins)', () {
      final c = Obd2CommDiagnostics(enabled: true)..beginSession();
      c.noteFallbackActivated(detail: 'transportError');
      final firstMs = c.snapshot().fallbackActivatedAtMs;
      c.noteFallbackActivated(detail: 'silentFailure');
      final s = c.snapshot();
      expect(s.fallbackActivatedAtMs, firstMs);
      expect(s.fallbackActivatedAtMs, isNotNull);
      // But every activation still records a transition marker.
      expect(s.transitions.where((e) => e.state == 'fallbackActivated'),
          hasLength(2));
    });

    test('FIFO-caps the transition list at maxTransitions', () {
      final c = Obd2CommDiagnostics(enabled: true)..beginSession();
      const n = Obd2SessionDiagnostic.maxTransitions + 5;
      for (var i = 0; i < n; i++) {
        c.noteSessionTransition(Obd2SessionState.reconnecting);
      }
      expect(c.snapshot().transitions,
          hasLength(Obd2SessionDiagnostic.maxTransitions));
    });
  });

  group('export carries the new telemetry (#2905)', () {
    test('toJson round-trips the new short keys (ra/tn/fa/de)', () {
      final c = Obd2CommDiagnostics(enabled: true)..beginSession();
      c.noteReconnectAttempt(attemptNumber: 1, succeeded: false,
          reasonCode: 'timeout', backoffMs: 1000, path: 'direct');
      c.noteSessionTransition(Obd2SessionState.dropped, detail: 'x');
      c.noteFallbackActivated();
      c.noteDisconnectException();

      final json = c.snapshot().toJson();
      expect(json.containsKey('ra'), isTrue);
      expect(json.containsKey('tn'), isTrue);
      expect(json.containsKey('fa'), isTrue);
      expect(json.containsKey('de'), isTrue);
      expect((json['ra'] as List), isNotEmpty);
      expect(json['de'], 1);

      // Round-trips back into an identical model.
      final back = Obd2SessionDiagnostic.fromJson(
          jsonDecode(jsonEncode(json)) as Map<String, dynamic>);
      expect(back.reconnectAttempts, hasLength(1));
      expect(back.reconnectAttempts.single.reasonCode, 'timeout');
      // dropped + fallbackActivated + disconnectedException (the typed-drop
      // marker also records its own transition) = 3.
      expect(back.transitions, hasLength(3));
      expect(back.transitions.map((e) => e.state),
          containsAll(['dropped', 'fallbackActivated', 'disconnectedException']));
      expect(back.fallbackActivatedAtMs, isNotNull);
      expect(back.disconnectExceptions, 1);
    });

    test('buildObd2SessionContextBlock stamps the reconnect telemetry', () {
      final c = Obd2CommDiagnostics(enabled: true)
        ..beginSession(linkKind: 'ble', redactedMac: '··:DA');
      c.noteReconnectAttempt(attemptNumber: 1, succeeded: false,
          reasonCode: 'gatt-133', path: 'scan');
      c.noteSessionTransition(Obd2SessionState.dropped);

      final block = buildObd2SessionContextBlock(collector: c);
      expect(block, isNotNull);
      final session = block!['obd2Session'] as Map<String, Object?>;
      expect(session.containsKey('ra'), isTrue,
          reason: 'the trip export must carry the per-attempt timeline');
      expect(session.containsKey('tn'), isTrue,
          reason: 'the trip export must carry the session-state transitions');
    });
  });

  group('computeObd2DiagnosticsSummary reconnect rollup (#2905)', () {
    test('tallies attempts, successes, reasons + the markers', () {
      final c = Obd2CommDiagnostics(enabled: true)..beginSession();
      c.noteReconnectAttempt(attemptNumber: 1, succeeded: false,
          reasonCode: 'gatt-133');
      c.noteReconnectAttempt(attemptNumber: 2, succeeded: false,
          reasonCode: 'gatt-133');
      c.noteReconnectAttempt(attemptNumber: 3, succeeded: false,
          reasonCode: 'timeout');
      c.noteReconnectAttempt(attemptNumber: 4, succeeded: true);
      c.noteSessionTransition(Obd2SessionState.dropped);
      c.noteFallbackActivated();
      c.noteDisconnectException();

      final s = computeObd2DiagnosticsSummary(c.snapshot());
      expect(s.reconnectAttemptCount, 4);
      expect(s.reconnectSuccessCount, 1);
      // Reason tally sorted by count desc: gatt-133 (2) before timeout (1).
      expect(s.reconnectReasonCounts.keys.toList(), ['gatt-133', 'timeout']);
      expect(s.reconnectReasonCounts['gatt-133'], 2);
      expect(s.disconnectExceptions, 1);
      expect(s.fallbackActivated, isTrue);
      // dropped + fallbackActivated + disconnectedException = 3 transitions.
      expect(s.transitionCount, 3);
    });
  });
}
