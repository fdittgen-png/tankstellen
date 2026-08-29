// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3878 — with a writable WAL the GPS-only path keeps NO full sample list:
// samples go to the append-only file once each, the Hive row stays
// meta-only, and `readAll()` hands the whole trip back at stop.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/obd2/data/active_trip_repository.dart';
import 'package:tankstellen/features/obd2/data/active_trip_sample_wal.dart';
import 'package:tankstellen/features/trips/domain/trip_sample.dart';
import 'package:tankstellen/features/trips/domain/trip_summary.dart';
import 'package:tankstellen/features/trips/providers/gps_only_trip_wal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late Box<String> box;
  late ActiveTripSampleWal sampleWal;
  late ActiveTripRepository repo;
  late GpsOnlyTripWal wal;
  final start = DateTime(2026, 8, 29, 7);

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('gps_wal_readall_');
    Hive.init(dir.path);
    box = await Hive.openBox<String>('active_trip_readall');
    sampleWal = ActiveTripSampleWal(supportDirOverride: () => dir);
    repo = ActiveTripRepository(box: box, sampleWal: sampleWal);
    wal = GpsOnlyTripWal(repoOverride: repo);
  });

  tearDown(() async {
    await sampleWal.clear();
    await box.deleteFromDisk();
    await Hive.close();
    dir.deleteSync(recursive: true);
  });

  TripSample fix(int i) => TripSample(
      timestamp: start.add(Duration(seconds: i)),
      speedKmh: 30.0 + i,
      latitude: 43.4 + i * 1e-4,
      longitude: 3.5);
  const summary = TripSummary(
      distanceKm: 2,
      maxRpm: 0,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: 0,
      harshAccelerations: 0,
      distanceSource: 'gps');

  test('samples stream to the WAL file; the row is meta-only; readAll '
      'returns the whole trip', () async {
    wal.seed(startedAt: start, automatic: false, vehicleId: 'v');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(wal.walWritable, isTrue);
    for (var i = 0; i < 25; i++) {
      wal.onSample(fix(i), summary);
    }
    wal.flushNow(summary);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(repo.loadSnapshot()!.samples, isEmpty,
        reason: 'meta-only row — the samples live in the WAL file');

    final all = await wal.readAll();
    expect(all, hasLength(25));
    expect(all.first.speedKmh, 30);
    expect(all.last.speedKmh, 54);
  });
}
