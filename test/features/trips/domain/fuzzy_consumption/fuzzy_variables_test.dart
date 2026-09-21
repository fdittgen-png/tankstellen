// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/trips/domain/fuzzy_consumption/fuzzy_consumption_engine.dart';
import 'package:tankstellen/features/trips/domain/road_load_track.dart';
import 'package:tankstellen/features/trips/domain/vehicle_road_load_parameters.dart';
import 'package:tankstellen/features/vehicle/domain/fuzzy_classifier.dart';

/// Membership semantics per linguistic variable (#4232 acceptance: "rule /
/// membership semantics are documented and unit-tested").
void main() {
  /// A dense sweep across the variable's whole plausible domain.
  List<double> sweep(FuzzyVariable v) {
    const steps = 4000;
    final width = v.max - v.min;
    return [for (var i = 0; i <= steps; i++) v.min + width * i / steps];
  }

  for (final v in FuzzyVariable.values) {
    group(v.name, () {
      test('every membership is in [0, 1]', () {
        for (final x in sweep(v)) {
          for (final t in v.terms) {
            final mu = v.membership(t, x);
            expect(mu, inInclusiveRange(0, 1), reason: '${t.name} at $x');
          }
        }
      });

      test('the terms partition the domain: memberships sum to 1', () {
        for (final x in sweep(v)) {
          final sum =
              v.terms.fold<double>(0, (s, t) => s + v.membership(t, x));
          expect(sum, closeTo(1, 1e-9), reason: 'at $x');
        }
      });

      test('adjacent terms overlap somewhere', () {
        for (var i = 0; i + 1 < v.terms.length; i++) {
          final a = v.terms[i], b = v.terms[i + 1];
          final overlaps = sweep(v).any((x) =>
              v.membership(a, x) > 0 && v.membership(b, x) > 0);
          expect(overlaps, isTrue, reason: '${a.name} / ${b.name}');
        }
      });

      test('every term reaches (near-)full membership', () {
        // The sweep's step can miss a triangle's exact peak, hence 0.98.
        for (final t in v.terms) {
          final peak = sweep(v)
              .map((x) => v.membership(t, x))
              .reduce((a, b) => a > b ? a : b);
          expect(peak, greaterThan(0.98), reason: t.name);
        }
      });

      test('the edge terms are monotone toward the domain edges', () {
        // Curvature is symmetric in the sign of the yaw rate, so its edges
        // are monotone in the magnitude, i.e. over the non-negative half.
        final xs = v == FuzzyVariable.curvature
            ? sweep(v).where((x) => x >= 0).toList()
            : sweep(v);
        final first = v.terms.first, last = v.terms.last;
        for (var i = 1; i < xs.length; i++) {
          expect(v.membership(first, xs[i]),
              lessThanOrEqualTo(v.membership(first, xs[i - 1]) + 1e-12));
          expect(v.membership(last, xs[i]),
              greaterThanOrEqualTo(v.membership(last, xs[i - 1]) - 1e-12));
        }
      });

      test('a term the variable does not own has membership 0', () {
        final foreign =
            FuzzyTerm.values.where((t) => !v.terms.contains(t));
        for (final t in foreign) {
          expect(v.membership(t, (v.min + v.max) / 2), 0, reason: t.name);
        }
      });
    });
  }

  group('documented breakpoints', () {
    test('speed: standstill until 5 km/h, highway from 90 km/h', () {
      const v = FuzzyVariable.speed;
      expect(v.membership(FuzzyTerm.standstill, 0), 1);
      expect(v.membership(FuzzyTerm.standstill, 5), 0);
      expect(v.membership(FuzzyTerm.urban, 30), 1);
      expect(v.membership(FuzzyTerm.rural, 70), 1);
      expect(v.membership(FuzzyTerm.highway, 90), 1);
    });

    test('coolant: cold at 40 °C, warm at 70 °C', () {
      const v = FuzzyVariable.coolantTemp;
      expect(v.membership(FuzzyTerm.cold, 40), 1);
      expect(v.membership(FuzzyTerm.warm, 70), 1);
      expect(v.membership(FuzzyTerm.cold, 55), closeTo(0.5, 1e-12));
    });

    test('curvature uses the yaw-rate magnitude', () {
      const v = FuzzyVariable.curvature;
      expect(v.membership(FuzzyTerm.curving, 0.2),
          v.membership(FuzzyTerm.curving, -0.2));
      expect(v.membership(FuzzyTerm.curving, kFuzzyCurveYawRateRadPerS),
          closeTo(0.5, 1e-12),
          reason: '#4203 turning threshold sits at the crossover');
    });
  });

  group('restated constants stay in step with their owners', () {
    test('road-load thresholds (#4203)', () {
      expect(kFuzzyAccelSaturationMps2, kOscillationAccelMps2);
      expect(kFuzzyCurveYawRateRadPerS, kCurveYawRateRadPerS);
    });

    test('vehicle body-class bounds (#4209)', () {
      expect(kFuzzyCompactMaxKg, VehicleRoadLoadParameters.compactMaxKg);
      expect(kFuzzyMidsizeMaxKg, VehicleRoadLoadParameters.midsizeMaxKg);
    });

    test("FuzzyClassifier's decel / coast edges (#894, #2515)", () {
      const classifier = FuzzyClassifier();
      Map<Situation, double> at(double accel) => classifier.classify(
          speedKmh: 50, accel: accel, grade: 0, throttlePct: 0, rpm: 1000);
      // Just below the decel edge is decel; at it, the partial-decel band.
      expect(at(kFuzzyDecelEdgeMps2 - 0.01)[Situation.decel], greaterThan(0));
      expect(at(kFuzzyDecelEdgeMps2)[Situation.partialDecel], greaterThan(0));
      // The partial-decel band ends at −0.1: the coast edge.
      expect(at(-kFuzzyCoastEdgeMps2 - 0.01)[Situation.partialDecel],
          greaterThan(0));
      expect(at(-kFuzzyCoastEdgeMps2)[Situation.partialDecel], 0);
    });
  });

  group('input validation', () {
    test('missing, invalid, stale and fresh are told apart', () {
      FuzzyInputStatus c(FuzzyReading? r) =>
          classifyReading(r, min: 0, max: 100, staleAfterSeconds: 3);
      expect(c(null), FuzzyInputStatus.missing);
      expect(c(const FuzzyReading(double.nan)), FuzzyInputStatus.invalid);
      expect(c(const FuzzyReading(double.infinity)), FuzzyInputStatus.invalid);
      expect(c(const FuzzyReading(-1)), FuzzyInputStatus.invalid);
      expect(c(const FuzzyReading(101)), FuzzyInputStatus.invalid);
      expect(c(const FuzzyReading(5, ageSeconds: -1)),
          FuzzyInputStatus.invalid);
      expect(c(const FuzzyReading(5, ageSeconds: double.nan)),
          FuzzyInputStatus.invalid);
      expect(c(const FuzzyReading(5, ageSeconds: 3.5)),
          FuzzyInputStatus.stale);
      expect(c(const FuzzyReading(5, ageSeconds: 1)), FuzzyInputStatus.fresh);
    });

    test('freshness falls linearly to 0 at the horizon', () {
      expect(freshnessOf(const FuzzyReading(1), 3), 1);
      expect(freshnessOf(const FuzzyReading(1, ageSeconds: 1.5), 3),
          closeTo(0.5, 1e-12));
      expect(freshnessOf(const FuzzyReading(1, ageSeconds: 3), 3), 0);
      expect(
          freshnessOf(
              const FuzzyReading(1, ageSeconds: 1e9), double.infinity),
          1,
          reason: 'a static parameter never ages');
    });
  });
}
