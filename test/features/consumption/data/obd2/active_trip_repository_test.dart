import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/consumption/data/obd2/active_trip_repository.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

/// Direct unit tests for [ActiveTripRepository] (#1303).
///
/// Round-trips snapshots through an in-memory Hive box and verifies
/// that:
///   1. save → load round-trips every field, including the captured
///      samples buffer the trip-detail charts depend on,
///   2. load on an empty box returns null,
///   3. clear removes the row,
///   4. a corrupt payload deserialises as null without throwing,
///   5. the [ActiveTripRepository.isStale] helper agrees with the
///      24 h default.
void main() {
  group('ActiveTripRepository (#1303)', () {
    late Directory tmpDir;
    late Box<String> box;
    late ActiveTripRepository repo;

    setUp(() async {
      tmpDir = Directory.systemTemp.createTempSync(
        'active_trip_repo_test_',
      );
      Hive.init(tmpDir.path);
      final stamp = DateTime.now().microsecondsSinceEpoch;
      box = await Hive.openBox<String>('active_$stamp');
      repo = ActiveTripRepository(box: box);
    });

    tearDown(() async {
      await box.deleteFromDisk();
      await Hive.close();
      tmpDir.deleteSync(recursive: true);
    });

    // -------- Helpers ----------------------------------------------------

    final start = DateTime.utc(2026, 4, 28, 9, 0);

    TripSummary summary({double distance = 12.4}) => TripSummary(
          distanceKm: distance,
          maxRpm: 4200,
          highRpmSeconds: 18.5,
          idleSeconds: 42,
          harshBrakes: 2,
          harshAccelerations: 1,
          avgLPer100Km: 6.7,
          fuelLitersConsumed: 0.83,
          startedAt: start,
          endedAt: start.add(const Duration(minutes: 30)),
        );

    List<TripSample> samples(int n) => [
          for (int i = 0; i < n; i++)
            TripSample(
              timestamp: start.add(Duration(seconds: i)),
              speedKmh: 50.0 + i,
              rpm: 2000.0 + i * 10,
              fuelRateLPerHour: 6.0 + i * 0.1,
              throttlePercent: 25.0 + i,
              engineLoadPercent: 30.0 + i,
              coolantTempC: 80.0 + i,
            ),
        ];

    ActiveTripSnapshot snapshotFor({
      String id = 'session-1',
      DateTime? lastFlushedAt,
      bool automatic = false,
      int sampleCount = 5,
    }) =>
        ActiveTripSnapshot(
          id: id,
          vehicleId: 'veh-1',
          vin: 'VIN-1303',
          automatic: automatic,
          phase: 'recording',
          summary: summary(),
          samples: samples(sampleCount),
          odometerStartKm: 9271.6,
          odometerLatestKm: 9284.0,
          startedAt: start,
          lastFlushedAt: lastFlushedAt ?? start.add(const Duration(minutes: 5)),
        );

    // -------- Tests ------------------------------------------------------

    test('saveSnapshot + loadSnapshot round-trip every field', () async {
      final snap = snapshotFor(automatic: true, sampleCount: 7);
      await repo.saveSnapshot(snap);

      final restored = repo.loadSnapshot();
      expect(restored, isNotNull);
      expect(restored!.id, 'session-1');
      expect(restored.vehicleId, 'veh-1');
      expect(restored.vin, 'VIN-1303');
      expect(restored.automatic, isTrue);
      expect(restored.phase, 'recording');
      expect(restored.odometerStartKm, 9271.6);
      expect(restored.odometerLatestKm, 9284.0);
      expect(restored.startedAt, start);
      expect(restored.lastFlushedAt, snap.lastFlushedAt);
      expect(restored.summary.distanceKm, snap.summary.distanceKm);
      expect(restored.summary.harshBrakes, 2);
      expect(restored.samples, hasLength(7));
      expect(restored.samples.first.speedKmh, 50.0);
      expect(restored.samples.last.speedKmh, 56.0);
      expect(restored.samples.first.fuelRateLPerHour, closeTo(6.0, 1e-9));
      expect(restored.samples.first.throttlePercent, 25.0);
      expect(restored.samples.first.engineLoadPercent, 30.0);
      expect(restored.samples.first.coolantTempC, 80.0);
    });

    test('loadSnapshot returns null on an empty box', () {
      expect(repo.loadSnapshot(), isNull);
    });

    test('saveSnapshot overwrites the previous payload', () async {
      await repo.saveSnapshot(
        snapshotFor(id: 'old-id', sampleCount: 2),
      );
      await repo.saveSnapshot(
        snapshotFor(id: 'new-id', sampleCount: 4),
      );

      final restored = repo.loadSnapshot();
      expect(restored, isNotNull);
      expect(restored!.id, 'new-id');
      expect(restored.samples, hasLength(4));
    });

    test('clearSnapshot removes the entry', () async {
      await repo.saveSnapshot(snapshotFor());
      expect(repo.loadSnapshot(), isNotNull);

      await repo.clearSnapshot();
      expect(repo.loadSnapshot(), isNull);
    });

    test('clearSnapshot is idempotent on an empty box', () async {
      // Should not throw even when nothing is on disk.
      await repo.clearSnapshot();
      expect(repo.loadSnapshot(), isNull);
    });

    test('a corrupt payload deserialises to null without throwing', () async {
      // Write raw garbage under the singleton key.
      await box.put('active', 'not even json');
      expect(repo.loadSnapshot(), isNull);
    });

    test('isStale returns true past the threshold, false within', () {
      final now = DateTime.utc(2026, 4, 28, 12, 0);
      // 23 h ago — within the default 24 h window.
      final freshSnap = snapshotFor(
        lastFlushedAt: now.subtract(const Duration(hours: 23)),
      );
      // 25 h ago — past the default window.
      final staleSnap = snapshotFor(
        lastFlushedAt: now.subtract(const Duration(hours: 25)),
      );

      expect(ActiveTripRepository.isStale(freshSnap, now: now), isFalse);
      expect(ActiveTripRepository.isStale(staleSnap, now: now), isTrue);
    });

    test('isStale honours an overridden olderThan', () {
      final now = DateTime.utc(2026, 4, 28, 12, 0);
      final snap = snapshotFor(
        lastFlushedAt: now.subtract(const Duration(minutes: 10)),
      );
      expect(
        ActiveTripRepository.isStale(snap, now: now,
            olderThan: const Duration(minutes: 5)),
        isTrue,
      );
      expect(
        ActiveTripRepository.isStale(snap, now: now,
            olderThan: const Duration(minutes: 15)),
        isFalse,
      );
    });

    test('legacy payload without phase deserialises with default', () async {
      // Write a JSON payload missing the `phase` field — keeps the
      // contract safe if older snapshots ever exist on disk.
      const legacy =
          '{"id":"legacy-1","summary":{"distanceKm":1.0,"maxRpm":0.0,'
          '"highRpmSeconds":0.0,"idleSeconds":0.0,"harshBrakes":0,'
          '"harshAccelerations":0,"distanceSource":"virtual","cs":false},'
          '"samples":[],"startedAt":"2026-04-28T09:00:00.000Z",'
          '"lastFlushedAt":"2026-04-28T09:05:00.000Z"}';
      await box.put('active', legacy);

      final restored = repo.loadSnapshot();
      expect(restored, isNotNull);
      expect(restored!.phase, 'recording');
      expect(restored.samples, isEmpty);
      expect(restored.automatic, isFalse);
    });
  });
}
