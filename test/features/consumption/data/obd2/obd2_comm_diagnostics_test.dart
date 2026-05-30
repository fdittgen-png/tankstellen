// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_comm_diagnostics.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_response_class.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_session_diagnostic.dart';

void main() {
  group('Obd2CommDiagnostics — disabled is a pure no-op (#2464)', () {
    test('every record method is a no-op; snapshot stays the empty sentinel',
        () {
      final c = Obd2CommDiagnostics(); // enabled defaults to false
      expect(c.enabled, isFalse);

      c.beginSession(linkKind: 'ble', redactedMac: 'AA:BB:**:**:**:FF');
      c.recordAdapterIdentity(elmVersion: 'ELM327 v1.5', mtu: 247);
      c.recordHandshakeLine('ATZ', 'ELM327 v1.5', 80);
      c.noteDispatch('010C');
      c.noteResult('010C', ResponseClass.ok, rttMs: 40);
      c.noteConnectionEvent(attempt: true, success: true, timeToConnectMs: 900);
      c.noteFraming(garbage: true);
      c.noteFuelTier('pid5E');
      c.endSession();

      // The disabled snapshot is the const-default empty sentinel — no
      // rows added, nothing accumulated.
      expect(c.snapshot(), const Obd2SessionDiagnostic());
      expect(c.finishedSessions, isEmpty);
    });
  });

  group('Obd2CommDiagnostics — enabled accumulation (#2464)', () {
    test('noteDispatch/noteResult accumulate the 5-way per-PID counts', () {
      final c = Obd2CommDiagnostics(enabled: true);
      c.beginSession(linkKind: 'ble');

      // 010C: 4 dispatched, outcomes ok/ok/noData/timeout + 1 error reply.
      for (var i = 0; i < 5; i++) {
        c.noteDispatch('010C');
      }
      c.noteResult('010C', ResponseClass.ok, rttMs: 30);
      c.noteResult('010C', ResponseClass.ok, rttMs: 50);
      c.noteResult('010C', ResponseClass.noData);
      c.noteResult('010C', ResponseClass.timeout);
      c.noteResult('010C', ResponseClass.canError); // → error bucket

      final row = c.snapshot().pidStats['010C']!;
      expect(row.polled, 5);
      expect(row.ok, 2);
      expect(row.noData, 1);
      expect(row.timeout, 1);
      expect(row.error, 1);
    });

    test('every error-class folds into the single error counter', () {
      final c = Obd2CommDiagnostics(enabled: true);
      c.beginSession();
      c.noteResult('0105', ResponseClass.bufferFull);
      c.noteResult('0105', ResponseClass.canError);
      c.noteResult('0105', ResponseClass.unrecognized);
      c.noteResult('0105', ResponseClass.garbage);
      expect(c.snapshot().pidStats['0105']!.error, 4);
    });

    test('latency reservoir yields a sane p50/p95', () {
      final c = Obd2CommDiagnostics(enabled: true);
      c.beginSession();
      // 1..100 ms, in order — p50 ≈ 50, p95 ≈ 95 (nearest-rank).
      for (var ms = 1; ms <= 100; ms++) {
        c.noteResult('010C', ResponseClass.ok, rttMs: ms);
      }
      final row = c.snapshot().pidStats['010C']!;
      expect(row.latencyP50Ms, inInclusiveRange(48, 52));
      expect(row.latencyP95Ms, inInclusiveRange(93, 97));
      expect(row.latencyP50Ms, lessThan(row.latencyP95Ms));
    });

    test('connection / framing / fuel-tier counters accumulate', () {
      final c = Obd2CommDiagnostics(enabled: true);
      c.beginSession();
      c.noteConnectionEvent(attempt: true);
      c.noteConnectionEvent(attempt: true, failureReason: 'gattTimeout');
      c.noteConnectionEvent(attempt: true, success: true, timeToConnectMs: 800);
      c.noteConnectionEvent(drop: true);
      c.noteConnectionEvent(silentReconnect: true, timeToReconnectMs: 300);
      c.noteFraming(partialFrame: true);
      c.noteFraming(garbage: true);
      c.noteFuelTier('pid5E');
      c.noteFuelTier('pid5E');
      c.noteFuelTier('maf');

      final s = c.snapshot();
      expect(s.connection.attempts, 3);
      expect(s.connection.successes, 1);
      expect(s.connection.failuresByReason['gattTimeout'], 1);
      expect(s.connection.drops, 1);
      expect(s.connection.silentReconnects, 1);
      expect(s.connection.timeToConnectP50Ms, 800);
      expect(s.connection.timeToReconnectP50Ms, 300);
      expect(s.framing.partialFrames, 1);
      expect(s.framing.garbageReads, 1);
      expect(s.fuelTierTicks, {'pid5E': 2, 'maf': 1});
    });

    test('adapter identity + capped one-shot handshake transcript', () {
      final c = Obd2CommDiagnostics(enabled: true);
      c.beginSession();
      c.recordAdapterIdentity(
        elmVersion: 'ELM327 v1.5',
        protocolDigit: '6',
        mtu: 247,
        warmStart: true,
      );
      // Push beyond the cap — the ring must clamp.
      for (var i = 0; i < Obd2SessionDiagnostic.maxTranscriptLines + 10; i++) {
        c.recordHandshakeLine('AT$i', 'OK', i);
      }
      final s = c.snapshot();
      expect(s.elmVersion, 'ELM327 v1.5');
      expect(s.protocolDigit, '6');
      expect(s.mtu, 247);
      expect(s.warmStart, isTrue);
      expect(
        s.initTranscript.length,
        Obd2SessionDiagnostic.maxTranscriptLines,
      );
      // One-shot cap keeps the EARLIEST lines (the handshake is the value).
      expect(s.initTranscript.first.cmd, 'AT0');
    });

    test('the finished-session ring caps at maxSessions (5)', () {
      final c = Obd2CommDiagnostics(enabled: true);
      for (var i = 0; i < Obd2CommDiagnostics.maxSessions + 3; i++) {
        c.beginSession(linkKind: 'ble');
        c.noteDispatch('010C');
        c.endSession();
      }
      expect(
        c.finishedSessions.length,
        Obd2CommDiagnostics.maxSessions,
      );
    });

    test('beginSession finalises an in-progress session into the ring', () {
      final c = Obd2CommDiagnostics(enabled: true);
      c.beginSession(linkKind: 'ble');
      c.noteDispatch('010C');
      // No explicit endSession — the next beginSession should roll it over.
      c.beginSession(linkKind: 'classic');
      expect(c.finishedSessions.length, 1);
      expect(c.finishedSessions.first.linkKind, 'ble');
      expect(c.snapshot().linkKind, 'classic');
    });

    test('reset drops live + finished sessions', () {
      final c = Obd2CommDiagnostics(enabled: true);
      c.beginSession();
      c.noteDispatch('010C');
      c.endSession();
      c.beginSession();
      c.reset();
      expect(c.finishedSessions, isEmpty);
      expect(c.snapshot(), const Obd2SessionDiagnostic());
    });
  });

  group('Obd2CommDiagnostics — scheduler health (#2468)', () {
    test('backpressure / tick / governor counters accumulate', () {
      final c = Obd2CommDiagnostics(enabled: true);
      c.beginSession();
      c.recordSchedulerHealth(tick: true);
      c.recordSchedulerHealth(tick: true, backpressureSkip: true);
      c.recordSchedulerHealth(tick: true, backpressureSkip: true);
      c.recordSchedulerHealth(
        tickRateHz: 10.0,
        achievedReadsPerSecond: 8.5,
        dynamicsEffectiveHz: 4.2,
        demotions: 2,
        backedOffCount: 3,
        starved: true,
      );
      final s = c.snapshot().scheduler;
      expect(s.ticks, 3);
      expect(s.backpressureSkips, 2);
      expect(s.tickRateHz, 10.0);
      expect(s.achievedReadsPerSecond, 8.5);
      expect(s.dynamicsEffectiveHz, 4.2);
      expect(s.demotions, 2);
      expect(s.backedOffCount, 3);
      expect(s.starved, isTrue);
    });

    test('infinite dynamicsEffectiveHz clamps to 0 so JSON stays finite', () {
      final c = Obd2CommDiagnostics(enabled: true);
      c.beginSession();
      c.recordSchedulerHealth(dynamicsEffectiveHz: double.infinity);
      expect(c.snapshot().scheduler.dynamicsEffectiveHz, 0.0);
    });
  });

  group('Obd2CommDiagnostics — per-PID table extras (#2468)', () {
    test('dispatch carries targetHz + tier; result carries backoff state', () {
      final c = Obd2CommDiagnostics(enabled: true);
      c.beginSession();
      c.noteDispatch('010C', targetHz: 5.0, tier: 'dynamics');
      c.noteResult('010C', ResponseClass.timeout,
          rttMs: 5000, consecutiveFailures: 3, backedOff: true);
      final row = c.snapshot().pidStats['010C']!;
      expect(row.targetHz, 5.0);
      expect(row.tier, 'dynamics');
      expect(row.consecutiveFailures, 3);
      expect(row.backedOff, isTrue);
      expect(row.timeout, 1);
    });
  });

  group('Obd2CommDiagnostics — completeness + tri-state + fuel (#2469)', () {
    test('snapshot runs the completeness summary over active seconds', () {
      var fakeNow = DateTime(2026, 1, 1, 12);
      final c = Obd2CommDiagnostics(enabled: true, clock: () => fakeNow);
      c.beginSession();
      c.noteDispatch('010C', targetHz: 5.0, tier: 'dynamics');
      for (var i = 0; i < 50; i++) {
        c.noteResult('010C', ResponseClass.ok, rttMs: 30);
      }
      fakeNow = fakeNow.add(const Duration(seconds: 10)); // 10 active s
      final s = c.snapshot();
      expect(s.sessionActiveSeconds, 10);
      expect(s.expectedReads, 50); // 5 Hz × 10 s
      expect(s.achievedReads, 50);
      expect(s.completenessPercent, closeTo(100, 0.01));
      expect(s.pidStats['010C']!.effectiveHz, closeTo(5.0, 0.01));
    });

    test('tri-state records supported/unsupported/unknown', () {
      final c = Obd2CommDiagnostics(enabled: true);
      c.beginSession();
      c.recordSupportedTriState('010C', 'supported');
      c.recordSupportedTriState('0166', 'unsupported');
      c.recordSupportedTriState('015E', 'unknown');
      final tri = c.snapshot().discoveredSupported;
      expect(tri['010C'], 'supported');
      expect(tri['0166'], 'unsupported');
      expect(tri['015E'], 'unknown');
    });

    test('fuel-tier downgrade rollup + suspicious ratio', () {
      final c = Obd2CommDiagnostics(enabled: true);
      c.beginSession();
      c.recordFuelDowngrade(totalSamples: 200, suspiciousSamples: 40);
      final fd = c.snapshot().fuelDowngrade;
      expect(fd.totalSamples, 200);
      expect(fd.suspiciousSamples, 40);
      expect(fd.suspiciousRatio, closeTo(0.2, 0.001));
    });

    test('disabled → scheduler/tri-state/fuel tees are all no-ops', () {
      final c = Obd2CommDiagnostics(); // disabled
      c.beginSession();
      c.recordSchedulerHealth(tick: true, backpressureSkip: true);
      c.recordSupportedTriState('010C', 'supported');
      c.recordFuelDowngrade(totalSamples: 5, suspiciousSamples: 1);
      expect(c.snapshot(), const Obd2SessionDiagnostic());
    });
  });
}
