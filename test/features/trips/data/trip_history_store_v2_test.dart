// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3882 — trip detail v2: the columnar chunk is the exact transpose of the
// per-sample codec (byte-identical `sampleToJson` maps round-trip), the
// v2 rows re-assemble to the same `toJson()`, and the repository reads
// legacy rows, migrates them, filters sidecar keys and trims chunks.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/trips/data/trip_column_chunk.dart';
import 'package:tankstellen/features/trips/data/trip_history_repository.dart';
import 'package:tankstellen/features/trips/data/trip_history_store_v2.dart';
import 'package:tankstellen/features/trips/data/trip_sample_codec.dart';
import 'package:tankstellen/features/trips/domain/entities/gps_sample_diagnostic.dart';
import 'package:tankstellen/features/trips/domain/trip_sample.dart';
import 'package:tankstellen/features/trips/domain/trip_summary.dart';
import 'package:tankstellen/features/trips/domain/trip_verdict.dart';

final _start = DateTime(2026, 8, 30, 8);

List<TripSample> _samples(int n) => [
      for (var i = 0; i < n; i++)
        TripSample(
          timestamp: _start.add(Duration(milliseconds: 1000 * i + (i % 3))),
          speedKmh: 30.0 + (i % 40),
          rpm: i % 7 == 0 ? null : 1500.0 + i,
          fuelRateLPerHour: i % 5 == 0 ? null : 3.0 + i / 100,
          latitude: 48.0 + i * 1e-5,
          longitude: 2.0 + i * 1e-5,
          batteryVoltageV: i == 42 ? 14.2 : null, // sparse column
        ),
    ];

TripHistoryEntry _entry(String id, int n) => TripHistoryEntry(
      id: id,
      vehicleId: 'veh',
      summary: TripSummary(
          distanceKm: n / 60,
          maxRpm: 3000,
          highRpmSeconds: 0,
          idleSeconds: 0,
          harshBrakes: 1,
          harshAccelerations: 2,
          startedAt: _start),
      samples: _samples(n),
      gpsSampleDiagnostics: [
        for (var i = 0; i < 3; i++)
          GpsSampleDiagnostic(
              timestamp: _start.add(Duration(seconds: i)),
              lifecycleState: 'resumed',
              index: i),
      ],
      adapterMac: 'AA:BB:CC:DD:EE:FF',
    );

