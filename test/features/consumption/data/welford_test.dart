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
    });

    test('reset() clears every accumulator field', () {
      final w = WelfordAccumulator();
      w.update(42);
      w.reset();
      expect(w.n, 0);
      expect(w.mean, 0);
      expect(w.m2, 0);
    });
  });
}
