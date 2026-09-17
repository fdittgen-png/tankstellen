// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel/behaviour_metric.dart';
import 'package:tankstellen/core/domain/fuel/fuel_context.dart';
import 'package:tankstellen/core/domain/fuel/fuel_grade.dart';
import 'package:tankstellen/core/domain/fuel/tank_blend_snapshot.dart';

import 'fuel_behaviour_fixtures.dart';

/// #4276 — the context a blend is learned under, the timeline that reads
/// it at a trip's instant, and the interval arithmetic behind every metric.
void main() {
  TankBlendSnapshot snap(Map<FuelGrade, double> shares) => TankBlendSnapshot(
        gradeShares: shares,
        minLitres: 0,
        maxLitres: null,
        tankCapacityLitres: null,
        appliedEventIds: const [],
        logFingerprint: 0,
      );

  group('FuelContext.classify', () {
    test('a guaranteed 85 % of one grade is that pure grade', () {
      expect(
          FuelContext.classify(
              snap({FuelGrade.e85: 0.85, FuelGrade.e10: 0.15})),
          FuelContext.pure(FuelGrade.e85));
    });

    test('below 85 % it is a mixed bucket keyed by both grades', () {
      final c = FuelContext.classify(
          snap({FuelGrade.e85: 0.6, FuelGrade.e10: 0.3, FuelGrade.unknown: 0.1}));
      expect(c.kind, FuelContextKind.mixed);
      expect(c, FuelContext.mixed([FuelGrade.e85, FuelGrade.e10]));
      expect(c.key, 'mixed:e10+e85');
    });

    test('an E5/E10 mix is not the E10/E85 bucket', () {
      expect(
          FuelContext.classify(snap({FuelGrade.e5: 0.5, FuelGrade.e10: 0.5})),
          isNot(FuelContext.mixed([FuelGrade.e10, FuelGrade.e85])));
    });

    test('more than 15 % unattributable is unknown', () {
      expect(
          FuelContext.classify(
              snap({FuelGrade.e10: 0.8, FuelGrade.unknown: 0.2})),
          FuelContext.unknown);
    });

    test('a trace grade does not create a mix', () {
      expect(
          FuelContext.classify(snap({
            FuelGrade.e10: 0.84,
            FuelGrade.e85: 0.005,
            FuelGrade.unknown: 0.155,
          })),
          FuelContext.unknown);
      expect(
          FuelContext.classify(snap({
            FuelGrade.e10: 0.84,
            FuelGrade.e85: 0.005,
            FuelGrade.unknown: 0.155 - 0.01,
            FuelGrade.e5: 0.01,
          })),
          FuelContext.mixed([FuelGrade.e10, FuelGrade.e5]));
    });
  });

  group('FuelContext.combine', () {
    final e10 = FuelContext.pure(FuelGrade.e10);
    final e85 = FuelContext.pure(FuelGrade.e85);

    test('one context throughout is that context', () {
      expect(FuelContext.combine([e85, e85]), e85);
    });

    test('two known contexts make a mixed window; any unknown is unknown', () {
      expect(FuelContext.combine([e85, e10]),
          FuelContext.mixed([FuelGrade.e10, FuelGrade.e85]));
      expect(FuelContext.combine([e85, FuelContext.unknown]),
          FuelContext.unknown);
      expect(FuelContext.combine([]), FuelContext.unknown);
    });
  });

  group('BlendTimeline', () {
    final timeline = referenceTimeline();

    test('before any fill the tank is unknown', () {
      expect(timeline.contextAt(day(-1)), FuelContext.unknown);
    });

    test('a trip reads the blend it started on', () {
      expect(timeline.contextAt(day(3)), FuelContext.pure(FuelGrade.e10));
      expect(timeline.contextAt(day(12)), FuelContext.pure(FuelGrade.e85));
      expect(timeline.contextAt(day(23)),
          FuelContext.mixed([FuelGrade.e10, FuelGrade.e85]));
    });

    test('an event at the trip instant is not yet in the tank', () {
      expect(timeline.contextAt(day(11)), FuelContext.pure(FuelGrade.e10));
    });

    test('a window includes its opening fill, excludes its closing fill', () {
      expect(timeline.contextOverWindow(day(5), day(11)),
          FuelContext.pure(FuelGrade.e10));
      expect(timeline.contextOverWindow(day(5), day(12)),
          FuelContext.mixed([FuelGrade.e10, FuelGrade.e85]),
          reason: 'the E85 fill at day 11 was burned inside this window');
    });
  });

  group('BehaviourMetric', () {
    test('weighted mean, Kish-effective SE and a t interval', () {
      final m = BehaviourMetric.weightedMean(
          [(6.0, 10.0), (8.0, 10.0)], MetricBasis.measuredTrips);
      expect(m.value, 7.0);
      // variance = (10·1 + 10·1)/20 · 2/1 = 2; nEff = 2; SE = 1.
      expect(m.standardError, closeTo(1.0, 1e-12));
      expect(m.lower, closeTo(7 - 12.706, 1e-9));
      expect(m.sampleCount, 2);
    });

    test('one sample has no spread and is insufficient', () {
      final m = BehaviourMetric.weightedMean(
          [(6.0, 10.0)], MetricBasis.measuredTrips);
      expect(m.isKnown, isFalse);
      expect(m.insufficientReason, InsufficientReason.tooFewSamples);
    });

    test('a reciprocal inverts the interval; one touching zero is refused', () {
      const m = BehaviourMetric.known(
          value: 5,
          standardError: 1,
          lower: 4,
          upper: 6,
          sampleCount: 5,
          basis: MetricBasis.measuredTrips);
      final r = m.reciprocal(5000);
      expect(r.value, 1000);
      expect(r.lower, closeTo(5000 / 6, 1e-9));
      expect(r.upper, 1250);
      const wide = BehaviourMetric.known(
          value: 5,
          standardError: 3,
          lower: -1,
          upper: 11,
          sampleCount: 5,
          basis: MetricBasis.measuredTrips);
      expect(wide.reciprocal(5000).insufficientReason,
          InsufficientReason.uncertaintyTooWide);
    });

    test('t95 falls back to 1.96 beyond 30 degrees of freedom', () {
      expect(BehaviourMetric.t95(1), 12.706);
      expect(BehaviourMetric.t95(30), 2.042);
      expect(BehaviourMetric.t95(31), 1.96);
    });
  });
}
