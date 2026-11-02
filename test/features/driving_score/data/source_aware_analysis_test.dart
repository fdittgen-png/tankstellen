// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/driving_score/data/driving_dimensions_calculator.dart';
import 'package:tankstellen/features/driving_score/data/driving_score_calculator.dart';
import 'package:tankstellen/features/driving_score/data/analysis/driving_score_evidence.dart';
import 'package:tankstellen/features/driving_score/data/analysis/mixture_lesson_evidence.dart';
import 'package:tankstellen/features/driving_score/domain/driving_dimensions.dart';
import 'package:tankstellen/features/driving_score/domain/driving_score.dart';
import 'package:tankstellen/features/trips/api.dart';

List<TripSample> deceleration(String? source, {double rate = 0}) => [
  for (var i = 0; i <= 30; i++)
    TripSample(
      timestamp: DateTime.utc(2026).add(Duration(seconds: i)),
      speedKmh: 100.0 - i * 2,
      rpm: 2000,
      fuelRateLPerHour: rate,
      fuelSource: source,
      hAccuracyM: 3,
    ),
];

void main() {
  test('air-derived or untagged fuel cannot prove no injector cut', () {
    for (final source in ['speedDensity', 'maf', null]) {
      final samples = deceleration(source);
      final d = computeDrivingDimensions(samples);
      expect(d[DrivingDimensionKind.coasting].value, isNull, reason: '$source');
      expect(
        d[DrivingDimensionKind.coasting].confidence,
        DimensionConfidence.none,
      );
      expect(computeDrivingScore(samples).ecoCreditCoast, 0);
    }
  });

  test('direct flow distinguishes observed cut from an observable non-cut', () {
    final cut = computeDrivingDimensions(deceleration('pid5E'));
    final fueled = computeDrivingDimensions(deceleration('pid5E', rate: 3));
    expect(cut[DrivingDimensionKind.coasting].value, 1);
    expect(fueled[DrivingDimensionKind.coasting].value, 0);
    expect(
      computeDrivingScore(deceleration('pid5E')).ecoCreditCoast,
      greaterThan(0),
    );
  });

  test(
    'wire lambda below one is rich; lean lambda must not be scored rich',
    () {
      List<TripSample> trip(double phi) => [
        for (var i = 0; i < 20; i++)
          TripSample(
            timestamp: DateTime.utc(2026).add(Duration(seconds: i)),
            speedKmh: 60,
            rpm: 2000,
            coolantTempC: 84,
            lambda: phi,
          ),
      ];
      expect(
        computeDrivingScore(trip(0.88)).lambdaEnrichmentPenalty,
        greaterThan(0),
      );
      for (final phi in [1.12, 1.0, 9.0, 0.1]) {
        expect(computeDrivingScore(trip(phi)).lambdaEnrichmentPenalty, 0);
      }
      expect(mixtureLessonEvidence(trip(0.88))['kind'], 'commandedEnrichment');
      expect(mixtureLessonEvidence(trip(1.12))['fired'], isFalse);
    },
  );

  test('full exported score contributions reproduce actual score exactly', () {
    final score = computeDrivingScore(
      deceleration('pid5E'),
      secondsBelowOptimalGear: 10,
    );
    final json = drivingScoreEvidence(score);
    expect((json['calculation'] as Map)['reconstructedScore'], score.score);
    expect(json, contains('smoothnessPenalty'));
    expect(json, contains('pedalVelocityPenalty'));
    expect(json, contains('ecoCreditCoast'));
  });

  test(
    'trim lesson magnitude comes from qualifying LTFT, not total trim or MAP',
    () {
      final samples = [
        for (var i = 0; i < 12; i++)
          TripSample(
            timestamp: DateTime.utc(2026).add(Duration(seconds: i)),
            speedKmh: 58,
            rpm: 2000,
            coolantTempC: 84,
            stft: 3.125,
            ltft: 10,
            mapKpa: 35,
          ),
      ];
      final e = mixtureLessonEvidence(samples);
      expect(e['fired'], isTrue);
      expect(e['reportedMagnitudePct'], 10);
      expect(e['sustainedSamples'], 12);
      expect(e['magnitudeDefinition'], contains('mean absolute LTFT'));
    },
  );
  test(
    'score reconstruction preserves canonical rounding at a half-point boundary',
    () {
      const score = DrivingScore(
        score: 79,
        idlingPenalty: 2.3770268241990204,
        highRpmPenalty: 1.6062563425620144,
        hardAccelPenalty: 2.2662793721825474,
        hardBrakePenalty: 0.45424480375552123,
        fullThrottlePenalty: 2.091659648281621,
        pedalVelocityPenalty: 1.3725574362322313,
        luggingPenalty: 2.8022102680322174,
        hardShiftPenalty: 2.5110133363626304,
        revWhileStationaryPenalty: 0.7941114894794367,
        smoothnessPenalty: 1.3897668648651436,
        speedEfficiencyPenalty: 2.7083180937190066,
        lambdaEnrichmentPenalty: 1.1265555203286226,
      );
      final calculation = drivingScoreEvidence(score)['calculation'] as Map;
      expect(calculation['reconstructedScore'], 79);
      expect(calculation['matchesExportedScore'], isTrue);
    },
  );
}
