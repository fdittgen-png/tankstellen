// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuzzy_membership.dart';

/// The shared membership primitives (#4232) — extracted from
/// `FuzzyClassifier`, so they must keep its exact shapes.
void main() {
  group('trapezoid', () {
    test('0 outside, 1 on the plateau, linear on the shoulders', () {
      double t(double x) => FuzzyMembership.trapezoid(x, 5, 25, 45, 60);
      expect(t(5), 0);
      expect(t(60), 0);
      expect(t(-1), 0);
      expect(t(100), 0);
      expect(t(25), 1);
      expect(t(45), 1);
      expect(t(15), closeTo(0.5, 1e-12));
      expect(t(52.5), closeTo(0.5, 1e-12));
    });

    test('b == c is a triangle peaking at 1', () {
      expect(FuzzyMembership.trapezoid(70, 45, 70, 70, 90), 1);
      expect(FuzzyMembership.trapezoid(80, 45, 70, 70, 90), closeTo(0.5, 1e-12));
    });
  });

  group('ramps', () {
    test('rampDown is 1 at/below lo, 0 at/above hi', () {
      expect(FuzzyMembership.rampDown(40, 40, 70), 1);
      expect(FuzzyMembership.rampDown(-10, 40, 70), 1);
      expect(FuzzyMembership.rampDown(70, 40, 70), 0);
      expect(FuzzyMembership.rampDown(55, 40, 70), closeTo(0.5, 1e-12));
    });

    test('rampUp is 0 at/below lo, 1 at/above hi', () {
      expect(FuzzyMembership.rampUp(0, 0, 8), 0);
      expect(FuzzyMembership.rampUp(8, 0, 8), 1);
      expect(FuzzyMembership.rampUp(20, 0, 8), 1);
      expect(FuzzyMembership.rampUp(4, 0, 8), closeTo(0.5, 1e-12));
    });

    test('rampUp and rampDown over the same bounds sum to 1', () {
      for (var x = -10.0; x <= 90; x += 0.25) {
        expect(
          FuzzyMembership.rampUp(x, 40, 70) +
              FuzzyMembership.rampDown(x, 40, 70),
          closeTo(1, 1e-12),
        );
      }
    });
  });
}
