// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/consumption_estimate.dart';
import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/core/domain/fuel/behaviour_metric.dart';
import 'package:tankstellen/core/domain/fuel/blend_timeline.dart';
import 'package:tankstellen/core/domain/fuel/fuel_behaviour_analyzer.dart';
import 'package:tankstellen/core/domain/fuel/fuel_behaviour_evidence.dart';
import 'package:tankstellen/core/domain/fuel/fuel_context.dart';
import 'package:tankstellen/core/domain/fuel/fuel_grade.dart';
import 'package:tankstellen/core/domain/fuel/tank_blend_engine.dart';
import 'package:tankstellen/core/domain/fuel/tank_blend_event.dart';
import 'package:tankstellen/core/domain/money_tally.dart';

/// #4364 acceptance box 9 — an "adjusted vehicle efficiency" claim
/// asserts the confounders were controlled. Production evaluates cold
/// starts alone and stamps no blend-independent expectation, so the
/// claim is withheld while the qualified OBSERVATION survives.
void main() {
  final t0 = DateTime.utc(2026, 3, 1, 8);
  DateTime at(int hours) => t0.add(Duration(hours: hours));
  final e10 = FuelContext.pure(FuelGrade.e10);

  /// A timeline that holds a pure E10 tank for the whole period.
  BlendTimeline timeline() => BlendTimeline.fold(
        TankBlendEngine(tankCapacityLitres: 50),
        [
          TankFillEvent(
            id: 'seed',
            at: t0.subtract(const Duration(days: 1)),
            grade: FuelGrade.e10,
            litres: 50,
            fillsTank: true,
          ),
        ],
      );

  TripFuelEvidence evidence(
    int i, {
    required double observed,
    double? expected,
    Set<DrivingCondition> observedConditions = const {...DrivingCondition.values},
  }) =>
      TripFuelEvidence(
        id: 't$i',
        at: at(i * 2),
        distanceKm: 40,
        litresPer100Km: DataValue.measured(observed),
        sourceClass: ConsumptionSourceClass.measured,
        expectedLPer100Km: expected,
        observedConditions: observedConditions,
      );

  test('full context + expected figures still produce the adjusted claim', () {
    final profile = FuelBehaviourAnalyzer.analyze(
      timeline: timeline(),
      trips: [
        for (var i = 1; i <= 6; i++)
          evidence(i, observed: 6 + i * 0.1, expected: 6.0),
      ],
      windows: const [],
    );

    final behaviour = profile.behaviourOf(e10)!;
    expect(behaviour.conditionCoverage, 1);
    expect(behaviour.residualRatio.isKnown, isTrue);
    expect(behaviour.conditionAdjustedLPer100Km.isKnown, isTrue);
  });

  test('production condition coverage suppresses the adjusted claim', () {
    // The same evidence, but the producer only ever evaluated cold
    // starts — exactly what `tripFuelEvidenceFor` states today.
    final profile = FuelBehaviourAnalyzer.analyze(
      timeline: timeline(),
      trips: [
        for (var i = 1; i <= 6; i++)
          evidence(i,
              observed: 6 + i * 0.1,
              expected: 6.0,
              observedConditions: const {DrivingCondition.coldStart}),
      ],
      windows: const [],
    );

    final behaviour = profile.behaviourOf(e10)!;
    expect(behaviour.conditionCoverage, 0);
    expect(behaviour.conditionAdjustedLPer100Km.isKnown, isFalse);
    expect(behaviour.conditionAdjustedLPer100Km.insufficientReason,
        InsufficientReason.incompleteConditionCoverage);
    // The qualified observation is preserved — that is the point.
    expect(behaviour.lPer100Km.isKnown, isTrue);
    expect(behaviour.lPer100Km.basis, MetricBasis.measuredTrips);
  });

  test('missing expected-consumption inputs suppress it too', () {
    final profile = FuelBehaviourAnalyzer.analyze(
      timeline: timeline(),
      trips: [for (var i = 1; i <= 6; i++) evidence(i, observed: 6 + i * 0.1)],
      windows: const [],
    );

    final behaviour = profile.behaviourOf(e10)!;
    expect(behaviour.residualRatio.isKnown, isFalse);
    expect(behaviour.conditionAdjustedLPer100Km.isKnown, isFalse);
    expect(behaviour.lPer100Km.isKnown, isTrue);
  });

  test('partial expected coverage is not enough for an adjustment', () {
    // Five trips carry an expectation (clearing the sample/distance bar)
    // and twenty do not — the residual speaks for a fifth of the driving.
    final profile = FuelBehaviourAnalyzer.analyze(
      timeline: timeline(),
      trips: [
        for (var i = 1; i <= 5; i++) evidence(i, observed: 6.2, expected: 6.0),
        for (var i = 6; i <= 25; i++) evidence(i, observed: 6.2),
      ],
      windows: const [],
    );

    final behaviour = profile.behaviourOf(e10)!;
    expect(behaviour.residualCoverage, lessThan(kMinResidualCoverage));
    expect(behaviour.conditionAdjustedLPer100Km.insufficientReason,
        InsufficientReason.incompleteConditionCoverage);
  });

  test('measured and estimated evidence are counted apart, never pooled', () {
    // #4364 box 8 — a model estimate and a sensor reading are both
    // useful and are not one population.
    final profile = FuelBehaviourAnalyzer.analyze(
      timeline: timeline(),
      trips: [
        for (var i = 1; i <= 3; i++) evidence(i, observed: 6.0),
        for (var i = 4; i <= 8; i++)
          TripFuelEvidence(
            id: 'e$i',
            at: at(i * 2),
            distanceKm: 40,
            litresPer100Km:
                const DataValue.estimated(7.0, basis: DataBasis.derived),
            sourceClass: ConsumptionSourceClass.estimated,
          ),
      ],
      windows: const [],
    );

    final behaviour = profile.behaviourOf(e10)!;
    expect(behaviour.provenance[EvidenceTier.measured], 3);
    expect(behaviour.provenance[EvidenceTier.estimated], 5);
  });

  test('evidence whose blend is unknown is counted, never learned from', () {
    // An empty timeline knows no blend: the drives are real, the context
    // is not, so they stay visible as unattributed instead of silently
    // joining a bucket.
    final profile = FuelBehaviourAnalyzer.analyze(
      timeline: BlendTimeline.fold(
          TankBlendEngine(tankCapacityLitres: 50), const []),
      trips: [for (var i = 1; i <= 6; i++) evidence(i, observed: 6.0)],
      windows: const [],
    );

    expect(profile.contexts, isEmpty);
    expect(profile.unattributed[EvidenceTier.measured], 6);
  });

  group('window money never crosses a currency', () {
    FillWindowEvidence window(int i, {double? cost, String? currency}) =>
        FillWindowEvidence(
          id: 'w$i',
          openedAt: at(i * 24),
          closedAt: at(i * 24 + 12),
          litres: 40,
          distanceKm: 500,
          pumpedCost: cost,
          costCurrency: currency,
        );

    test('two denominations withhold cost/km and say which reason', () {
      final profile = FuelBehaviourAnalyzer.analyze(
        timeline: timeline(),
        trips: const [],
        windows: [
          window(1, cost: 60, currency: 'EUR'),
          window(2, cost: 450, currency: 'DKK'),
        ],
      );

      final behaviour = profile.behaviourOf(e10)!;
      expect(behaviour.costPerKm.isKnown, isFalse);
      expect(behaviour.costPerKm.insufficientReason,
          InsufficientReason.mixedCurrencies);
      expect(behaviour.costCurrency, isNull);
      // The consumption observation survives the withheld money.
      expect(behaviour.lPer100Km.isKnown, isTrue);
    });

    test('one denomination keeps the figure and names it', () {
      final profile = FuelBehaviourAnalyzer.analyze(
        timeline: timeline(),
        trips: const [],
        windows: [
          window(1, cost: 60, currency: 'EUR'),
          window(2, cost: 70, currency: 'EUR'),
        ],
      );

      final behaviour = profile.behaviourOf(e10)!;
      expect(behaviour.costPerKm.isKnown, isTrue);
      expect(behaviour.costCurrency, 'EUR');
    });

    test('an all-unknown-currency history keeps its figure, unnamed', () {
      final profile = FuelBehaviourAnalyzer.analyze(
        timeline: timeline(),
        trips: const [],
        windows: [
          window(1, cost: 60, currency: kUnknownCurrency),
          window(2, cost: 70, currency: kUnknownCurrency),
        ],
      );

      expect(profile.behaviourOf(e10)!.costCurrency, kUnknownCurrency);
    });
  });
}
