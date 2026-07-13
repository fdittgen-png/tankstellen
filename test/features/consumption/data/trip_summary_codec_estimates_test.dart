// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/trip_summary_codec.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

/// #3576 — the GPS-physics estimate figures must survive the Hive JSON
/// round-trip (the #2776 lesson: a field that any toJson path drops is a
/// field the app silently loses), and legacy/measured trips must
/// round-trip byte-identical (no `eAvg`/`eFuel` keys).
void main() {
  TripSummary mk({double? estAvg, double? estFuel, double? measured}) =>
      TripSummary(
        distanceKm: 18.2,
        maxRpm: 0,
        highRpmSeconds: 0,
        idleSeconds: 30,
        harshBrakes: 0,
        harshAccelerations: 0,
        avgLPer100Km: measured,
        estimatedAvgLPer100Km: estAvg,
        estimatedFuelLitersConsumed: estFuel,
        startedAt: DateTime(2026, 7, 13, 21, 37),
      );

  test('estimate figures round-trip through the codec', () {
    final json = tripSummaryToJson(mk(estAvg: 11.0, estFuel: 2.01));
    expect(json['eAvg'], 11.0);
    expect(json['eFuel'], 2.01);
    final back = tripSummaryFromJson(json);
    expect(back.estimatedAvgLPer100Km, 11.0);
    expect(back.estimatedFuelLitersConsumed, 2.01);
  });

  test('trips without estimates serialise with zero extra bytes', () {
    final json = tripSummaryToJson(mk(measured: 6.4));
    expect(json.containsKey('eAvg'), isFalse);
    expect(json.containsKey('eFuel'), isFalse);
    final back = tripSummaryFromJson(json);
    expect(back.estimatedAvgLPer100Km, isNull);
    expect(back.estimatedFuelLitersConsumed, isNull);
    expect(back.avgLPer100Km, 6.4);
  });
}
