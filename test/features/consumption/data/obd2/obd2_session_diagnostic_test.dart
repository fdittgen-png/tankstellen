// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_session_diagnostic.dart';

void main() {
  group('Obd2SessionDiagnostic (#2464)', () {
    Obd2SessionDiagnostic sample() => const Obd2SessionDiagnostic(
          linkKind: 'ble',
          redactedMac: 'AA:BB:**:**:**:FF',
          elmVersion: 'ELM327 v1.5',
          protocolDigit: '6',
          mtu: 247,
          warmStart: false,
          initTranscript: [
            Obd2HandshakeLine(cmd: 'ATZ', response: 'ELM327 v1.5', latencyMs: 80),
            Obd2HandshakeLine(cmd: '0100', response: '41 00 BE', latencyMs: 42),
          ],
          pidStats: {
            '010C': Obd2PidStat(
              polled: 100,
              ok: 92,
              noData: 3,
              timeout: 2,
              error: 3,
              latencyP50Ms: 40,
              latencyP95Ms: 110,
            ),
          },
          connection: Obd2ConnectionStats(
            attempts: 3,
            successes: 2,
            failuresByReason: {'gattTimeout': 1},
            drops: 1,
            silentReconnects: 1,
            visibleReconnects: 0,
            timeToConnectP50Ms: 900,
            timeToConnectP95Ms: 1800,
          ),
          scheduler: Obd2SchedulerStats(
            tickRateHz: 3.8,
            backpressureSkips: 4,
            demotions: 1,
            ticks: 380,
            achievedReadsPerSecond: 7.2,
            dynamicsEffectiveHz: 4.1,
            backedOffCount: 2,
            starved: false,
          ),
          framing: Obd2FramingStats(
            partialFrames: 2,
            leftoverBytes: 1,
            strayPrompts: 0,
            garbageReads: 1,
          ),
          fuelTierTicks: {'pid5E': 412, 'maf': 88},
          fuelDowngrade:
              Obd2FuelDowngradeStats(totalSamples: 500, suspiciousSamples: 25),
          sessionActiveSeconds: 100,
          discoveredSupported: {'010C': 'supported', '015E': 'unsupported'},
          completeness: Obd2CompletenessStats(
            overallPercent: 92.0,
            perTierPercent: {'dynamics': 92.0, 'mixture': 88.0},
            activeDutyCycle: 0.92,
            emitGapDetected: false,
          ),
          expectedReads: 500,
          achievedReads: 460,
          completenessPercent: 92.0,
        );

    test('two structurally-equal sessions are == and share a hashCode', () {
      final a = sample();
      final b = sample();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('a differing field breaks equality', () {
      final a = sample();
      final b = a.copyWith(protocolDigit: '8');
      expect(a, isNot(equals(b)));
    });

    test('JSON round-trips losslessly', () {
      final original = sample();
      final restored = Obd2SessionDiagnostic.fromJson(original.toJson());
      expect(restored, equals(original));
    });

    test('toJson uses the compact short keys', () {
      final json = sample().toJson();
      expect(json.containsKey('lk'), isTrue); // linkKind
      expect(json.containsKey('ev'), isTrue); // elmVersion
      expect(json.containsKey('pid'), isTrue); // pidStats
      expect(json.containsKey('conn'), isTrue); // connection
      // No long-form keys leaked.
      expect(json.containsKey('linkKind'), isFalse);
      expect(json.containsKey('elmVersion'), isFalse);
    });

    test('the empty default carries no rows and null completeness', () {
      const empty = Obd2SessionDiagnostic();
      expect(empty.pidStats, isEmpty);
      expect(empty.initTranscript, isEmpty);
      expect(empty.fuelTierTicks, isEmpty);
      expect(empty.expectedReads, isNull);
      expect(empty.achievedReads, isNull);
      expect(empty.completenessPercent, isNull);
      expect(empty.connection.attempts, 0);
      // Empty round-trips too.
      expect(
        Obd2SessionDiagnostic.fromJson(empty.toJson()),
        equals(empty),
      );
    });
  });
}
