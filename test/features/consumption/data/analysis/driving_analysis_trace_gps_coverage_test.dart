// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/analysis/driving_analysis_trace.dart';
import 'package:tankstellen/features/consumption/domain/driving_score.dart';
import 'package:tankstellen/features/consumption/domain/entities/recording_lifecycle_mark.dart';
import 'package:tankstellen/features/consumption/domain/gps_coverage_report.dart';
import 'package:tankstellen/features/consumption/domain/trip_sample.dart';
import 'package:tankstellen/features/consumption/domain/trip_summary.dart';

/// #3465 — the driving-analysis export's `gpsCoverage` block (schema v3):
/// present + JSON-round-trippable for a tracked trip, capped at 20 gaps,
/// null for legacy trips without a usable track, and honest (`unknown`
/// attribution, null backgroundShare) for legacy trips without marks.
void main() {
  final t0 = DateTime.utc(2026, 7, 1, 8);

  TripSummary summary() => TripSummary(
        distanceKm: 20,
        maxRpm: 0,
        highRpmSeconds: 0,
        idleSeconds: 30,
        harshBrakes: 0,
        harshAccelerations: 0,
        startedAt: t0,
        endedAt: t0.add(const Duration(minutes: 25)),
        kind: TripKind.gpsOnly,
      );

  const score = DrivingScore(
    score: 78,
    idlingPenalty: 2,
    hardAccelPenalty: 6,
    hardBrakePenalty: 4,
    hardAccelEvents: 2,
    hardBrakeEvents: 1,
    highRpmPenalty: 0,
    fullThrottlePenalty: 0,
  );

  TripSample fix(Duration offset) => TripSample(
        timestamp: t0.add(offset),
        speedKmh: 50,
        latitude: 43.4 + offset.inSeconds * 1e-5,
        longitude: 3.5,
      );

  DrivingAnalysisTrace trace({GpsCoverageReport? coverage}) =>
      DrivingAnalysisTrace(
        capturedAt: t0.add(const Duration(hours: 1)),
        summary: summary(),
        score: score,
        lessons: const [],
        gpsCoverage: coverage,
      );

  test('schema is 3 and the gpsCoverage block round-trips through JSON',
      () {
    // A backgrounded 30 s hole on a no-FGS build — the field scenario.
    final samples = [
      for (var i = 0; i < 6; i++) fix(Duration(seconds: i)),
      for (var i = 35; i < 41; i++) fix(Duration(seconds: i)),
    ];
    final coverage = GpsCoverageReport.fromSamples(
      samples,
      expectedFixInterval: const Duration(seconds: 1),
      marks: [
        RecordingLifecycleMark(at: t0, backgrounded: false),
        RecordingLifecycleMark(
            at: t0.add(const Duration(seconds: 6)), backgrounded: true),
        RecordingLifecycleMark(
            at: t0.add(const Duration(seconds: 34)), backgrounded: false),
      ],
      fgsEnabled: false,
    );

    final json = trace(coverage: coverage).toJson();

    expect(json['schema'], 4); // v4: additive obd2Coverage + verdict (#3499/#3501)
    final block = json['gpsCoverage'] as Map<String, dynamic>;
    expect(block['actualFixCount'], 12);
    expect(block['expectedFixCount'], 41);
    expect(block['gapCount'], 1);
    expect((block['longestGap'] as Map)['attribution'], 'backgroundThrottle');
    expect((block['longestGap'] as Map)['durationMs'], 30000);
    expect(block['fgsEnabled'], false);

    // The whole trace stays valid, round-trippable JSON.
    final text = formatDrivingAnalysisTraceJson(trace(coverage: coverage));
    expect(jsonDecode(text), equals(trace(coverage: coverage).toJson()));
  });

  test('the exported gap list is capped at 20 entries', () {
    final samples = <TripSample>[];
    for (var i = 0; i < 26; i++) {
      samples.add(fix(Duration(seconds: i * 6)));
      samples.add(fix(Duration(seconds: i * 6 + 1)));
    }
    final coverage = GpsCoverageReport.fromSamples(
      samples,
      expectedFixInterval: const Duration(seconds: 1),
      fgsEnabled: false,
    );

    final block =
        trace(coverage: coverage).toJson()['gpsCoverage'] as Map;
    expect(block['gapCount'], 25);
    expect(block['gaps'], hasLength(20));
    expect(block['gapsTruncated'], isTrue);
  });

  test('a legacy trip without a usable track exports gpsCoverage: null '
      '(the forTrip gate)', () {
    // Engine-only samples — no fixes → no report → explicit null block.
    expect(
      GpsCoverageReport.forTrip([
        TripSample(timestamp: t0, speedKmh: 50, rpm: 2000),
        TripSample(
            timestamp: t0.add(const Duration(seconds: 1)),
            speedKmh: 51,
            rpm: 2100),
      ]),
      isNull,
    );
    final json = trace().toJson();
    expect(json.containsKey('gpsCoverage'), isTrue);
    expect(json['gpsCoverage'], isNull);
    // v2-shaped readers that ignore unknown keys still parse the trace.
    expect(jsonDecode(formatDrivingAnalysisTraceJson(trace())),
        equals(json));
  });

  test('a legacy trip with a track but NO marks exports honest unknowns',
      () {
    final samples = [
      for (var i = 0; i < 4; i++) fix(Duration(seconds: i)),
      for (var i = 12; i < 16; i++) fix(Duration(seconds: i)),
    ];
    final coverage = GpsCoverageReport.forTrip(samples);
    expect(coverage, isNotNull);

    final block =
        trace(coverage: coverage).toJson()['gpsCoverage'] as Map;
    expect((block['longestGap'] as Map)['attribution'], 'unknown',
        reason: 'no marks → foreground state unprovable → never claim '
            'signalLoss');
    expect(block['backgroundShare'], isNull,
        reason: 'no marks → 0.0 would falsely read as provably-foreground');
  });
}