void main() {
  test('a chunk is the exact transpose of the per-sample codec', () {
    final samples = _samples(50);
    final maps = samples.map(sampleToJson).toList();
    final chunk = encodeTripChunk(samples);
    expect(chunk['n'], 50);
    expect((chunk['c'] as Map).containsKey('bv'), isTrue);
    expect(decodeTripChunkMaps(chunk), maps,
        reason: 'omit-when-null survives the round-trip');
    expect(decodeTripChunk(chunk).map(sampleToJson).toList(), maps);
  });

  test('column-selective decode returns only the asked arrays', () {
    final cols = decodeTripChunkColumns(encodeTripChunk(_samples(10)), {'s', 'f'});
    expect(cols.length, 10);
    expect(cols.values.keys, {'s', 'f'});
    expect(cols.values['f']![0], isNull, reason: 'i % 5 == 0 has no fuel');
    expect(cols.values['s']![3], 33.0);
  });

  test('v2 rows re-assemble to the identical toJson()', () {
    final e = _entry('2026-08-30T08:00:00.000', 700); // 3 chunks
    final json = e.toJson();
    final rows = encodeTripRowsV2(json);
    expect(rows.keys, containsAll([
      e.id, tripChunkKey(e.id, 0), tripChunkKey(e.id, 1), tripChunkKey(e.id, 2),
      tripGpsdKey(e.id)]));
    expect(rows.containsKey(tripChunkKey(e.id, 3)), isFalse);
    final meta = jsonDecode(rows[e.id]!) as Map;
    expect(meta['v'], 2);
    expect(meta['sc'], 700);
    expect(meta['cols'], containsAll(['s', 'r', 'f', 'la', 'lo', 'bv']));
    expect(meta.containsKey('samples'), isFalse);
    final back = decodeTripRowsV2(TripRowsV2(
        meta: rows[e.id]!,
        chunks: [for (var i = 0; i < 3; i++) rows[tripChunkKey(e.id, i)]!],
        gpsd: rows[tripGpsdKey(e.id)]));
    expect(back, json,
        reason: 'the export / TankSync wire MAP is identical (key order '
            'is not part of the contract — every consumer merges maps)');
  });

  group('repository', () {
    late Directory dir;
    late Box<String> box;
    late TripHistoryRepository repo;
    setUp(() async {
      dir = Directory.systemTemp.createTempSync('trip_v2_');
      Hive.init(dir.path);
      box = await Hive.openBox<String>('trips_v2');
      repo = TripHistoryRepository(box: box, cap: 3);
    });
    tearDown(() async {
      await box.deleteFromDisk();
      await Hive.close();
      dir.deleteSync(recursive: true);
    });

    test('save writes meta + chunks; summaries never touch a chunk; '
        'loadById / loadByIdAsync / loadColumns agree', () async {
      final e = _entry('t1', 650);
      await repo.save(e);
      expect(repo.storedIds, ['t1'], reason: 'sidecars are not trips');
      expect(box.keys.length, 1 + 3 + 1);
      final summary = repo.loadSummaries().single;
      expect(summary.sampleCount, 650);
      expect(summary.columnsPresent, containsAll(['s', 'la']));
      expect(summary.samples, isEmpty);
      final full = repo.loadById('t1')!;
      expect(full.samples.map(sampleToJson).toList(),
          e.samples.map(sampleToJson).toList());
      expect(full.gpsSampleDiagnostics, hasLength(3));
      expect(full.adapterMac, e.adapterMac);
      final async = await repo.loadByIdAsync('t1');
      expect(jsonEncode(async!.toJson()), jsonEncode(e.toJson()));
      final cols = repo.loadColumns('t1', {'s', 'r'});
      expect(cols.length, 650);
      expect(cols.values['r']![0], isNull);
      expect(repo.loadSamplesWith('t1', {'s', 'f'}).length, 650);
    });

    test('saveVerdict rewrites the meta row only', () async {
      await repo.save(_entry('t2', 10));
      final chunkBefore = box.get(tripChunkKey('t2', 0));
      await repo.saveVerdict('t2', TripVerdict.smooth);
      expect(box.get(tripChunkKey('t2', 0)), chunkBefore);
      expect(repo.loadById('t2')!.verdict, TripVerdict.smooth.wireName);
    });

    test('delete and trim remove the sidecars too', () async {
      for (var i = 0; i < 5; i++) {
        await repo.save(_entry('t$i', 400)
            .withStart(_start.add(Duration(hours: i))));
      }
      expect(repo.storedIds.length, 3, reason: 'cap 3');
      expect(box.keys.where(isTripSidecarKey).length, 3 * 3,
          reason: 'two chunks + gpsd per surviving trip');
      await repo.delete('t4');
      expect(box.keys.where((k) => tripIdOfKey(k as String) == 't4'), isEmpty);
    });

    test('a legacy v1 row reads, migrates on first full read, and the '
        'background sweep converts the rest', () async {
      final e1 = _entry('legacy1', 320);
      final e2 = _entry('legacy2', 5);
      await box.put('legacy1', jsonEncode(e1.toJson()));
      await box.put('legacy2', jsonEncode(e2.toJson()));
      expect(repo.loadSummaries().map((t) => t.id), containsAll(['legacy1', 'legacy2']));
      final full = repo.loadById('legacy1')!;
      expect(full.samples, hasLength(320));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(box.containsKey(tripChunkKey('legacy1', 0)), isTrue,
          reason: 'first full read scheduled the rewrite');
      expect((jsonDecode(box.get('legacy1')!) as Map)['v'], 2);
      final n = await repo.migrateLegacyRowsInBackground(pause: Duration.zero);
      expect(n, 1, reason: 'legacy2 was still v1');
      expect(jsonEncode(repo.loadById('legacy2')!.toJson()), jsonEncode(e2.toJson()));
    });
  });
}

extension on TripHistoryEntry {
  TripHistoryEntry withStart(DateTime at) => TripHistoryEntry(
        id: id,
        vehicleId: vehicleId,
        summary: summary.copyWith(startedAt: at),
        samples: samples,
        gpsSampleDiagnostics: gpsSampleDiagnostics,
        adapterMac: adapterMac,
      );
}
