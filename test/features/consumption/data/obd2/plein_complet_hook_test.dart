import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/broken_map_belief.dart';
import 'package:tankstellen/features/consumption/data/obd2/broken_map_detector.dart';

/// Helper: pumped / consumed = ratio = reconciledLPer100km /
/// estimatedLPer100km. Build a `(reconciled, estimated)` pair from a
/// target ratio and a fixed-but-arbitrary L/100 km baseline.
({double reconciled, double estimated}) _pairForRatio(double ratio) {
  const double baseline = 6.0;
  return (reconciled: baseline * ratio, estimated: baseline);
}

void main() {
  // Deterministic time injected into every observation so the
  // posterior / lastUpdate assertions are reproducible.
  final fixedNow = DateTime(2026, 5, 4, 10, 30);

  group('recordPleinCompletObservation — combined-score math (#1424)', () {
    test(
        'high discrepancy + implausible eta → strong observation pushes '
        'posterior into the verifying band on a single fold', () async {
      // ratio 2.5 → discrepancyScore clamps to 1.0;
      // eta 1.30 → etaScore clamps to 1.0.
      // combined = 0.6 × 1 + 0.4 × 1 = 1.0.
      // α' = 0.5·1 + 8·1 = 8.5 ; β' = 0.5·9 + 0 = 4.5.
      final pair = _pairForRatio(2.5);

      final updated = const BrokenMapDetector().recordPleinCompletObservation(
        prior: const BrokenMapBelief(),
        reconciledLPer100km: pair.reconciled,
        estimatedLPer100km: pair.estimated,
        proposedEta: 1.30,
        now: fixedNow,
      );

      expect(updated.alpha, closeTo(8.5, 1e-9));
      expect(updated.beta, closeTo(4.5, 1e-9));
      expect(updated.pointEstimate, closeTo(8.5 / 13.0, 1e-9));
      expect(updated.observationCount, 1);
      expect(updated.lastUpdate, fixedNow);
      // Strong combined score (1.0 > 0.5) — trigger MUST land. eta
      // and discrepancy tied at 1.0 so the implementation prefers
      // discrepancy (eta is not strictly greater).
      expect(updated.lastTrigger, BrokenMapReason.pleinCompletDiscrepancy);
    });

    test(
        'eta dominates over weak discrepancy — combined score below '
        'strong threshold leaves trigger at default', () async {
      // ratio 1.4 → discrepancyScore = (1.4 - 1.3) / 0.9 ≈ 0.111.
      // eta 1.22 → etaScore = 1.0.
      // combined = 0.6 × 0.111 + 0.4 × 1.0 ≈ 0.467 — below strong (0.5).
      final pair = _pairForRatio(1.4);

      final updated = const BrokenMapDetector().recordPleinCompletObservation(
        prior: const BrokenMapBelief(),
        reconciledLPer100km: pair.reconciled,
        estimatedLPer100km: pair.estimated,
        proposedEta: 1.22,
        now: fixedNow,
      );

      // Beta fold: α' = 0.5 + 8·0.467 ≈ 4.233 ; β' = 4.5 + 0.533 ≈ 5.033.
      expect(updated.pointEstimate, greaterThan(0.4));
      expect(updated.pointEstimate, lessThan(0.55));
      expect(updated.observationCount, 1);
      // Not strong enough for trigger to flip — stays at default.
      expect(updated.lastTrigger, BrokenMapReason.none);
    });

    test(
        'eta strongly dominant → strong observation tags etaImplausible',
        () async {
      // ratio 1.6 → discrepancyScore = (1.6 - 1.3) / 0.9 = 0.333.
      // eta 1.22 → etaScore = 1.0. combined = 0.6 × 0.333 + 0.4 × 1.0 = 0.6.
      // Strong (>0.5). etaScore (1.0) > discrepancyScore (0.333).
      final pair = _pairForRatio(1.6);

      final updated = const BrokenMapDetector().recordPleinCompletObservation(
        prior: const BrokenMapBelief(),
        reconciledLPer100km: pair.reconciled,
        estimatedLPer100km: pair.estimated,
        proposedEta: 1.22,
        now: fixedNow,
      );

      // α' = 0.5 + 8·0.6 = 5.3 ; β' = 4.5 + 0.4 = 4.9 ;
      // mean = 5.3/10.2 ≈ 0.520.
      expect(updated.alpha, closeTo(5.3, 1e-9));
      expect(updated.beta, closeTo(4.9, 1e-9));
      expect(updated.lastTrigger, BrokenMapReason.etaImplausible);
    });
  });

  group('recordPleinCompletObservation — null proposedEta fallback', () {
    test(
        'null eta + high ratio → discrepancy-only weight, score == '
        'discrepancyScore (no NaN, no throw)', () async {
      // ratio 2.2 → discrepancyScore clamps to 1.0.
      // No eta → score == 1.0 (discrepancy-only weight).
      final pair = _pairForRatio(2.2);

      final updated = const BrokenMapDetector().recordPleinCompletObservation(
        prior: const BrokenMapBelief(),
        reconciledLPer100km: pair.reconciled,
        estimatedLPer100km: pair.estimated,
        proposedEta: null,
        now: fixedNow,
      );

      // α' = 0.5 + 8 = 8.5 ; β' = 4.5 + 0 = 4.5.
      expect(updated.alpha, closeTo(8.5, 1e-9));
      expect(updated.beta, closeTo(4.5, 1e-9));
      expect(updated.pointEstimate.isNaN, isFalse);
      expect(updated.observationCount, 1);
      expect(updated.lastTrigger, BrokenMapReason.pleinCompletDiscrepancy);
    });

    test('null eta + clean ratio → score 0, posterior decays toward 0',
        () {
      // ratio 1.1 → discrepancyScore clamps to 0 (below 1.3 boundary).
      final pair = _pairForRatio(1.1);

      final updated = const BrokenMapDetector().recordPleinCompletObservation(
        prior: const BrokenMapBelief(),
        reconciledLPer100km: pair.reconciled,
        estimatedLPer100km: pair.estimated,
        proposedEta: null,
        now: fixedNow,
      );

      // α' = 0.5·1 + 0 = 0.5 ; β' = 0.5·9 + 1 = 5.5 ; mean ≈ 0.083.
      expect(updated.alpha, closeTo(0.5, 1e-9));
      expect(updated.beta, closeTo(5.5, 1e-9));
      expect(updated.pointEstimate, lessThan(0.1));
      expect(updated.observationCount, 1);
      expect(updated.lastTrigger, BrokenMapReason.none);
    });
  });

  group('recordPleinCompletObservation — degenerate inputs', () {
    test('zero estimatedLPer100km returns prior unchanged', () {
      const prior = BrokenMapBelief(
        alpha: 3,
        beta: 7,
        observationCount: 5,
        lastTrigger: BrokenMapReason.idleVacuumMissing,
      );

      final updated = const BrokenMapDetector().recordPleinCompletObservation(
        prior: prior,
        reconciledLPer100km: 6.0,
        estimatedLPer100km: 0,
        proposedEta: null,
        now: fixedNow,
      );

      expect(updated, equals(prior));
    });

    test('zero reconciledLPer100km returns prior unchanged', () {
      const prior = BrokenMapBelief(
        alpha: 7, beta: 3, observationCount: 2,
      );

      final updated = const BrokenMapDetector().recordPleinCompletObservation(
        prior: prior,
        reconciledLPer100km: 0,
        estimatedLPer100km: 6.0,
        proposedEta: null,
        now: fixedNow,
      );

      expect(updated, equals(prior));
    });
  });

  group('recordPleinCompletObservation — Bayesian decay', () {
    test(
        'after a strong observation, a clean ratio decays the posterior '
        'toward the prior — posterior stays positive but shrinks',
        () {
      // First: strong observation.
      final highPair = _pairForRatio(2.5);
      final after1 = const BrokenMapDetector().recordPleinCompletObservation(
        prior: const BrokenMapBelief(),
        reconciledLPer100km: highPair.reconciled,
        estimatedLPer100km: highPair.estimated,
        proposedEta: 1.30,
        now: fixedNow,
      );
      expect(after1.alpha, closeTo(8.5, 1e-9));
      expect(after1.beta, closeTo(4.5, 1e-9));

      // Second: clean ratio + healthy eta → score = 0.
      // α' = 0.5·8.5 + 0 = 4.25 ; β' = 0.5·4.5 + 1 = 3.25.
      final cleanPair = _pairForRatio(1.0);
      final after2 = const BrokenMapDetector().recordPleinCompletObservation(
        prior: after1,
        reconciledLPer100km: cleanPair.reconciled,
        estimatedLPer100km: cleanPair.estimated,
        proposedEta: 0.85,
        now: fixedNow,
      );

      expect(after2.alpha, closeTo(4.25, 1e-9));
      expect(after2.beta, closeTo(3.25, 1e-9));
      expect(after2.observationCount, 2);
      // Strong trigger from observation 1 stays sticky — observation 2
      // was weak (score 0 < 0.5) so the updater leaves lastTrigger
      // alone.
      expect(after1.lastTrigger, BrokenMapReason.pleinCompletDiscrepancy);
      expect(after2.lastTrigger, BrokenMapReason.pleinCompletDiscrepancy);
    });
  });
}
