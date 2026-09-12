// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/stats.dart';

/// #4073 — the one stats module. The five private copies it replaced had
/// diverged: two percentile formulas, two empty-list behaviours. Each
/// function's contract is pinned here so the divergence cannot return.
void main() {
  group('median', () {
    test('odd count → the middle value', () => expect(median([3, 1, 2]), 2));
    test('even count → mean of the two middle values',
        () => expect(median([4, 1, 3, 2]), 2.5));
    test('does not mutate its input', () {
      final xs = [3.0, 1.0, 2.0];
      median(xs);
      expect(xs, [3.0, 1.0, 2.0]);
    });
    test('medianOrNull is null for an empty list',
        () => expect(medianOrNull(const []), isNull));
  });

  group('percentileNearestRank', () {
    test('picks the element at round((n-1)·p) of the sorted copy', () {
      expect(percentileNearestRank([10, 20, 30, 40, 50], 0.5), 30);
      expect(percentileNearestRank([50, 10, 30, 20, 40], 0.0), 10);
      expect(percentileNearestRank([50, 10, 30, 20, 40], 1.0), 50);
    });
  });

  group('percentileInterpolated', () {
    test('interpolates between neighbours (type 7)', () {
      expect(percentileInterpolated([10, 20, 30, 40], 0.5), 25);
      expect(percentileInterpolated([10, 20, 30, 40], 0.25), 17.5);
    });
    test('clamps q to the ends and handles tiny lists', () {
      expect(percentileInterpolated([10, 20], -1), 10);
      expect(percentileInterpolated([10, 20], 2), 20);
      expect(percentileInterpolated([7], 0.3), 7);
      expect(percentileInterpolated(const [], 0.3), 0.0);
    });
  });
}
