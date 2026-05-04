import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/welford.dart';

void main() {
  group('WelfordAccumulator (#769)', () {
    test('starts at zero', () {
      final w = WelfordAccumulator();
      expect(w.n, 0);
      expect(w.mean, 0);
      expect(w.m2, 0);
      expect(w.variance, 0);
    });

    test('single sample has zero variance, mean == sample', () {
      final w = WelfordAccumulator();
      w.update(7.5);
      expect(w.n, 1);
      expect(w.mean, closeTo(7.5, 1e-10));
      expect(w.variance, 0);
    });

    test('converges on the true mean and variance of a known set', () {
      // Dataset: [2, 4, 4, 4, 5, 5, 7, 9] — classic Wikipedia example.
      // Mean = 5. Sample variance (n-1) = 32/7 ≈ 4.57142857.
      final w = WelfordAccumulator();
      for (final v in const [2.0, 4.0, 4.0, 4.0, 5.0, 5.0, 7.0, 9.0]) {
        w.update(v);
      }
      expect(w.n, 8);
      expect(w.mean, closeTo(5.0, 1e-10));
      expect(w.variance, closeTo(32.0 / 7.0, 1e-10));
      expect(w.stddev, closeTo(math.sqrt(32.0 / 7.0), 1e-10));
    });

    test('survives a large range without catastrophic cancellation', () {
      // Classic numerical-stability edge case: samples clustered far
      // from zero with a tiny spread. A naive (sumSq / n - mean²)
      // implementation loses all precision here; Welford survives.
      final w = WelfordAccumulator();
      for (var i = 0; i < 1000; i++) {
        w.update(1e9 + i * 0.1);
      }
      // Sample variance (n-1 divisor) for [0, 0.1, …, 99.9]:
      //   var = sum((xi - mean)²) / 999 ≈ 834.16666…
      // Derived analytically from the uniform-spacing formula; not a
      // hand-wave. Tolerance is loose because the 1 × 10^9 offset
      // exercises double-precision catastrophic-cancellation edges.
      expect(w.variance, closeTo(834.16666666, 1.0));
    });

    test('toJson / fromJson round-trips without loss', () {
      final w = WelfordAccumulator();
      for (final v in const [1.0, 2.0, 3.0, 4.0, 5.0]) {
        w.update(v);
      }
      final restored = WelfordAccumulator.fromJson(w.toJson());
      expect(restored.n, w.n);
      expect(restored.mean, w.mean);
      expect(restored.m2, w.m2);
      expect(restored.sumWeight, w.sumWeight);
      expect(restored.sumWeightSq, w.sumWeightSq);
    });

    test('reset() clears every accumulator field', () {
      final w = WelfordAccumulator();
      w.update(42);
      w.reset();
      expect(w.n, 0);
      expect(w.mean, 0);
      expect(w.m2, 0);
      expect(w.sumWeight, 0);
      expect(w.sumWeightSq, 0);
    });
  });

  // #1426 — weighted update + effective-N + JSON migration. Wires the
  // #894 fuzzy classifier through to BaselineStore confidence math.
  group('WelfordAccumulator weighted (#1426)', () {
    test('unweighted updates keep effectiveSampleCount == n', () {
      final w = WelfordAccumulator();
      for (var i = 0; i < 10; i++) {
        w.update(i.toDouble());
      }
      expect(w.n, 10);
      expect(w.effectiveSampleCount, closeTo(10.0, 1e-10));
    });

    test('weighted mean matches the analytic weighted-mean formula', () {
      // Three samples: (10, w=1), (20, w=2), (30, w=1).
      // Weighted mean = (10·1 + 20·2 + 30·1) / 4 = 80/4 = 20.
      final w = WelfordAccumulator();
      w.updateWeighted(10.0, 1.0);
      w.updateWeighted(20.0, 2.0);
      w.updateWeighted(30.0, 1.0);
      expect(w.mean, closeTo(20.0, 1e-10));
      expect(w.sumWeight, closeTo(4.0, 1e-10));
    });

    test('Kish effective N: uniform weights give Σw² / Σw = w', () {
      // 10 samples × 0.5 weight: Σw = 5, Σw² = 2.5, effective N =
      // 25 / 2.5 = 10. Uniform weights leave effective N at the raw
      // count — the discriminating case is non-uniform weights.
      final w = WelfordAccumulator();
      for (var i = 0; i < 10; i++) {
        w.updateWeighted(i.toDouble(), 0.5);
      }
      expect(w.sumWeight, closeTo(5.0, 1e-10));
      expect(w.sumWeightSq, closeTo(2.5, 1e-10));
      expect(w.effectiveSampleCount, closeTo(10.0, 1e-10));
    });

    test('Kish effective N: non-uniform weights downweight low-weight '
        'contributions correctly', () {
      // 9 strong samples (w=1) + 1 weak (w=0.05). Σw = 9.05, Σw² =
      // 9.0025. Effective N ≈ 9.10. The weak sample buys ~0.10 of
      // additional confidence, not a full slot — exactly the
      // regression the analysis flagged in fuzzy mode.
      final w = WelfordAccumulator();
      for (var i = 0; i < 9; i++) {
        w.updateWeighted(i.toDouble(), 1.0);
      }
      w.updateWeighted(99.0, 0.05);
      expect(w.n, 10);
      expect(w.effectiveSampleCount, closeTo(9.10, 0.01));
    });

    test('zero-weight update is a no-op', () {
      final w = WelfordAccumulator();
      w.update(5.0);
      final beforeMean = w.mean;
      final beforeN = w.n;
      w.updateWeighted(999.0, 0.0);
      expect(w.mean, beforeMean);
      expect(w.n, beforeN);
      expect(w.sumWeight, closeTo(1.0, 1e-10));
      // Negative weight also rejected — defensive against fuzzy
      // membership functions that return slightly-negative numbers
      // through clamp drift.
      w.updateWeighted(999.0, -0.3);
      expect(w.mean, beforeMean);
    });

    test('legacy JSON without sumWeight back-fills to n', () {
      // Pre-#1426 baselines persisted only n / mean / m2. Decoded
      // via the new fromJson, sumWeight back-fills to n so the
      // confidence blend in BaselineStore.lookup() produces the
      // SAME value as the legacy n-based blend would have. This is
      // the migration path — no on-disk format change required.
      final json = <String, dynamic>{
        'n': 12,
        'mean': 6.5,
        'm2': 4.2,
        // sumWeight, sumWeightSq absent (legacy payload shape).
      };
      final w = WelfordAccumulator.fromJson(json);
      expect(w.n, 12);
      expect(w.mean, closeTo(6.5, 1e-10));
      expect(w.m2, closeTo(4.2, 1e-10));
      expect(w.sumWeight, closeTo(12.0, 1e-10));
      expect(w.sumWeightSq, closeTo(12.0, 1e-10));
      expect(w.effectiveSampleCount, closeTo(12.0, 1e-10));
    });

    test('weighted Welford with w=1 reproduces unweighted Wikipedia '
        'dataset exactly', () {
      // Regression guard: passing weight=1 must equal the classic
      // Welford output bit-for-bit (up to fp tolerance).
      final w = WelfordAccumulator();
      for (final v in const [2.0, 4.0, 4.0, 4.0, 5.0, 5.0, 7.0, 9.0]) {
        w.updateWeighted(v, 1.0);
      }
      expect(w.mean, closeTo(5.0, 1e-10));
      expect(w.variance, closeTo(32.0 / 7.0, 1e-10));
    });
  });
}
