// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/consumption_estimate.dart';
import 'package:tankstellen/core/domain/fuel/behaviour_metric.dart';
import 'package:tankstellen/core/domain/fuel/fuel_behaviour_analyzer.dart';
import 'package:tankstellen/core/domain/fuel/fuel_behaviour_profile.dart';
import 'package:tankstellen/core/domain/fuel/fuel_grade.dart';
import 'package:tankstellen/core/domain/fuel/next_fill_decision.dart';
import 'package:tankstellen/core/domain/fuel/tank_blend_snapshot.dart';
import 'package:tankstellen/features/fill_ups/domain/services/fuel_and_tank_view.dart';

import '../../../../core/domain/fuel/fuel_behaviour_fixtures.dart';

/// #4278 — the view model the Fuel & Tank widgets only format. Pins the
/// rounding that must never overstate a guaranteed minimum, the provenance
/// resolution, and which rows and comparisons exist.
void main() {
  TankBlendSnapshot snapshot(Map<FuelGrade, double> shares,
          {double min = 20, double? max = 30}) =>
      TankBlendSnapshot(
        gradeShares: shares,
        minLitres: min,
        maxLitres: max,
        tankCapacityLitres: 50,
        appliedEventIds: const [],
        logFingerprint: 0,
      );

  group('TankMixView', () {
    test('partial evidence floors the minimums; the rest is unknown', () {
      final mix = TankMixView.of(snapshot(
          {FuelGrade.e85: 0.627, FuelGrade.e10: 0.309, FuelGrade.unknown: 0.064}));
      expect(mix.isExact, isFalse);
      expect(mix.shares,
          const [MixShareView(FuelGrade.e85, 62), MixShareView(FuelGrade.e10, 30)]);
      expect(mix.unknownPercent, 8);
      expect(mix.isUnknown, isFalse);
    });

    test('exact shares still sum to 100 (largest remainder)', () {
      final mix = TankMixView.of(snapshot(
          {FuelGrade.e85: 0.625, FuelGrade.e10: 0.375},
          min: 32,
          max: 32));
      expect(mix.isExact, isTrue);
      expect(mix.shares.fold(0, (a, s) => a + s.percent), 100);
      expect(mix.unknownPercent, 0);
      expect(mix.exactLitres, 32);
    });

    test('a fully unattributed tank is the unknown state', () {
      final mix = TankMixView.of(
          snapshot({FuelGrade.unknown: 1}, min: 0, max: 50));
      expect(mix.isUnknown, isTrue);
      expect(mix.leading, isNull);
      expect(mix.unknownPercent, 100);
    });
  });

  test('GradeFactView reads the standards bounds of the blend model', () {
    final e10 = GradeFactView.of(FuelGrade.e10);
    expect((e10.petrolPercent, e10.openPercent), (90, 10));
    final e85 = GradeFactView.of(FuelGrade.e85);
    expect((e85.ethanolPercent, e85.openPercent), (50, 50));
    expect(GradeFactView.of(FuelGrade.diesel).dieselPercent, 93);
  });

  group('MetricView', () {
    test('a derived figure is credited to the consumption it came from', () {
      const root = BehaviourMetric.known(
          value: 6,
          standardError: 0.1,
          lower: 5.8,
          upper: 6.2,
          sampleCount: 4,
          basis: MetricBasis.measuredTrips);
      final range = MetricView.of(root.reciprocal(5000), root: root);
      expect(range.basis, MetricBasis.measuredTrips);
      expect(range.provenance, ProvenanceKind.measured);
      expect(range.confidence, DecisionConfidence.medium);
    });

    test('an insufficient figure has no provenance and no confidence', () {
      final m = MetricView.of(
          const BehaviourMetric.insufficient(InsufficientReason.tooFewSamples));
      expect(m.provenance, isNull);
      expect(m.confidence, isNull);
      expect(m.interval, isNull);
    });
  });

  group('behaviourViewsOf', () {
    FuelBehaviourProfile profile({bool estimated = false}) =>
        FuelBehaviourAnalyzer.analyze(
          timeline: referenceTimeline(),
          trips: [
            ...tripsOn('e10-', 0.5, 10,
                factor: 1.0,
                withExpected: !estimated,
                source: estimated
                    ? ConsumptionSourceClass.estimated
                    : ConsumptionSourceClass.measured),
            if (!estimated) ...tripsOn('e85-', 11.5, 10, factor: 1.3),
          ],
          windows: const [],
          tankCapacityLitres: kCapacity,
        );

    test('approved but unlearned grades get an honest empty row', () {
      final v = behaviourViewsOf(profile(),
          approvedGrades: [FuelGrade.e5, FuelGrade.e10, FuelGrade.e85],
          configuredGrade: FuelGrade.e85);
      final e5 = v.rows.firstWhere((r) => r.context.pureGrade == FuelGrade.e5);
      expect(e5.hasAnyFigure, isFalse);
      expect(e5.evidenceCount, 0);
      expect(
          v.rows.where((r) => r.hasAnyFigure).map((r) => r.context.key),
          containsAll(['pure:e10', 'pure:e85']));
    });

    test('E10 is compared against the configured E85, controlled', () {
      final v = behaviourViewsOf(profile(),
          approvedGrades: [FuelGrade.e10, FuelGrade.e85],
          configuredGrade: FuelGrade.e85);
      final c = v.comparisons.single;
      expect((c.a, c.b), (FuelGrade.e10, FuelGrade.e85));
      // 1.0 / 1.3 − 1 = −23 %.
      expect(c.percentDifference, -23);
      expect(c.isMaterial, isTrue);
    });

    test('estimated, unexpected trips are labelled estimated, uncontrolled',
        () {
      final v = behaviourViewsOf(profile(estimated: true),
          approvedGrades: [FuelGrade.e10], configuredGrade: FuelGrade.e10);
      final row = v.rows.single;
      expect(row.lPer100Km.provenance, ProvenanceKind.estimated);
      expect(row.confounderControl, ConfounderControl.uncontrolled);
      expect(v.comparisons, isEmpty);
    });
  });
}
