// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3878 — rendering downsampling invariants: LTTB keeps the endpoints and
// the extremes, never exceeds the budget, and is the identity below it;
// Douglas–Peucker keeps endpoints and every vertex beyond the tolerance.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/trips/domain/services/series_downsampling.dart';

void main() {
  group('lttbIndices', () {
    test('identity when n ≤ threshold', () {
      expect(lttbIndices(length: 5, x: (i) => i.toDouble(), y: (i) => 0, threshold: 10),
          [0, 1, 2, 3, 4]);
    });

    test('keeps first/last, respects the budget, ascending, keeps the peak',
        () {
      const n = 10000;
      final ys = List<double>.generate(n, (i) => math.sin(i / 50));
      ys[4321] = 50; // an outlier peak the chart must show
      final idx = lttbIndices(
          length: n, x: (i) => i.toDouble(), y: (i) => ys[i], threshold: 500);
      expect(idx.length, 500);
      expect(idx.first, 0);
      expect(idx.last, n - 1);
      for (var i = 1; i < idx.length; i++) {
        expect(idx[i], greaterThan(idx[i - 1]));
      }
      expect(idx, contains(4321), reason: 'the peak survives downsampling');
    });
  });

  group('douglasPeuckerIndices', () {
    test('a straight line collapses to its endpoints', () {
      const n = 1000;
      final idx = douglasPeuckerIndices(
          length: n,
          lat: (i) => 48.0 + i * 1e-5,
          lng: (i) => 2.0 + i * 1e-5,
          toleranceM: 4);
      expect(idx, [0, n - 1]);
    });

    test('a corner beyond the tolerance is kept', () {
      // 0..99 heading east, 100..199 heading north: one true vertex at 100.
      final idx = douglasPeuckerIndices(
        length: 200,
        lat: (i) => i < 100 ? 48.0 : 48.0 + (i - 100) * 1e-4,
        lng: (i) => i < 100 ? 2.0 + i * 1e-4 : 2.0 + 99 * 1e-4,
        toleranceM: 4,
      );
      expect(idx.first, 0);
      expect(idx.last, 199);
      expect(idx, contains(anyOf(99, 100)));
      expect(idx.length, lessThan(6));
    });

    test('pickIndices aligns parallel lists', () {
      expect(pickIndices(['a', 'b', 'c', 'd'], [0, 2]), ['a', 'c']);
    });
  });
}
