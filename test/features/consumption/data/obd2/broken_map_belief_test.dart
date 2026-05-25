// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/broken_map_belief.dart';

void main() {
  group('BrokenMapBelief defaults', () {
    test('default constructor uses Beta(1, 9) prior — mean = 0.1', () {
      const belief = BrokenMapBelief();
      expect(belief.alpha, 1.0);
      expect(belief.beta, 9.0);
      expect(belief.observationCount, 0);
      expect(belief.lastUpdate, isNull);
      expect(belief.lastTrigger, BrokenMapReason.none);
      expect(belief.pointEstimate, closeTo(0.1, 1e-9));
    });
  });

  group('JSON round-trip + migration', () {
    test('round-trips alpha/beta/observationCount/lastUpdate/lastTrigger', () {
      final ts = DateTime.utc(2026, 5, 4, 12, 30);
      final original = BrokenMapBelief(
        alpha: 7.5,
        beta: 12.25,
        observationCount: 12,
        lastUpdate: ts,
        lastTrigger: BrokenMapReason.idleVacuumMissing,
      );

      final json = original.toJson();
      final parsed = BrokenMapBelief.fromJson(json);

      expect(parsed.alpha, 7.5);
      expect(parsed.beta, 12.25);
      expect(parsed.observationCount, 12);
      expect(parsed.lastUpdate, ts);
      expect(parsed.lastTrigger, BrokenMapReason.idleVacuumMissing);
      expect(parsed, original);
    });

    test('legacy confidence shape migrates into Beta(α, β) form', () {
      // Legacy #1423 record: confidence + observationCount only.
      final legacy = <String, dynamic>{
        'confidence': 0.6,
        'observationCount': 4,
        'lastTrigger': 'idleVacuumMissing',
      };
      final migrated = BrokenMapBelief.fromJson(legacy);
      // pseudoCount = 4 → α = 0.6 * 4 + 1 = 3.4 ; β = 0.4 * 4 + 9 = 10.6.
      expect(migrated.alpha, closeTo(3.4, 1e-9));
      expect(migrated.beta, closeTo(10.6, 1e-9));
      expect(migrated.observationCount, 4);
      expect(migrated.lastTrigger, BrokenMapReason.idleVacuumMissing);
    });

    test('legacy confidence with zero observations falls back to pseudoCount = 1',
        () {
      final legacy = <String, dynamic>{
        'confidence': 0.5,
        'observationCount': 0,
      };
      final migrated = BrokenMapBelief.fromJson(legacy);
      // pseudoCount = max(0, 1) = 1 → α = 0.5*1 + 1 = 1.5 ; β = 0.5*1 + 9 = 9.5.
      expect(migrated.alpha, closeTo(1.5, 1e-9));
      expect(migrated.beta, closeTo(9.5, 1e-9));
    });

    test('confidence + alpha both present → new shape wins (no double-decode)',
        () {
      // Defensive — if a forward-rolled record carries both fields,
      // the new shape takes precedence.
      final mixed = <String, dynamic>{
        'confidence': 0.99,
        'observationCount': 0,
        'alpha': 2.0,
        'beta': 8.0,
      };
      final parsed = BrokenMapBelief.fromJson(mixed);
      expect(parsed.alpha, 2.0);
      expect(parsed.beta, 8.0);
    });

    test('every BrokenMapReason serializes to its enum name', () {
      final cases = <BrokenMapReason, String>{
        BrokenMapReason.idleVacuumMissing: 'idleVacuumMissing',
        BrokenMapReason.revDeltaMissing: 'revDeltaMissing',
        BrokenMapReason.pleinCompletDiscrepancy: 'pleinCompletDiscrepancy',
        BrokenMapReason.etaImplausible: 'etaImplausible',
        BrokenMapReason.priorObservation: 'priorObservation',
        BrokenMapReason.none: 'none',
      };

      for (final entry in cases.entries) {
        final belief = BrokenMapBelief(lastTrigger: entry.key);
        final json = belief.toJson();
        expect(
          json['lastTrigger'],
          entry.value,
          reason: '${entry.key} should serialize to "${entry.value}"',
        );
        final back = BrokenMapBelief.fromJson(json);
        expect(back.lastTrigger, entry.key);
      }
    });
  });

  group('pointEstimate', () {
    test('equals α / (α + β)', () {
      const belief = BrokenMapBelief(alpha: 3, beta: 7);
      expect(belief.pointEstimate, closeTo(0.3, 1e-9));
    });

    test('returns 0 when both parameters are zero (degenerate guard)', () {
      const belief = BrokenMapBelief(alpha: 0, beta: 0);
      expect(belief.pointEstimate, 0.0);
    });
  });

  group('credibleInterval (#1424 § C)', () {
    test('Beta(1, 9) — wide interval (low data, high uncertainty)', () {
      const belief = BrokenMapBelief();
      final ci = belief.credibleInterval;
      // Wilson-score branch (β > 5 but α ≤ 5). Mean is 0.1; we expect
      // a reasonably wide interval that covers low values plus some
      // margin.
      expect(ci.$1, lessThan(belief.pointEstimate));
      expect(ci.$2, greaterThan(belief.pointEstimate));
      expect(ci.$2 - ci.$1, greaterThan(0.1),
          reason: 'low-data prior should be wide');
      expect(ci.$1, greaterThanOrEqualTo(0.0));
      expect(ci.$2, lessThanOrEqualTo(1.0));
    });

    test('Beta(50, 50) — narrow interval centred on 0.5 (≈ ±0.07)', () {
      const belief = BrokenMapBelief(alpha: 50, beta: 50);
      final ci = belief.credibleInterval;
      // Normal-approximation branch. Variance = 50*50/(100²*101)
      // = 0.00247... → sd ≈ 0.0497, margin ≈ 0.0975.
      expect(ci.$1, closeTo(0.5 - 0.0975, 0.02));
      expect(ci.$2, closeTo(0.5 + 0.0975, 0.02));
      expect((ci.$2 - ci.$1) / 2, closeTo(0.097, 0.02));
    });

    test('Beta(20, 5) — interval centred above 0.5, narrow but skewed', () {
      const belief = BrokenMapBelief(alpha: 20, beta: 5);
      final ci = belief.credibleInterval;
      expect(ci.$1, lessThan(belief.pointEstimate));
      expect(ci.$2, greaterThan(belief.pointEstimate));
      // mean = 0.8; sd ≈ sqrt(20*5/(25²*26)) ≈ 0.0784; margin ≈ 0.154.
      expect(ci.$1, closeTo(0.8 - 0.154, 0.05));
      expect(ci.$2, closeTo(0.8 + 0.154, 0.05));
    });

    test('Beta(0, 0) (degenerate) returns [0, 1]', () {
      const belief = BrokenMapBelief(alpha: 0, beta: 0);
      expect(belief.credibleInterval, (0.0, 1.0));
    });

    test('always clamps to [0, 1]', () {
      // Skewed Beta(2, 1): mean = 2/3 ≈ 0.667. The Wilson-score
      // approximation can over-shoot 1 before the clamp; the clamp
      // is what keeps the public contract honest.
      const belief = BrokenMapBelief(alpha: 2, beta: 1);
      final ci = belief.credibleInterval;
      expect(ci.$1, greaterThanOrEqualTo(0.0));
      expect(ci.$2, lessThanOrEqualTo(1.0));
    });
  });

  group('isVerifiedClean (#1424 § D)', () {
    test('not enough observations → false even with clean posterior', () {
      const belief = BrokenMapBelief(
        alpha: 5,
        beta: 95,
        observationCount: 30,
      );
      expect(belief.observationCount, lessThanOrEqualTo(50));
      expect(belief.isVerifiedClean, isFalse);
    });

    test('enough obs + clean posterior + tight CI → true', () {
      const belief = BrokenMapBelief(
        alpha: 5,
        beta: 95,
        observationCount: 60,
      );
      expect(belief.pointEstimate, lessThan(0.1));
      expect(belief.credibleInterval.$2, lessThan(0.3));
      expect(belief.isVerifiedClean, isTrue);
    });

    test('enough obs but mean ≥ 0.1 → false', () {
      const belief = BrokenMapBelief(
        alpha: 15,
        beta: 85,
        observationCount: 60,
      );
      // mean = 0.15 — fails the < 0.1 gate.
      expect(belief.isVerifiedClean, isFalse);
    });

    test('enough obs + low mean but wide CI → false', () {
      // Low n keeps the CI wide. Beta(0.5, 4.5) → mean = 0.1, n = 5.
      const belief = BrokenMapBelief(
        alpha: 0.5,
        beta: 4.5,
        observationCount: 60,
      );
      // pointEstimate = 0.1 — exactly at the boundary, fails the
      // strict < gate.
      expect(belief.pointEstimate, closeTo(0.1, 1e-9));
      expect(belief.isVerifiedClean, isFalse);
    });
  });

  group('copyWith', () {
    test('alpha change preserves other fields', () {
      final ts = DateTime.utc(2026, 5, 4, 12, 30);
      final original = BrokenMapBelief(
        alpha: 2,
        beta: 8,
        observationCount: 4,
        lastUpdate: ts,
        lastTrigger: BrokenMapReason.revDeltaMissing,
      );
      final updated = original.copyWith(alpha: 9);
      expect(updated.alpha, 9);
      expect(updated.beta, 8);
      expect(updated.observationCount, 4);
      expect(updated.lastUpdate, ts);
      expect(updated.lastTrigger, BrokenMapReason.revDeltaMissing);
    });
  });
}
