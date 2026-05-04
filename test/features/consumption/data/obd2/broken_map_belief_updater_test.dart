import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/broken_map_belief.dart';
import 'package:tankstellen/features/consumption/data/obd2/broken_map_belief_updater.dart';

/// Reference EMA α used by [BrokenMapBeliefUpdater.update]. Kept here
/// as a literal so test assertions are self-explanatory; if production
/// retunes α the failing tests document the change.
const double _alpha = 0.4;

void main() {
  group('vacuumMissingScore', () {
    test('returns 0.0 when delta is at the healthy boundary (45 kPa)', () {
      // baro 100 kPa, map 55 kPa → delta 45 kPa → healthy.
      final s = BrokenMapBeliefUpdater.vacuumMissingScore(
        baroKpa: 100,
        mapKpa: 55,
      );
      expect(s, 0.0);
    });

    test('returns 1.0 when delta is at/below the suspicious boundary (15 kPa)',
        () {
      // baro 100 kPa, map 90 kPa → delta 10 kPa → strong evidence
      // (clamped from a negative formula value).
      final s = BrokenMapBeliefUpdater.vacuumMissingScore(
        baroKpa: 100,
        mapKpa: 90,
      );
      expect(s, 1.0);
    });

    test('linear interp at delta 30 returns 0.5', () {
      // baro 100 kPa, map 70 kPa → delta 30 → midpoint between 15 and 45.
      final s = BrokenMapBeliefUpdater.vacuumMissingScore(
        baroKpa: 100,
        mapKpa: 70,
      );
      expect(s, closeTo(0.5, 1e-9));
    });
  });

  group('revDeltaMissingScore', () {
    test('returns 0.0 when |rev - idle| is at healthy boundary (30 kPa)', () {
      final s = BrokenMapBeliefUpdater.revDeltaMissingScore(
        mapIdleKpa: 100,
        mapRevvedKpa: 70,
      );
      expect(s, 0.0);
    });

    test('returns 1.0 when |rev - idle| is at/below suspicious boundary (8 kPa)',
        () {
      final s = BrokenMapBeliefUpdater.revDeltaMissingScore(
        mapIdleKpa: 100,
        mapRevvedKpa: 95,
      );
      expect(s, 1.0);
    });

    test('linear interp at delta 19 returns 0.5', () {
      // |rev - idle| = 19 → midpoint between 8 and 30.
      final s = BrokenMapBeliefUpdater.revDeltaMissingScore(
        mapIdleKpa: 100,
        mapRevvedKpa: 81,
      );
      expect(s, closeTo(0.5, 1e-9));
    });
  });

  group('discrepancySeverityScore', () {
    test('returns 0.0 when ratio is at healthy boundary (1.3)', () {
      final s = BrokenMapBeliefUpdater.discrepancySeverityScore(ratio: 1.3);
      expect(s, 0.0);
    });

    test('returns 1.0 when ratio is at/above suspicious boundary (2.2)', () {
      final s = BrokenMapBeliefUpdater.discrepancySeverityScore(ratio: 2.2);
      expect(s, 1.0);
    });

    test('linear interp at ratio 1.75 returns 0.5', () {
      final s = BrokenMapBeliefUpdater.discrepancySeverityScore(ratio: 1.75);
      expect(s, closeTo(0.5, 1e-9));
    });
  });

  group('etaImplausibilityScore', () {
    test('returns 0.0 when proposedEta is at healthy boundary (0.97)', () {
      final s = BrokenMapBeliefUpdater.etaImplausibilityScore(
        proposedEta: 0.97,
      );
      expect(s, 0.0);
    });

    test('returns 1.0 when proposedEta is at/above suspicious boundary (1.22)',
        () {
      final s = BrokenMapBeliefUpdater.etaImplausibilityScore(
        proposedEta: 1.22,
      );
      expect(s, 1.0);
    });

    test('linear interp at proposedEta 1.095 returns 0.5', () {
      final s = BrokenMapBeliefUpdater.etaImplausibilityScore(
        proposedEta: 1.095,
      );
      expect(s, closeTo(0.5, 1e-9));
    });
  });

  group('update — EMA mechanics', () {
    test('single update of score 1.0 yields confidence == α', () {
      final now = DateTime.utc(2026, 5, 4, 12);
      const prev = BrokenMapBelief();

      final next = BrokenMapBeliefUpdater.update(prev, 1.0, now: now);

      expect(next.confidence, closeTo(_alpha, 1e-9));
      expect(next.observationCount, 1);
      expect(next.lastUpdate, now);
    });

    test('five sequential 0.4 observations stay around 0.4 (no compounding)',
        () {
      // EMA with constant input converges to that input — it does NOT
      // compound the way Bayesian accumulation does. Spec §E flags this.
      // Closed form after n updates from 0: x × (1 - (1-α)^n)
      // For n=5, α=0.4 → 0.4 × (1 - 0.6^5) ≈ 0.369. Confidence MUST stay
      // bounded by the input — never exceed it — and asymptotically
      // approach it.
      final now = DateTime.utc(2026, 5, 4, 12);
      BrokenMapBelief belief = const BrokenMapBelief();
      final history = <double>[];
      for (var i = 0; i < 5; i++) {
        belief = BrokenMapBeliefUpdater.update(belief, 0.4, now: now);
        history.add(belief.confidence);
      }
      // Never exceeds the input — would only happen if EMA compounded.
      expect(history.every((c) => c <= 0.4 + 1e-9), isTrue);
      // Approaching the input, not stuck.
      expect(belief.confidence, greaterThan(0.3));
      expect(belief.confidence, closeTo(0.369, 0.01));
      expect(belief.observationCount, 5);

      // Many more iterations get arbitrarily close to 0.4.
      for (var i = 0; i < 50; i++) {
        belief = BrokenMapBeliefUpdater.update(belief, 0.4, now: now);
      }
      expect(belief.confidence, closeTo(0.4, 1e-6));
    });

    test('strong observation with reason updates lastTrigger and stamps fields',
        () {
      final now = DateTime.utc(2026, 5, 4, 12);
      const prev = BrokenMapBelief();

      final next = BrokenMapBeliefUpdater.update(
        prev,
        0.9,
        now: now,
        reason: BrokenMapReason.idleVacuumMissing,
      );

      expect(next.lastTrigger, BrokenMapReason.idleVacuumMissing);
      expect(next.observationCount, 1);
      expect(next.lastUpdate, now);
      // 0.4 × 0.9 + 0.6 × 0 = 0.36
      expect(next.confidence, closeTo(0.36, 1e-9));
    });

    test('weak observation does NOT overwrite a previously-set lastTrigger',
        () {
      final t0 = DateTime.utc(2026, 5, 4, 12);
      final t1 = DateTime.utc(2026, 5, 4, 12, 5);
      const prev = BrokenMapBelief();

      // Strong hit sets the trigger.
      final after = BrokenMapBeliefUpdater.update(
        prev,
        0.9,
        now: t0,
        reason: BrokenMapReason.idleVacuumMissing,
      );
      expect(after.lastTrigger, BrokenMapReason.idleVacuumMissing);

      // Weak follow-up — score below the strong threshold AND a different
      // reason supplied. Trigger must remain sticky.
      final later = BrokenMapBeliefUpdater.update(
        after,
        0.2,
        now: t1,
        reason: BrokenMapReason.revDeltaMissing,
      );
      expect(later.lastTrigger, BrokenMapReason.idleVacuumMissing);
      expect(later.observationCount, 2);
    });

    test('belief at 0.8 decays toward 0 after five zero-score updates', () {
      final now = DateTime.utc(2026, 5, 4, 12);
      BrokenMapBelief belief = const BrokenMapBelief(confidence: 0.8);
      for (var i = 0; i < 5; i++) {
        belief = BrokenMapBeliefUpdater.update(belief, 0.0, now: now);
      }
      // (1 - α)^5 × 0.8 ≈ 0.6^5 × 0.8 ≈ 0.0622
      expect(belief.confidence, lessThan(0.1));
      expect(belief.confidence, greaterThan(0.0));
    });

    test('observationScore above 1.0 is clamped — confidence stays in [0,1]',
        () {
      final now = DateTime.utc(2026, 5, 4, 12);
      const prev = BrokenMapBelief();

      final next = BrokenMapBeliefUpdater.update(prev, 1.5, now: now);

      expect(next.confidence, lessThanOrEqualTo(1.0));
      expect(next.confidence, greaterThanOrEqualTo(0.0));
      // Should equal α × 1.0 (clamped) = 0.4
      expect(next.confidence, closeTo(_alpha, 1e-9));
    });
  });
}
