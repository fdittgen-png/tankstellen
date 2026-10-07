// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/trips/data/trip_history_repository.dart';
import 'package:tankstellen/features/trips/data/trip_history_store_v2.dart';
import 'package:tankstellen/features/trips/domain/services/speed_consumption_histogram.dart';
import 'package:tankstellen/features/trips/domain/trip_sample.dart';
import 'package:tankstellen/features/trips/domain/trip_summary.dart';
import 'package:tankstellen/features/trips/providers/speed_consumption_bins_provider.dart';
import 'package:tankstellen/features/trips/providers/trip_history_provider.dart';

import '../../../helpers/hive_temp_dir.dart';

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

TripHistoryEntry _entry(String id, List<TripSample> samples,
        {String? vehicleId = 'veh'}) =>
    TripHistoryEntry(
      id: id,
      vehicleId: vehicleId,
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

/// A fixture list (no box) whose entries carry their samples.
class _FixtureList extends TripHistoryList {
  _FixtureList(this._entries);
  final List<TripHistoryEntry> _entries;

  @override
  List<TripHistoryEntry> build() => _entries;
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

  test('without a repository the fixture entries are the data', () async {
    final a = _entry('a', _samples(400, 2));
    final container = ProviderContainer(overrides: [
      tripHistoryRepositoryProvider.overrideWithValue(null),
      tripHistoryListProvider.overrideWith(() => _FixtureList([a])),
    ]);
    addTearDown(container.dispose);

    final bins =
        await container.read(speedConsumptionBinsProvider('veh').future);

    expect(bins.map(_fields).toList(),
        aggregateSpeedConsumption(a.samples).map(_fields).toList());
  });

  group('through a real repository', () {
    late Directory dir;
    late Box<String> box;
    late TripHistoryRepository repo;
    final mine = _entry('mine', _samples(700, 0));
    final shared = _entry('shared', _samples(320, 5), vehicleId: null);
    final other = _entry('other', _samples(500, 11), vehicleId: 'veh2');
    final empty = _entry('empty', const [], vehicleId: 'veh');

    setUp(() async {
      dir = Directory.systemTemp.createTempSync('speed_bins_');
      Hive.init(dir.path);
      box = await Hive.openBox<String>('trips_bins');
      repo = TripHistoryRepository(box: box, cap: 10);
      for (final e in [mine, shared, other, empty]) {
        await repo.save(e);
      }
    });
    tearDown(() async {
      await box.deleteFromDisk();
      await closeHiveAndDeleteTemp(dir);
    });

    test('columnSources hands over every stored trip, absent ids skipped',
        () {
      final sources = repo.columnSources(['mine', 'missing', 'other']);
      expect(sources, hasLength(2));
      expect(speedConsumptionBinsFromSources(sources).map(_fields).toList(),
          aggregateSpeedConsumption([...mine.samples, ...other.samples])
              .map(_fields)
              .toList());
    });

    Future<List<SpeedConsumptionBin>> binsFor(String? vehicleId) {
      final container = ProviderContainer(overrides: [
        tripHistoryRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);
      return container.read(speedConsumptionBinsProvider(vehicleId).future);
    }

    test('a vehicle sees its own trips plus the unassigned ones', () async {
      final bins = await binsFor('veh');
      expect(bins.map(_fields).toList(),
          aggregateSpeedConsumption([...mine.samples, ...shared.samples])
              .map(_fields)
              .toList());
    });

    test('no vehicle sees every trip that stores samples', () async {
      final bins = await binsFor(null);
      expect(
          bins.map(_fields).toList(),
          aggregateSpeedConsumption(
                  [...mine.samples, ...shared.samples, ...other.samples])
              .map(_fields)
              .toList());
    });

    test('a vehicle with no sampled trip gets the empty histogram', () async {
      final bins = await binsFor('nobody-else');
      expect(bins.map(_fields).toList(),
          aggregateSpeedConsumption([...shared.samples]).map(_fields).toList());
      await repo.delete('shared');
      expect((await binsFor('nobody-else')).fold<int>(0, (n, b) => n + b.sampleCount), 0);
    });
  });
}
