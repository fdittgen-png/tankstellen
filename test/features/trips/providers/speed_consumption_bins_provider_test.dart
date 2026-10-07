// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/trips/data/trip_history_repository.dart';
import 'package:tankstellen/features/trips/data/trip_history_store_v2.dart';
import 'package:tankstellen/features/trips/domain/services/speed_consumption_histogram.dart';
import 'package:tankstellen/features/trips/domain/trip_sample.dart';
import 'package:tankstellen/features/trips/domain/trip_summary.dart';
import 'package:tankstellen/features/trips/providers/speed_consumption_bins_provider.dart';

/// The worker-isolate fold of the carbon Charts histogram must produce the
/// EXACT bins the old per-trip UI-isolate path did, for both row layouts.

final _start = DateTime.utc(2026, 9, 1, 8);

List<TripSample> _samples(int n, double speedOffset) => [
      for (var i = 0; i < n; i++)
        TripSample(
          timestamp: _start.add(Duration(seconds: i)),
          speedKmh: (i % 140) + speedOffset,
          rpm: 2000.0,
          fuelRateLPerHour: i % 5 == 0 ? null : 3.0 + (i % 9),
        ),
    ];

TripHistoryEntry _entry(String id, List<TripSample> samples) =>
    TripHistoryEntry(
      id: id,
      vehicleId: 'veh',
      summary: TripSummary(
        distanceKm: 10,
        maxRpm: 3000,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        startedAt: _start,
      ),
      samples: samples,
    );

/// The rows `TripHistoryRepository.columnSources` hands to the worker.
TripColumnSource _v2Source(TripHistoryEntry e) {
  final rows = encodeTripRowsV2(e.toJson());
  return (
    row: rows[e.id]!,
    chunks: [
      for (var i = 0; rows.containsKey(tripChunkKey(e.id, i)); i++)
        rows[tripChunkKey(e.id, i)]!,
    ],
  );
}

List<Object?> _fields(SpeedConsumptionBin b) =>
    [b.band, b.sampleCount, b.timeShareSeconds, b.avgLPer100Km];

void main() {
  test('v2 rows: the isolate fold equals the per-trip histogram', () {
    final a = _entry('a', _samples(700, 0));
    final b = _entry('b', _samples(450, 7));
    final expected = aggregateSpeedConsumption([...a.samples, ...b.samples]);

    final bins =
        speedConsumptionBinsFromSources([_v2Source(a), _v2Source(b)]);

    expect(bins.map(_fields).toList(), expected.map(_fields).toList());
    expect(bins.fold<int>(0, (n, x) => n + x.sampleCount), greaterThan(0));
  });

  test('a legacy v1 row folds the same as its samples', () {
    final legacy = _entry('old', _samples(300, 3));
    final expected = aggregateSpeedConsumption(legacy.samples);

    final bins = speedConsumptionBinsFromSources([
      (row: jsonEncode(legacy.toJson()), chunks: const <String>[]),
    ]);

    expect(bins.map(_fields).toList(), expected.map(_fields).toList());
  });
}
