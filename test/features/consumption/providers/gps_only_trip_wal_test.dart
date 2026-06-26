// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/consumption/domain/trip_sample.dart';
import 'package:tankstellen/features/consumption/domain/trip_summary.dart';
import 'package:tankstellen/features/consumption/providers/gps_only_trip_wal.dart';
import 'package:tankstellen/features/obd2/data/active_trip_repository.dart';

/// #3248 — GPS-only recordings now write a WAL so an OS kill mid-trip recovers
/// rather than losing the whole trip. These drive the writer against a real
/// in-memory ActiveTripRepository (the same box launch-recovery reads).
void main() {
  group('GpsOnlyTripWal (#3248)', () {
    late Directory tmp;
    late Box<String> box;
    late ActiveTripRepository repo;
    late GpsOnlyTripWal wal;

    setUp(() async {
      tmp = Directory.systemTemp.createTempSync('gps_wal_test_');
      Hive.init(tmp.path);
      box = await Hive.openBox<String>(
          'gw_${DateTime.now().microsecondsSinceEpoch}');
      repo = ActiveTripRepository(box: box);
      wal = GpsOnlyTripWal(repoOverride: repo);
    });

    tearDown(() async {
      await box.deleteFromDisk();
      await Hive.close();
      tmp.deleteSync(recursive: true);
    });

    final start = DateTime.utc(2026, 6, 26, 9);
    TripSample fix(int i) => TripSample(
        timestamp: start.add(Duration(seconds: i)),
        speedKmh: 40.0 + i,
        latitude: 43.4,
        longitude: 3.5);
    const summary = TripSummary(
      distanceKm: 1.2,
      maxRpm: 0,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: 0,
      harshAccelerations: 0,
      distanceSource: 'gps',
    );

    test('seed writes a recoverable snapshot immediately', () {
      wal.seed(startedAt: start, automatic: true, vehicleId: 'veh-1');
      final snap = repo.loadSnapshot();
      expect(snap, isNotNull, reason: 'recovery needs a seed on disk at once');
      expect(snap!.id, start.toIso8601String());
      expect(snap.automatic, isTrue);
      expect(snap.vehicleId, 'veh-1');
      expect(snap.phase, 'recording');
    });

    test('flushNow persists the current samples + summary', () {
      wal.seed(startedAt: start, automatic: false, vehicleId: null);
      wal.flushNow([fix(0), fix(1), fix(2)], summary);
      final snap = repo.loadSnapshot()!;
      expect(snap.samples, hasLength(3));
      expect(snap.summary.distanceKm, 1.2);
      expect(snap.samples.first.latitude, 43.4);
    });

    test('clear() drops the WAL so launch recovery never resurrects it', () {
      wal.seed(startedAt: start, automatic: false, vehicleId: null);
      expect(repo.loadSnapshot(), isNotNull);
      wal.clear();
      expect(repo.loadSnapshot(), isNull);
    });

    test('onSample flushes once the debounce threshold (10 samples) is hit',
        () {
      wal.seed(startedAt: start, automatic: false, vehicleId: null);
      // The seed just wrote; the next few samples are debounced out.
      for (var i = 0; i < 9; i++) {
        wal.onSample([for (var k = 0; k <= i; k++) fix(k)], summary);
      }
      expect(repo.loadSnapshot()!.samples, isEmpty,
          reason: 'still inside the debounce window after the seed');
      // The 10th sample crosses the count threshold → flush.
      wal.onSample([for (var k = 0; k < 10; k++) fix(k)], summary);
      expect(repo.loadSnapshot()!.samples, hasLength(10),
          reason: 'a kill now loses at most the debounce window, not the trip');
    });

    test('writes are best-effort no-ops before a seed', () {
      // No seed → nothing to write; must not throw.
      expect(() => wal.flushNow([fix(0)], summary), returnsNormally);
      expect(repo.loadSnapshot(), isNull);
    });
  });
}
