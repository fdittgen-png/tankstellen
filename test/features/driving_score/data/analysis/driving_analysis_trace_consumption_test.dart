// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/consumption_estimate.dart';
import 'package:tankstellen/features/driving_score/data/analysis/driving_analysis_trace.dart';
import 'package:tankstellen/features/driving_score/domain/driving_score.dart';
import 'package:tankstellen/features/trips/domain/trip_summary.dart';

/// #4233 — the driving-analysis export reads the trip's consumption through
/// the canonical adapter (ADR 0024 §7): it adds the source class and the
/// stored fuzzy version beside the UNCHANGED stored `avgLPer100Km`.
const DrivingScore _score = DrivingScore(
  score: 90,
  idlingPenalty: 0,
  hardAccelPenalty: 0,
  hardBrakePenalty: 0,
  highRpmPenalty: 0,
  fullThrottlePenalty: 0,
  hardAccelEvents: 0,
  hardBrakeEvents: 0,
);

Map<String, dynamic> _summaryBlock(TripSummary s) {
  final json = DrivingAnalysisTrace(
    capturedAt: DateTime.utc(2026, 9, 16, 11),
    summary: s,
    score: _score,
    lessons: const [],
  ).toJson();
  // Through a real encode/decode, as the shared file is.
  return (jsonDecode(jsonEncode(json)) as Map<String, dynamic>)['summary']
      as Map<String, dynamic>;
}

TripSummary _trip({double? avg, double? eAvg, String? dfs, TripKind? kind,
        ConsumptionModelVersion? cmv}) =>
    TripSummary(
      distanceKm: 14,
      maxRpm: 2600,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: 0,
      harshAccelerations: 0,
      avgLPer100Km: avg,
      fuelLitersConsumed: avg == null ? null : avg * 0.14,
      estimatedAvgLPer100Km: eAvg,
      dominantFuelSource: dfs,
      kind: kind ?? TripKind.gpsPlusObd2,
      consumptionVersion: cmv,
      startedAt: DateTime.utc(2026, 9, 16, 10),
      endedAt: DateTime.utc(2026, 9, 16, 10, 20),
    );

void main() {
  test('a stamped GPS live estimate exports its class and version', () {
    final block = _summaryBlock(_trip(
        eAvg: 5.9,
        kind: TripKind.gpsOnly,
        cmv: const ConsumptionModelVersion(model: 1, rules: 1)));
    expect(block['consumptionSource'], 'gpsOnly');
    expect(block['consumptionVersion'], {'model': 1, 'rules': 1});
    expect(block['avgLPer100Km'], isNull,
        reason: 'the stored figure is exported unchanged');
  });

  test('a legacy measured trip exports measured and no version', () {
    final block = _summaryBlock(_trip(avg: 6.37, dfs: 'pid5E'));
    expect(block['consumptionSource'], 'measured');
    expect(block['consumptionVersion'], isNull);
    expect(block['avgLPer100Km'], 6.37);
  });
}
