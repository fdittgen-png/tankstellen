// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/analysis/driving_analysis_trace.dart';
import 'package:tankstellen/features/consumption/domain/driving_score.dart';
import 'package:tankstellen/features/consumption/domain/gps_driving_features.dart';
import 'package:tankstellen/features/consumption/domain/lessons/driving_lesson.dart';
import 'package:tankstellen/features/consumption/domain/obd2_trip_features.dart';
import 'package:tankstellen/features/consumption/domain/trip_sample.dart';
import 'package:tankstellen/features/consumption/domain/trip_summary.dart';

TripSummary _summary() => TripSummary(
      distanceKm: 20,
      maxRpm: 0,
      highRpmSeconds: 0,
      idleSeconds: 30,
      harshBrakes: 0,
      harshAccelerations: 0,
      avgLPer100Km: 5.4,
      startedAt: DateTime.utc(2026, 6, 3, 10),
      endedAt: DateTime.utc(2026, 6, 3, 10, 25),
      distanceSource: 'real',
      kind: TripKind.gpsOnly,
      imuHardAccelCount: 2,
      imuHardBrakeCount: 1,
      sharpCornerCount: 3,
    );

GpsDrivingFeatures _features() => const GpsDrivingFeatures(
      idleSeconds: 30,
      lowSpeedSeconds: 100,
      cruiseSeconds: 1200,
      highSpeedSeconds: 200,
      accelEvents: 4,
      brakeEvents: 5,
      maxAccelG: 0.21,
      meanSpeedKmh: 52.3,
      distanceKm: 20,
      totalSeconds: 1530,
      gradeClimbMeters: 80,
      gradeDescentMeters: 75,
      cornerLoadIntegral: 12,
      sharpCornerEvents: 3,
      relativePositiveAcceleration: 0.224,
      positiveKineticEnergy: 0.331,
      meanPositiveVa: 1.42,
      coastShare: 0.18,
      climbEnergyPerKm: 145.6,
    );

const DrivingScore _score = DrivingScore(
  score: 78,
  idlingPenalty: 2,
  hardAccelPenalty: 6,
  hardBrakePenalty: 4,
  hardAccelEvents: 2,
  hardBrakeEvents: 1,
  highRpmPenalty: 0,
  fullThrottlePenalty: 0,
);

