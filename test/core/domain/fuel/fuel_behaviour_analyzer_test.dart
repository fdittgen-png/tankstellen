// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/consumption_estimate.dart';
import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/core/domain/fuel/behaviour_metric.dart';
import 'package:tankstellen/core/domain/fuel/fuel_behaviour_analyzer.dart';
import 'package:tankstellen/core/domain/fuel/fuel_behaviour_evidence.dart';
import 'package:tankstellen/core/domain/fuel/fuel_behaviour_profile.dart';
import 'package:tankstellen/core/domain/fuel/fuel_context.dart';
import 'package:tankstellen/core/domain/fuel/fuel_grade.dart';

import 'fuel_behaviour_fixtures.dart';

/// #4276 — domain logic of the behaviour profile over SYNTHETIC fixtures.
///
/// Not accuracy validation (there is no real corpus, #4231): each figure
/// is built as expected × a chosen fuel factor, so these tests pin that the
/// analyzer attributes, isolates and compares correctly — not that any
/// real car burns 30 % more on E85.
void main() {
  final e10 = FuelContext.pure(FuelGrade.e10);
  final e85 = FuelContext.pure(FuelGrade.e85);
  final mixed = FuelContext.mixed([FuelGrade.e10, FuelGrade.e85]);

  FuelBehaviourProfile analyze(
    List<TripFuelEvidence> trips, {
    List<FillWindowEvidence> windows = const [],
    double? capacity,
    Co2eFactorLookup factors = noCo2eFactor,
  }) =>
      FuelBehaviourAnalyzer.analyze(
        timeline: referenceTimeline(),
        trips: trips,
        windows: windows,
        tankCapacityLitres: capacity,
        co2eFactors: factors,
      );

  group('same vehicle on E10 vs E85', () {
    final profile = analyze([
      ...tripsOn('e10-', 0.5, 10, factor: 1.0),
      ...tripsOn('e85-', 11.5, 10, factor: 1.3),
    ]);

    test('each grade is its own context with its own residual', () {
      expect(profile.contexts.keys, [e10, e85]);
      expect(profile.behaviourOf(e10)!.residualRatio.value,
          closeTo(1.0, 0.01));
      expect(profile.behaviourOf(e85)!.residualRatio.value,
          closeTo(1.3, 0.01));
      expect(profile.behaviourOf(e85)!.residualRatio.basis,
          MetricBasis.measuredResiduals);
    });

    test('E85 vs E10 is compared on residuals and is material', () {
      final c = profile.compare(e85, e10);
      expect(c.basis, ComparisonBasis.residuals);
      expect(c.ratio.value, closeTo(1.3, 0.01));
      expect(c.isMaterial, isTrue);
    });

    test('every metric carries value, interval, count and provenance', () {
      final b = profile.behaviourOf(e85)!;
      expect(b.lPer100Km.value, closeTo(7.8, 0.05));
      expect(b.lPer100Km.lower, lessThan(b.lPer100Km.value!));
      expect(b.lPer100Km.upper, greaterThan(b.lPer100Km.value!));
      expect(b.lPer100Km.sampleCount, 10);
      expect(b.provenance, {EvidenceTier.measured: 10});
      expect(b.residualCoverage, 1.0);
      expect(b.confounderControl, ConfounderControl.residuals);
    });
  });

  test('a mixed blend is its own bucket, isolated from both pure grades', () {
    final profile = analyze([
      ...tripsOn('e10-', 0.5, 10, factor: 1.0),
      ...tripsOn('e85-', 11.5, 10, factor: 1.3),
      ...tripsOn('mix-', 22.5, 10, factor: 1.15),
    ]);
    expect(profile.contexts.keys, containsAll([e10, e85, mixed]));
    expect(profile.behaviourOf(mixed)!.residualRatio.value,
        closeTo(1.15, 0.01));
    expect(profile.behaviourOf(e85)!.residualRatio.value, closeTo(1.3, 0.01));
    expect(mixed.key, 'mixed:e10+e85');
  });

  group('confounders: hills, cold starts and traffic are not the fuel', () {
    const hard = {
      DrivingCondition.hilly,
      DrivingCondition.coldStart,
      DrivingCondition.stopAndGo,
    };

    test('hill-heavy E85 does not look worse once residuals are used', () {
      final profile = analyze([
        ...tripsOn('e10-', 0.5, 10, factor: 1.0),
        ...tripsOn('e85-', 11.5, 10,
            factor: 1.3, conditions: {DrivingCondition.hilly}),
      ]);
      final raw = profile.behaviourOf(e85)!.lPer100Km
          .over(profile.behaviourOf(e10)!.lPer100Km);
      expect(raw.value, closeTo(1.73, 0.02), reason: 'raw L/100 km blames E85');
      expect(profile.compare(e85, e10).ratio.value, closeTo(1.3, 0.01));
      expect(profile.behaviourOf(e85)!.conditionShares,
          {DrivingCondition.hilly: 1.0});
    });

    test('no fuel effect + hard conditions → no material difference', () {
      final profile = analyze([
        ...tripsOn('e10-', 0.5, 10, factor: 1.0),
        ...tripsOn('e85-', 11.5, 10, factor: 1.0, conditions: hard),
      ]);
      final raw = profile.behaviourOf(e85)!.lPer100Km
          .over(profile.behaviourOf(e10)!.lPer100Km);
      expect(raw.value, greaterThan(1.7));
      final c = profile.compare(e85, e10);
      expect(c.ratio.value, closeTo(1.0, 0.01));
      expect(c.isMaterial, isFalse);
    });

    test('adjusted L/100 km expresses both grades under the same roads', () {
      final profile = analyze([
        ...tripsOn('e10-', 0.5, 10, factor: 1.0),
        ...tripsOn('e85-', 11.5, 10, factor: 1.3, conditions: hard),
      ]);
      final typical = profile.typicalExpectedLPer100Km.value!;
      expect(profile.behaviourOf(e10)!.conditionAdjustedLPer100Km.value,
          closeTo(typical, 0.1));
      expect(profile.behaviourOf(e85)!.conditionAdjustedLPer100Km.value,
          closeTo(typical * 1.3, 0.15));
    });

    test('without expected figures the comparison says it is uncontrolled',
        () {
      final profile = analyze([
        ...tripsOn('e10-', 0.5, 10, factor: 1.0, withExpected: false),
        ...tripsOn('e85-', 11.5, 10,
            factor: 1.3, conditions: hard, withExpected: false),
      ]);
      final c = profile.compare(e85, e10);
      expect(c.basis, ComparisonBasis.uncontrolled);
      expect(profile.behaviourOf(e85)!.confounderControl,
          ConfounderControl.uncontrolled);
      expect(profile.behaviourOf(e85)!.residualRatio.insufficientReason,
          InsufficientReason.noEvidence);
    });
  });

  group('insufficient evidence is never a number', () {
    test('four trips are too few', () {
      final b = analyze(tripsOn('e10-', 0.5, 4, factor: 1.0)).behaviourOf(e10)!;
      expect(b.lPer100Km.value, isNull);
      expect(b.lPer100Km.insufficientReason, InsufficientReason.tooFewSamples);
      expect(b.residualRatio.value, isNull);
      expect(b.confounderControl, ConfounderControl.none);
    });

    test('five short trips are too little distance', () {
      final b = analyze(tripsOn('e10-', 0.5, 5, factor: 1.0, km: 5))
          .behaviourOf(e10)!;
      expect(b.lPer100Km.insufficientReason,
          InsufficientReason.tooLittleDistance);
    });

    test('one fill window is not enough; two are', () {
      final one = analyze([], windows: [window('w1', 0, 5, lPer100Km: 6)]);
      expect(one.behaviourOf(e10)!.lPer100Km.insufficientReason,
          InsufficientReason.tooFewSamples);
      final two = analyze([], windows: [
        window('w1', 0, 5, lPer100Km: 6),
        window('w2', 5, 10, lPer100Km: 6.4),
      ]);
      final b = two.behaviourOf(e10)!;
      expect(b.lPer100Km.value, closeTo(6.2, 1e-9));
      expect(b.lPer100Km.basis, MetricBasis.referenceWindows);
      expect(b.costPerKm.value, closeTo(0.093, 1e-9));
      expect(b.costPer100Km.value, closeTo(9.3, 1e-9));
      expect(b.confounderControl, ConfounderControl.uncontrolled,
          reason: 'windows only — lower-confidence evidence, stated');
    });

    test('evidence before any fill is unattributed, never learned', () {
      final profile = analyze([
        trip('early', -1, observed: 6, expected: 6),
      ]);
      expect(profile.contexts, isEmpty);
      expect(profile.unattributed, {EvidenceTier.measured: 1});
    });

    test('no capacity → no range; no factor → no CO2e', () {
      final b = analyze(tripsOn('e85-', 11.5, 10, factor: 1.3))
          .behaviourOf(e85)!;
      expect(b.rangeKm.insufficientReason, InsufficientReason.capacityUnknown);
      expect(b.co2eKgPerKm.insufficientReason, InsufficientReason.noCo2eFactor);
      expect(b.co2eFactor, isNull);
    });

    test('capacity and a versioned factor give range and CO2e', () {
      final factor = Co2eFactor(
          kgCo2ePerLitre: 1.4,
          source: 'test',
          version: 't1',
          boundary: Co2eBoundary.wellToWheel);
      final profile = analyze(tripsOn('e85-', 11.5, 10, factor: 1.3),
          capacity: kCapacity,
          factors: (g) => g == FuelGrade.e85 ? factor : null);
      final b = profile.behaviourOf(e85)!;
      final l = b.lPer100Km.value!;
      expect(b.rangeKm.value, closeTo(kCapacity * 100 / l, 1e-9));
      expect(b.co2eKgPerKm.value, closeTo(l / 100 * 1.4, 1e-12));
      expect(b.co2eFactor, same(factor));
    });

    test('a mixed context never gets a CO2e factor', () {
      final b = analyze(tripsOn('mix-', 22.5, 10, factor: 1.15),
              factors: (_) => Co2eFactor(
                  kgCo2ePerLitre: 2,
                  source: 's',
                  version: 'v',
                  boundary: Co2eBoundary.wellToWheel))
          .behaviourOf(mixed)!;
      expect(b.co2eKgPerKm.insufficientReason,
          InsufficientReason.contextNotPure);
    });
  });

  group('evidence hierarchy', () {
    test('reference windows outrank trips for absolute L/100 km', () {
      final b = analyze(tripsOn('e10-', 0.5, 10, factor: 1.0), windows: [
        window('w1', 0, 5, lPer100Km: 7),
        window('w2', 5, 10, lPer100Km: 7),
      ]).behaviourOf(e10)!;
      expect(b.lPer100Km.basis, MetricBasis.referenceWindows);
      expect(b.lPer100Km.value, closeTo(7, 1e-9));
      expect(b.provenance,
          {EvidenceTier.measured: 10, EvidenceTier.reference: 2});
    });

    test('measured trips outrank estimates; estimates fill in alone', () {
      final est = analyze(tripsOn('e10-', 0.5, 10,
              factor: 1.0, source: ConsumptionSourceClass.estimated))
          .behaviourOf(e10)!;
      expect(est.lPer100Km.basis, MetricBasis.estimatedTrips);
      expect(est.residualRatio.basis, MetricBasis.estimatedResiduals);
      expect(est.provenance, {EvidenceTier.estimated: 10});
    });

    test('a figure-less trip is counted as unknown, not averaged', () {
      final none = TripFuelEvidence.fromEstimate(
        ConsumptionEstimate.unavailable(
            reason: DataUnknownReason.notMeasuredYet, version: v1),
        id: 'none',
        at: day(1),
        distanceKm: 30,
      );
      final b = analyze([...tripsOn('e10-', 0.5, 10, factor: 1.0), none])
          .behaviourOf(e10)!;
      expect(none.tier, EvidenceTier.unknown);
      expect(b.exclusions, {EvidenceExclusion.noFigure: 1});
      expect(b.lPer100Km.sampleCount, 10);
    });
  });

  group('E10 / E85 isolation', () {
    List<TripFuelEvidence> e85Trips() => [
          ...tripsOn('e85-', 11.5, 10, factor: 1.3),
          // An estimate calibrated under the E10 gain must not teach E85.
          trip('leak', 14, observed: 99, expected: 6,
              source: ConsumptionSourceClass.estimated,
              calibrationGrade: FuelGrade.e10),
        ];
    final e85Windows = [
      window('w85a', 11, 16, lPer100Km: 8),
      window('w85b', 16, 21, lPer100Km: 8.2),
    ];

    Map<String, Object?> e85Json(double e10Factor, double e10WindowL) =>
        analyze([
          ...tripsOn('e10-', 0.5, 10, factor: e10Factor),
          ...e85Trips(),
        ], windows: [
          window('w10a', 0, 5, lPer100Km: e10WindowL),
          window('w10b', 5, 10, lPer100Km: e10WindowL * 1.1,
              pricePerLitre: 3),
          ...e85Windows,
        ]).behaviourOf(e85)!.toJson();

    test('changing everything E10 learned leaves E85 bit-identical', () {
      expect(jsonEncode(e85Json(2.5, 14)), jsonEncode(e85Json(1.0, 6)));
    });

    test('a cross-calibrated estimate is excluded and named', () {
      final b = analyze(e85Trips()).behaviourOf(e85)!;
      expect(b.exclusions, {EvidenceExclusion.crossCalibrated: 1});
      expect(b.residualRatio.value, closeTo(1.3, 0.01));
    });
  });

  group('versioned, deterministic replay', () {
    final trips = [
      ...tripsOn('e10-', 0.5, 10, factor: 1.0),
      ...tripsOn('e85-', 11.5, 10, factor: 1.3),
      ...tripsOn('mix-', 22.5, 10, factor: 1.15),
    ];
    final windows = [
      window('w1', 0, 5, lPer100Km: 6),
      window('w2', 5, 10, lPer100Km: 6.3),
    ];

    test('delivery order and duplicates do not change the profile', () {
      final a = analyze(trips, windows: windows);
      final b = analyze([...trips.reversed, ...trips.take(5)],
          windows: [...windows.reversed, windows.first]);
      expect(jsonEncode(b.toJson()), jsonEncode(a.toJson()));
    });

    test('the profile states its model and input versions', () {
      final p = analyze(trips);
      expect(p.modelVersion, FuelBehaviourProfile.currentModelVersion);
      expect(p.toJson()['modelVersion'], 1);
      expect(p.blendModelVersion, 1);
      expect(p.consumptionVersions, [v1]);
      expect(p.unversionedTrips, 0);
    });

    test('the thresholds are the documented constants', () {
      expect(kMinReferenceWindows, 2);
      expect(kMinTripSamples, 5);
      expect(kMinTripDistanceKm, 50);
      expect(kMinResidualSamples, kMinTripSamples);
      expect(kPureGradeMinShare, 0.85);
      expect(kMaxUnknownShareForContext, 0.15);
    });
  });
}
