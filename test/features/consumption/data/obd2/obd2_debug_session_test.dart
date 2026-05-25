// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/auto_record_trace_log.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_debug_session.dart';

/// Unit tests for [Obd2DebugSessionRecorder] and [Obd2DebugSession]
/// (#1925) — the opt-in OBD2 debug-session recorder.
void main() {
  final t0 = DateTime.utc(2026, 5, 18, 14);
  DateTime at(int seconds) => t0.add(Duration(seconds: seconds));

  setUp(() {
    Obd2DebugSessionRecorder.reset();
    Obd2DebugSessionRecorder.enabled = false;
  });

  tearDown(() {
    Obd2DebugSessionRecorder.reset();
    Obd2DebugSessionRecorder.enabled = false;
  });

  group('disabled (opt-in off)', () {
    test('ingest / handshake / data are all no-ops', () {
      Obd2DebugSessionRecorder.ingest(AutoRecordEventKind.connectStarted,
          mac: 'AA:BB:CC:DD:EE:FF', timestamp: at(0));
      Obd2DebugSessionRecorder.recordHandshakeCommand('ATZ\r', 'OK', 50,
          clock: at(1));
      Obd2DebugSessionRecorder.recordData(at(2));
      expect(Obd2DebugSessionRecorder.currentSession, isNull);
      expect(Obd2DebugSessionRecorder.latestSession, isNull);
    });
  });

  group('enabled', () {
    setUp(() => Obd2DebugSessionRecorder.enabled = true);

    test('connectStarted opens a session with a sessionStarted event', () {
      Obd2DebugSessionRecorder.ingest(AutoRecordEventKind.connectStarted,
          mac: 'AA:BB:CC:DD:EE:FF', timestamp: at(0));
      final session = Obd2DebugSessionRecorder.currentSession;
      expect(session, isNotNull);
      expect(session!.adapterMac, 'AA:BB:CC:DD:EE:FF');
      expect(session.startedAt, at(0));
      expect(session.events.single.kind, Obd2SessionEventKind.sessionStarted);
    });

    test('handshake commands are recorded with command, reply and latency',
        () {
      Obd2DebugSessionRecorder.ingest(AutoRecordEventKind.connectStarted,
          timestamp: at(0));
      Obd2DebugSessionRecorder.recordHandshakeCommand('ATZ\r', 'ELM327 v1.5',
          120,
          clock: at(1));
      Obd2DebugSessionRecorder.recordHandshakeCommand('ATE0\r', 'OK', 40,
          clock: at(1));
      final handshakes = Obd2DebugSessionRecorder.currentSession!.events
          .where((e) => e.kind == Obd2SessionEventKind.handshakeCommand)
          .toList();
      expect(handshakes, hasLength(2));
      expect(handshakes.first.command, 'ATZ');
      expect(handshakes.first.response, 'ELM327 v1.5');
      expect(handshakes.first.latencyMs, 120);
    });

    test('connectSucceeded marks the connection established', () {
      Obd2DebugSessionRecorder.ingest(AutoRecordEventKind.connectStarted,
          timestamp: at(0));
      Obd2DebugSessionRecorder.ingest(AutoRecordEventKind.connectSucceeded,
          detail: 'ELM327 v1.5', timestamp: at(2));
      expect(Obd2DebugSessionRecorder.currentSession!.summary.outcome,
          'established');
    });

    test('connectFailed records the failure and finalises the session', () {
      Obd2DebugSessionRecorder.ingest(AutoRecordEventKind.connectStarted,
          timestamp: at(0));
      Obd2DebugSessionRecorder.ingest(AutoRecordEventKind.connectFailed,
          detail: 'timeout', timestamp: at(3));
      expect(Obd2DebugSessionRecorder.currentSession, isNull);
      final last = Obd2DebugSessionRecorder.latestSession!;
      expect(last.endedAt, at(3));
      expect(last.summary.outcome, 'failed');
    });

    test('a silence longer than the threshold is recorded as a data gap', () {
      Obd2DebugSessionRecorder.ingest(AutoRecordEventKind.connectStarted,
          timestamp: at(0));
      Obd2DebugSessionRecorder.recordData(at(1));
      Obd2DebugSessionRecorder.recordData(at(2)); // 1 s — no gap
      Obd2DebugSessionRecorder.recordData(at(12)); // 10 s — gap
      final gaps = Obd2DebugSessionRecorder.currentSession!.events
          .where((e) => e.kind == Obd2SessionEventKind.dataGap)
          .toList();
      expect(gaps, hasLength(1));
      expect(gaps.single.gapMs, 10000);
    });

    test('a data gap records vehicle state before and after the silence',
        () {
      Obd2DebugSessionRecorder.ingest(AutoRecordEventKind.connectStarted,
          timestamp: at(0));
      Obd2DebugSessionRecorder.recordData(at(1), speedKmh: 95, rpm: 2200);
      // 12 s later data resumes with the car stopped — the link died
      // mid-drive (pre-gap moving, post-gap stationary).
      Obd2DebugSessionRecorder.recordData(at(13), speedKmh: 0, rpm: 0);
      final gap = Obd2DebugSessionRecorder.currentSession!.events
          .firstWhere((e) => e.kind == Obd2SessionEventKind.dataGap);
      expect(gap.preGapSpeedKmh, 95);
      expect(gap.preGapRpm, 2200);
      expect(gap.postGapSpeedKmh, 0);
      expect(gap.postGapRpm, 0);
    });

    test('a session that ends while data is silent records a trailing gap',
        () {
      Obd2DebugSessionRecorder.ingest(AutoRecordEventKind.connectStarted,
          timestamp: at(0));
      Obd2DebugSessionRecorder.recordData(at(1), speedKmh: 80, rpm: 2000);
      // No further data — the session ends 30 s later.
      Obd2DebugSessionRecorder.endSession(clock: at(31));
      final gaps = Obd2DebugSessionRecorder.latestSession!.events
          .where((e) => e.kind == Obd2SessionEventKind.dataGap)
          .toList();
      expect(gaps, hasLength(1));
      expect(gaps.single.gapMs, 30000);
      expect(gaps.single.preGapSpeedKmh, 80);
      expect(gaps.single.postGapSpeedKmh, isNull,
          reason: 'data never resumed — post-gap state is unknown');
    });

    test('disconnect-save timer transitions are mapped into the session',
        () {
      Obd2DebugSessionRecorder.ingest(AutoRecordEventKind.connectStarted,
          timestamp: at(0));
      Obd2DebugSessionRecorder.ingest(
          AutoRecordEventKind.disconnectTimerStarted,
          timestamp: at(5));
      Obd2DebugSessionRecorder.ingest(
          AutoRecordEventKind.disconnectTimerFired,
          timestamp: at(65));
      final kinds = Obd2DebugSessionRecorder.currentSession!.events
          .map((e) => e.kind);
      expect(
          kinds,
          containsAll(<Obd2SessionEventKind>[
            Obd2SessionEventKind.disconnectTimerStarted,
            Obd2SessionEventKind.disconnectTimerFired,
          ]));
    });

    test('drop and silent-reconnect transitions are mapped', () {
      Obd2DebugSessionRecorder.ingest(AutoRecordEventKind.connectStarted,
          timestamp: at(0));
      Obd2DebugSessionRecorder.ingest(AutoRecordEventKind.dropDetected,
          timestamp: at(5));
      Obd2DebugSessionRecorder.ingest(
          AutoRecordEventKind.silentReconnectStarted,
          timestamp: at(5));
      Obd2DebugSessionRecorder.ingest(
          AutoRecordEventKind.silentReconnectSucceeded,
          timestamp: at(7));
      final s = Obd2DebugSessionRecorder.currentSession!.summary;
      expect(s.reconnectAttempts, 1);
      expect(s.reconnectsSucceeded, 1);
    });

    test('dropEscalatedToVisible maps to a reconnectFailed event', () {
      Obd2DebugSessionRecorder.ingest(AutoRecordEventKind.connectStarted,
          timestamp: at(0));
      Obd2DebugSessionRecorder.ingest(
          AutoRecordEventKind.dropEscalatedToVisible,
          timestamp: at(11));
      final kinds = Obd2DebugSessionRecorder.currentSession!.events
          .map((e) => e.kind);
      expect(kinds, contains(Obd2SessionEventKind.reconnectFailed));
    });

    test('coordinator / threshold events are not part of the session log',
        () {
      Obd2DebugSessionRecorder.ingest(AutoRecordEventKind.connectStarted,
          timestamp: at(0));
      Obd2DebugSessionRecorder.ingest(
          AutoRecordEventKind.thresholdCrossed,
          timestamp: at(1));
      Obd2DebugSessionRecorder.ingest(
          AutoRecordEventKind.speedSampleSupraThreshold,
          timestamp: at(2));
      // Only the sessionStarted event — the rest were ignored.
      expect(Obd2DebugSessionRecorder.currentSession!.events, hasLength(1));
    });

    test('endSession finalises the open session', () {
      Obd2DebugSessionRecorder.ingest(AutoRecordEventKind.connectStarted,
          timestamp: at(0));
      Obd2DebugSessionRecorder.endSession(clock: at(60));
      expect(Obd2DebugSessionRecorder.currentSession, isNull);
      expect(Obd2DebugSessionRecorder.latestSession!.endedAt, at(60));
    });

    test('a new connectStarted finalises the previous session', () {
      Obd2DebugSessionRecorder.ingest(AutoRecordEventKind.connectStarted,
          timestamp: at(0));
      Obd2DebugSessionRecorder.ingest(AutoRecordEventKind.connectStarted,
          timestamp: at(100));
      expect(Obd2DebugSessionRecorder.currentSession!.startedAt, at(100));
      // The first session was closed, not lost.
      expect(Obd2DebugSessionRecorder.latestSession!.startedAt, at(100));
    });

    test('summary aggregates handshakes, gaps and reconnects', () {
      Obd2DebugSessionRecorder.ingest(AutoRecordEventKind.connectStarted,
          timestamp: at(0));
      Obd2DebugSessionRecorder.recordHandshakeCommand('ATZ\r', 'OK', 100,
          clock: at(0));
      Obd2DebugSessionRecorder.recordHandshakeCommand('ATE0\r', 'OK', 30,
          clock: at(0));
      Obd2DebugSessionRecorder.ingest(AutoRecordEventKind.connectSucceeded,
          timestamp: at(1));
      Obd2DebugSessionRecorder.recordData(at(2));
      Obd2DebugSessionRecorder.recordData(at(20)); // 18 s gap
      // End at the last data point so no trailing gap is added (#1930).
      Obd2DebugSessionRecorder.endSession(clock: at(20));

      final s = Obd2DebugSessionRecorder.latestSession!.summary;
      expect(s.duration, const Duration(seconds: 20));
      expect(s.handshakeCommands, 2);
      expect(s.handshakeLatencyMs, 130);
      expect(s.dataGaps, 1);
      expect(s.longestDataGapMs, 18000);
      expect(s.outcome, 'established');
    });
  });
}