void main() {
  group('DrivingAnalysisTrace', () {
    test('comment defaults to the annotation prompt', () {
      final trace = DrivingAnalysisTrace(
        capturedAt: DateTime.utc(2026, 6, 3, 11),
        summary: _summary(),
        score: _score,
        lessons: const [],
      );
      expect(trace.comment, kDrivingAnalysisCommentPrompt);
      expect(trace.toJson()['comment'], kDrivingAnalysisCommentPrompt);
    });

    test('serialises the full KPI / IMU / score / lesson contract', () {
      final trace = DrivingAnalysisTrace(
        capturedAt: DateTime.utc(2026, 6, 3, 11),
        summary: _summary(),
        score: _score,
        gpsFeatures: _features(),
        comment: 'calm motorway cruise — felt smooth',
        lessons: const [
          DrivingLesson(
            id: 'smoothDriving',
            impact: 0,
            metricValue: 0.224,
            title: 'Conduite souple',
            polarity: LessonPolarity.positive,
          ),
        ],
      );
      final json = trace.toJson();

      expect(json['schema'], DrivingAnalysisTrace.schema);
      expect(json['kind'], 'drivingAnalysis');
      expect(json['capturedAt'], '2026-06-03T11:00:00.000Z');
      expect(json['comment'], 'calm motorway cruise — felt smooth');

      final summary = json['summary'] as Map<String, dynamic>;
      expect(summary['tripKind'], 'gpsOnly');
      expect(summary['distanceKm'], 20);
      expect(summary['durationSec'], 1500);
      expect(summary['avgLPer100Km'], 5.4);
      expect(summary['distanceSource'], 'real');

      final imu = json['imu'] as Map<String, dynamic>;
      expect(imu['hardAccelCount'], 2);
      expect(imu['hardBrakeCount'], 1);
      expect(imu['sharpCornerCount'], 3);
      expect(imu['hardAccelPerKm'], 0.1);
      expect(imu['sharpCornersPerKm'], 0.15);
      // #3589 — the per-stretch calibration records ride the imu block.
      expect(imu['events'], isA<List<dynamic>>());
      expect(imu['droppedEvents'], 0);

      final gps = json['gpsFeatures'] as Map<String, dynamic>;
      expect(gps['rpa'], 0.224);
      expect(gps['pke'], 0.331);
      expect(gps['vapos'], 1.42);
      expect(gps['coastShare'], 0.18);
      expect(gps['climbEnergyPerKm'], 145.6);
      expect(gps['accelEvents'], 4);
      expect(gps['brakeEvents'], 5);
      expect(gps['sharpCornerEvents'], 3);
      expect(gps['meanSpeedKmh'], 52.3);
      final bands = gps['speedBandSeconds'] as Map<String, dynamic>;
      expect(bands['cruise'], 1200);

      final score = json['score'] as Map<String, dynamic>;
      expect(score['overall'], 78);
      expect(score['styleClass'], _score.styleClass.name);
      expect(score['hardAccelPenalty'], 6);
      expect(score['hardBrakePenalty'], 4);
      // #3350 — the score block exports the counts the penalties were computed
      // from, read straight off the score so they always match.
      expect(score['hardAccelCount'], 2);
      expect(score['hardBrakeCount'], 1);

      final lessons = json['lessons'] as List<dynamic>;
      expect(lessons, hasLength(1));
      expect((lessons.first as Map)['id'], 'smoothDriving');
      expect((lessons.first as Map)['polarity'], 'positive');
    });

    test(
        '#3350 — the score block\'s harsh counts are the penalty drivers '
        '(read off the score), even when the summary figure is a suppressed 0',
        () {
      // Reproduces the field bug: an OBD2 trip with the IMU INACTIVE. The
      // summary's harshAccelerations fell back to the recorder's
      // GPS-suppressed HarshEventDetector → 0, but the SCORE's penalty was
      // driven by the sample-derived gate (12 accel / 5 brake episodes). Before
      // #3350 the export read the summary (0), so a 15-pt penalty showed
      // alongside count 0 — a phantom. Now it reads the score's own resolved
      // counts, so count ⟺ penalty by construction.
      final summary = TripSummary(
        distanceKm: 109,
        maxRpm: 3000,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0, // suppressed → would contradict the penalty
        harshAccelerations: 0,
        startedAt: DateTime.utc(2026, 6, 3, 10),
        endedAt: DateTime.utc(2026, 6, 3, 11),
        distanceSource: 'gps',
        kind: TripKind.gpsPlusObd2,
        imuActive: false,
        imuHardAccelCount: 0,
        imuHardBrakeCount: 0,
      );
      const score = DrivingScore(
        score: 33,
        idlingPenalty: 0,
        hardAccelPenalty: 15,
        hardBrakePenalty: 15,
        hardAccelEvents: 12, // the count that ACTUALLY drove the penalty
        hardBrakeEvents: 5,
        highRpmPenalty: 0,
        fullThrottlePenalty: 0,
      );
      final json = DrivingAnalysisTrace(
        capturedAt: DateTime.utc(2026, 6, 3, 11),
        summary: summary,
        score: score,
        lessons: const [],
      ).toJson();

      final scoreBlock = json['score'] as Map<String, dynamic>;
      final imu = json['imu'] as Map<String, dynamic>;
      // The score block reports the penalty-driving counts, NOT the summary 0.
      expect(scoreBlock['hardAccelCount'], 12);
      expect(scoreBlock['hardBrakeCount'], 5);
      expect(scoreBlock['hardAccelPenalty'], 15);
      expect(scoreBlock['hardBrakePenalty'], 15);
      // The IMU truth block is unchanged (still the inertial scalars).
      expect(imu['hardAccelCount'], 0);
      expect(imu['hardBrakeCount'], 0);
      // Invariant: a non-zero penalty always has a non-zero score-block count.
      expect(scoreBlock['hardAccelCount'], greaterThan(0));
      expect(scoreBlock['hardBrakeCount'], greaterThan(0));
    });

    test('gpsFeatures is null when no GPS KPIs were computed', () {
      final trace = DrivingAnalysisTrace(
        capturedAt: DateTime.utc(2026, 6, 3, 11),
        summary: _summary(),
        score: _score,
        lessons: const [],
      );
      expect(trace.toJson()['gpsFeatures'], isNull);
    });

    test('obd2Features is null when no engine signal landed — the broken-link '
        '/ GPS-only marker (#3402)', () {
      final trace = DrivingAnalysisTrace(
        capturedAt: DateTime.utc(2026, 6, 3, 11),
        summary: _summary(),
        score: _score,
        lessons: const [],
      );
      expect(trace.toJson()['obd2Features'], isNull);
    });

    test('obd2Features surfaces real engine telemetry + fuel provenance '
        '(#3402)', () {
      final obd2 = Obd2TripFeatures.fromSamples([
        TripSample(
          timestamp: DateTime.utc(2026, 6, 3, 10),
          speedKmh: 50,
          rpm: 1800,
          fuelRateLPerHour: 2.4,
          engineLoadPercent: 42,
        ),
        TripSample(
          timestamp: DateTime.utc(2026, 6, 3, 10, 0, 1),
          speedKmh: 55,
          rpm: 2200,
          fuelRateLPerHour: 2.8,
          engineLoadPercent: 48,
        ),
      ]);
      final json = DrivingAnalysisTrace(
        capturedAt: DateTime.utc(2026, 6, 3, 11),
        summary: _summary(),
        score: _score,
        lessons: const [],
        obd2Features: obd2,
      ).toJson();

      final block = json['obd2Features'] as Map<String, dynamic>;
      expect(block['fuelSource'], 'measured');
      expect(block['obd2Coverage'], 1.0);
      expect((block['rpm'] as Map)['mean'], 2000.0);
      expect((block['signalCoverage'] as Map)['engineLoadPercent'], 1.0);
    });

    test('#3433 — the precision block exports '
        'measured φ / ethanol / dominant fuel branch', () {
      final obd2 = Obd2TripFeatures.fromSamples([
        TripSample(
          timestamp: DateTime.utc(2026, 6, 3, 10),
          speedKmh: 50,
          rpm: 1800,
          fuelRateLPerHour: 48.6,
          measuredPhi: 0.99,
          ethanolPercent: 10,
          fuelSource: 'pid9D',
        ),
        TripSample(
          timestamp: DateTime.utc(2026, 6, 3, 10, 0, 1),
          speedKmh: 55,
          rpm: 2200,
          fuelRateLPerHour: 50.1,
          measuredPhi: 1.01,
          ethanolPercent: 10,
          fuelSource: 'pid9D',
        ),
      ]);
      final json = DrivingAnalysisTrace(
        capturedAt: DateTime.utc(2026, 6, 3, 11),
        summary: _summary(),
        score: _score,
        lessons: const [],
        obd2Features: obd2,
      ).toJson();

      // #3499/#3501 bumped the trace schema to 4 (additive obd2Coverage +
      // verdict); the #3433 precision keys are unchanged.
      expect(json['schema'], 4);
      final block = json['obd2Features'] as Map<String, dynamic>;
      expect((block['measuredPhi'] as Map)['mean'], 1.0);
      expect((block['ethanolPercent'] as Map)['mean'], 10.0);
      expect(block['dominantFuelSource'], 'pid9D');
      expect((block['fuelSourceShares'] as Map)['pid9D'], 1.0);
      expect((block['signalCoverage'] as Map)['measuredPhi'], 1.0);
      expect((block['signalCoverage'] as Map)['ethanolPercent'], 1.0);
    });

    test('formatDrivingAnalysisTraceJson is valid, round-trippable JSON', () {
      final trace = DrivingAnalysisTrace(
        capturedAt: DateTime.utc(2026, 6, 3, 11),
        summary: _summary(),
        score: _score,
        gpsFeatures: _features(),
        lessons: const [],
      );
      final text = formatDrivingAnalysisTraceJson(trace);
      // Pretty-printed (indented) and parseable back to the same map.
      expect(text, contains('\n  '));
      expect(jsonDecode(text), equals(trace.toJson()));
    });
  });
}
