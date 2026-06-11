// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_session_completeness.dart';
import 'package:tankstellen/features/obd2/data/obd2_session_diagnostic.dart';

void main() {
  group('summariseObd2Completeness (#2469)', () {
    test('overall completeness% = Σ ok / Σ(targetHz × activeSeconds)', () {
      // 10 active seconds. RPM: target 5 Hz → expected 50, got 50 (100%).
      // Coolant: target 0.1 Hz → expected 1, got 1 (100%).
      const raw = Obd2SessionDiagnostic(
        sessionActiveSeconds: 10,
        pidStats: {
          '010C': Obd2PidStat(
              polled: 50, ok: 50, targetHz: 5.0, tier: 'dynamics'),
          '0105': Obd2PidStat(
              polled: 1, ok: 1, targetHz: 0.1, tier: 'thermalContext'),
        },
      );
      final s = summariseObd2Completeness(raw);
      expect(s.expectedReads, 51); // 50 + 1
      expect(s.achievedReads, 51);
      expect(s.completenessPercent, closeTo(100, 0.01));
      expect(s.completeness.overallPercent, closeTo(100, 0.01));
    });

    test('per-tier completeness + emit-gap when a tier under-delivers', () {
      // Dynamics target 5 Hz over 10 s = 50 expected, only 25 ok → 50%.
      // Mixture target 2 Hz over 10 s = 20 expected, 20 ok → 100%.
      const raw = Obd2SessionDiagnostic(
        sessionActiveSeconds: 10,
        pidStats: {
          '010C': Obd2PidStat(
              polled: 50, ok: 25, targetHz: 5.0, tier: 'dynamics'),
          '0104': Obd2PidStat(
              polled: 20, ok: 20, targetHz: 2.0, tier: 'mixture'),
        },
      );
      final s = summariseObd2Completeness(raw);
      expect(s.completeness.perTierPercent['dynamics'], closeTo(50, 0.01));
      expect(s.completeness.perTierPercent['mixture'], closeTo(100, 0.01));
      // The 50% dynamics tier is below the 0.7 threshold → emit-gap fires.
      expect(s.completeness.emitGapDetected, isTrue);
    });

    test('no emit-gap when every tier clears the threshold', () {
      const raw = Obd2SessionDiagnostic(
        sessionActiveSeconds: 10,
        pidStats: {
          '010C': Obd2PidStat(
              polled: 50, ok: 45, targetHz: 5.0, tier: 'dynamics'), // 90%
        },
      );
      final s = summariseObd2Completeness(raw);
      expect(s.completeness.emitGapDetected, isFalse);
    });

    test('effectiveHz filled per row = ok / activeSeconds + attainment', () {
      const raw = Obd2SessionDiagnostic(
        sessionActiveSeconds: 10,
        pidStats: {
          '010C': Obd2PidStat(
              polled: 40, ok: 40, targetHz: 5.0, tier: 'dynamics'),
        },
      );
      final s = summariseObd2Completeness(raw);
      final row = s.pidStats['010C']!;
      expect(row.effectiveHz, closeTo(4.0, 0.01)); // 40 / 10 s
      expect(row.targetHzAttainment, closeTo(0.8, 0.01)); // 4 / 5
    });

    test('active duty cycle is achieved/expected clamped to [0,1]', () {
      const raw = Obd2SessionDiagnostic(
        sessionActiveSeconds: 10,
        pidStats: {
          '010C': Obd2PidStat(
              polled: 30, ok: 30, targetHz: 5.0, tier: 'dynamics'), // 60%
        },
      );
      final s = summariseObd2Completeness(raw);
      expect(s.completeness.activeDutyCycle, closeTo(0.6, 0.01));
    });

    test('zero active seconds → no divide-by-zero, all zero', () {
      const raw = Obd2SessionDiagnostic(
        sessionActiveSeconds: 0,
        pidStats: {
          '010C': Obd2PidStat(polled: 5, ok: 5, targetHz: 5.0),
        },
      );
      final s = summariseObd2Completeness(raw);
      expect(s.expectedReads, 0);
      expect(s.completenessPercent, 0);
      expect(s.completeness.activeDutyCycle, 0);
    });

    test('empty pid table → zeroed completeness block, never null', () {
      final s = summariseObd2Completeness(const Obd2SessionDiagnostic());
      expect(s.expectedReads, 0);
      expect(s.achievedReads, 0);
      expect(s.completenessPercent, 0);
      expect(s.completeness, const Obd2CompletenessStats());
    });
  });
}
