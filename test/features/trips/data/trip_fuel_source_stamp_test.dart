// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3919 — the dominant fuel-source branch is stamped onto the summary at
// persist time (from the per-sample provenance) and round-trips through
// the codec under the compact `dfs` key, so the summary-only history
// list can badge measured vs estimated fuel without its samples.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/trips/data/trip_history_entry.dart';
import 'package:tankstellen/features/trips/data/trip_summary_codec.dart';
import 'package:tankstellen/features/trips/domain/trip_sample.dart';
import 'package:tankstellen/features/trips/domain/trip_summary.dart';

final _t0 = DateTime(2026, 9, 1, 8);

TripSummary _summary({String? dominant}) => TripSummary(
      distanceKm: 12,
      maxRpm: 3000,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: 0,
      harshAccelerations: 0,
      fuelLitersConsumed: 1.2,
      avgLPer100Km: 10,
      startedAt: _t0,
      dominantFuelSource: dominant,
    );

TripSample _sample(int sec, String? fs) => TripSample(
      timestamp: _t0.add(Duration(seconds: sec)),
      speedKmh: 50,
      rpm: 2000,
      fuelRateLPerHour: fs == null ? null : 5.0,
      fuelSource: fs,
    );

void main() {
  test('codec: dfs written when set, absent otherwise, read back', () {
    final withIt = tripSummaryToJson(_summary(dominant: 'speedDensity'));
    expect(withIt['dfs'], 'speedDensity');
    expect(tripSummaryFromJson(withIt).dominantFuelSource, 'speedDensity');
    final without = tripSummaryToJson(_summary());
    expect(without.containsKey('dfs'), isFalse);
    expect(tripSummaryFromJson(without).dominantFuelSource, isNull);
  });

  test('entry.toJson stamps the majority branch from the samples', () {
    final entry = TripHistoryEntry(
      id: 't',
      vehicleId: 'v',
      summary: _summary(),
      samples: [
        _sample(0, 'pid5E'),
        _sample(1, 'pid5E'),
        _sample(2, 'maf'),
        _sample(3, null),
      ],
    );
    final json = entry.toJson();
    expect((json['summary'] as Map)['dfs'], 'pid5E');
    // Both decode paths carry it — the summary-only one is the list's.
    expect(TripHistoryEntry.fromJson(json).summary.dominantFuelSource, 'pid5E');
    expect(TripHistoryEntry.summaryFromJson(json).summary.dominantFuelSource,
        'pid5E');
  });

  test('an already-stamped summary is kept; no samples → no stamp', () {
    final stamped = TripHistoryEntry(
      id: 't',
      vehicleId: 'v',
      summary: _summary(dominant: 'maf'),
      samples: [_sample(0, 'pid5E')],
    ).toJson();
    expect((stamped['summary'] as Map)['dfs'], 'maf');
    final bare = TripHistoryEntry(id: 't', vehicleId: 'v', summary: _summary())
        .toJson();
    expect((bare['summary'] as Map).containsKey('dfs'), isFalse);
  });
}
