// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/analysis/driving_analysis_trace.dart';
import 'package:tankstellen/features/consumption/domain/driving_score.dart';
import 'package:tankstellen/features/consumption/domain/gps_driving_features.dart';
import 'package:tankstellen/features/consumption/domain/lessons/driving_lesson.dart';
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

      final lessons = json['lessons'] as List<dynamic>;
      expect(lessons, hasLength(1));
      expect((lessons.first as Map)['id'], 'smoothDriving');
      expect((lessons.first as Map)['polarity'], 'positive');
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
