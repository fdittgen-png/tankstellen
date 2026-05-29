// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/num_extensions.dart';

void main() {
  group('NumIterableStats.average', () {
    test('computes the mean of multiple elements', () {
      expect([1.0, 2.0, 3.0].average, 2.0);
      expect([2.0, 4.0, 6.0, 8.0].average, 5.0);
    });

    test('returns the single element for a one-element iterable', () {
      expect([42.0].average, 42.0);
    });

    test('returns 0 for an empty iterable', () {
      expect(<num>[].average, 0.0);
      expect(<double>[].average, 0.0);
      expect(<int>[].average, 0.0);
    });

    test('works for ints and returns a double', () {
      expect([1, 2, 3, 4].average, 2.5);
      expect([10, 20].average, isA<double>());
      expect([10, 20].average, 15.0);
    });

    test('handles negative values', () {
      expect([-2.0, 2.0].average, 0.0);
      expect([-4, -2, 0].average, -2.0);
    });

    test('works on a lazy Iterable, not just a List', () {
      final lazy = Iterable<num>.generate(5, (i) => i); // 0,1,2,3,4
      expect(lazy.average, 2.0);
    });

    test('works on a mapped Iterable of doubles', () {
      final speeds = [10, 20, 30].map((v) => v.toDouble());
      expect(speeds.average, 20.0);
    });
  });
}
